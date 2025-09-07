# Cloud Native Gauntlet - CI/CD Pipeline Diagram

## Complete CI/CD Pipeline Flow

```mermaid
graph TB
    subgraph "Developer Workflow"
        DEV[Developer]
        CODE[Code Changes]
        PUSH[Git Push]
    end
    
    subgraph "Git Repository (Gitea)"
        GIT[Gitea Server<br/>gitea.local]
        WEBHOOK[Webhook Trigger]
    end
    
    subgraph "CI Pipeline (Drone CI)"
        DRONE[Drone CI Server<br/>drone.local]
        BUILD[Build Stage]
        TEST[Test Stage]
        SECURITY[Security Scan]
        IMAGE[Build & Push Image]
    end
    
    subgraph "Container Registry"
        REGISTRY[Docker Registry<br/>10.38.229.242:5000]
        IMAGES[Container Images]
    end
    
    subgraph "GitOps (ArgoCD)"
        ARGO[ArgoCD Server]
        SYNC[Auto Sync]
        DEPLOY[Deploy to K8s]
    end
    
    subgraph "Kubernetes Cluster"
        subgraph "Backend Namespace"
            API_DEPLOY[Task API Deployment]
            API_SVC[Task API Service]
            API_ING[Task API Ingress]
        end
        
        subgraph "Monitoring Namespace"
            PROM_DEPLOY[Prometheus Deployment]
            GRAF_DEPLOY[Grafana Deployment]
        end
        
        subgraph "Other Namespaces"
            KC_DEPLOY[Keycloak Deployment]
            PG_DEPLOY[PostgreSQL Cluster]
            DRONE_DEPLOY[Drone CI Deployment]
            GITEA_DEPLOY[Gitea Deployment]
        end
    end
    
    subgraph "Service Mesh"
        LINKERD[Linkerd Control Plane]
        PROXY[Linkerd Proxy Sidecars]
        VIZ[Linkerd Viz Dashboard]
    end
    
    subgraph "Monitoring & Observability"
        METRICS[Prometheus Metrics]
        DASHBOARDS[Grafana Dashboards]
        ALERTS[Alerting Rules]
    end
    
    subgraph "External Access"
        TRAEFIK[Traefik Ingress]
        DOMAINS[Local Domains]
        USERS[End Users]
    end
    
    %% Developer workflow
    DEV --> CODE
    CODE --> PUSH
    PUSH --> GIT
    
    %% Git to CI
    GIT --> WEBHOOK
    WEBHOOK --> DRONE
    
    %% CI Pipeline stages
    DRONE --> BUILD
    BUILD --> TEST
    TEST --> SECURITY
    SECURITY --> IMAGE
    
    %% Image management
    IMAGE --> REGISTRY
    REGISTRY --> IMAGES
    
    %% GitOps flow
    GIT --> ARGO
    ARGO --> SYNC
    SYNC --> DEPLOY
    
    %% Kubernetes deployments
    DEPLOY --> API_DEPLOY
    DEPLOY --> PROM_DEPLOY
    DEPLOY --> GRAF_DEPLOY
    DEPLOY --> KC_DEPLOY
    DEPLOY --> PG_DEPLOY
    DEPLOY --> DRONE_DEPLOY
    DEPLOY --> GITEA_DEPLOY
    
    %% Service mesh integration
    LINKERD --> PROXY
    PROXY -.-> API_DEPLOY
    PROXY -.-> KC_DEPLOY
    PROXY -.-> PG_DEPLOY
    PROXY -.-> DRONE_DEPLOY
    PROXY -.-> GITEA_DEPLOY
    PROXY -.-> PROM_DEPLOY
    PROXY -.-> GRAF_DEPLOY
    
    %% Monitoring
    API_DEPLOY --> METRICS
    KC_DEPLOY --> METRICS
    PG_DEPLOY --> METRICS
    PROXY --> METRICS
    METRICS --> DASHBOARDS
    METRICS --> ALERTS
    
    %% External access
    API_DEPLOY --> API_SVC
    API_SVC --> API_ING
    API_ING --> TRAEFIK
    TRAEFIK --> DOMAINS
    DOMAINS --> USERS
    
    %% Observability access
    VIZ --> TRAEFIK
    DASHBOARDS --> TRAEFIK
    
    %% Styling
    classDef dev fill:#e3f2fd
    classDef git fill:#f1f8e9
    classDef ci fill:#fff3e0
    classDef registry fill:#fce4ec
    classDef gitops fill:#e8f5e8
    classDef k8s fill:#f3e5f5
    classDef mesh fill:#e1f5fe
    classDef monitor fill:#fff8e1
    classDef external fill:#fafafa
    
    class DEV,CODE,PUSH dev
    class GIT,WEBHOOK git
    class DRONE,BUILD,TEST,SECURITY,IMAGE ci
    class REGISTRY,IMAGES registry
    class ARGO,SYNC,DEPLOY gitops
    class API_DEPLOY,API_SVC,API_ING,PROM_DEPLOY,GRAF_DEPLOY,KC_DEPLOY,PG_DEPLOY,DRONE_DEPLOY,GITEA_DEPLOY k8s
    class LINKERD,PROXY,VIZ mesh
    class METRICS,DASHBOARDS,ALERTS monitor
    class TRAEFIK,DOMAINS,USERS external
```

## Pipeline Stages Detail

### 1. Developer Workflow
- Developer makes code changes
- Commits and pushes to Gitea repository
- Triggers webhook to Drone CI

### 2. CI Pipeline (Drone CI)
- **Build Stage**: Compile Rust application, run tests
- **Test Stage**: Unit tests, integration tests
- **Security Stage**: Vulnerability scanning
- **Image Stage**: Build Docker image and push to registry

### 3. GitOps Flow (ArgoCD)
- ArgoCD monitors Git repository changes
- Automatically syncs new configurations
- Deploys updated applications to Kubernetes

### 4. Service Mesh Integration
- Linkerd automatically injects sidecar proxies
- Provides mTLS encryption between services
- Enables observability and traffic management

### 5. Monitoring & Observability
- Prometheus collects metrics from all services
- Grafana provides visualization dashboards
- Linkerd Viz shows service mesh topology

### 6. External Access
- Traefik ingress controller routes external traffic
- Local domain names provide easy access
- End users can access applications via web browsers

## Key Features

### Automated Deployment
- **GitOps**: Configuration as code, automatic deployment
- **Service Mesh**: Automatic sidecar injection and mTLS
- **Monitoring**: Automatic metrics collection and alerting

### Offline Capability
- **Local Registry**: All images stored locally
- **Self-hosted Git**: Gitea provides Git hosting
- **Local Domains**: No external DNS dependencies

### Security
- **mTLS**: Automatic encryption between services
- **RBAC**: Role-based access control
- **JWT Authentication**: Secure API access

### Observability
- **Metrics**: Comprehensive application and infrastructure metrics
- **Dashboards**: Real-time visualization
- **Service Mesh**: Traffic flow and performance monitoring