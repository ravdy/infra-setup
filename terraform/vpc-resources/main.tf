module "secrets" {
  source = "../segment-secrets"
  environment     = var.environment
  segment         = var.segment
}

provider "datadog" {
  validate = false
  app_key = module.secrets.dd_app_key
  api_key = module.secrets.dd_api_key
}


data "aws_caller_identity" "current" {}


module "env-segment" {
  source = "git@gitlab.com:edbence/Core/tf-modules/env-segment.git?ref=1.0.8"
  environment     = var.environment
  segment         = var.segment
  aws_account_id   = module.secrets.aws_account_id
  eks_cluster_name = "${var.environment}-${var.segment}"
  vpc_cidr_start = module.secrets.segment_vpc_cidr_prefix
  domain_name =  module.secrets.public_domain_name
  domain_suffix_internal = "internal"
  k8s_cluster_version = var.k8s_version
  k8s_worker_version = var.k8s_version
  k8s_map_users = []
  vpc_number_of_azs = 3
  k8s_worker_desired_size = 1
  k8s_worker_min_size = 1
  k8s_worker_instances_size = "t2.micro"
  vpc_nat_gateway_multiaz = true
  k8s_aws_auth_accounts = [ module.secrets.aws_account_id ]
  
}

module "env-segment-logging" {
  source = "git@gitlab.com:edbence/Core/tf-modules/env-segment-datadog.git?ref=1.0.0"
  environment = var.environment
  segment = var.segment
}

resource "local_file" "aws-auth" {
  filename = "aws-auth.yaml"
  content = module.env-segment.aws_auth_configmap_yaml
}