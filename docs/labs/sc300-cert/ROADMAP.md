# SC-300 Cert Lab — Roadmap

Progression de préparation à l'examen **SC-300** sur tenant Entra réel (`nchouarhipm.onmicrosoft.com`, Entra ID P2, domaine `hikenroot.fr`).
Chaque write-up reproduit un ou plusieurs labs officiels [MicrosoftLearning/SC-300](https://github.com/MicrosoftLearning/SC-300-Identity-and-Access-Administrator) au format maison HikenRoot Forge.

**Prérequis** : `Tenant` = direct · `P1`/`P2` = licence Entra · `Azure` = abo Azure · `MDCA` = Defender for Cloud Apps · `Hybrid` = AD on-prem.

---

## Write-ups

| Write-up | Sujet | Labs officiels | Domaine | Prérequis | Statut |
|----------|-------|----------------|---------|-----------|--------|
| SC-300-01 | Gestion utilisateurs & rôles | `Lab_01` | D1 | Tenant | 🔄 En cours |
| [SC-300-02](./SC-300-02-tenant-custom-domain.md) | Domaine custom + PIM least-privilege | `Lab_02` + `Lab_26` | D1 + D4 | P2 | ✅ Fait |

---

## Domaines d'examen & couverture

**D1 — Implement identities (20-25%)**
```
[~] SC-300-01  Manage User Roles              Lab_01   Tenant
[✓] SC-300-02  Tenant Properties / Domaine    Lab_02   Tenant
[ ] SC-300-03  Licenses by Group Membership   Lab_03   P1
[ ] SC-300-04  External Collaboration         Lab_04   Tenant
[ ] SC-300-05  Guest Users                    Lab_05   Tenant
[ ] SC-300-06  Federated Identity Provider    Lab_06   Tenant
[ ] SC-300-07  Hybrid Identity (Entra Connect) Lab_07  Hybrid·Azure
```

**D2 — Authentication & access management (25-30%)**
```
[ ] SC-300-08  Multi-Factor Authentication    Lab_08   Tenant/P1
[ ] SC-300-09  Self-Service Password Reset     Lab_09   P1
[ ] SC-300-10  Entra Auth Win/Linux VMs        Lab_10   Azure
[ ] SC-300-12  Smart Lockout                   Lab_12   Tenant
[ ] SC-300-13  Conditional Access Policy       Lab_13   P1
[ ] SC-300-14  Sign-in & User Risk Policies    Lab_14   P2
[ ] SC-300-15  MFA Registration Policy         Lab_15   P2
```

**D3 — Access management for apps (10-15%)**
```
[ ] SC-300-16  Key Vault Managed Identities    Lab_16   Azure
[ ] SC-300-17  Defender for Cloud Apps Discovery Lab_17 MDCA
[ ] SC-300-18  Defender for Cloud Apps Policies  Lab_18 MDCA·P1
[ ] SC-300-19  Register an Application         Lab_19   Tenant
[ ] SC-300-20  Access Management for Apps      Lab_20   Tenant
[ ] SC-300-21  Tenant-Wide Admin Consent       Lab_21   Tenant
```

**D4 — Identity governance (20-25%)**
```
[ ] SC-300-11  Azure Resource Roles in PIM     Lab_11   Azure·P2
[ ] SC-300-22  Entitlement Management Catalog  Lab_22   P2
[ ] SC-300-23  Terms of Use                    Lab_23   P1
[ ] SC-300-24  Lifecycle of External Users     Lab_24   P2
[ ] SC-300-25  Access Reviews                  Lab_25   P2
[✓] SC-300-26  PIM for Entra Roles (→ SC-300-02) Lab_26  P2
```

**Monitoring & posture (transversal)**
```
[ ] SC-300-27  Sentinel Kusto Queries          Lab_27   Azure
[ ] SC-300-28  Identity Secure Score           Lab_28   Tenant
```

---

## Ordre de travail recommandé

1. **Bloc tenant seul** (aucun extra) : 01, 02✓, 04, 05, 06, 12, 19, 20, 21, 28
2. **Bloc P1/P2** (licence couverte) : 03, 08, 09, 13, 14, 15, 22, 23, 24, 25, 26✓
3. **Bloc Azure requis** (free tier OK) : 10, 11, 16, 27
4. **Bloc MDCA** (trial 90 j) : 17, 18
5. **Optionnel/lourd** : 07 (hybride — VM + AD DS)

> Avec le tenant P2 seul : **~22 labs sur 29** faisables direct.

---

## Synergie toolkits

Les configurations défensives produites ici sont auditables/durcissables via [`m365-admin-toolkit`](https://github.com/hikenroot/m365-admin-toolkit) (section « Durcissement » de chaque write-up).

---

*Auteur : Nadyr Chouarhi (hik3nR00t) | HikenRoot Forge*
