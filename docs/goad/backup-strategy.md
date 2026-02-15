# 📦 Stratégie de Backup

Ce document décrit la stratégie de backup mise en place pour protéger l'infrastructure HikenRoot Forge.

---

## 📋 Table des matières

- [Architecture](#architecture)
- [Configuration PBS](#configuration-pbs)
- [Backups automatiques](#backups-automatiques)
- [Backups GOLDEN](#backups-golden)
- [Restauration](#restauration)
- [Maintenance](#maintenance)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE BACKUP                              │
│                                                                         │
│   ┌─────────────┐      API 8007     ┌─────────────┐       NFS          │
│   │   PROXMOX   │ ────────────────► │     PBS     │ ────────────────►  │
│   │             │                   │   VM 110    │                    │
│   │ VMs GOAD    │                   │             │                    │
│   │ VM 105-109  │                   │ Datastore:  │    ┌────────────┐  │
│   │             │                   │ "Synology"  │    │  SYNOLOGY  │  │
│   └─────────────┘                   │             │    │  DS923+    │  │
│        │                            │ /mnt/       │    │            │  │
│        │ vzdump                     │  synology   │───►│ /volume1/  │  │
│        │                            │             │    │  Backups   │  │
│        └────────────────────────────┤             │    │            │  │
│                                     └─────────────┘    │  7.66 TB   │  │
│                                                        └────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Composants

| Composant | Rôle | IP |
|-----------|------|-----|
| **Proxmox VE** | Hyperviseur, lance les backups | 192.168.50.227 |
| **PBS** | Proxmox Backup Server, déduplication | 192.168.50.129 |
| **Synology** | Stockage NFS, rétention long terme | 192.168.50.130 |

---

## Configuration PBS

### VM PBS (110)

| Paramètre | Valeur |
|-----------|--------|
| OS | Proxmox Backup Server 3.x |
| IP | 192.168.50.129 |
| Interface web | https://192.168.50.129:8007 |
| Datastore | Synology |

### Montage NFS

Fichier `/etc/fstab` sur PBS :

```
192.168.50.130:/volume1/Backups /mnt/synology nfs defaults 0 0
```

### Configuration storage sur Proxmox

Fichier `/etc/pve/storage.cfg` :

```
pbs: PBS
    datastore Synology
    server 192.168.50.129
    content backup
    fingerprint 6a:a4:a4:23:c9:80:72:77:7e:b5:85:ba:6e:ca:a9:74:32:89:93:b3:dd:b5:15:a4:27:da:57:1d:5f:94:cb:b6
    prune-backups keep-all=1
    username root@pam
```

---

## Backups automatiques

### Configuration du job

Fichier `/etc/pve/jobs.cfg` :

```
vzdump: backup-goad
    all 1
    enabled 1
    mode snapshot
    notes-template Backup Auto GOAD
    prune-backups keep-last=7,keep-weekly=2
    schedule *-*-* 03:00:00
    storage PBS
```

### Paramètres

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **Schedule** | 03:00 quotidien | Tous les jours à 3h du matin |
| **Mode** | Snapshot | Backup à chaud sans arrêt des VMs |
| **Compression** | zstd | Compression rapide et efficace |
| **Cibles** | Toutes les VMs | VMs 100-110 |

### Rétention automatique

```
keep-last=7      # Garde les 7 derniers backups
keep-weekly=2    # Garde 2 backups hebdomadaires
```

**Exemple de rotation :**

```
Semaine 1:
├── Lun 03:00 ✓ (keep-last)
├── Mar 03:00 ✓ (keep-last)
├── Mer 03:00 ✓ (keep-last)
├── Jeu 03:00 ✓ (keep-last)
├── Ven 03:00 ✓ (keep-last)
├── Sam 03:00 ✓ (keep-last)
└── Dim 03:00 ✓ (keep-last + keep-weekly)

Semaine 2:
├── Lun 03:00 → Supprime Lun S1
├── ...
└── Dim 03:00 ✓ (keep-weekly)

Semaine 3:
└── Dim 03:00 → Supprime Dim S1
```

---

## Backups GOLDEN

### Objectif

Créer un **snapshot propre** du lab GOAD après installation réussie, pour pouvoir restaurer rapidement après avoir "cassé" le lab pendant les tests de pentest.

### Création

```bash
# Sur Proxmox
vzdump 105 106 107 108 109 \
    --storage PBS \
    --mode snapshot \
    --compress zstd \
    --notes-template "GOAD-GOLDEN-STATE-CLEAN"
```

### Protection

Les backups GOLDEN doivent être **protégés** contre la suppression automatique :

1. Accéder à PBS : https://192.168.50.129:8007
2. Datastore → Synology → Content
3. Déplier vm/105, vm/106, etc.
4. Clic droit sur le backup "GOAD-GOLDEN-STATE-CLEAN"
5. **Modifier la protection** → Activer 🔒

### Backups GOLDEN actuels

| VM | Nom | Date | Taille | Status |
|----|-----|------|--------|--------|
| 105 | SRV02 | 2025-12-03 16:58 | 40 GB | 🔒 Protégé |
| 106 | DC01 | 2025-12-03 17:00 | 40 GB | 🔒 Protégé |
| 107 | DC02 | 2025-12-03 17:01 | 40 GB | 🔒 Protégé |
| 108 | SRV03 | 2025-12-03 17:02 | 40 GB | 🔒 Protégé |
| 109 | DC03 | 2025-12-03 17:03 | 40 GB | 🔒 Protégé |

---

## Restauration

### Via l'interface Proxmox

1. **Datacenter → Storage → PBS → Content**
2. Sélectionner le backup à restaurer
3. Cliquer sur **Restore**
4. Options :
   - **Target VM ID** : ID de la VM cible (ex: 106)
   - **Overwrite** : ☑️ si la VM existe déjà
5. Cliquer sur **Restore**

### Via CLI

```bash
# Lister les backups disponibles
pvesm list PBS | grep GOLDEN

# Restaurer DC01 depuis le backup GOLDEN
qmrestore "pbs:backup/vm/106/2025-12-03T16:00:15Z" 106 --force

# Restaurer toutes les VMs GOAD
for vmid in 105 106 107 108 109; do
    qmrestore "pbs:backup/vm/$vmid/GOLDEN" $vmid --force
done
```

### Temps de restauration estimé

| VM | Taille | Durée estimée |
|----|--------|---------------|
| DC01 | 40 GB | ~5 min |
| DC02 | 40 GB | ~5 min |
| DC03 | 40 GB | ~5 min |
| SRV02 | 40 GB | ~5 min |
| SRV03 | 40 GB | ~5 min |
| **Total** | 200 GB | **~25 min** |

---

## Maintenance

### Vérification quotidienne

```bash
# Sur Proxmox - Vérifier le status du storage
pvesm status | grep PBS

# Vérifier les tâches récentes
cat /var/log/pve/tasks/index | tail -20
```

### Vérification du montage NFS (sur PBS)

```bash
# Se connecter à PBS
ssh root@192.168.50.129

# Vérifier le montage
df -h | grep synology

# Si démonté, remonter
mount -a
```

### Vérification de l'intégrité (PBS)

1. Accéder à https://192.168.50.129:8007
2. Datastore → Synology → Content
3. Sélectionner un backup
4. **Verify** pour vérifier l'intégrité

### Garbage Collection

PBS effectue automatiquement le garbage collection pour supprimer les chunks non référencés.

Pour forcer manuellement :

```bash
# Sur PBS
proxmox-backup-manager garbage-collection start Synology
```

---

## Bonnes pratiques

### ✅ À faire

- Vérifier régulièrement que les backups automatiques fonctionnent
- Tester une restauration complète au moins une fois par mois
- Garder les backups GOLDEN protégés
- Monitorer l'espace disque sur le NAS

### ❌ À éviter

- Ne pas supprimer les backups GOLDEN sans en créer de nouveaux
- Ne pas modifier la configuration PBS sans backup de la config
- Ne pas oublier de mettre à jour les IPs si elles changent

---

## Troubleshooting

### Le storage PBS est indisponible

```bash
# Vérifier la connectivité
ping 192.168.50.129

# Vérifier que PBS est UP
qm status 110

# Redémarrer PBS si nécessaire
qm restart 110
```

### Le montage NFS échoue

```bash
# Sur PBS
# Vérifier l'IP du NAS
ping 192.168.50.130

# Vérifier /etc/fstab
cat /etc/fstab | grep synology

# Remonter
umount /mnt/synology
mount -a

# Vérifier
df -h | grep synology
```

### Les backups automatiques ne se lancent pas

```bash
# Vérifier le job
cat /etc/pve/jobs.cfg

# Vérifier les logs
journalctl -u pvedaemon | grep vzdump

# Lancer manuellement pour tester
vzdump 106 --storage PBS --mode snapshot
```

---

<p align="center">
  <em>Un bon backup est un backup testé ! 💾</em>
</p>
