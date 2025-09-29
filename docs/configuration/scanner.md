# Scanner Configuration

This document describes how to configure the nMapping+ scanner container for optimal network discovery and security assessment.

## Configuration File Location
- `/nmap/config/targets.conf` — List of target networks (CIDR notation)
- `/nmap/config/scanner.conf` — Scanner options and scheduling

## Key Settings
- **Targets**: Specify networks to scan (e.g., `192.168.1.0/24`)
- **Scan Types**: Choose between full, fast, or custom scans
- **Schedule**: Set scan intervals using cron (e.g., daily, hourly)
- **Exclusions**: List IPs or ranges to skip
- **Credentials**: (Optional) For authenticated scans (SMB, SNMP, etc.)

## Example: targets.conf
```
192.168.1.0/24
10.0.0.0/24
```

## Example: scanner.conf
```
SCAN_TYPE=fast
SCHEDULE="0 * * * *"  # Every hour
EXCLUDE=192.168.1.100,10.0.0.5
```

## Best Practices
- Use least privilege for scanner container (unprivileged LXC)
- Limit scan frequency to avoid network disruption
- Regularly review and update target lists
- Monitor scan logs for errors or anomalies

## References
- [Nmap Documentation](https://nmap.org/book/man.html)
- [Proxmox LXC Security](https://pve.proxmox.com/wiki/Linux_Container)
- [Network Scanning Best Practices](https://www.sans.org/white-papers/1139/)
