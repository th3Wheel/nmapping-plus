# nMapping+ API Specification

This document provides an overview of the RESTful API and WebSocket endpoints exposed by the nMapping+ dashboard container.

## REST API Overview
- **Base URL**: `http://<dashboard-ip>/api/`
- **Format**: JSON for all requests and responses
- **Authentication**: (Optional) API key or token-based (future enhancement)

## Core Endpoints

### Devices
- `GET /api/devices` — List all discovered devices
- `GET /api/devices/{ip}` — Get details for a specific device
- `POST /api/devices/scan` — Trigger a new scan (admin only)

### Scans
- `GET /api/scans` — List scan history
- `GET /api/scans/{id}` — Get scan details

### Changes
- `GET /api/changes` — List network changes

### Health
- `GET /api/health` — System health check

## WebSocket API
- **URL**: `ws://<dashboard-ip>/ws/`
- **Purpose**: Real-time push updates for device changes, scan results, and alerts

## Example: Get All Devices
```bash
curl -X GET http://<dashboard-ip>/api/devices
```

## OpenAPI/Swagger
- The API is designed to be compatible with [OpenAPI 3.0](https://swagger.io/specification/).
- Full OpenAPI spec: _Planned for future release._

## References
- [REST API Design Best Practices](https://restfulapi.net/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Flask-RESTful](https://flask-restful.readthedocs.io/)
- [WebSocket API Design](https://ably.com/concepts/websockets)
