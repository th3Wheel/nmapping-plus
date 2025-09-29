# Database Architecture

This document describes the database design for nMapping+.

## Database Engine

- **SQLite** is used for its simplicity, reliability, and zero-configuration deployment in containerized environments.
- WAL (Write-Ahead Logging) mode is enabled for concurrency and performance.

## Schema Overview

- **Devices Table**: Stores discovered network devices (IP, MAC, hostname, OS, vendor, first/last seen, etc.)
- **Scans Table**: Records scan events (timestamp, scan type, targets, results summary)
- **Changes Table**: Tracks network changes (device added/removed/changed, diff details)
- **Users Table** (optional): For dashboard authentication (username, password hash, role)

## Example Schema (simplified)

```sql
CREATE TABLE devices (
    id INTEGER PRIMARY KEY,
    ip_address TEXT,
    mac_address TEXT,
    hostname TEXT,
    os TEXT,
    vendor TEXT,
    first_seen DATETIME,
    last_seen DATETIME
);

CREATE TABLE scans (
    id INTEGER PRIMARY KEY,
    scan_time DATETIME,
    scan_type TEXT,
    targets TEXT,
    summary TEXT
);

CREATE TABLE changes (
    id INTEGER PRIMARY KEY,
    change_time DATETIME,
    device_id INTEGER,
    change_type TEXT,
    details TEXT,
    FOREIGN KEY(device_id) REFERENCES devices(id)
);
```

## Best Practices

- Use indexes on IP, MAC, and timestamps for fast lookups.
- Regularly vacuum and optimize the database (see SQLite docs).
- For large-scale or multi-user deployments, consider migration to PostgreSQL.

## References

- [SQLite Documentation](https://sqlite.org/docs.html)
- [Flask-SQLAlchemy](https://flask-sqlalchemy.palletsprojects.com/)
- [Database Design for Network Monitoring](https://www.cacti.net/)
