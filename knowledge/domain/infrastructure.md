# Infrastructure Knowledge Base

## Overview

Guía práctica para diseñar y operar infraestructura cloud, containers, CI/CD y IaC. Enfocado en patrones probados y best practices.

---

## Containers

### Docker Best Practices

#### Dockerfile Optimization

```dockerfile
# Multi-stage build (RECOMMENDED)
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies first (cache layer)
COPY package*.json ./
RUN npm ci --only=production

# Copy source and build
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production

# Security: non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

WORKDIR /app

# Copy only necessary files
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

#### Layer Caching Strategy

```dockerfile
# ORDEN IMPORTA - De menos a más frecuente cambio

# 1. Base image (rarely changes)
FROM node:20-alpine

# 2. System dependencies (rarely changes)
RUN apk add --no-cache curl

# 3. Application dependencies (changes with package.json)
COPY package*.json ./
RUN npm ci

# 4. Source code (changes frequently)
COPY . .
RUN npm run build
```

#### Security Checklist

- [ ] Use specific image tags, not `latest`
- [ ] Use official/verified base images
- [ ] Run as non-root user
- [ ] No secrets in Dockerfile
- [ ] Minimal base image (alpine, distroless)
- [ ] Scan images for vulnerabilities
- [ ] Set resource limits
- [ ] Use .dockerignore

### Docker Compose for Development

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app
      - /app/node_modules  # Prevent overwrite
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://user:pass@db:5432/app
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=app
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Kubernetes

### Deployment Patterns

#### Basic Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:1.0.0
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
```

#### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

#### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### Resource Management

**Requests vs Limits:**
```yaml
resources:
  requests:        # Guaranteed resources
    memory: "256Mi"
    cpu: "250m"
  limits:          # Maximum allowed
    memory: "512Mi"
    cpu: "500m"

# Best practices:
# - Set requests based on typical usage
# - Set limits based on max acceptable
# - CPU limit can cause throttling (consider not setting)
# - Memory limit prevents OOM kills
```

**Resource Quotas (Namespace level):**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
```

### ConfigMaps and Secrets

```yaml
# ConfigMap for non-sensitive config
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  FEATURE_FLAGS: |
    {
      "new_feature": true,
      "beta_feature": false
    }

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:  # Will be base64 encoded
  database-url: "postgres://user:pass@host/db"
  api-key: "secret-key-here"

# Use in deployment:
# envFrom:
# - configMapRef:
#     name: app-config
# - secretRef:
#     name: app-secrets
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```

---

## CI/CD

### Pipeline Design

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI/CD Pipeline                            │
├─────────┬─────────┬─────────┬─────────┬─────────┬──────────────┤
│  Lint   │  Test   │  Build  │Security │ Deploy  │   Deploy     │
│         │         │         │  Scan   │   Dev   │    Prod      │
│ (auto)  │ (auto)  │ (auto)  │ (auto)  │ (auto)  │  (manual)    │
└─────────┴─────────┴─────────┴─────────┴─────────┴──────────────┘
     │         │         │         │         │           │
     │         │         │         │         │           │
   Fail →    Fail →   Fail →    Fail →   Fail →      Fail →
   Stop      Stop     Stop      Stop     Stop        Rollback
```

### GitHub Actions Example

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Run linter
      run: npm run lint

  test:
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Run tests
      run: npm test
      env:
        DATABASE_URL: postgres://postgres:test@localhost:5432/test

    - name: Upload coverage
      uses: codecov/codecov-action@v3

  build:
    runs-on: ubuntu-latest
    needs: test
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    steps:
    - uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=sha,prefix=
          type=ref,event=branch

    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  security-scan:
    runs-on: ubuntu-latest
    needs: build
    steps:
    - uses: actions/checkout@v4

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  deploy-dev:
    runs-on: ubuntu-latest
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/develop'
    environment: development
    steps:
    - name: Deploy to dev
      run: |
        # kubectl set image deployment/app app=$IMAGE
        echo "Deploying to dev"

  deploy-prod:
    runs-on: ubuntu-latest
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/main'
    environment: production  # Requires approval
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying to production"
```

### Deployment Strategies

**Rolling Update:**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
```

**Blue-Green:**
```
1. Deploy new version (green) alongside old (blue)
2. Test green
3. Switch traffic to green
4. Remove blue

# Implementation: Two deployments, switch service selector
```

**Canary:**
```
1. Deploy new version to small % of traffic
2. Monitor metrics
3. Gradually increase %
4. If issues, rollback

# Implementation: Use service mesh (Istio) or ingress weights
```

---

## Infrastructure as Code

### Terraform Structure

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   ├── rds/
│   └── redis/
└── global/
    └── iam/
```

### Terraform Best Practices

```hcl
# modules/vpc/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use data sources for existing resources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

# Public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}-public-${count.index + 1}"
    Type = "public"
  })
}

# Private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.environment}-private-${count.index + 1}"
    Type = "private"
  })
}

# Outputs
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}
```

### State Management

```hcl
# Remote state (REQUIRED for teams)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# State locking prevents concurrent modifications
```

---

## Cloud Architecture Patterns

### Multi-AZ Deployment

```
                    ┌─────────────────┐
                    │  Route 53 (DNS) │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │   CloudFront    │
                    │     (CDN)       │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │  Load Balancer  │
                    │    (ALB/NLB)    │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
    ┌──────┴──────┐   ┌──────┴──────┐   ┌──────┴──────┐
    │    AZ-1     │   │    AZ-2     │   │    AZ-3     │
    │  ┌───────┐  │   │  ┌───────┐  │   │  ┌───────┐  │
    │  │  App  │  │   │  │  App  │  │   │  │  App  │  │
    │  └───────┘  │   │  └───────┘  │   │  └───────┘  │
    │  ┌───────┐  │   │  ┌───────┐  │   │  ┌───────┐  │
    │  │ Cache │  │   │  │ Cache │  │   │  │ Cache │  │
    │  └───────┘  │   │  └───────┘  │   │  └───────┘  │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                 │                 │
           └─────────────────┼─────────────────┘
                             │
                    ┌────────┴────────┐
                    │    Database     │
                    │ (Primary + RR)  │
                    └─────────────────┘
```

### Microservices Communication

```
┌──────────────────────────────────────────────────────────────┐
│                      API Gateway                              │
│              (Auth, Rate Limit, Routing)                      │
└──────────────────────────────────────────────────────────────┘
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
       ▼                      ▼                      ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   User      │       │   Order     │       │  Product    │
│   Service   │       │   Service   │       │   Service   │
└──────┬──────┘       └──────┬──────┘       └──────┬──────┘
       │                     │                     │
       │         ┌───────────┴───────────┐        │
       │         │                       │        │
       │         ▼                       ▼        │
       │  ┌─────────────┐       ┌─────────────┐  │
       │  │   Message   │       │   Service   │  │
       │  │    Queue    │       │    Mesh     │  │
       │  │  (RabbitMQ/ │       │   (Istio)   │  │
       │  │    SQS)     │       │             │  │
       │  └─────────────┘       └─────────────┘  │
       │                                         │
       └──────────────────┬──────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Distributed Cache   │
              │   (Redis Cluster)     │
              └───────────────────────┘
```

---

## Monitoring & Observability

### Metrics Stack

```yaml
# Prometheus config
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### Log Aggregation

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   App Pod   │───▶│  Fluentd/   │───▶│Elasticsearch│
│  (stdout)   │    │  Fluent Bit │    │  / Loki     │
└─────────────┘    └─────────────┘    └─────────────┘
                                              │
                                              ▼
                                      ┌─────────────┐
                                      │   Kibana/   │
                                      │   Grafana   │
                                      └─────────────┘
```

### Alerting Rules

```yaml
# Prometheus alerting rules
groups:
- name: app-alerts
  rules:
  - alert: HighErrorRate
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      /
      sum(rate(http_requests_total[5m])) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value | humanizePercentage }}"

  - alert: HighLatency
    expr: |
      histogram_quantile(0.99,
        sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
      ) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High latency detected"
      description: "P99 latency is {{ $value | humanizeDuration }}"
```

---

## Disaster Recovery

### RTO and RPO

| Tier | RTO | RPO | Strategy |
|------|-----|-----|----------|
| Tier 1 (Critical) | < 1h | < 15min | Active-Active, sync replication |
| Tier 2 (Important) | < 4h | < 1h | Active-Passive, async replication |
| Tier 3 (Standard) | < 24h | < 24h | Backup-Restore |

### Backup Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                     Backup Strategy                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Database:                                                  │
│   ├── Continuous WAL archiving (PostgreSQL)                 │
│   ├── Daily snapshots (retained 30 days)                    │
│   ├── Weekly full backups (retained 90 days)                │
│   └── Monthly backups to cold storage (retained 1 year)     │
│                                                              │
│   Application State:                                         │
│   ├── Stateless design (no local state)                     │
│   └── Configuration in Git (GitOps)                         │
│                                                              │
│   Files/Blobs:                                               │
│   ├── S3 versioning enabled                                 │
│   ├── Cross-region replication                              │
│   └── Lifecycle policies for archival                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Runbook Template

```markdown
# Runbook: Database Failover

## Overview
Manual failover procedure for PostgreSQL database.

## Prerequisites
- AWS CLI configured
- kubectl access to cluster
- Database admin credentials

## Procedure

### 1. Assess the situation
```bash
# Check primary status
aws rds describe-db-instances --db-instance-identifier prod-primary

# Check replication lag
aws rds describe-db-instances --db-instance-identifier prod-replica \
  --query 'DBInstances[0].StatusInfos'
```

### 2. Promote replica (if needed)
```bash
aws rds promote-read-replica --db-instance-identifier prod-replica
```

### 3. Update application configuration
```bash
kubectl set env deployment/app DATABASE_HOST=new-primary-endpoint
```

### 4. Verify
```bash
# Check application logs
kubectl logs -l app=my-app --tail=100

# Check database connectivity
kubectl exec -it deploy/app -- nc -zv $DATABASE_HOST 5432
```

## Rollback
If failover causes issues:
1. Revert DATABASE_HOST to original
2. Investigate root cause
3. Schedule maintenance window for proper failover

## Contacts
- DBA Team: #dba-oncall
- Platform Team: #platform-oncall
```
