# GOAD Troubleshooting — Récupération licence et relation d'approbation

**Auteur :** hik3nR00t
**Date :** 21 août 2026
**Lab :** GOAD v3 — HikenRoot Forge
**Sévérité :** Critique — Arrêt périodique de toutes les VMs

---

## Problème

Après plusieurs mois d'exploitation, les 5 VMs GOAD s'éteignent de manière intempestive toutes les heures. Les connexions RDP échouent avec `STATUS_TRUSTED_RELATIONSHIP_FAILURE` sur les serveurs membres et `STATUS_LOGON_FAILURE` sur les contrôleurs de domaine.

## Analyse des causes racines

Deux problèmes distincts identifiés :

### Problème 1 — Licence d'évaluation Windows Server expirée

Toutes les VMs GOAD utilisent des éditions Windows Server Evaluation (licence d'essai 180 jours). Après expiration, Windows force un arrêt toutes les heures.

**Détection :**
```powershell
cscript //nologo C:\Windows\System32\slmgr.vbs /dli
```
```
Name: Windows(R), ServerDatacenterEval edition
Description: Windows(R) Operating System, TIMEBASED_EVAL channel
License Status: Notification
Notification Reason: 0xC004FC07
```

### Problème 2 — Relation d'approbation domaine cassée

Les serveurs membres ont perdu leur relation d'approbation avec les contrôleurs de domaine. Cela se produit lorsque le mot de passe du compte machine expire ou se désynchronise (fréquent après un rollback de snapshot).

**Détection :**
```
STATUS_TRUSTED_RELATIONSHIP_FAILURE [0xC000018D]
```
Même les comptes locaux échouent en RDP quand NLA est activé — NLA nécessite de contacter le DC pour l'authentification.

---

## Résolution

### Étape 1 — Réarmement de la licence (5 VMs)

La licence Windows Evaluation peut être réarmée jusqu'à 6 fois, remettant le compteur à 180 jours.

**VMs avec credentials fonctionnels (DCs) :**
```bash
evil-winrm -i <IP_DC> -u administrator -H <HASH_NT>
```
```powershell
cscript //nologo C:\Windows\System32\slmgr.vbs /rearm
Restart-Computer -Force
```

**VMs avec trust cassé (serveurs membres) :**

Quand les credentials domaine échouent, utiliser impacket-psexec avec un compte local :
```bash
impacket-psexec './<utilisateur_local>:<mot_de_passe>@<IP_CIBLE>'
```
```cmd
cscript //nologo C:\Windows\System32\slmgr.vbs /rearm
net user administrator <NOUVEAU_MOT_DE_PASSE>
shutdown /r /t 5
```

**VMs accessibles uniquement via console Proxmox :**

Accès via la console web Proxmox VE (noVNC) → connexion avec un compte local → PowerShell en administrateur :
```powershell
cscript //nologo C:\Windows\System32\slmgr.vbs /rearm
Restart-Computer -Force
```

### Étape 2 — Réinitialisation des mots de passe

Les mots de passe admin avaient changé ou étaient inconnus.

**Réinitialisation standard (domaines enfants) :**
```powershell
net user administrator <NOUVEAU_MOT_DE_PASSE> /domain
```

**Quand la politique de mot de passe bloque (racine de forêt — 14 chars min + historique 24) :**

`net user` échoue avec :
```
The password does not meet the password policy requirements.
```

Contournement — `Set-ADAccountPassword` ignore l'âge minimum en mode reset :
```powershell
Set-ADAccountPassword -Identity administrator -Reset -NewPassword (ConvertTo-SecureString '<MOT_DE_PASSE_COMPLEXE>' -AsPlainText -Force)
```

### Étape 3 — Réparation de la relation d'approbation (serveurs membres)

Après le réarmement et le reset du mot de passe, le serveur membre avait toujours un trust cassé. Le compte machine n'était pas trouvé sur le DC :
```
Reset-ComputerMachinePassword: Cannot find the computer account for the local computer from the domain controller
```

Correction — utiliser `Test-ComputerSecureChannel` avec `-Repair` depuis une session admin locale (console Proxmox) :
```powershell
Test-ComputerSecureChannel -Server <IP_DC> -Repair -Credential (New-Object System.Management.Automation.PSCredential("<DOMAINE>\administrator",(ConvertTo-SecureString "<MOT_DE_PASSE>" -AsPlainText -Force)))
```
Résultat : `True` — relation d'approbation restaurée.

---

## Méthodes d'accès utilisées (chemin d'escalade)

Quand RDP et WinRM standard ont échoué, plusieurs méthodes ont été tentées :

| Méthode | Cible | Résultat |
|---------|-------|----------|
| `xfreerdp` avec PTH | DC01 | ❌ NLA bloque le PTH |
| `xfreerdp` avec mot de passe | DC02 | ❌ Mot de passe changé |
| `xfreerdp /sec:rdp /nego:off` | SRV02 | ❌ Erreur TLS |
| `evil-winrm` avec hash | DC02 | ❌ Authentification WinRM échouée |
| `evil-winrm` avec hash | DC03 | ❌ Hash expiré |
| `netexec smb` utilisateur domaine | DC03 | ✅ Authentification low-priv |
| `impacket-psexec` auth domaine | SRV03 | ✅ Domain admin |
| `impacket-psexec` auth locale | SRV02 | ✅ Compte local |
| **Console Proxmox (noVNC)** | Toutes les VMs | ✅ **Dernier recours, fonctionne toujours** |

**Point clé :** la console Proxmox (noVNC) est le recours ultime — pas de réseau, pas de NLA, pas de trust nécessaire.

---

## Vérification

Les 5 VMs validées avec netexec — 5/5 `Pwn3d!` confirmé.

---

## État final

| VM | Rôle | Licence | Trust |
|----|------|---------|-------|
| DC01 (Racine de forêt) | Contrôleur de domaine | ✅ 180 jours | ✅ |
| DC02 (Domaine enfant) | Contrôleur de domaine | ✅ 180 jours | ✅ |
| DC03 (Forêt externe) | Contrôleur de domaine | ✅ 180 jours | ✅ |
| SRV02 (Serveur membre) | MSSQL + IIS | ✅ 180 jours | ✅ Réparé |
| SRV03 (Serveur membre) | MSSQL + CA | ✅ 180 jours | ✅ |

---

## Leçons apprises

1. **Planifier le réarmement** — mettre un rappel calendrier à 150 jours pour réarmer avant expiration
2. **Snapshot avant durcissement** — toujours créer un snapshot Proxmox avant d'exécuter des scripts de sécurité qui modifient les mots de passe
3. **Documenter les changements de mots de passe** — maintenir un coffre-fort de credentials pour les environnements lab
4. **La console Proxmox est reine** — quand toute authentification réseau échoue, noVNC est le dernier recours
5. **L'ordre de réparation du trust compte** — corriger le DC d'abord, puis les serveurs membres. Utiliser `Test-ComputerSecureChannel -Repair` avant de tenter une re-jonction au domaine
6. **Connaissance des politiques de mot de passe** — `Set-ADAccountPassword -Reset` contourne l'âge minimum, contrairement à `net user /domain`

---

## Pertinence MITRE ATT&CK

Ce scénario de troubleshooting reflète des opérations défensives réelles :

| Technique | ID | Pertinence |
|-----------|-----|------------|
| Comptes valides : Domaine | T1078.002 | Récupération d'accès admin domaine après perte de credentials |
| Pass-the-Hash | T1550.002 | Utilisation de hash NT quand les mots de passe en clair sont inconnus |
| Services distants : SMB | T1021.002 | impacket-psexec pour exécution de commandes à distance |
| Manipulation de comptes | T1098 | Réinitialisation de mots de passe sur plusieurs domaines |

---

*hik3nR00t — HikenRoot Forge — GOAD Troubleshooting*
