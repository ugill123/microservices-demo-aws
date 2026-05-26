# Staging Environment

Deploys the Online Boutique infrastructure in the staging AWS account (716911968999).

## Configuration Differences from Dev

- Multi-AZ (2 NAT gateways)
- Auto-scaling enabled (min=1, max=3)
- ElastiCache: cache.t4g.small
- HTTPS enabled (ACM certificate required)

## Deploy

```bash
cd terraform/scripts
./deploy.sh staging plan
./deploy.sh staging apply
```
