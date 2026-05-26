# Shared Environment

Deploys shared resources in the central AWS account (099576492599).

## Resources

- ECR repositories (11 — one per microservice)
- GitHub OIDC provider + IAM deploy role
- Cross-account ECR pull policies for dev/staging/prod

## Prerequisites

- AWS SSO profile `usman-personal-shared-account` configured
- S3 state bucket and DynamoDB lock table already exist

## Deploy

```bash
cd terraform/scripts
./deploy.sh shared plan
./deploy.sh shared apply
```

## Notes

- This environment uses local state (it doesn't need remote backend since the state bucket already exists externally)
- Update `github_org` in `terraform.tfvars` with your GitHub username before deploying
