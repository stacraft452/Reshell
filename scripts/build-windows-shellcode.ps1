# Windows 壳代码由服务端在生成载荷时调用 Donut（见 data/renut/README.txt）。
# 旧脚本 build-shellcode-stubs.ps1 仅用于手工预生成模板，通常可忽略。
Write-Host "请将 donut.exe 放到 data/renut/，在 Web 载荷生成中选择「壳代码」。" -ForegroundColor Yellow
exit 1
