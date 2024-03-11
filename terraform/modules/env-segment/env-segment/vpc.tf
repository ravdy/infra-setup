resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_eip" "outgoing_ip" {
  count = var.vpc_number_of_azs == 0 || var.vpc_number_of_azs > 1 ? 0 : 1
}

resource "aws_eip" "outgoing_ip_multiaz" {
  count = var.vpc_number_of_azs
  vpc   = true
}

locals {
  vpc_az_count = var.vpc_number_of_azs == 0 ? length(data.aws_availability_zones.available.names) : var.vpc_number_of_azs
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name            = "vpc-${var.environment}-${var.segment}"
  cidr            = "${var.vpc_cidr_start}.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, local.vpc_az_count)
  private_subnets = ["${var.vpc_cidr_start}.16.0/20", "${var.vpc_cidr_start}.32.0/20", "${var.vpc_cidr_start}.176.0/20"]
  public_subnets  = ["${var.vpc_cidr_start}.48.0/20", "${var.vpc_cidr_start}.64.0/20", "${var.vpc_cidr_start}.160.0/20"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  // Choosing between a single NAT Gateway and one per AZ, using var.vpc_nat_gateway_multiaz
  // Note: changing this decision will rebuild large chunks of the VPC, plan and check ahead of
  // time.
  enable_nat_gateway     = true
  single_nat_gateway     = !var.vpc_nat_gateway_multiaz // true if multiaz is false, must be opposite below
  one_nat_gateway_per_az = var.vpc_nat_gateway_multiaz  // true if multiaz is true, must be opposite above

  // This variable behaves differently when using NAT Gateway for multiple AZ vs. single AZ
  external_nat_ip_ids = var.vpc_nat_gateway_multiaz ? "${aws_eip.outgoing_ip_multiaz.*.id}" : (length(aws_eip.outgoing_ip) != 0 ? [aws_eip.outgoing_ip[0].id] : [])
  reuse_nat_ips       = var.vpc_nat_gateway_multiaz // reduces number of situations where Nat IP is altered

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                               = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                      = "1"
  }
}

data "aws_vpc" "xpansiv" {
  id = module.vpc.vpc_id
}

resource "aws_route" "main_to_nat" {
  route_table_id         = data.aws_vpc.xpansiv.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.vpc.natgw_ids[0]
}

resource "aws_ssm_parameter" "vpc_id" {
  name = "/${var.environment}/${var.segment}/infra/vpc_id"
  type = "String"
  value = module.vpc.vpc_id
  overwrite = true
}
