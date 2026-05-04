# 打包 Windows 服务端发布目录：dist/c2-windows-amd64/c2-server.exe + config.yaml（内嵌 stub，可选内嵌 Donut）
# 在仓库根目录：.\scripts\pack-release-windows.ps1
# 可选：-NoStubs 跳过重建 stub（stubbin 已最新时）

param([switch]$NoStubs)

$ErrorActionPreference = "Stop"
$scriptParent = Split-Path -Parent $PSScriptRoot
$here = (Get-Location).Path
if (Test-Path (Join-Path $here "go.mod")) { $root = $here }
elseif (Test-Path (Join-Path $scriptParent "go.mod")) { $root = $scriptParent }
else { $root = $here }
Set-Location $root

if (-not $NoStubs) {
    & (Join-Path $PSScriptRoot "build-stub-templates.ps1")
}

$tags = @("stubembed")
$donutExe = Join-Path $root "internal\renut\donutbin\donut.exe"
if (Test-Path -LiteralPath $donutExe) {
    $tags += "donutembed"
    Write-Host "Using donutembed (donut.exe present)" -ForegroundColor Green
} else {
    Write-Warning "No internal\renut\donutbin\donut.exe -> build without donutembed (Windows shellcode gen needs external donut or rebuild with donut)."
}

$outDir = Join-Path $root "dist\c2-windows-amd64"
Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $outDir | Out-Null

$exeOut = Join-Path $outDir "c2-server.exe"
Remove-Item Env:GOOS -ErrorAction SilentlyContinue
Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue

$tagStr = $tags -join ","
go build "-tags=$tagStr" -trimpath -ldflags "-s -w" -o $exeOut ./cmd/server
if ($LASTEXITCODE -ne 0) { throw "go build failed" }

Copy-Item -LiteralPath (Join-Path $root "config.yaml") -Destination (Join-Path $outDir "config.yaml") -Force
@"
Start from this folder (exe and config.yaml must stay together):
  .\c2-server.exe

Then open the URL in config.yaml (server.addr), login with auth.login_password.
"@ | Set-Content -Encoding UTF8 (Join-Path $outDir "README_DEPLOY.txt")

Write-Host "Release: $outDir" -ForegroundColor Green
Get-ChildItem $outDir | Format-Table Name, Length -AutoSize
