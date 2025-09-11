#!/bin/bash
set -euo pipefail

print() { echo -e "[obs] $1"; }

ns=${1:-linkerd-viz}

case "${2:-}" in
  dashboard)
    print "Opening Linkerd Viz dashboard (requires linkerd CLI)..."
    linkerd viz dashboard
    ;;
  port-forward)
    print "Port-forwarding Linkerd Viz web svc on :8084"
    kubectl -n $ns port-forward svc/web 8084:8084
    ;;
  checks)
    print "Running linkerd checks"
    linkerd check
    ;;
  stat)
    target_ns=${3:-backend}
    deploy=${4:-task-api}
    print "Stat for $target_ns deploy/$deploy"
    linkerd -n "$target_ns" stat deploy/"$deploy"
    ;;
  tap)
    target_ns=${3:-backend}
    deploy=${4:-task-api}
    print "Tapping traffic for $target_ns deploy/$deploy (Ctrl+C to stop)"
    linkerd -n "$target_ns" tap deploy/"$deploy"
    ;;
  edges)
    print "Mesh edges"
    linkerd viz edges
    ;;
  routes)
    target_ns=${3:-backend}
    svc=${4:-task-api}
    print "Routes for svc/$svc in ns/$target_ns"
    linkerd viz routes -n "$target_ns" svc/"$svc"
    ;;
  *)
    cat <<EOF
Observability helper
Usage:
  $0 [namespace] <command> [args]

Commands:
  dashboard                  Open Linkerd Viz dashboard (CLI)
  port-forward               Port-forward viz web to localhost:8084
  checks                     Run linkerd control-plane checks
  stat  <ns> <deploy>        mesh stats for a deployment (default backend task-api)
  tap   <ns> <deploy>        live traffic tap for a deployment
  edges                      show mesh edges
  routes <ns> <svc>          show HTTP routes for a service
EOF
    ;;
esac

