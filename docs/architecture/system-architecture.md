# nMapping+ System Architecture

**Version**: 1.0.0  
**Last Updated**: 2025-10-19  
**Status**: 🔵 Design Complete

---

## Overview

nMapping+ is a network monitoring and inventory management system consisting of a network scanner component and a web dashboard component that work together to provide real-time visibility into network device inventory, services, and changes.

---

## High-Level Architecture

```mermaid
graph TB
    subgraph "Network Scanner"
        NS[Scanner Daemon]
        NM[Nmap Engine]
        MG[Markdown Generator]
        GIT[Git Integration]
    end
    
    subgraph "Data Layer"
        MD[Scanner Data<br/>Markdown Files]
        REPO[Git Repository]
        DB[(SQLite Database)]
    end
    
    subgraph "Dashboard Application"
        FW[File Watcher]
        SYNC[Sync Manager]
        API[REST API]
        WS[WebSocket Server]
        WEB[Web Interface]
    end
    
    subgraph "External"
        NET[Network Devices]
        BROWSER[Web Browser]
        MON[Monitoring<br/>Systems]
    end
    
    NET -->|Network Scans| NM
    NM -->|XML Results| NS
    NS -->|Device Data| MG
    MG -->|Markdown Files| MD
    MD -->|Git Commits| REPO
    REPO -->|Changes| GIT
    
    MD -->|File Changes| FW
    FW -->|Sync Trigger| SYNC
    SYNC -->|Parse & Validate| DB
    DB -->|Query| API
    API -->|REST| BROWSER
    WS -->|Real-time Updates| BROWSER
    BROWSER -->|HTTP/WS| WEB
    
    API -->|Metrics| MON
    
    style NS fill:#e1f5ff
    style API fill:#fff4e1
    style DB fill:#ffe1e1
```

---

## Component Architecture

### Scanner Component

```mermaid
classDiagram
    class NmapScanner {
        +subnet: str
        +scan_interval: int
        +output_dir: Path
        +discover_devices()
        +port_scan(ip: str)
        +service_scan(ip: str)
        +os_detection(ip: str)
        -parse_xml(xml_data)
    }
    
    class MarkdownGenerator {
        +schema: JSONSchema
        +template_dir: Path
        +generate(device_data: Dict)
        +validate(device_data: Dict)
        -format_frontmatter()
        -format_content()
    }
    
    class ScannerDaemon {
        +scanner: NmapScanner
        +generator: MarkdownGenerator
        +config: Config
        +run()
        +schedule_scan()
        -commit_to_git()
    }
    
    class GitIntegration {
        +repo_path: Path
        +commit(files: List)
        +push()
        +get_changes()
    }
    
    ScannerDaemon --> NmapScanner
    ScannerDaemon --> MarkdownGenerator
    ScannerDaemon --> GitIntegration
    NmapScanner --> MarkdownGenerator
```

### Dashboard Component

```mermaid
classDiagram
    class FlaskApp {
        +routes: List
        +socketio: SocketIO
        +init_app()
        +run()
    }
    
    class SyncManager {
        +file_watcher: FileWatcher
        +validator: Validator
        +db: Database
        +sync_file(file: Path)
        +sync_directory(dir: Path)
        +emit_changes()
    }
    
    class FileWatcher {
        +watch_dir: Path
        +observer: Observer
        +callback: Callable
        +start()
        +stop()
    }
    
    class Validator {
        +schema: JSONSchema
        +validate_file(file: Path)
        +validate_metadata(data: Dict)
    }
    
    class Database {
        +connection: sqlite3.Connection
        +migrate()
        +upsert_device(device: Device)
        +query_devices(filters: Dict)
        +get_statistics()
    }
    
    class WebSocketServer {
        +socketio: SocketIO
        +emit_update(event: str, data: Dict)
        +broadcast(message: str)
    }
    
    FlaskApp --> SyncManager
    FlaskApp --> WebSocketServer
    FlaskApp --> Database
    SyncManager --> FileWatcher
    SyncManager --> Validator
    SyncManager --> Database
    SyncManager --> WebSocketServer
```

---

## Data Flow Architecture

### Scan to Dashboard Flow

```mermaid
sequenceDiagram
    participant N as Network Devices
    participant S as Scanner
    participant M as Markdown Gen
    participant F as File System
    participant G as Git
    participant W as File Watcher
    participant V as Validator
    participant D as Database
    participant WS as WebSocket
    participant B as Browser
    
    S->>N: Network Scan
    N-->>S: Scan Results (XML)
    S->>M: Parse & Transform
    M->>F: Write Markdown File
    F->>G: Git Commit
    
    F->>W: File Change Event
    W->>V: Validate File
    
    alt Validation Success
        V->>D: Update Database
        D->>WS: Emit Change Event
        WS->>B: Push Update
        B->>B: Refresh UI
    else Validation Failed
        V->>W: Log Error
        W->>W: Skip Update
    end
```

### API Request Flow

```mermaid
sequenceDiagram
    participant B as Browser
    participant A as API Endpoint
    participant V as Validator
    participant D as Database
    participant C as Cache
    
    B->>A: HTTP GET /api/devices
    A->>A: Auth Check
    A->>C: Check Cache
    
    alt Cache Hit
        C-->>A: Cached Data
    else Cache Miss
        A->>D: Query Database
        D-->>A: Query Results
        A->>C: Update Cache
    end
    
    A->>V: Validate Response
    V-->>A: Valid Response
    A-->>B: JSON Response
```

---

## Deployment Architecture

### Single Host Deployment

```mermaid
graph TB
    subgraph "Proxmox Host"
        subgraph "LXC Container"
            NGINX[Nginx Reverse Proxy<br/>:80/:443]
            DASH[Dashboard Service<br/>:5000]
            SCAN[Scanner Service]
            SCHED[Scanner Timer]
            
            subgraph "Data"
                DB[(Database<br/>SQLite)]
                FILES[Scanner Data<br/>Markdown Files]
                LOGS[Log Files]
            end
        end
    end
    
    subgraph "Network"
        NET[Network Devices<br/>192.168.1.0/24]
    end
    
    subgraph "Monitoring"
        PROM[Prometheus]
        GRAF[Grafana]
    end
    
    NET -->|Nmap Scans| SCAN
    SCAN --> FILES
    FILES --> DASH
    DASH --> DB
    NGINX --> DASH
    SCHED -.triggers.-> SCAN
    
    DASH -->|Metrics| PROM
    SCAN -->|Metrics| PROM
    PROM --> GRAF
    
    style NGINX fill:#66b3ff
    style DASH fill:#ff9999
    style SCAN fill:#99ff99
    style DB fill:#ffcc99
```

### High Availability Deployment

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[HAProxy / Nginx]
    end
    
    subgraph "Dashboard Cluster"
        D1[Dashboard Node 1]
        D2[Dashboard Node 2]
        D3[Dashboard Node 3]
    end
    
    subgraph "Scanner Cluster"
        S1[Scanner Node 1<br/>Subnet A]
        S2[Scanner Node 2<br/>Subnet B]
        S3[Scanner Node 3<br/>Subnet C]
    end
    
    subgraph "Data Layer"
        DBMAIN[(Primary DB)]
        DBREP[(Replica DB)]
        SHARE[Shared Storage<br/>NFS/Ceph]
    end
    
    LB --> D1
    LB --> D2
    LB --> D3
    
    D1 --> DBMAIN
    D2 --> DBMAIN
    D3 --> DBMAIN
    
    DBMAIN --> DBREP
    
    S1 --> SHARE
    S2 --> SHARE
    S3 --> SHARE
    
    SHARE --> D1
    SHARE --> D2
    SHARE --> D3
```

---

## Security Architecture

### Security Layers

```mermaid
graph TD
    subgraph "External Access"
        EXT[Internet]
        FW[Firewall]
    end
    
    subgraph "Application Security"
        SSL[SSL/TLS Termination]
        AUTH[Authentication]
        AUTHZ[Authorization]
        RBAC[Role-Based Access]
        RATE[Rate Limiting]
    end
    
    subgraph "Application Layer"
        API[REST API]
        WS[WebSocket]
    end
    
    subgraph "Data Security"
        VAL[Input Validation]
        ENC[Encryption at Rest]
        AUDIT[Audit Logging]
        BACKUP[Encrypted Backups]
    end
    
    subgraph "Network Security"
        SEG[Network Segmentation]
        IDS[Intrusion Detection]
        MON[Security Monitoring]
    end
    
    EXT --> FW
    FW --> SSL
    SSL --> AUTH
    AUTH --> AUTHZ
    AUTHZ --> RBAC
    RBAC --> RATE
    RATE --> API
    RATE --> WS
    
    API --> VAL
    WS --> VAL
    VAL --> ENC
    ENC --> AUDIT
    AUDIT --> BACKUP
    
    API -.-> SEG
    WS -.-> SEG
    SEG --> IDS
    IDS --> MON
```

---

## Technology Stack

### Core Technologies

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Scanner** | Python 3.9+ | Core scanner application |
| | Nmap 7.80+ | Network scanning engine |
| | python-nmap | Nmap Python wrapper |
| | python-frontmatter | YAML frontmatter parsing |
| **Dashboard** | Flask 3.0 | Web application framework |
| | Flask-SocketIO | WebSocket support |
| | Gunicorn | WSGI HTTP server |
| | eventlet | Async worker |
| **Database** | SQLite 3.35+ | Embedded database |
| | WAL mode | Write-ahead logging |
| **Data Format** | Markdown | Device documentation |
| | YAML | Frontmatter metadata |
| | JSON Schema | Validation |
| **Version Control** | Git | Change tracking |
| **Process Management** | systemd | Service management |
| **Web Server** | Nginx | Reverse proxy (optional) |

### Development Tools

| Category | Tools |
|----------|-------|
| **Testing** | pytest, pytest-cov, pytest-flask |
| **Code Quality** | black, ruff, mypy, pylint |
| **Documentation** | Sphinx, MkDocs |
| **Monitoring** | Prometheus, Grafana |
| **CI/CD** | GitHub Actions |

---

## Performance Architecture

### Scalability Targets

| Metric | Target | Notes |
|--------|--------|-------|
| **Devices Monitored** | 1,000+ | Per scanner instance |
| **Scan Frequency** | 1-60 minutes | Configurable |
| **Dashboard Load Time** | < 2 seconds | Initial page load |
| **API Response Time** | < 200ms (p95) | Most endpoints |
| **WebSocket Latency** | < 100ms | Real-time updates |
| **Database Size** | 100MB-1GB | With 1 year history |
| **Memory Usage (Dashboard)** | < 512MB | Per instance |
| **Memory Usage (Scanner)** | < 256MB | Per instance |

### Performance Optimizations

```mermaid
graph LR
    subgraph "Scanner Optimization"
        P1[Parallel Scanning]
        P2[Scan Batching]
        P3[Result Caching]
    end
    
    subgraph "Database Optimization"
        D1[Indexes on Key Fields]
        D2[WAL Mode]
        D3[Query Optimization]
        D4[Connection Pooling]
    end
    
    subgraph "Dashboard Optimization"
        W1[Response Caching]
        W2[Asset Minification]
        W3[Lazy Loading]
        W4[WebSocket Efficiency]
    end
    
    P1 --> D1
    P2 --> D2
    P3 --> W1
    
    style P1 fill:#d4f1d4
    style D1 fill:#ffd4d4
    style W1 fill:#d4d4ff
```

---

## Integration Architecture

### External System Integration

```mermaid
graph TB
    subgraph "nMapping+"
        API[REST API]
        WH[Webhooks]
        EXPORT[Data Export]
    end
    
    subgraph "Monitoring Systems"
        PROM[Prometheus]
        ZABBIX[Zabbix]
        NAGIOS[Nagios]
    end
    
    subgraph "IT Management"
        CMDB[CMDB]
        ITSM[ITSM Platform]
        ASSET[Asset Management]
    end
    
    subgraph "Security Systems"
        SIEM[SIEM]
        VULN[Vulnerability Scanner]
        IDS[IDS/IPS]
    end
    
    API -->|Metrics Endpoint| PROM
    API -->|Device API| ZABBIX
    WH -->|Alerts| NAGIOS
    
    EXPORT -->|Device Data| CMDB
    EXPORT -->|Change Events| ITSM
    EXPORT -->|Inventory| ASSET
    
    API -->|Device Logs| SIEM
    EXPORT -->|Open Ports| VULN
    WH -->|New Devices| IDS
```

---

## Disaster Recovery Architecture

### Backup Strategy

```mermaid
graph TB
    subgraph "Primary System"
        DB[(Database)]
        FILES[Scanner Data]
        CONFIG[Configuration]
    end
    
    subgraph "Local Backups"
        BDB[(DB Backup)]
        BFILES[Data Backup]
        BCONFIG[Config Backup]
    end
    
    subgraph "Remote Backups"
        REMOTE[(Remote Storage)]
        OFFSITE[Offsite Backup]
    end
    
    DB -->|Daily| BDB
    FILES -->|Continuous| BFILES
    CONFIG -->|On Change| BCONFIG
    
    BDB -->|Encrypted| REMOTE
    BFILES -->|Compressed| REMOTE
    BCONFIG -->|Encrypted| REMOTE
    
    REMOTE -->|Weekly| OFFSITE
    
    style DB fill:#ff9999
    style BDB fill:#99ff99
    style REMOTE fill:#9999ff
```

### Recovery Procedures

| Scenario | RTO | RPO | Procedure |
|----------|-----|-----|-----------|
| **Service Crash** | 5 minutes | 0 | Systemd auto-restart |
| **Database Corruption** | 30 minutes | 1 hour | Restore from local backup |
| **Data Loss** | 2 hours | 24 hours | Restore from remote backup |
| **Host Failure** | 4 hours | 24 hours | Deploy to new host |
| **Site Disaster** | 24 hours | 1 week | Restore from offsite backup |

---

## Monitoring Architecture

### Metrics Collection

```mermaid
graph LR
    subgraph "Application Metrics"
        S[Scanner Metrics]
        D[Dashboard Metrics]
        DB[(Database Metrics)]
    end
    
    subgraph "System Metrics"
        CPU[CPU Usage]
        MEM[Memory Usage]
        DISK[Disk I/O]
        NET[Network I/O]
    end
    
    subgraph "Collection"
        PROM[Prometheus]
        EXPORT[Node Exporter]
    end
    
    subgraph "Visualization"
        GRAF[Grafana]
        ALERT[Alertmanager]
    end
    
    S -->|/metrics| PROM
    D -->|/metrics| PROM
    DB -->|/metrics| PROM
    
    CPU --> EXPORT
    MEM --> EXPORT
    DISK --> EXPORT
    NET --> EXPORT
    
    EXPORT --> PROM
    PROM --> GRAF
    PROM --> ALERT
```

---

## Future Architecture Considerations

### Potential Enhancements

1. **Multi-Tenant Support**
   - Separate data isolation per tenant
   - Per-tenant RBAC
   - Resource quotas

2. **Microservices Migration**
   - Split scanner and dashboard
   - API gateway
   - Service mesh

3. **Cloud Native**
   - Kubernetes deployment
   - Horizontal auto-scaling
   - Cloud storage backends

4. **Advanced Features**
   - Machine learning for anomaly detection
   - Predictive maintenance
   - Advanced network mapping
   - Integration marketplace

---

## Conclusion

This architecture provides a solid foundation for the nMapping+ v1.0 release while allowing for future growth and enhancement. The modular design enables independent scaling of scanner and dashboard components, while the well-defined data contracts ensure maintainability.

---

**Document Owner**: Architecture Team  
**Review Date**: Quarterly  
**Next Review**: 2026-01-19
