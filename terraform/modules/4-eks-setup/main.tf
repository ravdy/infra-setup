data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_vpc" "edbence" {
  filter {
    name   = "tag:Name"
    values = ["vpc-${var.environment}-${var.segment}"]
  }
}

#data "aws_subnet" "k8s" {
#  count = var.k8s_subnets_count
#
#  id = var.k8s_subnets[count.index]
#}


data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
}
