# =============================================================================
# ECR Repositories (shared account — all environments pull from here)
# =============================================================================
module "ecr" {
  source = "../../modules/ecr"

  project_name       = var.project_name
  service_names      = var.service_names
  cross_account_arns = var.cross_account_arns
  force_delete       = false
}

# =============================================================================
# GitHub OIDC + IAM role (in shared account)
# =============================================================================
module "github_oidc" {
  source = "../../modules/github_oidc"

  project_name       = var.project_name
  aws_region         = var.aws_region
  shared_account_id  = var.target_account_id
  github_org         = var.github_org
  github_repo        = var.github_repo
  target_account_ids = var.env_account_ids
}
