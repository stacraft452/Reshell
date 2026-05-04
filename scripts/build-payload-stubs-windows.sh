#!/usr/bin/env bash
# 仅 Windows x64 载荷模板（需 MinGW-w64）；不刷新预置壳代码（请在 Windows 上跑 gen-premade-windows-shellcode.ps1）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUBS="$ROOT/data/stubs"
STUBBIN="$ROOT/internal/payload/stubbin"
mkdir -p "$STUBS" "$STUBBIN"
if ! command -v x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
  echo "x86_64-w64-mingw32-g++ not found. Install mingw-w64 or build windows_x64.exe on Windows (build-payload-stubs-windows.ps1)." >&2
  exit 1
fi
echo "Building $STUBS/windows_x64.exe ..."
x86_64-w64-mingw32-g++ -O2 -s -static -o "$STUBS/windows_x64.exe" \
  -I"$ROOT/client/native" "$ROOT/client/native/client.cpp" \
  -lws2_32 -lgdi32 -lgdiplus -lbcrypt -liphlpapi -lpsapi -lshell32 -lole32 -luuid -lshlwapi
cp -f "$STUBS/windows_x64.exe" "$STUBBIN/windows_x64.exe"
echo "windows_x64.exe OK -> stubbin"
