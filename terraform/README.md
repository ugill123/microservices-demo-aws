# Terraform — AWS ECS Infrastructure

Multi-account Terraform setup for deploying Online Boutique on AWS ECS Fargate.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                 AWS ORGANIZATION                     │
│                                                     │
│  ┌──────────┐  ┌──────┐  ┌───────┐  ┌──────┐      │
│  │  SHARED  │  │ DEV  │  │ STAGE │  │ PROD │      │
│  │          │  │      │  │       │  │      │      │
│  │  ECR     │  │ VPC  │  │ VPC   │  │ VPC  │      │
│  │  OIDC    │  │ ECS  │  │ ECS   │  │ ECS  │      │
│  │  S3 State│  │ ALB  │  │ ALB   │  │ ALB  │      │
│  │  DynamoDB│  │ Redis│  │ Redis │  │ Redis│      │
│  └──────────┘  └──────┘  └───────┘  └──────┘      │
└─────────────────────────────────────────────────────┘
```

## Structure

```
terraform/
├── environments/
│   ├── shared/     # ECR repos, GitHub OIDC (account: 099576492599)
│   ├── dev/        # Full infra, minimal sizing (account: 723239944580)
│   ├── staging/    # Full infra, mid sizing (account: 716911968999)
│   └── prod/       # Full infra, HA sizing (account: 288280712573)
├── modules/
│   ├── networking/     # VPC, subnets, NAT, security groups
│   ├── compute/        # ECS cluster, services, auto-scaling
│   ├── database/       # ElastiCache Redis
│   ├── load_balancer/  # ALB, target groups, listeners
│   ├── ecr/            # ECR repositories
│   └── github_oidc/    # OIDC provider, IAM roles
└── scripts/
    └── deploy.sh       # Deployment wrapper script
```

## Quick Start

```bash
# 1. Deploy shared resources (one-time)
./scripts/deploy.sh shared apply

# 2. Deploy dev environment
./scripts/deploy.sh dev apply

# 3. Push Docker images to ECR, then ECS services start
```

## Authentication

- Local: AWS SSO profile assumes `Terraform-Deploy-Role` in target accounts
- CI/CD: GitHub OIDC → IAM role (no static credentials)
- State: Stored in shared account S3 with DynamoDB locking

## Modules

| Module | Description |
|--------|-------------|
| [networking](modules/networking/) | VPC, subnets, NAT, IGW, security groups |
| [compute](modules/compute/) | ECS cluster, task definitions, services, IAM |
| [database](modules/database/) | ElastiCache Redis, Secrets Manager |
| [load_balancer](modules/load_balancer/) | ALB, target groups, listeners |
| [ecr](modules/ecr/) | ECR repositories with cross-account access |
| [github_oidc](modules/github_oidc/) | GitHub Actions OIDC authentication |
