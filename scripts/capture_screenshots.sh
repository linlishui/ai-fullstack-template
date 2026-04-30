#!/usr/bin/env bash

# capture_screenshots.sh — Automated frontend screenshot capture for generated projects.
#
# Uses Playwright to visit frontend pages and save screenshots to doc/screenshots/.
# Designed as a template-level tool: works with any generated project.
#
# Usage:
#   ./scripts/capture_screenshots.sh <project-dir> [--base-url URL] [--force]
#
# Options:
#   --base-url URL   Frontend base URL (default: http://localhost)
#   --force          Overwrite existing screenshots

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYWRIGHT_DIR="$SCRIPT_DIR/playwright"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage:
  ./scripts/capture_screenshots.sh <project-dir> [--base-url URL] [--force]

Captures frontend page screenshots using Playwright and saves them to
<project-dir>/doc/screenshots/.

Options:
  --base-url URL   Frontend base URL (default: http://localhost)
  --force          Overwrite existing screenshots (default: skip if ≥3 exist)

Prerequisites:
  - node and npm must be installed
  - Services should be running (docker compose up)
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

PROJECT_DIR="$1"
shift

BASE_URL="http://localhost"
FORCE_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url)
      BASE_URL="${2:-}"
      shift 2
      ;;
    --force)
      FORCE_FLAG="--force"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [[ ! -d "$PROJECT_DIR/frontend/src" ]]; then
  echo "ERROR: No frontend/src/ directory in $PROJECT_DIR" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node is not installed" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm is not installed" >&2
  exit 1
fi

# Convert project dir to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# ---------------------------------------------------------------------------
# Check existing screenshots (skip if already sufficient)
# ---------------------------------------------------------------------------

SCREENSHOT_DIR="$PROJECT_DIR/doc/screenshots"

if [[ -z "$FORCE_FLAG" && -d "$SCREENSHOT_DIR" ]]; then
  existing_count=$(find "$SCREENSHOT_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$existing_count" -ge 3 ]]; then
    echo "Screenshots already present ($existing_count files). Use --force to overwrite."
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Install dependencies
# ---------------------------------------------------------------------------

echo "Setting up Playwright dependencies..."

if [[ ! -d "$PLAYWRIGHT_DIR/node_modules" ]]; then
  echo "  Installing npm packages..."
  (cd "$PLAYWRIGHT_DIR" && npm install --silent 2>&1) || {
    echo "ERROR: npm install failed in $PLAYWRIGHT_DIR" >&2
    exit 1
  }
fi

# Install Chromium browser if not present
echo "  Ensuring Chromium is available..."
(cd "$PLAYWRIGHT_DIR" && npx playwright install chromium 2>&1) || {
  echo "ERROR: Failed to install Playwright Chromium browser" >&2
  echo "  Try running: cd $PLAYWRIGHT_DIR && npx playwright install --with-deps chromium" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Run screenshot capture
# ---------------------------------------------------------------------------

echo ""
echo "Capturing screenshots for $PROJECT_DIR"
echo "  Base URL: $BASE_URL"
echo ""

node "$PLAYWRIGHT_DIR/capture.mjs" \
  --project-dir "$PROJECT_DIR" \
  --base-url "$BASE_URL" \
  $FORCE_FLAG

capture_exit=$?

# ---------------------------------------------------------------------------
# Post-capture check
# ---------------------------------------------------------------------------

if [[ -d "$SCREENSHOT_DIR" ]]; then
  final_count=$(find "$SCREENSHOT_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "Screenshot capture complete: $final_count file(s) in doc/screenshots/"
  if [[ "$final_count" -lt 3 ]]; then
    echo "WARNING: Only $final_count screenshot(s) captured. Audit requires at least 3."
  fi
else
  echo "WARNING: doc/screenshots/ directory was not created."
fi

exit $capture_exit
