# Cloud-Native Primer (Beginner Friendly)

## What is a Cloud-Native Application?
Think of software like a city. A traditional monolith is one giant building where everything happens inside. If the power fails, everything stops. A cloud-native app is a city of Lego-like buildings (microservices). Each building can be built, scaled, repaired, or replaced independently. The city has shared services like roads (networking), utilities (security, logging), and rules (automation) so the whole thing stays reliable as it grows.

Key traits:
- Small, independent services
- Automated deployment and recovery
- Observable (easy to monitor)
- Resilient by design

## Kubernetes Operators (with CloudNativePG)
A Kubernetes Operator is like an automated human expert for a specific app inside the cluster. It watches for desired state (from YAML) and continuously makes reality match it.

CloudNativePG (CNPG) is an operator that manages PostgreSQL clusters:
- Creates a Postgres cluster from a YAML file
- Handles replication, failover, and backups
- Exposes Postgres via Kubernetes Services
- Automates upgrades and maintenance

You declare the DB you want; CNPG keeps it healthy.

## GitOps and Argo CD
GitOps means using Git as the single source of truth for both app and infra configuration. Instead of clicking in a UI, you commit YAML to a repo.

Argo CD is the robot gardener: it constantly compares the cluster (the garden) with the Git repo (the blueprint). If something drifts, it prunes and fixes it.

Benefits:
- Every change is versioned in Git
- Rollbacks are trivial
- Safer, auditable deployments

## Service Mesh (Linkerd)
A service mesh is a smart postal service for your data between services. It adds a sidecar proxy next to each pod and handles:
- Security: mTLS encryption by default
- Reliability: retries, timeouts
- Observability: golden metrics, tap/inspect traffic

You get these capabilities without changing application code. Linkerd provides commands and a dashboard (viz) to see traffic and health.

## How It Fits Together Here
- CNPG runs PostgreSQL used by the Rust Task API
- Keycloak issues tokens; the API enforces auth
- Argo CD pulls manifests from Git and applies them
- Linkerd injects sidecars into namespaces for mesh features
- Prometheus/Grafana and Linkerd viz provide visibility

That’s the essence: declare intent in Git and YAML; operators and controllers keep reality aligned for a resilient, observable, secure system.
