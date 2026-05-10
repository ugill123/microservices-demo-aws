# Online Boutique - Production-Grade AWS ECS Deployment Plan

> **Project:** Google Online Boutique (Microservices Demo)
> **Target Platform:** AWS ECS Fargate | Region: us-east-1
> **Author Role:** Principal Cloud Architect & DevOps Engineer

---

## TABLE OF CONTENTS

1. [Project Analysis](#1-project-analysis)
2. [Core AWS Infrastructure](#2-core-aws-infrastructure)
3. [Architecture & Networking](#3-architecture--networking)
4. [ECS Task Definitions](#4-ecs-task-definitions)
5. [CI/CD Pipeline (GitHub Actions)](#5-cicd-pipeline-github-actions)
6. [Observability (OpenTelemetry / ADOT / CloudWatch)](#6-observability)
7. [Cost Estimate & Interview Talking Points](#7-cost-estimate--interview-talking-points)
8. [AI-Powered DevOps Strategy](#8-ai-powered-devops-strategy)

---

## 1. PROJECT ANALYSIS

### 1.1 What Is This Application?

Online Boutique is a **polyglot microservices e-commerce application** originally built
by Google to demonstrate Kubernetes and cloud-native patterns. It consists of **11
application microservices** written in 5 different languages, communicating primarily
over **gRPC**, with a single HTTP frontend serving the web UI.

### 1.2 Microservices Inventory

| # | Service                  | Language | Port  | Protocol | Stateful? | Purpose                              |
|---|--------------------------|----------|-------|----------|-----------|--------------------------------------|
| 1 | **frontend**             | Go       | 8080  | HTTP     | No        | Web UI, proxies to all backends      |
| 2 | **cartservice**          | C# .NET  | 7070  | gRPC     | Yes*      | Shopping cart (backed by Redis)       |
| 3 | **productcatalogservice**| Go       | 3550  | gRPC     | No        | Product listing from embedded JSON    |
| 4 | **currencyservice**      | Node.js  | 7000  | gRPC     | No        | Currency conversion (ECB rates)       |
| 5 | **paymentservice**       | Node.js  | 50051 | gRPC     | No        | Mock payment processing               |
| 6 | **shippingservice**      | Go       | 50051 | gRPC     | No        | Shipping cost calculation             |
| 7 | **emailservice**         | Python   | 8080  | gRPC     | No        | Mock order confirmation emails        |
| 8 | **checkoutservice**      | Go       | 5050  | gRPC     | No        | Orchestrates the checkout flow        |
| 9 | **recommendationservice**| Python   | 8080  | gRPC     | No        | Product recommendations               |
|10 | **adservice**            | Java     | 9555  | gRPC     | No        | Context-based text ads                |
|11 | **loadgenerator**        | Python   | N/A   | HTTP     | No        | Locust-based synthetic load testing   |

*cartservice delegates state to Redis — the service itself is stateless.

### 1.3 Data Store

- **Redis** — used exclusively by `cartservice` for shopping cart persistence.
- In Kubernetes: runs as `redis-cart` (redis:alpine) on port 6379.
- **AWS replacement:** Amazon ElastiCache for Redis (Serverless or single-node).

### 1.4 Service Dependency Graph

```
                        ┌─────────────┐
                        │  FRONTEND   │ (HTTP :8080)
                        └──────┬──────┘
       ┌────────┬────────┬──┴──┬────────┬────────┬────────┐
       ▼        ▼        ▼     ▼        ▼        ▼        ▼
   adservice  cart   product  currency recommend shipping checkout
    (:9555)  (:7070) (:3550)  (:7000)  (:8080)  (:50051) (:5050)
              │                         │                   │
              ▼                         ▼        ┌──────────┼──────────┬──────────┬──────────┐
            Redis                    product      ▼          ▼          ▼          ▼          ▼
           (:6379)                   catalog   product    shipping   payment    email      currency
                                    (:3550)   catalog   (:50051)  (:50051)   (:5000→    (:7000)
                                              (:3550)                         8080)
                                                                            + cart(:7070)
```

### 1.5 Key Observations for AWS Migration

- **All services are already containerized** with multi-stage Dockerfiles (distroless/alpine).
- **gRPC everywhere** — ECS services will use AWS Cloud Map (Service Connect) for
  service-to-service discovery instead of Kubernetes DNS.
- **Only one stateful dependency** (Redis) — maps cleanly to ElastiCache.
- **No persistent volumes** — all services use read-only root filesystems.
- **No ingress controller needed** — ALB handles external HTTP traffic to frontend.
- **OpenTelemetry is already instrumented** in the codebase — we just need to point
  the OTLP exporter at an ADOT sidecar.

---

## 2. CORE AWS INFRASTRUCTURE

### 2.1 AWS Services Mapping

| K8s / Open-Source Component | AWS Replacement                     | Why                                          |
|-----------------------------|-------------------------------------|----------------------------------------------|
| Kubernetes cluster          | **Amazon ECS (Fargate)**            | Serverless containers, no node management    |
| Container registry          | **Amazon ECR**                      | Private registry, integrated with ECS/IAM    |
| Kubernetes Service (DNS)    | **ECS Service Connect (Cloud Map)** | Service-to-service discovery via DNS          |
| LoadBalancer Service        | **Application Load Balancer (ALB)** | HTTP/HTTPS ingress with health checks        |
| Redis pod (redis-cart)      | **Amazon ElastiCache for Redis**    | Managed, HA, automatic failover              |
| Kubernetes Secrets          | **AWS Secrets Manager**             | Encrypted secrets with rotation support      |
| ConfigMaps / env vars       | **ECS Task Definition env vars**    | Native ECS configuration                     |
| Istio / Service Mesh        | **ECS Service Connect**             | Built-in service mesh without sidecar proxy  |
| OTel Collector pod          | **ADOT Sidecar container**          | AWS Distro for OpenTelemetry in each task    |
| Kubernetes RBAC             | **IAM Roles (Task & Execution)**    | Fine-grained permissions per service         |
| kube-dns                    | **AWS Cloud Map**                   | Service discovery namespace                  |
| Horizontal Pod Autoscaler   | **ECS Auto Scaling (Target Tracking)** | Scale on CPU/memory/custom metrics        |

### 2.2 Complete AWS Service List

**Compute & Containers:**
- Amazon ECS (Fargate) — 11 services + 1 optional loadgenerator
- Amazon ECR — 11 private repositories (one per microservice)

**Networking:**
- Amazon VPC — custom VPC with public/private/database subnets
- Application Load Balancer (ALB) — internet-facing, for frontend
- NAT Gateway — for private subnet internet access (ECR pulls, etc.)
- AWS Cloud Map — service discovery namespace for gRPC routing

**Data:**
- Amazon ElastiCache for Redis — replaces redis-cart pod

**Security:**
- AWS Secrets Manager — Redis connection string, any future secrets
- AWS Certificate Manager (ACM) — TLS certificate for ALB HTTPS
- IAM Roles — ECS Task Role + Execution Role per service
- Security Groups — least-privilege network access

**Observability:**
- Amazon CloudWatch Logs — centralized log aggregation
- Amazon CloudWatch Metrics — ECS and custom metrics
- AWS X-Ray — distributed tracing
- Amazon Managed Service for Prometheus (AMP) — metrics storage
- Amazon Managed Grafana (AMG) — dashboards and visualization
- AWS Distro for OpenTelemetry (ADOT) — sidecar collector

**CI/CD:**
- GitHub Actions — build, push, deploy pipeline
- AWS IAM OIDC Provider — keyless GitHub Actions authentication

---

## 3. ARCHITECTURE & NETWORKING

### 3.1 Architecture Diagram (ASCII)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AWS REGION: us-east-1                               │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐   │
│  │                          VPC: 10.0.0.0/16                                │   │
│  │                                                                           │   │
│  │  ┌─────────────────────────────┐  ┌─────────────────────────────┐        │   │
│  │  │   PUBLIC SUBNET (AZ-a)      │  │   PUBLIC SUBNET (AZ-b)      │        │   │
│  │  │   10.0.1.0/24              │  │   10.0.2.0/24              │        │   │
│  │  │                             │  │                             │        │   │
│  │  │  ┌───────────────────────┐  │  │  ┌───────────────────────┐  │        │   │
│  │  │  │   ALB (internet-      │  │  │  │   ALB (target in      │  │        │   │
│  │  │  │   facing) :443/:80    │  │  │  │   this AZ too)        │  │        │   │
│  │  │  └───────────┬───────────┘  │  │  └───────────────────────┘  │        │   │
│  │  │              │              │  │                             │        │   │
│  │  │  ┌───────────┴───────────┐  │  │  ┌───────────────────────┐  │        │   │
│  │  │  │   NAT Gateway        │  │  │  │   NAT Gateway        │  │        │   │
│  │  │  └───────────────────────┘  │  │  └───────────────────────┘  │        │   │
│  │  └─────────────────────────────┘  └─────────────────────────────┘        │   │
│  │                                                                           │   │
│  │  ┌─────────────────────────────┐  ┌─────────────────────────────┐        │   │
│  │  │  PRIVATE SUBNET (AZ-a)     │  │  PRIVATE SUBNET (AZ-b)     │        │   │
│  │  │  10.0.10.0/24             │  │  10.0.20.0/24             │        │   │
│  │  │                             │  │                             │        │   │
│  │  │  ┌────────────────────┐     │  │  ┌────────────────────┐     │        │   │
│  │  │  │  ECS FARGATE TASKS │     │  │  │  ECS FARGATE TASKS │     │        │   │
│  │  │  │                    │     │  │  │                    │     │        │   │
│  │  │  │  - frontend        │     │  │  │  - frontend        │     │        │   │
│  │  │  │  - cartservice     │     │  │  │  - cartservice     │     │        │   │
│  │  │  │  - checkoutservice │     │  │  │  - checkoutservice │     │        │   │
│  │  │  │  - productcatalog  │     │  │  │  - productcatalog  │     │        │   │
│  │  │  │  - currencyservice │     │  │  │  - currencyservice │     │        │   │
│  │  │  │  - paymentservice  │     │  │  │  - paymentservice  │     │        │   │
│  │  │  │  - shippingservice │     │  │  │  - shippingservice │     │        │   │
│  │  │  │  - emailservice    │     │  │  │  - emailservice    │     │        │   │
│  │  │  │  - recommendation  │     │  │  │  - recommendation  │     │        │   │
│  │  │  │  - adservice       │     │  │  │  - adservice       │     │        │   │
│  │  │  │  + ADOT sidecars   │     │  │  │  + ADOT sidecars   │     │        │   │
│  │  │  └────────────────────┘     │  │  └────────────────────┘     │        │   │
│  │  └─────────────────────────────┘  └─────────────────────────────┘        │   │
│  │                                                                           │   │
│  │  ┌─────────────────────────────┐  ┌─────────────────────────────┐        │   │
│  │  │  DATABASE SUBNET (AZ-a)    │  │  DATABASE SUBNET (AZ-b)    │        │   │
│  │  │  10.0.100.0/24            │  │  10.0.200.0/24            │        │   │
│  │  │                             │  │                             │        │   │
│  │  │  ┌────────────────────┐     │  │  ┌────────────────────┐     │        │   │
│  │  │  │  ElastiCache Redis │◄────┼──┼──│  ElastiCache Redis │     │        │   │
│  │  │  │  (Primary)  :6379  │     │  │  │  (Replica)  :6379  │     │        │   │
│  │  │  └────────────────────┘     │  │  └────────────────────┘     │        │   │
│  │  └─────────────────────────────┘  └─────────────────────────────┘        │   │
│  │                                                                           │   │
│  │  ┌───────────────────────────────────────────────────────────────┐        │   │
│  │  │  AWS CLOUD MAP NAMESPACE: onlineboutique.local               │        │   │
│  │  │  (Service Connect — DNS-based service discovery)              │        │   │
│  │  └───────────────────────────────────────────────────────────────┘        │   │
│  └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐     │
│  │  CloudWatch   │  │  X-Ray       │  │  AMP          │  │  Managed Grafana │     │
│  │  Logs+Metrics │  │  Traces      │  │  (Prometheus) │  │  (Dashboards)    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘     │
│                                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────────────┐   │
│  │  ECR          │  │  Secrets Mgr │  │  IAM (OIDC for GitHub Actions)      │   │
│  │  (11 repos)   │  │              │  │                                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘

INTERNET ──► ALB :443 ──► frontend :8080 ──► (gRPC) ──► backend services
                                                              │
                                                              ▼
                                                    ElastiCache Redis :6379
```

### 3.2 Network Layout

| Subnet Type     | CIDR (AZ-a)    | CIDR (AZ-b)    | Resources                          |
|-----------------|----------------|----------------|-------------------------------------|
| **Public**      | 10.0.1.0/24    | 10.0.2.0/24    | ALB, NAT Gateway, Internet Gateway |
| **Private**     | 10.0.10.0/24   | 10.0.20.0/24   | ECS Fargate tasks (all services)   |
| **Database**    | 10.0.100.0/24  | 10.0.200.0/24  | ElastiCache Redis subnet group     |

### 3.3 Security Group Rules (Least Privilege)

**SG: `sg-alb` (Application Load Balancer)**

| Direction | Port  | Source/Dest     | Description                |
|-----------|-------|-----------------|----------------------------|
| Inbound   | 443   | 0.0.0.0/0       | HTTPS from internet        |
| Inbound   | 80    | 0.0.0.0/0       | HTTP (redirect to HTTPS)   |
| Outbound  | 8080  | sg-ecs-frontend | Forward to frontend tasks  |

**SG: `sg-ecs-frontend` (Frontend ECS Tasks)**

| Direction | Port  | Source/Dest       | Description                    |
|-----------|-------|-------------------|--------------------------------|
| Inbound   | 8080  | sg-alb            | Traffic from ALB only          |
| Outbound  | 3550  | sg-ecs-backend    | → productcatalogservice        |
| Outbound  | 7000  | sg-ecs-backend    | → currencyservice              |
| Outbound  | 7070  | sg-ecs-backend    | → cartservice                  |
| Outbound  | 8080  | sg-ecs-backend    | → recommendationservice        |
| Outbound  | 50051 | sg-ecs-backend    | → shippingservice              |
| Outbound  | 5050  | sg-ecs-backend    | → checkoutservice              |
| Outbound  | 9555  | sg-ecs-backend    | → adservice                    |
| Outbound  | 443   | 0.0.0.0/0         | HTTPS to AWS APIs (logs, etc.) |

**SG: `sg-ecs-backend` (All Backend ECS Tasks)**

| Direction | Port  | Source/Dest       | Description                          |
|-----------|-------|-------------------|--------------------------------------|
| Inbound   | 3550  | sg-ecs-frontend, sg-ecs-backend | productcatalog from frontend+checkout |
| Inbound   | 5050  | sg-ecs-frontend   | checkoutservice from frontend        |
| Inbound   | 7000  | sg-ecs-frontend, sg-ecs-backend | currencyservice                      |
| Inbound   | 7070  | sg-ecs-frontend, sg-ecs-backend | cartservice                          |
| Inbound   | 8080  | sg-ecs-frontend, sg-ecs-backend | email + recommendation               |
| Inbound   | 9555  | sg-ecs-frontend   | adservice from frontend              |
| Inbound   | 50051 | sg-ecs-frontend, sg-ecs-backend | shipping + payment                   |
| Outbound  | 6379  | sg-redis          | cartservice → ElastiCache            |
| Outbound  | ALL   | sg-ecs-backend    | Inter-backend gRPC calls             |
| Outbound  | 443   | 0.0.0.0/0         | HTTPS to AWS APIs                    |

**SG: `sg-redis` (ElastiCache)**

| Direction | Port | Source/Dest    | Description                    |
|-----------|------|----------------|--------------------------------|
| Inbound   | 6379 | sg-ecs-backend | Only from backend ECS tasks    |
| Outbound  | None | —              | No outbound needed             |

---

## 4. ECS TASK DEFINITIONS

### 4.1 ECS Cluster & Service Connect Setup

- **ECS Cluster Name:** `online-boutique-prod`
- **Capacity Provider:** FARGATE (primary), FARGATE_SPOT (for non-critical services like loadgenerator)
- **Service Connect Namespace:** `onlineboutique.local` (backed by AWS Cloud Map)
- Each ECS Service registers a DNS name like `cartservice.onlineboutique.local:7070`

### 4.2 Task Definitions — All 11 Services

Each task definition below includes the **app container** + an **ADOT sidecar** for
observability. The ADOT sidecar is covered in Section 6.

---

#### 4.2.1 frontend

```
Task Family:        online-boutique-frontend
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB
Network Mode:       awsvpc

Container: frontend
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/frontend:latest
  Port Mapping:     8080 (tcp)
  Health Check:     HTTP GET /_healthz :8080 (with Cookie header)
  Environment Variables:
    PORT                            = "8080"
    PRODUCT_CATALOG_SERVICE_ADDR    = "productcatalogservice.onlineboutique.local:3550"
    CURRENCY_SERVICE_ADDR           = "currencyservice.onlineboutique.local:7000"
    CART_SERVICE_ADDR               = "cartservice.onlineboutique.local:7070"
    RECOMMENDATION_SERVICE_ADDR     = "recommendationservice.onlineboutique.local:8080"
    SHIPPING_SERVICE_ADDR           = "shippingservice.onlineboutique.local:50051"
    CHECKOUT_SERVICE_ADDR           = "checkoutservice.onlineboutique.local:5050"
    AD_SERVICE_ADDR                 = "adservice.onlineboutique.local:9555"
    ENV_PLATFORM                    = "aws"
    ENABLE_PROFILER                 = "0"

ECS Service Config:
  Desired Count:    2 (multi-AZ)
  ALB Target Group: Yes (port 8080, HTTP health check on /_healthz)
  Service Connect:  Client+Server (name: frontend, port: 8080)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=10
```

---

#### 4.2.2 cartservice

```
Task Family:        online-boutique-cartservice
Launch Type:        FARGATE
CPU:                512 (0.5 vCPU)
Memory:             1024 MB
Network Mode:       awsvpc

Container: cartservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/cartservice:latest
  Port Mapping:     7070 (tcp)
  Health Check:     Command ["grpc_health_probe", "-addr=:7070"] (or TCP on 7070)
  Environment Variables:
    REDIS_ADDR      = (from Secrets Manager → "online-boutique/redis-endpoint")

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: cartservice, port: 7070)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=6
```

---

#### 4.2.3 checkoutservice

```
Task Family:        online-boutique-checkoutservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB
Network Mode:       awsvpc

Container: checkoutservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/checkoutservice:latest
  Port Mapping:     5050 (tcp)
  Health Check:     TCP on 5050
  Environment Variables:
    PORT                            = "5050"
    PRODUCT_CATALOG_SERVICE_ADDR    = "productcatalogservice.onlineboutique.local:3550"
    SHIPPING_SERVICE_ADDR           = "shippingservice.onlineboutique.local:50051"
    PAYMENT_SERVICE_ADDR            = "paymentservice.onlineboutique.local:50051"
    EMAIL_SERVICE_ADDR              = "emailservice.onlineboutique.local:5000"
    CURRENCY_SERVICE_ADDR           = "currencyservice.onlineboutique.local:7000"
    CART_SERVICE_ADDR               = "cartservice.onlineboutique.local:7070"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: checkoutservice, port: 5050)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=6
```

---

#### 4.2.4 productcatalogservice

```
Task Family:        online-boutique-productcatalogservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB

Container: productcatalogservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/productcatalogservice:latest
  Port Mapping:     3550 (tcp)
  Health Check:     TCP on 3550
  Environment Variables:
    PORT              = "3550"
    DISABLE_PROFILER  = "1"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: productcatalogservice, port: 3550)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=6
```

---

#### 4.2.5 currencyservice

```
Task Family:        online-boutique-currencyservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB

Container: currencyservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/currencyservice:latest
  Port Mapping:     7000 (tcp)
  Health Check:     TCP on 7000
  Environment Variables:
    PORT              = "7000"
    DISABLE_PROFILER  = "1"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: currencyservice, port: 7000)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=4
```

---

#### 4.2.6 paymentservice

```
Task Family:        online-boutique-paymentservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB

Container: paymentservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/paymentservice:latest
  Port Mapping:     50051 (tcp)
  Health Check:     TCP on 50051
  Environment Variables:
    PORT              = "50051"
    DISABLE_PROFILER  = "1"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: paymentservice, port: 50051)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=4
```

---

#### 4.2.7 shippingservice

```
Task Family:        online-boutique-shippingservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB

Container: shippingservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/shippingservice:latest
  Port Mapping:     50051 (tcp)
  Health Check:     TCP on 50051
  Environment Variables:
    PORT              = "50051"
    DISABLE_PROFILER  = "1"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: shippingservice, port: 50051)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=4
```

---

#### 4.2.8 emailservice

```
Task Family:        online-boutique-emailservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             512 MB

Container: emailservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/emailservice:latest
  Port Mapping:     8080 (tcp)
  Health Check:     TCP on 8080
  Environment Variables:
    PORT              = "8080"
    DISABLE_PROFILER  = "1"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: emailservice, port: 5000, target: 8080)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=4

Note: K8s service exposes port 5000 → target 8080. Service Connect maps
emailservice.onlineboutique.local:5000 → container:8080.
```

---

#### 4.2.9 recommendationservice

```
Task Family:        online-boutique-recommendationservice
Launch Type:        FARGATE
CPU:                256 (0.25 vCPU)
Memory:             1024 MB  (needs more memory — 450Mi limit in K8s)

Container: recommendationservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/recommendationservice:latest
  Port Mapping:     8080 (tcp)
  Health Check:     TCP on 8080
  Environment Variables:
    PORT                            = "8080"
    PRODUCT_CATALOG_SERVICE_ADDR    = "productcatalogservice.onlineboutique.local:3550"
    DISABLE_PROFILER                = "1"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: recommendationservice, port: 8080)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=4
```

---

#### 4.2.10 adservice

```
Task Family:        online-boutique-adservice
Launch Type:        FARGATE
CPU:                512 (0.5 vCPU)
Memory:             1024 MB  (Java — needs more memory, 300Mi limit in K8s)

Container: adservice
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/adservice:latest
  Port Mapping:     9555 (tcp)
  Health Check:     TCP on 9555 (initialDelay: 20s, period: 15s)
  Environment Variables:
    PORT              = "9555"

ECS Service Config:
  Desired Count:    2
  Service Connect:  Client+Server (name: adservice, port: 9555)
  Auto Scaling:     Target tracking on CPU 60%, min=2, max=4
```

---

#### 4.2.11 loadgenerator (Optional — Dev/Staging Only)

```
Task Family:        online-boutique-loadgenerator
Launch Type:        FARGATE_SPOT  (cost savings — non-critical)
CPU:                512 (0.5 vCPU)
Memory:             1024 MB

Container: loadgenerator
  Image:            <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/loadgenerator:latest
  Health Check:     None (continuous load generation)
  Environment Variables:
    FRONTEND_ADDR   = "frontend.onlineboutique.local:8080"
    USERS           = "10"
    RATE            = "1"

ECS Service Config:
  Desired Count:    1 (or 0 in prod)
  Service Connect:  Client only (no server port)
```

### 4.3 IAM Roles

#### ECS Task Execution Role (shared by all tasks)

This role is used by the ECS agent to pull images and write logs.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRPull",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": "arn:aws:logs:us-east-1:<ACCOUNT_ID>:log-group:/ecs/online-boutique/*"
    },
    {
      "Sid": "SecretsAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:<ACCOUNT_ID>:secret:online-boutique/*"
    }
  ]
}
```

#### ECS Task Role — cartservice (needs Secrets Manager for Redis)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "XRayWrite",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PrometheusRemoteWrite",
      "Effect": "Allow",
      "Action": [
        "aps:RemoteWrite"
      ],
      "Resource": "arn:aws:aps:us-east-1:<ACCOUNT_ID>:workspace/<AMP_WORKSPACE_ID>"
    },
    {
      "Sid": "CloudWatchMetrics",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    }
  ]
}
```

> **Note:** All other services use the same Task Role (X-Ray + Prometheus + CloudWatch).
> Only `cartservice` additionally needs the Secrets Manager access, which is handled
> via the Execution Role's `secretsmanager:GetSecretValue` permission (secrets are
> injected as env vars at task launch time).

---

## 5. CI/CD PIPELINE (GitHub Actions)

### 5.1 Strategy: Zero-Downtime Rolling Deployments

- **Authentication:** AWS OIDC Provider (no static access keys stored in GitHub)
- **Registry:** Amazon ECR (one repo per microservice)
- **Deployment:** ECS rolling update with `minimumHealthyPercent: 100` and
  `maximumPercent: 200` — ensures old tasks stay running until new ones pass health checks
- **Trigger:** Push to `main` branch, with path filters per service

### 5.2 GitHub Actions Workflow

```yaml
# .github/workflows/deploy-ecs.yml
name: Deploy to ECS

on:
  push:
    branches: [main]
    paths:
      - 'src/**'

permissions:
  id-token: write   # Required for OIDC
  contents: read

env:
  AWS_REGION: us-east-1
  ECR_REGISTRY: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
  ECS_CLUSTER: online-boutique-prod

jobs:
  # Step 1: Detect which services changed
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      services: ${{ steps.filter.outputs.changes }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            frontend:        ['src/frontend/**']
            cartservice:     ['src/cartservice/**']
            checkoutservice: ['src/checkoutservice/**']
            productcatalogservice: ['src/productcatalogservice/**']
            currencyservice: ['src/currencyservice/**']
            paymentservice:  ['src/paymentservice/**']
            shippingservice: ['src/shippingservice/**']
            emailservice:    ['src/emailservice/**']
            recommendationservice: ['src/recommendationservice/**']
            adservice:       ['src/adservice/**']
            loadgenerator:   ['src/loadgenerator/**']

  # Step 2: Build, push, and deploy each changed service
  deploy:
    needs: detect-changes
    if: needs.detect-changes.outputs.services != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJson(needs.detect-changes.outputs.services) }}
      fail-fast: false

    steps:
      # 2a. Checkout code
      - uses: actions/checkout@v4

      # 2b. Authenticate to AWS via OIDC (no static keys!)
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-actions-ecs-deploy
          aws-region: ${{ env.AWS_REGION }}

      # 2c. Login to ECR
      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      # 2d. Build and push Docker image
      - name: Build and Push Image
        id: build
        run: |
          IMAGE_TAG="${{ github.sha }}"
          REPO="${{ env.ECR_REGISTRY }}/online-boutique/${{ matrix.service }}"

          # Handle cartservice special path
          if [ "${{ matrix.service }}" = "cartservice" ]; then
            CONTEXT="src/cartservice/src"
          else
            CONTEXT="src/${{ matrix.service }}"
          fi

          docker build -t ${REPO}:${IMAGE_TAG} -t ${REPO}:latest ${CONTEXT}
          docker push ${REPO}:${IMAGE_TAG}
          docker push ${REPO}:latest

          echo "image=${REPO}:${IMAGE_TAG}" >> $GITHUB_OUTPUT

      # 2e. Download current task definition
      - name: Download Task Definition
        run: |
          aws ecs describe-task-definition \
            --task-definition online-boutique-${{ matrix.service }} \
            --query 'taskDefinition' \
            --output json > task-def.json

          # Remove fields that can't be re-registered
          jq 'del(.taskDefinitionArn, .revision, .status,
              .requiresAttributes, .compatibilities,
              .registeredAt, .registeredBy)' task-def.json > clean-task-def.json

      # 2f. Update image in task definition
      - name: Update Task Definition Image
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        id: render
        with:
          task-definition: clean-task-def.json
          container-name: ${{ matrix.service }}
          image: ${{ steps.build.outputs.image }}

      # 2g. Deploy to ECS (rolling update)
      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: ${{ steps.render.outputs.task-definition }}
          service: online-boutique-${{ matrix.service }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
          wait-for-minutes: 10
```

### 5.3 AWS OIDC Setup (One-Time)

```bash
# 1. Create the OIDC identity provider in IAM
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create the IAM role with trust policy
# Trust policy allows only YOUR repo to assume this role:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_ORG>/<YOUR_REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}

# 3. Attach permissions to the role:
#    - AmazonEC2ContainerRegistryPowerUser (ECR push)
#    - Custom policy for ECS deploy (ecs:UpdateService, ecs:DescribeTaskDefinition,
#      ecs:RegisterTaskDefinition, ecs:DescribeServices, iam:PassRole)
```

---

## 6. OBSERVABILITY (OpenTelemetry / ADOT / CloudWatch)

### 6.1 Strategy Overview

The Online Boutique already has OpenTelemetry instrumentation built into most services.
On AWS, we use the **AWS Distro for OpenTelemetry (ADOT)** as a sidecar container in
each ECS task to collect traces, metrics, and logs, then export them to AWS-native backends.

```
┌─────────────────────────────────────────────────────┐
│                  ECS TASK                            │
│                                                     │
│  ┌──────────────┐      ┌──────────────────────┐     │
│  │  App Container│─────►│  ADOT Sidecar        │     │
│  │  (e.g.       │ OTLP │  (collector)          │     │
│  │  frontend)   │:4317 │                        │     │
│  └──────────────┘      │  Exporters:            │     │
│                        │  ├─ X-Ray (traces)     │────────► AWS X-Ray
│                        │  ├─ CloudWatch (metrics)│────────► CloudWatch Metrics
│                        │  └─ AMP (prometheus)   │────────► Amazon Managed Prometheus
│                        └──────────────────────┘     │
│                                                     │
│  Logs: awslogs driver ──────────────────────────────────► CloudWatch Logs
└─────────────────────────────────────────────────────┘
                          │
                          ▼
              Amazon Managed Grafana
              (dashboards for all signals)
```

### 6.2 ADOT Sidecar Container (added to every task definition)

```json
{
  "name": "adot-collector",
  "image": "public.ecr.aws/aws-observability/aws-otel-collector:latest",
  "essential": false,
  "portMappings": [
    { "containerPort": 4317, "protocol": "tcp" },
    { "containerPort": 4318, "protocol": "tcp" }
  ],
  "environment": [
    { "name": "AOT_CONFIG_CONTENT", "value": "<ADOT_CONFIG_YAML_BASE64>" }
  ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "/ecs/online-boutique/adot-collector",
      "awslogs-region": "us-east-1",
      "awslogs-stream-prefix": "adot"
    }
  }
}
```

### 6.3 ADOT Collector Configuration

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 512
  resourcedetection:
    detectors: [ecs, env]
    timeout: 5s
  memory_limiter:
    check_interval: 1s
    limit_mib: 128
    spike_limit_mib: 32

exporters:
  awsxray:
    region: us-east-1
  awsemf:
    region: us-east-1
    namespace: OnlineBoutique
    log_group_name: /ecs/online-boutique/metrics
  prometheusremotewrite:
    endpoint: https://aps-workspaces.us-east-1.amazonaws.com/workspaces/<WORKSPACE_ID>/api/v1/remote_write
    auth:
      authenticator: sigv4auth

extensions:
  sigv4auth:
    region: us-east-1
    service: aps
  health_check:
    endpoint: 0.0.0.0:13133

service:
  extensions: [sigv4auth, health_check]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, batch]
      exporters: [awsxray]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, batch]
      exporters: [awsemf, prometheusremotewrite]
```

### 6.4 App Container OTEL Environment Variables

Add these to each app container that supports OpenTelemetry:

```
OTEL_EXPORTER_OTLP_ENDPOINT    = "http://localhost:4317"
OTEL_SERVICE_NAME               = "<service-name>"
OTEL_RESOURCE_ATTRIBUTES        = "service.namespace=online-boutique,deployment.environment=production"
COLLECTOR_SERVICE_ADDR           = "localhost:4317"
ENABLE_TRACING                  = "1"
```

### 6.5 Logging Strategy

All containers use the `awslogs` log driver:

```json
"logConfiguration": {
  "logDriver": "awslogs",
  "options": {
    "awslogs-group": "/ecs/online-boutique/<service-name>",
    "awslogs-region": "us-east-1",
    "awslogs-stream-prefix": "ecs",
    "awslogs-create-group": "true"
  }
}
```

**Log Retention:** 30 days (dev), 90 days (prod)

### 6.6 Critical CloudWatch Alarms (Top 5)

| # | Alarm Name                          | Metric                                    | Threshold              | Action                    |
|---|-------------------------------------|-------------------------------------------|------------------------|---------------------------|
| 1 | **HighCPU-Frontend**                | ECS CPUUtilization (frontend service)     | > 80% for 5 min        | SNS → PagerDuty/Slack    |
| 2 | **ALB-5xx-Spike**                   | ALB HTTPCode_Target_5XX_Count             | > 50 in 5 min          | SNS → PagerDuty/Slack    |
| 3 | **UnhealthyTasks**                  | ECS RunningTaskCount < DesiredTaskCount   | Any service, > 2 min   | SNS → PagerDuty/Slack    |
| 4 | **Redis-HighMemory**                | ElastiCache DatabaseMemoryUsagePercentage | > 80%                  | SNS → Ops team           |
| 5 | **HighLatency-Checkout**            | ALB TargetResponseTime (p99)              | > 3 seconds for 5 min  | SNS → PagerDuty/Slack    |

**Bonus alarms to add later:**
- ElastiCache `CurrConnections` > 500
- ECS `MemoryUtilization` > 85% per service
- X-Ray `FaultRate` > 5% on any service
- CloudWatch Logs metric filter for `ERROR` or `FATAL` log patterns

---

## 7. COST ESTIMATE & INTERVIEW TALKING POINTS

### 7.1 Monthly Cost Estimate (us-east-1)

#### DEV Environment (single-AZ, 1 task per service, smaller resources)

| Resource                        | Spec                                  | Est. Monthly Cost |
|---------------------------------|---------------------------------------|-------------------|
| ECS Fargate (11 tasks)          | 0.25 vCPU / 0.5 GB each              | ~$45              |
| NAT Gateway (1x)               | 1 NAT + data processing              | ~$35              |
| ALB                             | 1 ALB + LCU hours                    | ~$20              |
| ElastiCache Redis               | cache.t4g.micro (single node)        | ~$12              |
| ECR Storage                     | ~5 GB images                          | ~$1               |
| CloudWatch Logs                 | ~10 GB/month ingestion               | ~$5               |
| Secrets Manager                 | 2 secrets                             | ~$1               |
| **TOTAL (Dev)**                 |                                       | **~$120/month**   |

#### PROD Environment (multi-AZ, 2+ tasks per service, auto-scaling)

| Resource                        | Spec                                  | Est. Monthly Cost |
|---------------------------------|---------------------------------------|-------------------|
| ECS Fargate (22+ tasks)         | Mixed 0.25-0.5 vCPU, 0.5-1 GB       | ~$150             |
| NAT Gateway (2x, multi-AZ)     | 2 NATs + data processing             | ~$70              |
| ALB                             | 1 ALB + higher LCU hours             | ~$30              |
| ElastiCache Redis               | cache.t4g.small (multi-AZ, replica)  | ~$50              |
| ECR Storage                     | ~10 GB images                         | ~$2               |
| CloudWatch Logs                 | ~30 GB/month ingestion               | ~$15              |
| CloudWatch Alarms               | 5-10 alarms                           | ~$1               |
| Amazon Managed Prometheus       | Ingestion + storage                   | ~$15              |
| Amazon Managed Grafana          | 1 editor workspace                    | ~$9               |
| AWS X-Ray                       | Trace sampling                        | ~$5               |
| Secrets Manager                 | 5 secrets                             | ~$2               |
| ACM Certificate                 | Free (for ALB)                        | $0                |
| **TOTAL (Prod)**                |                                       | **~$350/month**   |

> **Cost optimization tips:**
> - Use **Fargate Spot** for loadgenerator and non-critical dev tasks (up to 70% savings)
> - Use **ECS auto-scaling** to scale down during off-peak hours
> - Set CloudWatch log retention to 30 days (dev) / 90 days (prod)
> - Consider **Savings Plans** for Fargate if committing to 1-year usage (~30% savings)
> - Use **ElastiCache Serverless** for dev to pay only for what you use

### 7.2 Interview Talking Points (5 Key Defenses)

**1. Scalability — Independent Service Scaling with ECS Auto Scaling**

> "Each microservice runs as its own ECS Service with independent target-tracking
> auto-scaling policies. The frontend can scale to 10 tasks during a traffic spike
> while the payment service stays at 2 tasks. This is more cost-efficient than
> scaling an entire monolith. I use CPU-based target tracking at 60% as the primary
> signal, with the option to add custom CloudWatch metrics (like request count per
> target from the ALB) for more precise scaling. The multi-AZ deployment ensures
> tasks are spread across availability zones automatically via Fargate's placement
> strategy."

**2. Security — Zero-Trust, Least-Privilege at Every Layer**

> "Security is layered: IAM OIDC federation for CI/CD means zero static credentials
> in GitHub. Each ECS task has its own IAM Task Role scoped to only the AWS services
> it needs — cartservice can read from Secrets Manager, but adservice cannot. Security
> Groups enforce network-level least privilege: only the ALB can reach the frontend,
> only the frontend and checkout can reach backend services, and only cartservice can
> reach ElastiCache. Secrets like the Redis connection string are stored in AWS Secrets
> Manager and injected at task launch — they never appear in task definitions or source
> code. All container images run as non-root with read-only filesystems."

**3. Zero-Downtime Deployments — Rolling Updates with Health Checks**

> "ECS rolling deployments are configured with minimumHealthyPercent=100 and
> maximumPercent=200. During a deploy, ECS launches new tasks alongside old ones,
> waits for ALB health checks to pass, then drains connections from old tasks before
> stopping them. The CI/CD pipeline uses path-based change detection so only modified
> services are rebuilt and deployed — a change to cartservice doesn't trigger a
> frontend redeploy. The GitHub Actions workflow waits for service stability before
> marking the deployment as successful, and a failed health check automatically rolls
> back to the previous task definition revision."

**4. Observability — Full-Stack Telemetry with OpenTelemetry**

> "I implemented the three pillars of observability: logs go to CloudWatch Logs via
> the awslogs driver, distributed traces flow through the ADOT sidecar to AWS X-Ray
> for end-to-end request tracing across all 11 microservices, and metrics are exported
> to both CloudWatch (for alarms) and Amazon Managed Prometheus (for Grafana dashboards).
> The ADOT collector runs as a sidecar in each task definition, receiving OTLP data on
> localhost:4317 — this means the app containers don't need AWS SDK dependencies, they
> just speak standard OpenTelemetry protocol. I've configured 5 critical alarms covering
> CPU saturation, 5xx error spikes, unhealthy task counts, Redis memory pressure, and
> checkout latency."

**5. Cost Optimization — Right-Sizing and Serverless-First**

> "Fargate eliminates EC2 instance management and right-sizes at the task level — I
> allocated 0.25 vCPU to lightweight Go services and 0.5 vCPU to the Java adservice
> based on actual K8s resource limits from the project. The dev environment runs at
> roughly $120/month with single-AZ deployment and minimal task counts, while production
> with full HA runs around $350/month. I use Fargate Spot for the load generator
> (non-critical workload) saving up to 70%. ElastiCache Serverless is an option for
> dev environments to avoid paying for idle capacity. For sustained production workloads,
> Compute Savings Plans can reduce Fargate costs by 30%."

---

## 8. AI-POWERED DEVOPS STRATEGY

> This section demonstrates awareness of the AI-driven shift in DevOps — a skill set
> hiring managers increasingly look for. It covers practical AI agent integrations,
> custom automation solutions, and how to talk about them in interviews.

### 8.1 The AI + DevOps Landscape (Why This Matters)

DevOps is moving from "automate everything with scripts" to "let AI agents handle
the toil while engineers focus on architecture decisions." Hiring managers want to see
that you understand this shift and can implement it — not just talk about it.

The key areas where AI transforms DevOps for this project:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AI-POWERED DEVOPS LAYERS                         │
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  LAYER 1         │  │  LAYER 2         │  │  LAYER 3         │   │
│  │  AI Coding       │  │  AI Ops Agents   │  │  AI Incident     │   │
│  │  Assistants      │  │                  │  │  Response        │   │
│  │                  │  │                  │  │                  │   │
│  │  - GitHub        │  │  - Custom ChatOps│  │  - Auto-triage   │   │
│  │    Copilot       │  │    bots          │  │    from alerts   │   │
│  │  - Amazon Q      │  │  - IaC generators│  │  - Root cause    │   │
│  │    Developer     │  │  - Deployment    │  │    analysis      │   │
│  │  - Kiro IDE      │  │    validators    │  │  - Auto-remediate│   │
│  │    (this tool)   │  │  - Drift         │  │    known issues  │   │
│  │                  │  │    detectors     │  │                  │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  LAYER 4         │  │  LAYER 5         │  │  LAYER 6         │   │
│  │  AI Security     │  │  AI Cost         │  │  AI Testing      │   │
│  │                  │  │  Optimization    │  │                  │   │
│  │  - PR security   │  │  - Right-sizing  │  │  - AI-generated  │   │
│  │    scanning      │  │    suggestions   │  │    load tests    │   │
│  │  - IAM policy    │  │  - Anomaly       │  │  - Chaos         │   │
│  │    review        │  │    detection     │  │    engineering    │   │
│  │  - CVE triage    │  │  - Forecast      │  │    scenarios     │   │
│  │                  │  │    billing       │  │  - Test coverage  │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.2 AI DevOps Agents — Practical Implementations for This Project

#### Agent 1: Intelligent Incident Response Bot (Slack/Teams + AWS Lambda)

**What it does:** When a CloudWatch alarm fires, instead of just sending a raw alert
to Slack, an AI agent analyzes the context and provides actionable next steps.

```
FLOW:
CloudWatch Alarm → SNS → Lambda (AI Agent) → Slack

EXAMPLE OUTPUT IN SLACK:
┌──────────────────────────────────────────────────────────────┐
│ 🔴 ALARM: HighCPU-Frontend (CPU > 80% for 5 min)            │
│                                                              │
│ 🤖 AI Analysis:                                              │
│ • Current CPU: 87% across 2 tasks (both in us-east-1a)      │
│ • Auto-scaling triggered: scaling from 2 → 4 tasks          │
│ • Correlated event: loadgenerator USERS was changed from     │
│   10 → 50 via deployment 12 minutes ago                     │
│ • X-Ray shows p99 latency on /product/L9ECAV7KIM increased  │
│   from 120ms → 890ms                                        │
│                                                              │
│ 📋 Suggested Actions:                                        │
│ 1. Wait 3 min for auto-scaling to stabilize                 │
│ 2. If persists: check recommendationservice (upstream dep)  │
│ 3. Rollback loadgenerator if this was unintentional         │
│                                                              │
│ [View in CloudWatch] [View X-Ray Trace] [Rollback Deploy]   │
└──────────────────────────────────────────────────────────────┘
```

**Tech stack:**
- AWS Lambda (Python) with Amazon Bedrock (Claude) for analysis
- Reads from: CloudWatch Metrics API, X-Ray API, ECS DescribeServices
- Posts to: Slack webhook with structured blocks
- Cost: ~$5/month (Lambda + Bedrock invocations on alarm events only)

#### Agent 2: PR Deployment Validator (GitHub Actions + AI)

**What it does:** Before merging a PR that changes infrastructure or service config,
an AI agent reviews the diff and flags risks specific to this microservices architecture.

```yaml
# .github/workflows/ai-pr-review.yml
name: AI Deployment Risk Review
on:
  pull_request:
    paths: ['src/**', 'terraform/**', 'task-definitions/**']

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get PR Diff
        run: git diff origin/main...HEAD > pr_diff.txt

      - name: AI Risk Analysis
        run: |
          # Call Amazon Bedrock or OpenAI API with the diff
          # Prompt includes project context:
          # - Service dependency graph
          # - Security group rules
          # - Known breaking change patterns (port changes, env var renames)
          python scripts/ai-pr-review.py \
            --diff pr_diff.txt \
            --context docs/service-dependencies.json \
            --output review.md

      - name: Post Review Comment
        uses: actions/github-script@v7
        with:
          script: |
            const review = require('fs').readFileSync('review.md', 'utf8');
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: review
            });
```

**Example AI review output on a PR:**

```
## 🤖 AI Deployment Risk Analysis

### ⚠️ Medium Risk: Port Change Detected
`checkoutservice` port changed from 5050 → 5060 in task definition.
This will break:
- `frontend` env var `CHECKOUT_SERVICE_ADDR` (still points to :5050)
- Security Group `sg-ecs-backend` inbound rule (allows 5050, not 5060)
- Service Connect port mapping in Cloud Map

**Action required:** Update all 3 references before merging.

### ✅ Low Risk: Memory Increase
`adservice` memory increased from 1024 MB → 2048 MB.
This is within Fargate limits and won't affect other services.
Current peak usage: 780 MB (safe headroom).
```

#### Agent 3: Infrastructure Drift Detector (Scheduled Lambda)

**What it does:** Runs on a schedule (daily), compares actual AWS state against
the expected Terraform state or task definitions in Git, and reports drift.

```
FLOW:
EventBridge (daily cron) → Lambda (AI Agent) → Compare Git vs AWS API → Report

CHECKS:
✓ ECS task definitions match what's in the repo
✓ Security Group rules haven't been manually modified
✓ ElastiCache config matches expected parameters
✓ IAM roles don't have extra permissions added manually
✓ No orphaned resources (unused target groups, old task def revisions)

REPORT (posted to Slack weekly):
┌──────────────────────────────────────────────────────────────┐
│ 📊 Weekly Infrastructure Drift Report                        │
│                                                              │
│ ✅ ECS Task Definitions: All 11 services match Git (rev 47)  │
│ ⚠️  Security Groups: sg-ecs-backend has 1 extra rule          │
│    → Port 3306 inbound from 10.0.0.0/16 (added manually?)   │
│ ✅ ElastiCache: Config matches expected                       │
│ ⚠️  IAM: github-actions-ecs-deploy role has extra policy      │
│    → AmazonS3FullAccess (not in Terraform)                   │
│ ✅ No orphaned resources found                                │
│                                                              │
│ Drift Score: 2/5 items drifted — needs attention             │
└──────────────────────────────────────────────────────────────┘
```

#### Agent 4: AI-Powered Runbook Executor (ChatOps)

**What it does:** A Slack bot that lets on-call engineers execute pre-approved
operational runbooks using natural language instead of remembering exact commands.

```
SLACK CONVERSATION:

Engineer: @devops-bot scale up frontend to 6 tasks
Bot:      🔍 Interpreting: Update ECS service online-boutique-frontend
          desired count from 2 → 6
          ⚠️ This is above the auto-scaling max (currently 10). Proceeding.
          🔐 Requires approval from a second team member.

Sr. Eng:  @devops-bot approve
Bot:      ✅ Scaling frontend to 6 tasks...
          ✅ Done. 4 new tasks launching. ETA to healthy: ~90 seconds.
          📊 I'll report back when all tasks pass health checks.

Bot:      ✅ All 6 frontend tasks are healthy. Current CPU: 34%.
```

**Pre-approved runbooks the bot can execute:**
1. Scale a service up/down (within guardrails)
2. Force a new deployment (rolling restart)
3. Rollback to previous task definition revision
4. Toggle loadgenerator on/off
5. Fetch recent logs for a service
6. Show current service health summary

**Guardrails (critical for safety):**
- Cannot scale below minimum (2 for prod services)
- Cannot delete services or infrastructure
- Requires second approval for production changes
- All actions logged to an audit trail in DynamoDB
- AI interprets intent but maps to pre-defined, tested commands only

### 8.3 Amazon Q Developer Integration

Amazon Q Developer can be integrated directly into the DevOps workflow:

| Use Case                        | How It Helps This Project                                    |
|---------------------------------|--------------------------------------------------------------|
| **IaC Generation**              | Generate Terraform/CloudFormation for the VPC, ECS, ALB setup from natural language descriptions |
| **Troubleshooting**             | "Why is my ECS task failing to start?" → Q analyzes CloudTrail, task stopped reasons, and suggests fixes |
| **Security Scanning**           | Scans Dockerfiles and task definitions for vulnerabilities, suggests least-privilege IAM policies |
| **Cost Optimization**           | Analyzes ECS usage patterns and recommends right-sizing or Savings Plans |
| **Operational Investigation**   | "Show me all 5xx errors in the last hour across all services" → queries CloudWatch Logs Insights |

### 8.4 Custom AI Solution: Self-Healing Pipeline

A more advanced pattern that combines multiple agents into a self-healing loop:

```
┌──────────────────────────────────────────────────────────────────┐
│                    SELF-HEALING PIPELINE                          │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐   │
│  │ DETECT   │───►│ DIAGNOSE │───►│ DECIDE   │───►│ ACT      │   │
│  │          │    │          │    │          │    │          │   │
│  │CloudWatch│    │AI Agent  │    │Rules     │    │Lambda    │   │
│  │Alarms    │    │correlates│    │Engine +  │    │executes  │   │
│  │X-Ray     │    │logs,     │    │AI decides│    │approved  │   │
│  │anomalies │    │metrics,  │    │action or │    │runbook   │   │
│  │          │    │traces    │    │escalates │    │          │   │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘   │
│       │                                               │          │
│       │              ┌──────────┐                     │          │
│       └──────────────│ LEARN    │◄────────────────────┘          │
│                      │          │                                │
│                      │Record    │                                │
│                      │outcome,  │                                │
│                      │improve   │                                │
│                      │future    │                                │
│                      │responses │                                │
│                      └──────────┘                                │
└──────────────────────────────────────────────────────────────────┘

EXAMPLE SCENARIO:
1. DETECT:  CloudWatch alarm — cartservice tasks restarting (CrashLoopBackOff equivalent)
2. DIAGNOSE: AI reads ECS stopped reason: "CannotPullContainerError" on image tag v2.3.1
             Checks ECR: image v2.3.1 doesn't exist (typo in last deploy, should be v2.31)
3. DECIDE:  Confidence > 90% → auto-remediate. Roll back to previous task def revision.
4. ACT:     Lambda calls ecs:UpdateService with previous task definition ARN.
5. LEARN:   Log the incident. Add "image tag validation" step to CI/CD pipeline.
```

### 8.5 AI DevOps Tools Worth Knowing (For Interviews)

| Tool / Platform              | Category              | Relevance to This Project                        |
|------------------------------|-----------------------|--------------------------------------------------|
| **Amazon Q Developer**       | AI Assistant          | IaC generation, troubleshooting, security review |
| **GitHub Copilot**           | Code AI               | Write Terraform, Dockerfiles, CI/CD workflows    |
| **Kiro IDE**                 | AI Dev Environment    | Spec-driven development, agent hooks for automation |
| **Harness AI**               | CI/CD Intelligence    | AI-powered deployment verification, auto-rollback |
| **Datadog AI**               | Observability AI      | Watchdog anomaly detection, AI-suggested monitors |
| **PagerDuty AIOps**          | Incident Management   | Alert correlation, noise reduction, auto-triage  |
| **Kubecost / CloudZero**     | Cost AI               | AI-driven cost allocation and optimization       |
| **Snyk / Wiz**               | Security AI           | AI-prioritized vulnerability remediation         |
| **Pulumi AI**                | IaC Generation        | Natural language → infrastructure code           |
| **env0 / Spacelift**         | IaC Management        | AI-assisted plan review, drift detection         |

### 8.6 Interview Talking Points — AI in DevOps

**1. "How do you use AI in your DevOps workflow?"**

> "I integrate AI at three levels. First, at development time — I use AI coding
> assistants to generate Terraform modules, Dockerfiles, and CI/CD pipelines, then
> review and refine the output. Second, at operations time — I built a custom incident
> response agent using Amazon Bedrock that correlates CloudWatch alarms with X-Ray
> traces and ECS task events, then posts actionable analysis to Slack instead of raw
> alerts. Third, at governance time — a drift detection agent runs daily to compare
> actual AWS state against Git, catching manual changes that bypass the IaC pipeline."

**2. "What's the difference between AI-assisted and AI-autonomous DevOps?"**

> "AI-assisted is where we are today — the AI suggests, the human approves. My PR
> review bot flags risks but doesn't block merges. My ChatOps bot interprets commands
> but requires a second approval for production changes. AI-autonomous is the next
> step — self-healing systems that detect, diagnose, and remediate without human
> intervention. I've implemented a limited version: if an ECS task fails due to a
> known pattern like an image pull error, the system auto-rolls back. But for anything
> ambiguous, it escalates to a human. The key principle is: automate the obvious,
> escalate the uncertain."

**3. "How do you ensure AI agents don't cause outages?"**

> "Guardrails are everything. My agents operate on a pre-approved runbook model —
> the AI interprets intent and selects the right runbook, but the actual commands
> are pre-tested and scoped. There's a blast radius limit: agents can scale services
> or roll back deployments, but they cannot delete infrastructure or modify IAM
> policies. Every action is logged to an audit trail, and production changes require
> dual approval. I also use a confidence threshold — if the AI's diagnosis confidence
> is below 80%, it escalates to a human instead of acting."

### 8.7 Implementation Roadmap for AI DevOps (Phase 6)

Add this as a continuation of the 5-week plan in Appendix A:

### Phase 6 — AI DevOps Integration (Week 6-7)

- [ ] Deploy incident response Lambda with Amazon Bedrock integration
- [ ] Connect CloudWatch Alarms → SNS → Lambda → Slack pipeline
- [ ] Build AI PR review GitHub Action with project-specific context
- [ ] Create ChatOps Slack bot with pre-approved runbook library
- [ ] Set up infrastructure drift detection (EventBridge + Lambda)
- [ ] Configure guardrails: approval workflows, blast radius limits, audit logging
- [ ] Test self-healing loop with simulated failures (image pull error, OOM kill)
- [ ] Document AI agent architecture for team onboarding

---

## APPENDIX A: IMPLEMENTATION ORDER (Suggested Phases)

### Phase 1 — Foundation (Week 1)

- [ ] Create VPC with public/private/database subnets (Terraform or CloudFormation)
- [ ] Set up NAT Gateways, Internet Gateway, route tables
- [ ] Create Security Groups (ALB, ECS, Redis)
- [ ] Create ECR repositories (11 repos)
- [ ] Build and push all 11 Docker images to ECR
- [ ] Provision ElastiCache Redis cluster
- [ ] Create Secrets Manager secret for Redis endpoint

### Phase 2 — ECS Cluster & Services (Week 2)

- [ ] Create ECS Cluster with Fargate capacity provider
- [ ] Set up AWS Cloud Map namespace (onlineboutique.local)
- [ ] Create ECS Task Definitions for all 11 services
- [ ] Create ECS Services with Service Connect enabled
- [ ] Create ALB, target group, and listener for frontend
- [ ] Verify end-to-end connectivity (frontend → backends → Redis)

### Phase 3 — CI/CD (Week 3)

- [ ] Set up AWS IAM OIDC provider for GitHub Actions
- [ ] Create IAM role for GitHub Actions with scoped permissions
- [ ] Write and test the GitHub Actions deployment workflow
- [ ] Verify rolling deployment with a code change
- [ ] Add path-based change detection for per-service deploys

### Phase 4 — Observability (Week 4)

- [ ] Add ADOT sidecar to all task definitions
- [ ] Configure ADOT collector (X-Ray + CloudWatch + AMP exporters)
- [ ] Set up Amazon Managed Prometheus workspace
- [ ] Set up Amazon Managed Grafana workspace with dashboards
- [ ] Create CloudWatch alarms (5 critical alarms)
- [ ] Set up SNS topics for alarm notifications
- [ ] Verify traces appear in X-Ray, metrics in Grafana

### Phase 5 — Hardening (Week 5)

- [ ] Enable ECS Auto Scaling on all services
- [ ] Add ACM certificate and HTTPS listener on ALB
- [ ] Enable WAF on ALB (optional, for DDoS protection)
- [ ] Set CloudWatch log retention policies
- [ ] Run loadgenerator and validate scaling behavior
- [ ] Document runbooks for common operational scenarios
- [ ] Cost review and right-sizing adjustments

---

## APPENDIX B: KEY COMMANDS REFERENCE

```bash
# Create ECR repository for a service
aws ecr create-repository --repository-name online-boutique/frontend --region us-east-1

# Build and push an image
docker build -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/frontend:v1 src/frontend/
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/online-boutique/frontend:v1

# Register a task definition
aws ecs register-task-definition --cli-input-json file://task-definitions/frontend.json

# Create an ECS service
aws ecs create-service \
  --cluster online-boutique-prod \
  --service-name online-boutique-frontend \
  --task-definition online-boutique-frontend \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=DISABLED}"

# Force a new deployment (rolling restart)
aws ecs update-service --cluster online-boutique-prod --service online-boutique-frontend --force-new-deployment

# Check service events
aws ecs describe-services --cluster online-boutique-prod --services online-boutique-frontend --query 'services[0].events[:5]'
```

---

*Plan created: April 30, 2026*
*Target: Production-grade AWS ECS Fargate deployment for Online Boutique microservices demo*
