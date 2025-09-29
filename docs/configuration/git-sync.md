# Git Synchronization Configuration

This document explains how to configure secure, automated Git-based data synchronization between the nMapping+ scanner and dashboard containers.

## Purpose
- Ensure all scan results and network changes are versioned and available to the dashboard in real time.
- Enable rollback, audit, and distributed collaboration.

## Configuration Steps
1. **Generate SSH Keys**
   - On both containers, generate SSH keys for the relevant user (e.g., `scanner`, `nmapping`).
2. **Exchange Public Keys**
   - Add each container's public key to the other's `authorized_keys` for passwordless Git operations.
3. **Configure Git Remotes**
   - Set the scanner as the Git origin for the dashboard, or use a central bare repo.
4. **Set Up Cron or Systemd Timer**
   - Automate `git pull`/`git push` at regular intervals.

## Example: SSH Key Generation
```bash
sudo -u scanner ssh-keygen -t ed25519 -N ""
sudo -u nmapping ssh-keygen -t ed25519 -N ""
```

## Example: Cron Job for Sync
```cron
*/5 * * * * cd /dashboard/data && git pull && git push
```

## Security Best Practices
- Use unique SSH keys per container
- Restrict Git access to specific IPs/networks
- Monitor Git logs for unauthorized access
- Use Git hooks for validation if needed

## References
- [Pro Git Book: Remote Repositories](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes)
- [SSH Key Authentication](https://www.ssh.com/academy/ssh/keygen)
- [Automating Git with Cron](https://www.cyberciti.biz/faq/how-to-automate-git-pull-using-cron-job/)
