# Observability Server Module

Provisions a single EC2 instance (Amazon Linux 2023, t3.small) in a dedicated VPC for running Prometheus + Grafana via Docker Compose.

## Resources Created

- VPC with single public subnet
- Internet Gateway + route table
- Security group (Grafana :3000, Prometheus :9090 from your IP only)
- EC2 instance (t3.small) with Docker + Docker Compose pre-installed
- EBS volume (20GB gp3) mounted at `/data` for persistence
- Elastic IP for stable access
- IAM role with SSM + CloudWatch read + cross-account assume permissions

## Access

This module uses **AWS SSM Session Manager** instead of SSH — no key pairs needed:

```bash
aws ssm start-session --target <instance-id> --region us-east-1 --profile usman-personal-shared-account
```

The `ssm_session_command` output gives you the exact command.

## Usage

```hcl
module "observability_server" {
  source = "../../modules/observability_server"

  project_name           = "online-boutique"
  aws_region             = "us-east-1"
  allowed_ip_cidr        = "1.2.3.4/32"  # Your public IP
  monitored_account_ids  = ["723239944580"]  # Dev account (add prod later)
}
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| project_name | Project name | — |
| aws_region | AWS region | — |
| vpc_cidr | VPC CIDR | 10.99.0.0/16 |
| public_subnet_cidr | Subnet CIDR | 10.99.1.0/24 |
| availability_zone | AZ | us-east-1a |
| instance_type | EC2 type | t3.small |
| data_volume_size_gb | EBS size | 20 |
| allowed_ip_cidr | Your IP for Grafana/Prometheus | — |
| monitored_account_ids | Accounts to scrape via cross-account assume | [] |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| public_ip | Elastic IP |
| grafana_url | http://<eip>:3000 |
| prometheus_url | http://<eip>:9090 |
| iam_role_arn | EC2 IAM role ARN |
| ssm_session_command | Ready-to-use SSM Session Manager command |

## Next Steps After Apply

1. Connect via SSM Session Manager
2. Verify Docker is running: `sudo systemctl status docker`
3. Check `/data` is mounted: `df -h /data`
4. Proceed to Task 4.2: deploy Docker Compose stack
