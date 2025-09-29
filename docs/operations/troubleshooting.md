# Troubleshooting Guide

This guide provides solutions to common issues encountered when deploying or operating nMapping+.

## Common Issues & Solutions

### 1. Scanner Not Finding Devices

- **Check network connectivity**: `pct exec 201 -- ping 8.8.8.8`
- **Verify Nmap installation**: `pct exec 201 -- nmap --version`
- **Review scan logs**: `pct exec 201 -- tail -f /nmap/logs/scanner.log`

### 2. Dashboard Not Accessible

- **Check Nginx status**: `pct exec 202 -- systemctl status nginx`
- **Check port binding**: `pct exec 202 -- netstat -tuln | grep ':80\|:443'`
- **Test local access**: `pct exec 202 -- curl -s http://localhost/api/health`

### 3. Git Sync Failing

- **Test SSH connectivity**: `pct exec 202 -- sudo -u nmapping ssh scanner@<scanner-ip> echo 'OK'`
- **Check Git status**: `pct exec 201 -- sudo -u scanner git -C /nmap/registry status`

### 4. High Resource Usage

- **Check resource usage**: `pct exec 201 -- htop`, `pct exec 202 -- htop`
- **Review logs for errors**

### 5. Database Issues

- **Check SQLite status**: `pct exec 202 -- sqlite3 /dashboard/data/dashboard.db '.tables'`
- **Restore from backup if corrupted**

## General Tips

- Always check logs for error messages
- Use Proxmox UI for container status and console access
- Consult documentation for configuration details

## References

- [Proxmox Troubleshooting](https://pve.proxmox.com/wiki/Troubleshooting)
- [Nmap Troubleshooting](https://nmap.org/book/man-briefoptions.html)
- [Flask Debugging](https://flask.palletsprojects.com/en/latest/errorhandling/)
- [Git Troubleshooting](https://git-scm.com/docs/git-fsck)
- [SQLite Troubleshooting](https://sqlite.org/faq.html)
