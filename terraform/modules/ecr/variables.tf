variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "service_names" {
  description = "List of microservice names to create ECR repos for"
  type        = list(string)
}

variable "cross_account_arns" {
  description = "List of account root ARNs allowed to pull images"
  type        = list(string)
  default     = []
}

variable "force_delete" {
  description = "Force delete repositories even if they contain images"
  type        = bool
  default     = false
}
