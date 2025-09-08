#!/usr/bin/env bash

set -euo pipefail

# Simple helper to check if a local port is free
is_port_free() {
	local port="$1"
	if ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${port}$"; then
		return 1
	fi
	return 0
}

# Start a kubectl port-forward in background with logging, if the port is free
start_pf() {
	local ns="$1"
	local kind="$2"   # svc|pod|deploy
	local name="$3"
	local local_port="$4"
	local remote_port="$5"
	local label_selector="${6:-}"

	if ! is_port_free "$local_port"; then
		echo "[SKIP] Port ${local_port} already in use for ${ns} ${kind}/${name}" >&2
		return 0
	fi

	local target_ref="$kind/${name}"

	# If targeting a pod dynamically by label
	if [[ "$kind" == "pod" && -n "$label_selector" ]]; then
		local pod
		pod=$(kubectl -n "$ns" get pods -l "$label_selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
		if [[ -z "$pod" ]]; then
			echo "[WARN] No pod found for label ${label_selector} in ${ns}. Skipping." >&2
			return 0
		fi
		target_ref="pod/${pod}"
	fi

	local log_file="/tmp/pf-${ns}-${name//\//_}-${local_port}.log"
	nohup kubectl -n "$ns" port-forward "$target_ref" "${local_port}:${remote_port}" \
		>"${log_file}" 2>&1 &
	local pid=$!
	echo "[OK] ${ns} ${target_ref} ${local_port}:${remote_port} (pid ${pid}) | log: ${log_file}"
}

echo "Starting common port-forwards..."

# Monitoring: Prometheus (monitoring/prometheus -> 9090)
start_pf monitoring svc prometheus 9090 9090

# Monitoring: Grafana (monitoring/app=grafana -> 3000)
# Use dynamic pod selection to avoid service/mesh quirks
start_pf monitoring pod grafana 3000 3000 "app=grafana"

# CD: Argo CD server (argocd/argocd-server -> 8080)
start_pf argocd svc argocd-server 8080 80

# Git: Gitea (gitea/gitea -> 3001 since 3000 is Grafana)
start_pf gitea svc gitea 3001 3000

# Auth: Keycloak (keycloak/keycloak -> 8081)
start_pf keycloak svc keycloak 8081 80

# CI: Drone Server (ci/drone-server -> 8082)
start_pf ci svc drone-server 8082 80

# App: Task API (backend/task-api -> 8083)
start_pf backend svc task-api 8083 3000

# Service Mesh UI: Linkerd Viz Web (linkerd-viz/web -> 8084)
start_pf linkerd-viz svc web 8084 8084

cat <<'URLS'

Local URLs (if forwards started):
- Prometheus:           http://localhost:9090/graph
- Grafana:              http://localhost:3000/
- Argo CD:              http://localhost:8080/
- Gitea:                http://localhost:3001/
- Keycloak:             http://localhost:8081/
- Drone:                http://localhost:8082/
- Task API (service):   http://localhost:8083/
- Linkerd Dashboard:    http://localhost:8084/

Tip: To stop all forwards started from this shell session, use `pkill -f "kubectl .* port-forward"`.
URLS

