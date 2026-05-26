# --- Networking ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

# --- Load Balancer ---
output "alb_dns_name" {
  description = "ALB DNS name (access the frontend here)"
  value       = module.load_balancer.alb_dns_name
}

# --- Database ---
output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = module.database.redis_endpoint
}

# --- Compute ---
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.compute.cluster_name
}
