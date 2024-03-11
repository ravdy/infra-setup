variable "environment" {}
variable "segment" {}

variable "helm_nginx_ingress_controller_version" {
  type        = string
  description = "Desired Helm chart version for the NGINX Ingress Controller"
  default     = "4.8.3"
}

variable "ssl_cert_wildcard_arn" {
  type = string
}

variable "aws_route53_zone_public_id" {
  type = string
}

variable "aws_route53_zone_internal_id" {
  type = string
}
