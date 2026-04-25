#!/usr/bin/env bash

set -euo pipefail

TOOLS=(
  docker
  python3
  node
  npm
)

echo "Checking required tools..."

for tool in "${TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "[OK] $tool"
  else
    echo "[MISSING] $tool"
  fi
done

if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose"
else
  echo "[MISSING] docker compose"
fi
