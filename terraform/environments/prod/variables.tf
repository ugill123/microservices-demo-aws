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
  description = "The 12-digit AWS Account ID for this environment"
  type        = string
}

variable "deploy_role_name" {
  description = "The IAM role name to assume in the target account"
  type        = string
  default     = "Terraform-Deploy-Role"
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "project_name" {
  description = "The base name of the project"
  type        = string
}

# --- Networking ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways"
  type        = number
  default     = 2
}

# --- Database ---
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.small"
}

variable "redis_num_cache_clusters" {
  description = "Number of Redis cache clusters (2 = primary + replica for HA)"
  type        = number
  default     = 2
}

# --- Load Balancer ---
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

# --- Compute ---
variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
}

variable "service_names" {
  description = "List of all microservice names"
  type        = list(string)
  default = [
    "frontend", "cartservice", "productcatalogservice", "currencyservice",
    "paymentservice", "shippingservice", "emailservice", "checkoutservice",
    "recommendationservice", "adservice", "loadgenerator"
  ]
}

variable "frontend_desired_count" {
  description = "Desired task count for frontend"
  type        = number
  default     = 2
}

variable "default_desired_count" {
  description = "Default desired task count"
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling"
  type        = bool
  default     = true
}

variable "enable_loadgenerator" {
  description = "Enable load generator"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}


variable "shared_account_id" {
  description = "AWS account ID where the GitHub Actions OIDC role lives"
  type        = string
  default     = "099576492599"
}
