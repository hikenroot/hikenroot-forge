# SC-ID-007 — GPO CIS Baseline

## Classification

| Champ | Valeur |
|-------|--------|
| **Code scénario** | SC-ID-007 |
| **Nom** | GPO CIS Baseline — Durcissement des Domain Controllers selon CIS Level 1 |
| **Cible** | GOAD v3 — OU Domain Controllers (DC01, DC02) |
| **Phase** | Phase 3 — Durcir |
| **Référentiel** | CIS Benchmark Level 1 — Windows Server 2019 DC |
| **Date** | Mars 2026 |
| **Auteur** | Nadyr Chouarhi (hik3nR00t) |

---

## Résumé exécutif

### Pour un recruteur

Le CIS (Center for Internet Security) est le standard de référence pour le hardening des systèmes. Ce scénario crée et applique une GPO basée sur le **CIS Benchmark Level 1 pour les Domain Controllers**, couvrant 11 paramètres de sécurité critiques. C'est le type de GPO qu'un architecte Identity conçoit et déploie en mission de durcissement AD. Le référentiel CIS est auditable et accepté par les régulateurs (SOX, ISO 27001, HDS, NIS2).

### Pour un RSSI

Le Level 1 CIS représente le minimum de sécurité sans impact fonctionnel significatif. Les 11 paramètres couvrent la politique de mots de passe, le verrouillage de comptes, les protocoles d'authentification, et les droits utilisateur. Le déploiement en mode "Report-only" suivi d'un test sur un périmètre réduit est la méthode standard en production.

---

## GPO créée

**Nom :** `CIS-L1-DC-Baseline`
**Liée à :** OU `Domain Controllers`
**Référentiel :** CIS Benchmark Level 1 — Windows Server 2019 DC

---

## 11 paramètres configurés

### Politique de mots de passe

| Paramètre | Valeur CIS | Pourquoi |
|---|---|---|
| Longueur minimale du mot de passe | 14 caractères | Résistance au brute-force |
| Historique des mots de passe | 24 derniers | Empêche la réutilisation |
| Durée de vie maximale | 365 jours | Force le renouvellement annuel |
| Complexité requise | Activée | Majuscule + minuscule + chiffre + spécial |

### Verrouillage de comptes

| Paramètre | Valeur CIS | Pourquoi |
|---|---|---|
| Seuil de verrouillage | 5 tentatives | Bloque le password spray |
| Durée de verrouillage | 15 minutes | Ralentit les attaques automatisées |
| Réinitialisation du compteur | 15 minutes | Cohérent avec la durée de verrouillage |

### Protocoles et droits

| Paramètre | Valeur CIS | Pourquoi |
|---|---|---|
| LAN Manager auth level | NTLMv2 uniquement (niveau 5) | Bloque NTLM v1 / LM (crackable) |
| LDAP signing | Requis | Empêche le LDAP relay |
| SMB signing | Requis | Empêche le SMB relay |
| Anonymous SID enumeration | Désactivé | Bloque l'énumération anonyme |

---

## Déploiement

```powershell
# Création de la GPO
New-GPO -Name "CIS-L1-DC-Baseline" -Comment "CIS Benchmark Level 1 - Domain Controllers"

# Application des paramètres via Set-GPRegistryValue ou LGPO
# (chaque paramètre configuré individuellement)

# Liaison à l'OU Domain Controllers
New-GPLink -Name "CIS-L1-DC-Baseline" -Target "OU=Domain Controllers,DC=sevenkingdoms,DC=local"
```

## Vérification

```powershell
# Vérifier l'application sur un DC
gpresult /r /scope computer
gpresult /h gpo-report.html  # Rapport HTML complet
```

---

## Correspondance mission client

| Étape lab | Équivalent mission client |
|---|---|
| Choix référentiel CIS L1 | Validation avec le RSSI du niveau de durcissement acceptable |
| Création GPO + 11 settings | Implémentation en environnement de recette d'abord |
| Link sur OU DC | Déploiement contrôlé — change management |
| gpresult vérification | PV de recette + rapport de conformité |
