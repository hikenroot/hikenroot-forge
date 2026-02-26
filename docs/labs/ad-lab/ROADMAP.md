# AD Lab — GOAD Roadmap & Learning Path
**HikenRoot Forge | MediaTech Groupe SA**

> Document de référence central pour l'apprentissage AD offensif.  
> Aligné sur la progression **CRTP → CRTO → CRTE** via GOAD v3 (mayfly277).  
> Même approche que les SC-CLD : un module = une technique = un write-up.

---

## Tableau synthèse — Progression globale

| # | Scénario | Technique principale | Mayfly Part | CRTP | CRTO | CRTE | Statut |
|---|----------|---------------------|-------------|------|------|------|--------|
| SC-AD-001 | Recon & Initial Foothold | nmap, enum4linux, BloodHound collect, LDAP anonyme | Part 1+2 | ✅ | — | — | ✅ Fait |
| SC-AD-002 | Credential Harvesting | LDAP desc, SYSVOL, GPP, AS-REP Roasting, Kerberoasting, Password Spray | Part 2+3 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-003 | NTLM Relay & Poisoning | Responder, LLMNR/NBT-NS, mitm6, ntlmrelayx | Part 4 | ✅ | ✅ | — | ❌ À faire |
| SC-AD-004 | ACL Abuse Chain | ForceChangePwd → GenericWrite → WriteDACL → DA | Part 11 | ✅ | ✅ | — | 🔄 En cours |
| SC-AD-005 | Local & Domain Privesc | SamAccountName, PrintNightmare, KrbRelayUp, IIS upload | Part 5+8 | ✅ | ✅ | — | ❌ À faire |
| SC-AD-006 | MSSQL Pivot | Impersonate, linked servers, xp_cmdshell, UNC coerce | Part 7 | ✅ | ✅ | — | 🔄 Partiel |
| SC-AD-007 | Kerberos Delegation | Unconstrained, Constrained S4U2, RBCD, Shadow Creds | Part 10 | ✅ | ✅ | ✅ | ❌ À faire |
| SC-AD-008 | ADCS Attacks | ESC1/2/3/4/6/8, Certifried, PetitPotam | Part 6 | — | — | ✅ | ❌ À faire |
| SC-AD-009 | Domain Dominance | DCSync, Golden Ticket, Silver Ticket, Persistence | Part 9+11 | ✅ | ✅ | — | ❌ À faire |
| SC-AD-010 | Cross-Forest Trusts | Trust abuse, SID History, cross-domain lateral | Part 12 | — | ✅ | ✅ | ❌ À faire |
| SC-AD-011 | Coerce & File-based | WebDAV, searchConnector-ms, .lnk, PrinterBug | Part 13 | — | ✅ | — | ❌ À faire |
| SC-AD-012 | ADCS Avancé | ESC5/7/9/10/11/13/14/15 | Part 14 | — | — | ✅ | ❌ À faire |

**Légende :** ✅ Fait | 🔄 En cours | ❌ À faire | — Non requis pour cette certif

---

## Progression par certification

### CRTP (Altered Security) — Priorité 1
> Exam 24h — Multi-domaines — Fully patched — Pas d'exploits CVE  
> **Modules obligatoires : SC-AD-001 → 002 → 003 → 004 → 005 → 006 → 007 → 009**

```
[ ] SC-AD-001  Recon & Initial Foothold
[ ] SC-AD-002  Credential Harvesting          ← Kerberoasting, AS-REP, Spray
[ ] SC-AD-003  NTLM Relay & Poisoning         ← Responder, mitm6
[ ] SC-AD-004  ACL Abuse Chain                ← ForceChangePwd → DA
[ ] SC-AD-005  Local & Domain Privesc         ← SamAccountName, PrintNightmare
[ ] SC-AD-006  MSSQL Pivot                    ← Linked servers, xp_cmdshell
[ ] SC-AD-007  Kerberos Delegation            ← Constrained, RBCD
[ ] SC-AD-009  Domain Dominance               ← DCSync, Golden Ticket
```

### CRTO (Zero Point Security) — Priorité 2
> Exam 4 jours / 48h — Cobalt Strike — Focus OPSEC  
> **Modules obligatoires : tout CRTP + SC-AD-010 → 011**

```
[ ] Tout le CRTP +
[ ] SC-AD-010  Cross-Forest Trusts            ← SID History, trust abuse
[ ] SC-AD-011  Coerce & File-based            ← WebDAV, searchConnector-ms
[ ] C2 Setup   Sliver/Havoc contre GOAD       ← Beacon, pivoting, OPSEC
```

### CRTE (Altered Security) — Priorité 3
> Exam 48h — Multi-forest — ADCS avancé — Azure AD hybride  
> **Modules obligatoires : tout CRTO + SC-AD-008 → 012**

```
[ ] Tout le CRTO +
[ ] SC-AD-008  ADCS Attacks                   ← ESC1/4/8, Certifried
[ ] SC-AD-012  ADCS Avancé                    ← ESC5/7/9/10/11/13
[ ] Entra ID   Azure AD hybride               ← AADInternals, ROADtools
```

---

## Ordre de travail recommandé

Suivre la progression mayfly277 dans l'ordre — chaque partie construit sur la précédente :

```
Part 1+2  → SC-AD-001  ✅ Fait
Part 2+3  → SC-AD-002  ✅ Fait
Part 4    → SC-AD-003  ← PROCHAIN (Responder + NTLM Relay)
Part 5    → SC-AD-005a (SamAccountName, PrintNightmare)
Part 6    → SC-AD-008  (ADCS session dédiée)
Part 7    → SC-AD-006  (MSSQL — compléter)
Part 8    → SC-AD-005b (IIS + Privesc locale)
Part 9    → SC-AD-009  (Lateral Movement + Dominance)
Part 10   → SC-AD-007  (Delegation)
Part 11   → SC-AD-004  (ACL Abuse — compléter)
Part 12   → SC-AD-010  (Trusts)
Part 13   → SC-AD-011  (Coerce + File-based)
Part 14   → SC-AD-012  (ADCS avancé)
```

---

## Credentials GOAD — État actuel

| Utilisateur | Mot de passe | Domaine | Source | Statut |
|-------------|-------------|---------|--------|--------|
| samwell.tarly | Via LDAP desc | north.sevenkingdoms.local | SC-AD-001 | ✅ |
| brandon.stark | Via AS-REP | north.sevenkingdoms.local | SC-AD-002 | ✅ |
| hodor | hodor | north.sevenkingdoms.local | SC-AD-002 | ✅ |
| jon.snow | Via Kerberoast | north.sevenkingdoms.local | SC-AD-002 | ✅ |
| jeor.mormont | Via SYSVOL | north.sevenkingdoms.local | SC-AD-001 | ✅ |
| tywin.lannister | powerkingftw135 | sevenkingdoms.local | SC-AD-001 | ✅ |
| jaime.lannister | Hacked123! | sevenkingdoms.local | SC-AD-004 | ✅ ACL |
| missandei | fr3edom | essos.local | SC-AD-002 | ✅ |
| viserys.targaryen | GoldCrown | essos.local | SC-AD-002 | 🔄 Kerberoast |

---

## Infrastructure GOAD — Référence rapide

| Machine | IP | Domaine | Signing | SMBv1 | Rôle |
|---------|-----|---------|---------|-------|------|
| KINGSLANDING | 192.168.10.10 | sevenkingdoms.local | ✅ True | ❌ | DC01 |
| WINTERFELL | 192.168.10.11 | north.sevenkingdoms.local | ✅ True | ❌ | DC02 |
| MEEREEN | 192.168.10.12 | essos.local | ✅ True | ✅ | DC03 |
| CASTELBLACK | 192.168.10.22 | north.sevenkingdoms.local | ❌ **False** | ❌ | SRV — MSSQL + IIS |
| BRAAVOS | 192.168.10.23 | essos.local | ❌ **False** | ✅ | SRV — MSSQL |

> ⚠️ **CASTELBLACK et BRAAVOS** = cibles NTLM relay (signing:False)

---

## Write-ups disponibles

| Fichier | Technique | Date |
|---------|-----------|------|
| [SC-AD-001](./SC-AD-001-recon-and-initial-foothold.md) | Recon & Initial Foothold | — |
| [SC-AD-002](./SC-AD-002-credential-harvesting.md) | Credential Harvesting | — |
| [SC-AD-003](./SC-AD-003-ntlm-relay-and-poisoning.md) | NTLM Relay & Poisoning | ❌ |
| [SC-AD-004](./SC-AD-004-acl-abuse-chain.md) | ACL Abuse Chain | 🔄 |
| [SC-AD-005](./SC-AD-005-privesc.md) | Privesc locale & domaine | ❌ |
| [SC-AD-006](./SC-AD-006-mssql-pivot.md) | MSSQL Pivot | 🔄 |
| [SC-AD-007](./SC-AD-007-kerberos-delegation.md) | Kerberos Delegation | ❌ |
| [SC-AD-008](./SC-AD-008-adcs-attacks.md) | ADCS Attacks | ❌ |
| [SC-AD-009](./SC-AD-009-domain-dominance.md) | Domain Dominance | ❌ |
| [SC-AD-010](./SC-AD-010-cross-forest-trusts.md) | Cross-Forest Trusts | ❌ |
| [SC-AD-011](./SC-AD-011-coerce-file-based.md) | Coerce & File-based | ❌ |
| [SC-AD-012](./SC-AD-012-adcs-advanced.md) | ADCS Avancé | ❌ |

---

## Ressources de référence

| Ressource | URL | Usage |
|-----------|-----|-------|
| Mayfly277 GOAD Blog | https://mayfly277.github.io | Walkthrough officiel Part 1-14 |
| GOAD GitHub | https://github.com/Orange-Cyberdefense/GOAD | Source + data (passwords) |
| CRTP Syllabus | https://www.alteredsecurity.com/adlab | Objectifs certif |
| CRTO Syllabus | https://www.zeropointsecurity.co.uk/course/red-team-ops | Objectifs certif |
| CRTE Syllabus | https://www.alteredsecurity.com/redteamlab | Objectifs certif |
| HackTricks AD | https://book.hacktricks.xyz/windows-hardening/active-directory-methodology | Référence technique |
| ired.team | https://www.ired.team | Notes AD offensif |

---

*Auteur : Nadyr Chouarhi (hik3nR00t) | HikenRoot Forge | Février 2026*
