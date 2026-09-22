<#
.SYNOPSIS
    Automate the OAuthPluginVault setup for the ADO Cowork Plugin (Option C — M365 Copilot),
    and provide a fast, low-risk path to update an already-deployed tenant to a newer version.

.DESCRIPTION
    Automates everything in the "Step 6 — Authentication" section of README.md that can be
    driven from the Microsoft Graph / Azure CLI:
      1. Creates (or reuses) an Azure AD app registration scoped to the Azure DevOps
         `user_impersonation` delegated permission and grants admin consent.
      2. Creates a client secret and prints the Application (client) ID, Directory
         (tenant) ID, and secret value needed for the Teams Developer Portal form.
      3. Prompts for the OAuth registration ID (`referenceId`) produced by the Teams
         Developer Portal — that step has no public API and cannot be automated.
      4. Patches manifest.json (`mcpServerUrl`, `authorization.referenceId`, optionally `id`)
         and bumps the version.
      5. Appends a dated entry to CHANGELOG.md and moves any `[Unreleased]` notes into it.
      6. Re-runs package.ps1 to validate ASKILL rules and produce the ZIP.

    Requires the Azure CLI (`az`) to be installed and logged in (`az login`), or the
    Microsoft.Graph / Az.Resources PowerShell modules. The Teams Developer Portal OAuth
    client registration (dev.teams.microsoft.com) must still be completed manually in a
    browser — Microsoft does not expose a public API for it.

    Use `-UpdateOnly` for the common "I already have auth configured from a previous run,
    I just want to push a newer version" case (e.g. upgrading an existing 1.1.0 tenant
    deployment to 1.2.0+). It skips the Azure AD app registration/secret and the Teams
    Developer Portal `referenceId` prompt entirely, leaves the existing `mcpServerUrl` and
    `authorization` block in manifest.json untouched, and only bumps the version, appends a
    changelog entry, and re-packages — the minimum needed to produce a ZIP you can upload
    via **Agents → All agents → ADO Cowork → Update**.

.PARAMETER OrgName
    Azure DevOps organisation name (the segment after dev.azure.com/ in the browser URL).
    Required unless -UpdateOnly is used, in which case the existing value in manifest.json
    is kept and this parameter can be omitted.

.PARAMETER AppDisplayName
    Display name for the Azure AD app registration. Defaults to "ADO Cowork Plugin".

.PARAMETER SecretExpiryMonths
    Lifetime, in months, of the generated client secret. Defaults to 12. A shorter value
    forces more frequent rotation reminders; a longer value reduces rotation friction.

.PARAMETER SkipAzureAd
    Skip app-registration creation/secret generation but still prompt for the
    Teams Developer Portal `referenceId` and patch manifest.json with it. Use this when you
    already have the Application (client) ID, Directory (tenant) ID and a fresh referenceId
    from a previous run. For a plain version update with no auth changes at all, use
    `-UpdateOnly` instead.

.PARAMETER UpdateOnly
    Fast update path: skips Azure AD provisioning AND the referenceId prompt, keeping
    manifest.json's existing `mcpServerUrl` and `authorization` block untouched. Only bumps
    the version, appends a CHANGELOG.md entry, and re-runs package.ps1. Use this to move an
    already-configured tenant (e.g. one running 1.1.0 with auth already set up) to a newer
    version without re-running the Azure AD / Teams Developer Portal steps.

.PARAMETER NewVersion
    Version string to write into manifest.json (e.g. "1.2.0"). If omitted, the patch
    segment of the current version is incremented automatically.

.EXAMPLE
    .\setup-auth.ps1 -OrgName contoso

.EXAMPLE
    .\setup-auth.ps1 -OrgName contoso -SecretExpiryMonths 6 -NewVersion 1.3.0

.EXAMPLE
    # Upgrade an existing tenant deployment (auth already configured) from 1.1.0 to 1.2.0
    .\setup-auth.ps1 -UpdateOnly -NewVersion 1.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OrgName,

    [string]$AppDisplayName = "ADO Cowork Plugin",

    [ValidateRange(1, 24)]
    [int]$SecretExpiryMonths = 12,

    [switch]$SkipAzureAd,

    [switch]$UpdateOnly,

    [string]$NewVersion
)

if (-not $UpdateOnly -and -not $OrgName) {
    Write-Error "-OrgName is required unless -UpdateOnly is used."
    exit 1
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root         = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $root "manifest.json"
$changelogPath = Join-Path $root "CHANGELOG.md"
$packagePath  = Join-Path $root "package.ps1"

# Well-known Azure DevOps resource ID and the user_impersonation delegated permission ID.
$adoResourceAppId       = "499b84ac-1321-427f-aa17-267ca6975798"
$adoUserImpersonationId = "ee69721e-6c3a-468f-a9ec-302d16a4c599"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
}

if (-not (Test-Path $manifestPath)) {
    Write-Error "manifest.json not found at: $manifestPath"
    exit 1
}

# ---------------------------------------------------------------------------
# Step 1-2 — Azure AD app registration + client secret (automatable)
# ---------------------------------------------------------------------------
$appId = $null
$tenantId = $null
$secretValue = $null
$secretExpiry = $null
$referenceId = $null

if ($UpdateOnly) {
    Write-Section "Update-only mode (-UpdateOnly)"
    Write-Host "Skipping Azure AD provisioning and the Teams Developer Portal prompt."
    Write-Host "manifest.json's existing 'mcpServerUrl' and 'authorization' block will be kept as-is."
    Write-Host "Use this when auth is already configured (e.g. upgrading an existing 1.1.0 tenant deployment)."
} elseif (-not $SkipAzureAd) {
    Write-Section "Azure AD app registration"

    $az = Get-Command az -ErrorAction SilentlyContinue
    if (-not $az) {
        Write-Error "Azure CLI ('az') not found. Install it or re-run with -SkipAzureAd once you have the values from Step 6a manually."
        exit 1
    }

    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Error "Not logged in to Azure CLI. Run 'az login' first."
        exit 1
    }
    $tenantId = $account.tenantId
    Write-Host ("  Tenant: {0}" -f $tenantId)

    # Reuse an existing app registration with the same display name, otherwise create it.
    $existing = az ad app list --display-name $AppDisplayName --query "[0]" 2>$null | ConvertFrom-Json
    if ($existing) {
        $appId = $existing.appId
        Write-Host ("  Reusing existing app registration: {0}" -f $appId) -ForegroundColor Yellow
    } else {
        Write-Host "  Creating app registration..."
        $created = az ad app create --display-name $AppDisplayName --sign-in-audience AzureADMyOrg 2>$null | ConvertFrom-Json
        $appId = $created.appId
        Write-Host ("  Created app registration: {0}" -f $appId) -ForegroundColor Green
    }

    Write-Host "  Adding Azure DevOps user_impersonation delegated permission..."
    az ad app permission add --id $appId `
        --api $adoResourceAppId `
        --api-permissions "$adoUserImpersonationId=Scope" 2>$null | Out-Null

    Write-Host "  Granting admin consent..."
    try {
        az ad app permission admin-consent --id $appId 2>$null | Out-Null
        Write-Host "  Admin consent granted." -ForegroundColor Green
    } catch {
        Write-Warning "  Admin consent could not be granted automatically. Grant it manually in the Azure Portal (API permissions -> Grant admin consent) or re-run as a Global/Application Administrator."
    }

    Write-Section "Client secret"
    $secretExpiry = (Get-Date).AddMonths($SecretExpiryMonths).ToString("yyyy-MM-dd")
    $secret = az ad app credential reset --id $appId --years 0 --end-date $secretExpiry 2>$null | ConvertFrom-Json
    $secretValue = $secret.password

    Write-Host ""
    Write-Host "  Application (client) ID : $appId"
    Write-Host "  Directory (tenant) ID   : $tenantId"
    Write-Host "  Client secret           : $secretValue"
    Write-Host "  Secret expires          : $secretExpiry" -ForegroundColor Yellow
    Write-Host ""
    Write-Warning "Copy the secret value now - it will not be shown again. Add a calendar reminder for $secretExpiry to rotate it (see SECURITY.md - Secret rotation)."
} else {
    Write-Section "Skipping Azure AD app registration (-SkipAzureAd)"
}

if (-not $UpdateOnly) {
    # -----------------------------------------------------------------------
    # Step 3 — Teams Developer Portal OAuth client registration (manual, no public API)
    # -----------------------------------------------------------------------
    Write-Section "Teams Developer Portal (manual step)"
    Write-Host "Go to https://dev.teams.microsoft.com -> Tools -> OAuth client registration -> Register"
    Write-Host "and fill in the form using the values above (see README.md Step 6b for field-by-field guidance)."
    Write-Host "This step has no public REST/PowerShell API and cannot be automated."
    Write-Host ""

    $referenceId = Read-Host "Paste the OAuth registration ID (referenceId) from Teams Developer Portal"
    if ([string]::IsNullOrWhiteSpace($referenceId)) {
        Write-Error "referenceId is required to update manifest.json. Re-run once you have it."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Step 4 — Patch manifest.json
# ---------------------------------------------------------------------------
Write-Section "Patching manifest.json"

$manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json

if ($UpdateOnly) {
    Write-Host "  Keeping existing mcpServerUrl and authorization block unchanged."
} else {
    $manifest.agentConnectors[0].toolSource.remoteMcpServer.mcpServerUrl = "https://mcp.dev.azure.com/$OrgName"
    $manifest.agentConnectors[0].toolSource.remoteMcpServer.authorization.type = "OAuthPluginVault"
    $manifest.agentConnectors[0].toolSource.remoteMcpServer.authorization.referenceId = $referenceId
}

$currentVersion = $manifest.version
if (-not $NewVersion) {
    $parts = $currentVersion.Split('.')
    if ($parts.Count -eq 3) {
        $parts[2] = [string]([int]$parts[2] + 1)
        $NewVersion = [string]::Join('.', $parts)
    } else {
        Write-Error "Cannot auto-increment version '$currentVersion'. Pass -NewVersion explicitly."
        exit 1
    }
}
$manifest.version = $NewVersion

($manifest | ConvertTo-Json -Depth 20) | Set-Content -Path $manifestPath -Encoding utf8
if ($UpdateOnly) {
    Write-Host ("  manifest.json updated: version {0} -> {1} (mcpServerUrl/authorization unchanged)." -f $currentVersion, $NewVersion) -ForegroundColor Green
} else {
    Write-Host ("  manifest.json updated: version {0} -> {1}, org '{2}', referenceId set." -f $currentVersion, $NewVersion, $OrgName) -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Step 5 — Update CHANGELOG.md
# ---------------------------------------------------------------------------
Write-Section "Updating CHANGELOG.md"

if (Test-Path $changelogPath) {
    $changelog = Get-Content $changelogPath -Raw
    $today = (Get-Date).ToString("yyyy-MM-dd")

    $unreleasedPattern = '(?s)## \[Unreleased\]\s*(.*?)(\r?\n---)'
    $match = [regex]::Match($changelog, $unreleasedPattern)

    $unreleasedNotes = if ($match.Success) { $match.Groups[1].Value.Trim() } else { '' }
    if ([string]::IsNullOrWhiteSpace($unreleasedNotes) -or $unreleasedNotes -eq '- Placeholder for next changes') {
        $unreleasedNotes = if ($UpdateOnly) {
            "- Version bump only — no auth or skill changes (via ``setup-auth.ps1 -UpdateOnly``)"
        } else {
            "- Configured OAuthPluginVault authentication (org: $OrgName) via ``setup-auth.ps1``"
        }
    }

    $newEntry = @"
## [$NewVersion] — $today

### Changed
$unreleasedNotes

---

## [Unreleased]

- Placeholder for next changes
"@

    if ($match.Success) {
        $changelog = $changelog.Substring(0, $match.Index) + $newEntry
    } else {
        $changelog = $changelog.TrimEnd() + "`n`n---`n`n" + $newEntry
    }

    Set-Content -Path $changelogPath -Value $changelog -Encoding utf8
    Write-Host "  CHANGELOG.md updated with entry for $NewVersion." -ForegroundColor Green
} else {
    Write-Warning "CHANGELOG.md not found - skipping changelog update."
}

# ---------------------------------------------------------------------------
# Step 6 — Re-run package.ps1 (ASKILL validation + zip)
# ---------------------------------------------------------------------------
Write-Section "Packaging"

if (Test-Path $packagePath) {
    & $packagePath
} else {
    Write-Warning "package.ps1 not found - skipping validation/packaging step."
}

Write-Host ""
Write-Host "Done. Next manual step: upload ado-cowork-plugin.zip in admin.microsoft.com -> Agents -> All agents -> Update." -ForegroundColor Cyan
if ($secretExpiry) {
    Write-Host "Reminder: client secret for '$AppDisplayName' expires on $secretExpiry - rotate before then (see SECURITY.md)." -ForegroundColor Yellow
}
