locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.k8s_subnets_count)

  subnets = [
    for k, v in aws_subnet.k8s : v.id
  ]

  subnets_cidr_suffixes = [
    ".96.0/20",
    ".128.0/20",
    ".144.0/20"
  ]
}

resource "aws_subnet" "k8s" {
  count = length(local.azs)

  cidr_block              = "${var.vpc_cidr_start}${local.subnets_cidr_suffixes[count.index]}"
  vpc_id                  = module.vpc.vpc_id
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false
  tags = {
    "Name"                                          = "k8s_1-${local.azs[count.index]}"
    "purpose"                                       = "k8s"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

data "aws_internet_gateway" "default_igw" {
  internet_gateway_id = module.vpc.igw_id
}

data "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
}

module "eks" {
  version          = "18.30.2"
  source           = "terraform-aws-modules/eks/aws"

  iam_role_name                      = var.eks_cluster_name
  cluster_security_group_name        = var.eks_cluster_name
  cluster_security_group_description = "EKS cluster security group"

  cluster_name     = var.eks_cluster_name
  cluster_version  = var.k8s_cluster_version
  subnet_ids       = local.subnets
  enable_irsa      = true

  tags = {
    purpose = "k8s-${var.environment}-${var.segment}"
  }

  vpc_id = module.vpc.vpc_id

  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30
  manage_aws_auth_configmap              = false

  aws_auth_roles = concat(
    [
      {
        rolearn  = data.aws_iam_role.eks_node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
    ],
    var.k8s_map_roles,
  )


  aws_auth_users = var.k8s_map_users
  aws_auth_accounts = var.k8s_aws_auth_accounts
}



data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_eks_node_group" "worker" {
  depends_on    = [module.eks.cluster_arn]
  ami_type      = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  cluster_name  = var.eks_cluster_name
  disk_size     = 100
  instance_types = [
    var.k8s_worker_instances_size
  ]
  labels = {
    "Name"                   = "eks-node-worker-${var.environment}-${var.segment}"
    "purpose"                = "eks-node-worker"
    "tags.datadoghq.com/env" = "${var.environment}"
  }
  node_group_name = "worker"
  node_role_arn   = "arn:aws:iam::${var.aws_account_id}:role/eks-node-role"

  subnet_ids = local.subnets
  tags = {
    "Name" = "eks-node-worker-${var.environment}-${var.segment}"
  }
  version = var.k8s_worker_version

  scaling_config {
    desired_size = var.k8s_worker_desired_size
    max_size     = var.k8s_worker_max_size
    min_size     = var.k8s_worker_min_size
  }

  timeouts {}
}
