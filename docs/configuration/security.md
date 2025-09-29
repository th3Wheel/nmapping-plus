# Security Configuration

This document outlines best practices and configuration options for securing nMapping+ deployments.

## Key Security Areas
- **Container Hardening**: Use unprivileged LXC containers, minimal packages, and resource limits.
- **Network Segmentation**: Isolate scanner and dashboard containers from sensitive networks; use VLANs or firewalls.
- **Authentication**: Enable dashboard login and API keys; use strong, unique passwords.
- **Encryption**: Always enable HTTPS for dashboard access; use SSH for Git sync.
- **Logging & Monitoring**: Enable audit logs, monitor for suspicious activity, and set up alerts.

## Example: Firewall Rules (Proxmox)
```bash
pct set 201 -net0 firewall=1
pct set 202 -net0 firewall=1
# Allow only required ports (e.g., 80, 443, 22)
```

## Example: Enabling Authentication
```
AUTH_REQUIRED=true
API_KEY=your-strong-api-key
```

## Best Practices
- Regularly update all containers and dependencies
- Limit SSH and dashboard access to trusted IPs
- Use fail2ban or similar tools to block brute-force attacks
- Review logs and alerts regularly

## References
- [Proxmox LXC Security](https://pve.proxmox.com/wiki/Linux_Container)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Linux Hardening Checklist](https://www.cisecurity.org/benchmark/ubuntu_linux)
