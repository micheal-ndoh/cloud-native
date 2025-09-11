# Monitoring

Prometheus, Grafana, and Linkerd viz access tips.

## Access
```bash
# Start forwards for common tools
../../scripts/port-forward-all.sh
# Prometheus: http://prom.local
# Grafana:    http://grafana.local
# Linkerd:    http://linkerd.local
```

## Dashboards
- Import `dashboards/app-dashboard.json` into Grafana

## Notes
- If behind mesh, prefer pod-based port-forward for Grafana (script does this)