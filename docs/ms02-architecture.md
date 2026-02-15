# MS-02 Ultra — Architecture Overview

## Hardware

```
┌─────────────────────────────────────────────────────────────┐
│                    MS-02 ULTRA                               │
│                                                              │
│  CPU: Intel Core Ultra 9 285HX (24C/24T)                    │
│  RAM: 192 GB DDR5 ECC                                       │
│  Storage: 9 TB NVMe (3x 2TB + 1x 4TB)                      │
│  GPU: NVIDIA RTX PRO 4000 Blackwell (24GB GDDR7 ECC)       │
│                                                              │
│  Network:                                                    │
│  ├── nic1: Intel I226 — RJ45 2.5G (backup, unused)         │
│  ├── nic2: Intel E810 — SFP+ 10G (active, DAC 10Gtek)      │
│  └── nic3: Intel E810 — SFP+ 10G (available)               │
└─────────────────────────────────────────────────────────────┘
```

## Software Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    PROXMOX VE 9.1.5                          │
│                Kernel 6.14.11-5-pve                          │
│                  Secure Boot: ON                             │
│                                                              │
│  ┌──────────────────────┐   ┌────────────────────────────┐  │
│  │     NVIDIA GPU        │   │         DOCKER             │  │
│  │  Driver 570.133.07    │   │  NVIDIA Container Toolkit  │  │
│  │  CUDA 12.8            │   │  GPU-accelerated           │  │
│  │  MOK Signed Modules   │   │  containers                │  │
│  │                        │   │                            │  │
│  │  ┌──────────────────┐ │   │  ┌──────────────────────┐  │  │
│  │  │     OLLAMA       │ │   │  │  Future workloads:   │  │  │
│  │  │  Native host     │ │   │  │  - Garak (LLM test)  │  │  │
│  │  │  Port 11434      │ │   │  │  - Jupyter notebooks  │  │  │
│  │  │  100% GPU        │ │   │  │  - Custom AI tools    │  │  │
│  │  │                  │ │   │  └──────────────────────┘  │  │
│  │  │  Models:         │ │   └────────────────────────────┘  │
│  │  │  deepseek-r1:8b  │ │                                   │
│  │  │  (more planned)  │ │                                   │
│  │  └──────────────────┘ │                                   │
│  └──────────────────────┘                                    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    VMs / CTs                          │   │
│  │  (Phase 2: Cloud Lab, SOC Lab, DFIR)                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Network Architecture

```
                          INTERNET
                              │
                         HOME GATEWAY
                              │
══════════════════════════════╪════════════════════════════════
              MANAGEMENT NETWORK — 192.168.50.0/24
══════════════════════════════╪════════════════════════════════
         │                    │                    │
         ▼                    ▼                    ▼
   ┌──────────┐        ┌──────────┐         ┌──────────┐
   │ BEELINK  │        │ MIKROTIK │         │ MS-02    │
   │ .50.227  │◄──────►│CSS610-8P │◄───────►│ .50.228  │
   │          │  1G    │ -2S+IN   │  10G    │          │
   │ GOAD     │  RJ45  │          │  DAC    │ AI Lab   │
   │ WebLab   │        │          │  SFP+   │ CloudLab │
   │ pfSense  │        └──────────┘         │ SOC Lab  │
   └──────────┘                             └──────────┘
```

## VLAN Segmentation (MS-02)

```
vmbr0 (bridge-vlan-aware, bridge-ports nic2)
│
├── VLAN 30 — Cloud Lab (192.168.30.0/24)
│   └── K3s clusters, Kubeadm, container security
│
├── VLAN 40 — AI Lab (192.168.40.0/24)
│   └── Ollama API, LLM security research, Garak
│
└── VLAN 50 — Management (192.168.50.0/24)
    └── Proxmox web UI, SSH, backup traffic
```

## Routing

```
MS-02 (VLAN 30/40)
    │
    │ SFP+ 10G DAC
    ▼
MikroTik CSS610
    │
    │ RJ45 1G
    ▼
Beelink — pfSense (.50.250)
    │
    ├── VLAN 10 (192.168.10.0/24) → GOAD AD Lab
    ├── VLAN 20 (192.168.20.0/24) → Web Lab
    ├── VLAN 30 (192.168.30.0/24) → Cloud Lab (MS-02)
    ├── VLAN 40 (192.168.40.0/24) → AI Lab (MS-02)
    └── NAT → Internet
```

## Security

```
┌─────────────────────────────────────────┐
│            SECURITY LAYERS              │
│                                         │
│  UEFI Secure Boot                       │
│  └── Proxmox kernel signed             │
│      └── NVIDIA modules MOK signed     │
│                                         │
│  Network Isolation                      │
│  └── VLANs enforced at bridge level    │
│      └── pfSense inter-VLAN routing    │
│          └── Firewall rules per VLAN   │
│                                         │
│  Backup                                 │
│  └── PBS daily automated (03:00)       │
│      └── Golden snapshots (protected)  │
│          └── Synology NAS (NFS)        │
└─────────────────────────────────────────┘
```
