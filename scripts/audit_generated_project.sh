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
7. Production-grade gates from docs/production-grade-rubric.md have code/config evidence
8. CI includes production verification gates instead of only build smoke checks
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

assert_any_grep() {
  local description="$1"
  local pattern="$2"
  shift 2

  for path in "$@"; do
    if [[ -e "$path" ]] && grep -R -q "$pattern" "$path"; then
      return
    fi
  done

  echo "Missing required content for ${description}: pattern '${pattern}' in $*" >&2
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

assert_any_glob_exists() {
  local description="$1"
  shift

  for pattern in "$@"; do
    shopt -s nullglob
    local matches=($pattern)
    shopt -u nullglob
    if [[ ${#matches[@]} -gt 0 ]]; then
      return
    fi
  done

  echo "Missing required ${description}: $*" >&2
  exit 1
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
  "$PROJECT_DIR/docs/production-readiness-checklist.md" \
  "$PROJECT_DIR/docs/security-notes.md" \
  "$PROJECT_DIR/docs/observability.md" \
  "$PROJECT_DIR/docs/test-plan.md"; do
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
  "$PROJECT_DIR/backend/Dockerfile" \
  "$PROJECT_DIR/backend/.dockerignore" \
  "$PROJECT_DIR/frontend/package.json" \
  "$PROJECT_DIR/frontend/Dockerfile" \
  "$PROJECT_DIR/frontend/.dockerignore" \
  "$PROJECT_DIR/frontend/vite.config.ts" \
  "$PROJECT_DIR/frontend/src/main.tsx"; do
  assert_path "$path"
done

assert_any_path "frontend app assembly" \
  "$PROJECT_DIR/frontend/src/App.tsx" \
  "$PROJECT_DIR/frontend/src/app/App.tsx" \
  "$PROJECT_DIR/frontend/src/app/router.tsx"

assert_any_path "backend versioned api" \
  "$PROJECT_DIR/backend/app/api/v1" \
  "$PROJECT_DIR/backend/app/api/v1/__init__.py"

assert_any_path "backend response envelope module" \
  "$PROJECT_DIR/backend/app/schemas/common.py" \
  "$PROJECT_DIR/backend/app/schemas/response.py" \
  "$PROJECT_DIR/backend/app/core/response.py" \
  "$PROJECT_DIR/backend/app/core/responses.py"

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
  "$PROJECT_DIR/backend/app/api/health.py" \
  "$PROJECT_DIR/backend/app/api/v1/health.py"

assert_any_path "backend rate limiting module" \
  "$PROJECT_DIR/backend/app/core/rate_limit.py" \
  "$PROJECT_DIR/backend/app/core/ratelimit.py" \
  "$PROJECT_DIR/backend/app/middleware/rate_limit.py"

assert_any_path "backend request id middleware" \
  "$PROJECT_DIR/backend/app/core/request_context.py" \
  "$PROJECT_DIR/backend/app/core/request_id.py" \
  "$PROJECT_DIR/backend/app/middleware/request_id.py"

assert_any_path "backend metrics module" \
  "$PROJECT_DIR/backend/app/core/metrics.py" \
  "$PROJECT_DIR/backend/app/observability/metrics.py"

assert_any_glob_exists "OpenAPI export script" \
  "$PROJECT_DIR/scripts/export_openapi.sh" \
  "$PROJECT_DIR/backend/scripts/export_openapi.py" \
  "$PROJECT_DIR/backend/scripts/export_openapi.sh"

assert_glob_exists "CI workflow" "$PROJECT_DIR/.github/workflows/*.yml"
assert_glob_exists "Nginx config" "$PROJECT_DIR/infra/nginx/*"

assert_grep "JWT_SECRET_KEY" "$PROJECT_DIR/.env.example"
assert_grep "JWT_REFRESH_SECRET_KEY" "$PROJECT_DIR/.env.example"
assert_grep "DATABASE_URL" "$PROJECT_DIR/.env.example"
assert_grep "REDIS_URL" "$PROJECT_DIR/.env.example"
assert_any_grep "CORS env" "CORS_ALLOW_ORIGINS\|CORS_ORIGINS" "$PROJECT_DIR/.env.example"
assert_grep "COOKIE_SECURE" "$PROJECT_DIR/.env.example"
assert_grep "RATE_LIMIT" "$PROJECT_DIR/.env.example"
assert_grep "VITE_API_BASE_URL" "$PROJECT_DIR/.env.example"

assert_grep "docker compose config" "$PROJECT_DIR/README.md"
assert_grep "docker compose up --build" "$PROJECT_DIR/README.md"
assert_grep "pytest" "$PROJECT_DIR/README.md"
assert_grep "ruff check" "$PROJECT_DIR/README.md"
assert_grep "npm run build" "$PROJECT_DIR/README.md"
assert_grep "npm run lint" "$PROJECT_DIR/README.md"
assert_grep "npm test" "$PROJECT_DIR/README.md"
assert_grep "export_openapi" "$PROJECT_DIR/README.md"
assert_grep "check_business_flow" "$PROJECT_DIR/README.md"

assert_any_grep "request id usage" "request_id\|correlation_id\|X-Request-ID" "$PROJECT_DIR/backend/app"
assert_any_grep "metrics endpoint" "prometheus\|Counter\|Histogram\|/metrics" "$PROJECT_DIR/backend/app"
assert_any_grep "rate limit usage" "rate_limit\|RateLimit\|Too Many Requests\|429" "$PROJECT_DIR/backend/app"
assert_any_grep "safe admin bootstrap" "bootstrap\|seed_admin\|INITIAL_ADMIN\|ADMIN_BOOTSTRAP" "$PROJECT_DIR/backend" "$PROJECT_DIR/scripts"
assert_any_grep "Nginx gzip" "gzip[[:space:]]\+on" "$PROJECT_DIR/infra/nginx"
assert_any_grep "Nginx security headers" "X-Content-Type-Options\|Content-Security-Policy\|X-Frame-Options" "$PROJECT_DIR/infra/nginx"
assert_any_grep "CI compose config" "docker compose.*config" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI backend tests" "pytest" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI backend lint" "ruff check" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI frontend lint" "npm run lint" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI frontend build" "npm run build" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI frontend tests" "npm test\|npm run test" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI OpenAPI export" "export_openapi\|openapi" "$PROJECT_DIR/.github/workflows"
assert_any_grep "CI dependency audit" "pip-audit\|safety\|npm audit" "$PROJECT_DIR/.github/workflows"
assert_any_grep "security notes admin bootstrap" "Admin Bootstrap\|管理员初始化\|bootstrap\|seed" "$PROJECT_DIR/docs/security-notes.md"
assert_any_grep "security notes rate limiting" "Rate Limiting\|限流\|rate limit" "$PROJECT_DIR/docs/security-notes.md"
assert_any_grep "observability request id" "Request ID\|Correlation ID\|request_id\|correlation_id" "$PROJECT_DIR/docs/observability.md"
assert_any_grep "observability metrics" "metrics\|Prometheus\|/metrics" "$PROJECT_DIR/docs/observability.md"
assert_any_grep "test plan backend cases" "Auth failure\|认证失败\|Authorization failure\|越权" "$PROJECT_DIR/docs/test-plan.md"
assert_any_grep "test plan frontend tests" "Frontend Tests\|前端测试\|Component\|Smoke" "$PROJECT_DIR/docs/test-plan.md"

if grep -R -E -q "endswith\\([^)]*admin|startswith\\([^)]*admin|@admin\\.local|admin-.*example" "$PROJECT_DIR/backend/app"; then
  echo "Unsafe implicit admin promotion detected in backend code" >&2
  exit 1
fi

if grep -R -E -q "localStorage\\.setItem.*token|localStorage\\.getItem.*token" "$PROJECT_DIR/frontend/src"; then
  if [[ ! -f "$PROJECT_DIR/docs/security-notes.md" ]] || ! grep -q "localStorage" "$PROJECT_DIR/docs/security-notes.md"; then
    echo "Token localStorage usage requires explicit risk note in docs/security-notes.md" >&2
    exit 1
  fi
fi

echo "Template-level audit passed for $PROJECT_DIR"
