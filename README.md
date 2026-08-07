# HikenRoot Forge 🔥

🇫🇷 [Version française](docs/README_FR.md)

**Enterprise-grade cybersecurity lab built around a realistic company simulation**

[![HikenRoot Forge — Global Architecture](docs/architecture-globale.png)](docs/architecture-globale.md)

> **Global architecture** — 3 physical nodes · 6 VLANs · 4 active labs · GPU compute (Blackwell + RTX 5080). Full diagram → [docs/architecture-globale.md](docs/architecture-globale.md)

## About

HikenRoot Forge is a private cybersecurity training platform designed to simulate real-world enterprise attacks and defenses. Unlike typical CTF labs, every scenario is built around **MediaTech Groupe SA**, a fictional digital press group with realistic departments (IT, Legal, Finance, HR, Editorial), Active Directory infrastructure, cloud services, and business workflows.

This approach bridges the gap between technical exploitation and business impact — every write-up includes CVSS scoring, MITRE ATT&CK mapping, financial risk estimation, regulatory analysis (GDPR/NIS2/ISO 27001), and COMEX-level remediation recommendations.

## MediaTech Groupe SA — Business Context

All technical scenarios are contextualized around **MediaTech Groupe SA**, a fictional digital press group (250 users, multi-department: IT, Legal, Finance, HR, Editorial, Contractors). This bridges the gap between raw exploitation and real-world business impact.

**In every write-up**, the "Business Impact" section maps technical findings to MediaTech's context:
- Financial risk estimation (€) based on realistic press group operations
- Regulatory analysis — GDPR, NIS2, ISO 27001 compliance impact
- COMEX-level recommendations — executive decisions expected after incident
- Risk matrix — probability vs. impact (Mermaid quadrant charts)

**Planned — AI-driven business simulation:**
- LLM agents (Ollama + n8n) will simulate MediaTech employees: naive users responding to phishing, helpdesk interactions, vulnerable chatbots
- Automated scenario generation — LLM creates realistic attack contexts adapted to certification targets (OSCP vs CRTO vs CRTE)
- Business scenario library: fraud (SC-FIN), data exfiltration (SC-JUR), insider threat (SC-IT), supply chain (SC-SUP), spear phishing (SC-USR) — ~40 scenarios planned
- Domain-joined Windows 11 workstations with realistic user profiles, deployed via Ansible + Terraform (Proxmox provider) — same IaC approach as GOAD

## Infrastructure

| Node | Specs | Role |
|---|---|---|
| **Beelink EQR6** | Ryzen 9 6900HX, 128 GB DDR5, 1 TB NVMe | GOAD AD Lab, WebLab, pfSense, PBS |
| **MS-02 Ultra** | Core Ultra 9 285HX, 192 GB DDR5 ECC, 9 TB NVMe, RTX PRO 4000 Blackwell 24 GB | Compute node, Ollama, Cloud/SOC labs |
| **Battlebox** | Ryzen 9 9950X3D, RTX 5080 16 GB, 128 GB DDR5, 12 TB NVMe | Attack platform, Hashcat, Red Team |

**Network:** pfSense + MikroTik CSS610 10G backbone + WireGuard VPN

## Network Segmentation

| VLAN | Subnet | Purpose |
|---|---|---|
| 10 | 192.168.10.0/24 | AD Lab — GOAD v3 (5 DCs, 3 domains, 2 forests) |
| 20 | 192.168.20.0/24 | Web Lab — 7 vulnerable applications |
| 30 | 192.168.30.0/24 | Cloud Lab — K3s pentest + Kubeadm certification |
| 40 | 192.168.40.0/24 | AI Lab — LLM security, n8n orchestration |
| 50 | 192.168.50.0/24 | Management — Proxmox, PBS, NAS |

## Scenarios & Write-ups

### Active Directory Lab — GOAD v3

Realistic multi-forest AD environment (sevenkingdoms.local, north.sevenkingdoms.local, essos.local) mapped to MediaTech Groupe SA's infrastructure.

![SC-AD-004 ACL Abuse Chain](assets/demo-sc-ad-004.gif)
*Demo: ACL Abuse Chain — ForceChangePassword → Kerberoast → WriteDACL → AddSelf → ShadowCreds → DCSync → Domain Admin*

| Scenario | Title | Techniques | Status |
|---|---|---|---|
| SC-AD-001 | [Recon & Initial Foothold](docs/labs/ad-lab/SC-AD-001-recon-and-initial-foothold.md) | nmap, LDAP anon, BloodHound, SYSVOL | ✅ |
| SC-AD-002 | [Credential Harvesting](docs/labs/ad-lab/SC-AD-002-credential-harvesting.md) | AS-REP Roasting, Kerberoasting, Password Spray | ✅ |
| SC-AD-003 | [NTLM Relay & Poisoning](docs/labs/ad-lab/SC-AD-003-NTLM-Relay-Poisoning.md) | Responder, ntlmrelayx, SMB relay | ✅ |
| SC-AD-004 | [ACL Abuse Chain](docs/labs/ad-lab/SC-AD-004-acl-abuse-chain.md) | ForceChangePwd → GenericWrite → WriteDACL → DA | ✅ |
| SC-AD-005 | [noPac / SamAccountName Spoofing](docs/labs/ad-lab/SC-AD-005-nopac-samaccountname-spoofing.md) | CVE-2021-42278/42287, PrintNightmare | ✅ |
| SC-AD-006 | [MSSQL Pivot](docs/labs/ad-lab/SC-AD-006-mssql-pivot.md) | Impersonate, linked servers, xp_cmdshell | ✅ |
| SC-AD-007 | [Kerberos Delegation](docs/labs/ad-lab/SC-AD-007-kerberos-delegation.md) | Unconstrained, Constrained, RBCD, Shadow Creds | ✅ |
| SC-AD-008 | [ADCS Certificate Abuse](docs/labs/ad-lab/SC-AD-008-adcs-certificate-abuse.md) | ESC1/2/3/4/6/8, certipy, PetitPotam | ✅ |
| SC-AD-009 | [Domain Dominance](docs/labs/ad-lab/SC-AD-009-domain-dominance.md) | Golden/Silver Ticket, AdminSDHolder, DCSync | ✅ |
| SC-AD-010 | [Cross-Forest Trusts](docs/labs/ad-lab/SC-AD-010-cross-forest-trusts.md) | raiseChild, SID History, foreign groups | ✅ |
| SC-AD-011 | [Coerce & File-based Attacks](docs/labs/ad-lab/SC-AD-011-coerce-file-based-attacks.md) | .lnk, .scf, .url, searchConnector-ms, WebDAV | ✅ |
| SC-AD-012 | [ADCS Advanced](docs/labs/ad-lab/SC-AD-012-adcs-advanced.md) | ESC5 Golden Certificate, ESC9, ESC11 RPC Relay | ✅ |

### Cloud & Kubernetes Lab

| Scenario | Title | Techniques | Status |
|---|---|---|---|
| SC-CLD-001 | [Sensitive Keys in Codebases](docs/labs/cloud-lab/SC-CLD-001-sensitive-keys-in-codebases.md) | Git secrets, env leaks, registry exposure | ✅ |
| SC-CLD-002 | [SSRF in the Kubernetes World](docs/labs/cloud-lab/SC-CLD-002-ssrf-in-the-kubernetes-world.md) | SSRF → metadata, service account tokens | ✅ |
| SC-CLD-003 | [Container Escape to Host](docs/labs/cloud-lab/SC-CLD-003-container-escape-to-host-system.md) | Privileged container, host mount, nsenter | ✅ |
| SC-CLD-004 | [RBAC Misconfiguration](docs/labs/cloud-lab/SC-CLD-004-rbac-least-privileges-misconfiguration.md) | ClusterRole abuse, token theft, lateral movement | ✅ |
| SC-CLD-005 | [Attacking Private Registry](docs/labs/cloud-lab/SC-CLD-005-attacking-private-registry.md) | Registry enumeration, image tampering | ✅ |

### Write-up Format

Every scenario follows a standardized professional format:

1. **Classification** — Severity, CVSS 3.1, affected systems
2. **Executive Summary** — For recruiter / ISO 27001 auditor / CISO
3. **Kill Chain** — Mermaid diagram with attack flow
4. **Exploitation** — Step-by-step with real commands and outputs
5. **Business Impact — MediaTech Groupe SA** — Financial estimation, risk matrix, regulatory impact (GDPR/NIS2/ISO 27001), COMEX decisions
6. **Detection** — Event IDs, Sigma rules, IOCs
7. **Remediation** — Secure by Design (0-24h / 1 week / 1 month)
8. **Target Architecture** — Mermaid diagram

## Architecture Documentation

| Document | Description | Link |
|---|---|---|
| GOAD HLD (EN) | High-Level Design — AD Lab architecture | [docs/goad/HLD_GOAD_EN.md](docs/goad/HLD_GOAD_EN.md) |
| GOAD HLD (FR) | Architecture macro — Lab AD | [docs/goad/HLD_GOAD_FR.md](docs/goad/HLD_GOAD_FR.md) |
| MS-02 Architecture | Hardware, storage, GPU, network specs | [docs/ms02-architecture.md](docs/ms02-architecture.md) |
| WireGuard Setup | VPN configuration for pentest access | [docs/goad/wireguard-setup.md](docs/goad/wireguard-setup.md) |
| Backup Strategy | PBS + Synology NAS + GOLDEN snapshots | [docs/goad/backup-strategy.md](docs/goad/backup-strategy.md) |
| Troubleshooting | 50+ resolved issues | [docs/goad/troubleshooting.md](docs/goad/troubleshooting.md) |
| AD Lab Roadmap | GOAD progression tracker | [docs/labs/ad-lab/ROADMAP.md](docs/labs/ad-lab/ROADMAP.md) |

## Certifications Alignment

| Certification | Lab Coverage |
|---|---|
| OSCP+ | GOAD AD Lab + WebLab |
| CRTO / CRTP / CRTE | GOAD AD Lab + C2 |
| eWPT | WebLab (7 apps) |
| CKA / CKAD / CKS | Kubeadm cluster (VLAN 30) |
| AZ-500 | K3s pentest cluster |
| CAIPT-RT / C-AI/MLPen | AI Lab (VLAN 40) |

## Project Status

| Phase | Scope | Status |
|---|---|---|
| Phase 1 | Infrastructure foundation | ✅ Complete |
| Phase 2 | Cloud + AI + SOC + Guacamole | 🔧 In Progress |
| Phase 3 | DFIR + OT/ICS + Mobile | 📋 Planned |
| Phase 4 | Documentation GitBook FR/EN | 📋 Planned |

## Related Repositories

Part of the **HikenRoot Forge** ecosystem:

- [ad-hardening-baseline](https://github.com/hikenroot/ad-hardening-baseline) — PowerShell AD hardening toolkit (CIS Benchmark / NIST 800-53 / ISO 27001 / MITRE ATT&CK), tested on GOAD.
- [m365-admin-toolkit](https://github.com/hikenroot/m365-admin-toolkit) — PowerShell scripts for Microsoft 365 administration, auditing and security hardening.

## Author

**hik3nR00t** — Cybersecurity professional with 20+ years of infrastructure experience.

---

*HikenRoot Forge — Enterprise-grade cybersecurity lab*
