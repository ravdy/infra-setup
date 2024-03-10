variable "environment"                         {}
variable "segment"                             {}

variable "k8s_version" {
  default = "1.24"
}

variable "k8s_worker_desired_size" {
  default = "1"
}