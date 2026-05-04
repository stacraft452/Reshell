# Stubs + premade shellcode + sample payloads for pushing a consistent tree to GitHub.
# Run from repo root: .\scripts\prep-for-github.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> build-stub-templates" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "build-stub-templates.ps1")

Write-Host "==> gen-premade-windows-shellcode" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "gen-premade-windows-shellcode.ps1")

$art = Join-Path $root "artifacts\payload-samples"
New-Item -ItemType Directory -Force -Path $art | Out-Null
Get-ChildItem -LiteralPath $art -File -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "==> sample payloads -> $art" -ForegroundColor Cyan
$env:C2_GEN_PAYLOAD_OUT_DIR = $art
try {
    go run ./cmd/gen-sample-payloads/
} finally {
    Remove-Item Env:C2_GEN_PAYLOAD_OUT_DIR -ErrorAction SilentlyContinue
}

Write-Host "Done. Review artifacts/payload-samples and git add as needed." -ForegroundColor Green
