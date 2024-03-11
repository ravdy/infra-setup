variable "account" {
  type = string
  description = "AWS Account ID, must be twelve digits."
}

variable "environment" {
  type = string
  description = "Logical environment, for example dev-1,qa-1,uat-1,prod-1"
}

variable "segment" {
  type = string
  description = "Logical part of environment, for example in active/active setup we can have east and west segments in the corresponding regions"
}

variable "cluster" {
  type        = string
  description = "EKS Cluster Name"
}

variable "role" {
  type = string
  description = "(Optional) Name of the IAM Role that Datadog can assume to integrate with AWS"
  default = "DatadogAWSIntegrationRole"
}

variable "log_retention_years" {
  type = number
  description = "(Optional; default 1 year) The number of years that logs will be (almost) undeletable"
  default = 1
}
