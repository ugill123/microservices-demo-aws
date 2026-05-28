variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the observability VPC"
  type        = string
  default     = "10.99.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.99.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "data_volume_size_gb" {
  description = "Size of EBS data volume for Grafana persistence"
  type        = number
  default     = 20
}

variable "allowed_ip_cidr" {
  description = "Your public IP CIDR for accessing Grafana/Prometheus (e.g., 1.2.3.4/32)"
  type        = string
}

variable "monitored_account_ids" {
  description = "List of AWS account IDs the observability server can scrape (via assume role)"
  type        = list(string)
  default     = []
}
