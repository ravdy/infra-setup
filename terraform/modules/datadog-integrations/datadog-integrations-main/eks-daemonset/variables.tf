variable "cluster" {
  type        = string
  description = "EKS Cluster Name"
}

variable "environment" {
  type = string
  description = "xample-dev, commons-prod, etc."
}

variable "segment" {
  type = string
  description = "east, west, blue, green, etc."
}

variable "api_key" {
  type = string
  description = "API Key for Datadog"
}

variable "app_key" {
  type = string
  description = "APP Key for Datadog"
}

variable "datadog_helm_chart_version" {
  type = string
  description = "(Optional) Desired Helm chart version for Datadog agent"
  default = "3.10.1"
}
