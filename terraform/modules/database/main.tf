# =============================================================================
# ElastiCache Redis Subnet Group
# =============================================================================
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-${var.environment}-redis"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-subnet-group"
  }
}

# =============================================================================
# ElastiCache Redis Replication Group
# =============================================================================
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "Redis for ${var.project_name} ${var.environment} - cart service"

  node_type            = var.redis_node_type
  num_cache_clusters   = var.redis_num_cache_clusters
  port                 = 6379
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.redis_security_group_id]

  automatic_failover_enabled = var.redis_num_cache_clusters > 1
  multi_az_enabled           = var.redis_num_cache_clusters > 1

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  snapshot_retention_limit = var.environment == "prod" ? 7 : 0

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }
}

# =============================================================================
# Store Redis endpoint in Secrets Manager
# =============================================================================
resource "aws_secretsmanager_secret" "redis_endpoint" {
  name                    = "${var.project_name}/${var.environment}/redis-endpoint"
  description             = "Redis primary endpoint for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-endpoint"
  }
}

resource "aws_secretsmanager_secret_version" "redis_endpoint" {
  secret_id     = aws_secretsmanager_secret.redis_endpoint.id
  secret_string = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
}
