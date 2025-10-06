#!/usr/bin/env bash
# nMapping+ LXC Container Creation Script
# Leverages Proxmox VE Community Scripts for reliable container deployment.

set -euo pipefail

# Project Information
PROJECT_NAME="nMapping+"
PROJECT_VERSION="1.0.0"
PROJECT_DESCRIPTION="Self-hosted network mapping with real-time web dashboard"

# Container Configuration - Auto-assigned IDs
# IDs will be automatically assigned starting from 100
SCANNER_CT_ID=""
DASHBOARD_CT_ID=""
DEFAULT_STORAGE="${DEFAULT_STORAGE:-local-lvm}"
DEFAULT_NETWORK="${DEFAULT_NETWORK:-vmbr0}"
DEBIAN_TEMPLATE="${DEBIAN_TEMPLATE:-}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
TEMPLATE_FAMILY="${TEMPLATE_FAMILY:-debian-12-standard}"

SCANNER_ROOT_PASSWORD=""
DASHBOARD_ROOT_PASSWORD=""

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
    echo -e "${PURPLE}  LXC Container Creation Wizard${NC}"
    echo -e "${PURPLE}  ${PROJECT_DESCRIPTION}${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

# Check if running on Proxmox host with enhanced validation
check_proxmox_host() {
    log "Validating Proxmox VE environment..."
    
    if ! command -v pveversion &>/dev/null; then
        error "This script must be run on a Proxmox VE host"
        echo "Please run this script on your Proxmox VE server."
        exit 1
    fi
    
    # Get Proxmox version info
    local pve_version
    local pve_kernel
    pve_version=$(pveversion | grep pve-manager | cut -d/ -f2 | cut -d- -f1)
    pve_kernel=$(pveversion | grep pve-kernel | cut -d/ -f2)
    
    success "Running on Proxmox VE ${pve_version} (kernel: ${pve_kernel})"
    
    # Check if we have sufficient privileges
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root on the Proxmox host"
        exit 1
    fi
    
    # Check available storage
    msg_info "Checking available storage..."
    if pvesm status | grep -q "$DEFAULT_STORAGE"; then
    local available
    available=$(pvesm status -storage "$DEFAULT_STORAGE" | tail -n1 | awk '{print $4}')
        msg_ok "Storage '$DEFAULT_STORAGE' available: ${available}"
    else
        warning "Default storage '$DEFAULT_STORAGE' not found. Manual configuration may be required."
    fi
}

# Enhanced community scripts information
show_community_scripts_info() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Proxmox VE Community Scripts Integration            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}🚀 Why Community Scripts?${NC}"
    echo "   • Battle-tested deployment patterns"
    echo "   • 300+ proven installation scripts"
    echo "   • Optimized container configurations"
    echo "   • Active community support"
    echo "   • Regular security updates"
    echo
    echo -e "${YELLOW}📦 Recommended Base Containers for ${PROJECT_NAME}:${NC}"
    echo
    echo -e "${GREEN}📊 Dashboard Container (auto-assigned ID):${NC}"
    echo "   • Base: Debian 12 (stable, well-supported)"
    echo "   • RAM: 2GB (handles web interface + database)"
    echo "   • Storage: 8GB (application + logs + database)"
    echo "   • CPU: 2 cores (web server + real-time updates)"
    echo "   • Features: Python 3.11, Flask, SQLite, Nginx"
    echo
    echo -e "${GREEN}🔍 Scanner Container (auto-assigned ID):${NC}"
    echo "   • Base: Debian 12 (compatible with nmap packages)"
    echo "   • RAM: 1GB (network scanning operations)"
    echo "   • Storage: 4GB (nmap + scan results + git)"
    echo "   • CPU: 2 cores (parallel scanning)"
    echo "   • Features: Nmap, Masscan, Git, Python scripts"
    echo
    echo -e "${YELLOW}🌐 Network Requirements:${NC}"
    echo "   • Both containers need internet access"
    echo "   • Scanner needs access to target networks"
    echo "   • Dashboard accessible from management network"
    echo "   • Git communication between containers"
    echo
}

# Get next available container ID
get_next_available_id() {
    local start_id=$1
    local current_id=$start_id
    
    while pct status "$current_id" &>/dev/null 2>&1; do
        ((current_id++))
    done
    
    echo "$current_id"
}

# Auto-assign container IDs starting from 100
auto_assign_container_ids() {
    log "Auto-assigning container IDs..."
    
    # Start looking for available IDs from 100
    local base_id=100
    
    # Find first available ID for scanner
    SCANNER_CT_ID=$(get_next_available_id $base_id)
    if [[ -z "$SCANNER_CT_ID" ]] || ! [[ "$SCANNER_CT_ID" =~ ^[0-9]+$ ]]; then
        error "Failed to auto-assign scanner container ID. No available IDs found starting from $base_id."
        exit 1
    fi
    msg_ok "Scanner container ID: $SCANNER_CT_ID"
    
    # Find next available ID for dashboard
    if ! [[ "$SCANNER_CT_ID" =~ ^[0-9]+$ ]]; then
        error "Scanner container ID is not a valid number. Cannot assign dashboard container ID."
        exit 1
    fi
    DASHBOARD_CT_ID=$(get_next_available_id $((SCANNER_CT_ID + 1)))
    if [[ -z "$DASHBOARD_CT_ID" ]] || ! [[ "$DASHBOARD_CT_ID" =~ ^[0-9]+$ ]]; then
        error "Failed to auto-assign dashboard container ID. No available IDs found after $SCANNER_CT_ID."
        exit 1
    fi
    msg_ok "Dashboard container ID: $DASHBOARD_CT_ID"
    
    success "Container IDs auto-assigned: Scanner=$SCANNER_CT_ID, Dashboard=$DASHBOARD_CT_ID"
}

# Generate secure root password for automated deployments
generate_secure_password() {
    if command -v openssl &>/dev/null; then
        openssl rand -base64 24 | tr -dc 'A-Za-z0-9@#%+=' | head -c 20
    else
        date +%s | sha256sum | base64 | tr -dc 'A-Za-z0-9@#%+=' | head -c 20
    fi
}

resolve_debian_template() {
    local current_template="${DEBIAN_TEMPLATE:-}"
    if [[ -n "$current_template" ]]; then
        echo "$current_template"
        return
    fi

    local family="$TEMPLATE_FAMILY"
    local storage="$TEMPLATE_STORAGE"
    local local_candidate=""
    local remote_candidate=""

    local_candidate=$(pveam list "$storage" 2>/dev/null | awk 'NR>1 {print $2}' | awk -F/ '{print $NF}' | \
        grep -E "^${family}_" | LC_ALL=C sort -t_ -k2,2V | tail -n1 || true)

    if [[ -z "$local_candidate" ]]; then
        pveam update >/dev/null
        remote_candidate=$(pveam available 2>/dev/null | awk 'NR>1 {print $2}' | awk -F/ '{print $NF}' | \
            grep -E "^${family}_" | LC_ALL=C sort -t_ -k2,2V | tail -n1 || true)
    fi

    local selected="${local_candidate:-$remote_candidate}"
    if [[ -z "$selected" ]]; then
        error "Unable to resolve template matching '${family}'. Set DEBIAN_TEMPLATE explicitly or adjust TEMPLATE_FAMILY."
        exit 1
    fi

    echo "$selected"
}

# Ensure Debian LXC template is downloaded locally for pct creation
ensure_template_downloaded() {
    local template="$DEBIAN_TEMPLATE"
    local storage="$TEMPLATE_STORAGE"

    msg_info "Ensuring Debian template '$template' is available in storage '$storage'..."
    if ! pveam list "$storage" 2>/dev/null | awk 'NR>1 {print $2}' | awk -F/ '{print $NF}' | grep -qw -- "$template"; then
        log "Template not found locally. Updating Proxmox appliance catalog..."
        pveam update >/dev/null
        log "Downloading template $template to storage $storage..."
        pveam download "$storage" "$template"
        msg_ok "Template $template downloaded to $storage."
    else
        msg_ok "Template $template already present in $storage."
    fi
}

# Create and start an LXC container non-interactively using pct
create_container_automated() {
    local ct_id="$1"
    local hostname="$2"
    local cores="$3"
    local memory="$4"
    local disk="$5"
    local role="$6"
    local password_input="$7"

    if pct status "$ct_id" &>/dev/null; then
        error "Container ID $ct_id already exists. Aborting automated deployment."
        exit 1
    fi

    ensure_template_downloaded

    local rootfs_ref="${DEFAULT_STORAGE}:${disk}"
    local template_ref="${TEMPLATE_STORAGE}:vztmpl/${DEBIAN_TEMPLATE}"
    local password="$password_input"

    if [[ -z "$password" ]]; then
        password=$(generate_secure_password)
    fi

    msg_info "Creating container $ct_id ($hostname) from template $DEBIAN_TEMPLATE using pct..."
    pct create "$ct_id" "$template_ref" \
        -hostname "$hostname" \
        -description "${PROJECT_NAME} ${role}" \
        -cores "$cores" \
        -memory "$memory" \
        -features keyctl=1,nesting=1 \
        -unprivileged 1 \
        -onboot 1 \
        -net0 "name=eth0,bridge=${DEFAULT_NETWORK},ip=dhcp" \
        -rootfs "$rootfs_ref" \
        -password "$password" \
        -tags "${PROJECT_NAME// /-},${role// /-}" >/dev/null

    pct start "$ct_id" >/dev/null
    msg_ok "Container $ct_id ($hostname) created and started."

    echo "$password"
}

# Enhanced container creation with community scripts
create_scanner_container() {
    header
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  🔍 Scanner Container Setup                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    if [[ -z "$SCANNER_CT_ID" ]]; then
        error "Scanner container ID is not set. Please run auto_assign_container_ids or set SCANNER_CT_ID."
        exit 1
    fi

    log "Preparing to create ${PROJECT_NAME} scanner container..."
    
    msg_ok "Using auto-assigned container ID: $SCANNER_CT_ID"
    
    echo -e "${YELLOW}📋 Scanner Container Configuration:${NC}"
    echo "   • Container ID: $SCANNER_CT_ID"
    echo "   • Hostname: nmapping-scanner"
    echo "   • OS: Debian 12 (bookworm)"
    echo "   • CPU Cores: 2"
    echo "   • Memory: 1024 MB"
    echo "   • Storage: 4 GB"
    echo "   • Network: DHCP on $DEFAULT_NETWORK"
    echo "   • Features: Unprivileged, Start on boot"
    echo
    
    echo -e "${CYAN}🚀 Community Script Command:${NC}"
    cat << EOF
bash -c "\$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/debian.sh)"

When prompted, use these values:
- Container ID: $SCANNER_CT_ID
- Hostname: nmapping-scanner
- Root Password: [your secure password]
- Container Size: 4
- Core Count: 2
- RAM: 1024
- Bridge: $DEFAULT_NETWORK
- Start container: Yes
- Privileged: No

EOF
    
    echo -e "${YELLOW}🔧 Post-Creation Setup:${NC}"
    echo "After the container is created, install ${PROJECT_NAME} scanner:"
    echo
    cat << EOF
# Install nMapping+ scanner components:
pct exec $SCANNER_CT_ID -- bash -c "\\
  wget -qLO - https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install_dependencies.sh | bash && \\
  apt update && apt install -y nmap masscan git python3 python3-pip && \\
  pip3 install python-nmap scapy netaddr"

EOF
    
    echo -e "${GREEN}✅ Scanner Container Features:${NC}"
    echo "   • Network discovery and mapping"
    echo "   • Device fingerprinting with Nmap"
    echo "   • Fast port scanning with Masscan"
    echo "   • Git-based change tracking"
    echo "   • Automated vulnerability detection"
    echo "   • Integration with dashboard via Git sync"
    echo
}

# Enhanced dashboard container creation
create_dashboard_container() {
    header
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 📊 Dashboard Container Setup                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    if [[ -z "$DASHBOARD_CT_ID" ]]; then
        error "Dashboard container ID is not set. Please run auto_assign_container_ids or set DASHBOARD_CT_ID."
        exit 1
    fi

    log "Preparing to create ${PROJECT_NAME} dashboard container..."
    
    msg_ok "Using auto-assigned container ID: $DASHBOARD_CT_ID"
    
    echo -e "${YELLOW}📋 Dashboard Container Configuration:${NC}"
    echo "   • Container ID: $DASHBOARD_CT_ID"
    echo "   • Hostname: nmapping-dashboard"
    echo "   • OS: Debian 12 (bookworm)"
    echo "   • CPU Cores: 2"
    echo "   • Memory: 2048 MB"
    echo "   • Storage: 8 GB"
    echo "   • Network: DHCP on $DEFAULT_NETWORK"
    echo "   • Features: Unprivileged, Start on boot"
    echo
    
    echo -e "${CYAN}🚀 Community Script Command:${NC}"
    cat << EOF
bash -c "\$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/debian.sh)"

When prompted, use these values:
- Container ID: $DASHBOARD_CT_ID
- Hostname: nmapping-dashboard
- Root Password: [your secure password]
- Container Size: 8
- Core Count: 2
- RAM: 2048
- Bridge: $DEFAULT_NETWORK
- Start container: Yes
- Privileged: No

EOF
    
    echo -e "${YELLOW}🔧 Post-Creation Setup:${NC}"
    echo "After the container is created, install ${PROJECT_NAME} dashboard:"
    echo
    cat << EOF
# Transfer and run the enhanced installation script:
pct push $DASHBOARD_CT_ID install_dashboard_enhanced.sh /tmp/install_dashboard_enhanced.sh
pct exec $DASHBOARD_CT_ID -- chmod +x /tmp/install_dashboard_enhanced.sh
pct exec $DASHBOARD_CT_ID -- /tmp/install_dashboard_enhanced.sh

EOF
    
    echo -e "${GREEN}✅ Dashboard Container Features:${NC}"
    echo "   • Real-time web interface"
    echo "   • Interactive network topology"
    echo "   • Device management and monitoring"
    echo "   • Vulnerability tracking and alerts"
    echo "   • Historical change analysis"
    echo "   • RESTful API for integration"
    echo "   • Mobile-responsive design"
    echo
}

# Automated dual-container deployment
create_both_containers_guided() {
    header
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🚀 Dual-Container Deployment Wizard            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log "Setting up complete ${PROJECT_NAME} infrastructure..."
    
    msg_ok "Using auto-assigned container IDs: Scanner=$SCANNER_CT_ID, Dashboard=$DASHBOARD_CT_ID"
    
    echo -e "${YELLOW}📊 Infrastructure Overview:${NC}"
    echo "   • Scanner Container: LXC $SCANNER_CT_ID (nmapping-scanner)"
    echo "   • Dashboard Container: LXC $DASHBOARD_CT_ID (nmapping-dashboard)"
    echo "   • Total RAM: 3 GB"
    echo "   • Total Storage: 12 GB"
    echo "   • Network: Containers will communicate via $DEFAULT_NETWORK"
    echo
    
    echo -e "${CYAN}🔄 Deployment Steps:${NC}"
    echo "1. Create scanner container using community scripts"
    echo "2. Create dashboard container using community scripts"
    echo "3. Install ${PROJECT_NAME} components in each container"
    echo "4. Configure Git synchronization between containers"
    echo "5. Set up network access and firewall rules"
    echo
    
    read -r -p "Proceed with automated deployment? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Starting automated deployment..."
    SCANNER_ROOT_PASSWORD=$(create_container_automated "$SCANNER_CT_ID" "nmapping-scanner" 2 1024 4 "Scanner")
    DASHBOARD_ROOT_PASSWORD=$(create_container_automated "$DASHBOARD_CT_ID" "nmapping-dashboard" 2 2048 8 "Dashboard")

    create_post_deployment_script

    echo
    success "Containers created successfully!"
    echo -e "${YELLOW}🔐 Root Credentials:${NC}"
    echo "   • Scanner (ID $SCANNER_CT_ID): ${SCANNER_ROOT_PASSWORD}"
    echo "   • Dashboard (ID $DASHBOARD_CT_ID): ${DASHBOARD_ROOT_PASSWORD}"
    echo -e "${YELLOW}⚠️  Reminder:${NC} Change these passwords after first login."
    echo
    msg_info "Run ./nmapping_plus_setup.sh to complete in-container provisioning."
    else
        log "Manual deployment selected - showing individual container instructions..."
        echo
        create_scanner_container
        echo
        create_dashboard_container
    fi
}

# Create comprehensive post-deployment setup script
create_post_deployment_script() {
    log "Generating post-deployment configuration script..."
    
    cat > "nmapping_plus_setup.sh" << EOF
#!/bin/bash
# ${PROJECT_NAME} Post-Deployment Configuration Script
# Generated on $(date)

set -e

echo "=================================================================="
echo "🔧 ${PROJECT_NAME} Post-Deployment Configuration"
echo "=================================================================="

# Container IDs
SCANNER_ID="$SCANNER_CT_ID"
DASHBOARD_ID="$DASHBOARD_CT_ID"

echo "📦 Installing ${PROJECT_NAME} Scanner Components..."
pct exec \$SCANNER_ID -- bash -c "
    apt update && apt install -y nmap masscan git python3 python3-pip curl wget
    pip3 install python-nmap scapy netaddr requests
    mkdir -p /nmap/{scans,registry,logs}
    git config --global user.name '${PROJECT_NAME} Scanner'
    git config --global user.email 'scanner@nmapping-plus.local'
    echo 'Scanner components installed successfully'
"

echo "📊 Installing ${PROJECT_NAME} Dashboard Components..."
if [ -f "install_dashboard_enhanced.sh" ]; then
    pct push \$DASHBOARD_ID install_dashboard_enhanced.sh /tmp/install_dashboard_enhanced.sh
    pct exec \$DASHBOARD_ID -- chmod +x /tmp/install_dashboard_enhanced.sh
    pct exec \$DASHBOARD_ID -- /tmp/install_dashboard_enhanced.sh
else
    echo "Warning: install_dashboard_enhanced.sh not found in current directory"
    echo "Please upload and run the dashboard installation script manually"
fi

echo "🌐 Getting Container IP Addresses..."
SCANNER_IP=\$(pct exec \$SCANNER_ID -- hostname -I | awk '{print \$1}')
DASHBOARD_IP=\$(pct exec \$DASHBOARD_ID -- hostname -I | awk '{print \$1}')

echo "=================================================================="
echo "✅ ${PROJECT_NAME} Deployment Complete!"
echo "=================================================================="
echo "Scanner Container:   LXC \$SCANNER_ID (\$SCANNER_IP)"
echo "Dashboard Container: LXC \$DASHBOARD_ID (\$DASHBOARD_IP)"
echo
echo "🌐 Access your dashboard: http://\$DASHBOARD_IP"
echo "🔧 SSH to scanner: ssh root@\$SCANNER_IP"
echo "📊 SSH to dashboard: ssh root@\$DASHBOARD_IP"
echo
echo "Next steps:"
echo "1. Configure Git synchronization between containers"
echo "2. Set up network scanning schedules"
echo "3. Configure firewall rules if needed"
echo "4. Access the web dashboard and complete setup"
echo "=================================================================="
EOF
    
    chmod +x "nmapping_plus_setup.sh"
    success "Post-deployment script created: nmapping_plus_setup.sh"
}

# Show comprehensive deployment alternatives
show_deployment_alternatives() {
    header
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 🔄 Deployment Alternatives                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}1. 🏗️ Single Container (All-in-One):${NC}"
    echo "   • Simplest deployment option"
    echo "   • Lower resource requirements"
    echo "   • Scanner and dashboard in same container"
    echo "   • Recommended for: Testing, small networks"
    echo
    
    echo -e "${YELLOW}2. 🐳 Docker-based Deployment:${NC}"
    echo "   • Modern containerization approach"
    echo "   • Easy updates and scaling"
    echo "   • Requires Docker host LXC"
    echo "   • Recommended for: Production environments"
    echo
    
    echo -e "${YELLOW}3. 🖥️ Virtual Machine Deployment:${NC}"
    echo "   • Enhanced security isolation"
    echo "   • Better for mixed environments"
    echo "   • Higher resource overhead"
    echo "   • Recommended for: High-security environments"
    echo
    
    echo -e "${YELLOW}4. 🔧 Existing Container Integration:${NC}"
    echo "   • Use existing Debian/Ubuntu containers"
    echo "   • Manual installation process"
    echo "   • Flexible configuration options"
    echo "   • Recommended for: Existing infrastructure"
    echo
    
    echo -e "${YELLOW}5. 🏢 Enterprise Deployment:${NC}"
    echo "   • Multiple scanner containers"
    echo "   • Load-balanced dashboard"
    echo "   • External database server"
    echo "   • Recommended for: Large networks"
    echo
}

# Interactive deployment wizard with enhanced options
deployment_wizard() {
    header
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🧙 ${PROJECT_NAME} Deployment Wizard            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log "Welcome to the ${PROJECT_NAME} deployment wizard!"
    echo "This wizard will help you deploy network mapping infrastructure using"
    echo "proven Proxmox VE Community Scripts for reliable container creation."
    echo
    
    echo -e "${YELLOW}📋 Choose your deployment scenario:${NC}"
    echo
    echo "1) 🏆 Dual Containers (Recommended)"
    echo "   Scanner + Dashboard in separate containers"
    echo "   Best performance and isolation"
    echo
    echo "2) 🎯 Scanner Container Only"
    echo "   For existing dashboard or custom setup"
    echo
    echo "3) 📊 Dashboard Container Only"
    echo "   For existing scanner or testing"
    echo
    echo "4) 🔧 Manual Instructions"
    echo "   Show detailed setup commands"
    echo
    echo "5) 🔄 Alternative Deployments"
    echo "   Docker, VM, or enterprise options"
    echo
    echo "6) ℹ️ Community Scripts Information"
    echo "   Learn about the foundation technology"
    echo
    
    read -r -p "Enter your choice (1-6): " choice
    echo
    
    case $choice in
        1)
            log "Selected: Dual container deployment (recommended)"
            create_both_containers_guided
            ;;
        2)
            log "Selected: Scanner container only"
            create_scanner_container
            ;;
        3)
            log "Selected: Dashboard container only"
            create_dashboard_container
            ;;
        4)
            log "Selected: Manual instructions"
            show_community_scripts_info
            create_scanner_container
            echo
            create_dashboard_container
            ;;
        5)
            log "Selected: Alternative deployments"
            show_deployment_alternatives
            ;;
        6)
            log "Selected: Community scripts information"
            show_community_scripts_info
            ;;
        *)
            error "Invalid choice. Please run the script again and select 1-6."
            exit 1
            ;;
    esac
}

# Show comprehensive help and usage
show_help() {
    header
    echo
    echo -e "${CYAN}Usage: $0 [option]${NC}"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  --scanner       Create scanner container only"
    echo "  --dashboard     Create dashboard container only"
    echo "  --both          Create both containers (guided)"
    echo "  --alternatives  Show alternative deployment options"
    echo "  --info          Show community scripts information"
    echo "  --help, -h      Show this help message"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0                    # Run interactive wizard"
    echo "  $0 --scanner          # Create scanner container"
    echo "  $0 --dashboard        # Create dashboard container"
    echo "  $0 --both            # Create both containers"
    echo
    echo -e "${YELLOW}Environment Variables:${NC}"
    echo "  DEFAULT_STORAGE   Proxmox storage name (default: local-lvm)"
    echo "  DEFAULT_NETWORK   Network bridge (default: vmbr0)"
    echo "  SCANNER_CT_ID     Override auto-assigned scanner container ID"
    echo "  DASHBOARD_CT_ID   Override auto-assigned dashboard container ID"
    echo
    echo -e "${YELLOW}Requirements:${NC}"
    echo "  • Must run on Proxmox VE host as root"
    echo "  • Internet access for downloading community scripts"
    echo "  • Sufficient storage and memory for containers"
    echo
    echo -e "${YELLOW}Resources:${NC}"
    echo "  • Community Scripts: https://community-scripts.github.io/ProxmoxVE/"
    echo "  • ${PROJECT_NAME} Documentation: [your-repo-url]"
    echo "  • Proxmox VE Docs: https://pve.proxmox.com/wiki/"
    echo
}

# Main execution function
main() {
    # Handle help requests first
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Validate environment
    check_proxmox_host

    DEBIAN_TEMPLATE="$(resolve_debian_template)"
    msg_info "Resolved Debian template: ${DEBIAN_TEMPLATE}"
    
    # Auto-assign container IDs
    auto_assign_container_ids
    
    # Process command line options
    case "${1:-}" in
        --scanner)
            create_scanner_container
            ;;
        --dashboard)
            create_dashboard_container
            ;;
        --both)
            create_both_containers_guided
            ;;
        --alternatives)
            show_deployment_alternatives
            ;;
        --info)
            show_community_scripts_info
            ;;
        "")
            deployment_wizard
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}📚 Additional Resources:${NC}"
    echo "• Community Scripts: https://community-scripts.github.io/ProxmoxVE/"
    echo "• Proxmox Documentation: https://pve.proxmox.com/wiki/"
    echo "• ${PROJECT_NAME} Project: [your-repository-url]"
    echo
    success "${PROJECT_NAME} container creation wizard complete!"
}

# Execute main function with all arguments
main "$@"