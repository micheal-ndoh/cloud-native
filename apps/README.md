# Cloud Native Gauntlet - Applications

This directory contains the applications that make up the Cloud Native Gauntlet project, including Keycloak authentication, PostgreSQL database cluster, and a Rust-based task management API.

## Architecture Overview

The application stack consists of:

- **Authentication Layer**: Keycloak identity and access management
- **Database Layer**: CloudNativePG PostgreSQL cluster
- **Backend API**: Rust-based task management API with JWT authentication
- **Monitoring**: Prometheus and Grafana for observability

### Namespace Isolation

The application follows Kubernetes best practices with proper namespace isolation:

- **`keycloak` namespace**: Contains Keycloak authentication server and related resources
- **`database` namespace**: Contains all database-related resources (secrets, PostgreSQL cluster)
- **`backend` namespace**: Contains all backend API resources (deployment, service, ingress, configs)
- **`monitoring` namespace**: Contains monitoring stack (Prometheus, Grafana)

This separation ensures:
- Resource isolation and security boundaries
- Easier resource management and cleanup
- Clear separation of concerns
- Better access control and RBAC implementation

## Directory Structure

```
apps/
├── auth/               # Authentication components (namespace: keycloak)
│   ├── README.md              # Keycloak setup and authentication guide
│   ├── keycloak_auth_methods.md # Authentication flow documentation
│   ├── keycloak-deployment.yaml # Keycloak server deployment
│   ├── keycloak-service.yaml   # Keycloak service
│   ├── keycloak-configmap.yaml # Keycloak configuration
│   ├── keycloak-secret.yaml    # Keycloak secrets
│   └── keycloak-ingress.yaml   # Keycloak ingress
├── database/           # Database components (namespace: database)
│   ├── db-secret.yaml      # Database credentials
│   ├── cnpg-1.27.0.yaml   # CloudNativePG operator
│   └── cluster-app.yaml    # PostgreSQL cluster definition
├── backend/            # Backend API components (namespace: backend)
│   ├── task-api-secret.yaml    # API secrets
│   ├── task-api-configmap.yaml # API configuration
│   ├── task-api-deployment.yaml # API deployment
│   ├── task-api-service.yaml   # API service
│   ├── task-api-ingress.yaml  # API ingress
│   └── task-api/              # Source code
└── README.md           # This file
```

## Prerequisites

Before deploying the applications, ensure you have:

1. **K3s Cluster**: A running K3s cluster with Traefik ingress controller
2. **SSH Access**: SSH access to the master VM (configured via setup script)
3. **Terraform**: To get the master node IP address
4. **jq**: For JSON parsing in the deploy script
5. **Local SSH Key**: SSH key pair for authentication to VMs

**Note**: kubectl is NOT required on the host machine. All Kubernetes operations are executed on the master VM via SSH. The setup script automatically configures the kubeconfig file in the ubuntu user's home directory on the master VM.

## Setup and Deployment Workflow

### 1. Initial Setup

First, run the setup script to create the infrastructure and K3s cluster:

```bash
./scripts/setup.sh
```

This script will:
- Create VMs using Terraform
- Install and configure K3s cluster
- Set up SSH access to all VMs
- Mount project directory to master VM
- Configure kubeconfig for ubuntu user
- Verify cluster readiness

### 2. Application Deployment

After setup is complete, deploy applications using:

```bash
./scripts/deploy.sh
```

This script will:
1. **Connect to Master VM**: Establish SSH connection to the master VM
2. **Configure `/etc/hosts`**: Point `task-api.local` to your master node IP
3. **Update Registry IPs**: Dynamically replace hardcoded registry IPs with actual registry IP from Terraform
4. **Deploy on Master VM**: Execute all kubectl commands on the master VM via SSH:
   - Database components in order: secret → operator → cluster
   - Backend components in order: secret → configmap → deployment → service → ingress
   - Monitoring stack
5. **Wait for readiness**: Monitor deployment status on the master VM
6. **Display status**: Show comprehensive deployment information including registry details

**Note**: The deploy script runs locally but executes all Kubernetes operations on the master VM, ensuring proper cluster access and avoiding local kubectl configuration issues. It automatically updates Docker registry IPs in manifests to match your actual registry IP.

### Manual Deployment

If you prefer to deploy manually, follow this order:

#### 1. Database Components

```bash
# SSH to master VM first
ssh ubuntu@<MASTER_IP>

# Navigate to project directory
cd /home/ubuntu/projects

# Create namespace
kubectl create namespace database

# Deploy database secret
kubectl apply -f apps/database/db-secret.yaml

# Deploy CloudNativePG operator
kubectl apply -f apps/database/cnpg-1.27.0.yaml

# Deploy database cluster
kubectl apply -f apps/database/cluster-app.yaml

# Wait for cluster to be ready
kubectl wait --for=condition=ready --timeout=300s cluster/cluster-app -n database
```

#### 2. Backend Components

```bash
# Create namespace
kubectl create namespace backend

# Deploy in order
kubectl apply -f apps/backend/task-api-secret.yaml
kubectl apply -f apps/backend/task-api-configmap.yaml
kubectl apply -f apps/backend/task-api-deployment.yaml
kubectl apply -f apps/backend/task-api-service.yaml
kubectl apply -f apps/backend/task-api-ingress.yaml

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/task-api -n backend
```

#### 3. Auth Components

```bash
# Create namespace
kubectl create namespace keycloak

# Deploy in order
kubectl apply -f apps/auth/keycloak-secret.yaml
kubectl apply -f apps/auth/keycloak-configmap.yaml
kubectl apply -f apps/auth/keycloak-deployment.yaml
kubectl apply -f apps/auth/keycloak-service.yaml
kubectl apply -f apps/auth/keycloak-ingress.yaml

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/keycloak -n keycloak
```

**Note**: All kubectl commands must be run on the master VM where the K3s cluster is running. The manifests now include proper namespace definitions, so `-n` flags are not needed. The deploy script automatically uses the correct kubeconfig path (`/home/ubuntu/.kube/config`) for all kubectl operations. The setup script automatically mounts the project directory to `/home/ubuntu/projects/` on the master VM.

## Domain Configuration

The application uses `task-api.local` as the domain name. The deploy script automatically configures your `/etc/hosts` file to point this domain to your master node IP.

If you prefer to use a different domain:

1. Update `apps/backend/task-api-ingress.yaml`
2. Modify the deploy script or manually update `/etc/hosts`
3. Replace `task-api.local` with your preferred domain in all examples

## Usage

### API Access

Once deployed, the API is accessible at:

- **Base URL**: `http://task-api.local`
- **Health Check**: `http://task-api.local/api/health`
- **API Endpoints**: `http://task-api.local/api/*`

### Authentication

The application uses Keycloak for identity and access management with JWT-based authentication. The Task API integrates with Keycloak for user authentication and role-based access control.

**For complete Keycloak setup and authentication instructions, see [auth/README.md](auth/README.md)**

Quick authentication example:

```bash
# Get JWT token from Keycloak
TOKEN=$(curl -s -X POST "http://keycloak.local/realms/task-realm/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=task-api-client" \
  -d "username=testuser" \
  -d "password=testpass" | jq -r .access_token)

# Use token for API calls
curl -H "Authorization: Bearer $TOKEN" http://task-api.local/api/tasks
```

**Authentication Features:**
- JWT token-based authentication
- Role-based access control (Admin/User)
- Keycloak integration for user management
- UUID-based user identification
- Structured logging for authentication events

### Database Access

To connect to the PostgreSQL database:

```bash
# Get a shell into the db pod
kubectl exec -it pod/cluster-app-1 -n database -- bash

# Connect using psql
psql -U admin -d database -h localhost
# Password: password123
```

**Note**: The database is in the `database` namespace, so all database-related commands need the `-n database` flag.

### API Testing Examples

#### Health Check
```bash
curl http://task-api.local/api/health
```

#### User Login
```bash
curl -X POST http://task-api.local/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "adminpassword"}' | jq
```

#### Get Tasks (requires authentication token)
```bash
# First get a token from login, then use it
TOKEN="your_jwt_token_here"
curl -H "Authorization: Bearer $TOKEN" \
  http://task-api.local/api/tasks
```

## Monitoring

The monitoring stack provides:

- **Grafana**: Dashboard at `http://<MASTER_IP>:30001` (admin/admin)
- **Prometheus**: Metrics at `http://<MASTER_IP>:30002`

## Troubleshooting

### Common Issues

1. **SSH Connection**: Ensure SSH access to master VM is working
2. **Domain Resolution**: Ensure `/etc/hosts` is properly configured
3. **Database Connection**: Check if the PostgreSQL cluster is ready
4. **API Access**: Verify the ingress is properly configured

### Debug Commands

#### SSH Connectivity
```bash
# Test SSH connection to master VM
ssh -o ConnectTimeout=10 ubuntu@<MASTER_IP> "echo 'SSH working'"

# Check SSH key permissions
ls -la ~/.ssh/
```

#### Cluster Status (via SSH)
```bash
# Check pod status
ssh ubuntu@<MASTER_IP> "kubectl get pods -n database"
ssh ubuntu@<MASTER_IP> "kubectl get pods -n backend"

# Check ingress
ssh ubuntu@<MASTER_IP> "kubectl get ingress -n backend"

# Check services
ssh ubuntu@<MASTER_IP> "kubectl get svc -n backend"

# View logs
ssh ubuntu@<MASTER_IP> "kubectl logs -f deployment/task-api -n backend"
ssh ubuntu@<MASTER_IP> "kubectl logs -f cluster/cluster-app -n database"

# Check events
ssh ubuntu@<MASTER_IP> "kubectl get events -n database"
ssh ubuntu@<MASTER_IP> "kubectl get events -n backend"
```

### Reset Deployment

To completely reset the deployment:

```bash
# Delete all resources
kubectl delete namespace backend
kubectl delete namespace database
kubectl delete -f apps/database/cnpg-1.27.0.yaml

# Remove from /etc/hosts
sudo sed -i '/task-api.local/d' /etc/hosts

# Redeploy
./scripts/deploy.sh
```

## Development

### Backend API

The backend API is written in Rust using:
- **Framework**: Axum web framework
- **Database**: PostgreSQL with SQLx
- **Authentication**: JWT tokens
- **Migrations**: SQLx migrations for database schema

### Database

The database uses:
- **Operator**: CloudNativePG for PostgreSQL management
- **Instances**: 1 PostgreSQL instance
- **Storage**: 5Gi storage
- **Version**: PostgreSQL 16.4

## Security Notes

- Database credentials are stored in Kubernetes secrets
- API secrets are managed via Kubernetes secrets
- JWT tokens are used for API authentication
- Consider using external secret management for production

## Contributing

When adding new components:

1. Follow the existing naming convention
2. Update this README with new information
3. Ensure proper namespace isolation
4. Add appropriate health checks and monitoring
5. Update the deploy script if needed
