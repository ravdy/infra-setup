#
# AWS Locale Variables
#
variable "environment" {
  type        = string
  description = "Logical environment, for example dev-1,qa-1,uat-1,prod-1"
}


variable "segment" {
  type        = string
  description = "Logical part of environment, for example in active/active setup we can have east and west segments in the corresponding regions"
}

variable "domain_name_internal" {
  type        = string
  description = "Domain suffix for internal DNS, e.g: xmarkets-dev-1.xmarkets.edbence.internal"
}

variable "vpn_client_saml_provider_arn" {
  type        = string
  description = "IAM IdP arn of SAML provider"
}

///
/// Route 53
///
variable "public_route53_zone_id" {
  type        = string
  description = ""
  default     = "set-public_route53_zone_id"
}
