#!/usr/bin/env bash

set -euo pipefail

# Idempotently set /etc/hosts entries for local ingress IP and service hostnames.
# Requires sudo to modify /etc/hosts.

INGRESS_IP=${1:-}
REGISTRY_IP=${2:-}

if [[ -z "${INGRESS_IP}" ]]; then
  echo "Detecting ingress IP from existing entries..."
  # Try to detect from current hosts or fallback to kubectl get ingress
  INGRESS_IP=$(grep -E "\b(gitea\.local|drone\.local|task-api\.local|keycloak\.local)\b" /etc/hosts | awk '{print $1}' | head -n1 || true)
  if [[ -z "${INGRESS_IP}" ]]; then
    INGRESS_IP=$(kubectl -n kube-system get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  fi
fi

if [[ -z "${INGRESS_IP}" ]]; then
  echo "Could not determine ingress IP automatically. Usage: $0 <INGRESS_IP>" >&2
  exit 1
fi

echo "Using ingress IP: ${INGRESS_IP}"
if [[ -n "${REGISTRY_IP}" ]]; then
  echo "Using registry IP: ${REGISTRY_IP}"
else
  REGISTRY_IP="${INGRESS_IP}"
fi

TMP=$(mktemp)
cp /etc/hosts "$TMP"

# Remove existing conflicting lines for our hostnames
sed -i "/\\b\(gitea\.local\|drone\.local\|task-api\.local\|keycloak\.local\|registry\.local\|linkerd\.local\|grafana\.local\|prom\.local\|argocd\.local\)\\b/d" "$TMP"

cat >> "$TMP" <<EOF
${INGRESS_IP} gitea.local
${INGRESS_IP} drone.local
${INGRESS_IP} task-api.local
${INGRESS_IP} keycloak.local
${REGISTRY_IP} registry.local
${INGRESS_IP} linkerd.local
${INGRESS_IP} grafana.local
${INGRESS_IP} prom.local
${INGRESS_IP} argocd.local
EOF

echo "Preview of changes:" && tail -n 10 "$TMP"

echo "Applying changes to /etc/hosts (sudo required)..."
sudo cp "$TMP" /etc/hosts
rm -f "$TMP"

echo "Done. Verify with: getent hosts gitea.local drone.local keycloak.local task-api.local registry.local"

