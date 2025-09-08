# Database (CloudNativePG)

Manifests to install CloudNativePG operator and deploy a PostgreSQL cluster used by the Task API, plus a migrations Job.

## Deploy
Applied automatically by `scripts/deploy.sh`. Manual steps:
```bash
kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f cnpg-1.27.0.yaml
kubectl -n cnpg-system wait --for=condition=available --timeout=180s deployment/cnpg-controller-manager
kubectl apply -f db-secret.yaml
kubectl apply -f cluster-app.yaml
kubectl apply -f task-migrations-configmap.yaml
kubectl apply -f task-migrations-job.yaml
kubectl -n database wait --for=condition=complete --timeout=300s job/task-migrations
```

## Access
```bash
kubectl -n database port-forward svc/cluster-app-rw 5432:5432 &
psql "postgres://admin:<password>@localhost:5432/<db>" -c '\\l'
```

## Notes
- Credentials and DB name are set in `db-secret.yaml` and `cluster-app.yaml`.
- The Task API reads its connection string via `apps/backend/task-api-secret.yaml`.