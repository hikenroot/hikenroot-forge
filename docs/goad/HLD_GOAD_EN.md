# High Level Design — Multi-Forest Active Directory Infrastructure
## GOAD — Game of Active Directory
### Deployed on Proxmox VE 8.4 — HikenRoot Forge Lab

---

| Property | Value |
|----------|-------|
| Author | Nadyr Chouarhi (hik3nR00t) |
| Version | 1.0 |
| Date | February 2026 |
| Environment | Pentest Lab — HikenRoot Forge |
| Hypervisor | Proxmox VE 8.4.14 |
| Status | Operational |

---

## Table of Contents

1. [Objectives](#1-objectives)
2. [AD Logical Architecture](#2-ad-logical-architecture)
3. [Physical Architecture](#3-physical-architecture--infrastructure)
4. [Network Architecture](#4-network-architecture)
5. [Infrastructure as Code](#5-infrastructure-as-code-iac)
6. [Security & Attack Vectors](#6-security--attack-vectors)
7. [Backup & Continuity](#7-backup--continuity)
8. [Limitations & Roadmap](#8-limitations--roadmap)
9. [Glossary](#9-glossary)

---

## 1. Objectives

This document is the **High Level Design (HLD)** of the multi-forest Active Directory infrastructure deployed as part of the GOAD (Game of Active Directory) project on the Proxmox VE 8.4.14 hypervisor within the HikenRoot Forge lab.

Objectives:

- Document the logical and physical architecture of the multi-forest AD environment
- Describe inter-forest and inter-domain trust relationships
- Present infrastructure technical choices (IaC, networking, virtualization)
- Serve as a foundation for the detailed Low Level Design (LLD)
- Provide a training reference for AD attack and defense practice

### Scope

The GOAD environment simulates a realistic enterprise infrastructure composed of **3 interconnected Active Directory domains**, **2 member servers**, deployed via Infrastructure as Code on Proxmox VE.

---

## 2. AD Logical Architecture

### 2.1 Forests and Domains

| VM | Domain FQDN | Role | IP | OS | VMID |
|----|-------------|------|----|----|------|
| DC01 | sevenkingdoms.local | Root DC Forest 1 | 192.168.10.10 | WS 2019 | 106 |
| DC02 | north.sevenkingdoms.local | Child DC Forest 1 | 192.168.10.11 | WS 2019 | 107 |
| SRV02 | north.sevenkingdoms.local | Member Server | 192.168.10.22 | WS 2019 | 105 |
| DC03 | essos.local | Root DC Forest 2 | 192.168.10.12 | WS 2016 | 109 |
| SRV03 | essos.local | Member Server | 192.168.10.23 | WS 2016 | 108 |

### 2.2 Forest Topology

#### Forest 1 — sevenkingdoms.local

```
sevenkingdoms.local (DC01 — 192.168.10.10)
│
└── north.sevenkingdoms.local (DC02 — 192.168.10.11)
    └── SRV02 (192.168.10.22) — member server
```

- Parent-child relationship: automatic bidirectional transitive trust
- Functional level: Windows Server 2016

#### Forest 2 — essos.local

```
essos.local (DC03 — 192.168.10.12)
└── SRV03 (192.168.10.23) — member server
```

- Independent forest — separate security boundary from Forest 1
- Functional level: Windows Server 2016

#### Cross-Forest Trust Relationships

```
sevenkingdoms.local  ◄──── Bidirectional Trust ────►  essos.local
```

> **Key attack vector**: trust exploitation for cross-forest lateral movement

### 2.3 FSMO Roles

| FSMO Role | Owner | Domain |
|-----------|-------|--------|
| Schema Master | DC01 | sevenkingdoms.local |
| Domain Naming Master | DC01 | sevenkingdoms.local |
| PDC Emulator | DC01 | sevenkingdoms.local |
| RID Master | DC01 | sevenkingdoms.local |
| Infrastructure Master | DC01 | sevenkingdoms.local |
| PDC Emulator | DC02 | north.sevenkingdoms.local |
| PDC Emulator | DC03 | essos.local |

---

## 3. Physical Architecture & Infrastructure

### 3.1 Proxmox VE Hypervisor

| Property | Value |
|----------|-------|
| Host | proxmox (192.168.50.227/24) |
| Version | Proxmox VE 8.4.14 |
| Total RAM | 58 GB — 42 GB used under normal load |
| Storage | local (dir) 958 GB / 22% used \| PBS backup 7.48 TB |
| Network | eno1 (physical) — 6 virtual bridges (vmbr0 to vmbr5) |

### 3.2 GOAD VM Inventory

| VMID | Name | Role | RAM | vCPU | Disk | Network |
|------|------|------|-----|------|------|---------|
| 100 | GOAD-VM | IaC Jump Host / Attacker | 10 GB | 4 | 100 GB | vmbr4 + vmbr0 |
| 101 | VM 101 | pfSense Firewall/GW | 4 GB | 1 | 32 GB | vmbr1/2/3/4/5 |
| 105 | SRV02 | north.sevenkingdoms member | 6.2 GB | 2 | 40 GB | vmbr4 tag10 |
| 106 | DC01 | DC sevenkingdoms.local | 3 GB | 2 | 40 GB | vmbr4 tag10 |
| 107 | DC02 | DC north.sevenkingdoms.local | 4 GB | 2 | 40 GB | vmbr4 tag10 |
| 108 | SRV03 | essos.local member | 4 GB | 2 | 40 GB | vmbr4 tag10 |
| 109 | DC03 | DC essos.local | 3 GB | 2 | 40 GB | vmbr4 tag10 |
| 110 | PBS | Proxmox Backup Server | 2 GB | 2 | 32 GB | vmbr0 |
| 120 | docker-weblab | Web Lab (Docker) | 8 GB | 4 | 80 GB | vmbr4 tag20 |

---

## 4. Network Architecture

### 4.1 Segmentation — Proxmox Bridges

| Bridge | Subnet | Role | VLAN Tag |
|--------|--------|------|----------|
| vmbr0 | 192.168.50.x/24 | Proxmox Management (physical LAN) | — |
| vmbr1 | 10.0.0.0/30 | Proxmox WAN → pfSense | — |
| vmbr2 | — | pfSense external WAN | — |
| vmbr3 | 192.168.1.x/24 | pfSense internal LAN | — |
| vmbr4 | 192.168.10.x/24 | GOAD Network (AD Lab) | Tag 10 |
| vmbr5 | — | Web Lab | Tag 20 |

### 4.2 IP Addressing — GOAD Network (192.168.10.0/24)

| Host | IP | Role | Notes |
|------|----|------|-------|
| Proxmox (vmbr4) | 192.168.10.1 | Gateway / DNS forwarder | Lab DNS |
| DC01 | 192.168.10.10 | DC sevenkingdoms.local | Schema Master, PDC, DNS |
| DC02 | 192.168.10.11 | DC north.sevenkingdoms.local | PDC Emulator north, DNS |
| DC03 | 192.168.10.12 | DC essos.local | PDC Emulator essos, DNS |
| SRV02 | 192.168.10.22 | north.sevenkingdoms member | Application server |
| SRV03 | 192.168.10.23 | essos.local member | Application server |
| GOAD-VM | 192.168.10.x | Jump Host / Attacker | Kali Linux — offensive tooling |

### 4.3 Network Diagram

```
Internet
    │
  vmbr2 (external WAN)
    │
[VM101 — pfSense]
    │
  vmbr1 (10.0.0.0/30) ──── Proxmox Host (192.168.50.227)
    │                              │
  vmbr3 (192.168.1.0/24)        vmbr0 (Management)
    │
  vmbr4 (192.168.10.0/24) — GOAD AD Lab
    ├── DC01  192.168.10.10  (sevenkingdoms.local)
    ├── DC02  192.168.10.11  (north.sevenkingdoms.local)
    ├── DC03  192.168.10.12  (essos.local)
    ├── SRV02 192.168.10.22
    ├── SRV03 192.168.10.23
    └── GOAD-VM (Attacker / Jump Host)

  vmbr5 (Web Lab)
    └── docker-weblab (VLAN 20)
```

---

## 5. Infrastructure as Code (IaC)

### 5.1 Deployment Pipeline

| Step | Tool | Role | Description |
|------|------|------|-------------|
| 1 | **Packer** | Build VM templates | Creates Windows Server 2016/2019 images with sysprep, WinRM enabled |
| 2 | **Terraform** | VM provisioning | Deploys VMs on Proxmox — VMID, RAM, vCPU, network, disk |
| 3 | **Ansible** | AD configuration | Installs AD DS, creates domains/forests, configures trusts, GPOs, users, intentional vulnerabilities |

### 5.2 Windows Templates

| Template | VMID | OS | Used for |
|----------|------|----|----------|
| WinServer2019x64-cloudinit | 103 | Windows Server 2019 | Base for DC01, DC02, SRV02 |
| WinServer2016x64-cloudinit | 104 | Windows Server 2016 | Base for DC03, SRV03 |

### 5.3 Workspace Structure

```
/home/hiken/GOAD/
├── workspace/
│   └── d0536f-goad-proxmox/
│       └── inventory          # Host/IP/domain mapping
├── extensions/
│   ├── wazuh/                 # Blue Team extension (planned)
│   ├── exchange/              # Exchange extension (planned)
│   ├── lx01/                  # Linux extension (planned)
│   └── ws01/                  # Workstation extension (planned)
└── venv/                      # Ansible Python environment
```

---

## 6. Security & Attack Vectors

### 6.1 Purpose

GOAD is an **intentionally vulnerable** environment designed for Active Directory attack and defense practice. Vulnerabilities are deliberately configured via Ansible to simulate real-world misconfigurations found in enterprise environments.

### 6.2 Attack Vectors Covered

| Vector | Technique | Target |
|--------|-----------|--------|
| Kerberos Attacks | Kerberoasting, AS-REP Roasting | Service accounts with SPNs |
| Credential Theft | Pass-the-Hash, Pass-the-Ticket | Domain hosts |
| Privilege Escalation | ACL/ACE Abuse, GPO Abuse | Misconfigured AD objects |
| Domain Dominance | DCSync, Golden/Silver Ticket | DC01, DC02, DC03 |
| Lateral Movement | Cross-forest Trust Abuse | sevenkingdoms ↔ essos |
| Reconnaissance | BloodHound, ldapdomaindump | Entire lab |

### 6.3 Network Isolation

- GOAD environment is isolated on vmbr4 (192.168.10.0/24) with no direct Internet access
- pfSense (VM101) handles filtering and routing between segments
- Proxmox management network (vmbr0) is separated from the lab

---

## 7. Backup & Continuity

| Component | Details |
|-----------|---------|
| PBS VM | VMID 110 — 2 GB RAM — 32 GB disk |
| PBS Storage | 7.48 TB available — 1.75% used |

- Proxmox snapshots of GOAD VMs before each attack session
- Fast restore after full lab compromise
- PBS provides backup retention with deduplication

---

## 8. Limitations & Roadmap

### Current Limitations

- No active monitoring/SIEM on the GOAD segment (Wazuh planned for Phase 2)
- Windows templates in stopped mode — provisioned on demand
- Exchange extension not deployed
- Detailed LLD to be produced

### Planned Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | GOAD AD Lab infrastructure | ✅ Operational (~80%) |
| Phase 2 | Wazuh / Security Onion — Blue Team | 🔄 Planned |
| Phase 2 | GOAD extensions (lx01, ws01, Exchange) | 🔄 Planned |
| Phase 3 | Cloud Lab — Kubernetes K3s (VLAN 30) | 🔄 Planned |
| Phase 3 | AI/LLM Stack — RTX PRO 4000 Blackwell 24 GB (VLAN 40) | 🔄 Planned |
| Phase 4 | Full LLD + GitBook documentation | 🔄 Planned |

---

## 9. Glossary

| Term | Definition |
|------|-----------|
| AD DS | Active Directory Domain Services — Microsoft directory service |
| DC | Domain Controller |
| FSMO | Flexible Single Master Operations — single-instance AD roles |
| GOAD | Game of Active Directory — open source pentest lab (Orange Cyberdefense) |
| HLD | High Level Design — macro architecture document |
| IaC | Infrastructure as Code — infrastructure deployment automation |
| LLD | Low Level Design — detailed architecture document |
| Trust | Approval relationship between AD domains/forests enabling cross-domain authentication |
| WinRM | Windows Remote Management — Windows remote management protocol |

---

*Document produced by hik3nR00t — HikenRoot Forge Lab*
