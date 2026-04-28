#!/usr/bin/env bash

set -euo pipefail

REQUIRED_TOOLS=(
  docker
  python3
  node
  npm
)

OPTIONAL_TOOLS=(
  codex
  claude
)

missing_required=()

echo "Checking required tools..."

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "[OK] $tool"
  else
    echo "[MISSING] $tool"
    missing_required+=("$tool")
  fi
done

if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose"
else
  echo "[MISSING] docker compose"
  missing_required+=("docker compose")
fi

echo "Checking optional AI CLIs..."

for tool in "${OPTIONAL_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "[OK] $tool"
  else
    echo "[OPTIONAL] $tool not found"
  fi
done

if [[ ${#missing_required[@]} -gt 0 ]]; then
  echo "Missing required tools: ${missing_required[*]}" >&2
  exit 1
fi

echo "Prerequisite check passed."
