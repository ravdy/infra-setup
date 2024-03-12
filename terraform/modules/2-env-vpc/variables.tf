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
# NAT Gateway and AZ Variables
#
variable "availability_zones" {
  type        = list(string)
  description = "preferred availability zones for the region"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_nat_gateway_multiaz" {
  type        = bool
  description = "Should each AZ get its own NAT gateway?"
  default     = false
}

variable "vpc_number_of_azs" {
  type        = number
  description = "The number of AZs to be used in the VPC; use 0 for 'all of them'."
  default     = 0
}

#
# Networking Variables
#
variable "vpc_cidr_start" {
  type        = string
  description = "First two octets of the CIDR for the VPC"
}


variable "domain_name" {
  type        = string
  description = "Domain suffix to use, e.g: dev-1.env.cbourses.net, qa-1.env.cbourses.net, see environment variable"
}

variable "domain_suffix_internal" {
  type        = string
  description = "Domain suffix for internal DNS, e.g: xmarkets-dev-1.xmarkets.xpansiv.internal"
}


//
// Kubernetes
//
variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "k8s_cluster_version" {
  type        = string
  description = "EKS Version"
  default     = "1.28"
}

variable "k8s_worker_version" {
  type        = string
  description = "EKS Version"
  default     = "1.28"
}

variable "k8s_map_users" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  description = "Additional IAM users to add to the aws-auth configmap."
  default = []
}

variable "k8s_map_roles" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  description = "Additional IAM roles to add to the aws-auth configmap."
  default     = []
}


variable "k8s_aws_auth_accounts" {
  type        = list(string)
  description = "Additional accounts to put into aws-auth configmap."
}

variable "k8s_worker_instances_size" {
  type        = string
  description = "AWS instance size of the worker nodes"
  default     = "c4.2xlarge"
}

variable "k8s_worker_desired_size" {
  type        = number
  description = "Desired size of the node cluster"
  default     = 3
}

variable "k8s_worker_min_size" {
  type        = number
  description = "Minimum size of the node cluster"
  default     = 3
}

variable "k8s_worker_max_size" {
  type        = number
  description = "Maximum size of the node cluster"
  default     = 5
}

variable "k8s_subnets_count" {
  type        = number
  description = "Number of subnets to create for our eks cluster (one per each az in that region)"
  default     = 3
}

///
/// Route 53
///
variable "public_route53_zone_id" {
  type        = string
  description = ""
  default     = "set-public_route53_zone_id"
}
