variable "environment" {}
variable "segment" {}
variable "internal_dns_id" {}

variable "eks_node_role_arn" {
  type = string
  description = "part of default eks aws-auth security settings"
}

variable "ssl_cert_wildcard_public_arn" {
  type = string
}

variable "datadog_api_key" {}
variable "datadog_app_key" {}
