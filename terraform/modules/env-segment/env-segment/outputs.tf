output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_ca_certificate" {
   value = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_node_role_arn" {
  value = data.aws_iam_role.eks_node_role.arn
}

output "aws_auth_configmap_yaml" {
  description = "Formatted yaml output for base aws-auth configmap containing roles used in cluster node groups/fargate profiles"
  value       = module.eks.aws_auth_configmap_yaml
}

output "vpc_id" {
  value = data.aws_vpc.xpansiv.id
}

output "vpc_private_subnets_ids" {
  description = "The ids of the 3 private subnets created"
  value       = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_default_security_group_id" {
  description = "The id of the default security group id"
  value        = module.vpc.default_security_group_id
}

output "internal_dns_id" {
  value =  aws_route53_zone.internal.id
}

output "internal_dns_zone" {
  value =  aws_route53_zone.internal
}

output "aws_cloudwatch_log_group" {
  value = module.eks.cloudwatch_log_group_name
}
