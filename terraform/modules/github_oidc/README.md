# GitHub OIDC Module

Creates the GitHub Actions OIDC provider and IAM role for keyless CI/CD authentication.

## Resources Created

- IAM OIDC Identity Provider for GitHub Actions
- IAM Role with trust policy scoped to your repository
- ECR push policy (build and push images)
- ECS deploy policy (register task definitions, update services)

## Usage

```hcl
module "github_oidc" {
  source = "../../modules/github_oidc"

  project_name      = "online-boutique"
  aws_region        = "us-east-1"
  shared_account_id = "099576492599"
  github_org        = "your-username"
  github_repo       = "microservices-demo-aws"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | — |
| aws_region | AWS region | string | — |
| shared_account_id | Account ID where ECR lives | string | — |
| github_org | GitHub org or username | string | — |
| github_repo | GitHub repository name | string | — |

## Outputs

| Name | Description |
|------|-------------|
| oidc_provider_arn | OIDC provider ARN |
| deploy_role_arn | GitHub Actions deploy role ARN |
| deploy_role_name | GitHub Actions deploy role name |

## GitHub Actions Usage

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: <deploy_role_arn output>
    aws-region: us-east-1
```
