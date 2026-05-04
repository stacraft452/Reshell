# Build premade/windows_amd64_sc_e1.bin from data/stubs/windows_x64.exe using Donut -e1 (for Linux-hosted server shellcode gen).
# Run on Windows from repo root: .\scripts\gen-premade-windows-shellcode.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$donut = Join-Path $root "internal\renut\donutbin\donut.exe"
if (-not (Test-Path -LiteralPath $donut)) {
    $cands = @(
        (Join-Path $root "..\donut-master\donut.exe"),
        (Join-Path $root "donut-master\donut.exe"),
        (Join-Path $root "data\renut\donut.exe")
    )
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath $c) {
            $donut = $c
            break
        }
    }
}
if (-not (Test-Path -LiteralPath $donut)) {
    throw "Donut not found. Copy donut.exe to internal\renut\donutbin\ or place under donut-master\."
}

$pe = Join-Path $root "data\stubs\windows_x64.exe"
if (-not (Test-Path -LiteralPath $pe)) {
    & (Join-Path $PSScriptRoot "build-stub-templates.ps1")
}

$outDir = Join-Path $root "internal\payload\premade"
$out = Join-Path $outDir "windows_amd64_sc_e1.bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Donut: $donut" -ForegroundColor Cyan
Write-Host "IN:  $pe" -ForegroundColor Cyan
Write-Host "OUT: $out" -ForegroundColor Cyan
& $donut -i $pe -o $out -a 2 -e 1
if ($LASTEXITCODE -ne 0) { throw "donut failed" }

go test -count=1 ./internal/payload -run TestPremadeWindowsSCE1ContainsPatchableC2Embed
Write-Host "OK. Rebuild server: go build ./cmd/server" -ForegroundColor Green
