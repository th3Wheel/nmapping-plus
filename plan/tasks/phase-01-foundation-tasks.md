# Phase 1: Foundation & Core Dependencies - Detailed Task Specifications

**Parent Plan**: [feature-nmapping-implementation-1.md](../feature-nmapping-implementation-1.md)  
**Phase Goal**: Establish dependency management, configuration system, and development environment setup  
**Priority**: 🔴 Critical - Blocks all other implementation work  
**Estimated Duration**: 3-4 days

---

## TASK-001: Create requirements.txt with Pinned Versions

### TASK-001: Description

Create a comprehensive `requirements.txt` file with all production dependencies pinned to specific versions for reproducible installations.

### TASK-001: Acceptance Criteria

* [ ] File created at project root: `requirements.txt`
* [ ] All dependencies have exact version pins (==X.Y.Z)
* [ ] Dependencies organized by category with comments
* [ ] No dependency conflicts exist
* [ ] Installation succeeds on clean Ubuntu 22.04 environment

### TASK-001: Implementation Details

**File Location**: `i:\obsidian\Homelab Vault\nMapping+\requirements.txt`

**Content Structure**:

```txt
# Web Framework
Flask==3.0.0
Flask-SocketIO==5.3.5
python-socketio==5.10.0

# Data Processing
markdown==3.5.1
python-frontmatter==1.0.1

# Production Server
gunicorn==21.2.0
eventlet==0.33.3

# Utilities
python-dotenv==1.0.0
PyYAML==6.0.1
jsonschema==4.20.0
```

### TASK-001: Testing Steps

1. Create fresh Python virtual environment: `python3 -m venv test_env`
2. Activate environment: `source test_env/bin/activate`
3. Install requirements: `pip install -r requirements.txt`
4. Verify no errors or conflicts
5. Test import of all packages in Python REPL

### TASK-001: Dependencies

* None (foundational task)

### TASK-001: Estimated Time

1 hour

---

## TASK-002: Create requirements-dev.txt with Development Dependencies

### TASK-002: Description

Create development dependencies file with testing, linting, and development tools.

### TASK-002: Acceptance Criteria

* [ ] File created at project root: `requirements-dev.txt`
* [ ] Includes pytest and coverage tools
* [ ] Includes linting tools (black, flake8, pylint, mypy)
* [ ] Includes development utilities
* [ ] No conflicts with requirements.txt

### TASK-002: Implementation Details

**File Location**: `i:\obsidian\Homelab Vault\nMapping+\requirements-dev.txt`

**Content Structure**:

```txt
# Include production requirements
-r requirements.txt

# Testing Framework
pytest==7.4.3
pytest-cov==4.1.0
pytest-flask==1.3.0
pytest-mock==3.12.0

# Code Quality
black==23.12.0
flake8==6.1.0
pylint==3.0.3
mypy==1.7.1

# Testing Utilities
faker==20.1.0
responses==0.24.1
freezegun==1.4.0

# Development Tools
ipython==8.18.1
ipdb==0.13.13
```

### TASK-002: Testing Steps

1. Install dev requirements: `pip install -r requirements-dev.txt`
2. Run `pytest --version` to verify installation
3. Run `black --version`
4. Run `flake8 --version`
5. Run `mypy --version`

### TASK-002: Dependencies

* TASK-001 must be completed first

### TASK-002: Estimated Time

30 minutes

---

## TASK-003: Create pyproject.toml with Package Metadata

### TASK-003: Description

Create modern Python package configuration file with build system, metadata, and tool configurations.

### TASK-003: Acceptance Criteria

* [ ] File created at project root: `pyproject.toml`
* [ ] Contains package metadata (name, version, description, authors)
* [ ] Defines build system (setuptools)
* [ ] Includes tool configurations (black, pytest, mypy)
* [ ] Defines entry points for CLI commands

### TASK-003: Implementation Details

**File Location**: `i:\obsidian\Homelab Vault\nMapping+\pyproject.toml`

**Content Structure**:

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "nmapping-plus"
version = "1.0.0"
description = "Self-hosted network mapping and monitoring with real-time dashboard"
authors = [
    {name = "Development Team", email = "dev@example.com"}
]
requires-python = ">=3.9"
license = {text = "MIT"}
readme = "README.md"
keywords = ["network", "mapping", "nmap", "monitoring", "dashboard"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: System Administrators",
    "Topic :: System :: Networking :: Monitoring",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.3",
    "pytest-cov>=4.1.0",
    "black>=23.12.0",
    "flake8>=6.1.0",
    "pylint>=3.0.3",
]

[project.scripts]
nmapping-scanner = "scripts.nmap_scanner:main"
nmapping-dashboard = "dashboard.dashboard_app:main"

[tool.black]
line-length = 100
target-version = ["py39", "py310", "py311"]
include = '\.pyi?$'
extend-exclude = '''
/(
  \.git
  | \.venv
  | build
  | dist
)/
'''

[tool.pytest.ini_options]
minversion = "7.0"
addopts = "-ra -q --strict-markers --cov=dashboard --cov=scripts --cov-report=html --cov-report=term"
testpaths = ["tests"]
python_files = "test_*.py"
python_classes = "Test*"
python_functions = "test_*"

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

### TASK-003: Testing Steps

1. Validate TOML syntax: `python -c "import tomllib; tomllib.load(open(''pyproject.toml'', ''rb'))"`
2. Install package in editable mode: `pip install -e .`
3. Verify entry points are created: `which nmapping-scanner`
4. Test black configuration: `black --check dashboard/`

### TASK-003: Dependencies

* TASK-001 and TASK-002

### TASK-003: Estimated Time

1 hour

---

## TASK-005: Create .env.example Template

### TASK-005: Description

Create comprehensive environment variable template with all configuration options documented.

### TASK-005: Acceptance Criteria

* [ ] File created at project root: `.env.example`
* [ ] All required variables documented
* [ ] All optional variables documented
* [ ] Each variable has description comment
* [ ] Example values provided
* [ ] Security-sensitive values use placeholder text

### TASK-005: Implementation Details

**File Location**: `i:\obsidian\Homelab Vault\nMapping+\.env.example`

**Content** (200+ lines with comprehensive documentation):

```bash
# nMapping+ Environment Configuration Template
# Copy this file to .env and customize for your environment

# =============================================================================
# APPLICATION SETTINGS
# =============================================================================

# Application name (displayed in UI)
APP_NAME=nMapping+

# Application version
APP_VERSION=1.0.0

# Flask environment: development, testing, or production
FLASK_ENV=production

# Secret key for session encryption (CHANGE THIS!)
# Generate with: python -c "import secrets; print(secrets.token_hex(32))"
SECRET_KEY=change-this-to-a-random-secret-key-min-32-chars

# Debug mode (should be false in production)
DEBUG=false

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

# SQLite database file path
DATABASE_PATH=/dashboard/data/dashboard.db

# Enable WAL mode for better concurrent access
SQLITE_WAL_MODE=true

# Database connection timeout (seconds)
DATABASE_TIMEOUT=30

# =============================================================================
# SCANNER CONFIGURATION
# =============================================================================

# Path to scanner data repository (Git repository with markdown files)
SCANNER_DATA_PATH=/dashboard/scanner_data

# Scan interval in seconds (3600 = 1 hour)
SCAN_INTERVAL=3600

# Enable automatic Git synchronization
GIT_SYNC_ENABLED=true

# Git remote URL (optional, for pushing to remote repository)
GIT_REMOTE_URL=

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

# Dashboard web server bind address (0.0.0.0 = all interfaces)
DASHBOARD_HOST=0.0.0.0

# Dashboard web server port
DASHBOARD_PORT=5000

# WebSocket CORS allowed origins (* = all, comma-separated list for specific)
CORS_ORIGINS=*

# Number of gunicorn worker processes
WORKERS=4

# Worker class for async support
WORKER_CLASS=eventlet

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# Logging level: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL=INFO

# Log file path
LOG_FILE=/var/log/nmapping/dashboard.log

# Maximum log file size in bytes (10485760 = 10MB)
LOG_MAX_BYTES=10485760

# Number of log backup files to keep
LOG_BACKUP_COUNT=5

# Log format: json or text
LOG_FORMAT=json

# =============================================================================
# SECURITY SETTINGS
# =============================================================================

# Enable rate limiting
RATE_LIMIT_ENABLED=true

# Rate limit: requests per minute per IP
RATE_LIMIT_PER_MINUTE=60

# Session timeout in seconds (3600 = 1 hour)
SESSION_TIMEOUT=3600

# Enable HTTPS redirect (requires reverse proxy with SSL)
FORCE_HTTPS=false

# Content Security Policy header
CSP_POLICY=default-src ''self''; script-src ''self'' ''unsafe-inline''; style-src ''self'' ''unsafe-inline''

# =============================================================================
# GIT CONFIGURATION
# =============================================================================

# Git user name for commits
GIT_USER_NAME=nMapping+ Scanner

# Git user email for commits
GIT_USER_EMAIL=scanner@nmapping.local

# Enable automatic commits after scans
GIT_COMMIT_ENABLED=true

# Git commit message template
GIT_COMMIT_MESSAGE_TEMPLATE=Automated scan: {timestamp}

# =============================================================================
# MONITORING & METRICS
# =============================================================================

# Enable Prometheus metrics endpoint (/api/metrics)
METRICS_ENABLED=true

# Health check endpoint port (separate from main app)
HEALTH_CHECK_PORT=5001

# Enable detailed health checks
HEALTH_CHECK_DETAILED=true

# =============================================================================
# FEATURE FLAGS
# =============================================================================

# Enable authentication (requires additional setup)
AUTH_ENABLED=false

# Enable vulnerability scanning (requires additional tools)
VULN_SCAN_ENABLED=false

# Enable historical data tracking
HISTORICAL_DATA_ENABLED=true

# Data retention period in days (0 = unlimited)
DATA_RETENTION_DAYS=90

# =============================================================================
# ADVANCED SETTINGS
# =============================================================================

# Maximum devices to display per page
MAX_DEVICES_PER_PAGE=100

# WebSocket ping interval (seconds)
WEBSOCKET_PING_INTERVAL=25

# WebSocket ping timeout (seconds)
WEBSOCKET_PING_TIMEOUT=10

# Cache timeout for device data (seconds)
CACHE_TIMEOUT=300

# Enable async mode for better performance
ASYNC_MODE=eventlet
```

### TASK-005: Testing Steps

1. Copy file: `cp .env.example .env`
2. Modify `.env` with actual values
3. Test configuration loading in Python
4. Verify all variables are properly documented

### TASK-005: Dependencies

* None

### TASK-005: Estimated Time

2 hours

---

## TASK-008: Implement Configuration Loader in dashboard_app.py

### TASK-008: Description

Add configuration management system to `dashboard_app.py` that loads settings from environment variables and YAML files with proper precedence and validation.

### TASK-008: Acceptance Criteria

* [ ] Configuration class created (Config, DevelopmentConfig, ProductionConfig)
* [ ] Environment variables loaded via python-dotenv
* [ ] YAML configuration file support added
* [ ] Configuration precedence: env vars > YAML > defaults
* [ ] Type conversion for boolean/integer values
* [ ] Configuration validation on app startup

### TASK-008: Implementation Details

**File to Modify**: `dashboard/dashboard_app.py`

**Add Configuration Class** (before NetworkDashboard class):

```python
import os
from pathlib import Path
from dotenv import load_dotenv
import yaml

class Config:
    """Base configuration class with defaults"""
    
    def __init__(self):
        # Load .env file if it exists
        load_dotenv()
        
        # Application Settings
        self.APP_NAME = os.getenv(''APP_NAME'', ''nMapping+'')
        self.APP_VERSION = os.getenv(''APP_VERSION'', ''1.0.0'')
        self.SECRET_KEY = os.getenv(''SECRET_KEY'')
        self.DEBUG = self._get_bool(''DEBUG'', False)
        
        # Database Configuration
        self.DATABASE_PATH = Path(os.getenv(''DATABASE_PATH'', ''/dashboard/data/dashboard.db''))
        self.SQLITE_WAL_MODE = self._get_bool(''SQLITE_WAL_MODE'', True)
        
        # Scanner Configuration
        self.SCANNER_DATA_PATH = Path(os.getenv(''SCANNER_DATA_PATH'', ''/dashboard/scanner_data''))
        self.SCAN_INTERVAL = self._get_int(''SCAN_INTERVAL'', 3600)
        
        # Network Configuration
        self.DASHBOARD_HOST = os.getenv(''DASHBOARD_HOST'', ''0.0.0.0'')
        self.DASHBOARD_PORT = self._get_int(''DASHBOARD_PORT'', 5000)
        self.CORS_ORIGINS = os.getenv(''CORS_ORIGINS'', ''*'')
        
        # Logging Configuration
        self.LOG_LEVEL = os.getenv(''LOG_LEVEL'', ''INFO'')
        self.LOG_FILE = os.getenv(''LOG_FILE'', ''/var/log/nmapping/dashboard.log'')
        self.LOG_FORMAT = os.getenv(''LOG_FORMAT'', ''json'')
        
        # Security Settings
        self.RATE_LIMIT_ENABLED = self._get_bool(''RATE_LIMIT_ENABLED'', True)
        self.RATE_LIMIT_PER_MINUTE = self._get_int(''RATE_LIMIT_PER_MINUTE'', 60)
        
        # Validate critical settings
        self.validate()
    
    def _get_bool(self, key: str, default: bool = False) -> bool:
        """Convert environment variable to boolean"""
        value = os.getenv(key)
        if value is None:
            return default
        return value.lower() in (''true'', ''1'', ''yes'', ''on'')
    
    def _get_int(self, key: str, default: int) -> int:
        """Convert environment variable to integer"""
        value = os.getenv(key)
        if value is None:
            return default
        try:
            return int(value)
        except ValueError:
            print(f"Warning: Invalid integer for {key}, using default {default}")
            return default
    
    def validate(self):
        """Validate critical configuration settings"""
        errors = []
        
        if not self.SECRET_KEY:
            errors.append("SECRET_KEY must be set in environment variables")
        elif len(self.SECRET_KEY) < 32:
            errors.append("SECRET_KEY must be at least 32 characters long")
        
        if not self.SCANNER_DATA_PATH.exists():
            errors.append(f"SCANNER_DATA_PATH does not exist: {self.SCANNER_DATA_PATH}")
        
        if errors:
            raise ValueError(f"Configuration validation failed:\n" + "\n".join(f"- {e}" for e in errors))
    
    def load_yaml_config(self, yaml_path: Path):
        """Load additional configuration from YAML file"""
        if not yaml_path.exists():
            return
        
        with open(yaml_path) as f:
            yaml_config = yaml.safe_load(f)
        
        # Override with YAML values (env vars take precedence)
        for key, value in yaml_config.items():
            if not hasattr(self, key):
                setattr(self, key, value)

# Update NetworkDashboard to use configuration
class NetworkDashboard:
    def __init__(self, config: Config = None):
        self.config = config or Config()
        self.db_path = str(self.config.DATABASE_PATH)
        self.scanner_data_path = str(self.config.SCANNER_DATA_PATH)
        # ... rest of initialization
```

### TASK-008: Testing Steps

1. Create `.env` file with test values
2. Import Config class in Python REPL
3. Verify all settings loaded correctly
4. Test validation with missing SECRET_KEY
5. Test boolean/integer conversion
6. Test YAML configuration loading

### TASK-008: Dependencies

* TASK-001, TASK-005

### TASK-008: Estimated Time

3 hours

---

## Phase 1 Summary

**Total Tasks**: 12  
**Critical Path**: TASK-001 → TASK-002 → TASK-003 → TASK-005 → TASK-008  
**Estimated Total Time**: 2-3 days  
**Blockers**: None - this is the foundational phase

**Success Criteria**:

* [ ] All dependencies installable via pip
* [ ] Configuration system working with environment variables
* [ ] Development environment reproducible
* [ ] All tools (pytest, black, flake8) functional
* [ ] Documentation complete for configuration options
