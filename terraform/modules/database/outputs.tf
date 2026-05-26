output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}

output "redis_connection_string" {
  description = "Full Redis connection string (host:port)"
  value       = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
}

output "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis endpoint"
  value       = aws_secretsmanager_secret.redis_endpoint.arn
}
