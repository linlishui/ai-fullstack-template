#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/audit_generated_project.sh generated/<project-slug>

This script performs a lightweight template-level audit for a generated project:
1. Required top-level files and directories exist
2. OpenSpec project/spec/change files exist
3. Requirement/doc/script snapshots and the review-oriented checklists exist
4. Backend/frontend core entry files and production support assets exist
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

assert_any_path() {
  local description="$1"
  shift

  for path in "$@"; do
    if [[ -e "$path" ]]; then
      return
    fi
  done

  echo "Missing required path for ${description}: $*" >&2
  exit 1
}

assert_glob_exists() {
  local description="$1"
  local pattern="$2"
  shopt -s nullglob
  local matches=($pattern)
  shopt -u nullglob

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "Missing required ${description}: ${pattern}" >&2
    exit 1
  fi
}

echo "Auditing generated project structure in $PROJECT_DIR"

for path in \
  "$PROJECT_DIR/README.md" \
  "$PROJECT_DIR/AGENTS.md" \
  "$PROJECT_DIR/CLAUDE.md" \
  "$PROJECT_DIR/.gitignore" \
  "$PROJECT_DIR/.env.example" \
  "$PROJECT_DIR/compose.yaml" \
  "$PROJECT_DIR/requirements" \
  "$PROJECT_DIR/docs" \
  "$PROJECT_DIR/scripts" \
  "$PROJECT_DIR/openspec" \
  "$PROJECT_DIR/backend" \
  "$PROJECT_DIR/frontend" \
  "$PROJECT_DIR/infra/nginx" \
  "$PROJECT_DIR/.github/workflows"; do
  assert_path "$path"
done

for path in \
  "$PROJECT_DIR/openspec/project.md" \
  "$PROJECT_DIR/requirements/requirement.md" \
  "$PROJECT_DIR/docs/architecture.md" \
  "$PROJECT_DIR/docs/development.md" \
  "$PROJECT_DIR/docs/ai-workflow.md" \
  "$PROJECT_DIR/docs/review-log.md" \
  "$PROJECT_DIR/docs/fix-log.md" \
  "$PROJECT_DIR/docs/key-business-actions-checklist.md" \
  "$PROJECT_DIR/docs/frontend-ui-checklist.md" \
  "$PROJECT_DIR/docs/production-readiness-checklist.md"; do
  assert_path "$path"
done

assert_glob_exists "OpenSpec capability spec" "$PROJECT_DIR/openspec/specs/*/spec.md"
assert_glob_exists "OpenSpec proposal" "$PROJECT_DIR/openspec/changes/*/proposal.md"
assert_glob_exists "OpenSpec design" "$PROJECT_DIR/openspec/changes/*/design.md"
assert_glob_exists "OpenSpec tasks" "$PROJECT_DIR/openspec/changes/*/tasks.md"

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

assert_any_path "backend versioned api" \
  "$PROJECT_DIR/backend/app/api/v1" \
  "$PROJECT_DIR/backend/app/api/v1/__init__.py"

assert_any_path "backend response envelope module" \
  "$PROJECT_DIR/backend/app/schemas/common.py" \
  "$PROJECT_DIR/backend/app/schemas/response.py" \
  "$PROJECT_DIR/backend/app/core/response.py"

assert_any_path "backend error handling module" \
  "$PROJECT_DIR/backend/app/core/errors.py" \
  "$PROJECT_DIR/backend/app/core/exceptions.py" \
  "$PROJECT_DIR/backend/app/core/error_handlers.py"

assert_any_path "backend security module" \
  "$PROJECT_DIR/backend/app/core/security.py" \
  "$PROJECT_DIR/backend/app/core/auth.py"

assert_any_path "backend health route" \
  "$PROJECT_DIR/backend/app/api/routes/health.py" \
  "$PROJECT_DIR/backend/app/api/v1/routes/health.py" \
  "$PROJECT_DIR/backend/app/api/health.py"

assert_glob_exists "CI workflow" "$PROJECT_DIR/.github/workflows/*.yml"
assert_glob_exists "Nginx config" "$PROJECT_DIR/infra/nginx/*"

assert_grep "JWT_SECRET_KEY" "$PROJECT_DIR/.env.example"
assert_grep "JWT_REFRESH_SECRET_KEY" "$PROJECT_DIR/.env.example"
assert_grep "DATABASE_URL" "$PROJECT_DIR/.env.example"
assert_grep "REDIS_URL" "$PROJECT_DIR/.env.example"
assert_grep "CORS_ALLOW_ORIGINS" "$PROJECT_DIR/.env.example"
assert_grep "COOKIE_SECURE" "$PROJECT_DIR/.env.example"
assert_grep "VITE_API_BASE_URL" "$PROJECT_DIR/.env.example"

assert_grep "docker compose config" "$PROJECT_DIR/README.md"
assert_grep "docker compose up --build" "$PROJECT_DIR/README.md"
assert_grep "pytest" "$PROJECT_DIR/README.md"
assert_grep "ruff check" "$PROJECT_DIR/README.md"
assert_grep "npm run build" "$PROJECT_DIR/README.md"
assert_grep "npm run lint" "$PROJECT_DIR/README.md"
assert_grep "check_business_flow" "$PROJECT_DIR/README.md"

echo "Template-level audit passed for $PROJECT_DIR"
