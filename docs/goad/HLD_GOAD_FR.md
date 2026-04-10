# High Level Design — Infrastructure Active Directory Multi-Forêts
## GOAD — Game of Active Directory
### Déployé sur Proxmox VE 8.4 — HikenRoot Forge Lab

---

| Propriété | Valeur |
|-----------|--------|
| Auteur | hik3nR00t |
| Version | 1.0 |
| Date | Février 2026 |
| Environnement | Lab Pentest — HikenRoot Forge |
| Hyperviseur | Proxmox VE 8.4.14 |
| Statut | Opérationnel |

---

## Table des matières

1. [Objectifs](#1-objectifs)
2. [Architecture Logique AD](#2-architecture-logique-ad)
3. [Architecture Physique](#3-architecture-physique--infrastructure)
4. [Architecture Réseau](#4-architecture-réseau)
5. [Infrastructure as Code](#5-infrastructure-as-code-iac)
6. [Sécurité & Vecteurs d'Attaque](#6-sécurité--vecteurs-dattaque)
7. [Sauvegarde & Continuité](#7-sauvegarde--continuité)
8. [Limitations & Évolutions](#8-limitations--évolutions-prévues)
9. [Glossaire](#9-glossaire)

---

## 1. Objectifs

Ce document constitue le **High Level Design (HLD)** de l'infrastructure Active Directory multi-forêts déployée dans le cadre du projet GOAD (Game of Active Directory) sur l'hyperviseur Proxmox VE 8.4.14 du lab HikenRoot Forge.

Ce HLD a pour objectifs :

- Documenter l'architecture logique et physique de l'environnement AD multi-forêts
- Décrire les relations d'approbation (trusts) inter-forêts et inter-domaines
- Présenter les choix techniques d'infrastructure (IaC, réseau, virtualisation)
- Servir de base pour la rédaction du Low Level Design (LLD) détaillé
- Constituer un référentiel de formation pour la pratique des attaques et défenses AD

### Périmètre

L'environnement GOAD simule une infrastructure d'entreprise réaliste composée de **3 domaines Active Directory interconnectés**, **2 serveurs membres**, déployés via Infrastructure as Code sur Proxmox VE.

---

## 2. Architecture Logique AD

### 2.1 Forêts et Domaines

| VM | FQDN Domaine | Rôle | IP | OS | VMID |
|----|-------------|------|----|----|------|
| DC01 | sevenkingdoms.local | DC Racine Forêt 1 | 192.168.10.10 | WS 2019 | 106 |
| DC02 | north.sevenkingdoms.local | DC Enfant Forêt 1 | 192.168.10.11 | WS 2019 | 107 |
| SRV02 | north.sevenkingdoms.local | Serveur Membre | 192.168.10.22 | WS 2019 | 105 |
| DC03 | essos.local | DC Racine Forêt 2 | 192.168.10.12 | WS 2016 | 109 |
| SRV03 | essos.local | Serveur Membre | 192.168.10.23 | WS 2016 | 108 |

### 2.2 Topologie des Forêts

#### Forêt 1 — sevenkingdoms.local

```
sevenkingdoms.local (DC01 — 192.168.10.10)
│
└── north.sevenkingdoms.local (DC02 — 192.168.10.11)
    └── SRV02 (192.168.10.22) — serveur membre
```

- Relation parent-enfant : trust bidirectionnel transitif automatique
- Niveau fonctionnel : Windows Server 2016

#### Forêt 2 — essos.local

```
essos.local (DC03 — 192.168.10.12)
└── SRV03 (192.168.10.23) — serveur membre
```

- Forêt indépendante — limite de sécurité distincte de la Forêt 1
- Niveau fonctionnel : Windows Server 2016

#### Relations d'approbation cross-forest

```
sevenkingdoms.local  ◄──── Trust bidirectionnel ────►  essos.local
```

> **Vecteur d'attaque clé** : exploitation des trusts pour le mouvement latéral inter-forêts

### 2.3 Rôles FSMO

| Rôle FSMO | Détenteur | Domaine |
|-----------|-----------|---------|
| Schema Master | DC01 | sevenkingdoms.local |
| Domain Naming Master | DC01 | sevenkingdoms.local |
| PDC Emulator | DC01 | sevenkingdoms.local |
| RID Master | DC01 | sevenkingdoms.local |
| Infrastructure Master | DC01 | sevenkingdoms.local |
| PDC Emulator | DC02 | north.sevenkingdoms.local |
| PDC Emulator | DC03 | essos.local |

---

## 3. Architecture Physique & Infrastructure

### 3.1 Hyperviseur Proxmox VE

| Propriété | Valeur |
|-----------|--------|
| Hôte | proxmox (192.168.50.227/24) |
| Version | Proxmox VE 8.4.14 |
| RAM totale | 58 GB — 42 GB utilisés en charge normale |
| Stockage | local (dir) 958 GB / 22% utilisé \| PBS backup 7.48 TB |
| Réseau | eno1 (physique) — 6 bridges virtuels (vmbr0 à vmbr5) |

### 3.2 Inventaire VMs GOAD

| VMID | Nom | Rôle | RAM | vCPU | Disque | Réseau |
|------|-----|------|-----|------|--------|--------|
| 100 | GOAD-VM | Jump Host IaC / Attaquant | 10 GB | 4 | 100 GB | vmbr4 + vmbr0 |
| 101 | VM 101 | pfSense Firewall/GW | 4 GB | 1 | 32 GB | vmbr1/2/3/4/5 |
| 105 | SRV02 | Membre north.sevenkingdoms | 6.2 GB | 2 | 40 GB | vmbr4 tag10 |
| 106 | DC01 | DC sevenkingdoms.local | 3 GB | 2 | 40 GB | vmbr4 tag10 |
| 107 | DC02 | DC north.sevenkingdoms.local | 4 GB | 2 | 40 GB | vmbr4 tag10 |
| 108 | SRV03 | Membre essos.local | 4 GB | 2 | 40 GB | vmbr4 tag10 |
| 109 | DC03 | DC essos.local | 3 GB | 2 | 40 GB | vmbr4 tag10 |
| 110 | PBS | Proxmox Backup Server | 2 GB | 2 | 32 GB | vmbr0 |
| 120 | docker-weblab | Web Lab (Docker) | 8 GB | 4 | 80 GB | vmbr4 tag20 |

---

## 4. Architecture Réseau

### 4.1 Segmentation — Bridges Proxmox

| Bridge | Subnet | Rôle | VLAN Tag |
|--------|--------|------|----------|
| vmbr0 | 192.168.50.x/24 | Management Proxmox (LAN physique) | — |
| vmbr1 | 10.0.0.0/30 | WAN Proxmox → pfSense | — |
| vmbr2 | — | WAN pfSense externe | — |
| vmbr3 | 192.168.1.x/24 | LAN interne pfSense | — |
| vmbr4 | 192.168.10.x/24 | Réseau GOAD (AD Lab) | Tag 10 |
| vmbr5 | — | Web Lab | Tag 20 |

### 4.2 Plan d'adressage IP — Réseau GOAD (192.168.10.0/24)

| Hôte | IP | Rôle | Notes |
|------|-----|------|-------|
| Proxmox (vmbr4) | 192.168.10.1 | Gateway / DNS forwarder | DNS du lab |
| DC01 | 192.168.10.10 | DC sevenkingdoms.local | Schema Master, PDC, DNS |
| DC02 | 192.168.10.11 | DC north.sevenkingdoms.local | PDC Emulator north, DNS |
| DC03 | 192.168.10.12 | DC essos.local | PDC Emulator essos, DNS |
| SRV02 | 192.168.10.22 | Membre north.sevenkingdoms | Serveur applicatif |
| SRV03 | 192.168.10.23 | Membre essos.local | Serveur applicatif |
| GOAD-VM | 192.168.10.x | Jump Host / Attaquant | Kali Linux — outils offensifs |

### 4.3 Schéma réseau

```
Internet
    │
  vmbr2 (WAN externe)
    │
[VM101 — pfSense]
    │
  vmbr1 (10.0.0.0/30) ──── Proxmox Host (192.168.50.227)
    │                              │
  vmbr3 (192.168.1.0/24)        vmbr0 (Management)
    │
  vmbr4 (192.168.10.0/24) — GOAD AD Lab
    ├── DC01  192.168.10.10  (sevenkingdoms.local)
    ├── DC02  192.168.10.11  (north.sevenkingdoms.local)
    ├── DC03  192.168.10.12  (essos.local)
    ├── SRV02 192.168.10.22
    ├── SRV03 192.168.10.23
    └── GOAD-VM (Attaquant / Jump Host)
    
  vmbr5 (Web Lab)
    └── docker-weblab (VLAN 20)
```

---

## 5. Infrastructure as Code (IaC)

### 5.1 Chaîne de déploiement

| Étape | Outil | Rôle | Description |
|-------|-------|------|-------------|
| 1 | **Packer** | Build templates VM | Création des images Windows Server 2016/2019 avec sysprep, WinRM activé |
| 2 | **Terraform** | Provisioning VMs | Déploiement des VMs sur Proxmox — VMID, RAM, vCPU, réseau, disque |
| 3 | **Ansible** | Configuration AD | Installation AD DS, création domaines/forêts, trusts, GPO, utilisateurs, vulnérabilités intentionnelles |

### 5.2 Templates Windows

| Template | VMID | OS | Utilisation |
|----------|------|----|-------------|
| WinServer2019x64-cloudinit | 103 | Windows Server 2019 | Base DC01, DC02, SRV02 |
| WinServer2016x64-cloudinit | 104 | Windows Server 2016 | Base DC03, SRV03 |

### 5.3 Structure du workspace

```
/home/hiken/GOAD/
├── workspace/
│   └── d0536f-goad-proxmox/
│       └── inventory          # Mapping hôtes/IPs/domaines
├── extensions/
│   ├── wazuh/                 # Extension Blue Team (planifié)
│   ├── exchange/              # Extension Exchange (planifié)
│   ├── lx01/                  # Extension Linux (planifié)
│   └── ws01/                  # Extension Workstation (planifié)
└── venv/                      # Environnement Python Ansible
```

---

## 6. Sécurité & Vecteurs d'Attaque

### 6.1 Objectif

GOAD est un environnement **volontairement vulnérable** conçu pour la pratique des techniques d'attaque et de défense Active Directory. Les vulnérabilités sont intentionnellement configurées via Ansible pour simuler des erreurs de configuration réelles rencontrées en entreprise.

### 6.2 Vecteurs d'attaque couverts

| Vecteur | Technique | Cible |
|---------|-----------|-------|
| Kerberos Attacks | Kerberoasting, AS-REP Roasting | Comptes de service SPNs |
| Credential Theft | Pass-the-Hash, Pass-the-Ticket | Hôtes du domaine |
| Privilege Escalation | ACL/ACE Abuse, GPO Abuse | Objets AD mal configurés |
| Domain Dominance | DCSync, Golden/Silver Ticket | DC01, DC02, DC03 |
| Lateral Movement | Trust Abuse cross-forest | sevenkingdoms ↔ essos |
| Recon | BloodHound, ldapdomaindump | Ensemble du lab |

### 6.3 Isolation réseau

- L'environnement GOAD est isolé sur vmbr4 (192.168.10.0/24) sans accès direct à Internet
- pfSense (VM101) assure le filtrage et le routage entre les segments
- Le réseau de management Proxmox (vmbr0) est séparé du lab

---

## 7. Sauvegarde & Continuité

| Composant | Détail |
|-----------|--------|
| VM PBS | VMID 110 — 2GB RAM — 32GB disk |
| Stockage PBS | 7.48 TB disponibles — 1.75% utilisé |

- Snapshots Proxmox des VMs GOAD avant chaque session d'attaque
- Restauration rapide après compromission complète du lab
- PBS assure la rétention des backups avec déduplication

---

## 8. Limitations & Évolutions Prévues

### Limitations actuelles

- Pas de monitoring/SIEM actif sur le segment GOAD (Wazuh prévu Phase 2)
- Templates WinServer en mode stopped — provisionnement à la demande
- Extension Exchange non déployée
- LLD détaillé à produire

### Évolutions planifiées

| Phase | Scope | Statut |
|-------|-------|--------|
| Phase 1 | Infrastructure GOAD AD Lab | ✅ Opérationnel (~80%) |
| Phase 2 | Wazuh / Security Onion — Blue Team | 🔄 Planifié |
| Phase 2 | Extensions GOAD (lx01, ws01, Exchange) | 🔄 Planifié |
| Phase 3 | Cloud Lab Kubernetes K3s (VLAN 30) | 🔄 Planifié |
| Phase 3 | AI/LLM Stack — RTX PRO 4000 Blackwell 24GB (VLAN 40) | 🔄 Planifié |
| Phase 4 | LLD complet + GitBook documentation | 🔄 Planifié |

---

## 9. Glossaire

| Terme | Définition |
|-------|-----------|
| AD DS | Active Directory Domain Services — service d'annuaire Microsoft |
| DC | Domain Controller — contrôleur de domaine |
| FSMO | Flexible Single Master Operations — rôles AD à instance unique |
| GOAD | Game of Active Directory — lab pentest open source (Orange Cyberdefense) |
| HLD | High Level Design — document d'architecture macro |
| IaC | Infrastructure as Code — automatisation du déploiement infrastructure |
| LLD | Low Level Design — document d'architecture détaillé |
| Trust | Relation d'approbation entre domaines/forêts AD |
| WinRM | Windows Remote Management — protocole de gestion distante Windows |

---

*Document produit par hik3nR00t — HikenRoot Forge Lab*
