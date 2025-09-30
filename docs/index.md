# nMapping+ Documentation Index

Welcome to the comprehensive documentation for **nMapping+**, a self-hosted network mapping solution with real-time web dashboard built on Proxmox VE Community Scripts foundation.

**Current Version: 0.1.0** | **Development Phase: Foundation**

## 📚 Documentation Structure

### 🚀 Getting Started

- **[[deployment-guide|Deployment Guide]]** - Complete deployment instructions using Proxmox VE Community Scripts
- **[[quick-start|Quick Start]]** - Minimal setup for testing and evaluation
- **[[requirements|Installation Requirements]]** - System prerequisites and compatibility
- **[[semantic-versioning|Semantic Versioning Guide]]** - Version management and release procedures

### 🏗️ Architecture

- **[[overview|System Architecture]]** - High-level system design and components
- **[[containers|Container Architecture]]** - LXC container design and communication
- **[[database|Database Schema]]** - SQLite database structure and optimization
- **[[api|API Specification]]** - RESTful API endpoints and WebSocket interface
<!-- If any architecture/*.md files are missing, create or update as needed. -->

### 🔧 Configuration

- **[[scanner|Scanner Configuration]]** - Network scanning setup and customization
- **[[dashboard|Dashboard Configuration]]** - Web interface customization and features
- **[[git-sync|Git Synchronization]]** - Data synchronization between containers
- **[[nMapping+/docs/configuration/security|Security Configuration]]** - Hardening and access control
<!-- If any configuration/*.md files are missing, create or update as needed. -->

### 📋 Operations

- **[[monitoring|Monitoring Guide]]** - System monitoring and alerting
- **[[backup|Backup and Recovery]]** - Data protection strategies
- **[Maintenance Tasks](operations/maintenance.md)** - Regular maintenance procedures
- **[[troubleshooting]]** - Common issues and solutions
<!-- If any operations/*.md files are missing, create or update as needed. -->

### 🔌 Integration

- **[SIEM Integration](integration/siem.md)** - Security Information and Event Management
- **[Monitoring Tools](integration/monitoring.md)** - Prometheus, Grafana, and other tools
- **[Third-party APIs](integration/apis.md)** - External system integration
- **[Webhook Configuration](integration/webhooks.md)** - Real-time notifications
<!-- If any integration/*.md files are missing, create or update as needed. -->

### 🚀 Advanced Topics

- **[High Availability](advanced/high-availability.md)** - HA deployment strategies
- **[Performance Tuning](advanced/performance.md)** - Optimization techniques
- **[Custom Development](advanced/development.md)** - Extending nMapping+ functionality
- **[Enterprise Deployment](advanced/enterprise.md)** - Large-scale production deployment
<!-- If any advanced/*.md files are missing, create or update as needed. -->

### 📖 Reference

- **[CLI Reference](reference/cli.md)** - Command-line tools and utilities
- **[Configuration Reference](reference/configuration.md)** - Complete configuration options
- **[API Reference](reference/api.md)** - Detailed API documentation
- **[FAQ](reference/faq.md)** - Frequently asked questions
<!-- If any reference/*.md files are missing, create or update as needed. -->

## 🎯 Quick Navigation

### For New Users

1. Start with the **[[deployment-guide|Deployment Guide]]** for complete setup instructions
2. Review **[[overview|System Architecture]]** to understand the components
3. Follow **[[scanner|Scanner Configuration]]** to customize scanning

### For Administrators

1. Review **[[nMapping+/docs/configuration/security|Security Configuration]]** for hardening
2. Set up **[[monitoring|Monitoring Guide]]** for operational visibility
3. Plan **[[backup|Backup and Recovery]]** strategies

### For Developers

1. Understand the **[[api|API Specification]]** for integration
2. Review **[Custom Development](advanced/development.md)** guidelines
3. Explore **[Third-party APIs](integration/apis.md)** for extension possibilities

## 🌟 Key Features

### Network Discovery

- **Real-time Scanning**: Continuous network discovery with configurable intervals
- **Device Fingerprinting**: Advanced OS and service detection using Nmap
- **Change Tracking**: Git-based versioning of network changes
- **Vulnerability Detection**: Automated security scanning and reporting

### Web Dashboard

- **Interactive Topology**: Visual network mapping with device relationships
- **Real-time Updates**: WebSocket-powered live data refresh
- **Mobile Responsive**: Access from any device with web browser
- **Historical Analysis**: Trend analysis and change history

### Integration Capabilities

- **RESTful API**: Comprehensive API for external integrations
- **Webhook Support**: Real-time notifications for network changes
- **SIEM Compatible**: Structured logging for security platforms
- **Monitoring Ready**: Prometheus metrics and health checks

### Deployment Flexibility

- **Container-based**: LXC containers for efficient resource usage
- **Community Scripts**: Proven Proxmox VE deployment foundation
- **High Availability**: Scalable architecture for production use
- **Easy Maintenance**: Automated updates and comprehensive logging

## 📋 System Requirements

### Minimum Requirements

- **Proxmox VE**: Version 7.0 or higher
- **RAM**: 4GB available for containers
- **Storage**: 20GB available space
- **Network**: Internet access for downloads

### Recommended for Production

- **Proxmox VE**: Version 8.0 or higher
- **RAM**: 8GB+ for optimal performance
- **Storage**: 50GB+ with SSD for database
- **CPU**: 4+ cores for concurrent scanning
- **Network**: Dedicated VLAN for monitoring traffic

## 🔄 Version Information

### Current Version: 1.0.0

- **Release Date**: January 2025
- **Compatibility**: Proxmox VE 7.0+ / Debian 11+
- **Python**: 3.9+ required
- **Database**: SQLite 3.35+ with WAL mode

### Upgrade Path

- **From Legacy Nmap Fing+**: Migration guide available
- **Breaking Changes**: None in 1.x series
- **Automatic Updates**: Supported via package manager

## 🤝 Community and Support

### Getting Help

- **📖 Documentation**: Comprehensive guides and references
- **💬 Community Forum**: [GitHub Discussions](https://github.com/th3Wheel/nmapping-plus/discussions)
- **🐛 Bug Reports**: [GitHub Issues](https://github.com/th3Wheel/nmapping-plus/issues)
- **✨ Feature Requests**: [GitHub Issues](https://github.com/th3Wheel/nmapping-plus/issues)

### Contributing

- **🔧 Development**: See [Custom Development](advanced/development.md)
- **📝 Documentation**: Improvements welcome via pull requests
- **🧪 Testing**: Help test new features and bug fixes
- **🌍 Translation**: Multi-language support contributions

### Resources

- **🏠 Project Homepage**: [GitHub Repository](https://github.com/th3Wheel/nmapping-plus)
- **📦 Releases**: [GitHub Releases](https://github.com/th3Wheel/nmapping-plus/releases)
- **📊 Roadmap**: [Project Roadmap](https://github.com/th3Wheel/nmapping-plus/projects)
- **📈 Changelog**: [Release Notes](https://github.com/th3Wheel/nmapping-plus/blob/main/CHANGELOG.md)

## 📄 License and Legal

nMapping+ is released under the MIT License, allowing free use, modification, and distribution. See the [LICENSE](../LICENSE) file for complete terms.

### Third-party Components

- **Proxmox VE Community Scripts**: Various licenses (GPL, MIT, BSD)
- **Flask Framework**: BSD-3-Clause License
- **Nmap**: GPL v2 License (for scanning functionality)
- **Vis.js**: MIT License (for network visualization)

### Security Considerations

nMapping+ is designed for legitimate network monitoring and security assessment. Users are responsible for:

- Obtaining proper authorization before scanning networks
- Complying with local laws and regulations
- Following responsible disclosure practices
- Implementing appropriate access controls

---

**Welcome to nMapping+ - Professional network mapping made simple!**

*For the latest updates and announcements, visit our [GitHub repository](https://github.com/th3Wheel/nmapping-plus) and star the project to stay informed.*
