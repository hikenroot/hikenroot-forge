# AD Lab — GOAD Roadmap & Learning Path
HikenRoot Forge | MediaTech Groupe SA

Document de référence central pour l'apprentissage AD offensif.
Aligné sur la progression CRTP → CRTO → CRTE via GOAD v3 (mayfly277).
Un module = une technique = un write-up.

---

## Tableau synthèse — Progression globale

| # | Scénario | Technique principale | Mayfly Part | CRTP | CRTO | CRTE | Statut |
|---|----------|---------------------|-------------|------|------|------|--------|
| SC-AD-001 | Recon & Initial Foothold | nmap, enum4linux, BloodHound, LDAP anonyme | Part 1+2 | ✅ | — | — | ✅ Fait |
| SC-AD-002 | Credential Harvesting | LDAP desc, SYSVOL, AS-REP, Kerberoast, Spray | Part 2+3 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-003 | NTLM Relay & Poisoning | Responder, LLMNR/NBT-NS, mitm6, ntlmrelayx | Part 4 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-004 | ACL Abuse Chain | ForceChangePwd → GenericWrite → WriteDACL → DA | Part 11 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-005 | Local & Domain Privesc | noPac CVE-2021-42278/42287, PrintNightmare CVE-2021-1675 | Part 5+8 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-006 | MSSQL Pivot | Impersonate, linked servers, xp_cmdshell | Part 7 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-007 | Kerberos Delegation | Unconstrained, Constrained S4U2, RBCD, Shadow Creds | Part 10 | ✅ | ✅ | ✅ | ✅ Fait |
| SC-AD-008 | ADCS Attacks | ESC1/2/3/4/6/8, Certifried, PetitPotam | Part 6 | — | — | ✅ | ✅ Fait |
| SC-AD-009 | Domain Dominance | DCSync, Golden Ticket, Silver Ticket, Persistence | Part 9+11 | ✅ | ✅ | — | ✅ Fait |
| SC-AD-010 | Cross-Forest Trusts | Trust abuse, SID History, cross-domain lateral | Part 12 | — | ✅ | ✅ | ✅ Fait |
| SC-AD-011 | Coerce & File-based | WebDAV, searchConnector-ms, .lnk, PrinterBug | Part 13 | — | ✅ | — | ✅ Fait |
| SC-AD-012 | ADCS Avancé | ESC5/7/9/10/11/13/14/15 | Part 14 | — | — | ✅ | ✅ Fait |

**Légende :** ✅ Fait | ❌ À faire | — Non requis pour cette certif

---

## Progression par certification

### CRTP (Altered Security) — Priorité 1
> Exam 24h — Multi-domaines — Fully patched — Pas d'exploits CVE
> **Modules obligatoires : SC-AD-001 → 002 → 003 → 004 → 005 → 006 → 007 → 009**

```
[x] SC-AD-001  Recon & Initial Foothold       ✅
[x] SC-AD-002  Credential Harvesting          ✅
[x] SC-AD-003  NTLM Relay & Poisoning         ✅
[x] SC-AD-004  ACL Abuse Chain                ✅
[x] SC-AD-005  Local & Domain Privesc         ✅
[x] SC-AD-006  MSSQL Pivot                    ✅
[x] SC-AD-007  Kerberos Delegation            ✅
[x] SC-AD-009  Domain Dominance  ✅
```

### CRTO (Zero Point Security) — Priorité 2
> Exam 4 jours / 48h — Cobalt Strike — Focus OPSEC
> **Modules obligatoires : tout CRTP + SC-AD-010 → 011**

```
[x] Tout le CRTP (SC-AD-001 à 006) ✅
[x] SC-AD-007  Kerberos Delegation  ✅
[x] SC-AD-009  Domain Dominance  ✅
[x] SC-AD-010  Cross-Forest Trusts  ✅
[x] SC-AD-011  Coerce & File-based  ✅
[ ] C2 Setup   Sliver/Havoc contre GOAD
```

### CRTE (Altered Security) — Priorité 3
> Exam 48h — Multi-forest — ADCS avancé — Azure AD hybride
> **Modules obligatoires : tout CRTO + SC-AD-008 → 012**

```
[ ] Tout le CRTO +
[x] SC-AD-008  ADCS Attacks  ✅
[x] SC-AD-012  ADCS Avancé  ✅
[ ] Entra ID   Azure AD hybride
```

---

## Ordre de travail recommandé

```
Part 1+2  → SC-AD-001  ✅ Fait
Part 2+3  → SC-AD-002  ✅ Fait
Part 4    → SC-AD-003  ✅ Fait
Part 5+8  → SC-AD-005  ✅ Fait (noPac + PrintNightmare)
Part 6    → SC-AD-008  ✅ Fait
Part 7    → SC-AD-006  ✅ Fait
Part 9    → SC-AD-009  ✅ Fait
Part 10   → SC-AD-007  ✅ Fait
Part 11   → SC-AD-004  ✅ Fait
Part 12   → SC-AD-010  ✅ Fait
Part 13   → SC-AD-011  ✅ Fait
Part 14   → SC-AD-012  ✅ Fait
```

---

## Credentials GOAD — État actuel

| Utilisateur | Mot de passe | Domaine | Source | Statut |
|-------------|-------------|---------|--------|--------|
| samwell.tarly | Heartsbane | north.sevenkingdoms.local | SC-AD-001 | ✅ |
| brandon.stark | iseedeadpeople | north.sevenkingdoms.local | SC-AD-002 | ✅ |
| hodor | hodor | north.sevenkingdoms.local | SC-AD-002 | ✅ |
| jon.snow | iknownothing | north.sevenkingdoms.local | SC-AD-002 | ✅ |
| jeor.mormont | _L0ngCl@w_ | north.sevenkingdoms.local | SC-AD-001 | ✅ |
| tywin.lannister | powerkingftw135 | sevenkingdoms.local | SC-AD-001 | ✅ |
| jaime.lannister | Hacked123! | sevenkingdoms.local | SC-AD-004 | ✅ |
| missandei | fr3edom | essos.local | SC-AD-002 | ✅ |
| viserys.targaryen | GoldCrown | essos.local | SC-AD-002 | ✅ |
| jorah.mormont | H0nnor! | essos.local | SC-AD-006 | ✅ |
| robb.stark | sexywolfy | north.sevenkingdoms.local | SC-AD-005 LSA | ✅ |
| Administrator (north) | dbd13e1c4e338284ac4e9874f7de6ef4 | north | SC-AD-005 noPac DCSync | ✅ |
| krbtgt (north) | 5883cbf00ea968b503b20628fb83cc55 | north | SC-AD-005 noPac DCSync | ✅ |
| Administrator (essos) | 54296a48cd30259cc88095373cec24da | essos | SC-AD-005 PrintNightmare DCSync | ✅ |
| krbtgt (essos) | 1d8956cac33793f4d9f14f67eb40ec2a | essos | SC-AD-005 PrintNightmare DCSync | ✅ |

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

| Fichier | Technique | Statut |
|---------|-----------|--------|
| [SC-AD-001](./SC-AD-001-recon-and-initial-foothold.md) | Recon & Initial Foothold | ✅ |
| [SC-AD-002](./SC-AD-002-credential-harvesting.md) | Credential Harvesting | ✅ |
| [SC-AD-003](./SC-AD-003-NTLM-Relay-Poisoning.md) | NTLM Relay & Poisoning | ✅ |
| [SC-AD-004](./SC-AD-004-acl-abuse-chain.md) | ACL Abuse Chain | ✅ |
| [SC-AD-005](./SC-AD-005-nopac-samaccountname-spoofing.md) | noPac + PrintNightmare | ✅ |
| [SC-AD-006](./SC-AD-006-mssql-pivot.md) | MSSQL Pivot | ✅ |
| [SC-AD-007](./SC-AD-007-kerberos-delegation.md) | Kerberos Delegation | ✅ |
| [SC-AD-008](./SC-AD-008-adcs-certificate-abuse.md) | ADCS Attacks | ✅ |
| [SC-AD-009](./SC-AD-009-domain-dominance.md) | Domain Dominance | ✅ |
| [SC-AD-010](./SC-AD-010-cross-forest-trusts.md) | Cross-Forest Trusts | ✅ |
| [SC-AD-011](./SC-AD-011-coerce-file-based-attacks.md) | Coerce & File-based | ✅ |
| [SC-AD-012](./SC-AD-012-adcs-advanced.md) | ADCS Avancé | ✅ |

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

*Auteur : hik3nR00t | HikenRoot Forge | Mars 2026*
*Dernière mise à jour : 06 août 2026*
