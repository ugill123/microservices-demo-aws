# Observability Stack

Self-hosted Prometheus + Grafana running on the observability EC2 in the shared account.

## Components

- **Prometheus** (port 9090) — metrics storage, scrapes every 30s, retains 15 days
- **Grafana** (port 3000) — dashboards (default login: admin/admin)
- **Node Exporter** (port 9100) — host-level metrics
- **CloudWatch Exporter** (port 9106) — pulls AWS metrics from dev account

## Deploy

From your local machine, copy the config to the EC2 then start:

```bash
# 1. SSH into the observability server (via SSM)
aws ssm start-session --target <instance-id> --region us-east-1 --profile usman-personal-shared-account

# 2. Once on the server:
cd /home/ec2-user
git clone https://github.com/ugill123/microservices-demo-aws.git
cd microservices-demo-aws/observability
sudo docker compose up -d
```

## Verify

```bash
sudo docker compose ps
sudo docker compose logs -f prometheus
```

Access from your machine:
- Grafana: `http://<EIP>:3000` (admin / admin)
- Prometheus: `http://<EIP>:9090`

## Cross-Account Setup Required

Before Prometheus can scrape dev metrics, you need to create the IAM role
`Observability-CloudWatch-Read` in the dev account with:

- Trust: shared account observability EC2 IAM role
- Permissions: `cloudwatch:GetMetricStatistics`, `cloudwatch:ListMetrics`, `tag:GetResources`

This will be added to the dev environment's Terraform.
