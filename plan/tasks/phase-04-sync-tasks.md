# Phase 4: Scanner-Dashboard Synchronization - Detailed Tasks

**Phase**: 4 of 12
**Name**: Scanner-Dashboard Synchronization
**Duration**: 3-4 days
**Effort**: 20-24 person-hours
**Dependencies**: Phase 3 (Data Format)

---

## Phase Overview

Implement robust synchronization mechanism between scanner output and dashboard database, including file watching, git integration, and real-time updates.

---

## TASK-031: Implement File System Watcher

**Priority**: 🔴 Critical
**Effort**: 5 hours
**Dependencies**: TASK-025

### Description

Create file system watcher to monitor scanner output directory for changes.

### Implementation

**Create**: `src/sync/file_watcher.py`

```python
"""File system watcher for scanner output directory."""

import time
from pathlib import Path
from typing import Callable, Set
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileSystemEvent
import logging

logger = logging.getLogger(__name__)

class MarkdownFileHandler(FileSystemEventHandler):
    """Handler for markdown file change events."""
    
    def __init__(self, on_change_callback: Callable):
        self.on_change = on_change_callback
        self.debounce_time = 1.0  # seconds
        self.pending_files: Set[Path] = set()
        
    def on_modified(self, event: FileSystemEvent):
        if event.src_path.endswith('.md'):
            self.pending_files.add(Path(event.src_path))
            
    def on_created(self, event: FileSystemEvent):
        if event.src_path.endswith('.md'):
            self.pending_files.add(Path(event.src_path))
            
    def process_pending(self):
        """Process pending file changes after debounce."""
        if self.pending_files:
            files = list(self.pending_files)
            self.pending_files.clear()
            self.on_change(files)

class ScannerDataWatcher:
    """Watches scanner data directory for changes."""
    
    def __init__(self, watch_dir: Path, callback: Callable):
        self.watch_dir = Path(watch_dir)
        self.callback = callback
        self.observer = Observer()
        self.handler = MarkdownFileHandler(callback)
        
    def start(self):
        """Start watching directory."""
        self.observer.schedule(self.handler, str(self.watch_dir), recursive=True)
        self.observer.start()
        logger.info(f"Started watching {self.watch_dir}")
        
        # Debounce loop
        try:
            while True:
                time.sleep(1)
                self.handler.process_pending()
        except KeyboardInterrupt:
            self.stop()
            
    def stop(self):
        """Stop watching directory."""
        self.observer.stop()
        self.observer.join()
        logger.info("Stopped file watcher")
```

---

## TASK-032: Implement Git Change Detector

**Priority**: 🔴 Critical
**Effort**: 4 hours

### Description

Create module to detect changes via git commits and trigger synchronization.

**Create**: `src/sync/git_monitor.py`

Key features:
- Monitor git repository for new commits
- Extract changed files from commits
- Filter for device markdown files
- Trigger sync for changed files only

---

## TASK-033: Create Synchronization Manager

**Priority**: 🔴 Critical
**Effort**: 5 hours

### Description

Central manager coordinating file watching, git monitoring, and database updates.

**Create**: `src/sync/sync_manager.py`

Responsibilities:
- Coordinate file watcher and git monitor
- Queue changes for processing
- Trigger validation before sync
- Update database with validated data
- Handle sync errors and retries
- Emit WebSocket notifications

---

## TASK-034: Implement Database Update Logic

**Priority**: 🔴 Critical
**Effort**: 4 hours

### Description

Update database module to handle incremental updates from scanner data.

Features:
- Upsert device records (insert or update)
- Track last scan timestamp
- Maintain device history
- Handle deletions gracefully
- Transaction support for consistency

---

## TASK-035: Add WebSocket Notification System

**Priority**: 🟡 High
**Effort**: 3 hours

### Description

Implement WebSocket notifications for real-time dashboard updates.

Update `dashboard_app.py`:
- Emit events on device add/update/delete
- Send change notifications to connected clients
- Include change metadata in notifications

---

## TASK-036: Create Sync Configuration Module

**Priority**: 🟡 High
**Effort**: 2 hours

### Description

Configurable synchronization behavior.

**Create**: `src/sync/sync_config.py`

Options:
- Sync mode (auto/manual/scheduled)
- Sync interval
- Batch size
- Error retry policy
- Validation strictness

---

## TASK-037: Implement Sync Status Tracking

**Priority**: 🟢 Medium
**Effort**: 3 hours

### Description

Track synchronization status and history for monitoring.

Features:
- Last sync timestamp
- Sync success/failure counts
- Error logs
- Performance metrics
- Status API endpoint

---

## TASK-038: Add Manual Sync Trigger API

**Priority**: 🟢 Medium
**Effort**: 2 hours

### Description

API endpoint to trigger manual synchronization.

**Add to**: `dashboard_app.py`

```python
@app.route('/api/sync/trigger', methods=['POST'])
def trigger_sync():
    """Manually trigger data synchronization."""
    try:
        sync_manager.sync_all()
        return jsonify({'status': 'success', 'message': 'Sync triggered'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
```

---

## TASK-039: Create Sync Testing Framework

**Priority**: 🔴 Critical
**Effort**: 4 hours

### Description

Comprehensive tests for synchronization logic.

Test scenarios:
- File creation triggers sync
- File modification updates database
- Git commit triggers selective sync
- Multiple rapid changes handled correctly
- Sync errors handled gracefully
- WebSocket notifications sent

---

## TASK-040: Document Synchronization Architecture

**Priority**: 🟡 High
**Effort**: 2 hours

### Description

**Create**: `docs/architecture/synchronization.md`

Include:
- Architecture diagram
- Data flow
- Component interactions
- Configuration options
- Troubleshooting guide

---

## Phase 4 Completion Checklist

- [ ] TASK-031: File system watcher implemented
- [ ] TASK-032: Git change detector working
- [ ] TASK-033: Sync manager coordinating components
- [ ] TASK-034: Database update logic complete
- [ ] TASK-035: WebSocket notifications working
- [ ] TASK-036: Sync configuration module created
- [ ] TASK-037: Sync status tracking implemented
- [ ] TASK-038: Manual sync API added
- [ ] TASK-039: Sync tests passing
- [ ] TASK-040: Documentation complete

## Success Criteria

- ✅ File changes trigger database updates within 5 seconds
- ✅ WebSocket notifications received by clients
- ✅ Git commits trigger selective sync
- ✅ No data loss during sync
- ✅ >85% test coverage for sync module
