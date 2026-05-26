# Load Balancer Module

Creates the Application Load Balancer for the frontend service.

## Resources Created

- Application Load Balancer (internet-facing)
- Target group for frontend (port 8080, health check on /_healthz)
- HTTP listener (port 80 — redirects to HTTPS if cert provided, otherwise forwards)
- HTTPS listener (port 443 — only if ACM certificate ARN is provided)

## Usage

```hcl
module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name          = "online-boutique"
  environment           = "dev"
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  certificate_arn       = ""  # Empty = HTTP only, set for HTTPS
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | — |
| environment | Environment name | string | — |
| vpc_id | VPC ID | string | — |
| public_subnet_ids | Public subnet IDs for ALB | list(string) | — |
| alb_security_group_id | Security group for ALB | string | — |
| certificate_arn | ACM cert ARN (empty to skip HTTPS) | string | "" |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ALB ARN |
| alb_dns_name | ALB DNS name (use this to access the app) |
| alb_zone_id | ALB hosted zone ID |
| frontend_target_group_arn | Target group ARN for frontend |
| http_listener_arn | HTTP listener ARN |
| https_listener_arn | HTTPS listener ARN (empty if no cert) |
