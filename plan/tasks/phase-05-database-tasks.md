# Phase 5: Database Management - Detailed Tasks

**Phase**: 5 of 12
**Name**: Database Management
**Duration**: 3-4 days
**Effort**: 20-24 person-hours
**Dependencies**: Phase 1 (Foundation)

---

## Phase Overview

Implement proper database lifecycle management including migrations, backups, optimization, and operational procedures.

---

## TASK-041: Create Database Migration System

**Priority**: 🔴 Critical
**Effort**: 6 hours

### Description

Implement database migration framework for schema versioning and upgrades.

**Create**: `database/migration_manager.py`

```python
"""Database migration management for nMapping+."""

import sqlite3
from pathlib import Path
from typing import List, Tuple
import logging

logger = logging.getLogger(__name__)

class MigrationManager:
    """Manages database schema migrations."""
    
    def __init__(self, db_path: Path, migrations_dir: Path):
        self.db_path = Path(db_path)
        self.migrations_dir = Path(migrations_dir)
        self.conn = None
        
    def connect(self):
        """Connect to database."""
        self.conn = sqlite3.connect(str(self.db_path))
        self._ensure_migrations_table()
        
    def _ensure_migrations_table(self):
        """Create migrations tracking table if not exists."""
        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS schema_migrations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                version TEXT NOT NULL UNIQUE,
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                description TEXT
            )
        ''')
        self.conn.commit()
        
    def get_current_version(self) -> str:
        """Get current schema version."""
        cursor = self.conn.execute(
            'SELECT version FROM schema_migrations ORDER BY id DESC LIMIT 1'
        )
        result = cursor.fetchone()
        return result[0] if result else '000'
        
    def get_pending_migrations(self) -> List[Tuple[str, Path]]:
        """Get list of pending migration files."""
        current = self.get_current_version()
        pending = []
        
        for migration_file in sorted(self.migrations_dir.glob('*.sql')):
            version = migration_file.stem.split('_')[0]
            if version > current:
                pending.append((version, migration_file))
                
        return pending
        
    def apply_migration(self, version: str, migration_file: Path):
        """Apply a single migration."""
        logger.info(f"Applying migration {version}: {migration_file.name}")
        
        with open(migration_file, 'r') as f:
            sql = f.read()
            
        try:
            self.conn.executescript(sql)
            self.conn.execute(
                'INSERT INTO schema_migrations (version, description) VALUES (?, ?)',
                (version, migration_file.name)
            )
            self.conn.commit()
            logger.info(f"Migration {version} applied successfully")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Migration {version} failed: {e}")
            raise
            
    def migrate(self):
        """Apply all pending migrations."""
        pending = self.get_pending_migrations()
        
        if not pending:
            logger.info("No pending migrations")
            return
            
        logger.info(f"Found {len(pending)} pending migrations")
        
        for version, migration_file in pending:
            self.apply_migration(version, migration_file)
            
        logger.info("All migrations applied successfully")
```

---

## TASK-042: Create Initial Schema Migration

**Priority**: 🔴 Critical
**Effort**: 3 hours

### Description

Create initial database schema as a migration file.

**Create**: `database/migrations/001_initial_schema.sql`

Include:
- Devices table
- Services table
- Scan history table
- Indexes for performance
- Foreign key constraints

---

## TASK-043: Add Database Indexes Migration

**Priority**: 🔴 Critical
**Effort**: 2 hours

### Description

Create migration adding optimized indexes for common queries.

**Create**: `database/migrations/002_add_indexes.sql`

Indexes for:
- Device IP lookups
- Device type queries
- Last seen timestamps
- Service port lookups

---

## TASK-044: Implement Database Backup System

**Priority**: 🔴 Critical
**Effort**: 4 hours

### Description

Automated database backup with rotation.

**Create**: `scripts/backup_database.sh`

```bash
#!/bin/bash
# Database backup script for nMapping+

set -euo pipefail

DB_PATH="${DB_PATH:-/dashboard/data/dashboard.db}"
BACKUP_DIR="${BACKUP_DIR:-/dashboard/data/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/dashboard_${TIMESTAMP}.db"

# Backup database (using SQLite backup API)
sqlite3 "$DB_PATH" ".backup '$BACKUP_FILE'"

# Compress backup
gzip "$BACKUP_FILE"

# Remove old backups
find "$BACKUP_DIR" -name "dashboard_*.db.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
```

---

## TASK-045: Create Database Restore Procedure

**Priority**: 🟡 High
**Effort**: 3 hours

### Description

Procedure and script for restoring database from backup.

**Create**: `scripts/restore_database.sh`

Features:
- List available backups
- Validate backup integrity
- Restore from specified backup
- Verify restored database

---

## TASK-046: Implement Database Maintenance Scripts

**Priority**: 🟡 High
**Effort**: 3 hours

### Description

Scripts for routine database maintenance.

**Create**: `scripts/maintain_database.sh`

Tasks:
- VACUUM to reclaim space
- ANALYZE to update statistics
- Integrity check
- Index rebuild

---

## TASK-047: Add Database Monitoring

**Priority**: 🟡 High
**Effort**: 2 hours

### Description

Endpoints and metrics for database monitoring.

Metrics:
- Database size
- Table row counts
- Index usage statistics
- Query performance
- Connection pool stats

---

## TASK-048: Create Database Documentation

**Priority**: 🟡 High
**Effort**: 3 hours

### Description

**Create**: `docs/operations/database-management.md`

Include:
- Schema documentation
- Migration procedures
- Backup/restore procedures
- Maintenance schedule
- Troubleshooting guide

---

## TASK-049: Implement Database Testing

**Priority**: 🔴 Critical
**Effort**: 4 hours

### Description

Test suite for database operations.

Tests:
- Migration application
- Rollback scenarios
- Backup/restore
- Data integrity
- Performance benchmarks

---

## Phase 5 Completion Checklist

- [ ] TASK-041: Migration system implemented
- [ ] TASK-042: Initial schema migration created
- [ ] TASK-043: Indexes migration added
- [ ] TASK-044: Backup system working
- [ ] TASK-045: Restore procedure tested
- [ ] TASK-046: Maintenance scripts created
- [ ] TASK-047: Database monitoring added
- [ ] TASK-048: Documentation complete
- [ ] TASK-049: Database tests passing

## Success Criteria

- ✅ Migrations apply cleanly
- ✅ Backups complete in <30 seconds
- ✅ Restore verified successful
- ✅ Database maintenance automated
- ✅ Monitoring metrics available
