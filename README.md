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
Docker Desktop: 4.53.0
Docker Hub: alopezt24/birthday-api
```

## Prerequisites
```bash
# Install tools
brew install minikube docker helm

# Start Minikube with Docker driver
minikube start --driver=docker --cpus=2 --memory=2048

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
docker login docker.io

# Build and push
chmod +x docker-build.sh
./docker-build.sh
```

### 3. Deploy with ArgoCD
```bash
# Deploy
kubectl apply -f argocd/postgres-app.yaml
kubectl apply -f argocd/birthday-api-app.yaml
```

### 4. Enable Network Access (macOS required)
```bash
# Terminal 1: Start Minikube tunnel (leave it running)
sudo minikube tunnel
# This will ask for your password and must stay running

# Terminal 2: Configure DNS
echo "127.0.0.1 birthday-api.local" | sudo tee -a /etc/hosts
```

**Important:** The `minikube tunnel` command must remain running in a separate terminal for the ingress to work on macOS.

## Testing
```bash
# Create user
curl -X PUT http://birthday-api.local/hello/andres \
  -H "Content-Type: application/json" \
  -d '{"dateOfBirth": "2000-01-15"}'

# Expected: 204 No Content

# Get message
curl http://birthday-api.local/hello/andres

# Expected: {"message": "Hello, andres! Your birthday is in X day(s)"}
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

# Check ingress
kubectl get ingress -n birthday-system
```

## Making Changes
```bash
# 1. Modify code
vim app/main.py

# 2. Build and push
./docker-build.sh

# 3. Commit and push
git add .
git commit -m "Update"
git push

# ArgoCD auto-syncs in 3 minutes
```

## Troubleshooting

### Ingress not accessible
```bash
# Verify minikube tunnel is running
# In a separate terminal, run:
sudo minikube tunnel

# Verify /etc/hosts entry
cat /etc/hosts | grep birthday-api.local
# Should show: 127.0.0.1 birthday-api.local

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress -n birthday-system
```

### Database connection issues
```bash
# Test database
kubectl run -it --rm debug --image=postgres:18.1-alpine --restart=Never -n birthday-system -- \
  psql postgresql://postgres:postgres@postgres.birthday-system.svc.cluster.local:5432/birthdays -c "SELECT 1;"
```

## Cleanup
```bash
# Stop minikube tunnel (Ctrl+C in the tunnel terminal)

# Delete applications
kubectl delete -f argocd/birthday-api-app.yaml
kubectl delete -f argocd/postgres-app.yaml

# Delete namespace
kubectl delete namespace birthday-system

# Remove DNS entry
sudo sed -i '' '/birthday-api.local/d' /etc/hosts

# Stop Minikube
minikube stop
```

## Project Structure
```
birthday-api/
├── app/                    # Python code
│   ├── main.py
│   ├── models.py
│   ├── db.py
│   └── requirements.txt
├── charts/
│   ├── birthday-api/      # Application Helm chart
│   └── postgres/          # Database Helm chart
├── argocd/                # ArgoCD applications
│   ├── birthday-api-app.yaml
│   └── postgres-app.yaml
├── Dockerfile
├── docker-build.sh
└── README.md
```

## Important Notes

### macOS Networking

On macOS with Docker Desktop, Minikube runs in a VM. The `minikube tunnel` command creates a network route from your Mac to the Minikube cluster:

- **Required:** `sudo minikube tunnel` must be running in a separate terminal
- **DNS:** Use `127.0.0.1` in `/etc/hosts`, not the Minikube IP
- **Password:** Tunnel requires sudo password to create network routes