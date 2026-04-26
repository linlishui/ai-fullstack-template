#!/usr/bin/env bash

set -euo pipefail

echo "Cleaning generated artifacts..."

rm -rf generated/*

touch generated/.gitkeep

echo "Kept requirements/, prompts/, docs/ and scripts/ intact."
