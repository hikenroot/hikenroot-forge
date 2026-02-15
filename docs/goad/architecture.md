# 🏗️ Architecture Détaillée

Ce document présente l'architecture complète de l'infrastructure HikenRoot Forge.

---

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Infrastructure physique](#infrastructure-physique)
- [Infrastructure virtuelle](#infrastructure-virtuelle)
- [Configuration réseau](#configuration-réseau)
- [Active Directory](#active-directory)
- [Sécurité et Isolation](#sécurité-et-isolation)
- [Backup](#backup)

---

## Vue d'ensemble

```
                                    ┌─────────────────────────────────────────────────────────────────┐
                                    │                        INTERNET                                 │
                                    └─────────────────────────────────────┬───────────────────────────┘
                                                                          │
                                                                          │
                                    ┌─────────────────────────────────────▼───────────────────────────┐
                                    │                     BOX INTERNET MAISON                         │
                                    │                      (Gateway Internet)                         │
                                    └─────────────────────────────────────┬───────────────────────────┘
                                                                          │
══════════════════════════════════════════════════════════════════════════╪════════════════════════════
                                       RÉSEAU MAISON - 192.168.50.0/24    │              
══════════════════════════════════════════════════════════════════════════╪════════════════════════════
                                                                          │
            ┌─────────────────┬───────────────────┬───────────────────────┼────────────────────┐
            │                 │                   │                       │                    │
            ▼                 ▼                   ▼                       ▼                    ▼
    ┌───────────────┐ ┌───────────────┐ ┌─────────────────┐     ┌─────────────────┐   ┌───────────────┐
    │   KALI LINUX  │ │   SYNOLOGY    │ │    PROXMOX VE   │     │    pfSense      │   │  Autres PCs   │
    │   (VMware)    │ │   DS923+      │ │   (Beelink)     │     │  (PENTEST IF)   │   │   Maison      │
    │ 192.168.50.x  │ │ 192.168.50.130│ │ 192.168.50.227  │     │ 192.168.50.250  │   │ 192.168.50.x  │
    └───────┬───────┘ └───────┬───────┘ └────────┬────────┘     └────────┬────────┘   └───────────────┘
            │                 │                  │                       │
            │                 │                  │                       │
            │    WireGuard    │                  │     ┌─────────────────┘
            │    10.10.10.2   │                  │     │
            └─────────────────┼──────────────────┼─────┘
                              │                  │
                              │                  │
                              │     ┌────────────┴────────────────────────────────────────┐
                              │     │                   PROXMOX VE                        │
                              │     │                 192.168.50.227                      │
                              │     │                                                     │
                              │     │   ┌─────────────────────────────────────────────┐   │
                              │     │   │                BRIDGES                      │   │
                              │     │   │   vmbr0 ─── LAN (192.168.50.0/24)          │   │
                              │     │   │   vmbr1 ─── WAN interne (10.0.0.0/30)      │   │
                              │     │   │   vmbr2 ─── Management (192.168.1.0/24)    │   │
                              │     │   │   vmbr4 ─── GOAD Lab (192.168.10.0/24)     │   │
                              │     │   └─────────────────────────────────────────────┘   │
                              │     │                                                     │
                              │     │   ┌─────────────────────────────────────────────┐   │
                              │     │   │              VIRTUAL MACHINES               │   │
                              │     │   │                                             │   │
                              │     │   │  VM 101 : pfSense (Firewall/Router)         │   │
                              │     │   │  VM 105 : SRV02 - CASTELBLACK               │   │
                              │     │   │  VM 106 : DC01 - KINGSLANDING               │   │
                              │     │   │  VM 107 : DC02 - WINTERFELL                 │   │
                              │     │   │  VM 108 : SRV03 - BRAAVOS                   │   │
                              │     │   │  VM 109 : DC03 - MEEREEN                    │   │
                              │     │   │  VM 110 : PBS (Backup Server)               │   │
                              │     │   │                                             │   │
                              │     │   │  CT 102 : goad-vm (Provisioning)            │   │
                              │     │   └─────────────────────────────────────────────┘   │
                              │     └─────────────────────────────────────────────────────┘
                              │
                              │ NFS
                              │ /volume1/Backups
                              ▼
                     ┌─────────────────┐
                     │  VM 110 - PBS   │
                     │  /mnt/synology  │
                     └─────────────────┘
```

---

## Infrastructure physique

### Serveur principal

| Composant | Spécification |
|-----------|---------------|
| **Modèle** | Beelink Mini PC |
| **CPU** | Intel N100 / i5 (selon modèle) |
| **RAM** | 64 GB DDR4 |
| **Stockage** | 1 TB NVMe SSD |
| **OS** | Proxmox VE 8.x |
| **IP** | 192.168.50.227 |

### Stockage NAS

| Composant | Spécification |
|-----------|---------------|
| **Modèle** | Synology DS923+ |
| **Stockage** | 8 TB (RAID) |
| **Protocole** | NFS v3/v4 |
| **IP** | 192.168.50.130 |
| **Usage** | Backup PBS |

### Machine d'attaque

| Composant | Spécification |
|-----------|---------------|
| **Type** | VM VMware Workstation |
| **OS** | Kali Linux 2024.x |
| **RAM** | 8 GB |
| **IP** | 192.168.50.x (DHCP) |
| **VPN** | 10.10.10.2 (WireGuard) |

---

## Infrastructure virtuelle

### Machines virtuelles Proxmox

| VM ID | Nom | vCPU | RAM | Disque | Réseau | Rôle |
|-------|-----|------|-----|--------|--------|------|
| 101 | pfSense | 2 | 4 GB | 32 GB | Multi | Firewall/Router/VPN |
| 105 | SRV02 | 2 | 6 GB | 40 GB | vmbr4 | Member Server |
| 106 | DC01 | 2 | 3 GB | 40 GB | vmbr4 | Domain Controller |
| 107 | DC02 | 2 | 4 GB | 40 GB | vmbr4 | Domain Controller |
| 108 | SRV03 | 2 | 4 GB | 40 GB | vmbr4 | Member Server |
| 109 | DC03 | 2 | 3 GB | 40 GB | vmbr4 | Domain Controller |
| 110 | PBS | 2 | 2 GB | 32 GB | vmbr0 | Backup Server |

### Containers LXC

| CT ID | Nom | vCPU | RAM | Réseau | Rôle |
|-------|-----|------|-----|--------|------|
| 102 | goad-vm | 4 | 4 GB | vmbr2 | Provisioning (Ansible/Terraform) |

### Templates

| VM ID | Nom | OS | Usage |
|-------|-----|-----|-------|
| 103 | WinServer2019-Template | Windows Server 2019 | Clone pour VMs GOAD |
| 104 | WinServer2016-Template | Windows Server 2016 | Clone pour VMs GOAD |

---

## Configuration réseau

### Bridges Proxmox

```
┌─────────────────────────────────────────────────────────────┐
│                      PROXMOX BRIDGES                        │
├─────────────┬───────────────────┬───────────────────────────┤
│   Bridge    │      Réseau       │          Usage            │
├─────────────┼───────────────────┼───────────────────────────┤
│   vmbr0     │ 192.168.50.0/24   │ LAN Maison (physique)     │
│   vmbr1     │ 10.0.0.0/30       │ WAN pfSense (interne)     │
│   vmbr2     │ 192.168.1.0/24    │ Management                │
│   vmbr4     │ 192.168.10.0/24   │ GOAD Lab (isolé)          │
└─────────────┴───────────────────┴───────────────────────────┘
```

### Interfaces pfSense

```
┌─────────────────────────────────────────────────────────────┐
│                    pfSense VM 101                           │
├─────────────┬───────────────────┬───────────────────────────┤
│  Interface  │        IP         │          Bridge           │
├─────────────┼───────────────────┼───────────────────────────┤
│   WAN       │ 10.0.0.2/30       │ vmbr1                     │
│   LAN       │ 192.168.1.2/24    │ vmbr2                     │
│   VLAN10    │ 192.168.10.1/24   │ vmbr4                     │
│   PENTEST   │ 192.168.50.250/24 │ vmbr0                     │
│   WG_GOAD   │ 10.10.10.1/24     │ tun_wg0 (WireGuard)       │
└─────────────┴───────────────────┴───────────────────────────┘
```

### Table de routage

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUX RÉSEAU                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Kali (192.168.50.x)                                       │
│       │                                                     │
│       │ WireGuard UDP 51820                                │
│       ▼                                                     │
│  pfSense PENTEST (192.168.50.250)                          │
│       │                                                     │
│       │ Tunnel WireGuard                                   │
│       ▼                                                     │
│  pfSense WG_GOAD (10.10.10.1)                              │
│       │                                                     │
│       │ Routage interne                                    │
│       ▼                                                     │
│  pfSense VLAN10 (192.168.10.1)                             │
│       │                                                     │
│       │ Bridge vmbr4                                       │
│       ▼                                                     │
│  VMs GOAD (192.168.10.10-23)                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Active Directory

### Structure des domaines

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                         SEVENKINGDOMS.LOCAL                             │
│                           (Forest Root)                                 │
│                              DC01                                       │
│                          KINGSLANDING                                   │
│                         192.168.10.10                                   │
│                               │                                         │
│               ┌───────────────┴───────────────┐                        │
│               │                               │                        │
│               ▼                               │                        │
│   NORTH.SEVENKINGDOMS.LOCAL                  │    Bidirectional       │
│        (Child Domain)                         │       Trust            │
│            DC02                               │         │              │
│        WINTERFELL                             │         │              │
│       192.168.10.11                           │         │              │
│             │                                 │         │              │
│             │                                 │         │              │
│        ┌────┴────┐                           │         │              │
│        │         │                           │         │              │
│        ▼         │                           │         │              │
│      SRV02      ...                          │         │              │
│   CASTELBLACK                                │         │              │
│   192.168.10.22                              │         │              │
│   (MSSQL)                                    │         │              │
│                                              │         │              │
└──────────────────────────────────────────────┼─────────┼──────────────┘
                                               │         │
                                               │         │
┌──────────────────────────────────────────────┼─────────┼──────────────┐
│                                              │         │              │
│                      ESSOS.LOCAL ◄───────────┘         │              │
│                   (Separate Forest)                    │              │
│                         DC03 ◄─────────────────────────┘              │
│                       MEEREEN                                         │
│                     192.168.10.12                                     │
│                          │                                            │
│                          │                                            │
│                     ┌────┴────┐                                       │
│                     │         │                                       │
│                     ▼         │                                       │
│                   SRV03      ...                                      │
│                  BRAAVOS                                              │
│                 192.168.10.23                                         │
│                  (MSSQL)                                              │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

### Comptes et groupes

Les comptes utilisateurs sont basés sur l'univers Game of Thrones. Voici quelques exemples :

| Domaine | Utilisateurs | Description |
|---------|--------------|-------------|
| sevenkingdoms.local | robert.baratheon, cersei.lannister, jaime.lannister | Famille royale |
| north.sevenkingdoms.local | eddard.stark, jon.snow, arya.stark | Maison Stark |
| essos.local | daenerys.targaryen, khal.drogo, missandei | Personnages d'Essos |

---

## Sécurité et Isolation

### Principe de défense en profondeur

```
┌─────────────────────────────────────────────────────────────┐
│                    COUCHES DE SÉCURITÉ                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. ISOLATION PHYSIQUE                                      │
│     └── GOAD sur bridge séparé (vmbr4)                     │
│                                                             │
│  2. FIREWALL pfSense                                        │
│     └── NAT + Règles strictes                              │
│     └── Pas de route directe LAN → GOAD                    │
│                                                             │
│  3. VPN WireGuard                                           │
│     └── Accès contrôlé par clés                            │
│     └── Chiffrement du trafic                              │
│                                                             │
│  4. SEGMENTATION                                            │
│     └── VLANs séparés par fonction                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Ce qui est autorisé

| Source | Destination | Autorisé ? |
|--------|-------------|------------|
| LAN (50.x) | GOAD (10.x) | ❌ Non |
| Kali via WG | GOAD (10.x) | ✅ Oui |
| GOAD (10.x) | Internet | ✅ Oui (via NAT) |
| GOAD (10.x) | LAN (50.x) | ❌ Non |

---

## Backup

### Architecture de backup

```
┌─────────────┐      API       ┌─────────────┐      NFS       ┌─────────────┐
│   PROXMOX   │ ────────────► │     PBS     │ ────────────► │  SYNOLOGY   │
│ 192.168.50  │   Port 8007   │ 192.168.50  │  /volume1/    │ 192.168.50  │
│    .227     │               │    .129     │   Backups     │    .130     │
└─────────────┘               └─────────────┘               └─────────────┘
```

### Stratégie de rétention

| Type | Fréquence | Rétention | Protection |
|------|-----------|-----------|------------|
| **GOLDEN** | Manuel | Permanent | 🔒 Protégé |
| **Auto** | Quotidien 3h00 | 7 derniers + 2 hebdo | Auto-purge |

### Restauration

En cas de corruption du lab après pentest :

```bash
# Via CLI Proxmox
qmrestore pbs:vm/106/GOLDEN 106 --force

# Ou via l'interface web :
# Datacenter → Storage → PBS → Content → Select backup → Restore
```

---

## Dimensionnement

### Ressources totales utilisées

| Ressource | Utilisé | Disponible | % |
|-----------|---------|------------|---|
| vCPU | 14 cores | 16 cores | 87% |
| RAM | 26 GB | 64 GB | 40% |
| Stockage | 304 GB | 1 TB | 30% |

### Recommandations

- **Minimum** : 32 GB RAM, 500 GB SSD
- **Recommandé** : 64 GB RAM, 1 TB NVMe
- **Optimal** : 128 GB RAM, 2 TB NVMe

---

<p align="center">
  <em>Architecture conçue pour l'apprentissage du pentest AD en toute sécurité</em>
</p>
