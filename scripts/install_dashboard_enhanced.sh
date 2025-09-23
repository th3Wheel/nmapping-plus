#!/usr/bin/env bash
"""
nMapping+ Enhanced Dashboard Installation Script
Leverages Proxmox VE Community Scripts for reliable setup and adds custom dashboard functionality.
"""

set -euo pipefail

# Project Information
PROJECT_NAME="nMapping+"
PROJECT_VERSION="1.0.0"
PROJECT_DESCRIPTION="Self-hosted network mapping with real-time web dashboard"

# Configuration
DASHBOARD_USER="nmapping"
DASHBOARD_DIR="/dashboard"
SCANNER_REPO_URL=""  # Will be prompted during installation
WEB_PORT="5000"
PYTHON_VERSION="3.11"

# Community Scripts Integration
COMMUNITY_SCRIPTS_BASE="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"

# Colors for enhanced output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Enhanced logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [${PROJECT_NAME}]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR] [${PROJECT_NAME}]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] [${PROJECT_NAME}]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING] [${PROJECT_NAME}]${NC} $1"
}

msg_info() {
    echo -e "${CYAN}[INFO] [${PROJECT_NAME}]${NC} $1"
}

msg_ok() {
    echo -e "${GREEN}[OK] [${PROJECT_NAME}]${NC} $1"
}

header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE}  ${PROJECT_NAME} v${PROJECT_VERSION}${NC}"
    echo -e "${PURPLE}  ${PROJECT_DESCRIPTION}${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

# Import and use community script functions for reliability
import_community_functions() {
    log "Importing Proxmox VE Community Script functions for enhanced reliability..."
    
    # Download build functions from community scripts
    if ! wget -q "$COMMUNITY_SCRIPTS_BASE/misc/build.func" -O /tmp/build.func; then
        warning "Could not download community script functions - proceeding with local functions"
        return 1
    fi
    
    # Source the community functions
    source /tmp/build.func 2>/dev/null || {
        warning "Could not source community functions - using local implementations"
        return 1
    }
    
    success "Community script functions imported successfully"
    return 0
}

# Enhanced system update using community script patterns
setup_base_system() {
    header
    log "Setting up base system using community script patterns..."
    
    # Update system packages
    msg_info "Updating system packages..."
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    msg_ok "System packages updated"
    
    # Install essential packages
    msg_info "Installing essential packages..."
    apt-get install -y \
        curl \
        wget \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        git \
        unzip \
        sudo \
        systemd \
        logrotate \
        cron &>/dev/null
    msg_ok "Essential packages installed"
    
    # Configure timezone if not set
    if [ ! -f /etc/timezone ]; then
        msg_info "Configuring timezone..."
        timedatectl set-timezone UTC
        msg_ok "Timezone configured to UTC"
    fi
}

# Python installation with enhanced error handling
install_python_environment() {
    log "Installing Python ${PYTHON_VERSION} environment..."
    
    # Add deadsnakes PPA for latest Python versions
    msg_info "Adding Python repository..."
    add-apt-repository -y ppa:deadsnakes/ppa &>/dev/null
    apt-get update &>/dev/null
    msg_ok "Python repository added"
    
    # Install Python and development tools
    msg_info "Installing Python ${PYTHON_VERSION} and development tools..."
    apt-get install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        python${PYTHON_VERSION}-pip \
        python3-setuptools \
        build-essential \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libjpeg-dev \
        libpq-dev \
        libsqlite3-dev &>/dev/null
    msg_ok "Python environment installed"
    
    # Create symlinks for easy access
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1
    update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/python${PYTHON_VERSION} -m pip 1
    
    # Verify Python installation
    PYTHON_VER=$(python3 --version 2>&1 | cut -d' ' -f2)
    success "Python ${PYTHON_VER} installed and configured"
}

# Enhanced user creation with security best practices
create_dashboard_user() {
    log "Creating dedicated dashboard user with security best practices..."
    
    # Create user if it doesn't exist
    if ! id "$DASHBOARD_USER" &>/dev/null; then
        msg_info "Creating user: $DASHBOARD_USER"
        useradd -r -m -d "$DASHBOARD_DIR" -s /bin/bash "$DASHBOARD_USER"
        msg_ok "User created: $DASHBOARD_USER"
    else
        msg_ok "User already exists: $DASHBOARD_USER"
    fi
    
    # Set up user directories with proper permissions
    msg_info "Setting up user directories..."
    mkdir -p "$DASHBOARD_DIR"/{data,logs,config,scanner_data}
    chown -R "$DASHBOARD_USER:$DASHBOARD_USER" "$DASHBOARD_DIR"
    chmod 755 "$DASHBOARD_DIR"
    chmod 750 "$DASHBOARD_DIR"/{data,logs,config}
    msg_ok "User directories configured"
    
    # Add user to necessary groups
    usermod -a -G www-data "$DASHBOARD_USER"
    success "Dashboard user configured with appropriate permissions"
}

# Enhanced Nginx installation and configuration
setup_nginx() {
    log "Installing and configuring Nginx web server..."
    
    # Install Nginx
    msg_info "Installing Nginx..."
    apt-get install -y nginx &>/dev/null
    msg_ok "Nginx installed"
    
    # Create enhanced Nginx configuration
    msg_info "Configuring Nginx for nMapping+ dashboard..."
    cat > /etc/nginx/sites-available/nmapping-dashboard << EOF
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
    
    # Dashboard application
    location / {
        proxy_pass http://127.0.0.1:${WEB_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Static files caching
    location /static/ {
        alias ${DASHBOARD_DIR}/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:${WEB_PORT}/api/health;
        access_log off;
    }
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/nmapping-dashboard /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    if nginx -t &>/dev/null; then
        systemctl enable nginx
        systemctl restart nginx
        msg_ok "Nginx configured and started"
    else
        error "Nginx configuration test failed"
        return 1
    fi
    
    success "Nginx web server configured for nMapping+ dashboard"
}

# Python virtual environment and dependencies
setup_python_environment() {
    log "Setting up Python virtual environment and dependencies..."
    
    # Create virtual environment
    msg_info "Creating Python virtual environment..."
    sudo -u "$DASHBOARD_USER" python3 -m venv "$DASHBOARD_DIR/venv"
    msg_ok "Virtual environment created"
    
    # Upgrade pip and install wheel
    msg_info "Upgrading pip and installing build tools..."
    sudo -u "$DASHBOARD_USER" "$DASHBOARD_DIR/venv/bin/pip" install --upgrade pip wheel setuptools &>/dev/null
    msg_ok "Build tools updated"
    
    # Install Python dependencies
    msg_info "Installing Python dependencies..."
    cat > "$DASHBOARD_DIR/requirements.txt" << EOF
Flask==2.3.3
Flask-SocketIO==5.3.6
python-socketio==5.8.0
eventlet==0.33.3
python-frontmatter==1.0.0
Markdown==3.5.1
Jinja2==3.1.2
Werkzeug==2.3.7
click==8.1.7
itsdangerous==2.1.2
MarkupSafe==2.1.3
six==1.16.0
greenlet==2.0.2
dnspython==2.4.2
bidict==0.22.1
python-engineio==4.7.1
EOF
    
    sudo -u "$DASHBOARD_USER" "$DASHBOARD_DIR/venv/bin/pip" install -r "$DASHBOARD_DIR/requirements.txt" &>/dev/null
    msg_ok "Python dependencies installed"
    
    success "Python environment configured successfully"
}

# Database setup with optimized schema
setup_database() {
    log "Setting up SQLite database with optimized schema..."
    
    # Install SQLite
    msg_info "Installing SQLite..."
    apt-get install -y sqlite3 &>/dev/null
    msg_ok "SQLite installed"
    
    # Create database directory
    mkdir -p "$DASHBOARD_DIR/data"
    chown "$DASHBOARD_USER:$DASHBOARD_USER" "$DASHBOARD_DIR/data"
    
    # Create optimized database schema
    msg_info "Creating database schema..."
    sudo -u "$DASHBOARD_USER" sqlite3 "$DASHBOARD_DIR/data/dashboard.db" << 'EOF'
-- nMapping+ Database Schema
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = 10000;
PRAGMA temp_store = MEMORY;

-- Devices table with comprehensive indexing
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

-- Optimized indexes for common queries
CREATE INDEX IF NOT EXISTS idx_devices_ip ON devices(ip);
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen);
CREATE INDEX IF NOT EXISTS idx_devices_mac ON devices(mac);
CREATE INDEX IF NOT EXISTS idx_devices_hostname ON devices(hostname);

-- Scans table for tracking scan history
CREATE TABLE IF NOT EXISTS scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_type TEXT NOT NULL,
    scan_date TEXT NOT NULL,
    devices_found INTEGER DEFAULT 0,
    new_devices INTEGER DEFAULT 0,
    scan_file TEXT,
    scan_duration INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(scan_type, scan_date)
);

CREATE INDEX IF NOT EXISTS idx_scans_date ON scans(scan_date);
CREATE INDEX IF NOT EXISTS idx_scans_type ON scans(scan_type);

-- Network changes table for audit trail
CREATE TABLE IF NOT EXISTS network_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_ip TEXT NOT NULL,
    change_type TEXT NOT NULL, -- 'new', 'modified', 'disappeared'
    change_description TEXT,
    old_value TEXT,
    new_value TEXT,
    scan_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(id)
);

CREATE INDEX IF NOT EXISTS idx_changes_device ON network_changes(device_ip);
CREATE INDEX IF NOT EXISTS idx_changes_type ON network_changes(change_type);
CREATE INDEX IF NOT EXISTS idx_changes_date ON network_changes(created_at);

-- Insert initial metadata
INSERT OR REPLACE INTO scans (scan_type, scan_date, devices_found, scan_file) 
VALUES ('init', date('now'), 0, 'database_init.sql');
EOF
    
    # Set proper permissions
    chown "$DASHBOARD_USER:$DASHBOARD_USER" "$DASHBOARD_DIR/data/dashboard.db"
    chmod 640 "$DASHBOARD_DIR/data/dashboard.db"
    
    msg_ok "Database schema created and optimized"
    success "SQLite database configured with performance optimizations"
}

# Enhanced systemd service configuration
setup_systemd_service() {
    log "Creating systemd service for nMapping+ dashboard..."
    
    # Create comprehensive systemd service file
    cat > /etc/systemd/system/nmapping-dashboard.service << EOF
[Unit]
Description=nMapping+ Dashboard - Self-hosted network mapping with real-time monitoring
After=network.target nginx.service
Wants=nginx.service
Documentation=https://github.com/your-username/nmapping-plus

[Service]
Type=simple
User=$DASHBOARD_USER
Group=$DASHBOARD_USER
WorkingDirectory=$DASHBOARD_DIR
Environment=PATH=$DASHBOARD_DIR/venv/bin
Environment=PYTHONPATH=$DASHBOARD_DIR
Environment=FLASK_APP=dashboard_app.py
Environment=FLASK_ENV=production
ExecStart=$DASHBOARD_DIR/venv/bin/python $DASHBOARD_DIR/dashboard_app.py
ExecReload=/bin/kill -USR1 \$MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DASHBOARD_DIR
RestartSec=5
Restart=always

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nmapping-dashboard

[Install]
WantedBy=multi-user.target
EOF
    
    # Set proper permissions and enable service
    chmod 644 /etc/systemd/system/nmapping-dashboard.service
    systemctl daemon-reload
    systemctl enable nmapping-dashboard.service
    
    msg_ok "Systemd service created and enabled"
    success "nMapping+ dashboard service configured for automatic startup"
}

# Firewall configuration with security best practices
setup_firewall() {
    log "Configuring firewall for enhanced security..."
    
    # Install and configure UFW
    msg_info "Installing and configuring UFW firewall..."
    apt-get install -y ufw &>/dev/null
    
    # Reset UFW to defaults
    ufw --force reset &>/dev/null
    
    # Set default policies
    ufw default deny incoming &>/dev/null
    ufw default allow outgoing &>/dev/null
    
    # Allow SSH (important!)
    ufw allow 22/tcp comment 'SSH access' &>/dev/null
    
    # Allow HTTP for dashboard
    ufw allow 80/tcp comment 'nMapping+ dashboard HTTP' &>/dev/null
    
    # Allow HTTPS if configured
    ufw allow 443/tcp comment 'nMapping+ dashboard HTTPS' &>/dev/null
    
    # Enable UFW
    ufw --force enable &>/dev/null
    
    msg_ok "UFW firewall configured and enabled"
    success "Firewall configured with security best practices"
}

# Configuration collection
collect_configuration() {
    log "Collecting configuration information..."
    
    # Get scanner repository URL
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    nMapping+ Configuration                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    while [ -z "$SCANNER_REPO_URL" ]; do
        echo -e "${YELLOW}Please provide the Git repository URL for your scanner LXC:${NC}"
        echo -e "${BLUE}Example: user@scanner-lxc-ip:/nmap/registry${NC}"
        echo -e "${BLUE}Or SSH URL: ssh://user@scanner-lxc-ip/path/to/nmap/registry${NC}"
        read -p "Scanner Repository URL: " SCANNER_REPO_URL
        
        if [ -z "$SCANNER_REPO_URL" ]; then
            warning "Repository URL cannot be empty. Please try again."
        fi
    done
    
    success "Configuration collected successfully"
}

# Git repository setup
setup_git_sync() {
    log "Setting up Git synchronization with scanner..."
    
    # Configure Git for dashboard user
    msg_info "Configuring Git for dashboard user..."
    sudo -u "$DASHBOARD_USER" git config --global user.name "nMapping+ Dashboard"
    sudo -u "$DASHBOARD_USER" git config --global user.email "dashboard@nmapping-plus.local"
    sudo -u "$DASHBOARD_USER" git config --global init.defaultBranch main
    msg_ok "Git configured"
    
    # Test connection to scanner repository
    msg_info "Testing connection to scanner repository..."
    if sudo -u "$DASHBOARD_USER" git ls-remote "$SCANNER_REPO_URL" &>/dev/null; then
        msg_ok "Scanner repository accessible"
    else
        warning "Cannot access scanner repository. You may need to configure SSH keys."
        echo -e "${YELLOW}Manual configuration may be required after installation.${NC}"
    fi
    
    # Set up sync script configuration
    sed -i "s|SCANNER_REMOTE_URL=\"\"|SCANNER_REMOTE_URL=\"$SCANNER_REPO_URL\"|" "$DASHBOARD_DIR/sync_dashboard.sh"
    
    success "Git synchronization configured"
}

# Log rotation setup
setup_log_rotation() {
    log "Setting up log rotation for nMapping+ dashboard..."
    
    cat > /etc/logrotate.d/nmapping-dashboard << EOF
${DASHBOARD_DIR}/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $DASHBOARD_USER $DASHBOARD_USER
    postrotate
        systemctl reload nmapping-dashboard
    endscript
}
EOF
    
    msg_ok "Log rotation configured"
}

# Installation validation and testing
validate_installation() {
    log "Validating nMapping+ dashboard installation..."
    
    # Check if all services are running
    msg_info "Checking service status..."
    
    if systemctl is-active --quiet nginx; then
        msg_ok "Nginx is running"
    else
        error "Nginx is not running"
        return 1
    fi
    
    if systemctl is-active --quiet nmapping-dashboard; then
        msg_ok "nMapping+ dashboard service is running"
    else
        warning "Dashboard service is not running - attempting to start..."
        systemctl start nmapping-dashboard
        sleep 3
        if systemctl is-active --quiet nmapping-dashboard; then
            msg_ok "Dashboard service started successfully"
        else
            error "Dashboard service failed to start"
            return 1
        fi
    fi
    
    # Check if dashboard is accessible
    msg_info "Testing dashboard accessibility..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health | grep -q "200"; then
        msg_ok "Dashboard is accessible via HTTP"
    else
        warning "Dashboard may not be fully accessible yet"
    fi
    
    success "Installation validation completed"
}

# Installation summary and next steps
show_installation_summary() {
    clear
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 nMapping+ Installation Complete              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}🎉 nMapping+ dashboard has been successfully installed!${NC}"
    echo
    echo -e "${YELLOW}📊 Dashboard Information:${NC}"
    echo -e "   • Project: ${PROJECT_NAME} v${PROJECT_VERSION}"
    echo -e "   • Web Interface: http://$(hostname -I | awk '{print $1}')/"
    echo -e "   • Local Access: http://localhost/"
    echo -e "   • User: $DASHBOARD_USER"
    echo -e "   • Directory: $DASHBOARD_DIR"
    echo
    echo -e "${YELLOW}🔧 Service Management:${NC}"
    echo -e "   • Start:   systemctl start nmapping-dashboard"
    echo -e "   • Stop:    systemctl stop nmapping-dashboard"
    echo -e "   • Restart: systemctl restart nmapping-dashboard"
    echo -e "   • Status:  systemctl status nmapping-dashboard"
    echo -e "   • Logs:    journalctl -u nmapping-dashboard -f"
    echo
    echo -e "${YELLOW}📁 Important Files:${NC}"
    echo -e "   • Database: $DASHBOARD_DIR/data/dashboard.db"
    echo -e "   • Logs: $DASHBOARD_DIR/logs/"
    echo -e "   • Config: $DASHBOARD_DIR/config/"
    echo -e "   • Sync Script: $DASHBOARD_DIR/sync_dashboard.sh"
    echo
    echo -e "${YELLOW}🔄 Next Steps:${NC}"
    echo -e "   1. Configure SSH keys for Git synchronization (if needed)"
    echo -e "   2. Run initial data sync: sudo -u $DASHBOARD_USER $DASHBOARD_DIR/sync_dashboard.sh"
    echo -e "   3. Set up cron job for automatic syncing"
    echo -e "   4. Configure HTTPS with SSL certificates (optional)"
    echo -e "   5. Set up monitoring and alerting (optional)"
    echo
    echo -e "${GREEN}✅ Installation completed successfully!${NC}"
    echo -e "${BLUE}📖 For more information, visit: https://github.com/your-username/nmapping-plus${NC}"
    echo
}

# Main installation function
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
    
    # Check if this is a supported system
    if ! command -v apt-get &> /dev/null; then
        error "This script requires a Debian/Ubuntu-based system"
        exit 1
    fi
    
    # Import community script functions (optional)
    import_community_functions || true
    
    # Main installation steps
    setup_base_system
    collect_configuration
    install_python_environment
    create_dashboard_user
    setup_python_environment
    setup_database
    setup_nginx
    setup_systemd_service
    setup_firewall
    setup_git_sync
    setup_log_rotation
    
    # Copy dashboard application files
    if [ -f "./dashboard_app.py" ]; then
        msg_info "Copying dashboard application..."
        cp ./dashboard_app.py "$DASHBOARD_DIR/"
        chown "$DASHBOARD_USER:$DASHBOARD_USER" "$DASHBOARD_DIR/dashboard_app.py"
        chmod 755 "$DASHBOARD_DIR/dashboard_app.py"
        msg_ok "Dashboard application copied"
    fi
    
    # Copy sync script
    if [ -f "./sync_dashboard.sh" ]; then
        msg_info "Copying sync script..."
        cp ./sync_dashboard.sh "$DASHBOARD_DIR/"
        chown "$DASHBOARD_USER:$DASHBOARD_USER" "$DASHBOARD_DIR/sync_dashboard.sh"
        chmod 755 "$DASHBOARD_DIR/sync_dashboard.sh"
        msg_ok "Sync script copied"
    fi
    
    # Final validation and summary
    validate_installation
    show_installation_summary
}

# Script execution
main "$@"