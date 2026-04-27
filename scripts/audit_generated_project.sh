#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/audit_generated_project.sh generated/<project-slug>

This script performs a lightweight template-level audit for a generated project:
1. Required top-level files and directories exist
2. OpenSpec files exist
3. Requirement/doc/script snapshots and the business actions checklist exist
4. Backend/frontend core entry files exist
5. .env.example contains required environment keys
6. README contains required verification command references
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

PROJECT_DIR="$1"

if [[ "$PROJECT_DIR" == "-h" || "$PROJECT_DIR" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

assert_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
}

assert_grep() {
  local pattern="$1"
  local path="$2"
  if ! grep -q "$pattern" "$path"; then
    echo "Missing expected content '$pattern' in $path" >&2
    exit 1
  fi
}

echo "Auditing generated project structure in $PROJECT_DIR"

for path in \
  "$PROJECT_DIR/README.md" \
  "$PROJECT_DIR/.gitignore" \
  "$PROJECT_DIR/.env.example" \
  "$PROJECT_DIR/compose.yaml" \
  "$PROJECT_DIR/requirements" \
  "$PROJECT_DIR/docs" \
  "$PROJECT_DIR/scripts" \
  "$PROJECT_DIR/openspec" \
  "$PROJECT_DIR/backend" \
  "$PROJECT_DIR/frontend"; do
  assert_path "$path"
done

for path in \
  "$PROJECT_DIR/openspec/project.md" \
  "$PROJECT_DIR/openspec/changes/proposal.md" \
  "$PROJECT_DIR/openspec/changes/tasks.md" \
  "$PROJECT_DIR/requirements/requirement.md" \
  "$PROJECT_DIR/docs/architecture.md" \
  "$PROJECT_DIR/docs/development.md" \
  "$PROJECT_DIR/docs/key-business-actions-checklist.md"; do
  assert_path "$path"
done

for path in \
  "$PROJECT_DIR/backend/pyproject.toml" \
  "$PROJECT_DIR/backend/alembic.ini" \
  "$PROJECT_DIR/backend/app/main.py" \
  "$PROJECT_DIR/frontend/package.json" \
  "$PROJECT_DIR/frontend/vite.config.ts" \
  "$PROJECT_DIR/frontend/src/App.tsx" \
  "$PROJECT_DIR/frontend/src/main.tsx"; do
  assert_path "$path"
done

assert_grep "JWT_SECRET_KEY" "$PROJECT_DIR/.env.example"
assert_grep "DATABASE_URL" "$PROJECT_DIR/.env.example"
assert_grep "REDIS_URL" "$PROJECT_DIR/.env.example"
assert_grep "VITE_API_BASE_URL" "$PROJECT_DIR/.env.example"

assert_grep "docker compose" "$PROJECT_DIR/README.md"
assert_grep "pytest" "$PROJECT_DIR/README.md"
assert_grep "ruff check" "$PROJECT_DIR/README.md"
assert_grep "npm run build" "$PROJECT_DIR/README.md"
assert_grep "npm run lint" "$PROJECT_DIR/README.md"

echo "Template-level audit passed for $PROJECT_DIR"
