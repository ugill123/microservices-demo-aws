# Compute Module

Creates the ECS cluster, task definitions, services, and auto-scaling for all 11 microservices.

## Resources Created

- ECS Cluster with Fargate + Fargate Spot capacity providers
- AWS Cloud Map HTTP namespace (Service Connect)
- CloudWatch log groups (one per service)
- IAM Task Execution Role (ECR pull, logs, secrets)
- IAM Task Role (X-Ray, CloudWatch metrics)
- ECS Task Definitions (one per service)
- ECS Services with Service Connect enabled
- Auto-scaling targets and CPU-based policies

## Usage

```hcl
module "compute" {
  source = "../../modules/compute"

  project_name                   = "online-boutique"
  environment                    = "dev"
  aws_region                     = "us-east-1"
  private_subnet_ids             = module.networking.private_subnet_ids
  ecs_frontend_security_group_id = module.networking.ecs_frontend_security_group_id
  ecs_backend_security_group_id  = module.networking.ecs_backend_security_group_id
  frontend_target_group_arn      = module.load_balancer.frontend_target_group_arn
  ecr_registry                   = "099576492599.dkr.ecr.us-east-1.amazonaws.com"
  secrets_arns                   = [module.database.redis_secret_arn]
  log_retention_days             = 30
  service_names                  = ["frontend", "cartservice", ...]

  services = [
    {
      name          = "frontend"
      cpu           = 256
      memory        = 512
      port          = 8080
      desired_count = 1
      is_frontend   = true
      environment   = { PORT = "8080", ... }
    },
    ...
  ]
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | — |
| environment | Environment name | string | — |
| aws_region | AWS region | string | — |
| private_subnet_ids | Private subnet IDs | list(string) | — |
| ecs_frontend_security_group_id | Frontend SG ID | string | — |
| ecs_backend_security_group_id | Backend SG ID | string | — |
| frontend_target_group_arn | ALB target group ARN | string | — |
| ecr_registry | ECR registry URL | string | — |
| secrets_arns | Secrets Manager ARNs | list(string) | ["*"] |
| log_retention_days | Log retention | number | 30 |
| service_names | Service names for log groups | list(string) | — |
| services | Service configurations | list(object) | — |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ECS cluster ID |
| cluster_name | ECS cluster name |
| service_discovery_namespace_arn | Cloud Map namespace ARN |
| task_execution_role_arn | Execution role ARN |
| task_role_arn | Task role ARN |
| service_names | Map of service names to ECS service names |
