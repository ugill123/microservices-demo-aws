# =============================================================================
# Shared Account Configuration
# =============================================================================

# --- Account & Auth ---
sso_profile       = "usman-personal-shared-account"
target_account_id = "099576492599"
project_name      = "online-boutique"

# --- GitHub (for OIDC) ---
github_org  = "ugill123"
github_repo = "microservices-demo-aws"

# --- Cross-account ECR pull access ---
cross_account_arns = [
  "arn:aws:iam::723239944580:root",
  "arn:aws:iam::716911968999:root",
  "arn:aws:iam::288280712573:root"
]

# --- Environment account IDs (for GitHub Actions cross-account assume) ---
env_account_ids = [
  "723239944580",
  "716911968999",
  "288280712573"
]
