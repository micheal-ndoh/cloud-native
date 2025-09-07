#!/bin/bash
set -euo pipefail

# Split current mono-repo into two Gitea repos:
# - App repo:    Cloud-native (contains only apps/backend/task-api source)
# - Infra repo:  Cloud-native-infra (contains k8s manifests, gitops, infra, etc.)

GITEA_HOST="gitea.local"
GITEA_API="http://${GITEA_HOST}/api/v1"
USER="${1:-michealndoh}"
PASS="${2:-Nemory09}"
# Optional commit message, allow spaces via quoted arg
COMMIT_MSG="${3:-}"

APP_REPO="Cloud-native"
INFRA_REPO="Cloud-native-infra"

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORK_DIR="${ROOT_DIR}/.split-tmp"
APP_DIR="${WORK_DIR}/app"
INFRA_DIR="${WORK_DIR}/infra"

mkdir -p "${APP_DIR}" "${INFRA_DIR}"

need_bin() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need_bin git
need_bin curl
need_bin jq
need_bin rsync

echo "Creating (or ensuring) Gitea repos exist..."

# Create repo helper
create_repo() {
  local name="$1"
  # Try to create; ignore 409 conflicts if exists
  curl -sS -u "${USER}:${PASS}" -H "Content-Type: application/json" \
    -X POST "${GITEA_API}/user/repos" \
    -d "{\"name\":\"${name}\",\"private\":false}" \
    | jq -e '.id' >/dev/null || true
}

create_repo "${APP_REPO}"
create_repo "${INFRA_REPO}"

echo "Preparing app repo content..."

# Copy application source only
mkdir -p "${APP_DIR}/apps/backend"
rsync -a --delete \
  "${ROOT_DIR}/apps/backend/task-api" \
  "${APP_DIR}/apps/backend/"

# Optionally include a lightweight root README for app repo
cat >"${APP_DIR}/README.md" <<'EOF'
# Cloud-native (App)

This repository contains the Rust Task API application source (`apps/backend/task-api`).

Build and push image to local registry:
```bash
cd apps/backend/task-api
chmod +x build-and-push.sh
./build-and-push.sh
```
EOF

# Add Drone CI pipeline to build & push to registry.local:5000
cat >"${APP_DIR}/.drone.yml" <<'EOF'
kind: pipeline
type: docker
name: build-and-push

steps:
  - name: docker-build-push
    image: plugins/docker
    settings:
      repo: registry.local:5000/task-api
      tags:
        - latest
      dockerfile: apps/backend/task-api/Dockerfile
      context: apps/backend/task-api
      registry: registry.local:5000
      insecure: true
      skip_verify: true
      build_args_from_env:
        - RUSTFLAGS
    volumes:
      - name: dockersock
        path: /var/run/docker.sock

volumes:
  - name: dockersock
    host:
      path: /var/run/docker.sock

trigger:
  event:
    - push
    - tag
EOF

echo "Preparing infra repo content..."

# Copy everything except the application source folder and local artifacts
rsync -a --delete \
  --exclude '.git/' \
  --exclude 'target/' \
  --exclude '.split-tmp/' \
  --exclude 'apps/backend/task-api/' \
  "${ROOT_DIR}/" "${INFRA_DIR}/"

# Initialize and push app repo
push_repo() {
  local src_dir="$1"; shift
  local repo_name="$1"; shift
  local remote_url="http://${USER}:${PASS}@${GITEA_HOST}/${USER}/${repo_name}.git"

  (
    set -e
    cd "${src_dir}"

    # Initialize or reinitialize repo
    if [ ! -d .git ]; then
      git init
    else
      git init
    fi

    git config user.name "${USER}"
    git config user.email "${USER}@local"

    # Prepare commit
    git add -A
    # Use provided message or sensible default
    local msg
    if [ -n "${COMMIT_MSG}" ]; then
      msg="${COMMIT_MSG}"
    else
      msg="Initial split: ${repo_name}"
    fi

    # Only commit if there are staged changes
    if ! git diff --cached --quiet; then
      git commit -m "${msg}"
    else
      echo "[split] No changes to commit for ${repo_name}"
    fi

    # Ensure main branch exists and is current
    git checkout -B main

    # Configure remote origin (create or update)
    if git remote | grep -q '^origin$'; then
      git remote set-url origin "${remote_url}" || true
    else
      git remote add origin "${remote_url}"
    fi

    # Push (force to ensure initial state matches split)
    git push -u --force origin main
  )
}

echo "Pushing app repo to Gitea (${APP_REPO})..."
push_repo "${APP_DIR}" "${APP_REPO}"

echo "Pushing infra repo to Gitea (${INFRA_REPO})..."
push_repo "${INFRA_DIR}" "${INFRA_REPO}"

echo "Done. Repos available at:"
echo " - App:   http://${GITEA_HOST}/${USER}/${APP_REPO}.git"
echo " - Infra: http://${GITEA_HOST}/${USER}/${INFRA_REPO}.git"

echo "Note: ArgoCD Applications are configured to pull infra from in-cluster URL. Ensure Gitea Service is reachable from cluster."

