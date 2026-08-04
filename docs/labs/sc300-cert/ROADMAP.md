# SC-300 — ROADMAP

**Statut global : ✅ Périmètre core = 20 / 20 (100 %)** · Auteur `hik3nR00t` · Août 2026

Repo labs officiels suivi : `MicrosoftLearning/SC-300-Identity-and-Access-Administrator` → `Instructions/Labs/`.
Tenant : Microsoft Entra ID **P2** (domaine custom).

**Légende :** ✅ Fait & poussé · `[→]` Reporté (hors périmètre SC-300, intentionnel)

---

## D1 — Implémenter les identités (20-25 %)

| # | Lab | Statut | Write-up |
|---|-----|--------|----------|
| 01 | Manage User Roles | ✅ | [lien](SC-300-01-manage-user-roles.md) |
| 02 | Working with Tenant Properties (domaine custom) | ✅ | [lien](SC-300-02-tenant-custom-domain.md) |
| 03 | Assign Licenses by Group Membership | ✅ | [lien](SC-300-03-licenses-group-membership.md) |
| 04 | Configure External Collaboration | ✅ | [lien](SC-300-04-external-collaboration.md) |
| 05 | Add Guest Users | ✅ | [lien](SC-300-05-guest-users.md) |
| 06 | Add a Federated Identity Provider | ✅ | [lien](SC-300-06-federated-idp.md) |
| 07 | Hybrid Identity (Entra Connect) | `[→]` AZ-500 | — (AD on-prem + Azure requis) |

## D2 — Authentification & gestion des accès (25-30 %)

| # | Lab | Statut | Write-up |
|---|-----|--------|----------|
| 08 | Enable Multi-Factor Authentication | ✅ | [lien](SC-300-08-enable-mfa.md) |
| 09 | Self-Service Password Reset | ✅ | [lien](SC-300-09-sspr.md) |
| 10 | Entra Auth for Windows & Linux VMs | `[→]` AZ-500 | — (abo Azure requis) |
| 12 | Manage Smart Lockout Values | ✅ | [lien](SC-300-12-smart-lockout.md) |
| 13 | Implement & Test a Conditional Access Policy | ✅ | [lien](SC-300-13-conditional-access.md) |
| 14 | Enable Sign-in & User Risk Policies | ✅ | [lien](SC-300-14-risk-policies.md) |
| 15 | Configure an MFA Registration Policy | ✅ | [lien](SC-300-15-mfa-registration-policy.md) |

## D3 — Gestion des accès aux applications (10-15 %)

| # | Lab | Statut | Write-up |
|---|-----|--------|----------|
| 16 | Azure Key Vault for Managed Identities | `[→]` AZ-500 | — (abo Azure requis) |
| 17 | Defender for Cloud Apps — Discovery | `[→]` SC-200 | — (licence MDCA requise) |
| 18 | Defender for Cloud Apps — Access Policies | `[→]` SC-200 | — (licence MDCA requise) |
| 19 | Register an Application | ✅ | [lien](SC-300-19-register-application.md) |
| 20 | Implement Access Management for Apps | ✅ | [lien](SC-300-20-access-management-apps.md) |
| 21 | Grant Tenant-Wide Admin Consent | ✅ | [lien](SC-300-21-admin-consent.md) |

## D4 — Gouvernance des identités (20-25 %)

| # | Lab | Statut | Write-up |
|---|-----|--------|----------|
| 11 | Assign Azure Resource Roles in PIM | `[→]` AZ-500 | — (ressources Azure ≠ rôles Entra) |
| 22 | Catalog in Entitlement Management | ✅ | [lien](SC-300-22-entitlement-catalog.md) |
| 23 | Add Terms of Use & Acceptance Reporting | ✅ | [lien](SC-300-23-terms-of-use.md) |
| 24 | Lifecycle of External Users | ✅ | [lien](SC-300-24-lifecycle-external-users.md) |
| 25 | Creating Access Reviews | ✅ | [lien](SC-300-25-access-reviews.md) |

> Note : la configuration **PIM pour rôles Entra** (Lab 26 officiel) est couverte de façon consolidée dans le write-up **domaine custom + PIM** (SC-300-02).

## Monitoring & posture (transversal)

| # | Lab | Statut | Write-up |
|---|-----|--------|----------|
| 27 | Sentinel Kusto Queries for Entra Data | `[→]` SC-200 | — (abo Azure + Sentinel requis) |
| 28 | Monitor Posture with Identity Secure Score | ✅ | [lien](SC-300-28-identity-secure-score.md) |

---

## Synthèse

| Bloc | Fait | Total core | Reportés |
|------|------|-----------|----------|
| D1 | 6 | 6 | 07 → AZ-500 |
| D2 | 6 | 6 | 10 → AZ-500 |
| D3 | 3 | 3 | 16 → AZ-500 · 17/18 → SC-200 |
| D4 | 4 | 4 | 11 → AZ-500 |
| Monitoring | 1 | 1 | 27 → SC-200 |
| **Total** | **20** | **20** ✅ | 7 reportés (intentionnels) |

**Reportés = 7 labs** hors périmètre SC-300 (nécessitent abo Azure, licence MDCA ou AD hybride) : 07, 10, 11, 16, 17, 18, 27. Ils seront traités dans les parcours **AZ-500** et **SC-200**.

---

## Prochaines certifications (HikenRoot Forge)

- **CRTP** (Altered Security) — priorité 1
- **AZ-500** — reprise des labs 07/10/11/16
- **SC-200** — reprise des labs 17/18/27 (+ Sentinel KQL)

---

*HikenRoot Forge — ROADMAP SC-300 — hik3nR00t — Août 2026*
