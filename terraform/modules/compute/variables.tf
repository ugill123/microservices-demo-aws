variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_frontend_security_group_id" {
  description = "Security group ID for frontend ECS tasks"
  type        = string
}

variable "ecs_backend_security_group_id" {
  description = "Security group ID for backend ECS tasks"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the ALB target group for frontend"
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry URL (e.g., 099576492599.dkr.ecr.us-east-1.amazonaws.com)"
  type        = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs the execution role can access"
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "service_names" {
  description = "List of all service names (for log group creation)"
  type        = list(string)
}

variable "services" {
  description = "List of service configurations"
  type = list(object({
    name                 = string
    cpu                  = number
    memory               = number
    port                 = optional(number)
    desired_count        = number
    max_count            = optional(number, 4)
    is_frontend          = optional(bool, false)
    use_spot             = optional(bool, false)
    enable_autoscaling   = optional(bool, false)
    service_connect_port = optional(number)
    environment          = optional(map(string), {})
    secrets              = optional(map(string))
    health_check         = optional(list(string))
  }))
}
