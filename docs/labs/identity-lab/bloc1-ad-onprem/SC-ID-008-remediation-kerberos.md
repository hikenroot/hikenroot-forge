# SC-ID-008 — Remédiations Kerberos

## Classification

| Champ | Valeur |
|-------|--------|
| **Code scénario** | SC-ID-008 |
| **Nom** | Remédiations Kerberos — Rotation krbtgt, fix AS-REP, gMSA |
| **Cible** | GOAD v3 — sevenkingdoms.local |
| **Phase** | Phase 3 — Durcir |
| **Référentiel** | Microsoft Kerberos Security, ANSSI, CIS |
| **Date** | Mars 2026 |
| **Auteur** | Nadyr Chouarhi (hik3nR00t) |

---

## Résumé exécutif

### Pour un recruteur

Ce scénario corrige les 3 vulnérabilités Kerberos les plus critiques identifiées dans l'environnement GOAD : rotation du compte **krbtgt** (protection contre les Golden Tickets), désactivation de l'**AS-REP Roasting** sur les comptes vulnérables, et déploiement d'un **gMSA** (Group Managed Service Account) pour remplacer les comptes de service avec mots de passe statiques. Ce sont les remédiations les plus demandées en mission post-audit AD.

### Pour un RSSI

Le compte krbtgt est la clé de voûte de Kerberos — s'il est compromis (Golden Ticket), un attaquant peut forger n'importe quel ticket d'authentification indéfiniment. La rotation régulière de ce mot de passe est une mesure de sécurité fondamentale. L'AS-REP Roasting permet à un attaquant de craquer les mots de passe de certains comptes offline sans interaction. Le gMSA élimine le risque de mots de passe statiques sur les comptes de service.

---

## Remédiation 1 — Rotation krbtgt

### Pourquoi

Le mot de passe du compte `krbtgt` est utilisé pour chiffrer tous les tickets Kerberos (TGT). S'il n'a jamais été changé depuis la création du domaine, un attaquant qui l'obtient (via DCSync) peut forger des Golden Tickets valides indéfiniment. La rotation invalide les anciens tickets.

### Procédure

```powershell
# Vérifier la date du dernier changement
Get-ADUser krbtgt -Properties PasswordLastSet | Select PasswordLastSet

# Rotation (2 rotations espacées de 12-24h en prod)
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString "ComplexP@ss2026!" -AsPlainText -Force)
```

**Impact en prod :** La rotation du krbtgt invalide tous les TGT en cours. Les sessions existantes continuent mais les nouveaux tickets utilisent le nouveau mot de passe. Faire la rotation en heures creuses. En prod, 2 rotations espacées de 12-24h pour s'assurer que l'ancien mot de passe est complètement remplacé (Kerberos conserve N-1).

---

## Remédiation 2 — Fix AS-REP Roasting

### Pourquoi

Les comptes avec l'attribut `DONT_REQUIRE_PREAUTH` activé permettent à n'importe qui de demander un AS-REP (ticket chiffré avec le mot de passe du compte) sans s'authentifier. L'attaquant peut ensuite craquer le mot de passe offline avec hashcat/john.

### Procédure

```powershell
# Identifier les comptes vulnérables
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} | Select SamAccountName

# Désactiver l'attribut
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} | Set-ADAccountControl -DoesNotRequirePreAuth $false
```

---

## Remédiation 3 — Déploiement gMSA

### Pourquoi

Les comptes de service classiques ont des mots de passe statiques qui ne sont jamais changés et souvent faibles. Un gMSA (Group Managed Service Account) a un mot de passe de 240 caractères généré automatiquement et rotaté tous les 30 jours par AD. Personne ne connaît le mot de passe — même l'admin.

### Procédure

```powershell
# Créer la clé racine KDS (nécessaire pour gMSA)
Add-KdsRootKey -EffectiveImmediately

# Créer le gMSA
New-ADServiceAccount -Name "gMSA-SQLSvc" `
    -DNSHostName "gmsa-sqlsvc.sevenkingdoms.local" `
    -PrincipalsAllowedToRetrieveManagedPassword "Domain Controllers"
```

---

## Correspondance mission client

| Étape lab | Équivalent mission client |
|---|---|
| Rotation krbtgt | Remédiation post-pentest — finding critique |
| Fix AS-REP | Quick win — corrigeable en 5 minutes par compte |
| Déploiement gMSA | Projet de migration des comptes de service (2-4 semaines) |
| Vérification post-remédiation | PV de recette + rescan PingCastle/BloodHound |
