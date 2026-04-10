# Runbook — Opérations AD Connect

## Informations générales

| Paramètre | Valeur |
|---|---|
| Serveur | ADCONNECT (192.168.10.55) |
| Service | ADSync |
| Domaine | sevenkingdoms.local |
| Tenant | nhik3nR00tpm.onmicrosoft.com |
| Méthode auth | PHS (Password Hash Sync) |
| SSO | Seamless SSO (2 forêts) |
| Writeback | Password Writeback activé |

---

## Connexion RDP

```bash
xfreerdp /v:192.168.10.55 /u:Administrator /d:sevenkingdoms.local /p:'<MOT_DE_PASSE>' /cert-ignore /dynamic-resolution /kbd:0x0000040C
```

---

## Opérations courantes

### Vérifier l'état du service

```powershell
Get-Service ADSync | Select Status, StartType
```

### Importer le module ADSync

```powershell
cd "C:\Program Files\Microsoft Azure AD Sync\Bin"
Import-Module .\ADSync\ADSync.psd1
```

**Important :** toujours se placer dans le répertoire Bin avant d'importer le module, sinon erreur `MmsServerRCW`.

### Vérifier le scheduler

```powershell
Get-ADSyncScheduler
```

Champs importants :
- `AllowedSyncCycleInterval` : intervalle minimum (30 min par défaut)
- `CurrentlyEffectiveSyncCycleInterval` : intervalle actuel
- `SyncCycleEnabled` : doit être True
- `NextSyncCycleStartTimeInUTC` : prochaine sync

### Lancer une sync manuelle

```powershell
# Delta sync (synchronise uniquement les changements)
Start-ADSyncSyncCycle -PolicyType Delta

# Full sync (resynchronise tout — à utiliser avec précaution)
Start-ADSyncSyncCycle -PolicyType Initial
```

### Vérifier le statut des connecteurs

```powershell
Get-ADSyncConnectorRunStatus
```

### Ouvrir Sync Manager GUI

```powershell
& "C:\Program Files\Microsoft Azure AD Sync\UIShell\miisclient.exe"
```

---

## Dépannage

### Erreur MmsServerRCW à l'import du module

**Cause :** PowerShell lancé depuis un répertoire autre que Bin.

**Solution :**
```powershell
cd "C:\Program Files\Microsoft Azure AD Sync\Bin"
Import-Module .\ADSync\ADSync.psd1
```

### Service ADSync ne démarre pas

**Cause possible :** SQL Express lent au premier démarrage.

**Solution :**
```powershell
Restart-Service ADSync
# Attendre 2-3 minutes
Get-Service ADSync
```

### Sync bloquée ou erreurs d'export

```powershell
# Vérifier les erreurs
Get-ADSyncConnectorRunStatus

# Voir les détails dans le Sync Manager GUI
& "C:\Program Files\Microsoft Azure AD Sync\UIShell\miisclient.exe"
# Onglet "Operations" → regarder les exports en erreur
```

### Connexion Graph depuis WSL (contournement bug WAM)

```powershell
pwsh
Set-MgGraphOption -DisableLoginByWAM $true
Connect-MgGraph -Scopes "User.Read.All" -TenantId "eea0e92c-08ea-4aa8-a0b2-d5e8854c81cd" -UseDeviceCode
```

---

## Seuils et alertes

| Métrique | Seuil normal | Alerte si |
|---|---|---|
| Delta sync interval | 30 min | > 2h sans sync |
| Export errors | 0 | > 10 erreurs consécutives |
| Service ADSync | Running | Stopped > 5 min |
| Seuil suppression | 500 | Suppression massive détectée |
