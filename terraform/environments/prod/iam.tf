resource "aws_iam_user" "desafio_aquarela" {
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
  name   = "desafio-aquarela-eks-access"
  user   = aws_iam_user.desafio_aquarela.name
  policy = data.aws_iam_policy_document.desafio_aquarela_cluster_access.json
}
