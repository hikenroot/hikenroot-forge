<#
.SYNOPSIS
    Deploy-ConditionalAccess.ps1
    Déploie 1 Named Location + 4 Conditional Access Policies en Report-only

.DESCRIPTION
    Contexte : Lab GOAD v3 — Phase 5 (Conditional Access + PIM)
    Déploiement via Microsoft Graph PowerShell — méthode recommandée par Microsoft
    pour les déploiements IaC en environnement entreprise.

    Crée :
      - Named Location "Blocked-Countries" (RU, CN, KP, IR)
      - CA001-Block-Legacy-Auth
      - CA002-MFA-Admins
      - CA003-Block-Countries
      - CA004-Session-Admin-Portal

    Toutes les policies sont en mode Report-only (pas d'enforcement).
    Les comptes Break Glass sont exclus de toutes les policies.

    Prérequis :
      - PowerShell 7+ (pwsh) — PS 5.1 a un bug WAM avec DeviceCode
      - Modules : Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users
      - Licence Entra ID P1 ou P2 active sur le tenant
      - Rôle : Global Admin ou Conditional Access Admin

    Usage :
      pwsh
      Set-MgGraphOption -DisableLoginByWAM $true
      .\Deploy-ConditionalAccess.ps1

.NOTES
    Auteur  : Nadyr Chouarhi (hik3nR00t)
    Date    : Avril 2026
    Tenant  : nchouarhipm.onmicrosoft.com
    Testé   : PowerShell 7.6.0 sur WSL Ubuntu 24.04
#>

param(
    [string]$TenantId = "eea0e92c-08ea-4aa8-a0b2-d5e8854c81cd",
    [string]$BG01_UPN = "breakglass01@nchouarhipm.onmicrosoft.com",
    [string]$BG02_UPN = "breakglass02@nchouarhipm.onmicrosoft.com"
)

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users

# ==============================================================================
# CONNEXION
# ==============================================================================
Write-Host "[*] Connexion à Microsoft Graph (Device Code)..." -ForegroundColor Cyan
Write-Host "[*] Ouvrez https://microsoft.com/devicelogin sur votre navigateur" -ForegroundColor Yellow

Connect-MgGraph -Scopes @(
    "Policy.ReadWrite.ConditionalAccess",
    "Policy.Read.All",
    "Directory.Read.All",
    "User.Read.All"
) -TenantId $TenantId -UseDeviceCode -NoWelcome -ErrorAction Stop

$ctx = Get-MgContext
if (-not $ctx) {
    Write-Error "[-] Connexion échouée. Arrêt."
    exit 1
}
Write-Host "[+] Connecté en tant que $($ctx.Account)" -ForegroundColor Green

# ==============================================================================
# RÉCUPÉRATION DES BREAK GLASS
# ==============================================================================
Write-Host "[*] Récupération des comptes Break Glass..." -ForegroundColor Cyan

$bg01 = (Get-MgUser -Filter "userPrincipalName eq '$BG01_UPN'").Id
$bg02 = (Get-MgUser -Filter "userPrincipalName eq '$BG02_UPN'").Id

if (-not $bg01 -or -not $bg02) {
    Write-Error "[-] Impossible de trouver les comptes Break Glass. Arrêt."
    Disconnect-MgGraph
    exit 1
}
Write-Host "[+] BG01 = $bg01" -ForegroundColor Green
Write-Host "[+] BG02 = $bg02" -ForegroundColor Green

# ==============================================================================
# NAMED LOCATION — Blocked-Countries
# ==============================================================================
Write-Host "`n[*] Création Named Location 'Blocked-Countries'..." -ForegroundColor Cyan

$existingNL = Get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq "Blocked-Countries" }

if ($existingNL) {
    $namedLocationId = $existingNL.Id
    Write-Host "[=] Named Location existe déjà : $namedLocationId" -ForegroundColor Yellow
} else {
    $nl = New-MgIdentityConditionalAccessNamedLocation -BodyParameter @{
        "@odata.type"                     = "#microsoft.graph.countryNamedLocation"
        displayName                       = "Blocked-Countries"
        countriesAndRegions               = @("RU", "CN", "KP", "IR")
        includeUnknownCountriesAndRegions = $false
    }
    $namedLocationId = $nl.Id
    Write-Host "[+] Named Location créée : $namedLocationId" -ForegroundColor Green
}

# ==============================================================================
# ROLE TEMPLATE IDs (universels — identiques sur tous les tenants)
# ==============================================================================
$globalAdminRoleId   = "62e90394-69f5-4237-9190-012177145e10"
$userAdminRoleId     = "fe930be7-5e62-47db-91af-98c3a49a38b1"
$exchangeAdminRoleId = "29232cdf-9323-42fd-ade2-1d097af3e4de"

# ==============================================================================
# CA001 — Block Legacy Authentication
# ==============================================================================
Write-Host "`n[*] Création CA001-Block-Legacy-Auth..." -ForegroundColor Cyan

New-MgIdentityConditionalAccessPolicy -BodyParameter @{
    displayName = "CA001-Block-Legacy-Auth"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users          = @{ includeUsers = @("All"); excludeUsers = @($bg01, $bg02) }
        applications   = @{ includeApplications = @("All") }
        clientAppTypes = @("exchangeActiveSync", "other")
    }
    grantControls = @{ operator = "OR"; builtInControls = @("block") }
} -ErrorAction Stop | Out-Null
Write-Host "[+] CA001-Block-Legacy-Auth créée (Report-only)" -ForegroundColor Green

# ==============================================================================
# CA002 — MFA for Admins
# ==============================================================================
Write-Host "[*] Création CA002-MFA-Admins..." -ForegroundColor Cyan

New-MgIdentityConditionalAccessPolicy -BodyParameter @{
    displayName = "CA002-MFA-Admins"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users        = @{
            includeRoles = @($globalAdminRoleId, $userAdminRoleId, $exchangeAdminRoleId)
            excludeUsers = @($bg01, $bg02)
        }
        applications = @{ includeApplications = @("All") }
    }
    grantControls = @{ operator = "OR"; builtInControls = @("mfa") }
} -ErrorAction Stop | Out-Null
Write-Host "[+] CA002-MFA-Admins créée (Report-only)" -ForegroundColor Green

# ==============================================================================
# CA003 — Block Countries
# ==============================================================================
Write-Host "[*] Création CA003-Block-Countries..." -ForegroundColor Cyan

New-MgIdentityConditionalAccessPolicy -BodyParameter @{
    displayName = "CA003-Block-Countries"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users        = @{ includeUsers = @("All"); excludeUsers = @($bg01, $bg02) }
        applications = @{ includeApplications = @("All") }
        locations    = @{ includeLocations = @($namedLocationId) }
    }
    grantControls = @{ operator = "OR"; builtInControls = @("block") }
} -ErrorAction Stop | Out-Null
Write-Host "[+] CA003-Block-Countries créée (Report-only)" -ForegroundColor Green

# ==============================================================================
# CA004 — Session Admin Portal
# ==============================================================================
Write-Host "[*] Création CA004-Session-Admin-Portal..." -ForegroundColor Cyan

New-MgIdentityConditionalAccessPolicy -BodyParameter @{
    displayName = "CA004-Session-Admin-Portal"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users        = @{ includeRoles = @($globalAdminRoleId); excludeUsers = @($bg01, $bg02) }
        applications = @{ includeApplications = @("797f4846-ba00-4fd7-ba43-dac1f8f63013") }
    }
    sessionControls = @{
        signInFrequency = @{ value = 1; type = "hours"; isEnabled = $true }
    }
} -ErrorAction Stop | Out-Null
Write-Host "[+] CA004-Session-Admin-Portal créée (Report-only)" -ForegroundColor Green

# ==============================================================================
# VÉRIFICATION
# ==============================================================================
Write-Host "`n[*] Vérification..." -ForegroundColor Cyan
Write-Host "`n--- Named Locations ---" -ForegroundColor Yellow
Get-MgIdentityConditionalAccessNamedLocation | Format-Table DisplayName, Id

Write-Host "--- Conditional Access Policies ---" -ForegroundColor Yellow
Get-MgIdentityConditionalAccessPolicy | Format-Table DisplayName, State, Id

# ==============================================================================
# DÉCONNEXION
# ==============================================================================
Disconnect-MgGraph | Out-Null
Write-Host "`n[+] Terminé. 4 policies créées en Report-only." -ForegroundColor Green
Write-Host "[i] Vérifiez dans Entra ID > Accès conditionnel > Stratégies." -ForegroundColor Cyan
