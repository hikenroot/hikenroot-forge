# Backup Strategy

## Table of Contents

- [Architecture](#architecture)
- [PBS Configuration](#pbs-configuration)
- [Automated Backups](#automated-backups)
- [Golden State Backups](#golden-state-backups)
- [Restore Procedures](#restore-procedures)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## Architecture

```
┌─────────────┐     API 8007     ┌─────────────┐      NFS       ┌─────────────┐
│   PROXMOX   │ ───────────────► │     PBS     │ ──────────────► │  SYNOLOGY   │
│  .50.227    │                  │   VM 110    │                 │   DS923+    │
│             │    vzdump        │             │  /volume1/      │             │
│  VMs GOAD   │    snapshot      │  Datastore: │  Backups        │  7.66 TB    │
│  VM 105-109 │                  │  "Synology" │                 │             │
└─────────────┘                  └─────────────┘                 └─────────────┘
```

### Components

| Component | Role | IP |
|-----------|------|----|
| Proxmox VE | Hypervisor, initiates backups | 192.168.50.227 |
| PBS | Proxmox Backup Server, deduplication | 192.168.50.129 |
| Synology | NFS storage, long-term retention | 192.168.50.130 |

## PBS Configuration

### VM 110 Settings

| Parameter | Value |
|-----------|-------|
| OS | Proxmox Backup Server 3.x |
| IP | 192.168.50.129 |
| Web interface | https://192.168.50.129:8007 |
| Datastore | Synology |

### NFS Mount

File `/etc/fstab` on PBS:

```
192.168.50.130:/volume1/Backups /mnt/synology nfs defaults 0 0
```

### Proxmox Storage Configuration

File `/etc/pve/storage.cfg`:

```
pbs: PBS
    datastore Synology
    server 192.168.50.129
    content backup
    fingerprint 6a:a4:a4:23:c9:80:72:77:7e:b5:85:ba:6e:ca:a9:74:32:89:93:b3:dd:b5:15:a4:27:da:57:1d:5f:94:cb:b6
    prune-backups keep-all=1
    username root@pam
```

## Automated Backups

### Job Configuration

File `/etc/pve/jobs.cfg`:

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

### Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Schedule | Daily at 03:00 | Runs every night |
| Mode | Snapshot | Hot backup, no VM downtime |
| Compression | zstd | Fast and efficient |
| Targets | All VMs | VM 100-110 |

### Retention Policy

```
keep-last=7      # Keep the 7 most recent backups
keep-weekly=2    # Keep 2 weekly backups
```

Rotation example:

```
Week 1:
├── Mon 03:00 ✓ (keep-last)
├── Tue 03:00 ✓ (keep-last)
├── Wed 03:00 ✓ (keep-last)
├── Thu 03:00 ✓ (keep-last)
├── Fri 03:00 ✓ (keep-last)
├── Sat 03:00 ✓ (keep-last)
└── Sun 03:00 ✓ (keep-last + keep-weekly)

Week 2:
├── Mon 03:00 → Deletes Mon W1
├── ...
└── Sun 03:00 ✓ (keep-weekly)

Week 3:
└── Sun 03:00 → Deletes Sun W1
```

## Golden State Backups

### Purpose

Create a clean snapshot of the GOAD lab after successful installation, enabling rapid restore after penetration testing exercises.

### Creation

```bash
vzdump 105 106 107 108 109 \
    --storage PBS \
    --mode snapshot \
    --compress zstd \
    --notes-template "GOAD-GOLDEN-STATE-CLEAN"
```

### Write Protection

Golden backups must be protected against automatic pruning:

1. Access PBS: https://192.168.50.129:8007
2. Navigate to Datastore → Synology → Content
3. Expand vm/105, vm/106, etc.
4. Right-click on "GOAD-GOLDEN-STATE-CLEAN" backup
5. Edit protection → Enable

### Current Golden Backups

| VM | Name | Date | Size | Status |
|----|------|------|------|--------|
| 105 | SRV02 | 2025-12-03 16:58 | 40 GB | Protected |
| 106 | DC01 | 2025-12-03 17:00 | 40 GB | Protected |
| 107 | DC02 | 2025-12-03 17:01 | 40 GB | Protected |
| 108 | SRV03 | 2025-12-03 17:02 | 40 GB | Protected |
| 109 | DC03 | 2025-12-03 17:03 | 40 GB | Protected |

## Restore Procedures

### Via Proxmox Web Interface

1. Navigate to Datacenter → Storage → PBS → Content
2. Select the backup to restore
3. Click Restore
4. Set Target VM ID and enable Overwrite if the VM already exists
5. Click Restore

### Via CLI

```bash
# List available backups
pvesm list PBS | grep GOLDEN

# Restore DC01 from Golden backup
qmrestore "pbs:backup/vm/106/2025-12-03T16:00:15Z" 106 --force

# Restore all GOAD VMs
for vmid in 105 106 107 108 109; do
    qmrestore "pbs:backup/vm/$vmid/GOLDEN" $vmid --force
done
```

### Estimated Restore Times

| VM | Size | Duration |
|----|------|----------|
| DC01 | 40 GB | ~5 min |
| DC02 | 40 GB | ~5 min |
| DC03 | 40 GB | ~5 min |
| SRV02 | 40 GB | ~5 min |
| SRV03 | 40 GB | ~5 min |
| **Total** | **200 GB** | **~25 min** |

## Maintenance

### Daily Verification

```bash
# Check PBS storage status
pvesm status | grep PBS

# Check recent backup tasks
cat /var/log/pve/tasks/index | tail -20
```

### NFS Mount Verification (on PBS)

```bash
ssh root@192.168.50.129
df -h | grep synology

# If unmounted, remount
mount -a
```

### Integrity Verification

1. Access https://192.168.50.129:8007
2. Navigate to Datastore → Synology → Content
3. Select a backup
4. Click Verify to check integrity

### Garbage Collection

PBS automatically runs garbage collection to remove unreferenced chunks. To force manually:

```bash
# On PBS
proxmox-backup-manager garbage-collection start Synology
```

### Best Practices

**Do:**
- Verify automated backups are running regularly
- Test a full restore at least once per month
- Keep Golden backups write-protected
- Monitor disk space on the NAS

**Avoid:**
- Deleting Golden backups without creating new ones first
- Modifying PBS configuration without backing up the config
- Ignoring NAS IP changes (will break NFS mount)

## Troubleshooting

### PBS Storage Unavailable

```bash
# Check connectivity
ping 192.168.50.129

# Check PBS VM status
qm status 110

# Restart PBS if necessary
qm restart 110
```

### NFS Mount Failure

```bash
# On PBS
ping 192.168.50.130
cat /etc/fstab | grep synology

# Remount
umount /mnt/synology
mount -a
df -h | grep synology
```

### Automated Backups Not Running

```bash
# Check job configuration
cat /etc/pve/jobs.cfg

# Check logs
journalctl -u pvedaemon | grep vzdump

# Manual test run
vzdump 106 --storage PBS --mode snapshot
```
