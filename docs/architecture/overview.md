# System Architecture — nMapping+

## Overview

nMapping+ is a container-based network-mapping platform composed of discrete services that collaborate to discover, store, visualize, and notify about network topology and changes. The architecture favors small, single-responsibility containers (LXC) to simplify deployment on Proxmox VE and to enable horizontal scaling for larger environments.

## Core Components

- Scanner
  - Performs scheduled and on-demand network discovery using Nmap and supplemental probes.
  - Emits structured results to the Data API and commits snapshot diffs to the Git store for change tracking.
- Data API
  - RESTful API and WebSocket endpoint.
  - Validates and normalizes scanner output, persists to SQLite (WAL) and exposes metrics for monitoring.
- Database
  - SQLite with WAL mode for simplicity and portability. Schema described in architecture/database.md.
  - Stores device inventory, adjacency/topology data, change history metadata, and scan logs.
- Dashboard
  - Web UI (Flask backend + frontend assets) that subscribes to WebSocket updates for real-time visualization.
  - Renders interactive topology maps and historical change views.
- Git Sync
  - Keeps a versioned history of network snapshots and diffs (for audit and rollback).
  - Optional remote sync for offsite backup or CI-driven analysis.
- Notification/Integrations
  - Webhook and SIEM connectors for external alerting (see integration/webhooks.md and integration/siem.md).

## Deployment Topology

- Single-node (minimal/test): All components may run in a single LXC container.
- Multi-container (recommended): Separate LXC containers for Scanner, API+DB, Dashboard, and Git Sync to improve isolation and scalability.
- High-availability options are described in advanced/high-availability.md.

Diagram (logical)
```
[Scanner] --> [Data API] <--> [SQLite DB]
                       \
                        --> [Git Sync]
                       \
                        --> [Dashboard (Web + WS)]
                       \
                        --> [Notifier / Webhooks / SIEM]
```

## Security & Networking

- Scanner containers should run in a network namespace with appropriate privileges and restrict outbound management access.
- API and Dashboard should be placed behind authentication and TLS (reverse proxy recommended).
- Follow recommendations in configuration/security.md for access control, secrets, and firewall rules.

## Observability

- Expose Prometheus-compatible metrics from the API and Scanner.
- Centralized logs (syslog/ELK) recommended for production; see operations/monitoring.md.

## References

- Container layout and comms: architecture/containers.md
- Database schema: architecture/database.md
- API endpoints and WebSocket contract: architecture/api.md
- HA patterns: advanced/high-availability.md
