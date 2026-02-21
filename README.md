# HikenRoot Forge

**Enterprise-inspired cybersecurity lab — Offensive, defensive, cloud and AI security training platform**

## Objective

Design and operate a realistic enterprise environment to practice:

- Active Directory attacks & defense (on-premise + hybrid cloud)
- Web application security
- Cloud & Kubernetes security
- AI/LLM security research
- Network segmentation & monitoring
- Incident response & digital forensics

Built around a fictional company (MediaTech Groupe SA) with realistic penetration testing scenarios.

## Hardware

| Node | CPU | RAM | Storage | GPU | Role |
|------|-----|-----|---------|-----|------|
| **Beelink EQR6** | AMD Ryzen 9 6900HX | 128 Go DDR5 | 1 To NVMe | — | AD Lab, Web Lab, pfSense, PBS |
| **MS-02 Ultra** | Intel Core Ultra 9 285HX | 192 Go DDR5 ECC | 9 To NVMe | RTX PRO 4000 Blackwell 24 Go | Cloud, AI, DFIR, OT/ICS, SOC |
| **Synology DS923+** | AMD Ryzen R1600 | 32 Go DDR4 | 3x 4 To IronWolf RAID 5 | — | NFS Backup |
| **MikroTik CSS610** | — | — | — | — | 10G Backbone (8x 1G PoE + 2x SFP+) |

## Architecture Overview

| Segment | Role | Purpose |
|---------|------|---------|
| Bunker | Defensive Core | AD, SIEM, infrastructure services |
| Armurerie | Offensive R&D | Red team tooling & exploit development |
| Système Nerveux | Network Control | Segmentation, routing, filtering |
| Intelligence | AI Stack | LLM security research & AI-assisted operations |

## Network Segmentation

| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 10 | AD Lab | 192.168.10.0/24 | Active Directory attacks & defense |
| 20 | Web Lab | 192.168.20.0/24 | Web exploitation & secure coding |
| 30 | Cloud Lab | 192.168.30.0/24 | Kubernetes & container security |
| 40 | AI Lab | 192.168.40.0/24 | LLM security research |
| 50 | Management | 192.168.50.0/24 | Infrastructure management |

## Technologies

- **Virtualization:** Proxmox VE 9.1, QEMU/KVM
- **Network:** pfSense, MikroTik 10G, WireGuard VPN, DAC SFP+
- **Containers:** Docker, Kubernetes (K3s + Kubeadm)
- **AI/ML:** NVIDIA RTX PRO 4000 Blackwell, Ollama (qwen3:32b, deepseek-r1:8b)
- **Active Directory:** GOAD v3 (Game of Active Directory) — 5 VMs, multi-forest
- **Monitoring:** Wazuh, Security Onion, Velociraptor (planned)
- **Backup:** Proxmox Backup Server → Synology NAS via NFS

## Cloud Lab — Kubernetes Penetration Testing

K3s cluster (3 nodes) on VLAN 30 running Kubernetes Goat — 5 exploitation scenarios with expert-level write-ups including SOC detection rules (Sigma/Falco), network diagrams, MITRE ATT&CK mapping, and financial impact analysis.

| Scenario | Attack Vector | Severity | Write-up |
|----------|--------------|----------|----------|
| SC-CLD-001 | Sensitive Keys in Codebases | High | [Read](docs/labs/cloud-lab/SC-CLD-001-sensitive-keys-in-codebases.md) |
| SC-CLD-002 | SSRF in Kubernetes | Critical | [Read](docs/labs/cloud-lab/SC-CLD-002-ssrf-in-the-kubernetes-world.md) |
| SC-CLD-003 | Container Escape to Host System | Critical | [Read](docs/labs/cloud-lab/SC-CLD-003-container-escape-to-host-system.md) |
| SC-CLD-004 | RBAC Least Privileges Misconfiguration | High | [Read](docs/labs/cloud-lab/SC-CLD-004-rbac-least-privileges-misconfiguration.md) |
| SC-CLD-005 | DIND Exploitation — Exposed Git Repository | Critical | [Read](docs/labs/cloud-lab/SC-CLD-005-dind-exploitation-exposed-git-repository.md) |

Each write-up follows a professional pentest deliverable format:

- CVSS scoring & CWE/MITRE ATT&CK classification
- Executive summary (recruiter / auditor / CISO)
- Network diagram with real IPs
- Full exploitation walkthrough with command outputs
- SOC detection rules (Sigma, Falco, IOCs)
- Financial impact estimation (MediaTech Groupe SA)
- Remediation roadmap (immediate / short-term / long-term)

## AD Lab — GOAD v3

Multi-forest Active Directory environment (5 VMs, 3 domain controllers) for OSCP+/CRTO/CRTP/CRTE preparation.

| Document | Description | Link |
|----------|-------------|------|
| Architecture | High-level design & network topology | [Read](docs/goad/architecture.md) |
| HLD (EN) | Architecture document (English) | [Read](docs/goad/HLD_GOAD_EN.md) |
| HLD (FR) | Architecture document (French) | [Read](docs/goad/HLD_GOAD_FR.md) |
| Backup Strategy | Golden snapshots & automated backups | [Read](docs/goad/backup-strategy.md) |
| WireGuard | VPN setup for remote access | [Read](docs/goad/wireguard-setup.md) |
| Troubleshooting | Common issues & solutions | [Read](docs/goad/troubleshooting.md) |
| Network Diagram | Interactive network topology | [Read](docs/goad/GOAD_Network_Diagram.html) |

## AI Lab — LLM Stack

Ollama running natively on MS-02 host with NVIDIA GPU acceleration:

| Model | Size | VRAM | Usage |
|-------|------|------|-------|
| qwen3:32b | 20 GB | ~22 GB | General purpose, dense |
| qwen3:30b-a3b | 18 GB | ~3 GB active | Fast inference, MoE agent |
| deepseek-r1:8b | 5.2 GB | ~8 GB | Autonomous pentest agent |

## Certifications Alignment

| Certification | Lab | Priority |
|---------------|-----|----------|
| OSCP+ | GOAD + WebLab | High |
| CRTO | GOAD + C2 | High |
| CRTP | GOAD (AD escalation) | High |
| CRTE | GOAD (cross-forest) | High |
| eWPT | WebLab | Medium |
| CKA / CKS | Cloud Lab Kubeadm | High |
| AZ-500 | Cloud Lab + Entra ID | Medium |
| CAIPT-RT | AI Lab | High |
| C-AI/MLPen | AI Lab | High |

## Project Status

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | Infrastructure foundation (Proxmox, VLANs, GPU, Ollama, backups) | ✅ Complete |
| Phase 2 | Cloud + AI + SOC + Guacamole | 🔧 In Progress |
| Phase 3 | DFIR + OT/ICS + Mobile | Planned |
| Phase 4 | Documentation & GitBook | Planned |

## Infrastructure Documentation

| Document | Description | Link |
|----------|-------------|------|
| MS-02 Architecture | Compute node setup & GPU configuration | [Read](docs/ms02-architecture.md) |
| Architecture Overview | Four-branch design diagram | [Read](diagrams/architecture-overview.md) |
| Network Topology | VLAN routing & segmentation | [Read](diagrams/network-topology.md) |

## Session Reports

| Report | Description | Link |
|--------|-------------|------|
| Feb 14-15, 2026 | GPU passthrough, SFP+ troubleshooting, Secure Boot | [Read](docs/reports/report-14-15-february-2026.md) |
| Feb 15, 2026 | MOK signing, kernel pinning, Ollama deployment | [Read](docs/reports/report-15-february-2026-part2.md) |

## Author

**hik3nR00t**
