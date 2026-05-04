#!/usr/bin/env bash
# 全部载荷模板：先 Linux 再 Windows（若本机有 MinGW）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
bash "$HERE/build-payload-stubs-linux.sh"
if command -v x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
  bash "$HERE/build-payload-stubs-windows.sh"
else
  echo "Skip Windows stub: no x86_64-w64-mingw32-g++ (build on Windows or install mingw-w64)."
fi
echo "Done. Optional: cd .. && go build -tags=stubembed ./..."
