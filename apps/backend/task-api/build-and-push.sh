#!/bin/bash
set -euo pipefail

REGISTRY_HOST="registry.local:5000"
IMAGE_NAME="task-api"
# Allow passing the tag as the first argument or via DRONE_COMMIT_SHA; fallback to latest
TAG="${1:-${DRONE_COMMIT_SHA:-latest}}"

echo "Building ${IMAGE_NAME}:${TAG}..."
docker build -t ${IMAGE_NAME}:${TAG} -f Dockerfile .

echo "Tagging to ${REGISTRY_HOST}/${IMAGE_NAME}:${TAG}..."
docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY_HOST}/${IMAGE_NAME}:${TAG}

echo "Pushing to ${REGISTRY_HOST}..."
docker push ${REGISTRY_HOST}/${IMAGE_NAME}:${TAG}

echo "Done."
