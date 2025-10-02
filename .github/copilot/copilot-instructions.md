# GitHub Copilot Instructions for nMapping+

## Priority Guidelines

When generating code for this repository:

1. **Version Compatibility**: Always detect and respect the exact versions of languages, frameworks, and libraries used in this project
   - Node.js: >=14.0.0
   - Python: >=3.9.0
   - Use only language features compatible with these versions
   - Never use newer language features not available in the detected versions

2. **Context Files**: Prioritize patterns and standards defined in the .github/copilot directory

3. **Codebase Patterns**: When context files don't provide specific guidance, scan the codebase for established patterns

4. **Architectural Consistency**: Maintain the dual-container architecture (scanner and dashboard) and established boundaries

5. **Code Quality**: Prioritize maintainability, performance, security, accessibility, and testability in all generated code

## Technology Version Detection

Before generating code, scan the codebase to identify:

1. **Language Versions**:
   - Examine package.json, requirements.txt, and configuration files
   - Look for language-specific version indicators
   - Never use language features beyond the detected version

2. **Framework Versions**:
   - Check package.json, requirements.txt, setup.py, etc.
   - Respect version constraints when generating code
   - Never suggest features not available in the detected framework versions

3. **Library Versions**:
   - Generate code compatible with these specific versions
   - Never use APIs or features not available in the detected versions

## Context Files

Prioritize the following files in .github/copilot directory (if they exist):

- **architecture.md**: System architecture guidelines
- **tech-stack.md**: Technology versions and framework details
- **coding-standards.md**: Code style and formatting standards
- **folder-structure.md**: Project organization guidelines
- **exemplars.md**: Exemplary code patterns to follow

## Codebase Scanning Instructions

When context files don't provide specific guidance:

1. Identify similar files to the one being modified or created
2. Analyze patterns for:
   - Naming conventions
   - Code organization
   - Error handling
   - Logging approaches
   - Documentation style
   - Testing patterns

3. Follow the most consistent patterns found in the codebase
4. When conflicting patterns exist, prioritize patterns in newer files or files with higher test coverage
5. Never introduce patterns not found in the existing codebase

## Code Quality Standards

### Maintainability
- Write self-documenting code with clear naming
- Follow the naming and organization conventions evident in the codebase
- Follow established patterns for consistency
- Keep functions focused on single responsibilities
- Limit function complexity and length to match existing patterns

### Performance
- Follow existing patterns for memory and resource management
- Match existing patterns for handling computationally expensive operations
- Follow established patterns for asynchronous operations
- Apply caching consistently with existing patterns
- Optimize according to patterns evident in the codebase

### Security
- Follow existing patterns for input validation
- Apply the same sanitization techniques used in the codebase
- Use parameterized queries matching existing patterns
- Follow established authentication and authorization patterns
- Handle sensitive data according to existing patterns

### Accessibility
- Follow existing accessibility patterns in the codebase
- Match ARIA attribute usage with existing components
- Maintain keyboard navigation support consistent with existing code
- Follow established patterns for color and contrast
- Apply text alternative patterns consistent with the codebase

### Testability
- Follow established patterns for testable code
- Match dependency injection approaches used in the codebase
- Apply the same patterns for managing dependencies
- Follow established mocking and test double patterns
- Match the testing style used in existing tests

## Documentation Requirements

- Follow the exact documentation format found in the codebase
- Match the XML/JSDoc style and completeness of existing comments
- Document parameters, returns, and exceptions in the same style
- Follow existing patterns for usage examples
- Match class-level documentation style and content

## Testing Approach

### Unit Testing
- Match the exact structure and style of existing unit tests
- Follow the same naming conventions for test classes and methods
- Use the same assertion patterns found in existing tests
- Apply the same mocking approach used in the codebase
- Follow existing patterns for test isolation

### Integration Testing
- Follow the same integration test patterns found in the codebase
- Match existing patterns for test data setup and teardown
- Use the same approach for testing component interactions
- Follow existing patterns for verifying system behavior

### End-to-End Testing
- Match the existing E2E test structure and patterns
- Follow established patterns for UI testing
- Apply the same approach for verifying user journeys

### Test-Driven Development
- Follow TDD patterns evident in the codebase
- Match the progression of test cases seen in existing code
- Apply the same refactoring patterns after tests pass

### Behavior-Driven Development
- Match the existing Given-When-Then structure in tests
- Follow the same patterns for behavior descriptions
- Apply the same level of business focus in test cases

## Technology-Specific Guidelines

### Python Guidelines
- Detect and adhere to the specific Python version in use (>=3.9.0)
- Follow the same import organization found in existing modules
- Match type hinting approaches if used in the codebase
- Apply the same error handling patterns found in existing code
- Follow the same module organization patterns
- Use Flask patterns consistent with dashboard_app.py
- Follow SQLite database interaction patterns
- Match real-time update patterns as implemented in the codebase (e.g., WebSocket or other relevant technologies)

### JavaScript/TypeScript Guidelines
- Detect and adhere to the specific ECMAScript/TypeScript version in use
- Follow the same module import/export patterns found in the codebase
- Match TypeScript type definitions with existing patterns
- Use the same async patterns (promises, async/await) as existing code
- Follow error handling patterns from similar files

### Bash Guidelines
- Follow the same script structure found in existing bash scripts
- Match error handling patterns (set -euo pipefail)
- Use the same logging functions and color schemes
- Follow the same function naming and organization
- Apply the same security practices (proper permissions, user creation)

## Version Control Guidelines

- Follow Semantic Versioning patterns as applied in the codebase
- Match existing patterns for documenting breaking changes
- Follow the same approach for deprecation notices
- Use conventional commit format as enforced by commitlint
- Follow established patterns for changelog generation
- Ensure commit messages include a non-empty type (e.g., 'feat', 'fix') and subject to avoid validation errors like "subject may not be empty" or "type may not be empty"

## General Best Practices

- Follow naming conventions exactly as they appear in existing code
- Match code organization patterns from similar files
- Apply error handling consistent with existing patterns
- Follow the same approach to testing as seen in the codebase
- Match logging patterns from existing code
- Use the same approach to configuration as seen in the codebase

## Project-Specific Guidance

- Scan the codebase thoroughly before generating any code
- Respect existing architectural boundaries without exception
- Match the style and patterns of surrounding code
- When in doubt, prioritize consistency with existing code over external best practices
- Follow the dual-container architecture pattern (scanner + dashboard)
- Use Git-based change tracking patterns for network data
- Match WebSocket implementation patterns for real-time updates
- Follow SQLite database schema patterns
- Use markdown processing patterns consistent with the codebase

## nMapping+ Architecture Essentials

### Dual-Container Architecture
- **Scanner Container (LXC 201)**: Nmap scanning, Git repository storage, cron automation
- **Dashboard Container (LXC 202)**: Flask web app, SQLite cache, Nginx proxy, WebSocket server
- **Data Flow**: Scanner → Git commits → Dashboard pulls → SQLite cache → WebSocket updates
- **Never** mix scanner and dashboard functionality in single components

### Critical Patterns to Follow

#### Database Operations (`dashboard/dashboard_app.py`)
```python
# Always use connection context management
conn = self.get_db_connection()  # sqlite3.Row factory set
try:
    # Database operations
    results = conn.execute("SELECT * FROM devices").fetchall()
    conn.commit()
finally:
    conn.close()

# Use WAL mode for concurrent access
conn.execute("PRAGMA journal_mode=WAL")

# Indexed queries for performance
conn.execute("SELECT * FROM devices ORDER BY last_seen DESC, ip ASC")
```

#### WebSocket Real-time Updates
```python
# Server-side: Emit updates to all connected clients
socketio.emit('dashboard_update', data)

# Client-side: Receive real-time updates
socket.on('dashboard_update', function(data) {
    updateDashboard(data);
    updateLastUpdated();
});
```

#### Markdown Processing with Frontmatter
```python
import frontmatter
import re

# Parse device files with metadata
post = frontmatter.loads(content)
metadata = post.metadata
content = post.content

# Extract fields using regex patterns (from dashboard_app.py)
mac = self.extract_field(content, r'\*\*MAC:\*\*\s*(.+)')
vendor = self.extract_field(content, r'\*\*Vendor:\*\*\s*(.+)')
hostname = self.extract_field(content, r'\*\*Hostname:\*\*\s*(.+)')
first_seen = self.extract_field(content, r'\*\*First Seen:\*\*\s*(.+)')
last_seen = self.extract_field(content, r'\*\*Last Seen:\*\*\s*(.+)')

# Extract sections
os_info = self.extract_section(content, r'## OS & Services')
services = self.extract_services(content)
vulnerabilities = self.extract_section(content, r'## Vulnerabilities')
```

#### Git Synchronization Pattern
```python
# Pull latest changes from scanner repo (from dashboard_app.py)
def sync_from_scanner_data(self):
    if not os.path.exists(SCANNER_DATA_PATH):
        print(f"{PROJECT_NAME}: Scanner data path not found: {SCANNER_DATA_PATH}")
        return False
    
    try:
        # Pull latest changes
        subprocess.run(['git', 'pull'], cwd=SCANNER_DATA_PATH, check=True, capture_output=True)
        
        # Process markdown files
        self.process_device_files()
        self.process_scan_summaries()
        
        print(f"{PROJECT_NAME}: Data sync completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{PROJECT_NAME}: Git pull failed: {e}")
        return False
    except Exception as e:
        print(f"{PROJECT_NAME}: Error syncing data: {e}")
        return False
```

#### Error Handling & Logging Patterns
```python
# Consistent error logging with project prefix
PROJECT_NAME = "nMapping+"
PROJECT_VERSION = "1.0.0"

def log_error(message, error=None):
    """Standardized error logging"""
    if error:
        print(f"{PROJECT_NAME}: {message}: {error}")
    else:
        print(f"{PROJECT_NAME}: {message}")

# Try/catch with specific error types
try:
    # Risky operation (e.g., git pull, database query)
    result = subprocess.run(['git', 'pull'], check=True)
except subprocess.CalledProcessError as e:
    log_error("Git operation failed", e)
    return False
except FileNotFoundError as e:
    log_error("Required file not found", e)
    return False
except Exception as e:
    log_error("Unexpected error", e)
    return False
```

#### Device Status Determination Logic
```python
def determine_device_status(self, last_seen):
    """Determine device status based on last seen date"""
    if not last_seen:
        return 'unknown'
    
    try:
        # Handle different date formats
        for fmt in ['%Y-%m-%d', '%Y-%m-%d %H:%M:%S', '%d/%m/%Y', '%m/%d/%Y']:
            try:
                last_date = datetime.strptime(last_seen.split()[0], fmt)
                break
            except ValueError:
                continue
        else:
            return 'unknown'
        
        days_diff = (datetime.now() - last_date).days
        
        if days_diff == 0:
            return 'online'
        elif days_diff <= 1:
            return 'recently_seen'
        elif days_diff <= 7:
            return 'inactive'
        else:
            return 'offline'
    except Exception as e:
        log_error(f"Error parsing date '{last_seen}'", e)
        return 'unknown'
```

### Deployment Workflow Commands
```bash
# Full deployment (dual-container) - runs create_nmap_lxc.sh
npm run setup

# Individual components
npm run setup:scanner    # Runs scripts/install_nmap_fingplus.sh
npm run setup:dashboard  # Runs scripts/install_dashboard_enhanced.sh
npm run sync            # Runs scripts/sync_dashboard.sh

# Development
npm start               # python3 dashboard/dashboard_app.py
npm run build           # echo 'Build process placeholder'
npm run test:lint       # Linting checks

# Version management
npm run version:patch   # Semantic versioning
npm run changelog       # Generate changelog with conventional-changelog
```

### File Organization Patterns

#### Scripts Directory Structure
```
scripts/
├── create_nmap_lxc.sh              # Interactive LXC creation wizard
├── install_nmap_fingplus.sh        # Scanner component installation
├── install_dashboard_enhanced.sh   # Dashboard with community scripts
├── sync_dashboard.sh              # Git synchronization service
└── version-bump.ps1               # PowerShell version management
```

#### Dashboard Directory Structure
```
dashboard/
├── dashboard_app.py               # Main Flask application
├── templates/                     # Jinja2 HTML templates (if any)
├── static/                        # CSS, JS, images (if any)
└── requirements.txt               # Python dependencies
```

#### Documentation Structure
```
docs/
├── index.md                       # Documentation hub
├── deployment-guide.md           # Complete setup guide
├── quick-start.md                # 30-minute setup
├── architecture/
│   ├── overview.md               # System architecture
│   ├── database.md              # Database schema
│   ├── api.md                   # API documentation
│   └── containers.md            # Container patterns
├── configuration/
│   ├── dashboard.md             # Dashboard config
│   ├── scanner.md               # Scanner config
│   └── security.md              # Security settings
└── operations/
    ├── monitoring.md            # Monitoring setup
    ├── backup.md                # Backup procedures
    └── troubleshooting.md       # Issue resolution
```

### Key Integration Points

#### Proxmox VE Container Management
```bash
# Container creation (from create_nmap_lxc.sh)
pct create $CT_ID local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst \
    --hostname $HOSTNAME \
    --memory $MEMORY \
    --cores $CORES \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --storage local-lvm \
    --password $PASSWORD

# Container startup
pct start $CT_ID

# Execute commands in container
pct exec $CT_ID -- bash -c "apt update && apt upgrade -y"
```

#### Git Repository for Change Tracking
```bash
# Initialize scanner repository
git init /scanner-data
cd /scanner-data

# Configure for automated commits
git config user.name "nMapping+ Scanner"
git config user.email "scanner@nmapping-plus.local"

# Commit device changes
git add *.md
git commit -m "feat: update network scan results

- Added 3 new devices
- Updated 5 existing devices
- Detected 2 service changes"
```

#### SQLite Database Schema Patterns
```sql
-- Devices table (from dashboard_app.py)
CREATE TABLE IF NOT EXISTS devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT UNIQUE NOT NULL,
    mac TEXT,
    vendor TEXT,
    hostname TEXT,
    first_seen TEXT,
    last_seen TEXT,
    status TEXT DEFAULT 'unknown',
    os_info TEXT,
    services TEXT,
    vulnerabilities TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_devices_ip ON devices(ip);
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen);

-- Scans table for historical tracking
CREATE TABLE IF NOT EXISTS scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_type TEXT NOT NULL,           -- 'discovery', 'fingerprint', 'vuln'
    scan_date TEXT NOT NULL,
    devices_found INTEGER DEFAULT 0,
    new_devices INTEGER DEFAULT 0,
    scan_file TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(scan_type, scan_date)
);
```

#### WebSocket Real-time Communication
```python
# Flask-SocketIO setup
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# Background sync thread
def background_sync():
    while True:
        success = dashboard.sync_from_scanner_data()
        if success:
            data = dashboard.get_dashboard_data()
            socketio.emit('dashboard_update', data)  # Broadcast to all clients
        time.sleep(300)  # Sync every 5 minutes

# API endpoint to trigger manual refresh
@app.route('/api/refresh', methods=['POST', 'GET'])
def api_refresh():
    success = dashboard.sync_from_scanner_data()
    data = dashboard.get_dashboard_data()
    socketio.emit('dashboard_update', data)  # Real-time update
    return jsonify({'success': success})
```

### Development Environment Setup

#### Local Development Requirements
```bash
# Python environment (3.9+)
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install flask flask-socketio python-frontmatter

# For development database
# sqlite3 is included with Python (no pip install needed)

# For git operations
# git should be available in PATH
```

#### Testing the Dashboard Locally
```bash
# Start the dashboard
cd dashboard
python dashboard_app.py

# Dashboard will be available at:
# http://localhost:5000

# API endpoints:
# GET  /api/dashboard     # Get all dashboard data
# GET  /api/health        # Health check
# POST /api/refresh       # Manual data refresh
# GET  /api/device/<ip>   # Individual device details
# GET  /api/stats         # Dashboard statistics
```

### Common Development Workflows

#### Adding a New Device Field
1. **Update database schema** in `NetworkDashboard.init_database()`
2. **Add extraction logic** in `process_device_file()` method
3. **Update API response** in `get_dashboard_data()` method
4. **Update frontend** to display the new field
5. **Test with sample data** to ensure proper parsing

#### Adding a New Scan Type
1. **Update scanner script** to generate new markdown files
2. **Add processing logic** in `process_scan_summaries()` method
3. **Update database schema** if needed for new scan metadata
4. **Add to dashboard UI** for displaying new scan results
5. **Update API endpoints** to expose new scan data

#### Modifying Network Topology Visualization
1. **Update data processing** in `get_dashboard_data()` method
2. **Modify JavaScript** in dashboard HTML template
3. **Adjust Vis.js options** for new visualization requirements
4. **Test with various network sizes** (10, 100, 1000+ devices)
5. **Optimize performance** for large networks

### Code Quality Patterns

#### Function Organization
```python
class NetworkDashboard:
    def __init__(self):
        """Initialize dashboard with configuration"""
        self.db_path = DATABASE_PATH
        self.init_database()
    
    def get_db_connection(self):
        """Get database connection with proper configuration"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def sync_from_scanner_data(self):
        """Main synchronization method - calls subprocesses safely"""
        # Implementation with proper error handling
        pass
    
    def process_device_files(self):
        """Process all device markdown files"""
        # Batch processing logic
        pass
    
    def process_device_file(self, conn, ip, filepath):
        """Process individual device file with transaction"""
        # Individual file processing
        pass
```

#### Configuration Management
```python
# Configuration constants at module level
DASHBOARD_DIR = '/dashboard'
DATABASE_PATH = os.path.join(DASHBOARD_DIR, 'data', 'dashboard.db')
SCANNER_DATA_PATH = os.path.join(DASHBOARD_DIR, 'scanner_data')

# Project information
PROJECT_NAME = "nMapping+"
PROJECT_VERSION = "1.0.0"
PROJECT_DESCRIPTION = "Self-hosted network mapping with real-time web dashboard"
```

#### Logging and Debugging
```python
# Enable debug mode for development
if __name__ == '__main__':
    # Debug logging
    import logging
    logging.basicConfig(level=logging.DEBUG)
    
    # Start with debug enabled
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
```

### Security Patterns

#### Input Validation
```python
def validate_ip_address(ip):
    """Validate IP address format"""
    import ipaddress
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False

def sanitize_filename(filename):
    """Sanitize filenames to prevent path traversal"""
    import os
    return os.path.basename(filename)
```

#### Container Security
```bash
# From installation scripts - security hardening
# Set proper permissions
chown -R nmapping:nmapping /dashboard
chmod 755 /dashboard
chmod 644 /dashboard/data/dashboard.db

# Firewall configuration
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### Performance Optimization Patterns

#### Database Query Optimization
```python
# Use indexes for common queries
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen);
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);

# Batch operations
def bulk_insert_devices(self, devices):
    """Bulk insert multiple devices efficiently"""
    conn = self.get_db_connection()
    try:
        conn.executemany('''
            INSERT OR REPLACE INTO devices 
            (ip, mac, vendor, hostname, last_seen, status)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', devices)
        conn.commit()
    finally:
        conn.close()
```

#### Memory Management
```python
# Process large files in chunks
def process_large_file(filepath):
    """Process large files without loading entirely into memory"""
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            # Process line by line
            process_line(line)
```

#### Caching Strategies
```python
# Cache frequently accessed data
@lru_cache(maxsize=128)
def get_device_stats():
    """Cache device statistics to reduce database queries"""
    # Implementation
    pass

# Clear cache when data changes
def invalidate_cache():
    """Clear caches after data updates"""
    get_device_stats.cache_clear()
```

### Testing Patterns

#### Unit Test Structure
```python
import unittest
from unittest.mock import patch, MagicMock

class TestNetworkDashboard(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures"""
        self.dashboard = NetworkDashboard()
    
    def test_device_status_determination(self):
        """Test device status logic"""
        # Test cases for different date scenarios
        from datetime import datetime, timedelta
        from datetime import datetime
        today_str = datetime.now().strftime("%Y-%m-%d")
        self.assertEqual(self.dashboard.determine_device_status(today_str), "online")
        self.assertEqual(self.dashboard.determine_device_status(old_date), "offline")
        self.assertEqual(self.dashboard.determine_device_status("2025-12-31"), "online")
    
    @patch('subprocess.run')
    def test_git_sync_success(self, mock_subprocess):
        """Test successful git synchronization"""
        mock_subprocess.return_value = MagicMock(returncode=0)
        result = self.dashboard.sync_from_scanner_data()
        self.assertTrue(result)
    
    @patch('subprocess.run')
    def test_git_sync_failure(self, mock_subprocess):
        """Test git synchronization failure handling"""
        mock_subprocess.side_effect = subprocess.CalledProcessError(1, 'git')
        result = self.dashboard.sync_from_scanner_data()
        self.assertFalse(result)
```

#### Integration Test Patterns
```python
def test_full_data_flow(self):
    """Test complete data flow from scanner to dashboard"""
    # 1. Create mock scanner data
    # 2. Run sync process
    # 3. Verify database updates
    # 4. Check API responses
    # 5. Validate WebSocket emissions
    pass
```

### Deployment Validation

#### Health Checks
```bash
# Container health check
#!/bin/bash
# Check if services are running
if pgrep -f "python.*dashboard_app.py" > /dev/null; then
    echo "Dashboard service is running"
    exit 0
else
    echo "Dashboard service is not running"
    exit 1
fi
```

#### Configuration Validation
```python
def validate_configuration():
    """Validate all required configuration before startup"""
    required_paths = [
        DASHBOARD_DIR,
        os.path.dirname(DATABASE_PATH),
        SCANNER_DATA_PATH
    ]
    
    for path in required_paths:
        if not os.path.exists(path):
            raise ConfigurationError(f"Required path does not exist: {path}")
    
    # Validate database connectivity
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        conn.close()
    except sqlite3.Error as e:
        raise ConfigurationError(f"Database connection failed: {e}")
```

This detailed guidance should enable AI agents to be immediately productive with nMapping+, understanding not just what to do but how to do it following established patterns and best practices.

## Copilot PR Summary Instructions

When asked to generate a pull request summary, use the file .github/pull_request_template.md as the authoritative template and produce a completed PR description that fills the template's sections.

Rules:
- Read .github/pull_request_template.md and follow its section headings exactly.
- Produce a concise "Summary" (3–5 sentences) that explains what changed and why.
- For "Type of Change", mark the most relevant checkbox(es) and leave others unchecked.
- Under "Related Issues" include issue references using the form "Fixes #NNN" or "Relates to #NNN" where applicable.
- In "Changes Made":
  - Fill "Components Modified" by checking the items that apply.
  - Provide a "Detailed Changes" bullet list describing the code-level changes; include file paths for key changes (short, relative paths).
- In "Testing Performed":
  - Provide environment details if known or mark them "N/A".
  - Check the test scenario checkboxes that were validated.
  - Give short test results describing success/failures and any follow-up needed.
- For any section that does not apply, write "N/A" rather than leaving it blank.
- Include "Documentation Updates", "Security Considerations", "Performance Impact", and "Breaking Changes" with concrete notes or "N/A".
- In "Checklist" ensure important developer checks are either checked or explicitly noted as not applicable.
- Add reviewer guidance under "Review Requests" with specific areas to focus on (2–3 items) and any direct questions for reviewers.
- When possible, suggest labels and a small list of likely reviewers (use contributors mentioned in the changed files or OWNERS file; if unknown, omit suggestions).

Formatting guidelines:
- Use the same Markdown structure and checkboxes as in pull_request_template.md.
- Use bullet lists for readability.
- Keep the total PR description professional, clear, and under ~500 words when possible while still filling required sections.
- Do not invent test runs or claim tests passed unless evidence is provided in the PR context.

Behavior trigger:
- When the user asks "generate PR summary", "write PR description", "create pull request body", or similar, produce the filled template automatically using the rules above.
