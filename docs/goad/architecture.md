# Architecture Details

## Table of Contents

- [Overview](#overview)
- [Physical Infrastructure](#physical-infrastructure)
- [Virtual Infrastructure](#virtual-infrastructure)
- [Network Configuration](#network-configuration)
- [Active Directory Structure](#active-directory-structure)
- [Security and Isolation](#security-and-isolation)
- [Backup Architecture](#backup-architecture)
- [Resource Sizing](#resource-sizing)

## Overview

```
                                         INTERNET
                                            │
                                        HOME GATEWAY
                                            │
    ════════════════════════════════════════╪═══════════════════════════════
                     MANAGEMENT NETWORK - 192.168.50.0/24
    ════════════════════════════════════════╪═══════════════════════════════
                                            │
         ┌──────────────┬──────────────────┼─────────────────┐
         │              │                  │                 │
         ▼              ▼                  ▼                 ▼
    ┌──────────┐  ┌──────────┐     ┌────────────┐    ┌──────────┐
    │   KALI   │  │ SYNOLOGY │     │ PROXMOX VE │    │ pfSense  │
    │ (VMware) │  │  DS923+  │     │ (Beelink)  │    │          │
    │ .50.x    │  │ .50.130  │     │ .50.227    │    │ .50.250  │
    └────┬─────┘  └────┬─────┘     └─────┬──────┘    └────┬─────┘
         │             │                 │                 │
         │  WireGuard  │                 │    ┌────────────┘
         │  10.10.10.2 │                 │    │
         └─────────────┼─────────────────┼────┘
                       │                 │
                       │    ┌────────────┴──────────────────────────┐
                       │    │            PROXMOX VE                 │
                       │    │          192.168.50.227               │
                       │    │                                       │
                       │    │  ┌─────────────────────────────────┐  │
                       │    │  │           BRIDGES               │  │
                       │    │  │  vmbr0 ── LAN (192.168.50.0/24)│  │
                       │    │  │  vmbr1 ── WAN (10.0.0.0/30)    │  │
                       │    │  │  vmbr2 ── MGMT (192.168.1.0/24)│  │
                       │    │  │  vmbr4 ── GOAD (192.168.10.0/24│  │
                       │    │  └─────────────────────────────────┘  │
                       │    │                                       │
                       │    │  ┌─────────────────────────────────┐  │
                       │    │  │       VIRTUAL MACHINES          │  │
                       │    │  │                                 │  │
                       │    │  │  VM 101 : pfSense (Router/FW)  │  │
                       │    │  │  VM 105 : SRV02 (Member Server)│  │
                       │    │  │  VM 106 : DC01 (Forest Root DC)│  │
                       │    │  │  VM 107 : DC02 (Child DC)      │  │
                       │    │  │  VM 108 : SRV03 (Member Server)│  │
                       │    │  │  VM 109 : DC03 (External DC)   │  │
                       │    │  │  VM 110 : PBS (Backup Server)  │  │
                       │    │  │  CT 102 : Provisioning (IaC)   │  │
                       │    │  └─────────────────────────────────┘  │
                       │    └───────────────────────────────────────┘
                       │
                       │ NFS /volume1/Backups
                       ▼
              ┌─────────────────┐
              │  VM 110 - PBS   │
              │  /mnt/synology  │
              └─────────────────┘
```

## Physical Infrastructure

### Hypervisor

| Component | Specification |
|-----------|--------------|
| Model | Beelink EQR6 Mini PC |
| CPU | AMD Ryzen 9 6900HX |
| RAM | 128 GB DDR5 |
| Storage | 1 TB NVMe SSD |
| OS | Proxmox VE 8.x |
| IP | 192.168.50.227 |

### NAS Storage

| Component | Specification |
|-----------|--------------|
| Model | Synology DS923+ |
| Storage | 8 TB (RAID) |
| Protocol | NFS v3/v4 |
| IP | 192.168.50.130 |
| Purpose | PBS backup target |

### Attack Machine

| Component | Specification |
|-----------|--------------|
| Type | VMware Workstation VM |
| OS | Kali Linux 2024.x |
| RAM | 8 GB |
| IP | 192.168.50.x (DHCP) |
| VPN | 10.10.10.2 (WireGuard) |

## Virtual Infrastructure

### Virtual Machines

| VM ID | Name | vCPU | RAM | Disk | Network | Role |
|-------|------|------|-----|------|---------|------|
| 101 | pfSense | 2 | 4 GB | 32 GB | Multi | Firewall / Router / VPN |
| 105 | SRV02 | 2 | 6 GB | 40 GB | vmbr4 | Member Server + MSSQL |
| 106 | DC01 | 2 | 3 GB | 40 GB | vmbr4 | Forest Root Domain Controller |
| 107 | DC02 | 2 | 4 GB | 40 GB | vmbr4 | Child Domain Controller |
| 108 | SRV03 | 2 | 4 GB | 40 GB | vmbr4 | Member Server + MSSQL |
| 109 | DC03 | 2 | 3 GB | 40 GB | vmbr4 | External Forest Domain Controller |
| 110 | PBS | 2 | 2 GB | 32 GB | vmbr0 | Proxmox Backup Server |

### LXC Containers

| CT ID | Name | vCPU | RAM | Network | Role |
|-------|------|------|-----|---------|------|
| 102 | goad-vm | 4 | 4 GB | vmbr2 | Provisioning (Ansible/Terraform) |

### Templates

| VM ID | Name | OS | Purpose |
|-------|------|----|---------|
| 103 | WinServer2019-Template | Windows Server 2019 | GOAD VM cloning |
| 104 | WinServer2016-Template | Windows Server 2016 | GOAD VM cloning |

## Network Configuration

### Proxmox Bridges

| Bridge | Network | Purpose |
|--------|---------|---------|
| vmbr0 | 192.168.50.0/24 | Home LAN (physical) |
| vmbr1 | 10.0.0.0/30 | pfSense WAN (internal) |
| vmbr2 | 192.168.1.0/24 | Management |
| vmbr4 | 192.168.10.0/24 | GOAD Lab (isolated) |

### pfSense Interfaces

| Interface | IP | Bridge | Purpose |
|-----------|-----|--------|---------|
| WAN | 10.0.0.2/30 | vmbr1 | Internal WAN link |
| LAN | 192.168.1.2/24 | vmbr2 | Management access |
| VLAN10 | 192.168.10.1/24 | vmbr4 | GOAD lab gateway |
| PENTEST | 192.168.50.250/24 | vmbr0 | VPN entry point |
| WG_GOAD | 10.10.10.1/24 | tun_wg0 | WireGuard tunnel |

### Traffic Flow

```
Kali (192.168.50.x)
    │
    │ WireGuard UDP 51820
    ▼
pfSense PENTEST (192.168.50.250)
    │
    │ WireGuard Tunnel
    ▼
pfSense WG_GOAD (10.10.10.1)
    │
    │ Internal Routing
    ▼
pfSense VLAN10 (192.168.10.1)
    │
    │ Bridge vmbr4
    ▼
GOAD VMs (192.168.10.10-23)
```

## Active Directory Structure

### Domain Topology

```
SEVENKINGDOMS.LOCAL (Forest Root)
         │
         ├── DC01 (192.168.10.10) — Forest Root Domain Controller
         │
         ├── NORTH.SEVENKINGDOMS.LOCAL (Child Domain, bidirectional trust)
         │       ├── DC02 (192.168.10.11) — Child Domain Controller
         │       └── SRV02 (192.168.10.22) — Member Server + MSSQL
         │
         └── ESSOS.LOCAL (External Forest, bidirectional trust)
                 ├── DC03 (192.168.10.12) — External Forest Domain Controller
                 └── SRV03 (192.168.10.23) — Member Server + MSSQL
```

### Trust Relationships

| Source | Target | Type | Direction |
|--------|--------|------|-----------|
| SEVENKINGDOMS.LOCAL | NORTH.SEVENKINGDOMS.LOCAL | Parent-Child | Bidirectional |
| SEVENKINGDOMS.LOCAL | ESSOS.LOCAL | Forest | Bidirectional |

## Security and Isolation

### Defense in Depth

| Layer | Implementation |
|-------|---------------|
| Physical isolation | GOAD lab on dedicated bridge (vmbr4) |
| Firewall | pfSense with strict inter-zone rules, NAT |
| No direct LAN access | No route from home LAN to GOAD network |
| VPN access control | WireGuard with key-based authentication |
| Network segmentation | Separate VLANs per function |

### Firewall Rules Summary

| Source | Destination | Allowed |
|--------|-------------|---------|
| Home LAN (50.x) | GOAD Lab (10.x) | Denied |
| Kali via WireGuard | GOAD Lab (10.x) | Allowed |
| GOAD Lab (10.x) | Internet | Allowed (via NAT) |
| GOAD Lab (10.x) | Home LAN (50.x) | Denied |

## Backup Architecture

```
┌─────────────┐     API 8007     ┌─────────────┐      NFS       ┌─────────────┐
│   PROXMOX   │ ───────────────► │     PBS     │ ──────────────► │  SYNOLOGY   │
│  .50.227    │                  │  .50.129    │                 │  .50.130    │
│             │    vzdump        │  Datastore: │  /volume1/      │  7.66 TB    │
│  VMs GOAD   │    snapshot      │  "Synology" │  Backups        │             │
└─────────────┘                  └─────────────┘                 └─────────────┘
```

### Retention Policy

| Type | Frequency | Retention | Protection |
|------|-----------|-----------|------------|
| GOLDEN | Manual | Permanent | Write-protected |
| Automated | Daily at 03:00 | 7 daily + 2 weekly | Auto-pruned |

See [Backup Strategy](backup-strategy.md) for full details.

## Resource Sizing

### Current Usage

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| vCPU | 14 cores | 16 cores | 87% |
| RAM | 26 GB | 128 GB | 20% |
| Storage | 304 GB | 1 TB | 30% |

### Recommendations

| Tier | RAM | Storage |
|------|-----|---------|
| Minimum | 32 GB | 500 GB SSD |
| Recommended | 64 GB | 1 TB NVMe |
| Optimal | 128 GB | 2 TB NVMe |
