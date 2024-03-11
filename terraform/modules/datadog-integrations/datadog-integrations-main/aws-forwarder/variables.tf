variable "environment" {
  type = string
  description = "Such as commons-prod or xample-dev"
}

variable "segment" {
  type = string
  description = "east, west, blue, green, etc."
}

variable "cluster" {
  type = string
  description = "EKS Cluster Name"
}

variable "api_key" {
  type = string
  description = "The Datadog API Key"
}
