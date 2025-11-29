# Birthday API - Kubernetes Deployment

FastAPI application to manage user birthdays, deployed on Minikube with Helm and ArgoCD.

## Requirements

- Username: Only letters
- Date: YYYY-MM-DD format, must be in the past
- Response: Birthday message or days until birthday

## API Endpoints

- `PUT /hello/{username}` - Save/update user birthday
- `GET /hello/{username}` - Get birthday message
- `GET /health` - Health check

## Technology Stack
```
Python: 3.13.1
PostgreSQL: 18.1-alpine
FastAPI: 0.122.0
Uvicorn: 0.38.0
SQLAlchemy: 2.0.44
psycopg2-binary: 2.9.11
Kubernetes: 1.37.0 (via Minikube)
Helm: 4.x
ArgoCD: 3.2.0
Podman Desktop: 1.23
Docker Hub: alopezt24/birthday-api
```

## Prerequisites
```bash
# Install tools
brew install minikube podman helm

# Start Minikube
minikube start --driver=podman --cpus=2 --memory=2048

# Enable ingress
minikube addons enable ingress
```

## Quick Start

### 1. Install ArgoCD
```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Access UI (new terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

ArgoCD UI: https://localhost:8080 (admin / password-from-above)

### 2. Build and Push Image
```bash
# Login to Docker Hub
podman login docker.io

# Build and push
chmod +x podman-build.sh
./podman-build.sh
```

### 3. Deploy with ArgoCD
```bash

# Deploy
kubectl apply -f argocd/postgres-app.yaml
kubectl apply -f argocd/birthday-api-app.yaml

# Wait for sync
kubectl wait --for=condition=Synced application/postgres -n argocd --timeout=120s
kubectl wait --for=condition=Synced application/birthday-api -n argocd --timeout=120s
```

### 4. Configure DNS
```bash
echo "$(minikube ip) birthday-api.local" | sudo tee -a /etc/hosts
```

## Testing
```bash
# Create user
curl -X PUT http://birthday-api.local/hello/john \
  -H "Content-Type: application/json" \
  -d '{"dateOfBirth": "2000-01-15"}'

# Get message
curl http://birthday-api.local/hello/john
```

## Monitoring
```bash
# Check pods
kubectl get pods -n birthday-system

# Check logs
kubectl logs -l app.kubernetes.io/name=birthday-api -n birthday-system -f

# Check all resources
kubectl get all -n birthday-system

# ArgoCD status
kubectl get applications -n argocd
```

## Making Changes
```bash
# 1. Modify code
vim app/main.py

# 2. Build and push
./podman-build.sh

# 3. Commit and push
git add .
git commit -m "Update"
git push

# ArgoCD auto-syncs in 3 minutes
```

## Troubleshooting
```bash
# Test database
kubectl run -it --rm debug --image=postgres:18.1-alpine --restart=Never -n birthday-system -- \
  psql postgresql://postgres:postgres@postgres.birthday-system.svc.cluster.local:5432/birthdays -c "SELECT 1;"

# Check ingress
kubectl describe ingress -n birthday-system

# Force ArgoCD sync
kubectl patch application birthday-api -n argocd --type merge -p '{"operation":{"sync":{}}}'

# Restart pods
kubectl rollout restart deployment/birthday-api -n birthday-system
```

## Cleanup
```bash
# Delete applications
kubectl delete -f argocd/birthday-api-app.yaml
kubectl delete -f argocd/postgres-app.yaml

# Delete namespace
kubectl delete namespace birthday-system

# Stop Minikube
minikube stop
```

## Project Structure
```
birthday-api/
├── app/                    # Python code
├── charts/
│   ├── birthday-api/      # Application Helm chart
│   └── postgres/          # Database Helm chart
├── argocd/                # ArgoCD applications
├── Dockerfile
├── podman-build.sh
└── README.md
```