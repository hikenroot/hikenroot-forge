# AD Lab — GOAD v3
## HikenRoot Forge | MediaTech Groupe SA

Multi-forest Active Directory environment deployed on Proxmox (Beelink EQR6, VLAN 10 — 192.168.10.0/24).
Based on [Game of Active Directory v3](https://github.com/Orange-Cyberdefense/GOAD) by mayfly277.

---

## Infrastructure

| Machine | IP | Domaine | OS | Signing | SMBv1 | Services |
|---------|-----|---------|-----|---------|-------|----------|
| KINGSLANDING | 192.168.10.10 | sevenkingdoms.local | WS 2019 | True | No | DC, DNS, LDAP |
| WINTERFELL | 192.168.10.11 | north.sevenkingdoms.local | WS 2019 | True | No | DC, DNS, LDAP |
| MEEREEN | 192.168.10.12 | essos.local | WS 2016 | True | **Yes** | DC, DNS, LDAP |
| CASTELBLACK | 192.168.10.22 | north.sevenkingdoms.local | WS 2019 | **False** | No | MSSQL, IIS, WinRM |
| BRAAVOS | 192.168.10.23 | essos.local | WS 2016 | **False** | **Yes** | MSSQL, WinRM |

> **CASTELBLACK** et **BRAAVOS** — SMB signing desactive, cibles NTLM relay

---

## Domain Trusts

| Source | Cible | Type | Direction |
|--------|-------|------|-----------|
| north.sevenkingdoms.local | sevenkingdoms.local | Parent-Child | Bidirectionnel |
| sevenkingdoms.local | essos.local | Cross-Forest | Bidirectionnel |

---

## Active Bots (NTLM capture)

| Compte | Frequence | Cible |
|--------|-----------|-------|
| robb.stark | toutes les 3 min | CASTELBLACK SMB |
| eddard.stark | toutes les 5 min | CASTELBLACK SMB |

---

## Lab Access

WireGuard VPN — Kali `10.10.10.2` to VLAN 10 via pfSense (UDP 51820).

```bash
# Verify connectivity
netexec smb 192.168.10.0/24

# Reset lab via Proxmox snapshots
# Proxmox UI -> VM -> Snapshots -> GOLDEN -> Rollback
```

---

## Exploitation Scenarios

All write-ups in [`docs/labs/ad-lab/`](../labs/ad-lab/README.md)

| Scenario | Technique | Status |
|----------|-----------|--------|
| SC-AD-001 | Recon & Initial Foothold | Done |
| SC-AD-002 | Credential Harvesting | Done |
| SC-AD-003 | NTLM Relay & Poisoning | Done |
| SC-AD-004 | ACL Abuse Chain | Done |
| SC-AD-005 | noPac CVE-2021-42278/42287 + PrintNightmare CVE-2021-1675 | Done |
| SC-AD-006 | MSSQL Pivot | Done |
| SC-AD-007 | Kerberos Delegation | Pending |
| SC-AD-008 | ADCS Attacks | Pending |
| SC-AD-009 | Domain Dominance | Pending |
| SC-AD-010 | Cross-Forest Trusts | Pending |
| SC-AD-011 | Coerce & File-based | Pending |
| SC-AD-012 | ADCS Advanced | Pending |

---

## Documentation

| Document | Description |
|----------|-------------|
| [HLD_GOAD_EN.md](HLD_GOAD_EN.md) | Architecture document (English) |
| [HLD_GOAD_FR.md](HLD_GOAD_FR.md) | Architecture document (French) |
| [GOAD_Network_Diagram.html](GOAD_Network_Diagram.html) | Interactive network topology |
| [backup-strategy.md](backup-strategy.md) | Golden snapshots & automated backups |
| [wireguard-setup.md](wireguard-setup.md) | VPN setup for remote access |
| [troubleshooting.md](troubleshooting.md) | Common issues & solutions |

---

## References

- GOAD Source : https://github.com/Orange-Cyberdefense/GOAD
- Mayfly277 Walkthrough : https://mayfly277.github.io

---

*Auteur : hik3nR00t | HikenRoot Forge | Mars 2026*
