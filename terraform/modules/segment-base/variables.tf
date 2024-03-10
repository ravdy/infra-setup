

variable "environment"                         {}
variable "segment"                             {}



variable "k8s_version" {
  default = "1.24"
}

variable "k8s_worker_desired_size" {
  default = "1"
}


variable "domain_name_internal" {
  default = "edbence.internal"
}

variable "ec2_key_name" {
  default = "edbence-commons-preprod"
}

variable "ec2_ami_filter" {
  type = list(string)
  default = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20221101.1"]
}
