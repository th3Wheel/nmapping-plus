# Backup and Recovery Guide

This guide describes how to back up and restore your nMapping+ deployment for disaster recovery and data protection.

## What to Back Up

- **LXC Containers**: Full snapshots of scanner and dashboard containers
- **Database**: Regular SQLite database dumps from the dashboard
- **Git Data**: The `/nmap/registry` directory (scan results and change history)
- **Configuration Files**: All files in `/nmap/config` and `/dashboard/config`

## Backup Methods

- **Proxmox Snapshots**: Use `vzdump` for full container backups
- **Database Dumps**: Use `sqlite3` to export the dashboard database
- **Git Archive**: Use `git bundle` or `tar` to archive the registry

## Example Backup Commands

```bash
# Full container backup
vzdump 201 --mode stop --compress gzip --storage local
vzdump 202 --mode stop --compress gzip --storage local

# Database backup
pct exec 202 -- sqlite3 /dashboard/data/dashboard.db ".backup '/tmp/dashboard-backup.db'"

# Git data backup
pct exec 201 -- tar -czf /tmp/nmap-data-backup.tar.gz /nmap/registry
```

## Recovery Steps

- Restore containers with `vzdump` or Proxmox UI
- Restore database with `sqlite3 .restore`
- Restore Git data with `tar` or `git clone`

## Best Practices

- Schedule regular automated backups
- Store backups offsite or in secure storage
- Test recovery procedures periodically

## References

- [Proxmox Backup and Restore](https://pve.proxmox.com/wiki/Backup_and_Restore)
- [SQLite Backup Guide](https://sqlite.org/backup.html)
- [Disaster Recovery Planning](https://www.nist.gov/publications/contingency-planning-guide-information-technology-systems)
