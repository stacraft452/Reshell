# 将 Donut 打入服务端二进制（单 exe + config.yaml 部署）
# 用法：在仓库根目录
#   .\scripts\build-server-embed-donut.ps1
#   .\scripts\build-server-embed-donut.ps1 -DonutExe C:\path\to\donut.exe

param(
    [string]$DonutExe = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $root "go.mod"))) {
    Write-Error "请在包含 go.mod 的仓库根目录下运行（scripts 的上级目录）。"
}
Set-Location $root

$dest = Join-Path $root "internal\renut\donutbin\donut.exe"
$donutbin = Split-Path $dest -Parent
if (-not (Test-Path $donutbin)) { New-Item -ItemType Directory -Path $donutbin | Out-Null }

if ($DonutExe -eq "") {
    $candidates = @(
        (Join-Path $root "..\donut-master\donut.exe"),
        (Join-Path $root "donut-master\donut.exe"),
        (Join-Path $root "data\renut\donut.exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $DonutExe = $c; break }
    }
}

if ([string]::IsNullOrWhiteSpace($DonutExe) -or -not (Test-Path -LiteralPath $DonutExe)) {
    Write-Error "未找到 donut.exe。请指定 -DonutExe 完整路径，或将其放到仓库内 donut-master\、data\renut\、上级目录 donut-master\ 等路径后再运行。"
}

Copy-Item -LiteralPath $DonutExe -Destination $dest -Force
Write-Host "已复制 -> $dest" -ForegroundColor Green
go build -tags=donutembed -o c2-server.exe ./cmd/server
Write-Host "输出: $(Join-Path $root 'c2-server.exe')" -ForegroundColor Green
