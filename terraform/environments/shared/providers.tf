provider "aws" {
  region  = var.aws_region
  profile = var.sso_profile

  default_tags {
    tags = {
      Environment = "shared"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
