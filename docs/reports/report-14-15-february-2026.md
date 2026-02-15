# HikenRoot Forge — Session Report: February 14-15, 2026

## Summary

Two major wins and a critical architecture decision. The SFP+ 10Gbps network was restored by replacing a third-party GIQITCK transceiver with a 10Gtek DAC cable. GPU passthrough testing confirmed a QEMU/KVM bug with the RTX PRO 4000 Blackwell architecture. The decision was made to deploy the GPU in Docker host mode with NVIDIA Container Toolkit, with a documented migration path to passthrough when the bug is resolved.

---

## Part 1 — SFP+ 10Gbps Network Resolution (February 14)

### Problem Context

Kernel 6.14 was required for NVIDIA 570.133.07 drivers with the RTX PRO 4000 Blackwell GPU. Kernel 6.17 supported SFP+ networking but failed to compile NVIDIA drivers. The MS-02 was running on a temporary 2.5Gbps RJ45 emergency connection via nic1.

### Network Port Identification

Identified physical ports using sysfs driver symlinks:

```bash
readlink /sys/class/net/nic1/device/driver  # igc (Intel I226 2.5G RJ45)
readlink /sys/class/net/nic2/device/driver  # ice (Intel E810 SFP+)
readlink /sys/class/net/nic3/device/driver  # ice (Intel E810 SFP+)
```

### Driver Analysis

```bash
ethtool -i nic2
# driver: ice, version: 6.14.11-5-pve, firmware: 4.70
```

The kernel ice driver reported: `The selected speed is not supported by the current media.`

### Troubleshooting Attempts (All Failed)

**Force speed configuration:**
```bash
ethtool -s nic2 speed 10000 duplex full autoneg off
# ERROR: Operation not supported
```

**Cross-kernel module loading:**
```bash
insmod /lib/modules/6.17.9-1-pve/kernel/drivers/net/ethernet/intel/ice/ice.ko
# ERROR: Invalid module format (kernel version mismatch)
```

**Intel GitHub driver compilation:**
```bash
wget https://github.com/intel/ethernet-linux-ice/archive/refs/heads/main.tar.gz -O ice-intel.tar.gz
tar xzf ice-intel.tar.gz && cd ethernet-linux-ice-main/src
make install
```
Result: Intel driver was even stricter — reported `Module is not present` for the transceiver.

**Unsupported SFP flag:**
```bash
modprobe ice allow_unsupported_sfp=1
# No effect — this parameter exists on ixgbe driver, not ice
```

### Root Cause

The connection was not using a DAC cable as initially assumed, but a **GIQITCK GQ-SFP-10G-T** third-party SFP+ to RJ45 transceiver with a Cat8 cable. This transceiver is not Intel-certified. The kernel 6.17 ice driver was permissive and accepted it; the kernel 6.14 ice driver enforces a vendor whitelist.

### Solution

Replaced the GIQITCK transceiver with a **10Gtek CAB-10GSFP-P1M** passive DAC SFP+ cable (direct copper with integrated SFP+ connectors, no conversion electronics).

```bash
ip link set nic2 up
dmesg | tail -5
# ice 0000:03:00.0 nic2: NIC Link is up 10 Gbps Full Duplex
```

### Final Network Configuration

Updated `/etc/network/interfaces` with nic2 as bridge-port:

```
auto vmbr0
iface vmbr0 inet static
        address 192.168.50.228/24
        gateway 192.168.50.1
        bridge-ports nic2
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        post-up bridge vlan add dev nic2 vid 30
        post-up bridge vlan add dev nic2 vid 40
```

### Lesson Learned

Third-party SFP+ to RJ45 transceivers may work on some kernel versions but are not guaranteed across ice driver versions. Passive DAC SFP+ cables are universally compatible with Intel E810 controllers regardless of kernel version.

---

## Part 2 — GPU Passthrough Test (February 15)

### Objective

Test whether the RTX PRO 4000 Blackwell can be passed through via VFIO to a QEMU/KVM virtual machine on Proxmox, enabling an isolated AI Lab VM on VLAN40.

### Prerequisites Verification

**IOMMU active:**
```bash
dmesg | grep -i iommu | head -5
# iommu: Default domain type: Translated
```

**GPU isolated in IOMMU group 13:**
```bash
ls /sys/kernel/iommu_groups/13/devices/
# 0000:02:00.0  0000:02:00.1
```
Only GPU VGA (02:00.0) and Audio (02:00.1) — no other devices. Clean isolation.

**Resizable BAR active:**
```bash
lspci -vvs 02:00.0 | grep -i "resize"
# Capabilities: [134 v1] Physical Resizable BAR
# BAR 1: current size: 32GB
```

### Configuration Backup

```bash
mkdir /root/backup-modprobe-15feb
cp /etc/modprobe.d/*.conf /root/backup-modprobe-15feb/
```

### VFIO-PCI Configuration

```bash
echo "options vfio-pci ids=10de:2c33,10de:22e9 disable_vga=1 disable_idle_d3=1" > /etc/modprobe.d/vfio.conf

cat > /etc/modprobe.d/blacklist-nvidia.conf << 'EOF'
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
EOF

update-initramfs -u -k all
reboot
```

**Post-reboot verification:**
```bash
lspci -nnk -s 02:00
# 02:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2c33]
#         Kernel driver in use: vfio-pci
# 02:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22e9]
#         Kernel driver in use: vfio-pci
```

GPU successfully captured by vfio-pci.

### VM Configuration

```
bios: ovmf
machine: q35
cpu: host
cores: 2
sockets: 2
memory: 8192
efidisk0: vmdata:vm-900-disk-1,efitype=4m,pre-enrolled-keys=0,size=4M
hostpci0: 0000:02:00,pcie=1,rombar=1,x-vga=0
scsi0: vmdata:vm-900-disk-0,iothread=1,size=32G
net0: virtio=BC:24:11:CA:32:87,bridge=vmbr0,firewall=1
```

Configuration follows community recommendations: OVMF (UEFI), Q35 machine type, host CPU, PCIe mode with rombar enabled.

### Test Result — FAILED

```bash
qm start 900
```

```
error writing '1' to '/sys/bus/pci/devices/0000:02:00.0/reset': Inappropriate ioctl for device
failed to reset PCI device '0000:02:00.0', but trying to continue as not all devices need a reset
kvm: ../hw/pci/pci.c:1815: pci_irq_handler: Assertion '0 <= irq_num && irq_num < PCI_NUM_PINS' failed.
TASK ERROR: start failed: QEMU exited with code 1
```

The test was repeated multiple times with the same result.

### Error Analysis

**PCI reset failure:** The RTX PRO 4000 Blackwell does not support the standard PCI reset mechanism used by QEMU/KVM for passthrough device initialization. This is a known issue with recent Blackwell GPUs.

**IRQ handler crash:** After the failed reset, QEMU attempts to continue but the PCI interrupts are not properly configured, causing a fatal assertion in QEMU's PCI IRQ handler code.

### Rollback Procedure

```bash
sed -i '/hostpci0/d' /etc/pve/qemu-server/900.conf
cp /root/backup-modprobe-15feb/vfio.conf /etc/modprobe.d/
cp /root/backup-modprobe-15feb/blacklist-nvidia.conf /etc/modprobe.d/
update-initramfs -u -k all
proxmox-boot-tool kernel pin 6.14.11-5-pve
reboot
```

nvidia-smi confirmed operational after rollback.

---

## Part 3 — Architecture Decision: Docker Host

### Comparison

| Criteria | VM Passthrough | Docker Host |
|----------|---------------|-------------|
| GPU sharing | Single VM only | Multiple containers simultaneously |
| Isolation | Full VM isolation on VLAN40 | Container namespaces + cgroups |
| Secure Boot | Complex (sign at two levels) | Simple (one MOK signature on host) |
| Snapshots | Independent VM snapshots | No separate snapshots |
| Industry usage | Enterprise production (VMware, vGPU) | Cloud/K8s deployments (EKS, GKE) |
| Flexibility | Shut down VM to reassign GPU | Start/stop containers in seconds |
| Current status | **Blocked** (Blackwell QEMU bug) | **Ready to deploy** |

### Decision

**Docker host with NVIDIA Container Toolkit** is the selected approach. The Ollama API will be exposed on VLAN40 via a virtual interface so VMs can access AI services over the network, maintaining logical segmentation.

Both approaches are documented as technical exercises for professional portfolio:
- VM passthrough: demonstrates VFIO/IOMMU/PCI passthrough knowledge
- Docker host: demonstrates NVIDIA Container Toolkit/K8s GPU Operator knowledge

### Future Migration Path (When Bug is Fixed)

1. Remove Docker and Ollama from host
2. Reconfigure vfio-pci to capture GPU
3. Create AI Lab VM on VLAN40 (192.168.40.10)
4. Pass GPU through to VM
5. Install NVIDIA drivers, Docker, NVIDIA Container Toolkit and Ollama inside VM

---

## Current MS-02 State

- **Kernel:** 6.14.11-5-pve (pinned)
- **GPU:** RTX PRO 4000 Blackwell — Driver 570.133.07, CUDA 12.8, 24GB GDDR7 ECC
- **Network:** SFP+ 10Gbps via 10Gtek DAC on nic2 (vmbr0)
- **VLANs:** 30 and 40 configured (bridge-vlan-aware)
- **Proxmox:** VE 9.1.5
- **Backups:** PBS integrated with Synology NAS

## Next Steps

1. Sign NVIDIA module with MOK key and re-enable Secure Boot
2. Install Docker and NVIDIA Container Toolkit on MS-02 host
3. Deploy Ollama with GPU access
4. Deploy LLM models (qwen3:72b, mistral-large:123b, deepseek-r1:8b)
5. Expose Ollama API on VLAN40
6. Full documentation commit to GitHub
