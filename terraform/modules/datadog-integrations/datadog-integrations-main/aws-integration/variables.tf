variable "environment" {
  type = string
  description = "Logical environment, for example dev-1,qa-1,uat-1,prod-1"
}

variable "role" {
  type = string
  description = "(Optional) Name of the IAM Role that Datadog can assume to integrate with AWS"
  default = "DatadogAWSIntegrationRole"
}

variable "policy" {
  type = string
  description = "(Optional) Name of the IAM Policy that attached to role"
  default = "DatadogAWSIntegrationPolicy"
}

variable "integration_id" {
  type = string
  description = "(Optional) Use an existing ID instead of creating a new one."
  default = ""
}
