data "aws_iam_user" "existing_desafio_aquarela" {
  count = var.use_existing_desafio_aquarela_user ? 1 : 0

  user_name = var.existing_desafio_aquarela_user_name
}

resource "aws_iam_user" "desafio_aquarela" {
  count = var.use_existing_desafio_aquarela_user ? 0 : 1

  name = "desafio_aquarela"
  path = "/"
  tags = local.common_tags
}

data "aws_iam_policy_document" "desafio_aquarela_cluster_access" {
  statement {
    sid = "DescribeManagedCluster"

    actions = [
      "eks:DescribeCluster",
    ]

    resources = [module.eks.cluster_arn]
  }

  statement {
    sid = "ListClusters"

    actions = [
      "eks:ListClusters",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "desafio_aquarela_cluster_access" {
  name = "desafio-aquarela-eks-access"
  user = var.use_existing_desafio_aquarela_user ? var.existing_desafio_aquarela_user_name : aws_iam_user.desafio_aquarela[0].name

  policy = data.aws_iam_policy_document.desafio_aquarela_cluster_access.json
}
