# =============================================================================
# Networking
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  nat_gateway_count     = var.nat_gateway_count
}

# =============================================================================
# Database (ElastiCache Redis)
# =============================================================================
module "database" {
  source = "../../modules/database"

  project_name             = var.project_name
  environment              = var.environment
  database_subnet_ids      = module.networking.database_subnet_ids
  redis_security_group_id  = module.networking.redis_security_group_id
  redis_node_type          = var.redis_node_type
  redis_num_cache_clusters = var.redis_num_cache_clusters
}

# =============================================================================
# Load Balancer
# =============================================================================
module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  certificate_arn       = var.certificate_arn
}

# =============================================================================
# Compute (ECS)
# =============================================================================
module "compute" {
  source = "../../modules/compute"

  project_name                   = var.project_name
  environment                    = var.environment
  aws_region                     = var.aws_region
  private_subnet_ids             = module.networking.private_subnet_ids
  ecs_frontend_security_group_id = module.networking.ecs_frontend_security_group_id
  ecs_backend_security_group_id  = module.networking.ecs_backend_security_group_id
  frontend_target_group_arn      = module.load_balancer.frontend_target_group_arn
  ecr_registry                   = var.ecr_registry
  secrets_arns                   = [module.database.redis_secret_arn]
  log_retention_days             = var.log_retention_days
  service_names                  = var.service_names

  services = [
    {
      name               = "frontend"
      cpu                = 256
      memory             = 512
      port               = 8080
      desired_count      = var.frontend_desired_count
      max_count          = 10
      is_frontend        = true
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT                            = "8080"
        PRODUCT_CATALOG_SERVICE_ADDR    = "productcatalogservice.${var.project_name}.local:3550"
        CURRENCY_SERVICE_ADDR           = "currencyservice.${var.project_name}.local:7000"
        CART_SERVICE_ADDR               = "cartservice.${var.project_name}.local:7070"
        RECOMMENDATION_SERVICE_ADDR     = "recommendationservice.${var.project_name}.local:8080"
        SHIPPING_SERVICE_ADDR           = "shippingservice.${var.project_name}.local:50051"
        CHECKOUT_SERVICE_ADDR           = "checkoutservice.${var.project_name}.local:5050"
        AD_SERVICE_ADDR                 = "adservice.${var.project_name}.local:9555"
        SHOPPING_ASSISTANT_SERVICE_ADDR = "shoppingassistantservice.${var.project_name}.local:8080"
        ENV_PLATFORM                    = "aws"
        ENABLE_PROFILER                 = "0"
      }
    },
    {
      name               = "cartservice"
      cpu                = 512
      memory             = 1024
      port               = 7070
      desired_count      = var.default_desired_count
      max_count          = 6
      enable_autoscaling = var.enable_autoscaling
      environment = {
        REDIS_ADDR = module.database.redis_connection_string
      }
    },
    {
      name               = "productcatalogservice"
      cpu                = 256
      memory             = 512
      port               = 3550
      desired_count      = var.default_desired_count
      max_count          = 6
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT             = "3550"
        DISABLE_PROFILER = "1"
      }
    },
    {
      name               = "currencyservice"
      cpu                = 256
      memory             = 512
      port               = 7000
      desired_count      = var.default_desired_count
      max_count          = 4
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT             = "7000"
        DISABLE_PROFILER = "1"
      }
    },
    {
      name               = "paymentservice"
      cpu                = 256
      memory             = 512
      port               = 50051
      desired_count      = var.default_desired_count
      max_count          = 4
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT             = "50051"
        DISABLE_PROFILER = "1"
      }
    },
    {
      name               = "shippingservice"
      cpu                = 256
      memory             = 512
      port               = 50051
      desired_count      = var.default_desired_count
      max_count          = 4
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT             = "50051"
        DISABLE_PROFILER = "1"
      }
    },
    {
      name               = "emailservice"
      cpu                = 256
      memory             = 512
      port               = 8080
      desired_count      = var.default_desired_count
      max_count          = 4
      service_connect_port = 5000
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT             = "8080"
        DISABLE_PROFILER = "1"
      }
    },
    {
      name               = "checkoutservice"
      cpu                = 256
      memory             = 512
      port               = 5050
      desired_count      = var.default_desired_count
      max_count          = 6
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT                         = "5050"
        PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice.${var.project_name}.local:3550"
        SHIPPING_SERVICE_ADDR        = "shippingservice.${var.project_name}.local:50051"
        PAYMENT_SERVICE_ADDR         = "paymentservice.${var.project_name}.local:50051"
        EMAIL_SERVICE_ADDR           = "emailservice.${var.project_name}.local:5000"
        CURRENCY_SERVICE_ADDR        = "currencyservice.${var.project_name}.local:7000"
        CART_SERVICE_ADDR            = "cartservice.${var.project_name}.local:7070"
      }
    },
    {
      name               = "recommendationservice"
      cpu                = 256
      memory             = 1024
      port               = 8080
      desired_count      = var.default_desired_count
      max_count          = 4
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT                         = "8080"
        PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice.${var.project_name}.local:3550"
        DISABLE_PROFILER             = "1"
      }
    },
    {
      name               = "adservice"
      cpu                = 512
      memory             = 1024
      port               = 9555
      desired_count      = var.default_desired_count
      max_count          = 4
      enable_autoscaling = var.enable_autoscaling
      environment = {
        PORT = "9555"
      }
    },
    {
      name          = "loadgenerator"
      cpu           = 512
      memory        = 1024
      port          = null
      desired_count = var.enable_loadgenerator ? 1 : 0
      use_spot      = true
      environment = {
        FRONTEND_ADDR = "frontend.${var.project_name}.local:8080"
        USERS         = "10"
        RATE          = "1"
      }
    }
  ]
}


# =============================================================================
# GitHub Actions Deploy Role (assumed by CI/CD from shared account)
# =============================================================================
module "github_actions_role" {
  source = "../../modules/env_deploy_role"

  shared_account_id = var.shared_account_id
}
