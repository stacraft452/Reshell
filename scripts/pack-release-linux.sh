#!/usr/bin/env bash
# Linux 本机打包：dist/c2-linux-amd64/c2-server + config.yaml
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
NO_STUBS=0
for a in "$@"; do
  if [[ "$a" == "--no-stubs" ]]; then NO_STUBS=1; fi
done
if [[ "$NO_STUBS" -eq 0 ]]; then
  bash "$(dirname "$0")/build-stub-templates.sh"
fi
OUT="$ROOT/dist/c2-linux-amd64"
rm -rf "$OUT"
mkdir -p "$OUT"
TAGS="stubembed"
DONUT="$ROOT/internal/renut/donutbin/donut"
if [[ -f "$DONUT" ]]; then
  magic=$(head -c4 "$DONUT" | od -An -tx1 | tr -d '[:space:]')
  if [[ "$magic" == 7f454c46* ]]; then
    TAGS="stubembed,donutembed"
    echo "Using donutembed (ELF donut)"
  fi
fi
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -tags="$TAGS" -trimpath -ldflags '-s -w' -o "$OUT/c2-server" ./cmd/server
cp -f "$ROOT/config.yaml" "$OUT/config.yaml"
cat > "$OUT/README_DEPLOY.txt" <<'EOF'
chmod +x ./c2-server
./c2-server
config.yaml must stay beside the binary. Edit auth and server.addr for production.
EOF
echo "Release: $OUT"
ls -la "$OUT"
