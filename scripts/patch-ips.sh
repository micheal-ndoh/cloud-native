#!/usr/bin/env bash
set -euo pipefail

# Detect current Multipass VM IPs and patch files that reference the local registry IP
# Usage: ./scripts/patch-ips.sh

get_ip() {
  local name="$1"
  multipass info "$name" --format json 2>/dev/null | jq -r '.info["'"$name"'"] | .ipv4[0]'
}

REG_NAME=${REG_NAME:-docker-registry}
MASTER_NAME=${MASTER_NAME:-k3s-master}

REG_IP=${REG_IP:-$(get_ip "$REG_NAME")}
MASTER_IP=${MASTER_IP:-$(get_ip "$MASTER_NAME")}

if [[ -z "$REG_IP" || "$REG_IP" == "null" ]]; then
  echo "Failed to detect registry IP (vm: $REG_NAME)" >&2
  exit 1
fi
if [[ -z "$MASTER_IP" || "$MASTER_IP" == "null" ]]; then
  echo "Failed to detect master IP (vm: $MASTER_NAME)" >&2
  exit 1
fi

echo "Detected: REGISTRY_IP=$REG_IP MASTER_IP=$MASTER_IP"

# Replace any literal <ip>:5000/ registry references with current REG_IP:5000/
# Only in our app manifests and docs (avoid .split-tmp)
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
shopt -s nullglob globstar

files=(
  "$ROOT_DIR/apps"/**/*.yaml
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/docs"/**/*.md
  "$ROOT_DIR/scripts/mirror-images.sh"
)

pattern='\b([0-9]{1,3}\.){3}[0-9]{1,3}:5000/'
replacement="$REG_IP:5000/"

for f in "${files[@]}"; do
  [[ "$f" == *".split-tmp/"* ]] && continue
  [[ -f "$f" ]] || continue
  if grep -qE "$pattern" "$f"; then
    echo "Patching $f"
    sed -i -E "s/$pattern/$replacement/g" "$f"
  fi
done

echo "Done patching registry IP references."