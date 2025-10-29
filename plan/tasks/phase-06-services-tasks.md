# Phase 6: Systemd Services & Automation - Detailed Tasks

**Phase**: 6 of 12
**Name**: Systemd Services & Automation
**Duration**: 2-3 days
**Effort**: 16-20 person-hours
**Dependencies**: Phase 2 (Scanner), Phase 5 (Database)

---

## Phase Overview

Implement production-ready systemd services for dashboard and scanner components with automated startup, monitoring, and self-healing.

---

## TASK-050: Create Dashboard Systemd Service

**Priority**: 🔴 Critical
**Effort**: 3 hours

### Description

Production systemd service for dashboard application.

**Create**: `systemd/nmapping-dashboard.service`

```ini
[Unit]
Description=nMapping+ Network Dashboard
Documentation=https://github.com/yourorg/nmapping-plus
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=nmapping
Group=nmapping
WorkingDirectory=/opt/nmapping-plus

# Environment
Environment="PYTHONPATH=/opt/nmapping-plus/src"
Environment="FLASK_ENV=production"
EnvironmentFile=/etc/nmapping/dashboard.env

# Execution
ExecStartPre=/opt/nmapping-plus/scripts/pre-start-checks.sh
ExecStart=/opt/nmapping-plus/venv/bin/gunicorn \
    --bind 0.0.0.0:5000 \
    --workers 4 \
    --worker-class eventlet \
    --timeout 120 \
    --access-logfile /var/log/nmapping/access.log \
    --error-logfile /var/log/nmapping/error.log \
    --log-level info \
    dashboard.dashboard_app:app

# Restart policy
Restart=always
RestartSec=10
StartLimitInterval=300
StartLimitBurst=5

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/nmapping-plus/data /var/log/nmapping

# Resource limits
MemoryLimit=512M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
```

---

## TASK-051: Create Scanner Systemd Service

**Priority**: 🔴 Critical
**Effort**: 3 hours

### Description

Service for network scanner daemon.

**Create**: `systemd/nmapping-scanner.service`

```ini
[Unit]
Description=nMapping+ Network Scanner
After=network-online.target nmapping-dashboard.service
Wants=network-online.target

[Service]
Type=simple
User=nmapping
Group=nmapping
WorkingDirectory=/opt/nmapping-plus

# Capabilities for network scanning
AmbientCapabilities=CAP_NET_RAW CAP_NET_ADMIN
CapabilityBoundingSet=CAP_NET_RAW CAP_NET_ADMIN

Environment="PYTHONPATH=/opt/nmapping-plus/src"
EnvironmentFile=/etc/nmapping/scanner.env

ExecStart=/opt/nmapping-plus/venv/bin/python3 \
    /opt/nmapping-plus/src/scanner/scanner_daemon.py

Restart=always
RestartSec=30

# Security
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/opt/nmapping-plus/scanner_data /var/log/nmapping

[Install]
WantedBy=multi-user.target
```

---

## TASK-052: Create Scanner Timer for Scheduled Scans

**Priority**: 🔴 Critical
**Effort**: 2 hours

### Description

Systemd timer for periodic network scans.

**Create**: `systemd/nmapping-scanner.timer`

```ini
[Unit]
Description=nMapping+ Scanner Timer
Requires=nmapping-scanner.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
```

---

## TASK-053: Create Service Installation Script

**Priority**: 🔴 Critical
**Effort**: 4 hours

### Description

Automated script to install and configure services.

**Create**: `scripts/install_services.sh`

```bash
#!/bin/bash
# Install nMapping+ systemd services

set -euo pipefail

INSTALL_DIR="/opt/nmapping-plus"
USER="nmapping"
GROUP="nmapping"

# Check root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Create user if not exists
if ! id "$USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$USER"
fi

# Create directories
mkdir -p /etc/nmapping
mkdir -p /var/log/nmapping
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/scanner_data"

# Set permissions
chown -R $USER:$GROUP "$INSTALL_DIR"
chown -R $USER:$GROUP /var/log/nmapping
chmod 750 /etc/nmapping

# Copy service files
cp systemd/*.service /etc/systemd/system/
cp systemd/*.timer /etc/systemd/system/

# Copy environment templates
cp config/dashboard.env.example /etc/nmapping/dashboard.env
cp config/scanner.env.example /etc/nmapping/scanner.env

# Set capabilities for scanner
setcap 'cap_net_raw,cap_net_admin=+ep' $(which nmap)

# Reload systemd
systemctl daemon-reload

# Enable services
systemctl enable nmapping-dashboard.service
systemctl enable nmapping-scanner.service
systemctl enable nmapping-scanner.timer

echo "Services installed. Edit /etc/nmapping/*.env and then:"
echo "  systemctl start nmapping-dashboard"
echo "  systemctl start nmapping-scanner.timer"
```

---

## TASK-054: Create Health Check Script

**Priority**: 🟡 High
**Effort**: 2 hours

### Description

Pre-start health checks for services.

**Create**: `scripts/pre-start-checks.sh`

Checks:
- Database file exists and is writable
- Required directories exist
- Configuration files valid
- Network connectivity
- Required ports available

---

## TASK-055: Implement Service Monitoring

**Priority**: 🟡 High
**Effort**: 3 hours

### Description

Monitoring and alerting for services.

Features:
- Service status checks
- Restart count monitoring
- Resource usage tracking
- Alert on repeated failures
- Integration with systemd journal

---

## TASK-056: Create Service Management Documentation

**Priority**: 🟡 High
**Effort**: 2 hours

### Description

**Create**: `docs/operations/service-management.md`

Include:
- Installation procedures
- Starting/stopping services
- Viewing logs
- Troubleshooting
- Common issues

---

## TASK-057: Add Log Rotation Configuration

**Priority**: 🟡 High
**Effort**: 1 hour

### Description

**Create**: `/etc/logrotate.d/nmapping`

```
/var/log/nmapping/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nmapping nmapping
    sharedscripts
    postrotate
        systemctl reload nmapping-dashboard.service >/dev/null 2>&1 || true
    endscript
}
```

---

## TASK-058: Test Service Reliability

**Priority**: 🔴 Critical
**Effort**: 3 hours

### Description

Test suite for service reliability.

Test scenarios:
- Service starts successfully
- Service auto-restarts on failure
- Timer triggers scans correctly
- Log rotation works
- Resource limits enforced
- Health checks prevent bad starts

---

## Phase 6 Completion Checklist

- [ ] TASK-050: Dashboard service created
- [ ] TASK-051: Scanner service created
- [ ] TASK-052: Scanner timer configured
- [ ] TASK-053: Installation script working
- [ ] TASK-054: Health checks implemented
- [ ] TASK-055: Service monitoring added
- [ ] TASK-056: Documentation complete
- [ ] TASK-057: Log rotation configured
- [ ] TASK-058: Service tests passing

## Success Criteria

- ✅ Services start automatically on boot
- ✅ Services restart on failure
- ✅ Scanner runs on schedule
- ✅ Logs rotate properly
- ✅ Health checks prevent bad states
- ✅ Installation script tested on clean system
