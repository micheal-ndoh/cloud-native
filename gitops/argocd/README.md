# GitOps with Argo CD

This directory contains Argo CD application definitions. The repo follows an app-of-apps pattern using `applications/app-of-apps.yaml`.

## Install Argo CD

Option A: Use helper script (recommended)
```bash
chmod +x ../../scripts/install-argocd.sh || true
../../scripts/install-argocd.sh
```

Option B: Manual
```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server
```

## Apply App-of-Apps
```bash
kubectl apply -f applications/app-of-apps.yaml
kubectl -n argocd get applications
```

## Access the UI
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
# open http://argocd.local
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
# user: admin, password: Bqkarx8Pt3nyRGQD
```

## Notes
- Argo CD monitors target repos from the manifests. Adjust repo URLs/paths inside `applications/*.yaml`.
- For GitOps with in-cluster Gitea, ensure Gitea is reachable and has the repos populated.
- App sync options (prune/self-heal) should be configured per application.