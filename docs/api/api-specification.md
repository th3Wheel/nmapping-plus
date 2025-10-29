# nMapping+ REST API Specification

**Version**: 1.0.0  
**Base URL**: `http://localhost:5000/api`  
**Authentication**: Bearer Token (future), currently no auth  
**Format**: JSON

---

## API Overview

The nMapping+ REST API provides programmatic access to network device inventory, scan history, and system status. All responses are in JSON format with consistent error handling.

---

## Response Format

### Success Response

```json
{
  "status": "success",
  "data": { },
  "metadata": {
    "timestamp": "2025-10-19T10:00:00Z",
    "version": "1.0.0"
  }
}
```

### Error Response

```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": { }
  },
  "metadata": {
    "timestamp": "2025-10-19T10:00:00Z",
    "version": "1.0.0"
  }
}
```

---

## Endpoints

### Device Management

#### GET /api/devices

Get list of all discovered network devices.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number for pagination |
| `limit` | integer | 100 | Items per page (max 1000) |
| `device_type` | string | all | Filter by device type |
| `status` | string | all | Filter by status (up/down) |
| `sort` | string | ip_asc | Sort order (ip_asc, ip_desc, hostname_asc, last_seen_desc) |

**Example Request:**

```http
GET /api/devices?page=1&limit=50&device_type=router&status=up
```

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "devices": [
      {
        "id": 1,
        "device_ip": "192.168.1.1",
        "hostname": "router.local",
        "mac_address": "00:11:22:33:44:55",
        "vendor": "Ubiquiti Networks",
        "os_detected": "Linux 5.4",
        "os_confidence": 95,
        "device_type": "router",
        "status": "up",
        "open_ports": [22, 80, 443],
        "service_count": 3,
        "last_seen": "2025-10-19T09:45:00Z",
        "first_seen": "2025-01-01T00:00:00Z",
        "scan_count": 142,
        "tags": ["core", "gateway"]
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 245,
      "items_per_page": 50,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

#### GET /api/devices/{ip}

Get detailed information about a specific device.

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `ip` | string | Device IP address (e.g., 192.168.1.1) |

**Example Request:**

```http
GET /api/devices/192.168.1.1
```

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "device": {
      "id": 1,
      "device_ip": "192.168.1.1",
      "hostname": "router.local",
      "mac_address": "00:11:22:33:44:55",
      "vendor": "Ubiquiti Networks",
      "os_detected": "Linux 5.4",
      "os_confidence": 95,
      "device_type": "router",
      "status": "up",
      "last_seen": "2025-10-19T09:45:00Z",
      "first_seen": "2025-01-01T00:00:00Z",
      "scan_count": 142,
      "tags": ["core", "gateway"],
      "notes": "Main network router",
      "services": [
        {
          "port": 22,
          "protocol": "tcp",
          "service": "ssh",
          "version": "OpenSSH 8.9",
          "product": "OpenSSH",
          "state": "open"
        },
        {
          "port": 80,
          "protocol": "tcp",
          "service": "http",
          "version": "nginx 1.21",
          "product": "nginx",
          "state": "open"
        },
        {
          "port": 443,
          "protocol": "tcp",
          "service": "https",
          "version": "nginx 1.21",
          "product": "nginx",
          "state": "open"
        }
      ],
      "scan_history": {
        "total_scans": 142,
        "recent_scans": [
          {
            "scan_date": "2025-10-19T09:45:00Z",
            "scan_type": "full_scan",
            "duration_seconds": 45,
            "ports_found": 3,
            "changes_detected": 0
          },
          {
            "scan_date": "2025-10-19T08:45:00Z",
            "scan_type": "discovery",
            "duration_seconds": 2,
            "ports_found": 3,
            "changes_detected": 0
          }
        ]
      }
    }
  }
}
```

**Error Response (404 Not Found):**

```json
{
  "status": "error",
  "error": {
    "code": "DEVICE_NOT_FOUND",
    "message": "Device with IP 192.168.1.1 not found"
  }
}
```

#### POST /api/devices/{ip}/tags

Add tags to a device.

**Request Body:**

```json
{
  "tags": ["production", "critical"]
}
```

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "device_ip": "192.168.1.1",
    "tags": ["core", "gateway", "production", "critical"]
  }
}
```

#### DELETE /api/devices/{ip}/tags

Remove tags from a device.

**Request Body:**

```json
{
  "tags": ["production"]
}
```

#### PUT /api/devices/{ip}/notes

Update device notes.

**Request Body:**

```json
{
  "notes": "Main network router - DO NOT REBOOT during business hours"
}
```

---

### Service Management

#### GET /api/services

Get list of all discovered services across all devices.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `port` | integer | - | Filter by port number |
| `service` | string | - | Filter by service name |
| `protocol` | string | - | Filter by protocol (tcp/udp) |
| `device_type` | string | - | Filter by device type |

**Example Request:**

```http
GET /api/services?service=http&protocol=tcp
```

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "services": [
      {
        "device_ip": "192.168.1.1",
        "hostname": "router.local",
        "port": 80,
        "protocol": "tcp",
        "service": "http",
        "version": "nginx 1.21",
        "product": "nginx",
        "state": "open",
        "last_seen": "2025-10-19T09:45:00Z"
      },
      {
        "device_ip": "192.168.1.10",
        "hostname": "server.local",
        "port": 80,
        "protocol": "tcp",
        "service": "http",
        "version": "Apache 2.4",
        "product": "Apache httpd",
        "state": "open",
        "last_seen": "2025-10-19T09:47:00Z"
      }
    ],
    "summary": {
      "total_services": 245,
      "unique_service_types": 42,
      "filtered_results": 2
    }
  }
}
```

---

### Scan Management

#### GET /api/scans

Get scan history.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `start_date` | string | - | ISO 8601 start date |
| `end_date` | string | - | ISO 8601 end date |
| `scan_type` | string | - | Filter by scan type |
| `limit` | integer | 100 | Number of results |

**Example Request:**

```http
GET /api/scans?start_date=2025-10-01&limit=10
```

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "scans": [
      {
        "scan_id": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
        "scan_type": "full_scan",
        "start_time": "2025-10-19T09:00:00Z",
        "end_time": "2025-10-19T09:15:00Z",
        "duration_seconds": 900,
        "subnet": "192.168.1.0/24",
        "devices_found": 42,
        "devices_up": 38,
        "devices_down": 4,
        "new_devices": 1,
        "changed_devices": 3,
        "scanner_version": "1.0.0"
      }
    ]
  }
}
```

#### POST /api/scans/trigger

Manually trigger a network scan.

**Request Body:**

```json
{
  "scan_type": "discovery",
  "subnet": "192.168.1.0/24",
  "priority": "normal"
}
```

**Success Response (202 Accepted):**

```json
{
  "status": "success",
  "data": {
    "scan_id": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
    "status": "queued",
    "estimated_duration": 600,
    "message": "Scan queued for execution"
  }
}
```

#### GET /api/scans/{scan_id}

Get specific scan details.

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "scan": {
      "scan_id": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
      "scan_type": "full_scan",
      "status": "completed",
      "start_time": "2025-10-19T09:00:00Z",
      "end_time": "2025-10-19T09:15:00Z",
      "duration_seconds": 900,
      "subnet": "192.168.1.0/24",
      "devices_found": 42,
      "devices_up": 38,
      "devices_down": 4,
      "new_devices": 1,
      "changed_devices": 3,
      "changes": [
        {
          "device_ip": "192.168.1.50",
          "change_type": "new_device",
          "description": "New printer discovered"
        },
        {
          "device_ip": "192.168.1.10",
          "change_type": "service_change",
          "description": "Port 8080 now open"
        }
      ]
    }
  }
}
```

---

### Statistics & Analytics

#### GET /api/stats/overview

Get overall system statistics.

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "summary": {
      "total_devices": 42,
      "devices_up": 38,
      "devices_down": 4,
      "total_services": 245,
      "unique_service_types": 42,
      "total_scans": 1523,
      "last_scan": "2025-10-19T09:45:00Z"
    },
    "by_device_type": {
      "router": 2,
      "switch": 3,
      "server": 8,
      "workstation": 15,
      "printer": 5,
      "iot": 7,
      "unknown": 2
    },
    "by_os": {
      "Linux": 12,
      "Windows": 10,
      "macOS": 5,
      "Unknown": 15
    },
    "top_services": [
      {"service": "http", "count": 25},
      {"service": "https", "count": 22},
      {"service": "ssh", "count": 18},
      {"service": "smb", "count": 15},
      {"service": "rdp", "count": 8}
    ]
  }
}
```

#### GET /api/stats/timeline

Get device discovery timeline.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `interval` | string | day | Time interval (hour/day/week/month) |
| `days` | integer | 30 | Number of days to include |

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "timeline": [
      {
        "date": "2025-10-19",
        "devices_total": 42,
        "devices_up": 38,
        "devices_down": 4,
        "new_devices": 0,
        "scans_performed": 24
      },
      {
        "date": "2025-10-18",
        "devices_total": 42,
        "devices_up": 39,
        "devices_down": 3,
        "new_devices": 1,
        "scans_performed": 24
      }
    ]
  }
}
```

---

### Synchronization

#### POST /api/sync/trigger

Manually trigger data synchronization from scanner to dashboard.

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "message": "Synchronization triggered",
    "sync_id": "sync-20251019-094500",
    "files_processed": 42,
    "devices_updated": 38,
    "errors": 0
  }
}
```

#### GET /api/sync/status

Get current synchronization status.

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "sync_status": {
      "last_sync": "2025-10-19T09:45:00Z",
      "sync_enabled": true,
      "auto_sync": true,
      "sync_interval": 60,
      "last_sync_duration": 2.5,
      "files_watching": "/dashboard/scanner_data",
      "pending_changes": 0,
      "total_syncs": 1523,
      "failed_syncs": 3,
      "success_rate": 99.8
    }
  }
}
```

---

### Health & Monitoring

#### GET /api/health

System health check endpoint.

**Success Response (200 OK):**

```json
{
  "status": "success",
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "uptime_seconds": 86400,
    "checks": {
      "database": "ok",
      "scanner_data": "ok",
      "file_watcher": "ok",
      "websocket": "ok"
    },
    "timestamp": "2025-10-19T10:00:00Z"
  }
}
```

**Unhealthy Response (503 Service Unavailable):**

```json
{
  "status": "error",
  "error": {
    "code": "SERVICE_UNHEALTHY",
    "message": "One or more health checks failed",
    "details": {
      "database": "ok",
      "scanner_data": "error: Unable to read directory",
      "file_watcher": "warning: High queue depth",
      "websocket": "ok"
    }
  }
}
```

#### GET /api/metrics

Prometheus-compatible metrics endpoint.

**Success Response (200 OK):**

```prometheus
# HELP nmapping_devices_total Total number of discovered devices
# TYPE nmapping_devices_total gauge
nmapping_devices_total 42

# HELP nmapping_devices_up Number of devices currently up
# TYPE nmapping_devices_up gauge
nmapping_devices_up 38

# HELP nmapping_scans_total Total number of scans performed
# TYPE nmapping_scans_total counter
nmapping_scans_total 1523

# HELP nmapping_api_requests_total Total API requests
# TYPE nmapping_api_requests_total counter
nmapping_api_requests_total{endpoint="/api/devices",method="GET",status="200"} 1234

# HELP nmapping_sync_duration_seconds Sync operation duration
# TYPE nmapping_sync_duration_seconds histogram
nmapping_sync_duration_seconds_bucket{le="1"} 450
nmapping_sync_duration_seconds_bucket{le="5"} 1500
nmapping_sync_duration_seconds_bucket{le="10"} 1520
nmapping_sync_duration_seconds_bucket{le="+Inf"} 1523
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `DEVICE_NOT_FOUND` | 404 | Requested device does not exist |
| `INVALID_IP_ADDRESS` | 400 | IP address format is invalid |
| `INVALID_PARAMETER` | 400 | Request parameter is invalid |
| `SCAN_NOT_FOUND` | 404 | Requested scan does not exist |
| `SYNC_FAILED` | 500 | Data synchronization failed |
| `DATABASE_ERROR` | 500 | Database operation failed |
| `SERVICE_UNHEALTHY` | 503 | Service health check failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |

---

## Rate Limiting

API requests are rate limited to prevent abuse:

- **Default Limit**: 60 requests per minute per IP
- **Burst Limit**: 100 requests per minute per IP
- **Headers**: Rate limit information in response headers

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1634645100
```

---

## Pagination

List endpoints support pagination with standard parameters:

| Parameter | Type | Default | Maximum |
|-----------|------|---------|---------|
| `page` | integer | 1 | - |
| `limit` | integer | 100 | 1000 |

Pagination metadata included in responses:

```json
{
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 245,
    "items_per_page": 50,
    "has_next": true,
    "has_prev": false
  }
}
```

---

## WebSocket Events

Real-time updates via WebSocket connection at `/socket.io/`.

### Events from Server

| Event | Description | Data Format |
|-------|-------------|-------------|
| `device_discovered` | New device found | `{device: {...}}` |
| `device_updated` | Device information changed | `{device: {...}, changes: [...]}` |
| `device_offline` | Device went offline | `{device_ip: "...", last_seen: "..."}` |
| `scan_started` | Scan initiated | `{scan_id: "...", scan_type: "..."}` |
| `scan_completed` | Scan finished | `{scan_id: "...", summary: {...}}` |
| `service_change` | Service detected/changed | `{device_ip: "...", service: {...}}` |

### Example WebSocket Client

```javascript
// Connect to WebSocket
const socket = io('http://localhost:5000');

// Listen for device updates
socket.on('device_updated', (data) => {
  console.log('Device updated:', data);
  updateDeviceInUI(data.device);
});

// Listen for new devices
socket.on('device_discovered', (data) => {
  console.log('New device discovered:', data);
  addDeviceToUI(data.device);
});
```

---

## Changelog

### v1.0.0 (2025-10-19)

- Initial API release
- Device management endpoints
- Service discovery endpoints
- Scan management
- Statistics and analytics
- Health monitoring
- WebSocket real-time updates

---

**Document Owner**: API Team  
**Review Date**: Quarterly  
**Next Review**: 2026-01-19
