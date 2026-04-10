# Runbook — Incidents AD N3

## Périmètre

Ce runbook couvre les procédures de réponse aux incidents Active Directory de niveau 3 (architecte/expert) pour l'environnement GOAD v3 hybridé avec Entra ID.

---

## Incident 1 — Suspicion de Golden Ticket

### Symptômes
- Accès anormaux aux ressources avec des comptes qui ne devraient pas y avoir accès
- Tickets Kerberos avec des durées de vie anormalement longues
- Activité suspecte sur le compte krbtgt dans les logs

### Procédure immédiate

```powershell
# 1. Vérifier la date du dernier changement krbtgt
Get-ADUser krbtgt -Properties PasswordLastSet | Select PasswordLastSet

# 2. Rotation immédiate du krbtgt (invalide tous les Golden Tickets)
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString "NewP@ss$(Get-Random)" -AsPlainText -Force)

# 3. Attendre la réplication (vérifier sur tous les DC)
repadmin /replsummary

# 4. Deuxième rotation 12-24h plus tard
# (Kerberos conserve N-1, la 2e rotation élimine complètement l'ancien hash)
```

### Post-incident
- Analyser les logs EventID 4769 (TGS request) avec des durées anormales
- Vérifier les accès DCSync (EventID 4662 avec GUID de réplication)
- Rescan BloodHound pour identifier le vecteur initial

---

## Incident 2 — Compromission d'un compte Global Admin Entra ID

### Symptômes
- Connexions depuis des pays inhabituels dans les Sign-in Logs
- Création de comptes non autorisés
- Modification des Conditional Access policies

### Procédure immédiate

```powershell
# 1. Se connecter avec un Break Glass
# BG01: breakglass01@nhik3nR00tpm.onmicrosoft.com

# 2. Révoquer toutes les sessions du compte compromis
Revoke-MgUserSignInSession -UserId "ID_DU_COMPTE_COMPROMIS"

# 3. Reset du mot de passe
Update-MgUser -UserId "ID" -PasswordProfile @{
    Password = "TempP@ss$(Get-Random)!"
    ForceChangePasswordNextSignIn = $true
}

# 4. Vérifier les CA policies (pas de modification non autorisée)
Get-MgIdentityConditionalAccessPolicy | Format-Table DisplayName, State

# 5. Vérifier les rôles PIM (pas d'attribution non autorisée)
# Portail > PIM > Affectations actives
```

### Post-incident
- Analyser les Sign-in Logs et Audit Logs (portail Entra ID)
- Vérifier les modifications des 24 dernières heures
- Rescan des CA policies et Named Locations

---

## Incident 3 — AD Connect sync compromise

### Symptômes
- Service ADSync arrêté sans raison
- Erreurs de sync massives
- Modifications suspectes sur le compte MSOL_xxx

### Procédure immédiate

```powershell
# 1. Vérifier le service
Get-Service ADSync

# 2. Vérifier le compte MSOL (pas de modification non autorisée)
Get-ADUser -Filter {SamAccountName -like "MSOL_*"} -Properties PasswordLastSet, Enabled

# 3. Si compromission confirmée — isoler la VM ADCONNECT
# Couper NIC2 (Internet) pour bloquer la sync vers Entra ID
# Garder NIC1 (AD) pour l'investigation

# 4. Vérifier les exports récents dans Sync Manager
& "C:\Program Files\Microsoft Azure AD Sync\UIShell\miisclient.exe"
```

### Post-incident
- Recréer le compte MSOL si compromis
- Réinstaller AD Connect si nécessaire
- Vérifier les objets synchronisés dans Entra ID

---

## Incident 4 — Lockout massif des admins (MFA / CA policy)

### Symptômes
- Aucun admin ne peut se connecter au portail Entra
- MFA en panne ou Authenticator indisponible

### Procédure immédiate

```
1. Se connecter avec Break Glass 01 ou 02
   - breakglass01@nhik3nR00tpm.onmicrosoft.com
   - Ces comptes sont EXCLUS de toutes les CA policies
   - Pas de MFA requis

2. Diagnostiquer la cause du lockout
   - CA policy passée en "Activé" par erreur ?
   - Panne Azure MFA ?

3. Si CA policy en cause — passer en Report-only
   Portail Entra > Accès conditionnel > Stratégies > Policy fautive > Report-only

4. Si panne MFA — désactiver temporairement la policy CA002
```

### Post-incident
- Documenter la cause du lockout
- Tester les Break Glass accounts (test trimestriel)
- Vérifier que les BG ne sont pas impactés par de nouvelles policies

---

## Contacts et escalade

| Niveau | Contact | Délai |
|---|---|---|
| N1 | Support interne | Immédiat |
| N2 | Admin AD / Entra ID | < 30 min |
| N3 | Architecte Identity | < 1h |
| Microsoft | Support Premier (ticket) | < 4h (Sev A) |
