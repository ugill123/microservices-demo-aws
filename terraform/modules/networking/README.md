# Networking Module

Creates the VPC and all networking infrastructure for the Online Boutique application.

## Resources Created

- VPC with DNS support and hostnames enabled
- Public subnets (ALB, NAT Gateways)
- Private subnets (ECS Fargate tasks)
- Database subnets (ElastiCache Redis)
- Internet Gateway
- NAT Gateway(s) with Elastic IPs
- Route tables (public, private, database)
- Security Groups:
  - `alb` — allows HTTP/HTTPS from internet, egress to frontend
  - `ecs_frontend` — allows traffic from ALB, egress to backend services
  - `ecs_backend` — allows gRPC from frontend + inter-backend, egress to Redis
  - `redis` — allows port 6379 from backend only

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name          = "online-boutique"
  environment           = "dev"
  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24"]
  nat_gateway_count     = 1
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name for resource naming | string | — |
| environment | Environment name (dev, staging, prod) | string | — |
| vpc_cidr | CIDR block for the VPC | string | 10.0.0.0/16 |
| availability_zones | List of AZs | list(string) | — |
| public_subnet_cidrs | CIDRs for public subnets | list(string) | — |
| private_subnet_cidrs | CIDRs for private subnets | list(string) | — |
| database_subnet_cidrs | CIDRs for database subnets | list(string) | — |
| nat_gateway_count | Number of NAT gateways | number | 1 |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| database_subnet_ids | Database subnet IDs |
| alb_security_group_id | ALB security group ID |
| ecs_frontend_security_group_id | Frontend SG ID |
| ecs_backend_security_group_id | Backend SG ID |
| redis_security_group_id | Redis SG ID |
