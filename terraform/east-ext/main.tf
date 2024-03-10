terraform {
  backend "s3" {
    encrypt        = true
    region         = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
  }

}

data "terraform_remote_state" "east_base" {
  backend = "s3"
  config = {
    region         = "us-east-1"
    bucket = "edbence-${var.environment}-${var.segment}-terraform-infra-state"
    key = "${var.environment}-east-base-terraform-infra-state"
  }
}

data "aws_acm_certificate" "wildcard_public" {
  domain   = "*.${var.environment}.env.edbence.com"
  statuses = ["ISSUED"]
}


provider "aws" {
  ignore_tags {
    key_prefixes = ["cloudfix"]
  }
}


provider "kubernetes" {
  host                   = data.terraform_remote_state.east_base.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode( data.terraform_remote_state.east_base.outputs.eks_cluster_ca_certificate )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.east_base.outputs.eks_cluster_id ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.east_base.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode( data.terraform_remote_state.east_base.outputs.eks_cluster_ca_certificate )

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.east_base.outputs.eks_cluster_id ]
    }
  }
}

module "segment_east_ext" {
  source = "../modules/segment-ext"
  environment = var.environment
  segment = var.segment
  ssl_cert_wildcard_public_arn = data.aws_acm_certificate.wildcard_public.arn
  internal_dns_id = data.terraform_remote_state.east_base.outputs.internal_dns_id
  eks_node_role_arn = data.terraform_remote_state.east_base.outputs.eks_node_role_arn
  datadog_api_key = module.secrets.dd_api_key
  datadog_app_key = module.secrets.dd_app_key
}

module "secrets" {
  source = "../modules/segment-secrets"
  environment = var.environment
  segment = "east"
}
