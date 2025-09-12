#!/usr/bin/env bash
set -euo pipefail

# Config (override via env if needed)
GITEA_URL="${GITEA_URL:-http://gitea.local}"
GITEA_PAT="${GITEA_PAT:-}"                                 # export GITEA_PAT=...
APP_NAME="${APP_NAME:-Drone CI}"
REDIRECT_URI="${REDIRECT_URI:-http://drone.local/login}"

# Drone/K8s
NAMESPACE="${NAMESPACE:-ci}"
DEPLOYMENT="${DEPLOYMENT:-drone-server}"
SECRET_NAME="${SECRET_NAME:-drone-secrets}"
DRONE_RPC_SECRET="${DRONE_RPC_SECRET:-supersecret}"
DRONE_SERVER_HOST="${DRONE_SERVER_HOST:-drone.local}"
DRONE_SERVER_PROTO="${DRONE_SERVER_PROTO:-http}"
DRONE_GITEA_SERVER="${DRONE_GITEA_SERVER:-http://gitea.local}"

[[ -n "${GITEA_PAT}" ]] || { echo "ERROR: set GITEA_PAT"; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq is required"; exit 1; }

auth_hdr=("Authorization: token ${GITEA_PAT}")
json_hdr=("Content-Type: application/json" "Accept: application/json")

echo "[1/5] Ensure OAuth app '${APP_NAME}' exists with redirect '${REDIRECT_URI}'..."
apps_json="$(curl -sS -H "${auth_hdr[@]}" -H "${json_hdr[@]}" "${GITEA_URL}/api/v1/user/applications/oauth2")"
app_id="$(echo "${apps_json}" | jq -r --arg n "${APP_NAME}" '.[] | select(.name==$n) | .id' | head -n1 || true)"
client_id=""
client_secret=""

ensure_secret_json() {
  # Some Gitea returns plain text or nothing; normalize to JSON with 'client_secret'
  local raw="${1:-}"
  if echo "${raw}" | jq -e '.client_secret' >/dev/null 2>&1; then
    echo "${raw}"
  elif [[ -n "${raw}" ]]; then
    # Wrap plaintext as JSON
    jq -n --arg v "${raw}" '{client_secret:$v}'
  else
    jq -n '{client_secret:null}'
  fi
}

if [[ -n "${app_id}" && "${app_id}" != "null" ]]; then
  echo "  Found app id=${app_id}; getting client_id and trying to regenerate secret..."
  client_id="$(echo "${apps_json}" | jq -r --argjson id "${app_id}" 'map(select(.id==$id)) | .[0].client_id')"

  regen_raw="$(curl -sS -X POST -H "${auth_hdr[@]}" -H "${json_hdr[@]}" \
    "${GITEA_URL}/api/v1/user/applications/oauth2/${app_id}/secret" || true)"
  regen_json="$(ensure_secret_json "${regen_raw}")"
  client_secret="$(echo "${regen_json}" | jq -r '.client_secret')"

  if [[ -z "${client_secret}" || "${client_secret}" == "null" ]]; then
    echo "  Regenerate returned no secret; recreating app to obtain fresh client_id/secret..."
    # Delete and recreate (safe in dev/offline lab)
    curl -sS -X DELETE -H "${auth_hdr[@]}" "${GITEA_URL}/api/v1/user/applications/oauth2/${app_id}" >/dev/null 2>&1 || true
    create_payload="$(jq -n --arg name "${APP_NAME}" --arg uri "${REDIRECT_URI}" '{name:$name, redirect_uris:[$uri]}')"
    create_json="$(curl -sS -X POST -H "${auth_hdr[@]}" -H "${json_hdr[@]}" -d "${create_payload}" \
      "${GITEA_URL}/api/v1/user/applications/oauth2")"
    client_id="$(echo "${create_json}" | jq -r '.client_id')"
    client_secret="$(echo "${create_json}" | jq -r '.client_secret')"
  fi
else
  echo "  Creating new OAuth app..."
  create_payload="$(jq -n --arg name "${APP_NAME}" --arg uri "${REDIRECT_URI}" '{name:$name, redirect_uris:[$uri]}')"
  create_json="$(curl -sS -X POST -H "${auth_hdr[@]}" -H "${json_hdr[@]}" -d "${create_payload}" \
    "${GITEA_URL}/api/v1/user/applications/oauth2")"
  client_id="$(echo "${create_json}" | jq -r '.client_id')"
  client_secret="$(echo "${create_json}" | jq -r '.client_secret')"
fi

[[ -n "${client_id}" && -n "${client_secret}" && "${client_id}" != "null" && "${client_secret}" != "null" ]] || {
  echo "ERROR: Could not obtain client_id/client_secret from Gitea"; exit 1;
}
echo "  client_id=${client_id}"

echo "[2/5] Ensure namespace '${NAMESPACE}'..."
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${NAMESPACE}"

echo "[3/5] Apply Drone secret '${SECRET_NAME}'..."
kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" >/dev/null 2>&1 || \
  kubectl -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" --from-literal=PLACEHOLDER=1 >/dev/null 2>&1 || true
kubectl -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" \
  --from-literal=DRONE_GITEA_CLIENT_ID="${client_id}" \
  --from-literal=DRONE_GITEA_CLIENT_SECRET="${client_secret}" \
  --from-literal=DRONE_RPC_SECRET="${DRONE_RPC_SECRET}" \
  -o yaml --dry-run=client | kubectl apply -f -

echo "[4/5] Ensure Drone server hosts..."
kubectl -n "${NAMESPACE}" set env deploy/"${DEPLOYMENT}" \
  DRONE_GITEA_SERVER="${DRONE_GITEA_SERVER}" \
  DRONE_SERVER_HOST="${DRONE_SERVER_HOST}" \
  DRONE_SERVER_PROTO="${DRONE_SERVER_PROTO}" \
  DRONE_SERVER_PORT=":80"

echo "[5/5] Restart & wait..."
kubectl -n "${NAMESPACE}" rollout restart deploy/"${DEPLOYMENT}" || true
kubectl -n "${NAMESPACE}" rollout status deploy/"${DEPLOYMENT}" --timeout=120s || true

echo "Sanitized env:"
kubectl -n "${NAMESPACE}" get deploy "${DEPLOYMENT}" -o yaml | sed -n '/env:/,/volumeMounts:/p' \
  | sed 's/\(DRONE_GITEA_CLIENT_SECRET\|DRONE_RPC_SECRET\).*/\1: ****/g'

echo "Done. In Gitea the redirect must be exactly: ${REDIRECT_URI}"
echo "Open http://${DRONE_SERVER_HOST} → Continue."