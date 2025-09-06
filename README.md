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
- **install-argocd.sh**: ArgoCD installation script for GitOps

### GitOps
- **ArgoCD**: GitOps continuous deployment tool (installation script provided)
- **Application Definitions**: ArgoCD application configurations for App1 and Monitoring
- **Automated Sync**: Automatic deployment from Git changes (when fully implemented)

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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request# cloud-native
