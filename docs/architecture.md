# AWS Architecture - Birthday API

## Overview

High-availability production deployment on AWS with GitOps automation, service mesh, and multi-AZ redundancy.

---

## Architecture Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Infrastructure** | Terraform | Provision all AWS resources as code |
| **Compute** | EKS 1.31 | Kubernetes cluster across 3 AZs |
| **Application** | FastAPI + Uvicorn | Birthday API (6+ pod replicas) |
| **Database** | RDS PostgreSQL 18.1 | Multi-AZ primary + standby + read replicas |
| **Load Balancing** | ALB | HTTPS traffic distribution |
| **Service Mesh** | Istio | mTLS, traffic management, observability |
| **GitOps** | ArgoCD | Automated deployments from Git |
| **Package Management** | Helm | Kubernetes application packaging |
| **Container Registry** | ECR | Docker images |
| **Secrets** | Secrets Manager | Credentials with auto-rotation |
| **DNS** | Route 53 | Domain routing + health checks |
| **Security** | WAF | DDoS protection + rate limiting |
| **Logging** | CloudWatch | Centralized logs and metrics |

---

## Network Architecture

### VPC Layout

**CIDR**: `10.0.0.0/16`

**Public Subnets** (Internet-facing)
- `10.0.1.0/24` - AZ A
- `10.0.2.0/24` - AZ B  
- `10.0.3.0/24` - AZ C

**Private App Subnets** (EKS worker nodes)
- `10.0.11.0/24` - AZ A
- `10.0.12.0/24` - AZ B
- `10.0.13.0/24` - AZ C

**Private DB Subnets** (RDS instances)
- `10.0.21.0/24` - AZ A
- `10.0.22.0/24` - AZ B
- `10.0.23.0/24` - AZ C

### Components per AZ

**Public Subnet**: ALB, NAT Gateway  
**Private App Subnet**: EKS worker nodes, API pods with Envoy sidecars, Kubernetes services  
**Private DB Subnet**: RDS instances (Primary in AZ A, Standby in AZ B, Read Replica in AZ C)

---

## Infrastructure Provisioning (Terraform)

All infrastructure is defined and deployed using Terraform:

**Core Resources**:
- VPC with 9 subnets across 3 AZs
- Internet Gateway and NAT Gateways
- Security Groups with least privilege rules
- EKS cluster with managed node groups
- RDS PostgreSQL with Multi-AZ and read replicas
- Application Load Balancer
- Route 53 DNS records
- ACM SSL/TLS certificates
- WAF web ACL with security rules
- ECR repositories
- Secrets Manager secrets
- IAM roles and policies
---

## Service Mesh (Istio)

Istio provides advanced traffic management and security for pod-to-pod communication.

**Capabilities**:
- **mTLS**: Automatic mutual TLS between all services
- **Traffic Management**: Canary deployments, A/B testing, circuit breakers
- **Observability**: Distributed tracing, metrics, service graph
- **Security**: Authorization policies, network segmentation

**Pod Structure**:
```
┌─────────────────┐
│  Application    │
│  Container      │ ← Main API
├─────────────────┤
│  Envoy Proxy    │ ← Istio sidecar
│  (Sidecar)      │
└─────────────────┘
```

All traffic flows through Envoy, enabling transparent security and observability without application code changes.

---

## Component Relationships

### Infrastructure Deployment

```
Developer
  ↓ terraform apply
Terraform
  ├─ VPC + Subnets
  ├─ EKS Cluster
  ├─ RDS Database
  ├─ ALB + Route53
  ├─ Security Groups
  └─ IAM Roles
       ↓
AWS Resources (provisioned)
```

### GitOps Deployment

```
Developer
  ↓ git push
GitHub Repository
  ↓ webhook trigger
GitHub Actions (CI/CD)
  ├─ run tests
  ├─ build Docker image
  ├─ push to ECR
  └─ update Helm values
       ↓
GitHub Repository (updated)
  ↓ poll (every 3 min)
ArgoCD
  ↓ detect changes
Helm Charts
  ↓ apply to cluster
Kubernetes API
  ↓ rolling update
EKS Worker Nodes
  ↓ pull image from ECR
API Pods (updated)
```

### User Traffic

```
End User
  ↓ HTTPS
Route 53 (DNS)
  ↓
WAF (Security filtering)
  ↓
Internet Gateway
  ↓
Application Load Balancer (Multi-AZ)
  ↓
Istio Ingress Gateway
  ↓
Kubernetes Service
  ↓
Envoy Sidecar (mTLS)
  ↓
API Pod (FastAPI)
  ↓
RDS PostgreSQL (Primary)
  ⇄ Sync Replication ⇄ RDS Standby
  ⇄ Async Replication ⇄ RDS Read Replica
```
---

## High Availability Strategy

**Multi-AZ Deployment**:
- EKS worker nodes distributed across 3 AZs
- Minimum 2 API pods per AZ (6+ total)
- RDS Multi-AZ with automatic failover
- ALB spans all 3 AZs with health checks

**Auto-scaling**:
- Horizontal Pod Autoscaler: 2-4 pods based on CPU/memory
- Cluster Autoscaler: adds/removes nodes based on demand
- RDS: vertical scaling via instance class changes

**Failover Scenarios**:
- Pod failure: Kubernetes restarts automatically
- Node failure: Pods rescheduled to healthy nodes
- AZ failure: Traffic routed to remaining 2 AZs
- RDS primary failure: Automatic promotion of standby (<2 min)

---

## Security Layers

**Network Security**:
- Private subnets for application and database
- Security groups with least privilege
- Network ACLs as secondary defense

**Application Security**:
- WAF rules: SQL injection, XSS, rate limiting
- Istio mTLS: encrypted pod-to-pod communication
- Pod Security Standards: restricted mode

**Data Security**:
- Secrets Manager: encrypted credentials
- TLS 1.2+ for all external traffic (ACM certificates)

**Access Control**:
- IAM roles for service accounts.
- Least privilege policies
- No pods run as root

---

## Observability

**Logging** (CloudWatch):
- Application logs from all pods
- EKS control plane logs
- RDS database logs

**Metrics** (CloudWatch):
- Pod CPU/memory utilization
- Node resource usage
- RDS performance metrics
- ALB request/error rates

**Enhanced Monitoring** (Prometheus + Grafana - Optional, more advanced)

---

## Deployment Process

### Initial Setup

1. **Provision Infrastructure**
   - Configure Terraform state backend (S3 + DynamoDB)
   - Apply Terraform configurations for VPC, EKS, RDS
   - Verify all resources created successfully

2. **Bootstrap Kubernetes**
   - Install Istio service mesh
   - Deploy ArgoCD in cluster
   - Configure external-secrets operator
   - Set up ingress controller

3. **Configure GitOps**
   - Create ArgoCD applications for API and dependencies
   - Connect ArgoCD to GitHub repository
   - Enable auto-sync and self-heal

4. **Deploy Application**
   - Push Helm charts to Git repository
   - ArgoCD automatically syncs and deploys
   - Verify pods running with Istio sidecars

5. **Application**
   - Test your application.
