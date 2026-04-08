# Identity Lab — Expert AD / Entra ID

## Contexte

Projet de lab complet simulant une mission d'**Architecte Identity Senior** sur un environnement multi-forêts Active Directory hybridé avec Microsoft Entra ID. Chaque scénario suit le cycle d'une mission réelle : audit → design → implémentation → vérification.

## Infrastructure

| VM | Rôle | IP | OS |
|---|---|---|---|
| DC01 / KINGSLANDING | DC sevenkingdoms.local | 192.168.10.10 | Server 2019 |
| DC02 / WINTERFELL | DC north.sevenkingdoms.local | 192.168.10.11 | Server 2019 |
| DC03 / MEEREEN | DC essos.local | 192.168.10.12 | Server 2016 |
| SRV02 / CASTELBLACK | Member Server (north) | 192.168.10.22 | Server 2019 |
| SRV03 / BRAAVOS | Member Server (essos) | 192.168.10.23 | Server 2016 |
| ADCONNECT | AD Connect (Tier 0) | 192.168.10.55 | Server 2019 |

**Tenant Entra ID :** `nchouarhipm.onmicrosoft.com`

## Scénarios

### Bloc 1 — AD On-Prem (Audit & Hardening)

| Scénario | Titre | Outils | Statut |
|---|---|---|---|
| SC-ID-001 | [Cartographie AD Multi-Forêts](SC-ID-001-cartographie-ad.md) | netexec, PowerShell, Get-AD* | ✅ |
| SC-ID-002 | [Santé Réplication](SC-ID-002-sante-replication.md) | repadmin, dcdiag | ✅ |
| SC-ID-003 | [Redesign Sites & Services](SC-ID-003-sites-services.md) | PowerShell AD Sites, New-ADReplicationSite | ✅ |
| SC-ID-004 | [Tiering Model](SC-ID-004-tiering-model.md) | OUs, GPO Deny Logon, comptes T0/T1/T2 | ✅ |
| SC-ID-005 | [Audit PingCastle](SC-ID-005-pingcastle-audit.md) | PingCastle, rapport consolidé | ✅ |
| SC-ID-006 | [BloodHound — Chemins d'Attaque](SC-ID-006-bloodhound.md) | SharpHound, bloodhound-python, BloodHound CE | ✅ |
| SC-ID-007 | [GPO CIS Baseline](SC-ID-007-gpo-cis-baseline.md) | GPO, CIS Benchmark Level 1 DC | ✅ |
| SC-ID-008 | [Remédiations Kerberos](SC-ID-008-remediation-kerberos.md) | krbtgt rotation, AS-REP fix, gMSA | ✅ |
| SC-ID-009 | [PingCastle Post-Hardening](SC-ID-009-pingcastle-post-hardening.md) | PingCastle avant/après | ✅ |

### Bloc 2 — Entra ID Hybrid (Design & Implémentation)

| Scénario | Titre | Outils | Statut |
|---|---|---|---|
| SC-ID-010 | [Tenant Azure & Break Glass](SC-ID-010-tenant-breakglass.md) | Portail Entra, M365 Admin | ✅ |
| SC-ID-011 | [VM AD Connect (IaC)](SC-ID-011-vm-adconnect.md) | Terraform, Proxmox | ✅ |
| SC-ID-012 | [AD Connect — Hybrid Identity](SC-ID-012-adconnect-hybrid.md) | PHS, SSO, Password Writeback, filtrage OUs | ✅ |
| SC-ID-013 | [Conditional Access](SC-ID-013-conditional-access.md) | 4 CA policies, Named Locations | ✅ |
| SC-ID-014 | [PIM — Privileged Access](SC-ID-014-pim.md) | PIM, JIT, MFA activation, approbation | ✅ |

## Auteur

**Nadyr Chouarhi** (hik3nR00t) — Consultant Identity & Sécurité Microsoft
