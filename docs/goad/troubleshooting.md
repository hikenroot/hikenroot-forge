# 🐛 Troubleshooting Guide

Ce document recense les problèmes rencontrés durant le déploiement de HikenRoot Forge et leurs solutions.

---

## 📋 Table des matières

- [Packer / Templates](#packer--templates)
- [Terraform](#terraform)
- [Ansible / GOAD](#ansible--goad)
- [Proxmox](#proxmox)
- [pfSense / Réseau](#pfsense--réseau)
- [WireGuard VPN](#wireguard-vpn)
- [PBS / Backup](#pbs--backup)

---

## Packer / Templates

### ❌ Erreur : "No images found matching ImageIndex"

**Symptôme :**
```
Error: No images found matching ImageIndex: 1
```

**Cause :** L'ISO Windows Server Evaluation contient plusieurs éditions. L'index 1 correspond à la version Core (sans GUI).

**Solution :** Modifier le fichier `autounattend.xml` :
```xml
<InstallFrom>
    <MetaData wcm:action="add">
        <Key>/IMAGE/INDEX</Key>
        <Value>2</Value>  <!-- 2 = Standard avec Desktop Experience -->
    </MetaData>
</InstallFrom>
```

### ❌ Erreur : "winrm connection timeout"

**Symptôme :** Packer ne peut pas se connecter à la VM pendant le build.

**Cause :** WinRM n'est pas activé ou le firewall bloque la connexion.

**Solution :** Ajouter dans `autounattend.xml` :
```powershell
# Activer WinRM
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM" dir=in action=allow protocol=TCP localport=5985
```

### ❌ Erreur : "ISO not found"

**Symptôme :**
```
Error: ISO file not found: local:iso/windows_server_2019.iso
```

**Solution :**
1. Vérifier que l'ISO est uploadée dans Proxmox : `Datacenter → Storage → ISO Images`
2. Vérifier le nom exact (sensible à la casse)
3. Utiliser le bon storage dans Packer :
```hcl
iso_file = "local:iso/SERVER_EVAL_x64FRE_en-us.iso"
```

---

## Terraform

### ❌ Erreur : "Provider telmate/proxmox incompatible"

**Symptôme :**
```
Error: Incompatible provider version
```

**Cause :** Le provider `telmate/proxmox` est obsolète.

**Solution :** Utiliser le provider `bpg/proxmox` :
```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.38.0"
    }
  }
}
```

### ❌ Erreur : "VM template not found"

**Symptôme :**
```
Error: 500 Configuration file 'nodes/xxx/qemu-server/xxx.conf' does not exist
```

**Cause :** Le template référencé dans Terraform n'existe pas.

**Solution :**
1. Vérifier que les templates Packer sont créés : `qm list | grep -i template`
2. Vérifier les IDs dans la config Terraform
3. S'assurer que le template est bien marqué comme "Template" dans Proxmox

### ❌ Erreur : "Could not create VM, already exists"

**Solution :**
```bash
# Supprimer les VMs existantes
terraform destroy

# Ou forcer l'import
terraform import proxmox_vm_qemu.dc01 proxmox/qemu/106
```

---

## Ansible / GOAD

### ❌ Erreur : "unreachable: winrm connection refused"

**Symptôme :**
```
fatal: [dc01]: UNREACHABLE! => {"msg": "winrm connection refused"}
```

**Causes possibles :**
1. VM pas encore démarrée
2. WinRM pas activé
3. Mauvais credentials

**Solutions :**

```bash
# 1. Vérifier que la VM répond
ping 192.168.10.10

# 2. Tester WinRM manuellement
python3 -c "import winrm; s = winrm.Session('192.168.10.10', auth=('Administrator', 'Password'))"

# 3. Vérifier l'inventaire Ansible
cat inventory | grep -A5 dc01
```

### ❌ Erreur : "Failed to install ADCS"

**Cause :** Dépendances manquantes ou ordre d'exécution incorrect.

**Solution :** Relancer le playbook ADCS seul :
```bash
ansible-playbook -i inventory adcs.yml -l dc01
```

### ❌ Erreur : "The trust relationship failed"

**Cause :** Problème de relation d'approbation entre domaines.

**Solution :**
```powershell
# Sur le DC concerné
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)
```

### ❌ Erreur : "Ansible variables undefined"

**Symptôme :**
```
fatal: [dc01]: FAILED! => {"msg": "'dict object' has no attribute 'xxx'"}
```

**Solution :** Vérifier que l'inventaire est bien chargé :
```bash
ansible-inventory -i inventory --list | jq .
```

---

## Proxmox

### ❌ Erreur : "TASK ERROR: can't lock file '/var/lock/qemu-server/lock-XXX.conf'"

**Solution :**
```bash
# Supprimer le lock manuellement
rm /var/lock/qemu-server/lock-XXX.conf

# Ou forcer l'arrêt
qm stop XXX --skiplock
```

### ❌ Erreur : "No valid subscription"

**Solution :** Désactiver le popup (non recommandé en production) :
```bash
sed -i.bak "s/data.status !== 'Active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy
```

### ❌ Bridge vmbr4 ne fonctionne pas

**Symptôme :** Les VMs sur vmbr4 n'ont pas de réseau.

**Solution :** Vérifier `/etc/network/interfaces` :
```
auto vmbr4
iface vmbr4 inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
```

Puis :
```bash
ifreload -a
```

---

## pfSense / Réseau

### ❌ VMs obtiennent des IPs aléatoires

**Cause :** DHCP attribue des IPs dynamiques sans réservation.

**Solution :** Créer des réservations DHCP statiques :
1. `Services → DHCP Server → VLAN10`
2. `Add Static Mapping` pour chaque VM
3. Renseigner MAC Address + IP fixe

**Récupérer les MAC addresses :**
```bash
# Sur Proxmox
for vmid in 105 106 107 108 109; do
  echo "=== VM $vmid ==="
  qm config $vmid | grep net0
done
```

### ❌ Pas d'accès Internet depuis les VMs GOAD

**Cause :** NAT ou règles firewall manquantes.

**Solution :**
1. Vérifier NAT Outbound : `Firewall → NAT → Outbound`
2. Ajouter une règle : Interface VLAN10 → Any → WAN Address

### ❌ DNS ne résout pas

**Solution :** Configurer le DNS Forwarder :
1. `Services → DNS Forwarder → Enable`
2. Ajouter les forwarders : `8.8.8.8, 1.1.1.1`

---

## WireGuard VPN

### ❌ Tunnel UP mais pas de trafic (RX = 0)

**Symptôme :**
```
transfer: 0 B received, 1.30 KiB sent
```

**Causes possibles :**
1. Clés publiques ne correspondent pas
2. Firewall bloque le trafic

**Solution :**

```bash
# 1. Vérifier la clé publique côté client
sudo wg show

# 2. Comparer avec pfSense : VPN → WireGuard → Peers
# Les clés doivent être IDENTIQUES

# 3. Mettre à jour si nécessaire
```

### ❌ "Handshake did not complete"

**Causes :**
1. Endpoint incorrect
2. Port UDP 51820 bloqué
3. Clés incorrectes

**Solution :**
```bash
# Vérifier l'endpoint
ping 192.168.50.250

# Tester le port
nc -zvu 192.168.50.250 51820
```

### ❌ Pas de route vers GOAD

**Symptôme :** Ping 10.10.10.1 OK mais pas 192.168.10.x

**Solution :** Vérifier AllowedIPs dans la config client :
```ini
[Peer]
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24  # Doit inclure le réseau GOAD
```

---

## PBS / Backup

### ❌ Storage PBS indisponible dans Proxmox

**Symptôme :**
```
Error: storage 'PBS' is not available
```

**Causes :**
1. PBS VM arrêtée
2. IP changée
3. Montage NFS échoué

**Solution :**

```bash
# 1. Vérifier que PBS est UP
qm status 110

# 2. Vérifier la connectivité
ping 192.168.50.129

# 3. Vérifier le storage
pvesm status
```

### ❌ Montage NFS échoué sur PBS

**Symptôme :** `/mnt/synology` vide ou inaccessible.

**Solution :**
```bash
# Sur PBS (VM 110)
# 1. Vérifier /etc/fstab
cat /etc/fstab | grep synology

# 2. Corriger l'IP si nécessaire
sudo nano /etc/fstab
# 192.168.50.130:/volume1/Backups /mnt/synology nfs defaults 0 0

# 3. Remonter
sudo umount /mnt/synology
sudo mount -a

# 4. Vérifier
df -h | grep synology
```

### ❌ IP du NAS changée

**Solution :**

Sur PBS (`/etc/fstab`) :
```
192.168.50.130:/volume1/Backups /mnt/synology nfs defaults 0 0
```

Sur Proxmox (`/etc/pve/storage.cfg`) :
```
pbs: PBS
    datastore Synology
    server 192.168.50.129    # IP de PBS, pas du NAS !
    ...
```

---

## 💡 Conseils généraux

1. **Toujours vérifier les logs** :
   - Proxmox : `/var/log/pve/tasks/`
   - pfSense : `Status → System Logs`
   - Windows : Event Viewer

2. **Sauvegarder avant de modifier** :
   ```bash
   cp /etc/pve/storage.cfg /etc/pve/storage.cfg.bak
   ```

3. **Tester étape par étape** :
   - D'abord la connectivité réseau
   - Puis les services
   - Enfin l'application

4. **Documenter chaque changement** pour pouvoir revenir en arrière.

---

<p align="center">
  <em>Ce guide est basé sur mon expérience personnelle. N'hésitez pas à contribuer !</em>
</p>
