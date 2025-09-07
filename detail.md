# Cloud Native Gauntlet Deployment Details

## Access Information

- **Backend API:** <http://task-api.local/api>
- **Health Check:** <http://task-api.local/api/health>
- **Keycloak:** <http://keycloak.local/auth>
- **Keycloak Admin Console:** <http://keycloak.local/>
- **Registry:** 10.38.229.242:5000

## Database

- **Port Forward:**

  ```sh
  kubectl port-forward svc/cluster-app-rw 5432:5432 -n database
  ```

- **Connection:**

  ```sh
  psql -U admin -d database -h localhost
  ```

## API Testing Examples

- **Login:**

  ```sh
  curl -X POST http://task-api.local/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email": "admin@example.com", "password": "adminpassword"}'
  ```

## Keycloak Testing

- **Admin Console:** <http://keycloak.local/>
- **Default credentials:** (see keycloak-secret.yaml)

## Pods

| Namespace   | Name                                     | Status  | Age   |
|-------------|------------------------------------------|---------|-------|
| backend     | task-api-84d5d8657b-mwjvf                | Running | 24s   |
| cnpg-system | cnpg-controller-manager-8465b45454-ql7qq | Running | 93s   |
| database    | cluster-app-1                            | Running | 40s   |
| keycloak    | keycloak-7d9ccc55fc-t6hcr                | Running | 14s   |
| kube-system | coredns-ccb96694c-5wlnl                  | Running | 4h43m |
| kube-system | traefik-5d45fc8cc9-2xrvw                 | Running | 4h31m |

## Services

| Namespace   | Name                 | Type         | Cluster-IP    | External-IP                | Port(s)                    |
|-------------|----------------------|--------------|---------------|----------------------------|----------------------------|
| backend     | task-api             | ClusterIP    | 10.43.183.164 | <none>                     | 3000/TCP                   |
| cnpg-system | cnpg-webhook-service | ClusterIP    | 10.43.128.199 | <none>                     | 443/TCP                    |
| database    | cluster-app-rw       | ClusterIP    | 10.43.30.200  | <none>                     | 5432/TCP                   |
| keycloak    | keycloak             | ClusterIP    | 10.43.33.25   | <none>                     | 80/TCP                     |
| kube-system | traefik              | LoadBalancer | 10.43.134.185 | 10.38.229.161,10.38.229.69 | 80:32625/TCP,443:31752/TCP |

## Useful Commands

- **Get all pods:**

  ```sh
  kubectl get pods --all-namespaces
  ```

- **Get all services:**

  ```sh
  kubectl get svc --all-namespaces
  ```

- **Get all ingresses:**

  ```sh
  kubectl get ingress --all-namespaces
  ```

- **Check Keycloak secret:**

  ```sh
  kubectl get secret keycloak-db-secret -n keycloak -o yaml
  ```

---
Deployment completed successfully!
