terraform {
  backend "s3" {
    encrypt        = true
    region         = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
  }
}


provider "aws" {
  ignore_tags {
    key_prefixes = ["cloudfix"]
  }
}


module "segment_east" {
  source = "../modules/segment-base"
  environment = var.environment
  segment = var.segment
  k8s_version = var.k8s_version
  k8s_worker_desired_size = var.k8s_worker_desired_size
}

