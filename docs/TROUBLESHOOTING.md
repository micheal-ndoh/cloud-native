# Cloud Native Gauntlet - Troubleshooting Guide

## 🚨 Quick Diagnostics

### System Health Check
```bash
# Check all pods status
kubectl get pods -A

# Check node status
kubectl get nodes

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check service mesh health
linkerd check
```

### Service Status Check
```bash
# Check all services
kubectl get svc -A

# Check ingress status
kubectl get ingress -A

# Check ArgoCD applications
kubectl get applications -n argocd
```

## 🔧 Common Issues & Solutions

### 1. Pod Issues

#### Pods Stuck in Pending State
```bash
# Check pod events
kubectl describe pod -n <namespace> <pod-name>

# Check node resources
kubectl describe node <node-name>

# Check if nodes are schedulable
kubectl get nodes -o wide
```

**Common Causes:**
- Insufficient resources (CPU/Memory)
- Node not ready
- Image pull issues
- Storage issues

#### Pods Stuck in ImagePullBackOff
```bash
# Check image availability
docker images | grep <image-name>

# Check registry connectivity
curl http://10.38.229.242:5000/v2/_catalog

# Check pod events
kubectl describe pod -n <namespace> <pod-name>

# Restart pod
kubectl delete pod -n <namespace> <pod-name>
```

**Solutions:**
- Ensure image exists in local registry
- Check registry connectivity
- Verify image name and tag
- Restart pod to retry image pull

#### Pods Crashing (CrashLoopBackOff)
```bash
# Check pod logs
kubectl logs -n <namespace> <pod-name> --previous

# Check pod description
kubectl describe pod -n <namespace> <pod-name>

# Check resource limits
kubectl get pod -n <namespace> <pod-name> -o yaml | grep -A 5 resources
```

**Common Causes:**
- Application errors
- Resource limits exceeded
- Configuration issues
- Database connection problems

### 2. Service Mesh Issues

#### Linkerd Sidecar Not Injected
```bash
# Check pod annotations
kubectl get pod -n <namespace> <pod-name> -o yaml | grep linkerd

# Check Linkerd installation
linkerd check

# Manually inject sidecar
kubectl get deployment -n <namespace> <deployment> -o yaml | linkerd inject - | kubectl apply -f -
```

**Solutions:**
- Add `linkerd.io/inject: enabled` annotation
- Restart deployment after annotation
- Check Linkerd control plane health

#### mTLS Issues
```bash
# Check mTLS status
linkerd viz edges

# Check certificate status
linkerd check --proxy

# Check service communication
linkerd viz tap -n <namespace> deploy/<deployment>
```

**Solutions:**
- Ensure Linkerd is properly installed
- Check certificate validity
- Verify service mesh configuration

### 3. Database Issues

#### PostgreSQL Connection Failures
```bash
# Check PostgreSQL cluster status
kubectl get clusters -n database

# Check PostgreSQL pods
kubectl get pods -n database

# Check database logs
kubectl logs -n database <postgres-pod>

# Test database connection
kubectl exec -it -n database <postgres-pod> -- psql -U postgres -d tasks
```

**Solutions:**
- Verify PostgreSQL cluster is healthy
- Check database credentials
- Ensure network connectivity
- Check database resource limits

#### Database Performance Issues
```bash
# Check database metrics
curl "http://prom.local/api/v1/query?query=pg_stat_database_numbackends"

# Check connection pool
kubectl exec -it -n database <postgres-pod> -- psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

**Solutions:**
- Monitor connection pool usage
- Check for long-running queries
- Optimize database configuration
- Scale database resources if needed

### 4. Authentication Issues

#### Keycloak Login Problems
```bash
# Check Keycloak pod status
kubectl get pods -n keycloak

# Check Keycloak logs
kubectl logs -n keycloak <keycloak-pod>

# Test Keycloak health
curl http://keycloak.local/auth/realms/master
```

**Solutions:**
- Verify Keycloak is running
- Check database connectivity
- Verify admin credentials
- Check ingress configuration

#### JWT Token Issues
```bash
# Check API logs for token validation errors
kubectl logs -n backend <api-pod>

# Test token validation
curl -H "Authorization: Bearer <token>" http://task-api.local/tasks
```

**Solutions:**
- Verify JWT token format
- Check token expiration
- Validate Keycloak configuration
- Check API authentication setup

### 5. Monitoring Issues

#### Prometheus Not Scraping Metrics
```bash
# Check Prometheus targets
curl http://prom.local/api/v1/targets

# Check Prometheus configuration
kubectl get configmap -n monitoring prometheus-config -o yaml

# Check Prometheus logs
kubectl logs -n monitoring <prometheus-pod>
```

**Solutions:**
- Verify scrape configuration
- Check service annotations
- Ensure metrics endpoints are accessible
- Check Prometheus resource limits

#### Grafana Dashboard Issues
```bash
# Check Grafana health
curl http://grafana.local/api/health

# Check Grafana logs
kubectl logs -n monitoring <grafana-pod>

# Check datasource configuration
curl -u admin:admin123 http://localhost:3000/api/datasources
```

**Solutions:**
- Verify Prometheus datasource
- Check dashboard configuration
- Ensure Grafana has proper permissions
- Check Grafana resource limits

### 6. CI/CD Issues

#### Drone CI Pipeline Failures
```bash
# Check Drone CI pod status
kubectl get pods -n ci

# Check Drone CI logs
kubectl logs -n ci <drone-pod>

# Check pipeline configuration
kubectl get configmap -n ci drone-config -o yaml
```

**Solutions:**
- Verify pipeline YAML syntax
- Check Git repository access
- Ensure Docker registry connectivity
- Check Drone CI configuration

#### ArgoCD Sync Issues
```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force sync application
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"}}}'
```

**Solutions:**
- Verify Git repository access
- Check application configuration
- Ensure Kubernetes permissions
- Check ArgoCD server health

### 7. Network Issues

#### Service Discovery Problems
```bash
# Check service endpoints
kubectl get endpoints -A

# Test service connectivity
kubectl exec -it <pod> -- nslookup <service-name>.<namespace>.svc.cluster.local

# Check DNS resolution
kubectl exec -it <pod> -- cat /etc/resolv.conf
```

**Solutions:**
- Verify service configuration
- Check DNS resolution
- Ensure network policies
- Check service mesh configuration

#### Ingress Issues
```bash
# Check ingress status
kubectl get ingress -A

# Check Traefik logs
kubectl logs -n kube-system deployment/traefik

# Test ingress connectivity
curl -H "Host: <domain>" http://<node-ip>
```

**Solutions:**
- Verify ingress configuration
- Check Traefik health
- Ensure domain resolution
- Check firewall rules

## 🔍 Advanced Debugging

### Log Analysis
```bash
# Follow logs in real-time
kubectl logs -f -n <namespace> <pod-name>

# Get logs from previous container
kubectl logs -n <namespace> <pod-name> --previous

# Get logs from specific container
kubectl logs -n <namespace> <pod-name> -c <container-name>
```

### Resource Investigation
```bash
# Check resource usage
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu

# Check resource limits
kubectl describe pod -n <namespace> <pod-name> | grep -A 5 "Limits:"

# Check node resources
kubectl describe node <node-name> | grep -A 10 "Allocated resources:"
```

### Network Debugging
```bash
# Check network policies
kubectl get networkpolicies -A

# Test network connectivity
kubectl exec -it <pod> -- curl <service-url>

# Check service mesh traffic
linkerd viz tap -n <namespace> deploy/<deployment>
```

## 🚀 Performance Optimization

### Resource Optimization
```bash
# Check resource requests vs limits
kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,CPU_LIM:.spec.containers[*].resources.limits.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,MEM_LIM:.spec.containers[*].resources.limits.memory

# Optimize resource allocation
kubectl patch deployment -n <namespace> <deployment> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
```

### Database Optimization
```bash
# Check database performance
kubectl exec -it -n database <postgres-pod> -- psql -U postgres -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"

# Optimize database configuration
kubectl exec -it -n database <postgres-pod> -- psql -U postgres -c "SHOW shared_buffers;"
```

## 📞 Getting Help

### Useful Commands
```bash
# Get comprehensive system status
kubectl get all -A

# Check system events
kubectl get events -A --sort-by='.lastTimestamp'

# Check cluster info
kubectl cluster-info

# Check API resources
kubectl api-resources
```

### Log Locations
- **Application Logs**: `kubectl logs -n <namespace> <pod-name>`
- **System Logs**: `journalctl -u k3s` (on master node)
- **Docker Logs**: `docker logs <container-id>`
- **Service Mesh Logs**: `linkerd logs -n <namespace> <pod-name>`

### Monitoring URLs
- **Prometheus**: http://prom.local
- **Grafana**: http://grafana.local (admin/admin123)
- **Linkerd Viz**: http://linkerd.local
- **ArgoCD**: http://argocd.local (admin/password)

---

## 🎯 Quick Reference

### Essential Commands
```bash
# System health
kubectl get pods -A
kubectl get nodes
linkerd check

# Application status
kubectl get applications -n argocd
kubectl get ingress -A

# Monitoring
kubectl port-forward -n monitoring svc/prometheus 9090:9090
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n linkerd-viz svc/web 8084:8084

# Troubleshooting
kubectl describe pod -n <namespace> <pod-name>
kubectl logs -n <namespace> <pod-name>
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh
```

### Emergency Procedures
```bash
# Restart all deployments
kubectl rollout restart deployment -A

# Restart service mesh
kubectl rollout restart deployment -n linkerd

# Restart monitoring
kubectl rollout restart deployment -n monitoring

# Restart CI/CD
kubectl rollout restart deployment -n ci
kubectl rollout restart deployment -n argocd
```

This troubleshooting guide should help you resolve most issues encountered with the Cloud Native Gauntlet system. For additional support, check the logs and monitoring dashboards for detailed information about system behavior.