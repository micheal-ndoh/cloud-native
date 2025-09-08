# Scripts Reference

Quick reference for automation scripts.

## setup.sh
Creates Multipass VMs (Terraform), configures K3s (Ansible), mounts project, and prepares cluster access.
```bash
./setup.sh
```

## deploy.sh
Deploys CNPG, DB secrets/cluster/migrations, Task API, Keycloak (incl. bootstrap job), Gitea, Argo CD applications, labels namespaces for Linkerd, and shows access info. Also updates `/etc/hosts` for `task-api.local keycloak.local gitea.local registry.local drone.local`.
```bash
./deploy.sh
```

## observability.sh
Wrapper for Linkerd viz and mesh introspection.
```bash
./observability.sh checks
./observability.sh dashboard
./observability.sh linkerd-viz port-forward
./observability.sh _ stat backend task-api
./observability.sh _ tap backend task-api
```

## port-forward-all.sh
Starts common port-forwards locally:
- Prometheus: 9090
- Grafana: 3000
- Linkerd Viz: 8084
```bash
./port-forward-all.sh
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
echo "Open https://localhost:8080 (user: admin)"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```