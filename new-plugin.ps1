<#
.SYNOPSIS
    Starts a new plugin from this template. The Windows counterpart of
    new-plugin.sh.

.EXAMPLE
    .\new-plugin.ps1 -Name Vignette
    .\new-plugin.ps1 -Name Vignette -Dest C:\code\Vignette -Vendor Acme

.NOTES
    Copies the template (without its git history, build output or SDK),
    replaces the placeholder identity everywhere, resets the version to build 1,
    and initialises a fresh git repo with one commit.

    KEEP THIS FILE PURE ASCII - see the note in build.ps1.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Dest,
    [string]$Display,
    [string]$Vendor = $(if ($env:AE_PLUGIN_VENDOR) { $env:AE_PLUGIN_VENDOR } else { 'Acme' }),
    [string]$MatchName,
    [string]$Category,
    [string]$BundleId,
    [string]$EnvPrefix,
    [string]$LogName
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if ($Name -notmatch '^[A-Za-z][A-Za-z0-9_]*$') {
    throw "Plugin name must be a bare identifier (letters, digits, underscore): got '$Name'"
}

if (-not $Dest)      { $Dest = Join-Path (Split-Path $root -Parent) $Name }
if (Test-Path $Dest) { throw "Destination already exists: $Dest" }

# Defaults, derived the same way new-plugin.sh derives them.
if (-not $Display)   { $Display = [regex]::Replace($Name, '([a-z0-9])([A-Z])', '$1 $2') }
if (-not $MatchName) {
    $prefix = $Vendor.Substring(0, [Math]::Min(4, $Vendor.Length)).ToUpper()
    $MatchName = "$prefix $Display"
}
if (-not $Category)  { $Category = $Vendor }
if (-not $BundleId)  {
    $lowerVendor = ($Vendor -replace '[^A-Za-z0-9]', '').ToLower()
    $BundleId = "com.$lowerVendor.$($Name.ToLower())"
}
if (-not $EnvPrefix) { $EnvPrefix = ($Name -replace '[^A-Za-z0-9_]', '').ToUpper() }
if (-not $LogName)   { $LogName = "$($Name.ToLower()).log" }

Write-Host ""
Write-Host "New plugin: $Name -> $Dest"
Write-Host "  display     $Display"
Write-Host "  match name  $MatchName   (PERMANENT)"
Write-Host "  category    $Category"
Write-Host "  vendor      $Vendor"
Write-Host "  bundle id   $BundleId"
Write-Host "  diagnostics ${EnvPrefix}_DIAG -> $LogName"
Write-Host ""

# --- copy -------------------------------------------------------------------
$skipDirs = @('.git', 'build', 'build-dist', 'dist', 'sdk')
$skipFiles = @('new-plugin.sh', 'new-plugin.ps1', '.DS_Store')

New-Item -ItemType Directory -Path $Dest -Force | Out-Null
Get-ChildItem $root -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
    $top = ($rel -split '[\\/]')[0]
    if ($skipDirs -contains $top) { return }
    if ($skipFiles -contains $_.Name) { return }
    $outPath = Join-Path $Dest $rel
    New-Item -ItemType Directory -Path (Split-Path $outPath -Parent) -Force | Out-Null
    Copy-Item $_.FullName -Destination $outPath -Force
}

# --- replace the placeholder identity ---------------------------------------
# Order matters: longest and most specific first, so "ACME My Effect" is not
# half-rewritten by the "My Effect" rule.
$replacements = [ordered]@{
    'ACME My Effect'    = $MatchName
    'com.acme.myeffect' = $BundleId
    'myeffect.log'      = $LogName
    'MYEFFECT'          = $EnvPrefix
    'My Effect'         = $Display
    'MyEffect'          = $Name
    'Acme'              = $Vendor
}

$textExt = @('.md', '.txt', '.cmake', '.in', '.h', '.cpp', '.inl', '.sh', '.ps1')
Get-ChildItem $Dest -Recurse -File | Where-Object {
    $textExt -contains $_.Extension -or $_.Name -eq 'LICENSE'
} | ForEach-Object {
    $text = Get-Content $_.FullName -Raw
    foreach ($kv in $replacements.GetEnumerator()) {
        $text = $text.Replace($kv.Key, $kv.Value)
    }
    Set-Content -Path $_.FullName -Value $text -NoNewline
}

# Category is separate from the vendor, so set it directly.
$cfgPath = Join-Path $Dest 'cmake\PluginConfig.cmake'
$cfg = Get-Content $cfgPath -Raw
$cfg = $cfg.Replace("set(PLUGIN_CATEGORY `"$Vendor`")", "set(PLUGIN_CATEGORY `"$Category`")")
Set-Content -Path $cfgPath -Value $cfg -NoNewline

# --- reset version and changelog --------------------------------------------
$buildH = Join-Path $Dest 'src\ae\Build.h'
$text = Get-Content $buildH -Raw
$text = [regex]::Replace($text, '(?m)^#define PLUGIN_BUILD .*$', '#define PLUGIN_BUILD 1')
Set-Content -Path $buildH -Value $text -NoNewline

@"
# Changelog

## Unreleased

- build 1: created from the AE plugin template.
"@ | Set-Content -Path (Join-Path $Dest 'CHANGELOG.md')

# --- fresh history ----------------------------------------------------------
if (Get-Command git -ErrorAction SilentlyContinue) {
    Push-Location $Dest
    try {
        git init -q
        git add -A
        git commit -q -m "Initial commit: $Display from AE plugin template"
    } catch {
        Write-Host "(git init/commit skipped)" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

Write-Host "Created $Dest" -ForegroundColor Green
Write-Host ""
Write-Host "Next:"
Write-Host "  cd `"$Dest`""
Write-Host "  .\build.ps1 -Test -Install    # quit After Effects first"
Write-Host ""
Write-Host "Then look for Effect > $Category > $Display in After Effects."
