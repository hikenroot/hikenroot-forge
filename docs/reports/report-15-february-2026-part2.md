# HikenRoot Forge — Session Report: February 15, 2026 (Part 2)

## Summary

Three milestones completed: Secure Boot enabled with MOK-signed NVIDIA modules, Docker with NVIDIA Container Toolkit installed, and Ollama deployed natively with full GPU acceleration on the RTX PRO 4000 Blackwell. A Docker container GPU detection issue was identified and bypassed by switching to native host installation.

---

## Part 1 — Secure Boot with MOK Signing

### Context

The NVIDIA 570.133.07 driver was running with Secure Boot disabled in the MS-02 BIOS. Enabling Secure Boot requires all kernel modules to be signed by a trusted key. Third-party modules like NVIDIA must be signed with a custom Machine Owner Key (MOK) enrolled in the UEFI firmware.

### Procedure

#### Generate MOK Key Pair

```bash
mkdir -p /root/mok-keys
cd /root/mok-keys
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.key -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=HikenRoot Forge MOK/"
```

A 2048-bit RSA key pair valid for 100 years. The DER format is required by the UEFI firmware.

#### Sign All NVIDIA Modules

```bash
for module in $(find /lib/modules/$(uname -r) -name "nvidia*.ko*"); do
    echo "Signing: $module"
    /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /root/mok-keys/MOK.key /root/mok-keys/MOK.der "$module"
done
```

Seven modules signed: nvidia.ko, nvidia-modeset.ko, nvidia-uvm.ko, nvidia-drm.ko, nvidia-peermem.ko, nvidiafb.ko, nvidia-wmi-ec-backlight.ko.

#### Enroll MOK in UEFI Firmware

```bash
mokutil --import /root/mok-keys/MOK.der
# Enter a temporary password (used once at next boot)
```

#### BIOS Configuration

1. Enter BIOS (DEL at boot)
2. Set Secure Boot Mode to **Custom** (required to accept third-party MOK keys)
3. Enable Secure Boot
4. Save and reboot

At reboot, the **MOK Manager** blue screen appears:
- Select **Enroll MOK** → **Continue** → **Yes**
- Enter the temporary password
- Select **Reboot**

### Verification

```bash
mokutil --sb-state
# SecureBoot enabled

nvidia-smi
# Driver 570.133.07, CUDA 12.8, 24GB VRAM — operational
```

Secure Boot is active and NVIDIA drivers load successfully with the signed modules.

---

## Part 2 — Docker and NVIDIA Container Toolkit

### Docker Installation

```bash
apt install docker.io -y
systemctl enable docker
systemctl start docker
# Docker version 26.1.5
```

### NVIDIA Container Toolkit Installation

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt update
apt install nvidia-container-toolkit -y
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
```

### GPU Passthrough to Containers — Verified

```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
# GPU visible inside container: RTX PRO 4000 Blackwell, 24GB VRAM
```

Docker containers can access the GPU successfully.

---

## Part 3 — Ollama Deployment

### Docker Container Issue

Initial deployment via Docker container:

```bash
docker run -d --gpus all -v ollama:/root/.ollama -p 11434:11434 --name ollama --restart always ollama/ollama
```

The container detected 0 GPUs despite `nvidia-smi` working inside it. Debug logs showed:

```
msg="discovering available GPUs..."
msg="inference compute" id=cpu library=cpu total="188.4 GiB"
msg="offloaded 0/37 layers to GPU"
```

The Ollama GPU discovery subprocess failed to enumerate the RTX PRO 4000 Blackwell (compute capability 12.0) even though the CUDA libraries (`libggml-cuda.so`) contained `sm_120` support. The bootstrap discovery process returned `initial_count=0` devices.

This appears to be a container-specific issue with the Blackwell architecture GPU discovery, possibly related to the NVIDIA Container Toolkit CDI configuration or the way the Ollama runner subprocess initializes CUDA within the container namespace.

### Native Host Installation — Working

```bash
curl -fsSL https://ollama.com/install.sh | sh
# >>> NVIDIA GPU installed.
```

The native installation detected the GPU immediately.

### GPU Verification

```bash
ollama run deepseek-r1:8b "Hello"

nvidia-smi
# Memory-Usage: 9731MiB / 24467MiB
# Process: /usr/local/bin/ollama — 9722MiB

ollama ps
# deepseek-r1:8b    10 GB    100% GPU    32768 context
```

The model runs entirely on the GPU with a 32K token context window.

### Architecture Decision

Ollama runs natively on the host instead of inside a Docker container. Docker with NVIDIA Container Toolkit remains installed and functional for other AI workloads (Garak, Jupyter, custom containers). The Ollama API is accessible on port 11434 and can be exposed on VLAN40 for network access from other VMs.

### Why Native Host Instead of VM Passthrough

GPU passthrough via VFIO was tested earlier in this session (documented in [report-14-15-february-2026.md](report-14-15-february-2026.md)). The RTX PRO 4000 Blackwell triggers a fatal QEMU bug:

```
error writing '1' to '/sys/bus/pci/devices/0000:02:00.0/reset': Inappropriate ioctl for device
kvm: ../hw/pci/pci.c:1815: pci_irq_handler: Assertion '0 <= irq_num && irq_num < PCI_NUM_PINS' failed.
TASK ERROR: start failed: QEMU exited with code 1
```

The PCI reset function is not supported by the Blackwell architecture in QEMU/KVM, causing an IRQ handler crash. This was tested multiple times with OVMF, Q35, and correct IOMMU/Resizable BAR configuration. The test is documented with full procedure and rollback.

The native host deployment provides additional operational advantages:

- Multiple services share the GPU simultaneously (Ollama, Garak, Jupyter)
- Single MOK signature for Secure Boot (host only, no VM-level signing)
- Industry-standard deployment method (NVIDIA Container Toolkit, used in EKS/GKE)
- Faster iteration cycle for AI security research

A migration path to VM passthrough is documented for when NVIDIA or QEMU resolve the Blackwell PCI reset bug.

### Why This Approach Fits HikenRoot Forge

HikenRoot Forge is a multi-domain cybersecurity lab where the AI Lab (VLAN40) must interact with other lab segments. The native host deployment aligns better with the project architecture:

- **AI security testing requires multiple tools running simultaneously.** Ollama serves models while Garak runs adversarial tests and Clawbot performs autonomous penetration testing. Passthrough would lock the GPU to a single VM.
- **Cross-lab integration.** The Ollama API on port 11434 can be accessed from any VLAN through pfSense routing, enabling AD Lab VMs (VLAN10) or Cloud Lab containers (VLAN30) to leverage AI capabilities without GPU hardware dependency.
- **Certification alignment.** CAIPT-RT and C-AI/MLPen certifications focus on Docker-based AI deployments, not VM passthrough. This setup provides direct hands-on experience with the industry-standard toolchain.
- **Phase 2 readiness.** When K3s clusters are deployed in the Cloud Lab, the NVIDIA GPU Operator can manage GPU scheduling across containers, building on the Docker + NVIDIA Container Toolkit foundation already in place.
- **Operational resilience.** If Ollama breaks, a single command (`curl -fsSL https://ollama.com/install.sh | sh`) restores it in under 2 minutes. A broken passthrough VM requires full OS reinstallation, driver setup, and network reconfiguration. Downloaded models (5-70 GB each) persist in `/usr/share/ollama/.ollama/models` and survive Ollama updates without re-downloading.
- **Unified monitoring.** Prometheus and nvidia-smi on the host provide a single view of GPU utilization, Docker containers, Ollama inference, and Proxmox VMs. With passthrough, an additional monitoring agent inside the VM would be required to achieve the same visibility.

---

## Current MS-02 State

- **Kernel:** 6.14.11-5-pve (pinned)
- **Secure Boot:** Enabled (Custom mode, MOK enrolled)
- **GPU:** RTX PRO 4000 Blackwell — Driver 570.133.07, CUDA 12.8, 24GB GDDR7 ECC
- **Network:** SFP+ 10Gbps via DAC 10Gtek on nic2 (vmbr0)
- **VLANs:** 30 and 40 configured (bridge-vlan-aware)
- **Docker:** 26.1.5 with NVIDIA Container Toolkit 1.18.2
- **Ollama:** 0.16.1 native, GPU-accelerated, deepseek-r1:8b deployed
- **Proxmox:** VE 9.1.5

## Next Steps

1. Deploy additional LLM models (qwen3:72b, mistral-large:123b)
2. Expose Ollama API on VLAN40 (192.168.40.x)
3. Deploy Garak for LLM security testing
4. Begin Phase 2: Cloud Lab (K3s), SOC Lab (Wazuh), Guacamole
