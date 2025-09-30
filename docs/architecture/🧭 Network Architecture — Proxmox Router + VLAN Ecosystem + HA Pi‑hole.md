# 🧭 Network Infrastructure — Proxmox Router + VLAN Ecosystem + HA Pi‑hole

## 1. Visual Topology Diagram
```
                          [Internet]
                              │
                      [ISP Modem - Bridge Mode]
                              │
                        [Proxmox Host]
                    ┌────────────┬────────────┐
                    │ vmbr0 (WAN)│ vmbr1 (LAN trunk, VLAN-aware)
                    │           │
                    ▼           ▼
         [LXC Router CT]   [Managed Switches]
                              │
        ┌────────────────────────────────────────────────────────────┐
        │ VLAN 10 — IoT           → SSID: CylonSynthLink             │
        │ VLAN 20 — Main LAN      → SSID: Battlestar Ventana         │
        │ VLAN 30 — Guest         → SSID: Colonial Guest Portal      │
        │ VLAN 40 — Security      → SSID: (TBD)                      │
        │ VLAN 50 — AirPlay       → SSID: (TBD)                      │
        └────────────────────────────────────────────────────────────┘
                              │
        ┌────────────────────────────────────────────────────────────┐
        │ TL-SG1016PE (16-port PoE)                                  │
        │ GPS 208 (8+2-port PoE)                                     │
        │ TL-SG105E (5-port VLAN-aware)                              │
        │ TL-SG108E (8-port VLAN-aware)                              │
        │ GS108 x2 (PoE-powered via uplink port 1)                   │
        └────────────────────────────────────────────────────────────┘
                              │
        ┌────────────────────────────────────────────────────────────┐
        │ Pi-hole 1: 10.20.20.11                                     │
        │ Pi-hole 2: 10.20.20.12                                     │
        │ VIP:      10.20.20.10 (keepalived failover)                │
        └────────────────────────────────────────────────────────────┘
```

---

## 2. VLAN & SSID Mapping

| VLAN | SSID Name               | Purpose                        | DHCP Range              | Gateway       | DNS Server     |
|------|-------------------------|--------------------------------|--------------------------|---------------|----------------|
| 10   | `CylonSynthLink`        | IoT devices                    | 10.10.10.50–200         | 10.10.10.1    | 10.20.20.10    |
| 20   | `Battlestar Ventana`    | Main LAN                       | 10.20.20.50–200         | 10.20.20.1    | 10.20.20.10    |
| 30   | `Colonial Guest Portal` | Guest network                  | 10.30.30.50–200         | 10.30.30.1    | 10.20.20.10    |
| 40   | *(TBD)*                 | Security devices               | 10.40.40.50–200         | 10.40.40.1    | 10.20.20.10    |
| 50   | *(TBD)*                 | AirPlay/media devices          | 10.50.50.50–200         | 10.50.50.1    | 10.20.20.10    |

---

## 3. Firewall Policy

| VLAN | Internet | LAN Access         | Notes                                  |
|------|----------|--------------------|----------------------------------------|
| 10   | ✅ Yes   | 🔒 Pi-hole only    | IoT isolation                          |
| 20   | ✅ Yes   | ✅ Full            | Trusted devices                        |
| 30   | ✅ Yes   | ❌ None            | Guest isolation + shaping              |
| 40   | ❌ No    | 🔒 NVR only        | Security VLAN                          |
| 50   | ✅ Yes   | ✅ AirPlay only    | mDNS reflected, media ports allowed    |

---

## 4. Guest Bandwidth Shaping

- **Default cap:** 25 Mbps down / 2.5 Mbps up (5% of WAN)
- **Whitelist bypass:** Static IPs in `GUEST_WHITELIST_IPS` get full speed

```text
Whitelisted IPs:
- 10.30.30.50
- 10.30.30.51
```

---

## 5. Pi‑hole High Availability

- **Pi‑hole 1:** 10.20.20.11  
- **Pi‑hole 2:** 10.20.20.12  
- **VIP:** 10.20.20.10 (served via keepalived VRRP)  
- **Failover:** Automatic within ~2s  
- **DHCP/DNS:** All clients point to VIP

---

## 6. Switching Layer Details

### TL‑SG1016PE (16-port PoE)
- Ports 1–8: PoE for APs, cameras, sensors
- Ports 9–16: Trunk uplinks, wired clients

### GPS 208 (8+2-port PoE)
- Ports 1–8: PoE for APs or edge switches
- Ports 9–10: Uplink to TL‑SG1016PE or router

### TL‑SG105E / TL‑SG108E
- VLAN-aware trunking between router and APs
- Access ports for Pi‑hole, management, AirPlay

### GS108 x2
- PoE-powered via uplink port 1
- Used for edge expansion or isolated VLAN drops

---

## 7. Deployment Summary

- **Router CT (ID 210):** Debian LXC with VLAN NICs, NAT, firewall, DHCP relay, shaping
- **Pi‑hole CTs (IDs 220 & 221):** Debian LXCs with keepalived, DHCP/DNS, VIP failover
- **Switches:** VLAN trunking, access port segmentation, PoE delivery
- **APs:** SSID → VLAN mapping, mDNS support for AirPlay VLAN

---

## 8. Cutover Steps

1. Power down Deco mesh
2. Put modem in bridge mode
3. Connect modem → Proxmox WAN NIC
4. Connect Proxmox LAN NIC → switch trunk port
5. Boot router + Pi‑hole CTs
6. Confirm VIP responds, DHCP leases issued
7. Reboot clients and validate VLAN behavior

---

## 9. Maintenance

- Update Pi‑hole blocklists on both nodes
- Adjust whitelist in `/etc/router-env` on router CT
- Snapshot CTs after config changes
- Monitor keepalived status and failover events

---

## 10. Change Log

| Date       | Change                                      |
|------------|---------------------------------------------|
| 2025-09-14 | Initial deployment script created            |
| 2025-09-14 | Guest shaping + whitelist logic added        |
| 2025-09-14 | Avahi reflector enabled for AirPlay VLAN     |
| 2025-09-15 | Switch hardware mapped and port plan added   |
| 2025-09-16 | Final master doc consolidated                |