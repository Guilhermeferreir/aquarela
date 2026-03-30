module "vpc" {
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
