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
}
