module "secrets" {
  source = "../segment-secrets"
  environment     = var.environment
  segment         = var.segment
}


module "eks_auth_management" {
  source                     = "git@gitlab.com:edbence/Core/tf-modules/eks-auth-management.git?ref=1.0.0"

  eks_node_role_arn = var.eks_node_role_arn
  aws_extra_auth_roles = [
    {
      rolearn = "arn:aws:iam::${module.secrets.aws_account_id}:role/cicd"
      username = "cicd"
      groups = [ "system:masters"]
    },
    {
      rolearn = "arn:aws:iam::${module.secrets.aws_account_id}:role/ops"
      username = "ops"
      groups = [ "system:masters"]
    },
    {
      rolearn = "arn:aws:iam::${module.secrets.aws_account_id}:role/infrastructure"
      username = "infrastructure"
      groups = [ "system:masters"]
    },
    {
      rolearn = "arn:aws:iam::${module.secrets.aws_account_id}:role/developer"
      username = "developer"
      groups = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${module.secrets.aws_account_id}:role/ArgoCD",
      username = "argocd",
      groups   = ["argocd:management"]
    }]
  map_accounts = []
}


module "eks-setup" {
  depends_on = [ module.eks_auth_management ]
  source                     = "git@gitlab.com:edbence/Core/tf-modules/eks-setup.git?ref=1.0.4"

  aws_account_id             = module.secrets.aws_account_id
  environment                = var.environment
  segment                    = var.segment
  eks_cluster_name           = "${var.environment}-${var.segment}"

  domain_name                = module.secrets.public_domain_name
  aws_route53_zone_public_id = module.secrets.public_route53_zone_id
}


module "eks-datadog" {
  depends_on = [ module.eks-setup ]
  source = "git@gitlab.com:edbence/Core/tf-modules/datadog-integrations.git//eks-daemonset?ref=1.1.0"

  environment = var.environment
  segment = var.segment
  cluster = "${var.environment}-${var.segment}"

  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
}


module "datadog-forwarder" {
  source = "git@gitlab.com:edbence/Core/tf-modules/datadog-integrations.git//aws-forwarder?ref=1.1.0"

  environment = var.environment
  segment = var.segment
  cluster = "${var.environment}-${var.segment}"

  api_key = var.datadog_api_key
}


module "nginx-ingress" {
  depends_on = [ module.eks-setup, module.datadog-forwarder ]
  source = "git@gitlab.com:edbence/Core/tf-modules/eks-ingress-nginx-opensource.git?ref=1.0.8"

  environment = var.environment
  segment = var.segment

  aws_route53_zone_public_id = module.secrets.public_route53_zone_id
  aws_route53_zone_internal_id = var.internal_dns_id
  ssl_cert_wildcard_arn = var.ssl_cert_wildcard_public_arn
  #Pinned to 4.7.3 as this is the last version to support EKS 1.24
  helm_nginx_ingress_controller_version = "4.7.3"
}
