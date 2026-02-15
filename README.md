# HikenRoot Forge 🔥

**Enterprise-inspired cybersecurity lab — Offensive, defensive, cloud and AI security training platform**

## Objective

Design and operate a realistic enterprise environment to practice:

- Active Directory attacks & defense
- Web application security
- Cloud & Kubernetes security
- AI/LLM security research
- Network segmentation & monitoring
- Incident response & digital forensics

Built around a fictional company (MediaTech Groupe SA) with realistic penetration testing scenarios.

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

- **Virtualization:** Proxmox VE, QEMU/KVM
- **Network:** pfSense, MikroTik 10G, WireGuard VPN
- **Containers:** Docker, Kubernetes (K3s + Kubeadm)
- **AI/ML:** NVIDIA GPU acceleration, Ollama, LLM stack
- **Active Directory:** GOAD (Game of Active Directory)
- **Monitoring:** Wazuh, Security Onion, Velociraptor
- **Backup:** Proxmox Backup Server, Synology NAS

## Certifications Alignment

Platform designed to support preparation for:

OSCP+ | CRTO | CRTP | CRTE | eWPT | CKA/CKAD/CKS | AZ-500 | CAIPT-RT | C-AI/MLPen

## Project Status

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | Infrastructure foundation | ~80% |
| Phase 2 | Cloud + AI + SOC labs | Planned |
| Phase 3 | DFIR + OT/ICS + Mobile | Planned |
| Phase 4 | Documentation & GitBook | Planned |

## Documentation

| Lab | Description | Link |
|-----|-------------|------|
| AD Lab (GOAD) | Multi-forest Active Directory environment with IaC deployment | [docs/goad](docs/goad/) |
| Session Reports | Technical troubleshooting and architecture decisions | [docs/reports](docs/reports/) |

## Author

**hik3nR00t**
