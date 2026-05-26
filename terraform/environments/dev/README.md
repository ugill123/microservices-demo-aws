# Dev Environment

Deploys the full Online Boutique infrastructure in the dev AWS account (723239944580).

## Resources

- VPC with public/private/database subnets (2 AZs)
- NAT Gateway (single)
- Application Load Balancer
- ECS Cluster (Fargate) with 11 services
- ElastiCache Redis (single node, cache.t4g.micro)
- CloudWatch log groups
- IAM roles (task execution + task)
- Service Connect namespace

## Prerequisites

- Shared environment deployed first (ECR repos must exist)
- `Terraform-Deploy-Role` IAM role exists in dev account
- Docker images pushed to ECR

## Deploy

```bash
cd terraform/scripts
./deploy.sh dev plan
./deploy.sh dev apply
```

## Access

After deploy, access the frontend via the ALB DNS name:
```bash
terraform output alb_dns_name
```

## Cost

~$120/month (single-AZ, 1 task per service, no auto-scaling)

## Destroy

```bash
./deploy.sh dev destroy
```
