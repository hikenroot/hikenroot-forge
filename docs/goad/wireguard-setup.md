# 🔐 Configuration WireGuard VPN

Ce guide explique comment configurer WireGuard sur pfSense pour accéder au lab GOAD de manière sécurisée depuis une machine d'attaque.

---

## 📋 Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Configuration pfSense](#configuration-pfsense)
- [Configuration Client (Kali)](#configuration-client-kali)
- [Test et Validation](#test-et-validation)
- [Troubleshooting](#troubleshooting)

---

## Architecture

```
┌─────────────┐     WireGuard      ┌─────────────┐           ┌─────────────┐
│    KALI     │ ◄────────────────► │   pfSense   │ ◄───────► │    GOAD     │
│ 192.168.50.x│     UDP 51820      │ 10.10.10.1  │           │ 192.168.10.x│
│ 10.10.10.2  │                    │ 192.168.50. │           │ DC01, DC02  │
│             │                    │     250     │           │ DC03, SRV02 │
│             │                    │             │           │ SRV03       │
└─────────────┘                    └─────────────┘           └─────────────┘
```

**Avantages de cette architecture :**

- ✅ Accès sécurisé au lab depuis le LAN
- ✅ Isolation complète du réseau GOAD
- ✅ Pas besoin d'exposer les VMs Windows
- ✅ Chiffrement du trafic

---

## Prérequis

### Sur pfSense

- pfSense 2.5+ installé
- Interface sur le réseau LAN (192.168.50.x)
- Accès admin à l'interface web

### Sur la machine d'attaque

- WireGuard installé
- Accès au réseau 192.168.50.x

---

## Configuration pfSense

### Étape 1 : Installer le package WireGuard

1. **System → Package Manager → Available Packages**
2. Chercher "WireGuard"
3. Cliquer sur **Install**
4. Attendre la fin de l'installation

### Étape 2 : Ajouter une interface pour l'accès VPN

> ⚠️ Cette étape est nécessaire si pfSense n'a pas d'interface sur votre réseau LAN.

Sur Proxmox :
```bash
# Ajouter une carte réseau à pfSense sur vmbr0
qm set 101 --net4 virtio,bridge=vmbr0
```

Sur pfSense :
1. **Interfaces → Assignments**
2. **Add** la nouvelle interface
3. Cliquer sur la nouvelle interface (OPTx)
4. Configurer :
   - **Enable** : ☑️
   - **Description** : PENTEST
   - **IPv4 Configuration** : Static IPv4
   - **IPv4 Address** : 192.168.50.250 / 24
5. **Save → Apply Changes**

### Étape 3 : Créer le tunnel WireGuard

1. **VPN → WireGuard → Tunnels**
2. **Add Tunnel**
3. Configurer :

| Paramètre | Valeur |
|-----------|--------|
| Enable | ☑️ |
| Description | GOAD-VPN |
| Listen Port | 51820 |
| Interface Keys | Cliquer sur **Generate** |

4. **Save Tunnel**
5. **Copier la Public Key** (vous en aurez besoin pour le client)

### Étape 4 : Assigner l'interface WireGuard

1. **Interfaces → Assignments**
2. **Add** → Sélectionner `tun_wg0`
3. Cliquer sur la nouvelle interface
4. Configurer :

| Paramètre | Valeur |
|-----------|--------|
| Enable | ☑️ |
| Description | WG_GOAD |
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | 10.10.10.1 / 24 |

5. **Save → Apply Changes**

### Étape 5 : Ajouter le Peer (client)

1. **VPN → WireGuard → Peers**
2. **Add Peer**
3. Configurer :

| Paramètre | Valeur |
|-----------|--------|
| Tunnel | GOAD-VPN |
| Description | Kali-Attacker |
| Dynamic Endpoint | ☑️ |
| Public Key | [Clé publique du client - voir ci-dessous] |
| Allowed IPs | 10.10.10.2/32 |

4. **Save Peer**

### Étape 6 : Règles Firewall

#### Sur l'interface PENTEST (192.168.50.250)

1. **Firewall → Rules → PENTEST**
2. **Add** :

| Paramètre | Valeur |
|-----------|--------|
| Action | Pass |
| Protocol | UDP |
| Destination Port | 51820 |
| Description | Allow WireGuard |

#### Sur l'interface WG_GOAD

1. **Firewall → Rules → WG_GOAD**
2. **Add** :

| Paramètre | Valeur |
|-----------|--------|
| Action | Pass |
| Protocol | Any |
| Source | Any |
| Destination | Any |
| Description | Allow all WireGuard traffic |

3. **Save → Apply Changes**

---

## Configuration Client (Kali)

### Étape 1 : Installer WireGuard

```bash
sudo apt update
sudo apt install wireguard -y
```

### Étape 2 : Générer les clés

```bash
cd /etc/wireguard
sudo wg genkey | sudo tee privatekey | wg pubkey | sudo tee publickey

# Afficher la clé publique (à copier dans pfSense)
sudo cat publickey
```

### Étape 3 : Créer la configuration

```bash
sudo nano /etc/wireguard/wg-goad.conf
```

Contenu :

```ini
[Interface]
# Clé privée générée à l'étape 2
PrivateKey = VOTRE_CLÉ_PRIVÉE_ICI
# IP assignée dans le tunnel
Address = 10.10.10.2/24
# DNS optionnel
DNS = 192.168.10.1

[Peer]
# Clé publique de pfSense (copiée à l'étape 3 de la config pfSense)
PublicKey = CLÉ_PUBLIQUE_PFSENSE_ICI
# Endpoint : IP de l'interface PENTEST + port WireGuard
Endpoint = 192.168.50.250:51820
# Réseaux accessibles via le tunnel
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
# Keepalive pour maintenir le tunnel actif
PersistentKeepalive = 25
```

### Étape 4 : Mettre à jour le Peer sur pfSense

1. Retourner sur pfSense : **VPN → WireGuard → Peers**
2. Éditer le peer "Kali-Attacker"
3. Coller la **Public Key** de Kali
4. **Save Peer → Apply Changes**

---

## Test et Validation

### Démarrer le tunnel

```bash
# Démarrer
sudo wg-quick up wg-goad

# Vérifier le status
sudo wg show
```

Output attendu :
```
interface: wg-goad
  public key: xxxxx
  private key: (hidden)
  listening port: xxxxx

peer: xxxxx
  endpoint: 192.168.50.250:51820
  allowed ips: 10.10.10.0/24, 192.168.10.0/24
  latest handshake: X seconds ago    ← Important !
  transfer: X KiB received, X KiB sent
```

### Tester la connectivité

```bash
# Ping pfSense via WireGuard
ping -c 3 10.10.10.1

# Ping les VMs GOAD
ping -c 3 192.168.10.10   # DC01
ping -c 3 192.168.10.11   # DC02
ping -c 3 192.168.10.12   # DC03
ping -c 3 192.168.10.22   # SRV02
ping -c 3 192.168.10.23   # SRV03
```

### Test pentest

```bash
# Scanner SMB
crackmapexec smb 192.168.10.10-23

# Nmap
nmap -sC -sV 192.168.10.10
```

### Arrêter le tunnel

```bash
sudo wg-quick down wg-goad
```

### Démarrage automatique (optionnel)

```bash
sudo systemctl enable wg-quick@wg-goad
```

---

## Troubleshooting

### Handshake ne s'établit pas

**Vérifications :**

1. Les clés publiques correspondent-elles ?
```bash
# Sur Kali
sudo cat /etc/wireguard/publickey

# Sur pfSense : VPN → WireGuard → Peers → Vérifier Public Key
```

2. L'endpoint est-il joignable ?
```bash
ping 192.168.50.250
nc -zvu 192.168.50.250 51820
```

3. Le firewall autorise-t-il UDP 51820 ?

### Transfer: 0 B received

**Causes possibles :**
- Clés incorrectes
- Firewall sur WG_GOAD bloque le trafic

**Solution :**
- Vérifier les règles : **Firewall → Rules → WG_GOAD**
- S'assurer qu'une règle "Pass Any Any" existe

### Pas de route vers 192.168.10.x

**Vérifier AllowedIPs :**
```bash
sudo wg show
```

`allowed ips` doit inclure `192.168.10.0/24`.

Si non, modifier `/etc/wireguard/wg-goad.conf` :
```ini
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
```

---

## Configuration finale

### pfSense - Tunnel

```
Description  : GOAD-VPN
Listen Port  : 51820
Interface IP : 10.10.10.1/24
```

### pfSense - Peer

```
Description  : Kali-Attacker
Public Key   : [clé publique Kali]
Allowed IPs  : 10.10.10.2/32
```

### Kali - /etc/wireguard/wg-goad.conf

```ini
[Interface]
PrivateKey = [clé privée Kali]
Address = 10.10.10.2/24

[Peer]
PublicKey = [clé publique pfSense]
Endpoint = 192.168.50.250:51820
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
PersistentKeepalive = 25
```

---

<p align="center">
  <em>Happy Hacking! 🐉</em>
</p>
