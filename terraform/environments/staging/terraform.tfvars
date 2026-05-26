# =============================================================================
# Staging Environment Configuration
# =============================================================================

# --- Account & Auth ---
sso_profile       = "usman-personal-shared-account"
target_account_id = "716911968999"
environment       = "staging"
project_name      = "online-boutique"

# --- Networking ---
vpc_cidr              = "10.1.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs  = ["10.1.10.0/24", "10.1.20.0/24"]
database_subnet_cidrs = ["10.1.100.0/24", "10.1.200.0/24"]
nat_gateway_count     = 2

# --- Database ---
redis_node_type          = "cache.t4g.small"
redis_num_cache_clusters = 1

# --- Load Balancer ---
certificate_arn = ""

# --- Compute ---
ecr_registry           = "099576492599.dkr.ecr.us-east-1.amazonaws.com"
frontend_desired_count = 1
default_desired_count  = 1
enable_autoscaling     = true
enable_loadgenerator   = false
log_retention_days     = 60
