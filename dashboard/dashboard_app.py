#!/usr/bin/env python3
"""
nMapping+ Dashboard
A modern web dashboard for network monitoring and device management.
Self-hosted network mapping with real-time updates and interactive visualization.
"""

from flask import Flask, render_template_string, jsonify, request
from flask_socketio import SocketIO, emit
import sqlite3
import os
import json
import re
import markdown
import frontmatter
from datetime import datetime, timedelta
import subprocess
import threading
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'nmapping-plus-dashboard-secret-key-change-me'
socketio = SocketIO(app, cors_allowed_origins="*")

# Configuration
DASHBOARD_DIR = '/dashboard'
DATABASE_PATH = os.path.join(DASHBOARD_DIR, 'data', 'dashboard.db')
SCANNER_DATA_PATH = os.path.join(DASHBOARD_DIR, 'scanner_data')

# Project Information
PROJECT_NAME = "nMapping+"
PROJECT_VERSION = "1.0.0"
PROJECT_DESCRIPTION = "Self-hosted network mapping with real-time web dashboard"

class NetworkDashboard:
    def __init__(self):
        self.db_path = DATABASE_PATH
        self.init_database()
    
    def get_db_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def init_database(self):
        """Initialize database tables if they don't exist"""
        conn = self.get_db_connection()
        
        # Create tables if they don't exist
        conn.execute('''
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
            )
        ''')
        
        conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_devices_ip ON devices(ip)
        ''')
        
        conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status)
        ''')
        
        conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen)
        ''')
        
        conn.close()
    
    def sync_from_scanner_data(self):
        """Sync data from scanner Git repository"""
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
        except Exception as e:
            print(f"{PROJECT_NAME}: Error syncing data: {e}")
            return False
    
    def process_device_files(self):
        """Process individual device markdown files"""
        conn = self.get_db_connection()
        
        # Find all device IP files
        device_count = 0
        for file in os.listdir(SCANNER_DATA_PATH):
            if re.match(r'^\d+\.\d+\.\d+\.\d+\.md$', file):
                ip = file.replace('.md', '')
                self.process_device_file(conn, ip, os.path.join(SCANNER_DATA_PATH, file))
                device_count += 1
        
        print(f"{PROJECT_NAME}: Processed {device_count} device files")
        conn.close()
    
    def process_device_file(self, conn, ip, filepath):
        """Process individual device markdown file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Try to parse frontmatter if it exists
            try:
                post = frontmatter.loads(content)
                content = post.content
                metadata = post.metadata
            except:
                metadata = {}
            
            # Extract device information using improved regex patterns
            mac = self.extract_field(content, r'\*\*MAC:\*\*\s*(.+)')
            vendor = self.extract_field(content, r'\*\*Vendor:\*\*\s*(.+)')
            hostname = self.extract_field(content, r'\*\*Hostname:\*\*\s*(.+)')
            first_seen = self.extract_field(content, r'\*\*First Seen:\*\*\s*(.+)')
            last_seen = self.extract_field(content, r'\*\*Last Seen:\*\*\s*(.+)')
            
            # Extract OS and services information
            os_info = self.extract_section(content, r'## OS & Services')
            services = self.extract_services(content)
            vulnerabilities = self.extract_section(content, r'## Vulnerabilities')
            
            # Determine status based on last seen date
            status = self.determine_device_status(last_seen)
            
            # Insert or update device with proper error handling
            conn.execute('''
                INSERT OR REPLACE INTO devices 
                (ip, mac, vendor, hostname, first_seen, last_seen, status, os_info, services, vulnerabilities, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            ''', (ip, mac, vendor, hostname, first_seen, last_seen, status, os_info, services, vulnerabilities))
            
            conn.commit()
            
        except Exception as e:
            print(f"{PROJECT_NAME}: Error processing device file {filepath}: {e}")
    
    def extract_field(self, content, pattern):
        """Extract field using regex pattern"""
        match = re.search(pattern, content, re.IGNORECASE)
        if match:
            value = match.group(1).strip()
            # Clean up common formatting
            value = re.sub(r'^\*\*|\*\*$', '', value)  # Remove bold markers
            return value if value and value != 'Unknown' else ""
        return ""
    
    def extract_section(self, content, section_pattern):
        """Extract entire section content"""
        pattern = f"{section_pattern}.*?(?=## |$)"
        match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
        return match.group(0).strip() if match else ""
    
    def extract_services(self, content):
        """Extract services from OS & Services section"""
        services = []
        lines = content.split('\n')
        for line in lines:
            # Look for port information in various formats
            if re.search(r'\d+/(tcp|udp)\s+(open|filtered|closed)', line, re.IGNORECASE):
                services.append(line.strip())
            elif re.search(r'Port\s+\d+', line, re.IGNORECASE):
                services.append(line.strip())
        return '\n'.join(services)
    
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
            print(f"{PROJECT_NAME}: Error parsing date '{last_seen}': {e}")
            return 'unknown'
    
    def process_scan_summaries(self):
        """Process scan summary files"""
        conn = self.get_db_connection()
        
        # Create scans table if it doesn't exist
        conn.execute('''
            CREATE TABLE IF NOT EXISTS scans (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                scan_type TEXT NOT NULL,
                scan_date TEXT NOT NULL,
                devices_found INTEGER DEFAULT 0,
                new_devices INTEGER DEFAULT 0,
                scan_file TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(scan_type, scan_date)
            )
        ''')
        
        scan_count = 0
        for file in os.listdir(SCANNER_DATA_PATH):
            if re.match(r'^(discovery|fingerprint|vuln)_\d{4}-\d{2}-\d{2}\.md$', file):
                self.process_scan_summary(conn, os.path.join(SCANNER_DATA_PATH, file))
                scan_count += 1
        
        print(f"{PROJECT_NAME}: Processed {scan_count} scan summary files")
        conn.close()
    
    def process_scan_summary(self, conn, filepath):
        """Process individual scan summary file"""
        try:
            filename = os.path.basename(filepath)
            scan_type = filename.split('_')[0]
            scan_date = filename.split('_')[1].replace('.md', '')
            
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Count devices found using multiple patterns
            devices_found = len(re.findall(r'- \[\[(\d+\.\d+\.\d+\.\d+)\]\]', content))
            if devices_found == 0:
                devices_found = len(re.findall(r'(\d+\.\d+\.\d+\.\d+)', content))
            
            # Check for new devices section
            new_devices = 0
            if '## New Devices' in content:
                new_devices_section = content.split('## New Devices')[1].split('\n\n')[0]
                new_devices = len(re.findall(r'- (\d+\.\d+\.\d+\.\d+)', new_devices_section))
            
            # Insert scan record
            conn.execute('''
                INSERT OR REPLACE INTO scans 
                (scan_type, scan_date, devices_found, new_devices, scan_file)
                VALUES (?, ?, ?, ?, ?)
            ''', (scan_type, scan_date, devices_found, new_devices, filename))
            
            conn.commit()
            
        except Exception as e:
            print(f"{PROJECT_NAME}: Error processing scan summary {filepath}: {e}")
    
    def get_dashboard_data(self):
        """Get all dashboard data"""
        conn = self.get_db_connection()
        
        try:
            # Get devices with error handling
            devices = conn.execute('''
                SELECT * FROM devices ORDER BY last_seen DESC, ip ASC
            ''').fetchall()
            
            # Get recent scans with error handling
            recent_scans = conn.execute('''
                SELECT * FROM scans ORDER BY scan_date DESC LIMIT 10
            ''').fetchall()
            
            # Calculate statistics
            total_devices = len(devices)
            online_devices = len([d for d in devices if d['status'] == 'online'])
            offline_devices = len([d for d in devices if d['status'] == 'offline'])
            recently_seen = len([d for d in devices if d['status'] == 'recently_seen'])
            inactive_devices = len([d for d in devices if d['status'] == 'inactive'])
            unknown_devices = len([d for d in devices if d['status'] == 'unknown'])
            
            stats = {
                'total_devices': total_devices,
                'online_devices': online_devices,
                'offline_devices': offline_devices,
                'recently_seen': recently_seen,
                'inactive_devices': inactive_devices,
                'unknown_devices': unknown_devices,
                'last_updated': datetime.now().isoformat()
            }
            
            conn.close()
            
            return {
                'devices': [dict(device) for device in devices],
                'recent_scans': [dict(scan) for scan in recent_scans],
                'stats': stats,
                'project_info': {
                    'name': PROJECT_NAME,
                    'version': PROJECT_VERSION,
                    'description': PROJECT_DESCRIPTION
                }
            }
            
        except Exception as e:
            print(f"{PROJECT_NAME}: Error getting dashboard data: {e}")
            conn.close()
            return {
                'devices': [],
                'recent_scans': [],
                'stats': {'total_devices': 0, 'online_devices': 0, 'offline_devices': 0, 'recently_seen': 0, 'inactive_devices': 0, 'unknown_devices': 0},
                'project_info': {'name': PROJECT_NAME, 'version': PROJECT_VERSION, 'description': PROJECT_DESCRIPTION},
                'error': str(e)
            }

# Initialize dashboard
dashboard = NetworkDashboard()

# Enhanced HTML Template for the dashboard
DASHBOARD_HTML = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nMapping+ Dashboard</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        :root {
            --primary-color: #667eea;
            --secondary-color: #764ba2;
            --success-color: #10b981;
            --warning-color: #f59e0b;
            --danger-color: #ef4444;
            --info-color: #6366f1;
            --light-bg: #f8fafc;
            --border-color: #e2e8f0;
            --text-color: #2d3748;
            --text-light: #64748b;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: var(--light-bg); 
            line-height: 1.6; 
            color: var(--text-color);
        }
        
        .header {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white; 
            padding: 1.5rem 2rem; 
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 { 
            font-size: 2.5rem; 
            margin-bottom: 0.5rem;
            font-weight: 700;
        }
        
        .header p { 
            opacity: 0.9; 
            font-size: 1.1rem;
        }
        
        .header-stats {
            text-align: right;
            font-size: 0.875rem;
            opacity: 0.8;
        }
        
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            padding: 2rem; 
        }
        
        .grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); 
            gap: 2rem; 
        }
        
        .card {
            background: white; 
            border-radius: 16px; 
            padding: 2rem;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05), 0 1px 3px rgba(0,0,0,0.1); 
            border: 1px solid var(--border-color);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }
        
        .card h2 { 
            margin-bottom: 1.5rem; 
            color: var(--text-color); 
            font-size: 1.375rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); 
            gap: 1rem; 
        }
        
        .stat-item {
            text-align: center; 
            padding: 1.5rem 1rem; 
            background: var(--light-bg);
            border-radius: 12px; 
            border-left: 4px solid var(--primary-color);
            transition: all 0.2s ease;
        }
        
        .stat-item:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        .stat-number { 
            font-size: 2.5rem; 
            font-weight: 700; 
            color: var(--primary-color); 
        }
        
        .stat-label { 
            color: var(--text-light); 
            font-size: 0.875rem; 
            margin-top: 0.5rem;
            font-weight: 500;
        }
        
        .device-list { 
            max-height: 500px; 
            overflow-y: auto;
            scrollbar-width: thin;
        }
        
        .device-item {
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            padding: 1rem; 
            border-bottom: 1px solid var(--border-color); 
            margin-bottom: 0.5rem;
            border-radius: 8px;
            transition: background-color 0.2s ease;
        }
        
        .device-item:hover {
            background-color: var(--light-bg);
        }
        
        .device-item:last-child { border-bottom: none; }
        
        .device-info h3 { 
            font-size: 1.1rem; 
            margin-bottom: 0.25rem;
            font-weight: 600;
        }
        
        .device-info p { 
            color: var(--text-light); 
            font-size: 0.875rem; 
            margin-bottom: 0.125rem;
        }
        
        .status-badge {
            padding: 0.375rem 1rem; 
            border-radius: 25px; 
            font-size: 0.75rem;
            font-weight: 600; 
            text-transform: uppercase;
            letter-spacing: 0.025em;
        }
        
        .status-online { background: #d1fae5; color: #065f46; }
        .status-offline { background: #fee2e2; color: #991b1b; }
        .status-recently_seen { background: #fef3c7; color: #92400e; }
        .status-inactive { background: #e0e7ff; color: #3730a3; }
        .status-unknown { background: #f3f4f6; color: #374151; }
        
        .topology-container { 
            height: 450px; 
            border: 2px solid var(--border-color); 
            border-radius: 12px;
            background: white;
        }
        
        .scan-item {
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            padding: 1rem; 
            border-bottom: 1px solid var(--border-color);
            border-radius: 8px;
            margin-bottom: 0.5rem;
            transition: background-color 0.2s ease;
        }
        
        .scan-item:hover {
            background-color: var(--light-bg);
        }
        
        .scan-type {
            padding: 0.375rem 0.75rem; 
            background: var(--primary-color); 
            color: white;
            border-radius: 6px; 
            font-size: 0.75rem; 
            text-transform: uppercase;
            font-weight: 600;
            letter-spacing: 0.025em;
        }
        
        .refresh-btn {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); 
            color: white; 
            border: none; 
            padding: 0.75rem 1.5rem;
            border-radius: 8px; 
            cursor: pointer; 
            font-size: 0.875rem;
            font-weight: 600;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .refresh-btn:hover { 
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        
        .last-updated {
            font-size: 0.75rem;
            color: var(--text-light);
            margin-top: 1rem;
            text-align: center;
        }
        
        .empty-state {
            text-align: center;
            padding: 2rem;
            color: var(--text-light);
        }
        
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 2rem;
        }
        
        .spinner {
            width: 40px;
            height: 40px;
            border: 4px solid var(--border-color);
            border-top: 4px solid var(--primary-color);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        @media (max-width: 768px) {
            .container { padding: 1rem; }
            .grid { grid-template-columns: 1fr; }
            .stats-grid { grid-template-columns: repeat(2, 1fr); }
            .header-content { flex-direction: column; text-align: center; gap: 1rem; }
            .header h1 { font-size: 2rem; }
            .device-item { flex-direction: column; align-items: flex-start; gap: 0.5rem; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>🗺️ nMapping+</h1>
                <p>Self-hosted network mapping with real-time monitoring</p>
            </div>
            <div class="header-stats">
                <div>Version 1.0.0</div>
                <div id="connection-status">🔗 Connected</div>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="grid">
            <!-- Statistics Card -->
            <div class="card">
                <h2>📊 Network Statistics</h2>
                <div class="stats-grid" id="stats-grid">
                    <div class="loading"><div class="spinner"></div></div>
                </div>
                <button class="refresh-btn" onclick="refreshData()">
                    🔄 <span>Refresh Data</span>
                </button>
                <div class="last-updated" id="last-updated"></div>
            </div>

            <!-- Network Topology -->
            <div class="card">
                <h2>🗺️ Network Topology</h2>
                <div id="topology" class="topology-container"></div>
            </div>

            <!-- Device List -->
            <div class="card">
                <h2>💻 Network Devices</h2>
                <div id="device-list" class="device-list">
                    <div class="loading"><div class="spinner"></div></div>
                </div>
            </div>

            <!-- Recent Scans -->
            <div class="card">
                <h2>🔍 Recent Scans</h2>
                <div id="scan-list">
                    <div class="loading"><div class="spinner"></div></div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Initialize Socket.IO connection
        const socket = io();

        // Dashboard data
        let dashboardData = {};
        let isConnected = false;

        // Initialize dashboard
        socket.on('connect', function() {
            console.log('Connected to nMapping+ dashboard');
            isConnected = true;
            updateConnectionStatus();
            refreshData();
        });

        socket.on('disconnect', function() {
            console.log('Disconnected from nMapping+ dashboard');
            isConnected = false;
            updateConnectionStatus();
        });

        // Listen for data updates
        socket.on('dashboard_update', function(data) {
            dashboardData = data;
            updateDashboard();
        });

        function updateConnectionStatus() {
            const status = document.getElementById('connection-status');
            if (isConnected) {
                status.innerHTML = '🔗 Connected';
                status.style.color = '#10b981';
            } else {
                status.innerHTML = '❌ Disconnected';
                status.style.color = '#ef4444';
            }
        }

        function refreshData() {
            fetch('/api/dashboard')
                .then(response => response.json())
                .then(data => {
                    dashboardData = data;
                    updateDashboard();
                })
                .catch(error => {
                    console.error('Error fetching data:', error);
                });
        }

        function updateDashboard() {
            updateStats();
            updateDeviceList();
            updateScanList();
            updateTopology();
            updateLastUpdated();
        }

        function updateStats() {
            const stats = dashboardData.stats || {};
            const statsGrid = document.getElementById('stats-grid');
            
            statsGrid.innerHTML = `
                <div class="stat-item">
                    <div class="stat-number">${stats.total_devices || 0}</div>
                    <div class="stat-label">Total Devices</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">${stats.online_devices || 0}</div>
                    <div class="stat-label">Online</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">${stats.recently_seen || 0}</div>
                    <div class="stat-label">Recently Seen</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">${stats.offline_devices || 0}</div>
                    <div class="stat-label">Offline</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">${stats.inactive_devices || 0}</div>
                    <div class="stat-label">Inactive</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">${stats.unknown_devices || 0}</div>
                    <div class="stat-label">Unknown</div>
                </div>
            `;
        }

        function updateDeviceList() {
            const devices = dashboardData.devices || [];
            const deviceList = document.getElementById('device-list');
            
            if (devices.length === 0) {
                deviceList.innerHTML = '<div class="empty-state">No devices found. Run a network scan to discover devices.</div>';
                return;
            }
            
            deviceList.innerHTML = devices.map(device => `
                <div class="device-item">
                    <div class="device-info">
                        <h3>${device.ip} ${device.hostname ? '(' + device.hostname + ')' : ''}</h3>
                        <p><strong>MAC:</strong> ${device.mac || 'Unknown'} | <strong>Vendor:</strong> ${device.vendor || 'Unknown'}</p>
                        <p><strong>Last Seen:</strong> ${device.last_seen || 'Unknown'}</p>
                        ${device.services ? '<p><strong>Services:</strong> ' + device.services.split('\\n').slice(0, 2).join(', ') + '</p>' : ''}
                    </div>
                    <span class="status-badge status-${device.status}">${device.status.replace('_', ' ')}</span>
                </div>
            `).join('');
        }

        function updateScanList() {
            const scans = dashboardData.recent_scans || [];
            const scanList = document.getElementById('scan-list');
            
            if (scans.length === 0) {
                scanList.innerHTML = '<div class="empty-state">No recent scans found.</div>';
                return;
            }
            
            scanList.innerHTML = scans.map(scan => `
                <div class="scan-item">
                    <div>
                        <span class="scan-type">${scan.scan_type}</span>
                        <strong style="margin-left: 0.5rem;">${scan.scan_date}</strong>
                    </div>
                    <div>
                        <strong>${scan.devices_found}</strong> devices
                        ${scan.new_devices > 0 ? `<span style="color: var(--success-color); margin-left: 0.5rem;">(+${scan.new_devices} new)</span>` : ''}
                    </div>
                </div>
            `).join('');
        }

        function updateTopology() {
            const devices = dashboardData.devices || [];
            
            if (devices.length === 0) {
                document.getElementById('topology').innerHTML = '<div class="empty-state">No devices to display in topology view.</div>';
                return;
            }
            
            // Create nodes for network visualization
            const nodes = devices.map(device => ({
                id: device.ip,
                label: device.hostname || device.ip,
                color: getStatusColor(device.status),
                title: `IP: ${device.ip}\\nMAC: ${device.mac || 'Unknown'}\\nVendor: ${device.vendor || 'Unknown'}\\nStatus: ${device.status}\\nLast Seen: ${device.last_seen || 'Unknown'}`
            }));

            // Add router/gateway node
            nodes.unshift({
                id: 'router',
                label: 'Network\\nGateway',
                color: '#667eea',
                shape: 'diamond',
                size: 35,
                font: { color: 'white', size: 14, face: 'arial' }
            });

            // Create edges (connections to router)
            const edges = devices.map(device => ({
                from: 'router',
                to: device.ip,
                color: { color: getStatusColor(device.status), opacity: 0.6 },
                width: 2
            }));

            const data = { 
                nodes: new vis.DataSet(nodes), 
                edges: new vis.DataSet(edges) 
            };
            
            const options = {
                layout: { 
                    randomSeed: 42,
                    improvedLayout: true
                },
                physics: { 
                    enabled: true, 
                    stabilization: { iterations: 100 },
                    barnesHut: { gravitationalConstant: -2000, springConstant: 0.001, springLength: 200 }
                },
                interaction: { 
                    hover: true,
                    tooltipDelay: 200
                },
                nodes: {
                    shape: 'dot',
                    size: 25,
                    font: { size: 12, face: 'arial' },
                    borderWidth: 2,
                    shadow: true
                },
                edges: {
                    smooth: { type: 'continuous' }
                }
            };

            const container = document.getElementById('topology');
            const network = new vis.Network(container, data, options);
            
            // Add click event for device details
            network.on('click', function(params) {
                if (params.nodes.length > 0 && params.nodes[0] !== 'router') {
                    const deviceIp = params.nodes[0];
                    // You could open a modal or navigate to device details here
                    console.log('Device clicked:', deviceIp);
                }
            });
        }

        function updateLastUpdated() {
            const lastUpdated = document.getElementById('last-updated');
            const now = new Date();
            lastUpdated.textContent = `Last updated: ${now.toLocaleString()}`;
        }

        function getStatusColor(status) {
            switch(status) {
                case 'online': return '#10b981';
                case 'recently_seen': return '#f59e0b';
                case 'inactive': return '#6366f1';
                case 'offline': return '#ef4444';
                default: return '#6b7280';
            }
        }

        // Auto-refresh every 30 seconds
        setInterval(refreshData, 30000);

        // Initial load
        document.addEventListener('DOMContentLoaded', function() {
            refreshData();
        });
    </script>
</body>
</html>
'''

@app.route('/')
def dashboard():
    """Main dashboard page"""
    return render_template_string(DASHBOARD_HTML)

@app.route('/api/dashboard')
def api_dashboard():
    """API endpoint for dashboard data"""
    data = dashboard.get_dashboard_data()
    return jsonify(data)

@app.route('/api/refresh', methods=['POST', 'GET'])
def api_refresh():
    """API endpoint to refresh data from scanner"""
    success = dashboard.sync_from_scanner_data()
    data = dashboard.get_dashboard_data()
    
    # Emit update to all connected clients
    socketio.emit('dashboard_update', data)
    
    return jsonify({'success': success, 'message': f'{PROJECT_NAME} data refreshed successfully'})

@app.route('/api/health')
def api_health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'project': PROJECT_NAME,
        'version': PROJECT_VERSION,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/device/<ip>')
def api_device(ip):
    """API endpoint for individual device details"""
    conn = dashboard.get_db_connection()
    device = conn.execute('SELECT * FROM devices WHERE ip = ?', (ip,)).fetchone()
    conn.close()
    
    if device:
        return jsonify(dict(device))
    else:
        return jsonify({'error': 'Device not found'}), 404

@app.route('/api/stats')
def api_stats():
    """API endpoint for dashboard statistics"""
    data = dashboard.get_dashboard_data()
    return jsonify(data['stats'])

def background_sync():
    """Background task to sync data periodically"""
    print(f"{PROJECT_NAME}: Starting background sync service")
    
    while True:
        try:
            success = dashboard.sync_from_scanner_data()
            if success:
                data = dashboard.get_dashboard_data()
                socketio.emit('dashboard_update', data)
                print(f"{PROJECT_NAME}: Background sync completed and clients updated")
            else:
                print(f"{PROJECT_NAME}: Background sync failed")
        except Exception as e:
            print(f"{PROJECT_NAME}: Background sync error: {e}")
        
        # Sync every 5 minutes
        time.sleep(300)

# Start background sync thread
print(f"{PROJECT_NAME} v{PROJECT_VERSION}: Initializing dashboard...")
sync_thread = threading.Thread(target=background_sync, daemon=True)
sync_thread.start()

if __name__ == '__main__':
    print(f"{PROJECT_NAME} v{PROJECT_VERSION}: Starting web dashboard on port 5000")
    print(f"Dashboard will be available at: http://localhost:5000")
    socketio.run(app, host='0.0.0.0', port=5000, debug=False)