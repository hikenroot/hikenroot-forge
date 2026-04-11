# Identity Lab — Expert AD / Entra ID

> **Portfolio project** — Demonstrates end-to-end Active Directory & Entra ID expertise for enterprise hybrid identity missions.

---

## 🎯 Objectif

Ce lab simule une **mission complète d'Architecte Identity Senior** sur un environnement multi-forêts Active Directory hybridé avec Microsoft Entra ID. Le projet couvre le cycle complet d'une mission réelle : **audit → design → implémentation → hardening → vérification**.

L'objectif est de démontrer les compétences attendues pour des missions **Expert AD / Entra ID** dans des contextes grands comptes, banque, défense, telecom.

| Domaine | Outils | Statut |
|---|---|---|
| Cartographie AD multi-forêts | netexec, PowerShell, Get-AD* | ✅ |
| Santé réplication inter-DC | repadmin, dcdiag | ✅ |
| Topologie Sites & Services | PowerShell AD Sites, New-ADReplicationSite | ✅ |
| Tiering Model (T0/T1/T2) | OUs, GPO Deny Logon, comptes tiered | ✅ |
| Audit sécurité AD | PingCastle 3.5, rapport consolidé | ✅ |
| Chemins d'attaque | SharpHound, BloodHound Legacy | ✅ |
| Hardening CIS Level 1 DC | GPO, Security Options, Audit Policy | ✅ |
| Remédiations Kerberos | krbtgt rotation, AS-REP fix, gMSA | ✅ |
| Mesure d'impact post-hardening | PingCastle avant/après | ✅ |
| Tenant Entra ID + Break Glass | Portail Entra, M365 Admin | ✅ |
| VM AD Connect (IaC) | Terraform, Proxmox | ✅ |
| Hybrid Identity | PHS, SSO, Password Writeback, filtrage OUs | ✅ |
| Conditional Access | 4 CA policies Report-only, Named Locations | ✅ |
| Privileged Identity Management | PIM, JIT 4h, MFA, approbation | ✅ |

---

## 👤 Rôle simulé

**Architecte Identity Senior** — missionné par un grand compte pour :

1. **Auditer** l'infrastructure AD existante (2 forêts, 3 domaines, 5 serveurs)
2. **Identifier** les vulnérabilités et chemins d'attaque (PingCastle + BloodHound)
3. **Concevoir** l'architecture cible (Tiering, Sites & Services)
4. **Durcir** l'environnement (CIS Benchmark, remédiations Kerberos)
5. **Hybridiser** avec Entra ID (AD Connect, PHS, SSO)
6. **Gouverner** les accès privilégiés (Conditional Access, PIM)
7. **Mesurer** l'impact du hardening (PingCastle avant/après)

---

## 🏗️ Architecture

```
                        ┌─────────────────────────────────────┐
                        │         ENTRA ID (Cloud)            │
                        │     nchouarhipm.onmicrosoft.com     │
                        │                                     │
                        │  ┌───────────┐  ┌───────────────┐  │
                        │  │ Cond.     │  │ PIM           │  │
                        │  │ Access    │  │ Global Admin  │  │
                        │  │ 4 policies│  │ JIT 4h + MFA  │  │
                        │  └───────────┘  └───────────────┘  │
                        │                                     │
                        │  Break Glass 01 ── Global Admin     │
                        │  Break Glass 02 ── Global Admin     │
                        │  Entra ID P1 + P2 (trial)           │
                        │  Security Defaults: OFF             │
                        └──────────────┬──────────────────────┘
                                       │
                                       │ PHS + Seamless SSO
                                       │ Password Writeback
                                       │
                        ┌──────────────▼──────────────────────┐
                        │      ADCONNECT (VM 111)             │
                        │      192.168.10.55                  │
                        │      Server 2019 — Tier 0           │
                        │      Terraform IaC (Proxmox)        │
                        │                                     │
                        │   Sync: sevenkingdoms.local ──┐     │
                        │   Sync: essos.local ──────────┤     │
                        │   OU Filter: excl. T0/DC/Built│     │
                        └──────────────┬────────────────┘─────┘
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            │                          │                          │
            │          VLAN 10 — 192.168.10.0/24                  │
            │              AD Lab (vmbr4 tag=10)                  │
            │                                                     │
┌───────────▼───────────┐  ┌─────────────────────┐  ┌────────────▼──────────┐
│  FORÊT 1              │  │                     │  │  FORÊT 2              │
│  sevenkingdoms.local  │  │   Trust Inter-Forêt │  │  essos.local          │
│                       │◄─┤   Bidirectionnel    ├─►│                       │
│  ┌─────────────────┐  │  │                     │  │  ┌─────────────────┐  │
│  │ DC01             │  │  └─────────────────────┘  │  │ DC03             │  │
│  │ KINGSLANDING     │  │                           │  │ MEEREEN          │  │
│  │ 192.168.10.10    │  │                           │  │ 192.168.10.12    │  │
│  │ Server 2019      │  │                           │  │ Server 2016      │  │
│  │ 5 FSMO (forêt)   │  │                           │  │ 5 FSMO (seul DC) │  │
│  │ PDC + GC         │  │                           │  │ GC               │  │
│  │ Site: Paris-HQ   │  │                           │  │ Site: Essos-Intl │  │
│  └─────────────────┘  │                           │  └─────────────────┘  │
│                       │                           │                       │
│  ┌─────────────────┐  │                           │  ┌─────────────────┐  │
│  │ DC02             │  │                           │  │ SRV03            │  │
│  │ WINTERFELL       │  │                           │  │ BRAAVOS          │  │
│  │ 192.168.10.11    │  │                           │  │ 192.168.10.23    │  │
│  │ Server 2019      │  │                           │  │ Server 2016      │  │
│  │ 3 FSMO (child)   │  │                           │  │ Member Server    │  │
│  │ GC               │  │                           │  └─────────────────┘  │
│  │ Site: North-Off  │  │                           │                       │
│  └─────────────────┘  │                           └───────────────────────┘
│                       │
│  ┌─────────────────┐  │
│  │ SRV02            │  │
│  │ CASTELBLACK      │  │
│  │ 192.168.10.22    │  │
│  │ Server 2019      │  │
│  │ Member Server    │  │
│  └─────────────────┘  │
│                       │
│  Domaine enfant:      │
│  north.sevenkingdoms  │
│  .local (DC02)        │
└───────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                    PROXMOX HOST (Beelink)                        │
│                    192.168.50.227                                 │
│                                                                   │
│  Bridges: vmbr0=LAN │ vmbr1=WAN │ vmbr2=mgmt │ vmbr4=VLAN10    │
│                                                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ VM 105   │ │ VM 107   │ │ VM 109   │ │ VM 111   │            │
│  │ DC01     │ │ DC02     │ │ DC03     │ │ ADCONNECT│            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                         │
│  │ VM 106   │ │ VM 108   │ │ goad-vm  │                         │
│  │ SRV02    │ │ SRV03    │ │ Terraform│                         │
│  └──────────┘ └──────────┘ └──────────┘                         │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📊 Résultats mesurables

| Métrique | Avant | Après | Impact |
|---|---|---|---|
| PingCastle score global | 57/100 | 85/100 | Score dégradé par l'hybridation (attendu) |
| PingCastle Anomalies | 72/100 | 62/100 | -10 pts grâce au CIS (SMB signing, NTLMv2) |
| Comptes AS-REP Roastable | 2 (Brandon Stark, Missandei) | 0 | Remédiation complète |
| krbtgt password age | Jamais changé depuis création | Rotaté mars 2026 | Golden Ticket invalidé |
| Password policy | Complexity OFF, MinLength 5 | Complexity ON, MinLength 14 | Brute-force mitigé |
| Sites AD configurés | 1 (default) | 4 sites + 5 subnets + 2 site links | Réplication optimisée |
| Tiering | Aucune séparation | 3 tiers + GPO Deny Logon | Escalade cross-tier bloquée |
| Conditional Access | Aucune policy | 4 policies Report-only | Gouvernance cloud |
| PIM | Rôles permanents | JIT 4h + MFA + approbation | Least privilege |

> **Note :** Le score PingCastle global monte à 85 après hybridation car AD Connect et les comptes de service associés augmentent la surface Privileged Accounts (50→85). C'est un constat réaliste documenté dans SC-ID-009 — en mission client, ce serait adressé dans une phase 2 de remédiation.

---

## 📁 Structure du repository

```
docs/labs/identity-lab/
├── README.md                          ← vous êtes ici
├── bloc1-ad-onprem/                   # 9 write-ups AD On-Prem
│   ├── SC-ID-001-cartographie-ad.md
│   ├── SC-ID-002-sante-replication.md
│   ├── SC-ID-003-sites-services.md
│   ├── SC-ID-004-tiering-model.md
│   ├── SC-ID-005-pingcastle-audit.md
│   ├── SC-ID-006-bloodhound.md
│   ├── SC-ID-007-gpo-cis-baseline.md
│   ├── SC-ID-008-remediation-kerberos.md
│   ├── SC-ID-009-pingcastle-post-hardening.md
│   └── assets/                        # 43 screenshots
├── bloc2-entra-hybrid/                # 5 write-ups Entra ID
│   ├── SC-ID-010-tenant-breakglass.md
│   ├── SC-ID-011-vm-adconnect.md
│   ├── SC-ID-012-adconnect-hybrid.md
│   ├── SC-ID-013-conditional-access.md
│   ├── SC-ID-014-pim.md
│   └── assets/                        # 21 screenshots
└── bloc3-packaging/
    ├── runbooks/
    │   ├── runbook-adconnect-operations.md
    │   └── runbook-ad-incidents-n3.md
    └── diagrams/
        └── architecture-complete.md
```

---

## 🔬 Scénarios détaillés

### Bloc 1 — AD On-Prem (Audit & Hardening)

| # | Scénario | Phase | Outils | Write-up |
|---|---|---|---|---|
| SC-ID-001 | [Cartographie AD Multi-Forêts](bloc1-ad-onprem/SC-ID-001-cartographie-ad.md) | Auditer | netexec, Get-AD* | 7 findings identifiés |
| SC-ID-002 | [Santé Réplication](bloc1-ad-onprem/SC-ID-002-sante-replication.md) | Auditer | repadmin, dcdiag | 0 erreurs, MEEREEN isolé |
| SC-ID-003 | [Redesign Sites & Services](bloc1-ad-onprem/SC-ID-003-sites-services.md) | Concevoir | PowerShell AD Sites | 4 sites, 5 subnets, 2 links |
| SC-ID-004 | [Tiering Model](bloc1-ad-onprem/SC-ID-004-tiering-model.md) | Implémenter | OUs, GPO Deny Logon | 3 tiers, cross-tier bloqué |
| SC-ID-005 | [Audit PingCastle](bloc1-ad-onprem/SC-ID-005-pingcastle-audit.md) | Auditer | PingCastle 3.5 | Score initial : 57/100 |
| SC-ID-006 | [BloodHound — Chemins d'Attaque](bloc1-ad-onprem/SC-ID-006-bloodhound.md) | Auditer | SharpHound, BloodHound | 4 attack paths identifiés |
| SC-ID-007 | [GPO CIS Baseline](bloc1-ad-onprem/SC-ID-007-gpo-cis-baseline.md) | Durcir | GPO, CIS L1 DC | 5 Security Options + Audit |
| SC-ID-008 | [Remédiations Kerberos](bloc1-ad-onprem/SC-ID-008-remediation-kerberos.md) | Durcir | krbtgt, AS-REP, gMSA | 3 remédiations appliquées |
| SC-ID-009 | [PingCastle Post-Hardening](bloc1-ad-onprem/SC-ID-009-pingcastle-post-hardening.md) | Vérifier | PingCastle avant/après | Anomalies : 72→62 |

### Bloc 2 — Entra ID Hybrid (Design & Implémentation)

| # | Scénario | Phase | Outils | Write-up |
|---|---|---|---|---|
| SC-ID-010 | [Tenant Azure & Break Glass](bloc2-entra-hybrid/SC-ID-010-tenant-breakglass.md) | Concevoir | Portail Entra, M365 | 2 BG accounts, P2 active |
| SC-ID-011 | [VM AD Connect (IaC)](bloc2-entra-hybrid/SC-ID-011-vm-adconnect.md) | Implémenter | Terraform, Proxmox | VM provisionned via IaC |
| SC-ID-012 | [AD Connect — Hybrid Identity](bloc2-entra-hybrid/SC-ID-012-adconnect-hybrid.md) | Implémenter | PHS, SSO, Writeback | 2 forêts synchronisées |
| SC-ID-013 | [Conditional Access](bloc2-entra-hybrid/SC-ID-013-conditional-access.md) | Gouverner | CA policies, Named Loc. | 4 policies Report-only |
| SC-ID-014 | [PIM — Privileged Access](bloc2-entra-hybrid/SC-ID-014-pim.md) | Gouverner | PIM, JIT, MFA | 4h max, approbation BG01 |

---

## 🎓 Compétences démontrées

```
Active Directory On-Prem
├── Cartographie multi-forêts / multi-domaines             ✅
├── Diagnostic réplication (repadmin, dcdiag)               ✅
├── Design Sites & Services (sites, subnets, site links)   ✅
├── Tiering Model T0/T1/T2 + GPO Deny Logon               ✅
├── Audit PingCastle + BloodHound                           ✅
├── Hardening CIS Level 1 DC (GPO + Security Options)      ✅
├── Remédiations Kerberos (krbtgt, AS-REP, gMSA)           ✅
└── Mesure d'impact avant/après                             ✅

Entra ID / Hybrid Identity
├── Création tenant + Break Glass accounts                  ✅
├── AD Connect IaC (Terraform + Proxmox)                    ✅
├── PHS + Seamless SSO + Password Writeback                 ✅
├── Sync multi-forêts + filtrage OU                         ✅
├── Conditional Access (4 policies + Named Locations)       ✅
└── PIM (JIT, MFA, justification, approbation)              ✅

Méthodologie & Livrables
├── Write-ups structurés (audit → design → implémentation → vérification)
├── 64 screenshots (preuves visuelles)
├── Runbooks opérationnels (AD Connect, incidents N3)
├── Diagrammes d'architecture (Mermaid)
└── Scripts PowerShell de déploiement
```

---

## ⚠️ Problèmes rencontrés et solutions

| Problème | Cause | Solution |
|---|---|---|
| Portail Entra : bouton Named Locations grisé | Bug UI portail | Création via PowerShell Graph |
| WAM bug PS 5.1 / Windows Server 2019 | Bug connu Microsoft | pwsh 7 WSL + `-UseDeviceCode` |
| PIM "cannot update self assignment" | Limitation PIM | Connexion avec BG01 pour modifier admin |
| DNS WSL cassé | WSL override resolv.conf | `nameserver 8.8.8.8` dans `/etc/resolv.conf` |
| AD Connect wizard bloqué "sync in progress" | Scheduler lock | `Stop-ADSyncSyncCycle` + restart service |
| GOAD VMs réseau incorrect | Confusion vmbr3 vs vmbr4 | VMs sur vmbr4 avec tag=10 |

---

## 👤 Auteur

**hik3nR00t** — Consultant Identity & Sécurité Microsoft
Background : Sysadmin + Pentest → Expert Identity AD / Entra ID

---

## 📄 Alignement certifications

Ce lab couvre le périmètre des certifications suivantes :

| Certification | Couverture |
|---|---|
| **SC-300** — Identity and Access Administrator | ~80% du périmètre (AD Connect, CA, PIM) |
| **AZ-800/801** — Windows Server Hybrid Administrator | AD on-prem, Sites & Services, GPO |
| **DVAG** / **DVAI** — Certification ANSSI | Tiering, Kerberos, PingCastle |
