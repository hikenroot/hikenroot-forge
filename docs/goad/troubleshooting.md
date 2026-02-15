# Troubleshooting Guide

## Table of Contents

- [Packer / Templates](#packer--templates)
- [Terraform](#terraform)
- [Ansible / GOAD](#ansible--goad)
- [Proxmox](#proxmox)
- [pfSense / Networking](#pfsense--networking)
- [WireGuard VPN](#wireguard-vpn)
- [PBS / Backup](#pbs--backup)
- [General Guidelines](#general-guidelines)

---

## Packer / Templates

### "No images found matching ImageIndex"

**Symptom:**
```
Error: No images found matching ImageIndex: 1
```

**Cause:** Windows Server Evaluation ISO contains multiple editions. Index 1 corresponds to the Core edition (no GUI).

**Solution:** Modify `autounattend.xml`:

```xml
<InstallFrom>
    <MetaData wcm:action="add">
        <Key>/IMAGE/INDEX</Key>
        <Value>2</Value>  <!-- 2 = Standard with Desktop Experience -->
    </MetaData>
</InstallFrom>
```

### WinRM Connection Timeout During Build

**Symptom:** Packer cannot connect to the VM during template creation.

**Cause:** WinRM not enabled or firewall blocking the connection.

**Solution:** Add to `autounattend.xml`:

```powershell
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM" dir=in action=allow protocol=TCP localport=5985
```

### "ISO file not found"

**Symptom:**
```
Error: ISO file not found: local:iso/windows_server_2019.iso
```

**Solution:**
- Verify the ISO is uploaded in Proxmox: Datacenter → Storage → ISO Images
- Check the exact filename (case-sensitive)
- Use the correct storage reference in Packer:

```hcl
iso_file = "local:iso/SERVER_EVAL_x64FRE_en-us.iso"
```

---

## Terraform

### "Provider telmate/proxmox incompatible"

**Symptom:**
```
Error: Incompatible provider version
```

**Cause:** The telmate/proxmox provider is deprecated.

**Solution:** Migrate to bpg/proxmox:

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

### "VM template not found"

**Symptom:**
```
Error: 500 Configuration file 'nodes/xxx/qemu-server/xxx.conf' does not exist
```

**Cause:** The template referenced in Terraform does not exist.

**Solution:**
- Verify templates were created: `qm list | grep -i template`
- Check VM IDs in Terraform configuration
- Ensure the VM is marked as "Template" in Proxmox

### "Could not create VM, already exists"

**Solution:**

```bash
# Remove existing VMs
terraform destroy

# Or force import
terraform import proxmox_vm_qemu.dc01 proxmox/qemu/106
```

---

## Ansible / GOAD

### "unreachable: winrm connection refused"

**Symptom:**
```
fatal: [dc01]: UNREACHABLE! => {"msg": "winrm connection refused"}
```

**Possible causes:** VM not started, WinRM not enabled, incorrect credentials.

**Solution:**

```bash
# 1. Verify VM is reachable
ping 192.168.10.10

# 2. Test WinRM manually
python3 -c "import winrm; s = winrm.Session('192.168.10.10', auth=('Administrator', 'Password'))"

# 3. Verify Ansible inventory
cat inventory | grep -A5 dc01
```

### "Failed to install ADCS"

**Cause:** Missing dependencies or incorrect execution order.

**Solution:** Re-run the ADCS playbook in isolation:

```bash
ansible-playbook -i inventory adcs.yml -l dc01
```

### "The trust relationship failed"

**Cause:** Trust relationship between domains is broken.

**Solution:**

```powershell
# On the affected Domain Controller
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)
```

### "Ansible variables undefined"

**Symptom:**
```
fatal: [dc01]: FAILED! => {"msg": "'dict object' has no attribute 'xxx'"}
```

**Solution:** Verify inventory is properly loaded:

```bash
ansible-inventory -i inventory --list | jq .
```

---

## Proxmox

### "can't lock file"

**Symptom:**
```
TASK ERROR: can't lock file '/var/lock/qemu-server/lock-XXX.conf'
```

**Solution:**

```bash
# Remove the lock manually
rm /var/lock/qemu-server/lock-XXX.conf

# Or force stop
qm stop XXX --skiplock
```

### "No valid subscription" Popup

**Solution** (lab environment only):

```bash
sed -i.bak "s/data.status !== 'Active'/false/g" \
    /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy
```

### Bridge vmbr4 Not Working

**Symptom:** VMs on vmbr4 have no network connectivity.

**Solution:** Verify `/etc/network/interfaces`:

```
auto vmbr4
iface vmbr4 inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
```

Then reload:

```bash
ifreload -a
```

---

## pfSense / Networking

### VMs Getting Random IP Addresses

**Cause:** DHCP assigns dynamic IPs without static mappings.

**Solution:** Create static DHCP reservations:

1. Navigate to Services → DHCP Server → VLAN10
2. Add Static Mapping for each VM with MAC address and fixed IP

Retrieve MAC addresses:

```bash
for vmid in 105 106 107 108 109; do
    echo "=== VM $vmid ==="
    qm config $vmid | grep net0
done
```

### No Internet Access from GOAD VMs

**Cause:** Missing NAT or firewall rules.

**Solution:**
1. Check NAT Outbound: Firewall → NAT → Outbound
2. Add rule: Interface VLAN10 → Any → WAN Address

### DNS Resolution Failure

**Solution:** Configure DNS Forwarder:

1. Services → DNS Forwarder → Enable
2. Add forwarders: 8.8.8.8, 1.1.1.1

---

## WireGuard VPN

### Handshake Not Establishing

**Checks:**

```bash
# Verify public keys match
sudo cat /etc/wireguard/publickey
# Compare with pfSense: VPN → WireGuard → Peers

# Verify endpoint is reachable
ping 192.168.50.250
nc -zvu 192.168.50.250 51820
```

### "Transfer: 0 B received"

**Possible causes:** Incorrect keys, firewall blocking traffic on WG_GOAD interface.

**Solution:**
- Check rules: Firewall → Rules → WG_GOAD
- Ensure a Pass Any Any rule exists on the WG_GOAD interface

### No Route to GOAD Network (192.168.10.x)

**Symptom:** Ping 10.10.10.1 works but 192.168.10.x does not.

**Solution:** Verify AllowedIPs in client configuration:

```ini
[Peer]
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
```

Must include both the WireGuard tunnel subnet and the GOAD lab subnet.

---

## PBS / Backup

### PBS Storage Unavailable in Proxmox

**Symptom:**
```
Error: storage 'PBS' is not available
```

**Possible causes:** PBS VM stopped, IP changed, NFS mount failed.

**Solution:**

```bash
# Check PBS is running
qm status 110

# Check connectivity
ping 192.168.50.129

# Check storage status
pvesm status
```

### NFS Mount Failure on PBS

**Symptom:** `/mnt/synology` is empty or inaccessible.

**Solution:**

```bash
# On PBS (VM 110)
cat /etc/fstab | grep synology

# Correct IP if necessary
# 192.168.50.130:/volume1/Backups /mnt/synology nfs defaults 0 0

# Remount
sudo umount /mnt/synology
sudo mount -a
df -h | grep synology
```

### NAS IP Changed

Update both locations:

On PBS (`/etc/fstab`):
```
192.168.50.130:/volume1/Backups /mnt/synology nfs defaults 0 0
```

On Proxmox (`/etc/pve/storage.cfg`):
```
pbs: PBS
    datastore Synology
    server 192.168.50.129    # PBS IP, not NAS IP
    ...
```

---

## General Guidelines

**Log locations:**
- Proxmox: `/var/log/pve/tasks/`
- pfSense: Status → System Logs
- Windows: Event Viewer

**Before modifying any configuration:**

```bash
cp /etc/pve/storage.cfg /etc/pve/storage.cfg.bak
```

**Troubleshooting methodology:**
1. Verify network connectivity first
2. Check service status
3. Review application logs
4. Document every change for rollback capability
