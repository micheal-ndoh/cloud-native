# GitOps Configuration

GitOps with Argo CD. This directory contains:

- `argocd/` – application definitions (app-of-apps) and config
- `scripts/install-argocd.sh` – Argo CD installer (CLI + controller)

## Install Argo CD
```bash
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

## Apply app-of-apps
```bash
kubectl apply -f argocd/applications/app-of-apps.yaml
kubectl -n argocd get applications
```

## Access Argo CD UI
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
# Open https://localhost:8080
echo "user: admin"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## Notes
- Argo CD monitors repo URLs specified in the application specs under `argocd/applications/`.
- Use the root README for the golden path and verification steps.****