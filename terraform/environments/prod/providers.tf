provider "aws" {
  region  = var.aws_region
  profile = var.sso_profile

  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/${var.deploy_role_name}"
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
