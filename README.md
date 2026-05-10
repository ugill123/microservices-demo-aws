# Online Boutique — AWS ECS Fargate Deployment

**Online Boutique** is a cloud-first microservices demo application. It's a web-based e-commerce app where users can browse items, add them to the cart, and purchase them.

This repository contains the **AWS ECS Fargate** deployment of the application, migrated from the original Google Kubernetes Engine (GKE) demo to run on AWS serverless containers with production-grade infrastructure.

## Architecture

Online Boutique is composed of **11 microservices** written in different languages that communicate over **gRPC**, with a single HTTP frontend served via an Application Load Balancer.

[![Architecture Diagram](/docs/img/architecture-diagram.png)](/docs/img/architecture-diagram.png)

### Services

| Service | Language | Port | Protocol | Description |
|---------|----------|------|----------|-------------|
| [frontend](/src/frontend) | Go | 8080 | HTTP | Web UI, proxies to all backend services |
| [cartservice](/src/cartservice) | C# | 7070 | gRPC | Shopping cart (backed by Redis/ElastiCache) |
| [productcatalogservice](/src/productcatalogservice) | Go | 3550 | gRPC | Product listing from embedded JSON |
| [currencyservice](/src/currencyservice) | Node.js | 7000 | gRPC | Currency conversion using ECB rates |
| [paymentservice](/src/paymentservice) | Node.js | 50051 | gRPC | Mock payment processing |
| [shippingservice](/src/shippingservice) | Go | 50051 | gRPC | Shipping cost estimates |
| [emailservice](/src/emailservice) | Python | 8080 | gRPC | Mock order confirmation emails |
| [checkoutservice](/src/checkoutservice) | Go | 5050 | gRPC | Orchestrates the checkout flow |
| [recommendationservice](/src/recommendationservice) | Python | 8080 | gRPC | Product recommendations |
| [adservice](/src/adservice) | Java | 9555 | gRPC | Context-based text ads |
| [loadgenerator](/src/loadgenerator) | Python/Locust | — | HTTP | Synthetic load testing |

## AWS Infrastructure

This deployment targets **AWS ECS Fargate** in `us-east-1` with the following services:

| Component | AWS Service |
|-----------|-------------|
| Container orchestration | Amazon ECS (Fargate) |
| Container registry | Amazon ECR |
| Service discovery | ECS Service Connect (AWS Cloud Map) |
| Load balancing | Application Load Balancer (ALB) |
| Cache/data store | Amazon ElastiCache for Redis |
| Secrets | AWS Secrets Manager |
| Observability | CloudWatch, X-Ray, ADOT, AMP, Grafana |
| CI/CD | GitHub Actions with OIDC authentication |

### Network Architecture

```
Internet → ALB (:443) → frontend (:8080) → gRPC → backend services
                                                        │
                                                        ▼
                                              ElastiCache Redis (:6379)
```

- **VPC:** 10.0.0.0/16 with public, private, and database subnets across 2 AZs
- **ECS Tasks:** Run in private subnets, no public IPs
- **ElastiCache:** Isolated in database subnets, accessible only from backend tasks
- **ALB:** Internet-facing in public subnets, forwards to frontend only

## Deployment

### Prerequisites

- AWS account with appropriate permissions
- AWS CLI configured
- Docker installed locally
- GitHub repository with OIDC configured for AWS

### Quick Start

1. **Create ECR repositories** for all 11 services
2. **Build and push** Docker images to ECR
3. **Provision infrastructure** (VPC, ECS cluster, ALB, ElastiCache)
4. **Register task definitions** and create ECS services
5. **Verify** the frontend is accessible via ALB

For the complete step-by-step deployment guide, see:
- [AWS ECS Deployment Plan](/docs/aws-ecs-deployment-plan.md)

### CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy-ecs.yml`) handles:
- Path-based change detection (only rebuilds modified services)
- OIDC authentication to AWS (no static credentials)
- Docker build and push to ECR
- ECS rolling deployment with health check validation

## Project Structure

```
├── src/                          # Microservice source code (11 services)
│   ├── frontend/                 # Go — HTTP web UI
│   ├── cartservice/              # C# — Shopping cart
│   ├── productcatalogservice/    # Go — Product catalog
│   ├── currencyservice/          # Node.js — Currency conversion
│   ├── paymentservice/           # Node.js — Payment processing
│   ├── shippingservice/          # Go — Shipping estimates
│   ├── emailservice/             # Python — Email notifications
│   ├── checkoutservice/          # Go — Checkout orchestration
│   ├── recommendationservice/    # Python — Recommendations
│   ├── adservice/                # Java — Advertisements
│   └── loadgenerator/            # Python — Load testing
├── protos/                       # gRPC Protocol Buffer definitions
├── docs/                         # Documentation
│   └── aws-ecs-deployment-plan.md  # Complete AWS deployment plan
├── .github/                      # GitHub templates and workflows
└── README.md
```

## Observability

Each ECS task includes an **ADOT (AWS Distro for OpenTelemetry) sidecar** that collects:
- **Traces** → AWS X-Ray (distributed tracing across all services)
- **Metrics** → CloudWatch Metrics + Amazon Managed Prometheus
- **Logs** → CloudWatch Logs (via `awslogs` driver)

Dashboards are available in **Amazon Managed Grafana**.

## Cost Estimates

| Environment | Monthly Cost | Notes |
|-------------|-------------|-------|
| **Dev** | ~$120 | Single-AZ, 1 task per service, t4g.micro Redis |
| **Prod** | ~$350 | Multi-AZ, 2+ tasks, auto-scaling, HA Redis |

See the [deployment plan](/docs/aws-ecs-deployment-plan.md#7-cost-estimate--interview-talking-points) for detailed breakdowns and optimization tips.

## Documentation

- [AWS ECS Deployment Plan](/docs/aws-ecs-deployment-plan.md) — Complete infrastructure, networking, task definitions, CI/CD, observability, and cost analysis
- [Development Guide](/docs/development-guide.md) — Local development setup
- [Adding a New Microservice](/docs/adding-new-microservice.md) — Guide for extending the application
- [Product Requirements](/docs/product-requirements.md) — Feature specifications

## Screenshots

| Home Page | Checkout Screen |
|-----------|-----------------|
| [![Store homepage](/docs/img/online-boutique-frontend-1.png)](/docs/img/online-boutique-frontend-1.png) | [![Checkout screen](/docs/img/online-boutique-frontend-2.png)](/docs/img/online-boutique-frontend-2.png) |

## License

This project is licensed under the [Apache License 2.0](/LICENSE).

---

*Originally forked from [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) and migrated to AWS ECS Fargate.*
