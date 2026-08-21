# GOAD Troubleshooting — License & Trust Recovery

**Author:** hik3nR00t
**Date:** August 21, 2026
**Lab:** GOAD v3 — HikenRoot Forge
**Severity:** Critical — All VMs shutting down periodically

---

## Problem

After several months of operation, all 5 GOAD VMs started shutting down unexpectedly every hour. RDP connections failed with `STATUS_TRUSTED_RELATIONSHIP_FAILURE` on member servers, and `STATUS_LOGON_FAILURE` on domain controllers.

## Root Cause Analysis

Two separate issues identified:

### Issue 1 — Windows Server Evaluation License Expired

All GOAD VMs run Windows Server Evaluation editions (180-day trial). After expiration, Windows forces a shutdown every hour.

**Detection:**
```powershell
cscript //nologo C:\Windows\System32\slmgr.vbs /dli
```
```
Name: Windows(R), ServerDatacenterEval edition
Description: Windows(R) Operating System, TIMEBASED_EVAL channel
License Status: Notification
Notification Reason: 0xC004FC07
```

### Issue 2 — Domain Trust Relationship Broken

Member servers lost their trust relationship with domain controllers. This happens when the machine account password expires or desynchronizes (common after snapshot rollbacks).

**Detection:**
```
STATUS_TRUSTED_RELATIONSHIP_FAILURE [0xC000018D]
```
Even local accounts fail via RDP when NLA is enforced and the trust is broken — NLA requires domain controller contact for authentication.

---

## Resolution

### Step 1 — License Rearm (all 5 VMs)

Windows Evaluation can be rearmed up to 6 times, resetting the 180-day timer.

**For VMs with working credentials (DCs):**
```bash
evil-winrm -i <DC_IP> -u administrator -H <NT_HASH>
```
```powershell
cscript //nologo C:\Windows\System32\slmgr.vbs /rearm
Restart-Computer -Force
```

**For VMs with broken trust (member servers):**

When domain credentials fail, use impacket-psexec with local account:
```bash
impacket-psexec './<local_user>:<password>@<TARGET_IP>'
```
```cmd
cscript //nologo C:\Windows\System32\slmgr.vbs /rearm
net user administrator <NEW_PASSWORD>
shutdown /r /t 5
```

**For VMs where only Proxmox console works:**

Access via Proxmox VE web console (noVNC) → login with local account → PowerShell as admin:
```powershell
cscript //nologo C:\Windows\System32\slmgr.vbs /rearm
Restart-Computer -Force
```

### Step 2 — Password Reset (where needed)

Admin passwords had changed or were unknown. Reset approach per domain:

**Standard reset (child domains):**
```powershell
net user administrator <NEW_PASSWORD> /domain
```

**When password policy blocks reset (forest root — 14 chars min + 24 history):**

`net user` failed with:
```
The password does not meet the password policy requirements.
```

Fix — use `Set-ADAccountPassword` which bypasses minimum age:
```powershell
Set-ADAccountPassword -Identity administrator -Reset -NewPassword (ConvertTo-SecureString '<COMPLEX_PASSWORD>' -AsPlainText -Force)
```

### Step 3 — Trust Repair (member servers)

After rearm and password reset, member server still had a broken trust. The machine account was not found on the DC:
```
Reset-ComputerMachinePassword: Cannot find the computer account for the local computer from the domain controller
```

Fix — use `Test-ComputerSecureChannel` with `-Repair` from a local admin session (Proxmox console):
```powershell
Test-ComputerSecureChannel -Server <DC_IP> -Repair -Credential (New-Object System.Management.Automation.PSCredential("<DOMAIN>\administrator",(ConvertTo-SecureString "<PASSWORD>" -AsPlainText -Force)))
```
Result: `True` — trust restored.

---

## Access Methods Used (escalation path)

When standard RDP and WinRM failed, multiple access methods were attempted:

| Method | Target | Result |
|--------|--------|--------|
| `xfreerdp` with PTH | DC01 | ❌ NLA blocked PTH |
| `xfreerdp` with password | DC02 | ❌ Password changed |
| `xfreerdp /sec:rdp /nego:off` | SRV02 | ❌ TLS error |
| `evil-winrm` with hash | DC02 | ❌ WinRM auth failed |
| `evil-winrm` with hash | DC03 | ❌ Hash expired |
| `netexec smb` with domain user | DC03 | ✅ Low-priv user auth |
| `impacket-psexec` domain auth | SRV03 | ✅ Domain admin |
| `impacket-psexec` local auth | SRV02 | ✅ Local account |
| **Proxmox VNC console** | All VMs | ✅ **Last resort, always works** |

**Key takeaway:** Proxmox console (noVNC) is the ultimate fallback — no network, no NLA, no trust required.

---

## Verification

All 5 VMs validated with netexec — 5/5 `Pwn3d!` confirmed.

---

## Final State

| VM | Role | License | Trust |
|----|------|---------|-------|
| DC01 (Forest Root) | Domain Controller | ✅ 180 days | ✅ |
| DC02 (Child Domain) | Domain Controller | ✅ 180 days | ✅ |
| DC03 (External Forest) | Domain Controller | ✅ 180 days | ✅ |
| SRV02 (Member Server) | MSSQL + IIS | ✅ 180 days | ✅ Repaired |
| SRV03 (Member Server) | MSSQL + CA | ✅ 180 days | ✅ |

---

## Lessons Learned

1. **Schedule license rearm** — set a calendar reminder at 150 days to rearm before expiration
2. **Snapshot before hardening** — always create a Proxmox snapshot before running security scripts that may change passwords
3. **Document all password changes** — maintain a credential vault for lab environments
4. **Proxmox console is king** — when all network-based auth fails, noVNC console is the last resort
5. **Trust repair order matters** — fix DC first, then member servers. Use `Test-ComputerSecureChannel -Repair` before attempting domain re-join
6. **Password policy awareness** — `Set-ADAccountPassword -Reset` bypasses minimum password age, unlike `net user /domain`

---

## MITRE ATT&CK Relevance

This troubleshooting scenario mirrors real-world defensive operations:

| Technique | ID | Relevance |
|-----------|-----|-----------|
| Valid Accounts: Domain | T1078.002 | Recovering domain admin access after credential loss |
| Pass-the-Hash | T1550.002 | Using NT hashes when cleartext passwords are unknown |
| Remote Services: SMB | T1021.002 | impacket-psexec for remote command execution |
| Account Manipulation | T1098 | Password resets across multiple domains |

---

*hik3nR00t — HikenRoot Forge — GOAD Troubleshooting*
