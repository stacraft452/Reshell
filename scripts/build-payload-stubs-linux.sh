#!/usr/bin/env bash
# 仅 Linux amd64 载荷模板（与 build-payload-stubs-linux.ps1 一致）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUBS="$ROOT/data/stubs"
STUBBIN="$ROOT/internal/payload/stubbin"
mkdir -p "$STUBS" "$STUBBIN"
echo "Building $STUBS/linux_amd64.elf ..."
( cd "$ROOT" && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o "$STUBS/linux_amd64.elf" ./cmd/linuxagent )
cp -f "$STUBS/linux_amd64.elf" "$STUBBIN/linux_amd64.elf"
echo "linux_amd64.elf OK -> stubbin"
