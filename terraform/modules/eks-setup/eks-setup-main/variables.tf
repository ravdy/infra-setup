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

variable "aws_account_id" {
  type        = string
  description = ""
}

#
# Networking Variables
#
variable "domain_name" {
  type        = string
  description = "Domain suffix to use, e.g: dev-1.env.cbourses.net, qa-1.env.cbourses.net, see environment variable"
}

variable "aws_route53_zone_public_id" {
  type        = string
}


#variable "k8s_subnets" {
#  type        = list(string)
#  description = ""
#}
#
#variable "k8s_subnets_count" {
#  type        = number
#  description = ""
#  default     = 3
#}
#
#


variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "docker_auth_file_secret" {
  type        = string
  description = "Secret name for artifactory credentials"
  default     = "edbence-artifactory-docker-auth-file"
}



variable "helm_aws_load_balancer_controller_version" {
  type        = string
  description = "Desired Helm chart version for the AWS Load Balancer Controller"
  default     = "1.4.3"
}




