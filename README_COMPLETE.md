# Cloud Native Gauntlet - Complete Implementation Guide

[![Rust app](https://github.com/micheal-ndoh/cloud-native/actions/workflows/deploy.yml/badge.svg)](https://github.com/micheal-ndoh/cloud-native/actions/workflows/deploy.yml)

## 🎯 Project Overview

The Cloud Native Gauntlet is a comprehensive demonstration of modern cloud-native technologies, showcasing a complete end-to-end system running entirely offline. This project demonstrates Kubernetes deployment, service mesh, monitoring, GitOps, and infrastructure automation using K3s and Multipass.

## 🏗️ Architecture

### System Components
- **Infrastructure**: Multipass VMs running K3s Kubernetes cluster
- **Authentication**: Keycloak identity and access management with JWT
- **Applications**: Production-ready Task API with PostgreSQL database
- **Monitoring**: Prometheus and Grafana for observability
- **Service Mesh**: Linkerd for mTLS and observability
- **CI/CD**: Drone CI for continuous integration
- **GitOps**: ArgoCD for continuous deployment
- **Git Hosting**: Gitea for self-hosted Git repositories

### Technology Stack
- **Container Runtime**: Docker with local registry
- **Orchestration**: Kubernetes (K3s)
- **Service Mesh**: Linkerd with Viz observability
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: Drone CI + ArgoCD
- **Infrastructure**: Terraform + Ansible
- **Languages**: Rust (API), YAML (Kubernetes), Bash (Scripts)

## 🚀 Quick Start

### Prerequisites
- Multipass installed
- Docker installed
- kubectl installed
- Git installed

### 1. Infrastructure Setup
```bash
# Clone the repository
git clone http://gitea.local/michealndoh/Cloud-native-infra.git
cd Cloud-native-infra

# Run the complete setup
./scripts/setup.sh
```

### 2. Application Deployment
```bash
# Deploy all applications
./scripts/deploy.sh

# Verify deployment
kubectl get pods -A
```

### 3. Access Applications
- **Task API**: http://task-api.local
- **Keycloak**: http://keycloak.local (admin/admin123)
- **Gitea**: http://gitea.local (admin/admin123)
- **Drone CI**: http://drone.local
- **Grafana**: http://grafana.local (admin/admin123)
- **Prometheus**: http://prom.local
- **Linkerd Viz**: http://linkerd.local

## 📊 Monitoring & Observability

### Prometheus Metrics
- **Application Metrics**: HTTP requests, response times, error rates
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Service Mesh Metrics**: mTLS, traffic flow, latency
- **Database Metrics**: Connection pools, query performance

### Grafana Dashboards
- **System Overview**: Health status of all components
- **Application Performance**: Request rates, response times, errors
- **Infrastructure**: Resource utilization across nodes
- **Service Mesh**: Traffic topology and mTLS status

### Linkerd Viz
- **Service Topology**: Visual representation of service communication
- **Traffic Tap**: Real-time traffic inspection
- **Performance Metrics**: Latency, throughput, success rates
- **mTLS Status**: Certificate validation and encryption status

## 🔐 Security Features

### Authentication & Authorization
- **Keycloak**: Centralized identity management
- **JWT Tokens**: Secure API authentication
- **Role-Based Access**: Admin and User roles
- **OpenID Connect**: Industry-standard protocol

### Service Mesh Security
- **mTLS Encryption**: Automatic encryption between services
- **Certificate Management**: Automatic generation and rotation
- **Identity Verification**: Service-to-service authentication
- **Traffic Policies**: Fine-grained access control

### Network Security
- **Ingress Controller**: Traefik with TLS termination
- **Local Domains**: No external DNS exposure
- **Firewall Rules**: VM-level network isolation
- **Private Registry**: Container images stored locally

## 🔄 CI/CD Pipeline

### GitOps Workflow
1. **Developer**: Commits code to Gitea repository
2. **Drone CI**: Builds, tests, and pushes container images
3. **ArgoCD**: Monitors repository and auto-deploys changes
4. **Kubernetes**: Updates running applications

### Pipeline Stages
- **Build**: Compile Rust application
- **Test**: Unit and integration tests
- **Security**: Vulnerability scanning
- **Deploy**: Automatic deployment via GitOps

## 📁 Project Structure

```
cloud-native-gauntlet/
├── apps/                          # Application manifests
│   ├── auth/                      # Keycloak authentication
│   ├── backend/                   # Task API application
│   ├── database/                  # PostgreSQL cluster
│   ├── ci/                        # Drone CI configuration
│   └── gitea/                     # Git hosting service
├── monitoring/                    # Monitoring stack
│   ├── prometheus.yaml           # Prometheus configuration
│   ├── grafana.yaml              # Grafana configuration
│   └── dashboards/               # Custom dashboards
├── gitops/                        # GitOps configuration
│   ├── argocd/                   # ArgoCD applications
│   └── scripts/                  # GitOps automation
├── infrastructure/                # Infrastructure as Code
│   ├── terraform/                # VM provisioning
│   └── ansible/                  # K3s configuration
├── scripts/                       # Automation scripts
│   ├── setup.sh                  # Complete setup
│   ├── deploy.sh                 # Application deployment
│   └── observability.sh          # Monitoring helpers
└── docs/                          # Documentation
    ├── architecture-diagram.md   # System architecture
    ├── pipeline-diagram.md       # CI/CD pipeline
    └── auth-flow-diagram.md       # Authentication flow
```

## 🛠️ Troubleshooting Guide

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl get pods -A

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Check pod description
kubectl describe pod -n <namespace> <pod-name>
```

#### 2. Image Pull Errors
```bash
# Check if images exist in registry
docker images | grep <image-name>

# Check registry connectivity
curl http://10.38.229.242:5000/v2/_catalog

# Restart pods to retry image pull
kubectl delete pod -n <namespace> <pod-name>
```

#### 3. Service Mesh Issues
```bash
# Check Linkerd installation
linkerd check

# Check sidecar injection
kubectl get pods -n <namespace> -o yaml | grep linkerd-proxy

# Restart Linkerd
kubectl rollout restart deployment -n linkerd
```

#### 4. ArgoCD Sync Issues
```bash
# Check application status
kubectl get applications -n argocd

# Force sync application
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"}}}'

# Check application logs
kubectl logs -n argocd deployment/argocd-application-controller
```

#### 5. Database Connection Issues
```bash
# Check PostgreSQL cluster status
kubectl get clusters -n database

# Check database pods
kubectl get pods -n database

# Test database connection
kubectl exec -it -n database <postgres-pod> -- psql -U postgres -d tasks
```

#### 6. Monitoring Issues
```bash
# Check Prometheus targets
curl http://prom.local/api/v1/targets

# Check Grafana health
curl http://grafana.local/api/health

# Check Linkerd Viz
kubectl get pods -n linkerd-viz
```

### Performance Issues

#### High Memory Usage
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check resource limits
kubectl describe pod -n <namespace> <pod-name> | grep -A 5 "Limits:"
```

#### Slow Response Times
```bash
# Check service mesh metrics
linkerd viz stat -n <namespace> deploy/<deployment>

# Check Prometheus metrics
curl "http://prom.local/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[5m]))"
```

### Network Issues

#### Service Discovery
```bash
# Check service endpoints
kubectl get endpoints -A

# Test service connectivity
kubectl exec -it <pod> -- curl <service-name>.<namespace>.svc.cluster.local
```

#### Ingress Issues
```bash
# Check ingress status
kubectl get ingress -A

# Check Traefik logs
kubectl logs -n kube-system deployment/traefik
```

## 🔧 Maintenance

### Regular Tasks

#### Update Applications
```bash
# Update application images
kubectl set image deployment/<deployment> -n <namespace> <container>=<new-image>

# Or use GitOps (recommended)
git commit -m "Update application version"
git push origin main
```

#### Backup Database
```bash
# Create database backup
kubectl exec -it -n database <postgres-pod> -- pg_dump -U postgres tasks > backup.sql
```

#### Monitor System Health
```bash
# Check all pods
kubectl get pods -A

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check service mesh health
linkerd check
```

### Scaling Operations

#### Scale Applications
```bash
# Scale deployment
kubectl scale deployment <deployment> -n <namespace> --replicas=<count>

# Or update in Git (recommended)
# Edit deployment YAML and commit
```

#### Add New Nodes
```bash
# Add new worker node
multipass launch --name k3s-worker-2
# Run Ansible playbook to join cluster
```

## 📈 Monitoring Dashboards

### Key Metrics to Monitor

#### Application Metrics
- **Request Rate**: Requests per second
- **Response Time**: 95th percentile latency
- **Error Rate**: 4xx and 5xx error percentage
- **Throughput**: Successful requests per second

#### Infrastructure Metrics
- **CPU Usage**: Node and pod CPU utilization
- **Memory Usage**: Node and pod memory consumption
- **Disk Usage**: Storage utilization
- **Network**: Bandwidth and packet rates

#### Service Mesh Metrics
- **mTLS**: Percentage of encrypted traffic
- **Success Rate**: Successful vs failed requests
- **Latency**: P50, P95, P99 response times
- **Traffic**: Request volume and patterns

## 🎉 Success Criteria

### ✅ Completed Features
- [x] **Infrastructure**: Terraform + Ansible + K3s cluster
- [x] **Rust Application**: Task API with JWT auth, PostgreSQL, endpoints
- [x] **PostgreSQL**: CloudNativePG operator deployed
- [x] **Keycloak**: Authentication with JWT validation
- [x] **Docker**: Multi-stage builds, local registry
- [x] **Kubernetes**: All manifests (Deployments, Services, Ingress, ConfigMaps, Secrets)
- [x] **Git Repository**: Gitea deployed and configured
- [x] **CI/CD Pipeline**: Drone CI working with Gitea integration
- [x] **Service Mesh**: Linkerd installed and sidecar injection enabled
- [x] **Monitoring**: Prometheus and Grafana deployed with dashboards
- [x] **GitOps**: ArgoCD applications configured and working
- [x] **Offline Mode**: Everything runs locally without internet
- [x] **Documentation**: Comprehensive guides and diagrams

### 🎯 Victory Conditions Met
- ✅ Entire system runs offline
- ✅ Infra + configs are idempotent
- ✅ GitOps works end-to-end
- ✅ Keycloak protects app
- ✅ Linkerd meshes everything
- ✅ Docs + diagrams included
- ✅ Everything is finished!

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Commit with descriptive messages
5. Push to your fork
6. Create a pull request

### Code Standards
- **Rust**: Follow clippy recommendations
- **YAML**: Use consistent indentation and structure
- **Bash**: Use shellcheck for script validation
- **Documentation**: Update README and diagrams for changes

## 📞 Support

### Getting Help
- **Documentation**: Check this README and docs/ directory
- **Logs**: Use `kubectl logs` and `kubectl describe` commands
- **Monitoring**: Check Grafana dashboards and Prometheus metrics
- **Service Mesh**: Use Linkerd Viz for traffic analysis

### Reporting Issues
- **Bug Reports**: Include logs, steps to reproduce, and environment details
- **Feature Requests**: Describe the use case and expected behavior
- **Documentation**: Suggest improvements or clarifications

---

## 🏆 Project Status: COMPLETE

**The Cloud Native Gauntlet is fully implemented and operational!** 

This project demonstrates a complete cloud-native stack running entirely offline, with all modern DevOps practices including GitOps, service mesh, monitoring, and infrastructure automation. The system is production-ready and showcases best practices for cloud-native development.

**Total Implementation Time**: ~12 hours of focused development
**Technologies Demonstrated**: 15+ cloud-native tools and practices
**Lines of Code**: 2000+ across multiple languages and configurations
**Documentation**: Comprehensive guides, diagrams, and troubleshooting

🎉 **Victory achieved!** 🎉