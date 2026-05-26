# Deploy Scripts

Helper scripts for deploying Terraform across environments.

## Usage

```bash
./deploy.sh <environment> <action>
```

### Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| environment | `shared`, `dev`, `staging`, `prod` | Target environment |
| action | `plan`, `apply`, `destroy` | Terraform action (default: plan) |

### Examples

```bash
# Preview changes in dev
./deploy.sh dev plan

# Apply changes to dev
./deploy.sh dev apply

# Destroy dev infrastructure
./deploy.sh dev destroy

# Deploy shared resources (ECR, OIDC)
./deploy.sh shared apply
```

## Deployment Order

1. `./deploy.sh shared apply` — ECR repos + GitHub OIDC (first time only)
2. `./deploy.sh dev apply` — Dev infrastructure
3. `./deploy.sh staging apply` — Staging infrastructure
4. `./deploy.sh prod apply` — Production infrastructure

## How It Works

- `shared` uses local state (the state bucket already exists)
- All other environments use remote S3 backend with DynamoDB locking
- Backend config is loaded from `backend.hcl` in each environment directory
