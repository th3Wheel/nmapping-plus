# Monitoring Guide

This guide explains how to monitor the health, performance, and security of your nMapping+ deployment.

## What to Monitor

- **Container Health**: Use `pct status` and `systemctl status` for scanner and dashboard containers.
- **Service Status**: Monitor Nmap, dashboard, Nginx, and database services.
- **Resource Usage**: Track CPU, memory, disk, and network usage with Proxmox tools or `htop`, `iftop`.
- **Scan Results**: Review scan logs and change alerts for anomalies.
- **API/Health Endpoint**: Use `/api/health` for automated health checks.

## Example Monitoring Commands

```bash
pct status 201
pct exec 201 -- systemctl status nmapping-scanner
pct exec 202 -- systemctl status nmapping-dashboard
pct exec 202 -- tail -f /var/log/nginx/access.log
```

## Integrations

- **Prometheus**: Scrape custom metrics from dashboard endpoints.
- **Grafana**: Visualize trends and alerts.
- **SIEM**: Forward logs to security platforms for analysis.

## Best Practices

- Set up automated alerts for service failures or resource exhaustion.
- Regularly review logs and scan results.
- Use versioned backups for audit and rollback.

## References

- [Proxmox Monitoring](https://pve.proxmox.com/wiki/Monitoring)
- [Prometheus Monitoring](https://prometheus.io/docs/introduction/overview/)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
- [SIEM Fundamentals](https://www.sans.org/white-papers/siem/)
