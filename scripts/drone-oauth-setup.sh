#!/usr/bin/env bash

set -euo pipefail

# This script configures Drone to use Gitea OAuth with the provided Client ID and Secret,
# ensures the Drone deployment points to the external Gitea host, and restarts Drone.

NAMESPACE="ci"
DEPLOYMENT="drone-server"
SECRET_NAME="drone-secrets"

# Hardcoded credentials as requested
DRONE_GITEA_CLIENT_ID="210a3da9-fe9d-4cf3-b137-854ad9c77782"
DRONE_GITEA_CLIENT_SECRET="gto_acqpmpabayjfxtxtmsidgeoqn5k5qkifpha755jg4dxxycewnjxa"
DRONE_RPC_SECRET="supersecret"

# External hostnames used by ingress
DRONE_SERVER_HOST="drone.local"
DRONE_SERVER_PROTO="http"
DRONE_GITEA_SERVER="http://gitea.local"

echo "[1/5] Ensuring namespace '${NAMESPACE}' exists..."
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${NAMESPACE}"

echo "[2/5] Applying secret '${SECRET_NAME}' with provided OAuth credentials (idempotent)..."
kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" >/dev/null 2>&1 || kubectl -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" --from-literal=PLACEHOLDER=1 >/dev/null 2>&1 || true
kubectl -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" \
  --from-literal=DRONE_GITEA_CLIENT_ID="${DRONE_GITEA_CLIENT_ID}" \
  --from-literal=DRONE_GITEA_CLIENT_SECRET="${DRONE_GITEA_CLIENT_SECRET}" \
  --from-literal=DRONE_RPC_SECRET="${DRONE_RPC_SECRET}" \
  -o yaml --dry-run=client | kubectl apply -f -

echo "[3/5] Ensuring Drone deployment has correct external hosts..."
kubectl -n "${NAMESPACE}" set env deploy/"${DEPLOYMENT}" \
  DRONE_GITEA_SERVER="${DRONE_GITEA_SERVER}" \
  DRONE_SERVER_HOST="${DRONE_SERVER_HOST}" \
  DRONE_SERVER_PROTO="${DRONE_SERVER_PROTO}" \
  DRONE_SERVER_PORT=":80"

echo "[4/5] Restarting Drone deployment to pick up changes (non-disruptive if no change)..."
kubectl -n "${NAMESPACE}" rollout restart deploy/"${DEPLOYMENT}" || true
kubectl -n "${NAMESPACE}" rollout status deploy/"${DEPLOYMENT}" --timeout=120s || true

echo "[5/5] Current Drone env (sanitized):"
kubectl -n "${NAMESPACE}" get deploy "${DEPLOYMENT}" -o yaml | sed -n '/env:/,/volumeMounts:/p' |
  sed 's/\(DRONE_GITEA_CLIENT_SECRET\|DRONE_RPC_SECRET\).*/\1: ****/g'

echo "Done. Visit http://${DRONE_SERVER_HOST} and click Continue."

