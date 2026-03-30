variable "project_name" {
  description = "Project slug used in AWS resource names."
  type        = string
  default     = "aquarela"
}

variable "environment" {
  description = "Environment name used in tags and resource names."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region where the EKS cluster will be provisioned."
  type        = string
}

variable "kubernetes_version" {
  description = "Pinned Kubernetes version for EKS."
  type        = string
  default     = "1.34"
}

variable "azs_count" {
  description = "Number of availability zones used by the VPC."
  type        = number
  default     = 3
}

variable "use_existing_vpc" {
  description = "Reuse an existing VPC and subnets instead of creating a new dedicated VPC."
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID used when use_existing_vpc is true."
  type        = string
  default     = null
}

variable "existing_public_subnet_name_tags" {
  description = "Name tags of existing public subnets used for public load balancers."
  type        = list(string)
  default     = []
}

variable "existing_private_subnet_name_tags" {
  description = "Name tags of existing private subnets used by the worker nodes."
  type        = list(string)
  default     = []
}

variable "existing_control_plane_subnet_name_tags" {
  description = "Optional name tags of existing subnets dedicated to the EKS control plane. Defaults to the private subnets when omitted."
  type        = list(string)
  default     = []
}

variable "use_existing_desafio_aquarela_user" {
  description = "Reuse an existing IAM user named desafio_aquarela instead of creating a new one."
  type        = bool
  default     = false
}

variable "existing_desafio_aquarela_user_name" {
  description = "Existing IAM user name used when use_existing_desafio_aquarela_user is true."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block used by the dedicated VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "endpoint_public_access" {
  description = "Whether the EKS API endpoint should be public."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict this in real environments."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group_instance_types" {
  description = "Instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "node_group_disk_size" {
  description = "Root volume size for the worker nodes."
  type        = number
  default     = 50
}

variable "cluster_admin_principal_arns" {
  description = "Stable EKS admin principals managed explicitly through access entries."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags applied to the infrastructure."
  type        = map(string)
  default     = {}
}