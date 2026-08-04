# SC-300 — Microsoft Identity and Access Administrator · Labs réels

> **Preuve de compétence par la pratique**, pas par le bachotage.
> Tous les labs de la certification **SC-300** réalisés sur un **tenant Microsoft Entra ID P2 réel**, documentés en write-ups professionnels au format « attaque/défense ».

**Auteur :** `hik3nR00t` · **Projet :** HikenRoot Forge · **Tenant :** Entra ID P2 (domaine custom)

---

## 🎯 Objectif

Ce dossier documente l'intégralité du **périmètre core SC-300 (20 labs)**, chaque lab étant :
- **exécuté en conditions réelles** sur un tenant Entra ID P2 (pas un tenant de démo jetable) ;
- **prouvé** par captures d'écran, journaux d'audit, codes d'erreur et sorties Graph/KQL réelles ;
- documenté au **format maison 13 sections**, cadré autour d'une entreprise fictive fil rouge : **MediaTech Groupe SA**.

Chaque write-up dépasse le lab officiel Microsoft : il ajoute les **pièges terrain 2026** (fonctionnalités dépréciées, blades en lecture seule, migrations forcées), une couche **détection SOC/SIEM (KQL)**, un mapping **ISO 27001 / NIS2 / MITRE D3FEND**, et une lecture **impact métier (COMEX)**.

> ⚠️ Le scénario **MediaTech Groupe SA** est un cadre narratif **fictif** assumé (contexte métier, estimations financières illustratives). Les manipulations, preuves techniques et configurations sont, elles, **réelles**.

---

## 📐 Format maison (13 sections)

1. Classification (code, domaine SC-300, ISO 27001, NIS2, MITRE D3FEND, réf lab, auteur)
2. Contexte & scénario (MediaTech Groupe SA)
3. Résumé exécutif (recruteur / auditeur ISO-NIS2 / RSSI)
4. Objectif & périmètre
5. Prérequis
6. Procédure de mise en œuvre (captures pas-à-pas, session breakglass01)
7. Vérification & preuves d'audit (checklist + **Graph PowerShell**)
8. Impact métier MediaTech (financier, réglementaire, actions 0-24h/1sem/1mois, décisions COMEX)
9. Détection SOC / SIEM (**requêtes KQL** vérifiées)
10. Pièges rencontrés (terrain)
11. Durcissement continu
12. Points d'examen SC-300
13. Références

---

## 📚 Les 20 write-ups (core SC-300)

### D1 — Implémenter les identités
| # | Write-up | Sujet |
|---|----------|-------|
| 01 | [Manage User Roles](SC-300-01-manage-user-roles.md) | Attribution de rôles d'annuaire |
| 02 | [Tenant & Custom Domain](SC-300-02-tenant-custom-domain.md) | Domaine personnalisé + vérification DNS |
| 03 | [Licenses by Group Membership](SC-300-03-licenses-group-membership.md) | Licences par appartenance de groupe |
| 04 | [External Collaboration](SC-300-04-external-collaboration.md) | Paramètres de collaboration externe |
| 05 | [Guest Users](SC-300-05-guest-users.md) | Ajout d'invités à l'annuaire |
| 06 | [Federated IdP](SC-300-06-federated-idp.md) | Fournisseur d'identité fédéré |

### D2 — Authentification & gestion des accès
| # | Write-up | Sujet |
|---|----------|-------|
| 08 | [Enable MFA](SC-300-08-enable-mfa.md) | MFA via Conditional Access + per-user |
| 09 | [Self-Service Password Reset](SC-300-09-sspr.md) | SSPR ciblé par groupe |
| 12 | [Smart Lockout](SC-300-12-smart-lockout.md) | Verrouillage intelligent |
| 13 | [Conditional Access](SC-300-13-conditional-access.md) | Blocage app + What If + fréquence de connexion |
| 14 | [Risk Policies](SC-300-14-risk-policies.md) | Risque utilisateur & connexion (via CA) |
| 15 | [MFA Registration Policy](SC-300-15-mfa-registration-policy.md) | Inscription MFA forcée |

### D3 — Gestion des accès aux applications
| # | Write-up | Sujet |
|---|----------|-------|
| 19 | [Register an Application](SC-300-19-register-application.md) | Enregistrement d'application |
| 20 | [Access Management for Apps](SC-300-20-access-management-apps.md) | Gestion des accès applicatifs |
| 21 | [Tenant-Wide Admin Consent](SC-300-21-admin-consent.md) | Consentement administrateur |

### D4 — Gouvernance des identités
| # | Write-up | Sujet |
|---|----------|-------|
| 22 | [Entitlement Management Catalog](SC-300-22-entitlement-catalog.md) | Catalogue de ressources + délégation |
| 23 | [Terms of Use](SC-300-23-terms-of-use.md) | Conditions d'utilisation imposées via CA |
| 24 | [Lifecycle of External Users](SC-300-24-lifecycle-external-users.md) | Déprovisionnement automatique des invités |
| 25 | [Access Reviews](SC-300-25-access-reviews.md) | Revues d'accès récurrentes |

### Monitoring & posture (transversal)
| # | Write-up | Sujet |
|---|----------|-------|
| 28 | [Identity Secure Score](SC-300-28-identity-secure-score.md) | Surveillance de la posture d'identité |

---

## 🧪 Pièges terrain notables (valeur ajoutée vs lab officiel)

Le lab officiel Microsoft n'est pas toujours à jour. Ces write-ups documentent la **réalité 2026** :

- **Stratégies de risque legacy en lecture seule** (SC-300-14) — retrait au 01/10/2026, migration **Conditional Access** obligatoire.
- **Per-user MFA déprécié** (SC-300-08) — remplacé par les Authentication methods policies + CA.
- **Terms of Use déplacées** sous *Accès conditionnel* (SC-300-23), plus sous Entitlement Management.
- **Gouvernance des invités** (SC-300-22/24/25) — abonnement Azure lié requis (facturation à partir du 15/01/2026).
- **Précédence Conditional Access** : `Bloquer > Octroyer` (SC-300-13), code `53003 = BlockedByConditionalAccess`.

---

## 🔧 Méthode & garanties

- **Session privilégiée** : `breakglass01` (Global Admin), comptes break-glass **systématiquement exclus** des CA (anti-lockout).
- **Secrets & IP publiques floutés** dans toutes les captures.
- **Snippets KQL & PowerShell vérifiés** contre les schémas Microsoft officiels (SigninLogs, AADUserRiskEvents, Microsoft.Graph.Identity.Governance).
- **Preuves réelles** : number matching MFA, journaux d'audit signés, codes d'erreur, sorties Graph.

---

## 🔗 Cross-références

- [`m365-admin-toolkit`](https://github.com/hikenroot/m365-admin-toolkit) — audit & durcissement M365 en PowerShell (inventaire CA, couverture MFA, comptes orphelins).
- [`ad-hardening-baseline`](https://github.com/hikenroot/ad-hardening-baseline) — baseline de durcissement identité.

## 📈 Suite

Voir [`ROADMAP.md`](ROADMAP.md) pour le suivi complet (20/20 core faits + labs reportés vers AZ-500 / SC-200).

---

*HikenRoot Forge — SC-300 core bouclé — hik3nR00t — Août 2026*
