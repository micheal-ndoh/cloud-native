# Cloud Native Gauntlet - Architecture Diagram

## System Architecture Overview

```mermaid
graph TB
    subgraph "Infrastructure Layer"
        VM1[K3s Master VM<br/>10.38.229.161]
        VM2[K3s Worker VM<br/>10.38.229.69]
        REG[Docker Registry VM<br/>10.38.229.242]
    end
    
    subgraph "Kubernetes Cluster"
        subgraph "Control Plane"
            API[API Server]
            ETCD[etcd]
            SCHED[Scheduler]
            CM[Controller Manager]
        end
        
        subgraph "Worker Nodes"
            KUBELET[Kubelet]
            PROXY[kube-proxy]
            CNI[CNI Plugin]
        end
    end
    
    subgraph "Service Mesh"
        LINKERD[Linkerd Control Plane]
        PROXY_MESH[Linkerd Proxy Sidecars]
        VIZ[Linkerd Viz]
    end
    
    subgraph "Applications"
        subgraph "Authentication (keycloak namespace)"
            KC[Keycloak Server]
            KC_SVC[Keycloak Service]
            KC_ING[Keycloak Ingress]
        end
        
        subgraph "Backend (backend namespace)"
            API_APP[Task API Server]
            API_SVC[Task API Service]
            API_ING[Task API Ingress]
        end
        
        subgraph "Database (database namespace)"
            PG[PostgreSQL Cluster<br/>CloudNativePG]
            PG_SVC[PostgreSQL Service]
        end
        
        subgraph "CI/CD (ci namespace)"
            DRONE[Drone CI Server]
            DRONE_SVC[Drone Service]
            DRONE_ING[Drone Ingress]
        end
        
        subgraph "GitOps (gitea namespace)"
            GITEA[Gitea Server]
            GITEA_SVC[Gitea Service]
            GITEA_ING[Gitea Ingress]
        end
        
        subgraph "Monitoring (monitoring namespace)"
            PROM[Prometheus]
            GRAF[Grafana]
            PROM_SVC[Prometheus Service]
            GRAF_SVC[Grafana Service]
        end
        
        subgraph "GitOps Control (argocd namespace)"
            ARGO[ArgoCD Server]
            ARGO_SVC[ArgoCD Service]
        end
    end
    
    subgraph "External Access"
        TRAEFIK[Traefik Ingress Controller]
        DOMAINS[Local Domains:<br/>keycloak.local<br/>task-api.local<br/>gitea.local<br/>drone.local<br/>grafana.local<br/>prometheus.local]
    end
    
    %% Infrastructure connections
    VM1 --> VM2
    REG --> VM1
    REG --> VM2
    
    %% Kubernetes connections
    VM1 --> API
    VM1 --> ETCD
    VM1 --> SCHED
    VM1 --> CM
    VM2 --> KUBELET
    VM2 --> PROXY
    VM2 --> CNI
    
    %% Service mesh connections
    LINKERD --> PROXY_MESH
    VIZ --> LINKERD
    
    %% Application connections
    KC --> KC_SVC
    KC_SVC --> KC_ING
    API_APP --> API_SVC
    API_SVC --> API_ING
    PG --> PG_SVC
    DRONE --> DRONE_SVC
    DRONE_SVC --> DRONE_ING
    GITEA --> GITEA_SVC
    GITEA_SVC --> GITEA_ING
    PROM --> PROM_SVC
    GRAF --> GRAF_SVC
    ARGO --> ARGO_SVC
    
    %% Service mesh injection
    PROXY_MESH -.-> KC
    PROXY_MESH -.-> API_APP
    PROXY_MESH -.-> PG
    PROXY_MESH -.-> DRONE
    PROXY_MESH -.-> GITEA
    PROXY_MESH -.-> PROM
    PROXY_MESH -.-> GRAF
    PROXY_MESH -.-> ARGO
    
    %% External access
    TRAEFIK --> KC_ING
    TRAEFIK --> API_ING
    TRAEFIK --> DRONE_ING
    TRAEFIK --> GITEA_ING
    TRAEFIK --> PROM_SVC
    TRAEFIK --> GRAF_SVC
    DOMAINS --> TRAEFIK
    
    %% Data flow
    API_APP --> PG
    API_APP --> KC
    ARGO --> GITEA
    DRONE --> GITEA
    PROM --> API_APP
    PROM --> KC
    PROM --> PG
    PROM --> LINKERD
    GRAF --> PROM
    
    %% Styling
    classDef vm fill:#e1f5fe
    classDef k8s fill:#f3e5f5
    classDef mesh fill:#e8f5e8
    classDef app fill:#fff3e0
    classDef external fill:#fce4ec
    
    class VM1,VM2,REG vm
    class API,ETCD,SCHED,CM,KUBELET,PROXY,CNI k8s
    class LINKERD,PROXY_MESH,VIZ mesh
    class KC,API_APP,PG,DRONE,GITEA,PROM,GRAF,ARGO app
    class TRAEFIK,DOMAINS external
```

## Component Details

### Infrastructure
- **Multipass VMs**: Lightweight Ubuntu VMs running K3s
- **Docker Registry**: Local container registry for offline deployment
- **K3s**: Lightweight Kubernetes distribution

### Service Mesh
- **Linkerd**: Ultra-lightweight service mesh providing mTLS and observability
- **Linkerd Viz**: Observability dashboard for service mesh

### Applications
- **Keycloak**: Identity and access management with JWT authentication
- **Task API**: Rust-based REST API with PostgreSQL backend
- **PostgreSQL**: CloudNativePG-managed database cluster
- **Drone CI**: Continuous integration server
- **Gitea**: Self-hosted Git service
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Metrics visualization and dashboards
- **ArgoCD**: GitOps continuous deployment

### External Access
- **Traefik**: Ingress controller for external access
- **Local Domains**: Development-friendly domain names