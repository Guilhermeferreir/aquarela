output "github_oidc_provider_arn" {
  description = "OIDC provider ARN that trusts token.actions.githubusercontent.com."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions using OIDC."
  value       = aws_iam_role.github_actions.arn
}
