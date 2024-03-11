terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
      configuration_aliases = [ aws.target, aws.replication ]
    }

  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
}
