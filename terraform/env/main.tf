terraform {
  backend "s3" {
    encrypt        = true
    region         = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=4.30.0"
    }

    datadog = {
      source = "Datadog/datadog"
      version = ">=3.20.0"
    }
  }
}


provider "aws" {
  ignore_tags {
    key_prefixes = ["cloudfix"]
  }
}


provider "datadog" {
  validate = false
  app_key = module.secrets.dd_app_key
  api_key = module.secrets.dd_api_key
}


module "secrets" {
  source = "../modules/segment-secrets"
  environment = var.environment
  segment = var.segment
}


module "env-global" {
  source = "git@gitlab.com:edbence/Core/tf-modules/env-global.git?ref=1.0.5"
  environment = var.environment
  datadog_aws_integration_external_id = module.secrets.dd_aws_integration_external_id
}


module "datadog-integration" {
  source = "git@gitlab.com:edbence/Core/tf-modules/datadog-integrations.git//aws-integration?ref=1.1.2"

  environment = var.environment
}
