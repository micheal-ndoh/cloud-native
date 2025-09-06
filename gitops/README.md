# GitOps Configuration

This directory contains the GitOps configuration for the Cloud Native Gauntlet project using ArgoCD.

## Overview

GitOps is a way to do continuous deployment by using Git as a single source of truth for declarative infrastructure and applications. This project uses ArgoCD to implement GitOps practices.

## Structure

```
gitops/
├── README.md                    # This file
├── argocd/                      # ArgoCD configuration
│   ├── install/                 # ArgoCD installation manifests
│   ├── applications/            # Application definitions
│   └── projects/                # ArgoCD project configurations
├── apps/                        # Application manifests for GitOps
│   ├── app1/                    # App1 manifests
│   ├── app2/                    # App2 manifests
│   └── monitoring/              # Monitoring stack manifests
└── scripts/                     # GitOps automation scripts
    └── install-argocd.sh        # ArgoCD installation script
```

## Components

### ArgoCD
- **ArgoCD Server**: Web UI and API server
- **Application Controller**: Manages application deployments
- **Repo Server**: Handles Git repository operations
- **Redis**: Caches repository data

### GitOps Workflow
1. **Git Repository**: Source of truth for all configurations
2. **ArgoCD Watcher**: Monitors repository for changes
3. **Automatic Sync**: Changes in Git trigger deployments
4. **Drift Detection**: ArgoCD detects and corrects drift
5. **Web UI**: Visual interface for monitoring deployments

## Usage

### Install ArgoCD
```bash
./scripts/install-argocd.sh
```

### Access ArgoCD UI
```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Deploy Applications via GitOps
```bash
# Applications will be automatically deployed from Git
kubectl get applications -n argocd
kubectl get applicationsets -n argocd
```

### Monitor GitOps Status
```bash
argocd app list
argocd app get <app-name>
argocd app logs <app-name>
```

## Benefits

- **Declarative**: All configurations stored in Git
- **Automated**: Changes automatically deployed
- **Auditable**: Complete history of changes
- **Secure**: Git provides access control
- **Consistent**: Same process for all environments
- **Visual**: Web UI for monitoring and management
- **Multi-Cluster**: Can manage multiple clusters
- **RBAC**: Role-based access control 