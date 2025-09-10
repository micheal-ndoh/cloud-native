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

	# Retry logic for transient 5xx/proxy errors during startup
	local max_retries="${MAX_PF_RETRIES:-5}"
	local backoff_seconds="${PF_INITIAL_BACKOFF:-2}"
	local attempt=1
	while :; do
		# Ensure port still free before each attempt
		if ! is_port_free "$local_port"; then
			echo "[SKIP] Port ${local_port} became busy while starting ${ns} ${target_ref}" >&2
			return 0
		fi

		# Clear previous log to avoid stale error detection
		: >"${log_file}"

		nohup kubectl -n "$ns" port-forward "$target_ref" "${local_port}:${remote_port}" \
			>"${log_file}" 2>&1 &
		local pid=$!

		# Give it a moment to fail fast if there's a proxy error
		sleep 2

		if grep -qiE "(error upgrading connection|502 Bad Gateway|proxy error)" "${log_file}"; then
			# Detected a transient startup failure, kill and retry
			kill "$pid" 2>/dev/null || true
			wait "$pid" 2>/dev/null || true
			if (( attempt >= max_retries )); then
				echo "[FAIL] ${ns} ${target_ref} ${local_port}:${remote_port} after ${attempt} attempts | log: ${log_file}" >&2
				return 1
			fi
			echo "[RETRY] ${ns} ${target_ref} attempt ${attempt}/${max_retries} due to startup proxy error; backing off ${backoff_seconds}s" >&2
			sleep "$backoff_seconds"
			attempt=$((attempt + 1))
			# Exponential backoff up to a small ceiling
			if (( backoff_seconds < 10 )); then
				backoff_seconds=$((backoff_seconds * 2))
			fi
			continue
		fi

		echo "[OK] ${ns} ${target_ref} ${local_port}:${remote_port} (pid ${pid}) | log: ${log_file}"
		return 0
	done
}

echo "Starting required port-forwards (3000, 8080, 8084, 9090)..."

# Monitoring: Prometheus (monitoring/prometheus -> 9090)
start_pf monitoring svc prometheus 9090 9090

# Monitoring: Grafana (monitoring/app=grafana -> 3000)
# Use dynamic pod selection to avoid service/mesh quirks
start_pf monitoring pod grafana 3000 3000 "app=grafana"

# GitOps: Argo CD Server (argocd/argocd-server -> 8080:443)
start_pf argocd svc argocd-server 8080 443

# Service Mesh UI: Linkerd Viz Web (linkerd-viz/web -> 8084)
start_pf linkerd-viz svc web 8084 8084

cat <<'URLS'

Local URLs (if forwards started):
- Prometheus:        http://localhost:9090/graph
- Grafana:           http://localhost:3000/
- Argo CD:           http://localhost:8080/
- Linkerd Dashboard: http://localhost:8084/

Tip: To stop all forwards started from this shell session, use `pkill -f "kubectl .* port-forward"`.
URLS

