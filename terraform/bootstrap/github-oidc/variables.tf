variable "region" {
  description = "AWS region used to create the GitHub OIDC provider and CI role."
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "Repository name that is allowed to assume the role."
  type        = string
}

variable "github_branch" {
  description = "Protected branch allowed to assume the role."
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "IAM role name assumed by GitHub Actions."
  type        = string
  default     = "aquarela-github-actions"
}

variable "additional_subjects" {
  description = "Optional extra OIDC sub claims, such as environment-based subjects."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags applied to the created resources."
  type        = map(string)
  default     = {}
}
