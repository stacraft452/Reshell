# Build Linux amd64 server with -tags=stubembed,donutembed (embedded Linux Donut ELF).
# Run from repo root: .\scripts\build-server-linux-embed.ps1
# Optional: -LinuxDonutPath C:\path\to\donut   (skip WSL build if you already have ELF)
# Requires: Go; stub templates via build-stub-templates.ps1; for auto Donut either WSL+gcc+make, or -LinuxDonutPath.

param(
    [string]$LinuxDonutPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $scriptParent = Split-Path -Parent $PSScriptRoot
    $here = (Get-Location).Path
    if (Test-Path (Join-Path $here "go.mod")) { return $here }
    if (Test-Path (Join-Path $scriptParent "go.mod")) { return $scriptParent }
    return $here
}

function Convert-ToWslPath([string]$WinPath) {
    if ([string]::IsNullOrWhiteSpace($WinPath)) { return $null }
    $full = [System.IO.Path]::GetFullPath($WinPath)
    $full = $full.Replace('\', '/')
    if ($full -match '^([A-Za-z]):') {
        $d = $Matches[1].ToLowerInvariant()
        return "/mnt/$d" + $full.Substring(2)
    }
    return $full
}

function Test-ElfMagic([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $b = New-Object byte[] 4
        if ($fs.Read($b, 0, 4) -lt 4) { return $false }
        return ($b[0] -eq 0x7f -and $b[1] -eq 0x45 -and $b[2] -eq 0x4c -and $b[3] -eq 0x46)
    } finally {
        $fs.Close()
    }
}

$root = Resolve-RepoRoot
Set-Location $root

& (Join-Path $PSScriptRoot "build-stub-templates.ps1")

$donutBinDir = Join-Path $root "internal\renut\donutbin"
$donutLinuxOut = Join-Path $donutBinDir "donut"
if (-not (Test-Path $donutBinDir)) {
    New-Item -ItemType Directory -Path $donutBinDir | Out-Null
}

$haveDonut = $false
if (-not [string]::IsNullOrWhiteSpace($LinuxDonutPath)) {
    if (-not (Test-Path -LiteralPath $LinuxDonutPath)) {
        throw "LinuxDonutPath not found: $LinuxDonutPath"
    }
    Copy-Item -LiteralPath $LinuxDonutPath -Destination $donutLinuxOut -Force
    $haveDonut = $true
    Write-Host "Using -LinuxDonutPath -> $donutLinuxOut" -ForegroundColor Green
}

if (-not $haveDonut -and (Test-Path -LiteralPath $donutLinuxOut) -and (Test-ElfMagic $donutLinuxOut)) {
    Write-Host "Reusing existing ELF: $donutLinuxOut" -ForegroundColor Green
    $haveDonut = $true
}

if (-not $haveDonut) {
    $donutMaster = [System.IO.Path]::GetFullPath((Join-Path $root "..\donut-master"))
    if (-not (Test-Path (Join-Path $donutMaster "Makefile"))) {
        $donutMaster = [System.IO.Path]::GetFullPath((Join-Path $root "donut-master"))
    }
    if (-not (Test-Path (Join-Path $donutMaster "Makefile"))) {
        throw "No Linux donut and no donut-master next to repo. Place Linux ELF at internal\renut\donutbin\donut or pass -LinuxDonutPath, or clone donut next to Reshell-C2-main for WSL build."
    }

    $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $wsl) {
        throw "wsl.exe not found. Install WSL2 + Ubuntu, or build Donut on Linux and copy ELF to internal\renut\donutbin\donut, then re-run with -LinuxDonutPath."
    }

    $probe = Start-Process -FilePath $wsl.Source -ArgumentList @('bash','-lc','echo wsl_ok') -Wait -PassThru -NoNewWindow
    if ($probe.ExitCode -ne 0) {
        throw "WSL is not usable (exit $($probe.ExitCode)). Run: wsl --install  then reboot, or pass -LinuxDonutPath to a Linux amd64 Donut ELF."
    }

    $wslDm = Convert-ToWslPath $donutMaster
    $wslOut = Convert-ToWslPath $donutLinuxOut
    Write-Host "Building Donut in WSL under: $donutMaster" -ForegroundColor Cyan
    $inner = "set -e; cd '$wslDm'; command -v make >/dev/null || { echo 'make missing in WSL'; exit 1; }; command -v gcc >/dev/null || { echo 'gcc missing in WSL (sudo apt install build-essential)'; exit 1; }; make clean 2>/dev/null || true; make; test -f donut; cp -f donut '$wslOut'; chmod +x '$wslOut'"
    $p = Start-Process -FilePath $wsl.Source -ArgumentList @('bash','-lc', $inner) -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        if (Test-Path -LiteralPath $donutLinuxOut) { Remove-Item -LiteralPath $donutLinuxOut -Force -ErrorAction SilentlyContinue }
        throw "WSL Donut build failed (exit $($p.ExitCode)). Fix gcc/make in WSL or use -LinuxDonutPath."
    }
    if (-not (Test-ElfMagic $donutLinuxOut)) {
        throw "After WSL build, $donutLinuxOut is not a valid ELF."
    }
    Write-Host "WSL built Donut -> $donutLinuxOut" -ForegroundColor Green
}

$out = Join-Path $root "c2-server-linux-amd64"
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"
try {
    go build "-tags=stubembed,donutembed" -trimpath -ldflags "-s -w" -o $out ./cmd/server
} finally {
    Remove-Item Env:GOOS -ErrorAction SilentlyContinue
    Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
    Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue
}

Write-Host "Built $out with -tags=stubembed,donutembed" -ForegroundColor Green
