#!/usr/bin/env bash
set -euo pipefail

# Mirror images to local registry 10.38.229.242:5000 without duplicates
# Usage: ./scripts/mirror-images.sh

REG=10.38.229.242:5000
IMAGES=(
  "drone/drone:2"
  "drone/drone-runner-docker:1"
)

# Choose docker or nerdctl if available
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