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

assert_not_grep() {
  local description="$1"
  local pattern="$2"
  local path="$3"

  if [[ -e "$path" ]] && grep -R -E -q "$pattern" "$path"; then
    echo "Forbidden content for ${description}: pattern '${pattern}' in $path" >&2
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

assert_any_egrep() {
  local description="$1"
  local pattern="$2"
  shift 2

  for path in "$@"; do
    if [[ -e "$path" ]] && grep -R -E -q "$pattern" "$path"; then
      return
    fi
  done

  echo "Missing required content for ${description}: pattern '${pattern}' in $*" >&2
  exit 1
}

assert_no_fake_frontend_async_action() {
  local path="$1"
  [[ -d "$path" ]] || return

  while IFS= read -r file; do
    if grep -E -q "toast\\.(success|info)|成功|已(通过|拒绝|发布|安装|创建|提交)|approved|rejected|published|installed|created" "$file" \
      && ! grep -E -q "useMutation|mutate\\(|mutateAsync\\(|api\\.|http\\.|client\\.|fetch\\(" "$file"; then
      echo "Possible fake frontend async business action in $file: setTimeout with success-like feedback but no API/mutation evidence" >&2
      exit 1
    fi
  done < <(grep -R -l -E "setTimeout[[:space:]]*\\(" "$path" || true)
}

# --- C. 假脚本检测：验证 package.json scripts 调用了真实工具 ---
assert_real_frontend_scripts() {
  local pkg="$1"
  [[ -f "$pkg" ]] || return

  for script_name in build lint test; do
    local cmd
    cmd="$(node -e "const p=require('$pkg'); console.log(p.scripts?.['$script_name'] || '')" 2>/dev/null || true)"
    [[ -z "$cmd" ]] && continue

    case "$script_name" in
      build)
        if ! echo "$cmd" | grep -qE 'vite|tsc|next|webpack|rollup|esbuild|parcel'; then
          echo "Fake frontend script detected: '$script_name' = '$cmd' (no known build tool)" >&2
          exit 1
        fi
        ;;
      lint)
        if ! echo "$cmd" | grep -qE 'eslint|biome|oxlint|stylelint|tsc'; then
          echo "Fake frontend script detected: '$script_name' = '$cmd' (no known lint tool)" >&2
          exit 1
        fi
        ;;
      test)
        if ! echo "$cmd" | grep -qE 'vitest|jest|mocha|cypress|playwright'; then
          echo "Fake frontend script detected: '$script_name' = '$cmd' (no known test runner)" >&2
          exit 1
        fi
        ;;
    esac
  done
}

# --- D. 死代码检测：扫描未被任何文件引用的源码文件 ---
assert_no_excessive_dead_code() {
  local src_dir="$1"
  local ext="$2"
  [[ -d "$src_dir" ]] || return

  local orphan_count=0
  local orphans=""
  while IFS= read -r file; do
    local basename_no_ext
    basename_no_ext="$(basename "$file" ".$ext")"
    case "$basename_no_ext" in
      main|index|__init__|App|setup|vite-env|styles) continue ;;
    esac
    # 跳过文件名含 test/spec 的
    echo "$basename_no_ext" | grep -qiE '\.test$|\.spec$|_test$' && continue
    # 检查是否有其他文件引用了这个模块名
    if ! grep -R -l "$basename_no_ext" "$src_dir" \
      --include="*.$ext" --include="*.ts" --include="*.tsx" --include="*.py" \
      2>/dev/null | grep -v "$file" | grep -q .; then
      orphan_count=$((orphan_count + 1))
      orphans="${orphans}  ${file}\n"
    fi
  done < <(find "$src_dir" -name "*.$ext" \
    -not -path '*node_modules*' -not -path '*.venv*' -not -path '*__pycache__*' \
    -not -name '__init__.py' -not -name '*.test.*' -not -name '*.spec.*' \
    -not -name '*.d.ts' -not -name 'vite-env.d.ts' 2>/dev/null)

  if [[ "$orphan_count" -gt 3 ]]; then
    echo "Excessive dead code detected ($orphan_count orphan .$ext files not imported by anything):" >&2
    echo -e "$orphans" >&2
    exit 1
  fi
}

# --- F. 前端列表页接线检查：input/select 必须有 state 绑定 ---
assert_frontend_list_controls_wired() {
  local pages_dir="$1"
  [[ -d "$pages_dir" ]] || return

  while IFS= read -r page; do
    local page_name
    page_name="$(basename "$page")"
    # 只检查 Market/List/Browse/Catalog/Explore 类列表页
    if echo "$page_name" | grep -qiE 'market|list|browse|catalog|explore'; then
      if grep -qE '<input|<Input' "$page" \
        && ! grep -qE 'onChange|useState|useSearchParams|setKeyword|setSearch|setQuery|setFilter' "$page"; then
        echo "Decorative search control in $page: <input> without state binding" >&2
        exit 1
      fi
      if grep -qE '<select|<Select' "$page" \
        && ! grep -qE 'onChange|useState|setSort|setCategory|setFilter|useSearchParams' "$page"; then
        echo "Decorative filter control in $page: <select> without state binding" >&2
        exit 1
      fi
    fi
  done < <(find "$pages_dir" -name '*.tsx' -o -name '*.jsx' 2>/dev/null)
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
  "$PROJECT_DIR/frontend/index.html" \
  "$PROJECT_DIR/frontend/vite.config.ts" \
  "$PROJECT_DIR/frontend/src/main.tsx"; do
  assert_path "$path"
done

assert_any_path "frontend lockfile" \
  "$PROJECT_DIR/frontend/package-lock.json" \
  "$PROJECT_DIR/frontend/pnpm-lock.yaml" \
  "$PROJECT_DIR/frontend/yarn.lock"

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
assert_any_egrep "metrics route template labels" "scope.*route|route\\.path|path_format|APIRoute" "$PROJECT_DIR/backend/app"
assert_any_grep "rate limit usage" "rate_limit\|RateLimit\|Too Many Requests\|429" "$PROJECT_DIR/backend/app"
assert_any_grep "safe admin bootstrap" "bootstrap\|seed_admin\|INITIAL_ADMIN\|ADMIN_BOOTSTRAP" "$PROJECT_DIR/backend" "$PROJECT_DIR/scripts"
assert_any_egrep "database readiness probe" "SELECT[[:space:]]+1|select\\([[:space:]]*1[[:space:]]*\\)|execute\\([^)]*SELECT[[:space:]]+1" "$PROJECT_DIR/backend/app"
assert_any_egrep "redis readiness probe" "redis.*\\.ping\\(|redis.*ping\\(" "$PROJECT_DIR/backend/app"
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

assert_grep "<!doctype html\|<!DOCTYPE html" "$PROJECT_DIR/frontend/index.html"
assert_grep "<html[^>]*lang=" "$PROJECT_DIR/frontend/index.html"
assert_grep "charset" "$PROJECT_DIR/frontend/index.html"
assert_grep "viewport" "$PROJECT_DIR/frontend/index.html"
assert_grep "<title>" "$PROJECT_DIR/frontend/index.html"

assert_any_grep "backend Dockerfile non-root runtime user" "^USER[[:space:]][[:space:]]*" "$PROJECT_DIR/backend/Dockerfile"

assert_not_grep "production MemoryStore or in-memory business store" "MemoryStore|from app\\.services\\.store import store|services\\.store import store|store[[:space:]]*=[[:space:]]*MemoryStore" "$PROJECT_DIR/backend/app"
assert_not_grep "deprecated FastAPI startup/shutdown hooks" "@app\\.on_event" "$PROJECT_DIR/backend/app"
assert_not_grep "static database readiness" "database['\"]?[[:space:]]*:[[:space:]]*['\"]configured|database.*configured" "$PROJECT_DIR/backend/app"
assert_not_grep "raw URL metrics label" "request\\.url\\.path" "$PROJECT_DIR/backend/app"
assert_no_fake_frontend_async_action "$PROJECT_DIR/frontend/src/pages"
assert_no_fake_frontend_async_action "$PROJECT_DIR/frontend/src/features"
assert_not_grep "production CSP hardcoded localhost connect-src" "connect-src[^;]*localhost" "$PROJECT_DIR/infra/nginx"

if grep -R -E -q "register|signup|/auth/register" "$PROJECT_DIR/backend/app" "$PROJECT_DIR/frontend/src"; then
  assert_any_grep "frontend auth session layer" "AuthContext\|createContext\|useAuth\|authStore\|SessionProvider" "$PROJECT_DIR/frontend/src"
fi

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

# ==== Semantic validation (beyond file existence) ====

# --- J-helper. 假 OpenAPI 导出检测函数 ---
assert_no_fake_openapi_export() {
  local script_path=""
  for p in "$PROJECT_DIR/scripts/export_openapi.sh" \
           "$PROJECT_DIR/backend/scripts/export_openapi.py" \
           "$PROJECT_DIR/backend/scripts/export_openapi.sh"; do
    [[ -f "$p" ]] && script_path="$p" && break
  done
  [[ -z "$script_path" ]] && return

  if grep -qE 'printf|echo.*\{|cat.*<<.*EOF' "$script_path" \
    && ! grep -qE 'app\.openapi|from app|import app|openapi\(\)' "$script_path"; then
    echo "Fake OpenAPI export: $script_path writes static JSON instead of calling app.openapi()" >&2
    exit 1
  fi
}

# --- C. 假脚本检测 ---
assert_real_frontend_scripts "$PROJECT_DIR/frontend/package.json"

# --- D. 死代码检测 ---
assert_no_excessive_dead_code "$PROJECT_DIR/frontend/src" "tsx"
assert_no_excessive_dead_code "$PROJECT_DIR/backend/app" "py"

# --- E. Dockerfile 语义验证 ---
if [[ -f "$PROJECT_DIR/frontend/Dockerfile" ]]; then
  if ! grep -qE 'npm (ci|install)|yarn install|pnpm install' "$PROJECT_DIR/frontend/Dockerfile"; then
    echo "Frontend Dockerfile missing dependency install (npm ci / npm install)" >&2
    exit 1
  fi
fi

if [[ -f "$PROJECT_DIR/backend/Dockerfile" ]]; then
  if grep -qE 'pip install.*(fastapi|flask|django|uvicorn|sqlalchemy)' "$PROJECT_DIR/backend/Dockerfile" \
    && ! grep -q 'pyproject.toml\|requirements.txt\|requirements.lock' "$PROJECT_DIR/backend/Dockerfile"; then
    echo "Backend Dockerfile uses inline pip install instead of pyproject.toml/requirements file" >&2
    exit 1
  fi
fi

# --- F. 前端列表页接线检查 ---
assert_frontend_list_controls_wired "$PROJECT_DIR/frontend/src/pages"

# --- G. API 响应一致性 ---
assert_any_egrep "route response_model usage" "response_model[[:space:]]*=" \
  "$PROJECT_DIR/backend/app/api"

# --- H. conftest 必须包含真实 DB fixture ---
assert_any_grep "backend conftest DB fixture" \
  "create_async_engine\|AsyncSession\|ASGITransport\|TestClient" \
  "$PROJECT_DIR/backend/tests/conftest.py"

# --- I. 前端测试必须有组件 render ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  if grep -R -l -E '\.test\.|\.spec\.' "$PROJECT_DIR/frontend/src" --include='*.tsx' --include='*.jsx' 2>/dev/null | head -1 | grep -q .; then
    assert_any_egrep "frontend component test render" "render\\(|screen\\." \
      "$PROJECT_DIR/frontend/src"
  fi
fi

# --- J. 假 OpenAPI 导出检测 ---
assert_no_fake_openapi_export

# --- K. 已安装 react-hook-form 必须在 src/ 中使用 ---
if [[ -f "$PROJECT_DIR/frontend/package.json" ]] \
  && grep -q '"react-hook-form"' "$PROJECT_DIR/frontend/package.json"; then
  assert_any_egrep "react-hook-form usage" "useForm|zodResolver|handleSubmit" \
    "$PROJECT_DIR/frontend/src"
fi

# --- L. 已安装 @radix-ui/react-alert-dialog 必须在 src/ 中使用 ---
if [[ -f "$PROJECT_DIR/frontend/package.json" ]] \
  && grep -q '"@radix-ui/react-alert-dialog"' "$PROJECT_DIR/frontend/package.json"; then
  assert_any_egrep "AlertDialog usage" "AlertDialog" \
    "$PROJECT_DIR/frontend/src"
fi

# --- M. compose.yaml env_file 不应指向 .env.example ---
if [[ -f "$PROJECT_DIR/compose.yaml" ]] \
  && grep -qE 'env_file.*\.env\.example' "$PROJECT_DIR/compose.yaml"; then
  echo "WARNING: compose.yaml uses .env.example as env_file; production should use .env" >&2
fi

# --- N. .gitignore 应忽略 .claude/ 目录 ---
if [[ -f "$PROJECT_DIR/.gitignore" ]] \
  && ! grep -q '\.claude' "$PROJECT_DIR/.gitignore"; then
  echo "WARNING: .gitignore does not ignore .claude/ directory (may leak sensitive settings)" >&2
fi

# --- O. Migration 必须包含 downgrade 回滚路径 ---
if [[ -d "$PROJECT_DIR/backend/migrations/versions" ]]; then
  shopt -s nullglob
  local_migration_files=("$PROJECT_DIR"/backend/migrations/versions/*.py)
  shopt -u nullglob
  for mfile in "${local_migration_files[@]}"; do
    if ! grep -q 'def downgrade' "$mfile"; then
      echo "Migration missing downgrade(): $mfile" >&2
      exit 1
    fi
  done
fi

# --- P. Nginx 必须配置 proxy timeout ---
if [[ -d "$PROJECT_DIR/infra/nginx" ]]; then
  assert_any_grep "Nginx proxy timeout" "proxy_read_timeout\|proxy_connect_timeout\|proxy_send_timeout" \
    "$PROJECT_DIR/infra/nginx"
fi

# --- Q. 密码哈希算法一致性 ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  if grep -R -q "argon2" "$PROJECT_DIR/docs/security-notes.md" 2>/dev/null; then
    if ! grep -R -qE "argon2|PasswordHasher|hash_password" "$PROJECT_DIR/backend/app"; then
      echo "FAIL: docs/security-notes.md mentions argon2 but backend code has no argon2 usage" >&2
      exit 1
    fi
  elif grep -R -q "bcrypt" "$PROJECT_DIR/docs/security-notes.md" 2>/dev/null; then
    if ! grep -R -qE "bcrypt|passlib.*bcrypt" "$PROJECT_DIR/backend/app"; then
      echo "FAIL: docs/security-notes.md mentions bcrypt but backend code has no bcrypt usage" >&2
      exit 1
    fi
  fi
fi

# --- R. seed/bootstrap 脚本必须可执行 ---
for seed_script in "$PROJECT_DIR/backend/scripts/seed.py" \
                   "$PROJECT_DIR/backend/scripts/seed_admin.py" \
                   "$PROJECT_DIR/backend/scripts/bootstrap.py" \
                   "$PROJECT_DIR/scripts/seed.sh" \
                   "$PROJECT_DIR/scripts/bootstrap.sh"; do
  if [[ -f "$seed_script" && ! -x "$seed_script" ]] && [[ "$seed_script" == *.sh ]]; then
    echo "Seed/bootstrap script not executable: $seed_script" >&2
    exit 1
  fi
done

# --- S. CI workflow 必须覆盖前端测试 ---
if [[ -d "$PROJECT_DIR/.github/workflows" ]]; then
  assert_any_grep "CI coverage reporting" "coverage\|cov-report\|--cov\|pytest-cov\|npm run coverage" \
    "$PROJECT_DIR/.github/workflows"
fi

echo "Template-level audit passed for $PROJECT_DIR"
