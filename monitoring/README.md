# Monitoring

Prometheus, Grafana, and Linkerd viz access tips.

## Access
```bash
# Start forwards for common tools
../../scripts/port-forward-all.sh
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3000
# Linkerd:    http://localhost:8084
```

## Dashboards
- Import `dashboards/app-dashboard.json` into Grafana

## Notes
- If behind mesh, prefer pod-based port-forward for Grafana (script does this)