# Prod Environment

Deploys the Online Boutique infrastructure in the production AWS account (288280712573).

## Configuration Differences from Dev

- Multi-AZ (2 NAT gateways)
- Auto-scaling enabled (min=2, max=10 for frontend)
- ElastiCache: cache.t4g.small with multi-AZ replica
- HTTPS enabled with ACM certificate
- ALB deletion protection enabled
- Snapshot retention on Redis (7 days)
- Log retention: 90 days

## Deploy

```bash
cd terraform/scripts
./deploy.sh prod plan
./deploy.sh prod apply
```

## Warning

Production changes require careful review. Always run `plan` first and verify the output before applying.
