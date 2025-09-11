#!/usr/bin/env bash
set -euo pipefail

# Mirror images to local registry without duplicates
# Usage: REG=10.38.229.242:5000 ./scripts/mirror-images.sh  OR auto-detect from Multipass

get_ip() {
  local name="$1"
  multipass info "$name" --format json 2>/dev/null | jq -r '.info["'"$name"'"] | .ipv4[0]'
}

REG_HOSTPORT=${REG:-}
if [[ -z "$REG_HOSTPORT" ]]; then
  REG_IP=$(get_ip docker-registry || true)
  if [[ -n "$REG_IP" && "$REG_IP" != null ]]; then
    REG_HOSTPORT="$REG_IP:5000"
  else
    echo "Could not auto-detect registry IP. Set REG=<ip:port> env." >&2
    exit 1
  fi
fi

REG="$REG_HOSTPORT"

IMAGES=(
  "drone/drone:2"
  "drone/drone-runner-docker:1"
)

PUSHER=""
if command -v docker >/dev/null 2>&1; then PUSHER=docker; fi
if [[ -z "$PUSHER" ]] && command -v nerdctl >/dev/null 2>&1; then PUSHER=nerdctl; fi
if [[ -z "$PUSHER" ]]; then
  echo "No docker/nerdctl found. Please mirror images manually." >&2
  exit 1
fi

for src in "${IMAGES[@]}"; do
  name_tag=${src##*/}
  dest="$REG/${name_tag}"
  if $PUSHER image inspect "$dest" >/dev/null 2>&1; then
    echo "Already mirrored: $dest"
    continue
  fi
  echo "Mirroring $src -> $dest"
  $PUSHER pull "$src"
  $PUSHER tag "$src" "$dest"
  $PUSHER push "$dest"
 done
 echo "Done."