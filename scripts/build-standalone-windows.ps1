# Rebuild stubs -> stubbin -> single Windows server exe (-tags=stubembed, optional donutembed).
# Run from repo root: .\scripts\build-standalone-windows.ps1
# Deploy: place c2-server-standalone.exe next to config.yaml (no data/stubs needed when stubembed).

$ErrorActionPreference = "Stop"
$scriptParent = Split-Path -Parent $PSScriptRoot
$here = (Get-Location).Path
if (Test-Path (Join-Path $here "go.mod")) {
    $root = $here
} elseif (Test-Path (Join-Path $scriptParent "go.mod")) {
    $root = $scriptParent
} else {
    $root = $here
}
Set-Location $root

& (Join-Path $PSScriptRoot "build-stub-templates.ps1")

$tagList = @("stubembed")
$donutDest = Join-Path $root "internal\renut\donutbin\donut.exe"
$donutBinDir = Split-Path $donutDest -Parent
$candidates = @(
    (Join-Path $root "..\donut-master\donut.exe"),
    (Join-Path $root "donut-master\donut.exe"),
    (Join-Path $root "data\renut\donut.exe")
)
$donutSrc = $null
foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) {
        $donutSrc = $c
        break
    }
}
if ($donutSrc) {
    if (-not (Test-Path $donutBinDir)) {
        New-Item -ItemType Directory -Path $donutBinDir | Out-Null
    }
    Copy-Item -LiteralPath $donutSrc -Destination $donutDest -Force
    $tagList += "donutembed"
    Write-Host "Donut copied to $donutDest" -ForegroundColor Green
} else {
    Write-Warning "donut.exe not found: EXE/ELF payloads OK; Windows shellcode needs external donut or re-run after placing donut.exe in internal\renut\donutbin\"
}

$tags = $tagList -join ","
$out = Join-Path $root "c2-server-standalone.exe"
Remove-Item Env:GOOS -ErrorAction SilentlyContinue
Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
go build -tags=$tags -trimpath -ldflags "-s -w" -o $out ./cmd/server
Write-Host "Built $out with -tags=$tags" -ForegroundColor Green
