variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "shared_account_id" {
  description = "AWS account ID where ECR repos live"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "target_account_ids" {
  description = "List of target environment account IDs (dev, staging, prod) that this role can assume into"
  type        = list(string)
  default     = []
}
