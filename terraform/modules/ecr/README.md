# ECR Module

Creates Amazon ECR repositories for all microservices in the shared account.

## Resources Created

- 11 ECR repositories (one per microservice)
- Lifecycle policies (keep last 10 images)
- Cross-account pull policies (dev, staging, prod accounts can pull)

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project_name = "online-boutique"
  service_names = [
    "frontend", "cartservice", "productcatalogservice",
    "currencyservice", "paymentservice", "shippingservice",
    "emailservice", "checkoutservice", "recommendationservice",
    "adservice", "loadgenerator"
  ]
  cross_account_arns = [
    "arn:aws:iam::723239944580:root",
    "arn:aws:iam::716911968999:root",
    "arn:aws:iam::288280712573:root"
  ]
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | — |
| service_names | List of service names | list(string) | — |
| cross_account_arns | Account ARNs for cross-account pull | list(string) | [] |
| force_delete | Force delete repos with images | bool | false |

## Outputs

| Name | Description |
|------|-------------|
| repository_urls | Map of service name → ECR repo URL |
| registry_id | ECR registry ID (account ID) |
| registry_url | ECR registry base URL |
