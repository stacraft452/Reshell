# 打包 Linux amd64 服务端发布目录：dist/c2-linux-amd64/c2-server + config.yaml（内嵌 stub；不内嵌 Donut，除非已放置 ELF donut）
# 在仓库根目录（通常在 Windows 上交叉编译）：.\scripts\pack-release-linux.ps1
# 可选：-NoStubs 跳过重建 stub

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
$donutElf = Join-Path $root "internal\renut\donutbin\donut"
if (Test-Path -LiteralPath $donutElf) {
    $b = [System.IO.File]::ReadAllBytes($donutElf)
    if ($b.Length -ge 4 -and $b[0] -eq 0x7F -and $b[1] -eq 0x45 -and $b[2] -eq 0x4C -and $b[3] -eq 0x46) {
        $tags += "donutembed"
        Write-Host "Using donutembed (Linux ELF donut present)" -ForegroundColor Green
    }
}

$outDir = Join-Path $root "dist\c2-linux-amd64"
Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $outDir | Out-Null

$binOut = Join-Path $outDir "c2-server"
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"
try {
    $tagStr = $tags -join ","
    go build "-tags=$tagStr" -trimpath -ldflags "-s -w" -o $binOut ./cmd/server
    if ($LASTEXITCODE -ne 0) { throw "go build failed" }
} finally {
    Remove-Item Env:GOOS -ErrorAction SilentlyContinue
    Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
    Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue
}

Copy-Item -LiteralPath (Join-Path $root "config.yaml") -Destination (Join-Path $outDir "config.yaml") -Force
@"
Put this directory on Linux, then:
  chmod +x ./c2-server
  ./c2-server

config.yaml must stay in the same directory. Edit auth and server.addr before production.
"@ | Set-Content -Encoding UTF8 (Join-Path $outDir "README_DEPLOY.txt")

Write-Host "Release: $outDir" -ForegroundColor Green
Get-ChildItem $outDir | Format-Table Name, Length -AutoSize
