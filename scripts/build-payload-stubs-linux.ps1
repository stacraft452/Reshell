# 仅构建 Linux amd64 载荷模板：data/stubs/linux_amd64.elf -> stubbin（Go 交叉编 linuxagent）。
# 仓库根目录：.\scripts\build-payload-stubs-linux.ps1

$ErrorActionPreference = "Stop"
$scriptParent = Split-Path -Parent $PSScriptRoot
$here = (Get-Location).Path
if (Test-Path (Join-Path $here "go.mod")) { $root = $here }
elseif (Test-Path (Join-Path $scriptParent "go.mod")) { $root = $scriptParent }
else { $root = $here }
Set-Location $root

$stubs = Join-Path $root "data\stubs"
$stubbin = Join-Path $root "internal\payload\stubbin"
New-Item -ItemType Directory -Force -Path $stubs, $stubbin | Out-Null

$elfOut = Join-Path $stubs "linux_amd64.elf"
Write-Host "Building $elfOut (GOOS=linux GOARCH=amd64 CGO_ENABLED=0) ..."
Push-Location $root
try {
    $savedGOOS = $env:GOOS
    $savedGOARCH = $env:GOARCH
    $savedCGO = $env:CGO_ENABLED
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    $env:CGO_ENABLED = "0"
    go build -trimpath -ldflags "-s -w" -o $elfOut .\cmd\linuxagent
    if ($LASTEXITCODE -ne 0) { throw "linux_amd64.elf go build failed" }
} finally {
    $env:GOOS = $savedGOOS
    $env:GOARCH = $savedGOARCH
    $env:CGO_ENABLED = $savedCGO
    Pop-Location
}
Copy-Item -Force $elfOut (Join-Path $stubbin "linux_amd64.elf")
Write-Host "linux_amd64.elf OK -> stubbin" -ForegroundColor Green
