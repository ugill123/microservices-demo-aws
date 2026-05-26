# Database Module

Creates Amazon ElastiCache Redis for the cart service.

## Resources Created

- ElastiCache subnet group
- ElastiCache Redis replication group (single node or multi-AZ)
- Secrets Manager secret storing the Redis connection string

## Usage

```hcl
module "database" {
  source = "../../modules/database"

  project_name             = "online-boutique"
  environment              = "dev"
  database_subnet_ids      = module.networking.database_subnet_ids
  redis_security_group_id  = module.networking.redis_security_group_id
  redis_node_type          = "cache.t4g.micro"
  redis_num_cache_clusters = 1
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | — |
| environment | Environment name | string | — |
| database_subnet_ids | Subnet IDs for Redis | list(string) | — |
| redis_security_group_id | Security group for Redis | string | — |
| redis_node_type | Instance type | string | cache.t4g.micro |
| redis_num_cache_clusters | Number of clusters (1=dev, 2=prod with replica) | number | 1 |

## Outputs

| Name | Description |
|------|-------------|
| redis_endpoint | Primary endpoint address |
| redis_port | Redis port (6379) |
| redis_connection_string | Full host:port string |
| redis_secret_arn | Secrets Manager secret ARN |
