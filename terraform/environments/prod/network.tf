module "vpc" {
  count   = var.use_existing_vpc ? 0 : 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets  = [for idx in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, idx)]
  private_subnets = [for idx in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, idx + 10)]
  intra_subnets   = [for idx in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, idx + 20)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.network_tags
}

data "aws_subnet" "existing_public" {
  for_each = var.use_existing_vpc ? toset(var.existing_public_subnet_name_tags) : toset([])

  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

data "aws_subnet" "existing_private" {
  for_each = var.use_existing_vpc ? toset(var.existing_private_subnet_name_tags) : toset([])

  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

data "aws_subnet" "existing_control_plane" {
  for_each = var.use_existing_vpc ? toset(var.existing_control_plane_subnet_name_tags) : toset([])

  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

resource "aws_ec2_tag" "existing_subnet_cluster_tag" {
  for_each = var.use_existing_vpc ? toset(local.discovery_subnet_ids) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "existing_public_subnet_elb_tag" {
  for_each = var.use_existing_vpc ? toset(local.public_subnet_ids) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "existing_private_subnet_internal_elb_tag" {
  for_each = var.use_existing_vpc ? toset(local.private_subnet_ids) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
