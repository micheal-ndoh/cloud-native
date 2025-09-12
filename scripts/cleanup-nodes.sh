#!/usr/bin/env bash

set -euo pipefail

# Reclaims disk space on K3s nodes (Multipass VMs) and cleans up failed/evicted pods.
# Then restarts critical services that depend on repo access (Gitea, ArgoCD repo-server).
#
# Usage:
#   chmod +x scripts/cleanup-nodes.sh
#   scripts/cleanup-nodes.sh
#
# Notes:
# - This script targets Multipass instances named k3s-master and k3s-worker.
# - It uses crictl/ctr and journalctl to vacuum cache and logs.
# - It will NOT delete PVC data. It only prunes container images, cache, and logs.

NODES=(k3s-master k3s-worker)

info() { echo "[INFO] $*"; }
run_node() { local node="$1"; shift; multipass exec "$node" -- bash -lc "$*"; }

info "Nodes: ${NODES[*]}"

for node in "${NODES[@]}"; do
  info "==== Cleaning node: ${node} ===="

  info "Show disk usage before:"
  run_node "$node" 'df -h || true'
  run_node "$node" 'sudo du -sh /var/lib/rancher/k3s/agent || true'

  info "Prune container images/content (crictl/ctr)"
  run_node "$node" 'command -v crictl >/dev/null 2>&1 && sudo crictl rmi --prune --all || true'
  run_node "$node" 'command -v ctr >/dev/null 2>&1 && sudo ctr -n k8s.io images prune --all || true'

  info "Vacuum systemd journal (keep last 1 day)"
  run_node "$node" 'sudo journalctl --vacuum-time=1d || true'

  info "Truncate large logs under /var/log (>20MB)"
  run_node "$node" 'sudo find /var/log -type f -name "*.log" -size +20M -exec sudo truncate -s 0 {} \; || true'

  info "Clean temporary directories"
  run_node "$node" 'sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true'

  info "Remove Failed/Evicted pod sandboxes (best effort)"
  # Try stop then remove; ignore timeouts and continue.
  run_node "$node" 'if command -v crictl >/dev/null 2>&1; then sudo crictl pods --quiet | xargs -r -I{} timeout 3s sudo crictl stopp {} || true; fi'
  run_node "$node" 'if command -v crictl >/dev/null 2>&1; then sudo crictl pods --quiet | xargs -r -I{} sudo crictl rmp {} || true; fi'

  info "Show disk usage after:"
  run_node "$node" 'df -h || true'
  run_node "$node" 'sudo du -sh /var/lib/rancher/k3s/agent || true'

done

info "==== Kubernetes cleanup of Failed/Evicted pods ===="
# Delete failed pods cluster-wide
kubectl get pods -A --field-selector=status.phase=Failed -o name | xargs -r kubectl delete --force --grace-period=0
# Delete evicted pods cluster-wide
kubectl get pods -A | awk "/Evicted/ {print \$1 \" \" \$2}" | while read ns pod; do kubectl -n "$ns" delete pod "$pod" --force --grace-period=0 || true; done

info "==== Restart Gitea and ArgoCD repo-server ===="
# Restart Gitea (if present)
kubectl -n gitea rollout restart deploy/gitea || true
kubectl -n gitea rollout status deploy/gitea --timeout=180s || true
kubectl -n gitea get svc,endpoints || true

# Restart ArgoCD repo-server (to refresh git connections)
kubectl -n argocd rollout restart deploy/argocd-repo-server || true
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=180s || true

info "==== Done. Recheck your applications in Argo CD. ===="