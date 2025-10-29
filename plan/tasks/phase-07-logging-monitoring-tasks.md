# Phase 07: Logging & Monitoring Tasks

**Estimated Time**: 12-16 hours
**Dependencies**: Phases 1-6 complete, database schema, API endpoints

---

## Overview

Implement robust logging and monitoring for all nMapping+ components. Ensure all critical events, errors, and metrics are captured, stored, and visualized. Integrate with Prometheus and Grafana for observability.

---

### TASK-059: Centralized Logging Framework

- Integrate Python `logging` module in all services (scanner, dashboard, sync)
- Log to file and stdout with rotation (use `logging.handlers.RotatingFileHandler`)
- Log format: timestamp, level, component, message, context
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Acceptance: All logs are consistent, rotated, and accessible

### TASK-060: Structured Log Events

- Use JSON log format for all logs (use `python-json-logger`)
- Include request IDs, user/session info, and error stack traces
- Acceptance: Logs are machine-parseable and human-readable

### TASK-061: Error & Exception Tracking

- Capture all unhandled exceptions and log with stack trace
- Integrate with Sentry (optional, config-driven)
- Acceptance: All errors are logged and traceable to root cause

### TASK-062: Audit Logging

- Log all device changes, scan triggers, and user actions
- Store audit logs in `device_changes` and `scan_history` tables
- Acceptance: Complete audit trail for compliance

### TASK-063: Prometheus Metrics Exporter

- Expose `/api/metrics` endpoint with Prometheus format
- Export device, scan, sync, and API request metrics
- Use `prometheus_client` Python library
- Acceptance: Metrics visible in Prometheus scrape

### TASK-064: Grafana Dashboard Integration

- Provide Grafana dashboard JSON for key metrics (devices, scans, errors, syncs)
- Document import steps in `docs/monitoring/grafana-dashboard.md`
- Acceptance: Dashboard visualizes live metrics

### TASK-065: Health & Liveness Probes

- Implement `/api/health` endpoint with component checks
- Add systemd `ExecStartPre` health check scripts
- Acceptance: Health checks pass in normal operation

### TASK-066: Log Retention & Archival

- Configure log rotation (30 days retention, compress old logs)
- Document archival/cleanup in `docs/maintenance/logging.md`
- Acceptance: No log files older than 30 days

### TASK-067: Alerting & Notifications

- Configure Prometheus Alertmanager for critical events (device offline, scan failures, sync errors)
- Document alert rules in `docs/monitoring/alerting.md`
- Acceptance: Alerts fire and notify on test events

### TASK-068: Monitoring Documentation

- Write `docs/monitoring/overview.md` covering logging, metrics, alerting, and troubleshooting
- Acceptance: Documentation is complete and accurate

### TASK-069: Logging & Monitoring Tests

- Write unit/integration tests for logging and metrics endpoints
- Simulate error conditions and verify logs/alerts
- Acceptance: All tests pass, coverage >90%

---

**Acceptance Criteria:**

- All logs are structured, rotated, and accessible
- Metrics are exported and visualized in Grafana
- Health checks and alerting are operational
- Documentation and tests are complete

---

**Owner**: Observability Team
**Review Date**: 2026-01-19
