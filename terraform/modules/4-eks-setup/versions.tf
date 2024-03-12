terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.30.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">=2.6.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">=2.2.3"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.13.1"
    }
  }
}
