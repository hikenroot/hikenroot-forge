# HikenRoot Forge 🔥

**Enterprise-inspired cybersecurity lab — Offensive, defensive, cloud and AI security training platform**

## Objective

Design and operate a realistic enterprise environment to practice:

- Active Directory attacks & defense (on-premise + hybrid cloud)
- Web application security
- Cloud & Kubernetes security
- AI/LLM security research
- Identity & Access Management (IAM)
- Network segmentation & monitoring
- Incident response & digital forensics

Built around a fictional company (MediaTech Groupe SA) with realistic penetration testing scenarios.

## Hardware

| Node | CPU | RAM | Storage | GPU | Role |
|------|-----|-----|---------|-----|------|
| **Beelink EQR6** | AMD Ryzen 9 6900HX | 128 Go DDR5 | 1 To NVMe | — | AD Lab, Web Lab, pfSense, PBS |
| **MS-02 Ultra** | Intel Core Ultra 9 285HX | 192 Go DDR5 ECC | 9 To NVMe | RTX PRO 4000 Blackwell 24 Go | Cloud, AI, DFIR, OT/ICS, SOC |
| **Synology DS923+** | AMD Ryzen R1600 | 32 Go DDR4 | 3x 4 To IronWolf RAID 5 (7 To usable) | — | NFS Backup |
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
- **AI/ML:** NVIDIA RTX PRO 4000 Blackwell, Ollama (qwen3:32b, qwen3:30b-a3b, deepseek-r1:8b)
- **Active Directory:** GOAD v3 (Game of Active Directory) — 5 VMs, multi-forest
- **Identity:** Keycloak (planned), Entra ID hybrid (planned)
- **Monitoring:** Wazuh, Security Onion, Velociraptor (planned)
- **Backup:** Proxmox Backup Server → Synology NAS via NFS

## Cloud Lab — K3s Pentest Cluster

3-node Kubernetes cluster on VLAN 30 with Kubernetes Goat (20+ attack scenarios):

| Node | IP | Role |
|------|-----|------|
| k8s-prod-master | 192.168.30.10 | Control plane (API server, etcd, scheduler) |
| k8s-prod-worker-1 | 192.168.30.11 | Workload execution |
| k8s-prod-worker-2 | 192.168.30.12 | Workload execution |

Attack scenarios: container escape, SSRF to metadata API, RBAC escalation, exposed secrets, service account abuse, pod-to-pod lateral movement.

## AI Lab — LLM Stack

Ollama running natively on MS-02 host with NVIDIA GPU acceleration:

| Model | Size | VRAM | Usage |
|-------|------|------|-------|
| qwen3:32b | 20 GB | ~22 GB | General purpose, dense |
| qwen3:30b-a3b | 18 GB | ~3 GB active | Fast inference, MoE agent |
| deepseek-r1:8b | 5.2 GB | ~8 GB | Autonomous pentest agent |

API restricted to VLAN 40 via pfSense floating rule.

## Certifications Alignment

Platform designed to support preparation for:

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

### Roadmap

- [ ] Kubernetes Goat attack scenarios (SC-CLD-001 to 004)
- [ ] Kubeadm certification cluster (CKA/CKS prep)
- [ ] Keycloak IAM on K3s cluster
- [ ] Entra ID hybrid lab (M365 E5 trial + Azure AD Connect to GOAD)
- [ ] SOC Lab (Wazuh + Security Onion + Velociraptor)
- [ ] Guacamole remote access
- [ ] AI attack scenarios (prompt injection, RAG poisoning, model abuse)

## Documentation

| Lab | Description | Link |
|-----|-------------|------|
| AD Lab (GOAD) | Multi-forest Active Directory environment with IaC deployment | [docs/goad](docs/goad/) |
| MS-02 Architecture | Hardware, storage, GPU, network decisions | [docs/reports](docs/reports/) |
| Session Reports | Technical troubleshooting and architecture decisions | [docs/reports](docs/reports/) |

## Author

**hik3nR00t**
