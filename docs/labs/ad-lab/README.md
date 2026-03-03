# AD Lab — Write-ups Index
## HikenRoot Forge | MediaTech Groupe SA

Exploitation scenarios against GOAD v3 (Game of Active Directory).
Each write-up follows the standard pentest deliverable format: kill chain, CVSS, MITRE ATT&CK, business impact (COMEX), SOC detection, remediation.

---

## Progression

| Scenario | Technique | Mayfly | CRTP | CRTO | CRTE | Status |
|----------|-----------|--------|------|------|------|--------|
| [SC-AD-001](SC-AD-001-recon-and-initial-foothold.md) | Recon & Initial Foothold | Part 1+2 | Yes | - | - | Done |
| [SC-AD-002](SC-AD-002-credential-harvesting.md) | Credential Harvesting | Part 2+3 | Yes | Yes | - | Done |
| [SC-AD-003](SC-AD-003-NTLM-Relay-Poisoning.md) | NTLM Relay & Poisoning | Part 4 | Yes | Yes | - | Done |
| [SC-AD-004](SC-AD-004-acl-abuse-chain.md) | ACL Abuse Chain | Part 11 | Yes | Yes | - | Done |
| [SC-AD-005](SC-AD-005-nopac-samaccountname-spoofing.md) | noPac + PrintNightmare | Part 5+8 | Yes | Yes | - | Done |
| [SC-AD-006](SC-AD-006-mssql-pivot.md) | MSSQL Pivot | Part 7 | Yes | Yes | - | Done |
| SC-AD-007 | Kerberos Delegation | Part 10 | Yes | Yes | Yes | Pending |
| SC-AD-008 | ADCS Attacks | Part 6 | - | - | Yes | Pending |
| SC-AD-009 | Domain Dominance | Part 9+11 | Yes | Yes | - | Pending |
| SC-AD-010 | Cross-Forest Trusts | Part 12 | - | Yes | Yes | Pending |
| SC-AD-011 | Coerce & File-based | Part 13 | - | Yes | - | Pending |
| SC-AD-012 | ADCS Advanced | Part 14 | - | - | Yes | Pending |

---

## Write-up Format

Each scenario includes:

- Classification: CVSS 3.1, CVE, MITRE ATT&CK
- Executive summary: recruiter / ISO 27001 auditor / CISO
- Network diagram (Mermaid)
- Kill chain (Mermaid sequence diagram)
- Full exploitation walkthrough with real command outputs
- SOC detection: Event IDs + Sigma rules
- Business impact: financial estimate, RGPD/NIS2/ISO 27001 mapping
- COMEX section: priority action plan
- Remediation: PowerShell commands + secure architecture target

---

## Infrastructure Reference

| Machine | IP | Domain | Signing | Role |
|---------|----|--------|---------|------|
| KINGSLANDING | 192.168.10.10 | sevenkingdoms.local | True | DC01 |
| WINTERFELL | 192.168.10.11 | north.sevenkingdoms.local | True | DC02 |
| MEEREEN | 192.168.10.12 | essos.local | True | DC03 |
| CASTELBLACK | 192.168.10.22 | north.sevenkingdoms.local | **False** | SRV MSSQL+IIS |
| BRAAVOS | 192.168.10.23 | essos.local | **False** | SRV MSSQL |

---

## References

- [ROADMAP.md](ROADMAP.md) — learning path CRTP/CRTO/CRTE alignment
- [GOAD-LEARNING-PATH-OneNote.md](GOAD-LEARNING-PATH-OneNote.md) — detailed module notes
- [docs/goad/](../../goad/README.md) — GOAD architecture & infrastructure docs
- Mayfly277 : https://mayfly277.github.io

---

*Auteur : Nadyr Chouarhi (hik3nR00t) | HikenRoot Forge | Mars 2026*
