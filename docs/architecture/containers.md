# Container Architecture

This document describes the containerized architecture of nMapping+ as deployed on Proxmox VE using LXC containers.

## Overview

nMapping+ uses a dual-container model for separation of concerns, scalability, and security:

- **Scanner Container**: Runs network discovery, scanning, and data collection tools (Nmap, Masscan, custom scripts).
- **Dashboard Container**: Hosts the Flask web dashboard, SQLite database, API server, and reverse proxy (Nginx).

## Container Roles

### Scanner Container

- **Purpose**: Perform scheduled and on-demand network scans.
- **Key Components**:
  - Nmap, Masscan, Python scripts
  - Git client for change tracking
  - Cron for scheduling
- **Networking**: Requires access to target networks; typically unprivileged LXC for security.

### Dashboard Container

- **Purpose**: Provide real-time web UI, API, and data analytics.
- **Key Components**:
  - Flask (web server), Gunicorn (WSGI), Nginx (reverse proxy)
  - SQLite database
  - WebSocket server for live updates
  - Git client for data sync
- **Networking**: Exposes HTTP/HTTPS to management network; can be placed behind a firewall or VPN.

## Communication

- **Data Sync**: Git is used for secure, versioned data transfer between containers.
- **API**: RESTful API and WebSocket endpoints are exposed by the dashboard container.
- **Security**: SSH keys and firewall rules recommended for inter-container communication.

## References

- [Proxmox LXC Documentation](https://pve.proxmox.com/wiki/Linux_Container)
- [Docker vs LXC: Security and Use Cases](https://www.redhat.com/sysadmin/lxc-docker-containers)
- [Flask Deployment Options](https://flask.palletsprojects.com/en/latest/deploying/)
