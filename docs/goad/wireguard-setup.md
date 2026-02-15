# WireGuard VPN Configuration

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [pfSense Configuration](#pfsense-configuration)
- [Client Configuration (Kali)](#client-configuration-kali)
- [Testing and Validation](#testing-and-validation)
- [Troubleshooting](#troubleshooting)
- [Configuration Summary](#configuration-summary)

## Architecture

```
┌─────────────┐     WireGuard      ┌─────────────┐           ┌─────────────┐
│    KALI     │ ◄────────────────► │   pfSense   │ ◄───────► │    GOAD     │
│ 192.168.50.x│     UDP 51820      │ 10.10.10.1  │  Routing  │ 192.168.10.x│
│ 10.10.10.2  │                    │ 192.168.50. │           │ DC01, DC02  │
│             │                    │     250     │           │ DC03, SRV02 │
│             │                    │             │           │ SRV03       │
└─────────────┘                    └─────────────┘           └─────────────┘
```

**Design principles:**
- Secure access to the lab from the home LAN
- Complete isolation of the GOAD network
- No direct exposure of Windows VMs to the LAN
- Encrypted traffic between attack machine and lab

## Prerequisites

### pfSense

- pfSense 2.5+ installed
- Interface on the LAN network (192.168.50.x)
- Admin access to the web interface

### Attack Machine

- WireGuard installed
- Connectivity to 192.168.50.x network

## pfSense Configuration

### Step 1: Install WireGuard Package

1. Navigate to System → Package Manager → Available Packages
2. Search for "WireGuard"
3. Click Install
4. Wait for installation to complete

### Step 2: Add a Network Interface for VPN Access

On Proxmox, add a NIC to pfSense on vmbr0:

```bash
qm set 101 --net4 virtio,bridge=vmbr0
```

On pfSense:

1. Navigate to Interfaces → Assignments
2. Add the new interface
3. Configure:

| Parameter | Value |
|-----------|-------|
| Enable | Yes |
| Description | PENTEST |
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | 192.168.50.250 / 24 |

4. Save → Apply Changes

### Step 3: Create the WireGuard Tunnel

1. Navigate to VPN → WireGuard → Tunnels
2. Click Add Tunnel
3. Configure:

| Parameter | Value |
|-----------|-------|
| Enable | Yes |
| Description | GOAD-VPN |
| Listen Port | 51820 |
| Interface Keys | Click Generate |

4. Save Tunnel
5. Copy the Public Key (required for client configuration)

### Step 4: Assign the WireGuard Interface

1. Navigate to Interfaces → Assignments
2. Add → Select tun_wg0
3. Configure:

| Parameter | Value |
|-----------|-------|
| Enable | Yes |
| Description | WG_GOAD |
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | 10.10.10.1 / 24 |

4. Save → Apply Changes

### Step 5: Add the Peer (Client)

1. Navigate to VPN → WireGuard → Peers
2. Click Add Peer
3. Configure:

| Parameter | Value |
|-----------|-------|
| Tunnel | GOAD-VPN |
| Description | Kali-Attacker |
| Dynamic Endpoint | Yes |
| Public Key | Client public key (see below) |
| Allowed IPs | 10.10.10.2/32 |

4. Save Peer

### Step 6: Firewall Rules

**On the PENTEST interface (192.168.50.250):**

Firewall → Rules → PENTEST → Add:

| Parameter | Value |
|-----------|-------|
| Action | Pass |
| Protocol | UDP |
| Destination Port | 51820 |
| Description | Allow WireGuard |

**On the WG_GOAD interface:**

Firewall → Rules → WG_GOAD → Add:

| Parameter | Value |
|-----------|-------|
| Action | Pass |
| Protocol | Any |
| Source | Any |
| Destination | Any |
| Description | Allow all WireGuard traffic |

Save → Apply Changes

## Client Configuration (Kali)

### Step 1: Install WireGuard

```bash
sudo apt update
sudo apt install wireguard -y
```

### Step 2: Generate Keys

```bash
cd /etc/wireguard
sudo wg genkey | sudo tee privatekey | wg pubkey | sudo tee publickey

# Display public key (copy to pfSense)
sudo cat publickey
```

### Step 3: Create Configuration File

```bash
sudo nano /etc/wireguard/wg-goad.conf
```

Content:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.10.10.2/24
DNS = 192.168.10.1

[Peer]
PublicKey = PFSENSE_PUBLIC_KEY_HERE
Endpoint = 192.168.50.250:51820
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
PersistentKeepalive = 25
```

### Step 4: Update Peer on pfSense

1. Go to VPN → WireGuard → Peers
2. Edit "Kali-Attacker" peer
3. Paste the Kali public key
4. Save Peer → Apply Changes

## Testing and Validation

### Start the Tunnel

```bash
sudo wg-quick up wg-goad
sudo wg show
```

Expected output:

```
interface: wg-goad
  public key: xxxxx
  private key: (hidden)
  listening port: xxxxx

peer: xxxxx
  endpoint: 192.168.50.250:51820
  allowed ips: 10.10.10.0/24, 192.168.10.0/24
  latest handshake: X seconds ago
  transfer: X KiB received, X KiB sent
```

Key indicator: `latest handshake` must show a recent timestamp and `received` must be > 0.

### Connectivity Tests

```bash
# Ping pfSense via WireGuard
ping -c 3 10.10.10.1

# Ping GOAD VMs
ping -c 3 192.168.10.10   # DC01
ping -c 3 192.168.10.11   # DC02
ping -c 3 192.168.10.12   # DC03
ping -c 3 192.168.10.22   # SRV02
ping -c 3 192.168.10.23   # SRV03
```

### Penetration Testing Validation

```bash
# SMB enumeration
crackmapexec smb 192.168.10.10-23

# Port scan
nmap -sC -sV 192.168.10.10
```

### Stop the Tunnel

```bash
sudo wg-quick down wg-goad
```

### Enable Auto-Start (Optional)

```bash
sudo systemctl enable wg-quick@wg-goad
```

## Troubleshooting

### Handshake Not Completing

**Check keys:**
```bash
# On Kali
sudo cat /etc/wireguard/publickey
# Compare with pfSense: VPN → WireGuard → Peers
```

**Check endpoint reachability:**
```bash
ping 192.168.50.250
nc -zvu 192.168.50.250 51820
```

### Transfer Shows 0 B Received

**Possible causes:** Incorrect keys, firewall blocking traffic.

**Solution:** Verify firewall rules on WG_GOAD interface allow all traffic (Pass Any Any).

### No Route to GOAD Network

**Symptom:** Ping 10.10.10.1 succeeds but 192.168.10.x fails.

**Solution:** Verify AllowedIPs includes the GOAD subnet:

```ini
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
```

## Configuration Summary

### pfSense Tunnel

| Parameter | Value |
|-----------|-------|
| Description | GOAD-VPN |
| Listen Port | 51820 |
| Interface IP | 10.10.10.1/24 |

### pfSense Peer

| Parameter | Value |
|-----------|-------|
| Description | Kali-Attacker |
| Public Key | Kali public key |
| Allowed IPs | 10.10.10.2/32 |

### Kali Client

```ini
[Interface]
PrivateKey = [Kali private key]
Address = 10.10.10.2/24

[Peer]
PublicKey = [pfSense public key]
Endpoint = 192.168.50.250:51820
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24
PersistentKeepalive = 25
```
