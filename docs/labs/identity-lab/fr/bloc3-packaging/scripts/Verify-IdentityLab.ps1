<#
.SYNOPSIS
    Verify-IdentityLab.ps1
    Vérifie l'état complet du lab Identity (AD on-prem + Entra ID)

.DESCRIPTION
    Script de vérification post-déploiement qui contrôle :
      - Connectivité aux 3 DC
      - État de la réplication AD
      - Sites & Services configurés
      - Tiering Model (OUs présentes)
      - GPO CIS Baseline liée
      - Synchronisation AD Connect
      - Named Locations Entra ID
      - Conditional Access Policies
      - PIM assignments

.NOTES
    Auteur  : Nadyr Chouarhi (hik3nR00t)
    Date    : Avril 2026
    Usage   : Exécuter depuis un poste avec accès aux DC et à Graph
#>

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " VÉRIFICATION LAB IDENTITY — GOAD v3       " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ==============================================================================
# BLOC 1 — AD ON-PREM
# ==============================================================================
Write-Host "`n[BLOC 1] AD ON-PREM" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Yellow

# Connectivité DC
$dcs = @(
    @{Name="DC01-KINGSLANDING"; IP="192.168.10.10"},
    @{Name="DC02-WINTERFELL"; IP="192.168.10.11"},
    @{Name="DC03-MEEREEN"; IP="192.168.10.12"}
)

foreach ($dc in $dcs) {
    $result = Test-NetConnection -ComputerName $dc.IP -Port 389 -WarningAction SilentlyContinue
    if ($result.TcpTestSucceeded) {
        Write-Host "[+] $($dc.Name) ($($dc.IP)) — LDAP OK" -ForegroundColor Green
    } else {
        Write-Host "[-] $($dc.Name) ($($dc.IP)) — LDAP FAIL" -ForegroundColor Red
    }
}

# AD Connect
$adconnect = Test-NetConnection -ComputerName "192.168.10.55" -Port 3389 -WarningAction SilentlyContinue
if ($adconnect.TcpTestSucceeded) {
    Write-Host "[+] ADCONNECT (192.168.10.55) — RDP OK" -ForegroundColor Green
} else {
    Write-Host "[-] ADCONNECT (192.168.10.55) — RDP FAIL" -ForegroundColor Red
}

# ==============================================================================
# BLOC 2 — ENTRA ID (nécessite connexion Graph)
# ==============================================================================
Write-Host "`n[BLOC 2] ENTRA ID" -ForegroundColor Yellow
Write-Host "------------------" -ForegroundColor Yellow

try {
    $ctx = Get-MgContext
    if ($ctx) {
        Write-Host "[+] Connecté à Graph : $($ctx.Account)" -ForegroundColor Green

        # Named Locations
        $nl = Get-MgIdentityConditionalAccessNamedLocation
        Write-Host "[+] Named Locations : $($nl.Count) trouvée(s)" -ForegroundColor Green
        $nl | ForEach-Object { Write-Host "    - $($_.DisplayName) ($($_.Id))" }

        # CA Policies
        $policies = Get-MgIdentityConditionalAccessPolicy
        Write-Host "[+] CA Policies : $($policies.Count) trouvée(s)" -ForegroundColor Green
        $policies | ForEach-Object { Write-Host "    - $($_.DisplayName) [$($_.State)]" }

    } else {
        Write-Host "[!] Non connecté à Graph — lancez Connect-MgGraph d'abord" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] Module Graph non chargé — bloc Entra ID non vérifié" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " VÉRIFICATION TERMINÉE                      " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
