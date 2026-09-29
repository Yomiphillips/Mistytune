<#
.SYNOPSIS
    Configures and builds the plugin on Windows. Run from anywhere.

.EXAMPLE
    .\build.ps1
    .\build.ps1 -Test         # build and run the unit tests
    .\build.ps1 -Install      # also copy the .aex into AE's plugin folder
    .\build.ps1 -Hot          # swap render code with AE still running
    .\build.ps1 -Package      # build the distributable ZIP
    .\build.ps1 -Clean
    .\build.ps1 -Install -Dest "F:\some\other\Plug-ins\Effects"

.NOTES
    The plugin's NAME and VERSION are read out of cmake\PluginConfig.cmake and
    src\ae\Build.h, so this script needs no edit when you start a new plugin.

    KEEP THIS FILE PURE ASCII. Windows PowerShell 5.1 reads .ps1 files using
    the system ANSI codepage unless they carry a UTF-8 BOM, so a stray em-dash
    or smart quote written as UTF-8 gets mangled into garbage bytes and breaks
    parsing in ways that look nothing like an encoding problem.
#>
[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Hot,
    [switch]$Clean,
    [switch]$Test,
    [switch]$Package,
    [ValidateSet('Release', 'Debug')]
    [string]$Config = 'Release',
    [string]$Dest,
    # Leave empty to let CMake pick the newest Visual Studio it can find.
    [string]$Generator = ''
)

# -Hot is -Install without the "close After Effects first" requirement: it
# copies ONLY the impl DLL, which the stub loads via a shadow copy and can
# therefore swap while AE is running.
if ($Hot) { $Install = $true }

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# --- identity ---------------------------------------------------------------
$cfgPath = Join-Path $root 'cmake\PluginConfig.cmake'
$cfgText = Get-Content $cfgPath -Raw
function Get-Cfg([string]$name) {
    $pattern = '(?m)^\s*set\(\s*' + $name + '\s+"([^"]*)"'
    $m = [regex]::Match($cfgText, $pattern)
    if (-not $m.Success) { throw "Could not read $name from $cfgPath" }
    return $m.Groups[1].Value
}
$plugin = Get-Cfg 'PLUGIN_TARGET'

# -Package builds into its OWN directory, and that separation is load-bearing.
# The release shape is a different CMake configuration (PLUGIN_HOT_RELOAD=OFF),
# so sharing .\build with the dev loop would mean every -Package reconfigured it
# and the next plain build reconfigured it back.
$buildDir = if ($Package) { Join-Path $root 'build-dist' } else { Join-Path $root 'build' }

# Prefer a cmake on PATH; fall back to the one bundled with VS Build Tools.
$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) {
    $bundled = @(
        "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $bundled) { throw "No cmake found on PATH or in a Visual Studio install." }
    $cmake = $bundled
}
Write-Host "cmake: $cmake" -ForegroundColor DarkGray

if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "Removing $buildDir" -ForegroundColor Yellow
    Remove-Item $buildDir -Recurse -Force
}

# The AE SDK is Adobe's and is not in this repo. Adobe ships it as a
# zstd-compressed archive that must be extracted before use. An unextracted
# download looks exactly like a missing SDK to CMake, so say so explicitly.
$sdkDir = Join-Path $root 'sdk'
$sdkHit = $null
if (Test-Path $sdkDir) {
    $sdkHit = Get-ChildItem $sdkDir -Recurse -Filter 'AE_Effect.h' -ErrorAction SilentlyContinue |
              Select-Object -First 1
}
if (-not $sdkHit -and -not $env:AE_SDK_ROOT) {
    $archive = Get-ChildItem $sdkDir -Filter '*AfterEffectsSDK*.zip' -ErrorAction SilentlyContinue |
               Select-Object -First 1
    if ($archive) {
        throw "SDK archive found but not extracted: $($archive.Name). Run sdk\extractzstd.bat first."
    }
    throw "After Effects SDK not found. Download from https://developer.adobe.com/after-effects/ and unpack into .\sdk\, or set AE_SDK_ROOT."
}

# PLUGIN_HOT_RELOAD=OFF is what makes the .aex self-contained. See
# src\ae\CMakeLists.txt for why the stub must never reach a user.
$hotReload = if ($Package) { 'OFF' } else { 'ON' }

$configureArgs = @('-S', $root, '-B', $buildDir, "-DPLUGIN_HOT_RELOAD=$hotReload")
if ($Generator) { $configureArgs += @('-G', $Generator, '-A', 'x64') }

& $cmake @configureArgs
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed." }

& $cmake --build $buildDir --config $Config
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

$aex  = Join-Path $buildDir "src\ae\$Config\$plugin.aex"
$impl = Join-Path $buildDir "src\ae\$Config\${plugin}Impl.dll"

Write-Host ""
if (Test-Path $aex) { Write-Host "Built: $aex" -ForegroundColor Green }
else { Write-Host "No .aex was built (SDK missing? see above)." -ForegroundColor Yellow }

if ($Test) {
    # The engine has no AE dependency, so these run without launching After
    # Effects. That is the fast iteration loop -- use it.
    $exe = Join-Path $buildDir "tests\$Config\plugin_tests.exe"
    if (-not (Test-Path $exe)) { throw "Test binary not found: $exe" }
    Write-Host ""
    & $exe
    if ($LASTEXITCODE -ne 0) { throw "Unit tests FAILED." }
}

if ($Package) {
    # Version comes from the source, never from a string typed here. Two places
    # to edit is how a ZIP ends up named after a build it does not contain.
    $buildH = Join-Path $root 'src\ae\Build.h'
    $srcText = Get-Content $buildH -Raw
    function Get-Define([string]$name) {
        $m = [regex]::Match($srcText, "(?m)^#define\s+$name\s+(\d+)\s*$")
        if (-not $m.Success) { throw "Could not read $name from $buildH" }
        return [int]$m.Groups[1].Value
    }
    $major = Get-Define 'PLUGIN_MAJOR'
    $minor = Get-Define 'PLUGIN_MINOR'
    $build = Get-Define 'PLUGIN_BUILD'
    $version = "$major.$minor.0"

    if (-not (Test-Path $aex)) { throw "Release .aex not found: $aex" }

    # THE GUARD. A release build must be ONE self-contained file; if an impl DLL
    # exists here, PLUGIN_HOT_RELOAD did not actually go off and the .aex is a
    # stub that would ship broken. Fail loudly rather than zip it.
    if (Test-Path $impl) {
        throw "${plugin}Impl.dll exists in a -Package build. The .aex is a hot-reload stub and MUST NOT ship. Delete $buildDir and retry."
    }

    $stageRoot = Join-Path $root 'dist'
    $stage = Join-Path $stageRoot "$plugin-v$version"
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    Copy-Item $aex -Destination $stage -Force

    # THE DENOISER SHIPS IN THE ZIP. PLAN.md settled this on 2026-09-29: bundle rather
    # than fetch on first run, because the denoiser is ON BY DEFAULT, so every failure
    # mode of fetching lands on nearly every user rather than on a minority who opted
    # in. It is about 53 MB against a 1 MB effect and that is the trade taken knowingly.
    $oidnCopied = Copy-OidnRuntime -Destination $stage
    if ($oidnCopied -gt 0) {
        Write-Host "  bundled $oidnCopied OIDN DLLs" -ForegroundColor DarkGray
    } else {
        Write-Host "  PACKAGING WITHOUT THE DENOISER - the release will render noisy at Draft." -ForegroundColor Yellow
    }

    foreach ($doc in @('README.md', 'INSTALL.md', 'CHANGELOG.md', 'LICENSE')) {
        $p = Join-Path $root $doc
        if (Test-Path $p) { Copy-Item $p -Destination $stage -Force }
        else { Write-Host "  (missing $doc)" -ForegroundColor Yellow }
    }

    $zip = Join-Path $stageRoot "$plugin-v$version-win-x64.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal

    $sha = (Get-FileHash $zip -Algorithm SHA256).Hash
    $sizeKb = [math]::Round((Get-Item $zip).Length / 1KB, 1)

    Write-Host ""
    Write-Host "Packaged v$version (build $build)" -ForegroundColor Green
    Write-Host "  $zip  ($sizeKb KB)" -ForegroundColor Gray
    Write-Host "  SHA256: $sha" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Single self-contained .aex - no impl DLL, no hot-reload stub." -ForegroundColor DarkGray
    Write-Host "Publish the SHA256 alongside the download so users can verify it." -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# The Open Image Denoise runtime
# ---------------------------------------------------------------------------
#
# COPIED BESIDE THE .aex, WHICH IS WHERE src/engine/Denoiser.cpp LOOKS. It resolves the
# directory of its own module -- not of the EXE, which is AfterFX.exe -- so the DLLs
# have to sit next to the plugin and not in AE's own folder.
#
# NOT AN ERROR WHEN THEY ARE ABSENT. The integration is a RUNTIME load with no import
# table entry, so a plugin installed without these loads and renders; it just renders
# undenoised and says so in the diagnostic log. Failing the install here would turn an
# optional dependency back into a required one.
#
# Fetch them with:  cmake -P cmake/FetchOidn.cmake
function Copy-OidnRuntime {
    param([string]$Destination)

    $oidnBin = Join-Path $root 'tools\oidn\bin'
    if (-not (Test-Path $oidnBin)) {
        Write-Host "  no tools\oidn - installing without the denoiser (cmake -P cmake/FetchOidn.cmake)" -ForegroundColor Yellow
        return 0
    }

    $n = 0
    foreach ($dll in (Get-ChildItem -Path $oidnBin -Filter *.dll -ErrorAction SilentlyContinue)) {
        Copy-Item $dll.FullName -Destination $Destination -Force -ErrorAction Stop
        $n++
    }
    return $n
}

if ($Install) {
    if (-not $Hot -and (Get-Process -Name 'AfterFX' -ErrorAction SilentlyContinue)) {
        throw "After Effects is running - the .aex is locked. Close AE and retry, or use -Hot to swap just the impl DLL while AE stays open."
    }

    if (-not $Dest) {
        # Prefer After Effects' OWN Plug-ins\Effects folder over the shared
        # Common\Plug-ins\7.0\MediaCore location:
        #   * MediaCore is shared with Premiere and Media Encoder, which would
        #     then probe an AE-only effect on every launch.
        #   * AE installed outside Program Files is usually writable without
        #     elevation, which MediaCore under Program Files never is.
        #
        # ASK THE INSTALLER, DO NOT GUESS THE PATH.
        #
        # AE is not always on C:, and -- the part that actually bites -- the
        # folder ABOVE it is not always called "Adobe". A real install seen in
        # the wild sits at "F:\Adobe suite\Adobe After Effects 2026", which no
        # pattern built from "<drive>\Adobe" can ever match. The registry knows
        # where it is, on any drive, under any folder name.
        #
        # InstallPath points at "...\Support Files\", so the plug-ins folder is
        # one level below it. UNINSTALLED VERSIONS LEAVE THEIR KEY BEHIND with
        # the value blanked, so an empty InstallPath is skipped rather than
        # joined into a path that looks plausible and does not exist.
        $found = @()
        foreach ($key in @('HKLM:\SOFTWARE\Adobe\After Effects',
                           'HKLM:\SOFTWARE\WOW6432Node\Adobe\After Effects')) {
            if (-not (Test-Path $key)) { continue }
            Get-ChildItem $key -ErrorAction SilentlyContinue | ForEach-Object {
                $installPath = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).InstallPath
                if ($installPath) {
                    $effects = Join-Path $installPath 'Plug-ins\Effects'
                    if (Test-Path $effects) {
                        # Key names are "26.0", "25.0" -- compared as NUMBERS,
                        # not as text, or "9.0" would outrank "26.0".
                        $num = 0.0
                        [void][double]::TryParse($_.PSChildName, [ref]$num)
                        $found += [pscustomobject]@{ Version = $num; Path = $effects }
                    }
                }
            }
        }
        if ($found.Count -gt 0) {
            $Dest = ($found | Sort-Object Version -Descending | Select-Object -First 1).Path
        }

        # Fallback for an install the registry does not describe (a portable
        # copy, a broken uninstall). TWO levels deep per drive, which is what
        # reaches "<drive>\<anything>\Adobe After Effects <year>" without
        # crawling whole volumes.
        if (-not $Dest) {
            $bases = @()
            Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                $bases += $_.Root
                Get-ChildItem $_.Root -Directory -ErrorAction SilentlyContinue |
                    ForEach-Object { $bases += $_.FullName }
            }

            $candidates = @()
            foreach ($b in ($bases | Select-Object -Unique)) {
                Get-ChildItem $b -Directory -Filter 'Adobe After Effects*' -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        $p = Join-Path $_.FullName 'Support Files\Plug-ins\Effects'
                        if (Test-Path $p) { $candidates += $p }
                    }
            }
            $Dest = $candidates | Sort-Object -Descending | Select-Object -First 1
        }

        if ($Dest) {
            Write-Host "After Effects: $Dest" -ForegroundColor DarkGray
        } else {
            $Dest = 'C:\Program Files\Adobe\Common\Plug-ins\7.0\MediaCore'
            Write-Host "No AE install found; falling back to MediaCore (needs elevation)." -ForegroundColor Yellow
        }
    }

    try {
        # Always refresh the impl DLL. The stub loads a shadow copy of it, so
        # the original is never open and can be overwritten with AE running.
        # A release-shape build has no impl DLL at all.
        if (Test-Path $impl) {
            Copy-Item $impl -Destination $Dest -Force -ErrorAction Stop
        } elseif ($Hot) {
            throw "No impl DLL to hot-swap - this looks like a release-shape build. Use a normal build for -Hot."
        }
        if (-not $Hot) {
            Copy-Item $aex -Destination $Dest -Force -ErrorAction Stop

            # NOT ON -Hot. A hot swap replaces only the impl DLL with AE holding the
            # rest open, and OpenImageDenoise_core.dll is 48 MB that AE may well have
            # loaded and locked. Nothing about a render-code change needs them
            # refreshed.
            $oidnCopied = Copy-OidnRuntime -Destination $Dest
            if ($oidnCopied -gt 0) {
                Write-Host "  installed $oidnCopied OIDN DLLs" -ForegroundColor DarkGray
            }
        }

        if ($Hot) {
            Write-Host "Hot-swapped impl DLL -> $Dest" -ForegroundColor Green
            Write-Host "Nudge the frame in AE (move the time indicator or touch a param) to pick it up." -ForegroundColor DarkGray
            Write-Host "Parameter list, out_flags, effect name and PLUGIN_BUILD changes still need a full restart." -ForegroundColor DarkGray
            Write-Host "A hot-swapped PLUGIN_BUILD bump reports 'version mismatch ... (8001d)' - AE caches registration against the .aex, which -Hot does not replace." -ForegroundColor DarkGray
        } else {
            Write-Host "Installed to $Dest" -ForegroundColor Green
        }
    } catch {
        throw "Copy to '$Dest' failed. If it is under Program Files, use an elevated shell. Error: $_"
    }
}
