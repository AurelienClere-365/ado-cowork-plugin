<#
.SYNOPSIS
    Validate ASKILL rules and package the ADO Cowork plugin as a ZIP.

.DESCRIPTION
    Runs P001-P008 validation checks against all skills referenced in manifest.json.
    If all checks pass, creates ado-cowork-plugin.zip ready for Cowork installation.
    Exits with code 1 if any validation fails - no ZIP is produced on failure.

.PARAMETER SkillsOnly
    When set, also copies the skills/ folder to the VS Code user prompts folder
    (%APPDATA%\Code\User\prompts) for Skills-only mode (Option A).

.EXAMPLE
    .\package.ps1

.EXAMPLE
    .\package.ps1 -SkillsOnly
#>
[CmdletBinding()]
param(
    [switch]$SkillsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root         = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $root "manifest.json"
$zipPath      = Join-Path $root "ado-cowork-plugin.zip"

# ---------------------------------------------------------------------------
# Load manifest
# ---------------------------------------------------------------------------
if (-not (Test-Path $manifestPath)) {
    Write-Error "manifest.json not found at: $manifestPath"
    exit 1
}

$manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
$skills   = $manifest.agentSkills

if (-not $skills -or $skills.Count -eq 0) {
    Write-Error "manifest.json has no agentSkills entries."
    exit 1
}

# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------
$pass = $true

function Test-Rule {
    param([string]$Code, [bool]$Ok, [string]$Message)
    if ($Ok) {
        Write-Host ("  [PASS] {0}" -f $Code) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] {0}  {1}" -f $Code, $Message) -ForegroundColor Red
        $script:pass = $false
    }
}

Write-Host ""
Write-Host "ADO Cowork Plugin - ASKILL Validation" -ForegroundColor Cyan
Write-Host ("  Manifest : {0}" -f $manifestPath)
Write-Host ("  Skills   : {0}" -f $skills.Count)
Write-Host ""

# ---------------------------------------------------------------------------
# P001 - Each agentSkills folder exists
# ---------------------------------------------------------------------------
Write-Host "P001  Folder exists" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillDir = Join-Path $root $skill.folder.Replace('/', '\')
    Test-Rule "P001/$($skill.folder)" (Test-Path $skillDir -PathType Container) `
              "Folder not found: $skillDir"
}

# ---------------------------------------------------------------------------
# P002 - Each skill folder contains a SKILL.md file
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P002  SKILL.md present" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    Test-Rule "P002/$($skill.folder)" (Test-Path $skillMd) "SKILL.md not found: $skillMd"
}

# ---------------------------------------------------------------------------
# P003 - SKILL.md starts with YAML frontmatter (--- block)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P003  YAML frontmatter present" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    if (Test-Path $skillMd) {
        $content = [IO.File]::ReadAllText($skillMd)
        Test-Rule "P003/$($skill.folder)" ($content.TrimStart().StartsWith('---')) `
                  "SKILL.md does not start with --- frontmatter"
    }
}

# ---------------------------------------------------------------------------
# P004 - frontmatter contains a 'name:' field
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P004  name: field present" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    if (Test-Path $skillMd) {
        $content = [IO.File]::ReadAllText($skillMd)
        Test-Rule "P004/$($skill.folder)" ($content -match 'name:\s+\S') `
                  "Missing 'name:' in frontmatter"
    }
}

# ---------------------------------------------------------------------------
# P005 - frontmatter contains a 'description:' field
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P005  description: field present" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    if (Test-Path $skillMd) {
        $content = [IO.File]::ReadAllText($skillMd)
        Test-Rule "P005/$($skill.folder)" ($content -match 'description:') `
                  "Missing 'description:' in frontmatter"
    }
}

# ---------------------------------------------------------------------------
# P006 - name: matches the folder name (last segment of agentSkills path)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P006  name matches folder" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    $folderName = Split-Path $skill.folder -Leaf
    if (Test-Path $skillMd) {
        $content = [IO.File]::ReadAllText($skillMd)
        $nameMatch = [regex]::Match($content, 'name:\s+(\S+)')
        if ($nameMatch.Success) {
            $nameVal = $nameMatch.Groups[1].Value.Trim('"').Trim("'")
            Test-Rule "P006/$($skill.folder)" ($nameVal -eq $folderName) `
                      "name: '$nameVal' does not match folder '$folderName'"
        } else {
            Test-Rule "P006/$($skill.folder)" $false "Could not extract name: value"
        }
    }
}

# ---------------------------------------------------------------------------
# P007 - SKILL.md has a non-trivial body (at least 200 characters after frontmatter)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P007  Non-trivial body" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    if (Test-Path $skillMd) {
        $content  = [IO.File]::ReadAllText($skillMd)
        $bodyStart = $content.IndexOf('---', 3)   # closing ---
        $body     = if ($bodyStart -ge 0) { $content.Substring($bodyStart + 3) } else { '' }
        Test-Rule "P007/$($skill.folder)" ($body.Trim().Length -ge 200) `
                  "Skill body too short ($($body.Trim().Length) chars, minimum 200)"
    }
}

# ---------------------------------------------------------------------------
# P008 - license: MIT present in frontmatter
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "P008  license: MIT" -ForegroundColor DarkCyan
foreach ($skill in $skills) {
    $skillMd = Join-Path $root "$($skill.folder.Replace('/', '\'))\SKILL.md"
    if (Test-Path $skillMd) {
        $content = [IO.File]::ReadAllText($skillMd)
        Test-Rule "P008/$($skill.folder)" ($content -match 'license:\s+MIT') `
                  "Missing 'license: MIT' in frontmatter"
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
if (-not $pass) {
    Write-Host "VALIDATION FAILED - fix the above issues and re-run." -ForegroundColor Red
    exit 1
}

Write-Host "All validations passed." -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------------------------
# Package as ZIP
# ---------------------------------------------------------------------------
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$include = @('manifest.json','README.md','CHANGELOG.md','CONTRIBUTING.md',
             'PRIVACY.md','SECURITY.md','LICENSE','EXAMPLES.md',
             'package.ps1','color.png','outline.png',
             'architecture.png','architecture.mmd','ado-mcp-tools.json')

$tempDir = Join-Path $env:TEMP "ado-cowork-pkg-$(New-Guid)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

foreach ($file in $include) {
    $src = Join-Path $root $file
    if (Test-Path $src) { Copy-Item $src $tempDir }
}

# Copy skills/
$skillsSrc = Join-Path $root "skills"
if (Test-Path $skillsSrc) {
    Copy-Item $skillsSrc (Join-Path $tempDir "skills") -Recurse
}

Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath
Remove-Item $tempDir -Recurse -Force

Write-Host ("ZIP created: {0}" -f $zipPath) -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Skills-only install (Option A)
# ---------------------------------------------------------------------------
if ($SkillsOnly) {
    $promptsFolder = Join-Path $env:APPDATA "Code\User\prompts"
    if (-not (Test-Path $promptsFolder)) {
        New-Item -ItemType Directory -Path $promptsFolder -Force | Out-Null
    }
    $destSkills = Join-Path $promptsFolder "ado-cowork"
    if (Test-Path $destSkills) { Remove-Item $destSkills -Recurse -Force }
    Copy-Item (Join-Path $root "skills") $destSkills -Recurse
    Write-Host ("Skills copied to: {0}" -f $destSkills) -ForegroundColor Cyan
    Write-Host "Restart VS Code to pick up the new skills." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
