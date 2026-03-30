locals {
  name         = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name}-eks"
  azs          = slice(data.aws_availability_zones.available.names, 0, var.azs_count)

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  network_tags = merge(
    local.common_tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    },
  )

  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : module.vpc[0].vpc_id

  public_subnet_ids = var.use_existing_vpc ? [
    for subnet_name in var.existing_public_subnet_name_tags : data.aws_subnet.existing_public[subnet_name].id
  ] : module.vpc[0].public_subnets

  private_subnet_ids = var.use_existing_vpc ? [
    for subnet_name in var.existing_private_subnet_name_tags : data.aws_subnet.existing_private[subnet_name].id
  ] : module.vpc[0].private_subnets

  control_plane_subnet_ids = var.use_existing_vpc ? (
    length(var.existing_control_plane_subnet_name_tags) > 0 ? [
      for subnet_name in var.existing_control_plane_subnet_name_tags : data.aws_subnet.existing_control_plane[subnet_name].id
    ] : [
      for subnet_name in var.existing_private_subnet_name_tags : data.aws_subnet.existing_private[subnet_name].id
    ]
  ) : module.vpc[0].intra_subnets

  discovery_subnet_ids = distinct(concat(local.public_subnet_ids, local.private_subnet_ids))
}
