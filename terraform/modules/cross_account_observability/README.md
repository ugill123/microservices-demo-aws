# Cross-Account Observability Read Role

Creates the `Observability-CloudWatch-Read` IAM role in dev/staging/prod accounts,
trusted by the observability EC2 IAM role in the shared account.

## Usage

```hcl
module "observability_read" {
  source = "../../modules/cross_account_observability"

  observability_server_role_arn = "arn:aws:iam::099576492599:role/online-boutique-observability-server"
}
```

## Why?

The observability EC2 in shared needs to read CloudWatch metrics from monitored accounts.
Direct access isn't allowed across accounts — it must assume a role.

Permissions granted: `cloudwatch:GetMetricStatistics`, `cloudwatch:GetMetricData`,
`cloudwatch:ListMetrics`, `tag:GetResources`.
