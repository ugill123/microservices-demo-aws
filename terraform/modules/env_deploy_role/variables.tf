variable "shared_account_id" {
  description = "AWS account ID where the source role lives"
  type        = string
}

variable "shared_role_name" {
  description = "Name of the IAM role in the shared account that can assume this role"
  type        = string
  default     = "online-boutique-github-actions-deploy"
}
