# Active Directory Security Lab

## Overview

Segmented, fully isolated Active Directory infrastructure designed to simulate real-world enterprise attack scenarios. Built on the [GOAD framework](https://github.com/Orange-Cyberdefense/GOAD) (Orange Cyberdefense), deployed from scratch using Infrastructure as Code principles.

## Objectives

- Reproduce common Active Directory attack paths in a controlled environment
- Validate network segmentation and firewall policies
- Practice incident response and recovery procedures
- Evaluate backup resilience against ransomware scenarios
- Document troubleshooting methodology for complex infrastructure issues

## Architecture

```
                    MANAGEMENT NETWORK - 192.168.50.0/24
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
      Proxmox VE          pfSense             Synology NAS
      .50.227             .50.250             .50.130
          │                   │
          │          WireGuard VPN (10.10.10.0/24)
          │                   │
          ├───────────────────┘
          │
    ISOLATED AD NETWORK - 192.168.10.0/24
          │
    ┌─────┼──────────────────────────┐
    │     │                          │
    │  SEVENKINGDOMS.LOCAL      ESSOS.LOCAL
    │  (Forest Root)            (External Forest)
    │     │                          │
    │  DC01 (.10.10)            DC03 (.10.12)
    │     │                     SRV03 (.10.23)
    │     │
    │  NORTH.SEVENKINGDOMS.LOCAL
    │  (Child Domain)
    │  DC02 (.10.11)
    │  SRV02 (.10.22)
    │
    PBS (.50.129) ─── Isolated Backup Network
```

### Virtual Machines

| VM | Hostname | IP | Role | OS |
|----|----------|-----|------|-----|
| 101 | pfSense | Multi-IF | Firewall / Router / VPN | FreeBSD |
| 106 | DC01 | 192.168.10.10 | Forest Root Domain Controller | Windows Server 2019 |
| 107 | DC02 | 192.168.10.11 | Child Domain Controller | Windows Server 2019 |
| 109 | DC03 | 192.168.10.12 | External Forest Domain Controller | Windows Server 2016 |
| 105 | SRV02 | 192.168.10.22 | Member Server + MSSQL | Windows Server 2019 |
| 108 | SRV03 | 192.168.10.23 | Member Server + MSSQL | Windows Server 2016 |
| 110 | PBS | 192.168.50.129 | Proxmox Backup Server | Debian |

### Domain Trust Relationships

```
SEVENKINGDOMS.LOCAL (Forest Root)
        │
        ├── NORTH.SEVENKINGDOMS.LOCAL (Child Domain, bidirectional trust)
        │
        └── ESSOS.LOCAL (External Forest, bidirectional trust)
```

## Security Design

| Principle | Implementation |
|-----------|---------------|
| Default deny | pfSense blocks all inter-zone traffic unless explicitly allowed |
| Network isolation | GOAD lab on dedicated VLAN, no route to LAN |
| Controlled access | WireGuard VPN required for attack machine connectivity |
| Backup isolation | PBS on separate network segment |
| Golden state recovery | Pre-attack snapshots for full environment restore |

## Deployment — Infrastructure as Code

| Tool | Purpose |
|------|---------|
| Packer | Windows Server 2019/2016 template creation with cloud-init |
| Terraform | VM provisioning on Proxmox (bpg/proxmox provider) |
| Ansible | AD configuration, GPO deployment, vulnerability injection |

### Deployment Steps

```bash
# 1. Build templates
cd GOAD/packer/proxmox/
packer build -var-file=windows_server2019_proxmox_cloudinit.pkvars.hcl .
packer build -var-file=windows_server2016_proxmox_cloudinit.pkvars.hcl .

# 2. Deploy VMs
cd ../../ad/GOAD/providers/proxmox/terraform/
terraform init && terraform apply

# 3. Configure AD environment
cd ../../../../../
./goad.sh -t install -l GOAD -p proxmox -m local
```

Full deployment time: ~45 minutes (excluding template builds).

## Attack Surface

The environment exposes the following attack paths for training:

**Kerberos:** AS-REP Roasting, Kerberoasting, Unconstrained/Constrained/Resource-Based Constrained Delegation

**Active Directory:** Password Spraying, DCSync, GPO Abuse, ACL Abuse (WriteDACL, GenericAll), Forest Trust Abuse

**ADCS (PKI):** ESC1 (Misconfigured Certificate Templates), ESC8 (NTLM Relay to ADCS)

**Lateral Movement:** Pass-the-Hash, Pass-the-Ticket, NTLM Relay, LLMNR/NBT-NS Poisoning, MSSQL Attacks

## Backup & Recovery

| Strategy | Detail |
|----------|--------|
| Regular backups | Automated via Proxmox Backup Server |
| Golden snapshots | Pre-attack state preserved for instant restore |
| Recovery time | Full lab restore under 15 minutes |
| Storage | Synology NAS via NFS |

## Operational Issues Resolved

Over 50 technical issues were encountered and documented during deployment, including:

| Category | Examples |
|----------|----------|
| Provisioning | Terraform provider migration (telmate → bpg/proxmox), Packer ImageIndex configuration |
| Authentication | WinRM credential failures, Kerberos trust establishment |
| Networking | VLAN routing, pfSense rule ordering, DNS resolution chain |
| Storage | NAS IP changes breaking PBS, backup integrity verification |
| Hypervisor | Resource contention, template disk format compatibility |

Full troubleshooting documentation: [troubleshooting.md](troubleshooting.md)

## Related Documentation

- [Architecture Details](architecture.md)
- [WireGuard VPN Setup](wireguard-setup.md)
- [Backup Strategy](backup-strategy.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Network Diagram (Interactive)](GOAD_Network_Diagram.html)
