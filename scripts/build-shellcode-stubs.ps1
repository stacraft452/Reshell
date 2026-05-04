# 【可选 / 旧流程】预生成 shellcode_*.bin 放入 data/stubs/
# 当前服务端已集成 renut：format=shellcode 时从 windows_x64.exe / linux_amd64.elf 修补后再调用 Donut（-e3），
# 一般不再需要本脚本。仅在你仍想手工维护独立 .bin 模板时使用。
#
# 用法：在仓库根目录执行 .\scripts\build-shellcode-stubs.ps1
# 依赖：已构建的 windows_x64.exe / linux_amd64.elf（可先运行 build-stub-templates.ps1）

$ErrorActionPreference = "Stop"
$here = (Get-Location).Path
if (-not (Test-Path (Join-Path $here "go.mod"))) {
    $here = Split-Path -Parent $PSScriptRoot
}
$stubs = Join-Path $here "data\stubs"
New-Item -ItemType Directory -Force -Path $stubs | Out-Null
$userProfile = [Environment]::GetFolderPath("UserProfile")
if ([string]::IsNullOrEmpty($userProfile)) { $userProfile = $env:USERPROFILE }

$donut = $env:DONUT_EXE
if (-not $donut -or -not (Test-Path -LiteralPath $donut)) {
    $candidates = @(
        (Join-Path $here "data\renut\donut.exe"),
        (Join-Path (Split-Path $here -Parent) "donut-master\donut.exe")
    )
    if (-not [string]::IsNullOrEmpty($userProfile)) {
        $candidates += (Join-Path $userProfile "Downloads\411e5-main\donut-master\donut.exe")
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { $donut = $c; break }
    }
}
if (-not $donut -or -not (Test-Path -LiteralPath $donut)) {
    throw "未找到 donut.exe，请放入 data\renut\donut.exe、设置 DONUT_EXE，或与仓库同级的 donut-master\donut.exe"
}

$w64 = Join-Path $stubs "windows_x64.exe"
$elf = Join-Path $stubs "linux_amd64.elf"
if (-not (Test-Path $w64)) { throw "缺少 $w64，请先运行 scripts\build-stub-templates.ps1" }
if (-not (Test-Path $elf)) { throw "缺少 $elf，请先运行 scripts\build-stub-templates.ps1" }

$out64 = Join-Path $stubs "shellcode_windows_x64.bin"
$outL  = Join-Path $stubs "shellcode_linux_amd64.bin"

Write-Host "Donut x64 -> $out64 (-e1 -z1) ..."
& $donut -e 1 -z 1 -a 2 -o $out64 -i $w64
if ($LASTEXITCODE -ne 0) { throw "donut x64 failed" }

Write-Host "Copy ELF -> $outL"
Copy-Item -Force $elf $outL
Write-Host "Done."
