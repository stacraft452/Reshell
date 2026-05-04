# 仅构建 Windows 载荷模板：data/stubs/windows_x64.exe -> stubbin；可选刷新 Donut -e1 预置壳代码（需 donut.exe）。
# 仓库根目录：.\scripts\build-payload-stubs-windows.ps1

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

$winSrc = Join-Path $root "client\native\client.cpp"
$inc = Join-Path $root "client\native"
$out64 = Join-Path $stubs "windows_x64.exe"
if (-not (Test-Path -LiteralPath $winSrc)) {
    throw "Missing $winSrc"
}
Write-Host "Building $out64 ..."
& g++ -O2 -s -static -o $out64 $winSrc "-I$inc" `
  -lws2_32 -lgdi32 -lgdiplus -lbcrypt -liphlpapi -lpsapi -lshell32 -lole32 -luuid -lshlwapi -ladvapi32 -luser32
if ($LASTEXITCODE -ne 0) { throw "windows_x64 build failed" }
Copy-Item -Force $out64 (Join-Path $stubbin "windows_x64.exe")
Write-Host "windows_x64.exe OK -> stubbin" -ForegroundColor Green

$donut = Join-Path $root "internal\renut\donutbin\donut.exe"
if (Test-Path -LiteralPath $donut) {
    & (Join-Path $PSScriptRoot "gen-premade-windows-shellcode.ps1")
} else {
    Write-Warning "Skip premade shellcode: no internal\renut\donutbin\donut.exe"
}
