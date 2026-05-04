# 在本机构建全部载荷模板：Windows + Linux（分别调用独立脚本）
# 请在仓库根目录执行：.\scripts\build-stub-templates.ps1
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $here "build-payload-stubs-windows.ps1")
& (Join-Path $here "build-payload-stubs-linux.ps1")

Write-Host "Done. Optional: go build -tags=stubembed"
