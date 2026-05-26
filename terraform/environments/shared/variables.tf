variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "sso_profile" {
  description = "The AWS SSO profile name configured on your local machine"
  type        = string
}

variable "target_account_id" {
  description = "The 12-digit AWS Account ID for the shared account"
  type        = string
}

variable "deploy_role_name" {
  description = "The IAM role name to assume in the target account"
  type        = string
  default     = "Terraform-Deploy-Role"
}

variable "project_name" {
  description = "The base name of the project"
  type        = string
}

variable "service_names" {
  description = "List of microservice names for ECR repos"
  type        = list(string)
  default = [
    "frontend",
    "cartservice",
    "productcatalogservice",
    "currencyservice",
    "paymentservice",
    "shippingservice",
    "emailservice",
    "checkoutservice",
    "recommendationservice",
    "adservice",
    "loadgenerator"
  ]
}

variable "cross_account_arns" {
  description = "List of account root ARNs allowed to pull from ECR"
  type        = list(string)
  default     = []
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "env_account_ids" {
  description = "List of environment account IDs (dev, staging, prod) the GitHub Actions role can assume into"
  type        = list(string)
  default     = []
}
