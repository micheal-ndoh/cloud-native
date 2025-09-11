#!/usr/bin/env bash
set -euo pipefail

# Idempotent installer for required CLIs on Linux (x86_64)
# Installs: linkerd, argocd, drone, kcadm (proxy to in-cluster Keycloak)
# Usage: sudo ./scripts/install-clis.sh

ARCH=$(uname -m)
OS=$(uname -s)
BIN_DIR=/usr/local/bin

need_sudo() {
  [ "$(id -u)" -eq 0 ] || { echo "Please run as root (sudo)." >&2; exit 1; }
}

install_linkerd() {
  if command -v linkerd >/dev/null 2>&1; then
    echo "[cli] linkerd already installed: $(linkerd version --client || true)"
    return
  fi
  echo "[cli] Installing linkerd CLI..."
  curl -fsSL https://run.linkerd.io/install | sh
  mv "$HOME/.linkerd2/bin/linkerd" "$BIN_DIR/linkerd"
  chmod +x "$BIN_DIR/linkerd"
}

install_argocd() {
  if command -v argocd >/dev/null 2>&1; then
    echo "[cli] argocd already installed: $(argocd version --client 2>/dev/null || true)"
    return
  fi
  echo "[cli] Installing argo cd CLI..."
  curl -fsSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  install -m 0755 /tmp/argocd "$BIN_DIR/argocd"
}

install_drone() {
  if command -v drone >/dev/null 2>&1; then
    echo "[cli] drone already installed: $(drone --version 2>/dev/null || true)"
    return
  fi
  echo "[cli] Installing drone CLI..."
  curl -fsSL -o /tmp/drone.tar.gz https://github.com/harness/drone-cli/releases/latest/download/drone_linux_amd64.tar.gz
  tar -C /tmp -xzf /tmp/drone.tar.gz drone
  install -m 0755 /tmp/drone "$BIN_DIR/drone"
}

install_kcadm_proxy() {
  if command -v kcadm >/dev/null 2>&1; then
    echo "[cli] kcadm proxy already installed"
    return
  fi
  echo "[cli] Installing kcadm proxy (kubectl exec wrapper)..."
  cat > "$BIN_DIR/kcadm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
NS=${KEYCLOAK_NAMESPACE:-keycloak}
POD=$(kubectl -n "$NS" get pod -l app=keycloak -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [[ -z "${POD:-}" ]]; then
  echo "Keycloak pod not found in namespace $NS" >&2
  exit 1
fi
kubectl -n "$NS" exec -i "$POD" -- /opt/keycloak/bin/kcadm.sh "$@"
EOF
  chmod +x "$BIN_DIR/kcadm"
}

main() {
  need_sudo
  case "$OS/$ARCH" in
    Linux/x86_64|Linux/amd64)
      install_linkerd
      install_argocd
      install_drone
      install_kcadm_proxy
      ;;
    *)
      echo "[cli] Unsupported platform: $OS/$ARCH" >&2
      exit 1
      ;;
  esac
  echo "[cli] Done. Installed CLIs in $BIN_DIR"
}

main "$@"