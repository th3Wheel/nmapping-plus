#!/bin/bash
# sync_dashboard.sh
# nMapping+ Data Synchronization Service
# Synchronizes data between Nmap scanner and dashboard containers

set -e

# ===== Configuration =====
DASHBOARD_DIR="/dashboard"
SCANNER_DATA_DIR="${DASHBOARD_DIR}/scanner_data"
SCANNER_REMOTE_URL=""  # Set this to your scanner LXC Git remote URL
DATABASE_PATH="${DASHBOARD_DIR}/data/dashboard.db"
LOG_FILE="${DASHBOARD_DIR}/sync.log"

# Project branding
PROJECT_NAME="nMapping+"
PROJECT_VERSION="1.0.0"

# ===== Logging =====
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$PROJECT_NAME] $1" | tee -a "$LOG_FILE"
}

log_header() {
    log "=========================================="
    log "$PROJECT_NAME v$PROJECT_VERSION - Data Sync"
    log "=========================================="
}

# ===== Git Sync =====
sync_git_data() {
    log "Starting Git data synchronization..."
    
    if [ ! -d "$SCANNER_DATA_DIR" ]; then
        log "Scanner data directory not found. Creating: $SCANNER_DATA_DIR"
        mkdir -p "$SCANNER_DATA_DIR"
        
        if [ -n "$SCANNER_REMOTE_URL" ]; then
            log "Cloning scanner repository from: $SCANNER_REMOTE_URL"
            git clone "$SCANNER_REMOTE_URL" "$SCANNER_DATA_DIR"
        else
            log "WARNING: SCANNER_REMOTE_URL not configured"
            log "Please configure the scanner repository URL in this script"
            return 1
        fi
    else
        log "Pulling latest changes from scanner repository..."
        cd "$SCANNER_DATA_DIR"
        
        # Check if we have a remote configured
        if ! git remote get-url origin >/dev/null 2>&1; then
            if [ -n "$SCANNER_REMOTE_URL" ]; then
                log "Adding remote origin: $SCANNER_REMOTE_URL"
                git remote add origin "$SCANNER_REMOTE_URL"
            else
                log "WARNING: No remote configured and SCANNER_REMOTE_URL not set"
                log "Please configure SCANNER_REMOTE_URL in this script"
                return 1
            fi
        fi
        
        # Fetch and pull changes
        log "Fetching latest changes..."
        git fetch origin
        
        # Try pulling from main or master branch
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            git pull origin main
        elif git show-ref --verify --quiet refs/remotes/origin/master; then
            git pull origin master
        else
            log "ERROR: No main or master branch found in remote repository"
            return 1
        fi
    fi
    
    log "Git synchronization completed successfully"
    return 0
}

# ===== Dashboard API Integration =====
trigger_dashboard_update() {
    log "Triggering dashboard update via API..."
    
    # Wait for dashboard service to be ready
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:5000/api/health" >/dev/null 2>&1; then
            log "Dashboard API is accessible"
            break
        else
            log "Waiting for dashboard API (attempt $attempt/$max_attempts)..."
            sleep 2
            attempt=$((attempt + 1))
        fi
    done
    
    # Call the dashboard refresh API
    if curl -s -X POST "http://localhost:5000/api/refresh" >/dev/null 2>&1; then
        log "Dashboard refresh triggered successfully via REST API"
    else
        log "WARNING: Could not trigger dashboard update via REST API"
    fi
    
    # Send WebSocket notification (if dashboard is running)
    python3 << 'EOF'
import socketio
import sys
import time

try:
    sio = socketio.SimpleClient()
    sio.connect('http://localhost:5000')
    sio.emit('refresh_request', {'source': 'sync_service', 'timestamp': time.time()})
    sio.disconnect()
    print("Dashboard update triggered via WebSocket")
except Exception as e:
    print(f"Could not trigger WebSocket update: {e}")
    # Don't exit with error - this is not critical
EOF
}

# ===== Change Detection =====
detect_changes() {
    log "Detecting changes since last synchronization..."
    
    cd "$SCANNER_DATA_DIR"
    
    # Get list of changed files since last sync
    if [ -f "${DASHBOARD_DIR}/.last_sync_commit" ]; then
        LAST_COMMIT=$(cat "${DASHBOARD_DIR}/.last_sync_commit")
        
        # Check if commit exists
        if git cat-file -e "$LAST_COMMIT" 2>/dev/null; then
            CHANGED_FILES=$(git diff --name-only "$LAST_COMMIT" HEAD)
            
            if [ -n "$CHANGED_FILES" ]; then
                log "Changes detected in files since commit $LAST_COMMIT:"
                echo "$CHANGED_FILES" | while read -r file; do
                    log "  - $file"
                done
                
                # Count different types of changes
                DEVICE_CHANGES=0
                SCAN_CHANGES=0

                while IFS= read -r changed_file; do
                    file_name="$(basename "$changed_file")"
                    case "$file_name" in
                        *_*.md)
                            SCAN_CHANGES=$((SCAN_CHANGES + 1))
                            ;;
                        *.md)
                            DEVICE_CHANGES=$((DEVICE_CHANGES + 1))
                            ;;
                    esac
                done <<< "$CHANGED_FILES"

                log "Summary: $DEVICE_CHANGES device files, $SCAN_CHANGES scan files changed"
            else
                log "No changes detected since last sync"
                return 1
            fi
        else
            log "WARNING: Last sync commit $LAST_COMMIT not found, treating as first sync"
        fi
    else
        log "First sync detected - processing all files"
    fi
    
    # Update last sync commit
    CURRENT_COMMIT=$(git rev-parse HEAD)
    echo "$CURRENT_COMMIT" > "${DASHBOARD_DIR}/.last_sync_commit"
    log "Updated last sync commit to: $CURRENT_COMMIT"
    
    return 0
}

# ===== Service Health Check =====
health_check() {
    log "Performing nMapping+ system health check..."
    
    # Check if dashboard service is running
    if ! systemctl is-active --quiet nmap-dashboard 2>/dev/null; then
        log "WARNING: nMapping+ dashboard service is not running"
        log "Attempting to start dashboard service..."
        
        if systemctl start nmap-dashboard 2>/dev/null; then
            log "Dashboard service started successfully"
            sleep 3  # Give service time to start
        else
            log "ERROR: Failed to start dashboard service"
            return 1
        fi
    else
        log "Dashboard service is running correctly"
    fi
    
    # Check if database is accessible
    if [ ! -f "$DATABASE_PATH" ]; then
        log "WARNING: Dashboard database not found at $DATABASE_PATH"
        log "Database will be created on first dashboard startup"
    else
        # Test database connection
        if sqlite3 "$DATABASE_PATH" "SELECT COUNT(*) FROM devices;" >/dev/null 2>&1; then
            DEVICE_COUNT=$(sqlite3 "$DATABASE_PATH" "SELECT COUNT(*) FROM devices;")
            log "Database accessible - $DEVICE_COUNT devices in database"
        else
            log "WARNING: Cannot query dashboard database (may be initializing)"
        fi
    fi
    
    # Check disk space
    DISK_USAGE=$(df "$DASHBOARD_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        log "WARNING: Disk usage is high: ${DISK_USAGE}%"
    else
        log "Disk usage is acceptable: ${DISK_USAGE}%"
    fi
    
    log "Health check completed"
    return 0
}

# ===== Statistics and Metrics =====
update_sync_statistics() {
    log "Updating synchronization statistics..."
    
    cd "$SCANNER_DATA_DIR"
    
    # Count files and gather statistics
    DEVICE_FILES=$(find . -name "*.md" -not -name "*_*" 2>/dev/null | wc -l)
    SCAN_FILES=$(find . -name "*_*.md" 2>/dev/null | wc -l)
    TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    REPO_SIZE=$(du -sh . 2>/dev/null | cut -f1 || echo "unknown")
    
    # Get Git repository information
    GIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    GIT_HASH_SHORT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    LAST_COMMIT_DATE=$(git log -1 --format="%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
    
    # Create comprehensive statistics file
    cat > "${DASHBOARD_DIR}/sync_stats.json" << EOF
{
    "project": "$PROJECT_NAME",
    "version": "$PROJECT_VERSION",
    "last_sync": "$(date -Iseconds)",
    "scanner_stats": {
        "device_files": $DEVICE_FILES,
        "scan_files": $SCAN_FILES,
        "total_commits": $TOTAL_COMMITS,
        "repository_size": "$REPO_SIZE",
        "last_commit_date": "$LAST_COMMIT_DATE"
    },
    "git_info": {
        "current_hash": "$GIT_HASH",
        "short_hash": "$GIT_HASH_SHORT",
        "remote_url": "$(git remote get-url origin 2>/dev/null || echo 'not configured')"
    },
    "sync_status": "success",
    "dashboard_url": "http://$(hostname -I | awk '{print $1}'):5000"
}
EOF
    
    log "Statistics updated:"
    log "  - Device files: $DEVICE_FILES"
    log "  - Scan files: $SCAN_FILES" 
    log "  - Total commits: $TOTAL_COMMITS"
    log "  - Repository size: $REPO_SIZE"
    log "  - Current commit: $GIT_HASH_SHORT"
}

# ===== Error Handling =====
handle_error() {
    local exit_code=$1
    local line_number=$2
    
    log "ERROR: nMapping+ sync failed at line $line_number with exit code $exit_code"
    
    # Create error statistics
    cat > "${DASHBOARD_DIR}/sync_stats.json" << EOF
{
    "project": "$PROJECT_NAME",
    "version": "$PROJECT_VERSION", 
    "last_sync": "$(date -Iseconds)",
    "sync_status": "error",
    "error_code": $exit_code,
    "error_line": $line_number,
    "error_message": "Sync process failed during execution"
}
EOF
    
    # Send notification if configured
    if command -v curl >/dev/null && [ -n "${NTFY_TOPIC:-}" ]; then
        curl -s -d "nMapping+ dashboard sync failed with error $exit_code at line $line_number" \
             "https://ntfy.sh/${NTFY_TOPIC}" || true
    fi
    
    log "Error statistics saved to sync_stats.json"
    exit "$exit_code"
}

# ===== Configuration Validation =====
validate_configuration() {
    log "Validating nMapping+ configuration..."
    
    # Check required directories
    if [ ! -d "$DASHBOARD_DIR" ]; then
        log "ERROR: Dashboard directory not found: $DASHBOARD_DIR"
        return 1
    fi
    
    # Check scanner URL configuration
    if [ -z "$SCANNER_REMOTE_URL" ] && [ ! -f "${DASHBOARD_DIR}/.scanner_url_configured" ]; then
        log "ERROR: Scanner remote URL not configured"
        log "Please edit this script and set SCANNER_REMOTE_URL"
        log "Example: SCANNER_REMOTE_URL='user@scanner-lxc:/nmap/registry'"
        log "After configuration: touch ${DASHBOARD_DIR}/.scanner_url_configured"
        return 1
    fi
    
    # Check if we have git installed
    if ! command -v git >/dev/null; then
        log "ERROR: Git is not installed"
        return 1
    fi
    
    # Check if we have curl for API calls
    if ! command -v curl >/dev/null; then
        log "WARNING: curl not found - API calls will be skipped"
    fi
    
    log "Configuration validation completed"
    return 0
}

# ===== Main Execution =====
main() {
    log_header
    
    # Set error handler with line number
    trap 'handle_error $? $LINENO' ERR
    
    # Change to dashboard directory
    cd "$DASHBOARD_DIR" || {
        echo "ERROR: Cannot access dashboard directory: $DASHBOARD_DIR"
        exit 1
    }
    
    # Validate configuration
    validate_configuration || exit 1
    
    # Perform system health check
    health_check || exit 1
    
    # Sync Git data from scanner
    sync_git_data || exit 1
    
    # Detect and process changes
    if detect_changes; then
        log "Changes detected - triggering dashboard update..."
        trigger_dashboard_update
        update_sync_statistics
        log "Dashboard update process completed"
    else
        log "No changes detected - updating statistics only"
        update_sync_statistics
    fi
    
    log "=========================================="
    log "nMapping+ sync completed successfully"
    log "Dashboard available at: http://$(hostname -I | awk '{print $1}'):5000"
    log "=========================================="
}

# ===== Usage Information =====
show_usage() {
    cat << EOF
$PROJECT_NAME Data Synchronization Service v$PROJECT_VERSION

Usage: $0 [options]

Options:
    -h, --help          Show this help message
    -v, --version       Show version information
    -c, --config        Show current configuration
    --test-connection   Test connection to scanner repository
    --force-sync        Force full synchronization (ignore last sync commit)

Configuration:
    Edit SCANNER_REMOTE_URL in this script to set your scanner LXC Git repository.
    Example: SCANNER_REMOTE_URL='user@scanner-lxc:/nmap/registry'

Files:
    $LOG_FILE                     - Sync log file
    ${DASHBOARD_DIR}/sync_stats.json           - Sync statistics
    ${DASHBOARD_DIR}/.last_sync_commit         - Last processed commit hash

EOF
}

# ===== Command Line Processing =====
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -v|--version)
        echo "$PROJECT_NAME v$PROJECT_VERSION"
        exit 0
        ;;
    -c|--config)
        echo "Configuration:"
        echo "  Dashboard Directory: $DASHBOARD_DIR"
        echo "  Scanner Data Directory: $SCANNER_DATA_DIR"
        echo "  Scanner Remote URL: ${SCANNER_REMOTE_URL:-'NOT CONFIGURED'}"
        echo "  Database Path: $DATABASE_PATH"
        echo "  Log File: $LOG_FILE"
        exit 0
        ;;
    --test-connection)
        log "Testing connection to scanner repository..."
        if [ -n "$SCANNER_REMOTE_URL" ]; then
            if git ls-remote "$SCANNER_REMOTE_URL" >/dev/null; then
                log "SUCCESS: Connection to scanner repository successful"
            else
                log "ERROR: Cannot connect to scanner repository"
                exit 1
            fi
        else
            log "ERROR: SCANNER_REMOTE_URL not configured"
            exit 1
        fi
        exit 0
        ;;
    --force-sync)
        log "Forcing full synchronization..."
        rm -f "${DASHBOARD_DIR}/.last_sync_commit"
        ;;
esac

# Execute main function
main "$@"