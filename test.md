# Cloud Native Gauntlet - Complete Testing & Validation Guide

## 🎯 Exercise Aim

The Cloud Native Gauntlet is a comprehensive challenge designed to test your ability to build, deploy, and manage a complete cloud-native application stack entirely offline. This exercise validates your understanding of modern DevOps practices, containerization, orchestration, service mesh, monitoring, and GitOps workflows.

**Primary Objectives:**
- Build a production-ready Rust web application with JWT authentication
- Deploy a complete Kubernetes cluster with all supporting services
- Implement GitOps workflows for continuous deployment
- Secure all inter-service communication with mTLS
- Monitor the entire system with comprehensive observability
- Document everything with architecture diagrams and guides

**Success Criteria:**
- ✅ Entire system runs offline (no internet dependencies)
- ✅ Infrastructure and configurations are idempotent
- ✅ GitOps pipeline works end-to-end
- ✅ Keycloak protects the application with JWT
- ✅ Linkerd service mesh provides mTLS and observability
- ✅ Comprehensive documentation with Mermaid diagrams
- ✅ All components are production-ready and scalable

## 🛠️ Technologies Used

### Core Technologies
- **Rust**: High-performance web application backend
- **PostgreSQL**: Reliable database with CloudNativePG operator
- **Kubernetes (K3s)**: Lightweight container orchestration
- **Docker**: Containerization and local registry
- **Keycloak**: Identity and access management
- **Linkerd**: Service mesh with mTLS and observability

### DevOps & Automation
- **Terraform**: Infrastructure as Code (IaC)
- **Ansible**: Configuration management
- **Multipass**: Lightweight VM management
- **ArgoCD**: GitOps continuous deployment
- **Drone CI**: Continuous integration pipeline
- **Gitea**: Self-hosted Git repository

### Monitoring & Observability
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Metrics visualization and dashboards
- **Linkerd Viz**: Service mesh observability
- **Traefik**: Ingress controller and load balancing

## 🧪 Complete Testing & Validation

### 1. Infrastructure Testing

#### 1.1 VM and Cluster Health
```bash
# Test VM connectivity
multipass list
ping 10.38.229.161  # K3s Master
ping 10.38.229.69   # K3s Worker
ping 10.38.229.242  # Docker Registry

# Test Kubernetes cluster
kubectl get nodes
kubectl get pods -A
kubectl cluster-info

# Verify cluster resources
kubectl top nodes
kubectl describe nodes
```

**Expected Results:**
- All VMs show "Running" status
- All nodes show "Ready" status
- All system pods are "Running"
- Cluster shows healthy API server

#### 1.2 Terraform Infrastructure Validation
```bash
# Test Terraform state
cd infrastructure/terraform
terraform plan
terraform show

# Verify VM resources
multipass info k3s-master
multipass info k3s-worker
multipass info docker-registry
```

**Expected Results:**
- Terraform plan shows no changes needed
- VMs have correct CPU/memory allocation
- Network connectivity between VMs works

#### 1.3 Ansible Configuration Validation
```bash
# Test Ansible connectivity
cd infrastructure/ansible
ansible all -m ping -i inventory.ini

# Verify K3s installation
ansible all -m shell -a "kubectl version --client" -i inventory.ini
ansible all -m shell -a "docker --version" -i inventory.ini
```

**Expected Results:**
- All hosts respond to ping
- kubectl and Docker are installed on all nodes
- K3s cluster is properly configured

### 2. Application Testing

#### 2.1 Rust Application Functionality
```bash
# Test application endpoints
curl http://task-api.local/health
curl http://task-api.local/tasks
curl http://task-api.local/docs  # Swagger UI

# Test with authentication
TOKEN=$(curl -s -X POST http://keycloak.local/auth/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123&grant_type=password&client_id=task-api" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" http://task-api.local/tasks
curl -H "Authorization: Bearer $TOKEN" -X POST http://task-api.local/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing the API"}'
```

**Expected Results:**
- Health endpoint returns 200 OK
- Unauthenticated requests return 401 Unauthorized
- Authenticated requests return task data
- POST requests create new tasks successfully

#### 2.2 Database Integration Testing
```bash
# Test database connectivity
kubectl exec -it -n database $(kubectl get pods -n database -l postgresql.cnpg.io/cluster=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -d tasks -c "SELECT COUNT(*) FROM tasks;"

# Test database persistence
kubectl exec -it -n database $(kubectl get pods -n database -l postgresql.cnpg.io/cluster=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -d tasks -c "INSERT INTO tasks (id, title, description, user_id) VALUES (gen_random_uuid(), 'Test Task', 'Database Test', 'test-user');"
```

**Expected Results:**
- Database connection successful
- Tables exist and are accessible
- Data persistence works correctly
- UUID generation functions properly

### 3. Authentication & Security Testing

#### 3.1 Keycloak Authentication Flow
```bash
# Test Keycloak admin access
curl http://keycloak.local/auth/admin/

# Test realm configuration
curl http://keycloak.local/auth/realms/master/.well-known/openid_configuration

# Test user authentication
curl -X POST http://keycloak.local/auth/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123&grant_type=password&client_id=task-api"
```

**Expected Results:**
- Keycloak admin console accessible
- OpenID Connect configuration available
- JWT token generation successful
- Token contains correct claims (sub, roles, exp)

#### 3.2 JWT Token Validation
```bash
# Test token validation
TOKEN=$(curl -s -X POST http://keycloak.local/auth/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123&grant_type=password&client_id=task-api" | jq -r '.access_token')

# Decode token (without verification for testing)
echo $TOKEN | cut -d. -f2 | base64 -d | jq .

# Test protected endpoints
curl -H "Authorization: Bearer $TOKEN" http://task-api.local/tasks
curl -H "Authorization: Bearer invalid_token" http://task-api.local/tasks
```

**Expected Results:**
- Token contains user claims and roles
- Valid token allows API access
- Invalid token returns 401 Unauthorized
- Token expiration works correctly

#### 3.3 Role-Based Access Control (RBAC)
```bash
# Test admin endpoints
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://task-api.local/admin/users

# Test user endpoints
curl -H "Authorization: Bearer $USER_TOKEN" http://task-api.local/tasks

# Test unauthorized access
curl -H "Authorization: Bearer $USER_TOKEN" http://task-api.local/admin/users
```

**Expected Results:**
- Admin users can access admin endpoints
- Regular users can access user endpoints
- Regular users cannot access admin endpoints
- Proper HTTP status codes returned

### 4. Service Mesh Testing

#### 4.1 Linkerd Installation Verification
```bash
# Check Linkerd installation
linkerd check

# Verify control plane
kubectl get pods -n linkerd
kubectl get pods -n linkerd-viz

# Check sidecar injection
kubectl get pods -n backend -o yaml | grep linkerd-proxy
kubectl get pods -n keycloak -o yaml | grep linkerd-proxy
```

**Expected Results:**
- All Linkerd checks pass
- Control plane pods are running
- Sidecar proxies are injected in application pods
- Linkerd Viz is operational

#### 4.2 mTLS Encryption Testing
```bash
# Check mTLS status
linkerd viz edges

# Test traffic encryption
linkerd viz tap -n backend deploy/task-api

# Check certificate status
linkerd check --proxy
```

**Expected Results:**
- All service-to-service communication shows mTLS enabled
- Traffic tap shows encrypted connections
- Certificate validation passes
- No unencrypted traffic detected

#### 4.3 Service Mesh Observability
```bash
# Access Linkerd Viz dashboard
kubectl port-forward -n linkerd-viz svc/web 8084:8084 &
open http://localhost:8084

# Check service topology
linkerd viz stat -n backend deploy/task-api
linkerd viz stat -n keycloak deploy/keycloak

# Test traffic routing
linkerd viz routes -n backend svc/task-api
```

**Expected Results:**
- Linkerd Viz dashboard accessible
- Service metrics show healthy traffic
- Route configuration is correct
- Service topology visualization works

### 5. CI/CD Pipeline Testing

#### 5.1 GitOps Workflow Testing
```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Test application sync status
kubectl describe application backend -n argocd
kubectl describe application keycloak -n argocd

# Test GitOps automation
git commit -m "Test change"
git push origin main
# Wait for ArgoCD to detect changes
kubectl get applications -n argocd
```

**Expected Results:**
- All applications show "Synced" status
- Applications show "Healthy" status
- Git changes trigger automatic deployment
- ArgoCD successfully syncs configurations

#### 5.2 Drone CI Pipeline Testing
```bash
# Check Drone CI status
kubectl get pods -n ci

# Test CI pipeline
# Make a code change and push to trigger pipeline
git commit -m "Trigger CI pipeline"
git push origin main

# Check pipeline execution
# Access Drone CI dashboard at http://drone.local
```

**Expected Results:**
- Drone CI pods are running
- Pipeline triggers on code push
- Build, test, and deploy stages succeed
- Container images are built and pushed to registry

#### 5.3 Gitea Repository Testing
```bash
# Test Gitea access
curl http://gitea.local/

# Test repository access
curl http://gitea.local/michealndoh/Cloud-native-infra.git/info/refs?service=git-upload-pack

# Test webhook configuration
# Check webhook delivery in Gitea admin panel
```

**Expected Results:**
- Gitea web interface accessible
- Repository is accessible via Git
- Webhooks are properly configured
- CI/CD integration works

### 6. Monitoring & Observability Testing

#### 6.1 Prometheus Metrics Collection
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Test metrics queries
curl "http://localhost:9090/api/v1/query?query=up" | jq '.data.result[]'
curl "http://localhost:9090/api/v1/query?query=rate(http_requests_total[5m])" | jq '.data.result[]'

# Check application metrics
curl "http://localhost:9090/api/v1/query?query=up{job=\"task-api\"}" | jq '.data.result[]'
```

**Expected Results:**
- All targets show "up" status
- Application metrics are being collected
- Database metrics are available
- Service mesh metrics are present

#### 6.2 Grafana Dashboard Testing
```bash
# Check Grafana health
curl http://localhost:3000/api/health

# Test datasource connectivity
curl -u admin:admin123 http://localhost:3000/api/datasources

# Access dashboards
# Open http://localhost:3000 and verify dashboards load
```

**Expected Results:**
- Grafana returns healthy status
- Prometheus datasource is configured
- Dashboards display data correctly
- All panels show metrics

#### 6.3 Comprehensive Monitoring Validation
```bash
# Test all monitoring components
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get ingress -n monitoring

# Test monitoring endpoints
curl http://prometheus.local/targets
curl http://grafana.local/api/health
```

**Expected Results:**
- All monitoring pods are running
- Services are accessible
- Ingress routes work correctly
- Monitoring stack is fully operational

### 7. Offline Mode Testing

#### 7.1 Internet Dependency Validation
```bash
# Disable internet connectivity (simulate offline mode)
sudo iptables -A OUTPUT -d 8.8.8.8 -j DROP

# Test system functionality
kubectl get pods -A
curl http://task-api.local/health
curl http://keycloak.local/auth/admin/

# Re-enable internet
sudo iptables -D OUTPUT -d 8.8.8.8 -j DROP
```

**Expected Results:**
- All services continue to work without internet
- No external DNS lookups required
- All images available locally
- System operates completely offline

#### 7.2 Local Registry Testing
```bash
# Check local registry
curl http://10.38.229.242:5000/v2/_catalog

# Test image availability
docker images | grep -E "(prometheus|grafana|keycloak|postgres)"

# Test image pulls
kubectl get pods -A | grep ImagePullBackOff
```

**Expected Results:**
- Registry contains all required images
- No ImagePullBackOff errors
- All images are accessible locally
- System doesn't require external registries

### 8. Idempotence Testing

#### 8.1 Infrastructure Idempotence
```bash
# Run Terraform multiple times
cd infrastructure/terraform
terraform apply
terraform apply  # Should show no changes
terraform apply  # Should show no changes

# Run Ansible multiple times
cd infrastructure/ansible
ansible-playbook -i inventory.ini configure-k3s.yml
ansible-playbook -i inventory.ini configure-k3s.yml  # Should show no changes
```

**Expected Results:**
- Terraform shows "No changes" on subsequent runs
- Ansible shows "ok" status for all tasks
- No duplicate resources created
- System state remains consistent

#### 8.2 Application Idempotence
```bash
# Deploy applications multiple times
kubectl apply -f apps/backend/
kubectl apply -f apps/backend/  # Should show no changes
kubectl apply -f apps/auth/
kubectl apply -f apps/auth/  # Should show no changes
```

**Expected Results:**
- Kubernetes shows "unchanged" for resources
- No duplicate resources created
- Application state remains consistent
- No errors on repeated deployments

### 9. Performance & Scalability Testing

#### 9.1 Load Testing
```bash
# Test API performance
for i in {1..100}; do
  curl -H "Authorization: Bearer $TOKEN" http://task-api.local/tasks &
done
wait

# Check response times
curl -w "@curl-format.txt" -H "Authorization: Bearer $TOKEN" http://task-api.local/tasks
```

**Expected Results:**
- API handles concurrent requests
- Response times remain acceptable
- No errors under load
- System remains stable

#### 9.2 Resource Utilization Testing
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check resource limits
kubectl describe pod -n backend $(kubectl get pods -n backend -o name | head -1) | grep -A 5 "Limits:"
```

**Expected Results:**
- Resource usage within limits
- No resource exhaustion
- Proper resource allocation
- System performance acceptable

### 10. Documentation & Diagrams Testing

#### 10.1 Documentation Completeness
```bash
# Check documentation files
ls -la docs/
ls -la README*.md

# Verify diagram files
ls -la docs/*.md | grep -E "(diagram|flow)"
```

**Expected Results:**
- All documentation files present
- Mermaid diagrams included
- README files comprehensive
- Troubleshooting guides available

#### 10.2 Diagram Validation
```bash
# Check diagram content
grep -l "mermaid" docs/*.md
grep -l "graph TB" docs/*.md
grep -l "sequenceDiagram" docs/*.md
```

**Expected Results:**
- Architecture diagram present
- Pipeline diagram included
- Authentication flow diagram available
- All diagrams properly formatted

## 🎯 Final Validation Checklist

### ✅ Infrastructure
- [ ] VMs running and accessible
- [ ] K3s cluster healthy
- [ ] Terraform state consistent
- [ ] Ansible configuration applied
- [ ] Local registry operational

### ✅ Applications
- [ ] Rust API functional
- [ ] PostgreSQL cluster running
- [ ] Keycloak authentication working
- [ ] All endpoints accessible
- [ ] Database persistence verified

### ✅ Security
- [ ] JWT authentication working
- [ ] RBAC properly configured
- [ ] mTLS encryption active
- [ ] Service mesh security verified
- [ ] Network policies applied

### ✅ CI/CD
- [ ] GitOps pipeline functional
- [ ] Drone CI building images
- [ ] ArgoCD syncing applications
- [ ] Gitea repository accessible
- [ ] End-to-end automation working

### ✅ Monitoring
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboards functional
- [ ] Linkerd Viz observability active
- [ ] All services monitored
- [ ] Alerting configured

### ✅ Offline Mode
- [ ] No internet dependencies
- [ ] All images available locally
- [ ] Local DNS resolution working
- [ ] Registry accessible offline
- [ ] Complete offline operation

### ✅ Idempotence
- [ ] Terraform idempotent
- [ ] Ansible idempotent
- [ ] Kubernetes deployments idempotent
- [ ] No duplicate resources
- [ ] Consistent state management

### ✅ Documentation
- [ ] Comprehensive README
- [ ] Architecture diagrams
- [ ] Pipeline documentation
- [ ] Troubleshooting guides
- [ ] All components documented

## 🏆 Victory Conditions Verification

### Complete System Validation
```bash
# Final system health check
echo "=== FINAL SYSTEM VALIDATION ==="
echo "1. Infrastructure Health:"
kubectl get nodes
kubectl get pods -A | grep -v Running

echo "2. Application Health:"
curl -s http://task-api.local/health | jq .
curl -s http://keycloak.local/auth/admin/ | head -5

echo "3. Service Mesh Health:"
linkerd check

echo "4. Monitoring Health:"
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
curl -s http://localhost:3000/api/health | jq .

echo "5. GitOps Health:"
kubectl get applications -n argocd

echo "6. Offline Mode Test:"
ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "Internet: Available" || echo "Internet: Offline (Good!)"

echo "=== VALIDATION COMPLETE ==="
```

**Expected Final Results:**
- All nodes show "Ready" status
- All pods show "Running" status
- All services respond correctly
- Service mesh shows healthy status
- Monitoring shows all targets up
- GitOps shows all applications synced
- System operates completely offline

## 🎉 Success Confirmation

If all tests pass and validations succeed, you have successfully completed the Cloud Native Gauntlet! You have demonstrated mastery of:

- **Infrastructure as Code** with Terraform and Ansible
- **Container Orchestration** with Kubernetes
- **Service Mesh** with Linkerd and mTLS
- **Authentication & Authorization** with Keycloak and JWT
- **Monitoring & Observability** with Prometheus and Grafana
- **GitOps** with ArgoCD and Drone CI
- **Offline Operations** with local registry and DNS
- **Production Readiness** with comprehensive testing

**You are now ready to face LPIC 2xx, CKAD, and AWS Cloud Practitioner with confidence!** 🚀

---

*Remember: In YAML, no one can hear you scream... but with this comprehensive testing guide, you'll have the tools to debug any issue that comes your way!* 😄