terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.30.0"
    }

    datadog = {
      source = "DataDog/datadog"
      version = ">=3.20.0"
    }
  }
}
