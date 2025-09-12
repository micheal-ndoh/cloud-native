[![Rust app](https://github.com/micheal-ndoh/cloud-native/actions/workflows/deploy.yml/badge.svg)](https://github.com/micheal-ndoh/cloud-native/actions/workflows/deploy.yml)

# Cloud Native Gauntlet

A comprehensive cloud-native project demonstrating Kubernetes deployment, monitoring, and infrastructure automation using K3s and Multipass.

## Project Overview

This project sets up a complete cloud-native environment with:
- **Infrastructure**: Multipass VMs running K3s Kubernetes cluster
- **Authentication**: Keycloak identity and access management
- **Applications**: Production-ready Task API with PostgreSQL database
- **Monitoring**: Prometheus and Grafana for observability (templates provided)
- **Automation**: Terraform and Ansible for infrastructure management
- **GitOps**: ArgoCD for continuous deployment

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   K3s Master    │    │   K3s Worker    │
│   (Multipass)   │    │   (Multipass)   │
│                 │    │                 │
│ - Control Plane │    │ - Worker Node   │
│ - etcd          │    │ - Applications  │
│ - API Server    │    │ - Monitoring    │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
                    │
    ┌───────────────────────────────────┐
    │          Applications             │
    │                                   │
    │  ┌─────────────┐ ┌─────────────┐  │
    │  │  Keycloak   │ │  Task API   │  │
    │  │   (Auth)    │ │ (Backend)   │  │
    │  └─────────────┘ └─────────────┘  │
    │                                   │
    │  ┌─────────────┐ ┌─────────────┐  │
    │  │ PostgreSQL  │ │ Monitoring  │  │
    │  │ (Database)  │ │   Stack     │  │
    │  └─────────────┘ └─────────────┘  │
    └───────────────────────────────────┘
```

## Prerequisites

- Multipass installed
- Terraform installed
- Ansible installed
- kubectl installed
- SSH key pair generated (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd cloud-native-gauntlet
   ```

2. **Run the automated setup script**:
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

3. **Verify the cluster**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

4. **Install GitOps with ArgoCD** (optional):
   ```bash
   chmod +x gitops/scripts/install-argocd.sh
   ./gitops/scripts/install-argocd.sh
   ```

5. **Deploy applications** (optional):
   ```bash
   chmod +x scripts/deploy.sh
   ./scripts/deploy.sh
   ```

6. **Observability (Linkerd Viz)**:
   - Open dashboard (requires Linkerd CLI):
     ```bash
     ./scripts/observability.sh dashboard
     ```
   - Or port-forward the web UI:
     ```bash
     ./scripts/observability.sh linkerd-viz port-forward
     # then open http://linkerd.local
     ```
   - Useful checks:
     ```bash
     ./scripts/observability.sh checks
     ./scripts/observability.sh _ stat backend task-api
     ./scripts/observability.sh _ tap backend task-api
     ./scripts/observability.sh _ routes backend task-api
     ```

## Project Structure

```
cloud-native-gauntlet/
├── README.md                    # Project overview and setup instructions
├── .gitignore                   # Git ignore patterns
├── infrastruture/                       # Infrastructure automation
│   ├── ansible/                 # Ansible playbooks for K3s setup
│   └── terraform/               # Terraform for VM creation
├── apps/                        # Application deployments
│   ├── README.md                # Application deployment guide
│   ├── auth/                    # Keycloak authentication (keycloak namespace)
│   │   ├── README.md            # Keycloak setup and auth guide
│   │   └── keycloak-*.yaml      # Keycloak deployment manifests
│   ├── database/                # Database components (database namespace)
│   │   ├── db-secret.yaml       # Database credentials
│   │   ├── cnpg-1.27.0.yaml     # CloudNativePG operator
│   │   └── cluster-app.yaml     # PostgreSQL cluster definition
│   └── backend/                 # Backend API components (backend namespace)
│       ├── task-api-*.yaml      # Task API deployment manifests
│       └── task-api/            # Rust Axum-based Task API source code
│           ├── README.md        # Task API documentation
│           ├── migrations/      # Sql migrations
│           ├── src/             # Rust source code with logging & auth
│           ├── Cargo.toml       # Rust dependencies
│           └── Dockerfile       # Container definition
├── monitoring/                  # Monitoring stack (templates - not yet implemented)
├── gitops/                      # GitOps configuration with ArgoCD
│   ├── README.md                # GitOps documentation
│   ├── argocd/                  # ArgoCD application definitions
│   └── scripts/                 # GitOps automation scripts
├── scripts/                     # Automation scripts
│   ├── setup.sh                 # Complete infrastructure setup
│   └── deploy.sh                # Application deployment script
└── kustomization/               # Environment-specific configs (templates - not yet implemented)
```

## Components

### Infrastructure
- **Terraform**: Creates Multipass VMs (master and worker) with dynamic IP allocation
- **Ansible**: Installs and configures K3s cluster
- **Multipass**: Lightweight VM provider for development

### Applications
- **Authentication**: Keycloak identity and access management (fully implemented)
  - JWT token-based authentication
  - Role-based access control (Admin/User)
  - OAuth2/OpenID Connect support
  - Admin console for user management
- **Task API**: RESTful API built with Rust and Axum (fully implemented)
  - Keycloak authentication integration
  - PostgreSQL database with UUID handling
  - Comprehensive structured logging system
  - Swagger UI documentation
  - Role-based endpoint protection
  - Cloud-native deployment ready
- **Gitea**: Self-hosted Git service with persistence enabled
  - PVC `gitea-data` (5Gi) stores `/data`
  - Ingress at `gitea.local`
- **Database**: PostgreSQL cluster using CloudNativePG operator
  - High-availability configuration
  - Automated backups and recovery
  - Kubernetes-native management
- **Monitoring**: Prometheus and Grafana (templates provided, not yet implemented)

### Automation
- **setup.sh**: Complete automated setup script (cross-platform)
  - Creates Multipass VMs with Terraform
  - Configures K3s cluster with Ansible
  - Sets up kubectl access
- **deploy.sh**: Application deployment script
  - Deploys monitoring stack
  - Deploys applications to K3s cluster
  - Applies ArgoCD Applications (GitOps) pointing at in-cluster Gitea
  - Enables Linkerd sidecar injection and restarts workloads
- **install-argocd.sh**: ArgoCD installation script for GitOps

### GitOps
- **ArgoCD**: GitOps continuous deployment tool (installation script provided)
- **Application Definitions**: Backend, Database, Keycloak, and Monitoring Applications
- **Source**: In-cluster Gitea repo `http://gitea.gitea.svc.cluster.local:3000/admin/cloud-native-gauntlet.git`
- **Automated Sync**: Enabled (prune + self-heal)

## Images (offline)

- Build and push backend image to local registry:
  ```bash
  cd apps/backend/task-api
  chmod +x build-and-push.sh
  ./build-and-push.sh
  ```
  Image tag used by Kubernetes: `registry.local:5000/task-api:latest`

## Troubleshooting

### Common Issues

#### 1. Prerequisites Not Installed
The setup script will check for required tools and provide installation instructions.

#### 2. SSH Key Issues
```bash
# Generate SSH key if missing
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

#### 3. Cluster Access Issues
```bash
# Check VM connectivity
ping <master-ip>
```

#### 4. Cleanup
```bash
# Destroy infrastructure
cd infrastruture/terraform
terraform destroy -auto-approve
```

## Access Endpoints

- API: `http://task-api.local/` (health: `http://task-api.local/api/health`, Swagger: `http://task-api.local/swagger-ui/`)
- Keycloak: `http://keycloak.local/admin/master/console/` (admin/admin)
- Gitea: `http://gitea.local/michealndoh` (first admin auto-created per deploy; see `apps/ci/drone-server.yaml` for DRONE_USER_CREATE)
- Drone CI: `http://drone.local/`
- Linkerd Viz: `http://linkerd.local/`
- Grafana: `http://grafana.local/` (admin/admin)
- Prometheus: `http://prom.local/`
- Argo CD: `http://argocd.local/` (set admin password via ArgoCD install or secret)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request# cloud-native

## Local hosts setup

Use the idempotent script to configure UI hostnames:

```bash
./scripts/fix-hosts.sh <INGRESS_IP> 10.38.229.242
```

## JWT quick test

Obtain a token from Keycloak and call the protected endpoint:

```bash
KC_URL=http://keycloak.local
REALM=task-api-realm
CLIENT=app-client
USER=testuser PASS=testpass

TOKEN=$(curl -s -X POST "$KC_URL/realms/$REALM/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=$CLIENT -d username=$USER -d password=$PASS \
  | jq -r .access_token)

curl -s -H "Authorization: Bearer $TOKEN" http://task-api.local/api/tasks | jq .
```

## Linkerd viz verification

If Linkerd CLI is available:

```bash
linkerd viz stat deploy -n backend --time-window 30s
linkerd viz edges deploy -n backend
```

Otherwise, verify sidecar and metrics via kubectl:

```bash
kubectl -n backend get pods -l app=task-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.containers[*]}{.name}{","}{end}{"\n"}{end}'
kubectl -n linkerd-viz port-forward svc/web 8084:8084 # or use http://linkerd.local
```

## Post-cleanup recovery (Gitea, ArgoCD, Drone)

After running the cleanup script to reclaim node storage, the following recovery actions were applied:

- Reprovisioned Gitea PVC on `k3s-master` and pinned `gitea` Deployment to `k3s-master` to resolve DiskPressure and volume node affinity.
- Recreated Gitea repositories and pushed code:
  - App repo: `http://gitea.local/michealndoh/Cloud-native.git`
  - Infra repo: `http://gitea.local/michealndoh/Cloud-native-infra.git`
- Added Drone webhooks to both repos (`http://drone.local/hook`) for push/PR events.
- Created new Gitea OAuth2 application for Drone and rotated Drone server credentials:
  - Client ID: `210a3da9-fe9d-4cf3-b137-854ad9c77782`
  - Redirect URI: `http://drone.local/login`
- Updated `.drone.yml` and `apps/ci/drone-server.yaml` to use the new token and OAuth client.

To rerun:
```bash
# Reclaim node space and restart services
chmod +x scripts/cleanup-nodes.sh
./scripts/cleanup-nodes.sh

# Re-sync Argo CD apps
kubectl annotate application.argoproj.io/root-apps -n argocd argo.argoproj.io/refresh=hard --overwrite || true
```
