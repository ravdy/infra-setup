terraform {
  required_version = ">= 1.0"

  required_providers {
    datadog = {
      source = "DataDog/datadog"
      version = ">=3.20.0"
    }
  }
}
