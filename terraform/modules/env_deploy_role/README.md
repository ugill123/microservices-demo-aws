# Environment Deploy Role Module

Creates `GitHubActions-Deploy-Role` in dev/staging/prod accounts, trusted by the GitHub Actions role in the shared account.

## Resources

- IAM Role with trust policy allowing the shared account's GitHub Actions role
- Policy for ECS service updates and task definition operations

## Usage

```hcl
module "env_deploy_role" {
  source = "../../modules/env_deploy_role"

  shared_account_id = "099576492599"
  shared_role_name  = "online-boutique-github-actions-deploy"
}
```
