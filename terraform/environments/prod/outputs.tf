output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS control plane endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA data."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "region" {
  description = "AWS region hosting the cluster."
  value       = var.region
}

output "desafio_aquarela_user_arn" {
  description = "IAM user ARN mapped into the aws-auth ConfigMap."
  value       = var.use_existing_desafio_aquarela_user ? data.aws_iam_user.existing_desafio_aquarela[0].arn : aws_iam_user.desafio_aquarela[0].arn
}

output "update_kubeconfig_command" {
  description = "Command used by operators to retrieve kubeconfig."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
