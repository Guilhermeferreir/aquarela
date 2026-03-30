provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        ManagedBy = "terraform"
        Project   = "aquarela"
      },
      var.tags
    )
  }
}
