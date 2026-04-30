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
4. Parallel execution plan exists and records task ownership/integration evidence
5. Backend/frontend core entry files and production support assets exist
6. .env.example contains required environment keys
7. README contains required verification command references
8. Production-grade gates from docs/production-grade-rubric.md have code/config evidence
9. CI includes production verification gates instead of only build smoke checks
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
  "$PROJECT_DIR/doc" \
  "$PROJECT_DIR/scripts" \
  "$PROJECT_DIR/openspec" \
  "$PROJECT_DIR/backend" \
  "$PROJECT_DIR/frontend" \
  "$PROJECT_DIR/infra/nginx" \
  "$PROJECT_DIR/.github/workflows" \
  "$PROJECT_DIR/.gitlab-ci.yml" \
  "$PROJECT_DIR/.claude/skills/find-skills/SKILL.md"; do
  assert_path "$path"
done

for path in \
  "$PROJECT_DIR/openspec/project.md" \
  "$PROJECT_DIR/requirements/requirement.md" \
  "$PROJECT_DIR/doc/architecture.md" \
  "$PROJECT_DIR/doc/development.md" \
  "$PROJECT_DIR/doc/ai-workflow.md" \
  "$PROJECT_DIR/doc/parallel-execution-plan.md" \
  "$PROJECT_DIR/doc/review-log.md" \
  "$PROJECT_DIR/doc/fix-log.md" \
  "$PROJECT_DIR/doc/key-business-actions-checklist.md" \
  "$PROJECT_DIR/doc/frontend-ui-checklist.md" \
  "$PROJECT_DIR/doc/production-readiness-checklist.md" \
  "$PROJECT_DIR/doc/security-notes.md" \
  "$PROJECT_DIR/doc/observability.md" \
  "$PROJECT_DIR/doc/test-plan.md"; do
  assert_path "$path"
done

# --- 前端页面截图检查 ---
assert_path "$PROJECT_DIR/doc/screenshots"
if [[ -d "$PROJECT_DIR/doc/screenshots" ]]; then
  shopt -s nullglob
  screenshot_files=("$PROJECT_DIR"/doc/screenshots/*.{png,jpg,jpeg,gif,webp,PNG,JPG,JPEG})
  shopt -u nullglob
  if [[ ${#screenshot_files[@]} -lt 3 ]]; then
    echo "FAIL: doc/screenshots/ has only ${#screenshot_files[@]} image(s); minimum 3 frontend page screenshots required" >&2
    echo "  Fix: add screenshots of core pages (login, dashboard, list, detail, form) to doc/screenshots/" >&2
    exit 1
  fi
fi
assert_grep "截图\|screenshot\|Screenshots" "$PROJECT_DIR/README.md"

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
assert_any_grep "CI compose config" "docker compose.*config" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI backend tests" "pytest" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI backend lint" "ruff check" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI frontend lint" "npm run lint" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI frontend build" "npm run build" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI frontend tests" "npm test\|npm run test" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI OpenAPI export" "export_openapi\|openapi" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "CI dependency audit" "pip-audit\|safety\|npm audit" "$PROJECT_DIR/.github/workflows" "$PROJECT_DIR/.gitlab-ci.yml"
assert_any_grep "security notes admin bootstrap" "Admin Bootstrap\|管理员初始化\|bootstrap\|seed" "$PROJECT_DIR/doc/security-notes.md"
assert_any_grep "security notes rate limiting" "Rate Limiting\|限流\|rate limit" "$PROJECT_DIR/doc/security-notes.md"
assert_any_grep "observability request id" "Request ID\|Correlation ID\|request_id\|correlation_id" "$PROJECT_DIR/doc/observability.md"
assert_any_grep "observability metrics" "metrics\|Prometheus\|/metrics" "$PROJECT_DIR/doc/observability.md"
assert_any_grep "test plan backend cases" "Auth failure\|认证失败\|Authorization failure\|越权" "$PROJECT_DIR/doc/test-plan.md"
assert_any_grep "test plan frontend tests" "Frontend Tests\|前端测试\|Component\|Smoke" "$PROJECT_DIR/doc/test-plan.md"
assert_any_grep "parallel plan task ownership" "owner\|Owner\|文件所有权\|写入范围" "$PROJECT_DIR/doc/parallel-execution-plan.md"
assert_any_grep "parallel plan integration" "集成\|integration\|并发\|parallel" "$PROJECT_DIR/doc/parallel-execution-plan.md"

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
  if [[ ! -f "$PROJECT_DIR/doc/security-notes.md" ]] || ! grep -q "localStorage" "$PROJECT_DIR/doc/security-notes.md"; then
    echo "Token localStorage usage requires explicit risk note in doc/security-notes.md" >&2
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
  echo "FAIL: compose.yaml uses .env.example as env_file; production must use .env (copy from .env.example and customize)" >&2
  echo "  Fix: change env_file to .env, or use 'docker compose --env-file .env.example config' for validation only" >&2
  exit 1
fi

# --- N. .gitignore 应忽略 .claude/ 目录 ---
if [[ -f "$PROJECT_DIR/.gitignore" ]] \
  && ! grep -q '\.claude' "$PROJECT_DIR/.gitignore"; then
  echo "WARNING: .gitignore does not ignore .claude/ directory (may leak sensitive settings)" >&2
fi

# --- S2. 前端测试文件数量 ≥3 ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  fe_test_count=$(find "$PROJECT_DIR/frontend/src" \( -name '*.test.*' -o -name '*.spec.*' \) \
    -not -path '*node_modules*' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$fe_test_count" -lt 3 ]]; then
    echo "FAIL: Frontend has only $fe_test_count test file(s) in frontend/src; minimum is 3 covering 3 different categories" >&2
    echo "  Required categories (pick ≥3): API client, AuthProvider, page form validation, empty/error states, mutation success/failure" >&2
    exit 1
  fi
fi

# --- S3. Refresh Token 轮换证据 ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  has_refresh=$(grep -R -l -E "refresh_token|create_refresh_token|refresh_secret" "$PROJECT_DIR/backend/app" 2>/dev/null | head -1 || true)
  if [[ -n "$has_refresh" ]]; then
    has_rotation=$(grep -R -E -l "delete.*refresh|redis.*delete.*jti|remove.*jti|revoke.*refresh" "$PROJECT_DIR/backend/app" 2>/dev/null | head -1 || true)
    if [[ -z "$has_rotation" ]]; then
      echo "FAIL: Backend implements refresh token but no rotation evidence found (delete old jti on refresh)" >&2
      echo "  Expected: refresh endpoint should delete old jti and issue new refresh token" >&2
      exit 1
    fi
  fi
fi

# --- S4. 分页控件证据 ---
if [[ -d "$PROJECT_DIR/frontend/src" ]] && [[ -d "$PROJECT_DIR/backend/app" ]]; then
  has_backend_pagination=$(grep -R -E -l "page_size|Page\[|PageResponse|PaginatedResponse" "$PROJECT_DIR/backend/app" 2>/dev/null | head -1 || true)
  if [[ -n "$has_backend_pagination" ]]; then
    has_frontend_pagination=$(grep -R -E -l "setPage|pagination|Pagination|onPageChange|nextPage|prevPage|currentPage" "$PROJECT_DIR/frontend/src" 2>/dev/null | head -1 || true)
    if [[ -z "$has_frontend_pagination" ]]; then
      echo "FAIL: Backend implements pagination but frontend has no pagination controls (setPage, Pagination component, onPageChange)" >&2
      exit 1
    fi
  fi
fi

# --- S5. 路由守卫证据 ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  has_auth_page=$(grep -R -E -l "AuthPage|LoginPage|SignInPage|/login|/signin" "$PROJECT_DIR/frontend/src" 2>/dev/null | head -1 || true)
  if [[ -n "$has_auth_page" ]]; then
    has_route_guard=$(grep -R -E -l "ProtectedRoute|RequireAuth|AuthGuard|PrivateRoute|Navigate.*login|redirect.*login" "$PROJECT_DIR/frontend/src" 2>/dev/null | head -1 || true)
    if [[ -z "$has_route_guard" ]]; then
      echo "FAIL: Frontend has auth pages but no route guard evidence (ProtectedRoute, RequireAuth, Navigate to /login)" >&2
      exit 1
    fi
  fi
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
  if grep -R -q "argon2" "$PROJECT_DIR/doc/security-notes.md" 2>/dev/null; then
    if ! grep -R -qE "argon2|PasswordHasher|hash_password" "$PROJECT_DIR/backend/app"; then
      echo "FAIL: doc/security-notes.md mentions argon2 but backend code has no argon2 usage" >&2
      exit 1
    fi
  elif grep -R -q "bcrypt" "$PROJECT_DIR/doc/security-notes.md" 2>/dev/null; then
    if ! grep -R -qE "bcrypt|passlib.*bcrypt" "$PROJECT_DIR/backend/app"; then
      echo "FAIL: doc/security-notes.md mentions bcrypt but backend code has no bcrypt usage" >&2
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

# --- S2. GitLab CI 必须覆盖与 GitHub Actions 相同的质量门禁 ---
if [[ -f "$PROJECT_DIR/.gitlab-ci.yml" ]]; then
  assert_any_grep "GitLab CI backend tests" "pytest" "$PROJECT_DIR/.gitlab-ci.yml"
  assert_any_grep "GitLab CI backend lint" "ruff check" "$PROJECT_DIR/.gitlab-ci.yml"
  assert_any_grep "GitLab CI frontend build" "npm run build" "$PROJECT_DIR/.gitlab-ci.yml"
  assert_any_grep "GitLab CI frontend lint" "npm run lint" "$PROJECT_DIR/.gitlab-ci.yml"
  assert_any_grep "GitLab CI frontend tests" "npm test\|npm run test" "$PROJECT_DIR/.gitlab-ci.yml"
  assert_any_grep "GitLab CI compose config" "docker compose.*config" "$PROJECT_DIR/.gitlab-ci.yml"
fi

# ============================================================
# PHASE 2: fullstack-review-v2 强约束补充 (2026-04-30)
# 来源: review-v2 gap analysis — 将 L1/L2 检查项从文档约束升级为脚本硬约束
# ============================================================

# --- T1. [前端 L1] ErrorBoundary 必须存在 ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  if ! grep -R -E -q "ErrorBoundary|getDerivedStateFromError|componentDidCatch" "$PROJECT_DIR/frontend/src" \
    --include='*.tsx' --include='*.jsx' --include='*.ts' 2>/dev/null; then
    echo "FAIL: No ErrorBoundary found in frontend/src/ (componentDidCatch or getDerivedStateFromError required)" >&2
    echo "  Fix: create frontend/src/components/ErrorBoundary.tsx implementing React error boundary" >&2
    exit 1
  fi
fi

# --- T2. [前端 L1] 页面/功能组件禁止裸 fetch 调用 ---
# API 封装层 (api/, lib/, utils/) 中允许使用 fetch，但 pages/ 和 features/ 中不允许
if [[ -d "$PROJECT_DIR/frontend/src/pages" ]]; then
  raw_fetch_in_pages=$(grep -R -n 'fetch(' "$PROJECT_DIR/frontend/src/pages" \
    --include='*.tsx' --include='*.ts' --include='*.jsx' 2>/dev/null \
    | grep -v '//.*fetch\|refetch\|prefetch\|useFetch\|fetchNextPage\|fetchPreviousPage' || true)
  if [[ -n "$raw_fetch_in_pages" ]]; then
    echo "FAIL: Raw fetch() calls found in frontend/src/pages/ — must use centralized API client" >&2
    echo "$raw_fetch_in_pages" | head -5 >&2
    echo "  Fix: import and use the API client from api/ or lib/ instead of raw fetch()" >&2
    exit 1
  fi
fi

# --- T3. [前端 L1] 禁止空 catch 块静默吞掉错误 ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  empty_catch=$(grep -R -E -n '\.catch\s*\(\s*\(\s*\)\s*=>\s*\{\s*\}\s*\)|\.catch\s*\(\s*\(\s*\w+\s*\)\s*=>\s*\{\s*\}\s*\)' \
    "$PROJECT_DIR/frontend/src/pages" "$PROJECT_DIR/frontend/src/features" \
    --include='*.tsx' --include='*.ts' 2>/dev/null || true)
  if [[ -n "$empty_catch" ]]; then
    echo "FAIL: Empty .catch() blocks found — API errors must not be silently swallowed" >&2
    echo "$empty_catch" | head -5 >&2
    echo "  Fix: add error handling (toast, setState, console.error) in catch blocks" >&2
    exit 1
  fi
fi

# --- T4. [前端 L2] 路由懒加载 (React.lazy + Suspense) ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  app_entry=$(find "$PROJECT_DIR/frontend/src" -maxdepth 2 \( -name 'App.tsx' -o -name 'router.tsx' -o -name 'routes.tsx' \) 2>/dev/null | head -1)
  if [[ -n "$app_entry" ]]; then
    if ! grep -qE 'React\.lazy|lazy\(' "$app_entry" 2>/dev/null; then
      echo "FAIL: No route lazy loading (React.lazy) found in $app_entry" >&2
      echo "  Fix: use React.lazy(() => import('./pages/...')) for page-level code splitting" >&2
      exit 1
    fi
    if ! grep -qE 'Suspense' "$app_entry" 2>/dev/null; then
      echo "FAIL: React.lazy used but no <Suspense> wrapper found in $app_entry" >&2
      echo "  Fix: wrap lazy routes with <Suspense fallback={<Loading />}>" >&2
      exit 1
    fi
  fi
fi

# --- T5. [前端 L2] TypeScript any 滥用检测 (>5 处则 FAIL) ---
if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  any_matches_file=$(mktemp)
  grep -R -n -E ': any[^A-Za-z]|: any$|as any[^A-Za-z]|as any$|<any>' \
    "$PROJECT_DIR/frontend/src" \
    --include='*.ts' --include='*.tsx' \
    2>/dev/null \
    | grep -v -E 'node_modules|\.test\.|\.spec\.|__tests__' \
    > "$any_matches_file" 2>/dev/null || true
  any_count=$(wc -l < "$any_matches_file" | tr -d ' ')
  rm -f "$any_matches_file"
  if [[ "$any_count" -gt 5 ]]; then
    echo "FAIL: TypeScript 'any' abuse detected ($any_count occurrences in frontend/src/, max allowed: 5)" >&2
    echo "  Fix: replace 'any' with proper type definitions; use 'unknown' if type is truly uncertain" >&2
    exit 1
  fi
fi

# --- T6. [前端 WARN] 未使用的 npm 依赖检测 ---
if [[ -f "$PROJECT_DIR/frontend/package.json" ]] && [[ -d "$PROJECT_DIR/frontend/src" ]]; then
  for dep_name in axios lodash moment; do
    if grep -q "\"$dep_name\"" "$PROJECT_DIR/frontend/package.json" 2>/dev/null; then
      dep_imported=$(grep -R -l "$dep_name" "$PROJECT_DIR/frontend/src" \
        --include='*.ts' --include='*.tsx' --include='*.js' 2>/dev/null \
        | grep -v 'node_modules' | head -1 || true)
      if [[ -z "$dep_imported" ]]; then
        echo "WARNING: npm dependency '$dep_name' declared in package.json but never imported in frontend/src/" >&2
        echo "  Fix: npm uninstall $dep_name (dead dependency increases bundle size)" >&2
      fi
    fi
  done
fi

# --- T7. [安全 L1] CORS 禁止通配符 allow_origins=["*"] ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  if grep -R -E -q 'allow_origins\s*=\s*\["\*"\]|allow_origins\s*=\s*\['"'"'\*'"'"'\]' \
    "$PROJECT_DIR/backend/app" 2>/dev/null; then
    echo "FAIL: CORS allow_origins=[\"*\"] detected — production must use explicit origin whitelist" >&2
    echo "  Fix: use allow_origins=settings.cors_origins (read from CORS_ORIGINS env var)" >&2
    exit 1
  fi
fi

# --- T8. [安全 L2 WARN] Cookie COOKIE_SECURE 默认值不应为 False ---
if [[ -d "$PROJECT_DIR/backend/app/core" ]]; then
  config_file=$(find "$PROJECT_DIR/backend/app/core" -name 'config.py' -o -name 'settings.py' 2>/dev/null | head -1)
  if [[ -n "$config_file" ]] && grep -E -q 'COOKIE_SECURE.*=.*False|COOKIE_SECURE.*bool.*=.*False' "$config_file" 2>/dev/null; then
    echo "WARNING: COOKIE_SECURE defaults to False in $config_file — production should default to True (secure by default)" >&2
    echo "  Fix: change default to True; local dev overrides to false via .env" >&2
  fi
fi

# --- T9. [安全 L2] Refresh 端点需要 CSRF 保护 (Origin 校验或自定义 header) ---
# SameSite=strict cookie 提供了部分缓解，但纵深防御仍需服务端校验
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  refresh_file=$(grep -R -l -E "def.*refresh|/refresh|refresh_token" "$PROJECT_DIR/backend/app/api" \
    --include='*.py' 2>/dev/null | head -1 || true)
  if [[ -n "$refresh_file" ]]; then
    if ! grep -E -q 'origin|Origin|csrf|CSRF|X-Requested-With' "$refresh_file" 2>/dev/null; then
      echo "WARNING: Refresh token endpoint ($refresh_file) has no server-side CSRF protection" >&2
      echo "  SameSite=strict provides partial mitigation, but defense-in-depth requires Origin header validation" >&2
      echo "  Fix: add Origin header check or require X-Requested-With custom header in refresh endpoint" >&2
    fi
  fi
fi

# --- T10. [安全 L2] Cookie 必须配置 httpOnly + sameSite ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  cookie_files=$(grep -R -l -E "set_cookie|response\.cookies" "$PROJECT_DIR/backend/app" --include='*.py' 2>/dev/null || true)
  if [[ -n "$cookie_files" ]]; then
    for cf in $cookie_files; do
      if grep -q "set_cookie\|response\.cookies" "$cf" 2>/dev/null; then
        if ! grep -q "httponly" "$cf" 2>/dev/null; then
          echo "FAIL: Cookie set in $cf missing httponly attribute" >&2
          echo "  Fix: add httponly=True to set_cookie() call" >&2
          exit 1
        fi
        if ! grep -E -q "samesite|same_site" "$cf" 2>/dev/null; then
          echo "FAIL: Cookie set in $cf missing samesite attribute" >&2
          echo "  Fix: add samesite='strict' (or 'lax') to set_cookie() call" >&2
          exit 1
        fi
      fi
    done
  fi
fi

# --- T11. [安全 L1] SQL 注入：禁止 f-string 拼接 SQL ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  sql_fstring=$(grep -R -n -E 'f"[^"]*\b(SELECT|INSERT|UPDATE|DELETE)\b|f'"'"'[^'"'"']*\b(SELECT|INSERT|UPDATE|DELETE)\b' \
    "$PROJECT_DIR/backend/app" --include='*.py' 2>/dev/null \
    | grep -v 'migrations\|alembic\|health\|# ' || true)
  if [[ -n "$sql_fstring" ]]; then
    echo "FAIL: Potential SQL injection — f-string SQL construction detected:" >&2
    echo "$sql_fstring" | head -5 >&2
    echo "  Fix: use SQLAlchemy ORM queries or parameterized text() binds" >&2
    exit 1
  fi
fi

# --- T12. [后端 L2] 数据库连接池配置 ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  if ! grep -R -E -q "pool_size|pool_recycle|pool_pre_ping" "$PROJECT_DIR/backend/app" \
    --include='*.py' 2>/dev/null; then
    echo "FAIL: No database connection pool configuration found (pool_size, pool_recycle, pool_pre_ping)" >&2
    echo "  Fix: configure create_async_engine(pool_size=N, pool_recycle=3600, pool_pre_ping=True)" >&2
    exit 1
  fi
fi

# --- T13. [后端 L2] 模型 updated_at 字段 ---
if [[ -d "$PROJECT_DIR/backend/app/models" ]] || [[ -d "$PROJECT_DIR/backend/app/db" ]]; then
  if ! grep -R -q "updated_at" "$PROJECT_DIR/backend/app/models" "$PROJECT_DIR/backend/app/db" \
    --include='*.py' 2>/dev/null; then
    echo "FAIL: No 'updated_at' field found in backend models — required for audit trails and optimistic locking" >&2
    echo "  Fix: add updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now()) to Base or key models" >&2
    exit 1
  fi
fi

# --- T14. [后端 L2] Lifespan 优雅关机 (engine.dispose / redis.close) ---
if [[ -f "$PROJECT_DIR/backend/app/main.py" ]]; then
  if ! grep -E -q "dispose|aclose" "$PROJECT_DIR/backend/app/main.py" 2>/dev/null; then
    echo "FAIL: No graceful shutdown cleanup in main.py (engine.dispose() / redis.aclose())" >&2
    echo "  Fix: add engine.dispose() and redis.aclose() in the lifespan shutdown path (after yield)" >&2
    exit 1
  fi
fi

# --- T15. [后端 L2] N+1 查询预防 (eager loading) ---
if [[ -d "$PROJECT_DIR/backend/app" ]]; then
  # 检查是否有 relationship 定义 (意味着需要 eager loading)
  has_relationships=$(grep -R -E -q "relationship\(|Relationship\(" "$PROJECT_DIR/backend/app/models" \
    --include='*.py' 2>/dev/null && echo "yes" || echo "no")
  if [[ "$has_relationships" == "yes" ]]; then
    if ! grep -R -E -q "selectinload|joinedload|subqueryload|lazy=\"raise\"" \
      "$PROJECT_DIR/backend/app" --include='*.py' 2>/dev/null; then
      echo "FAIL: ORM relationships exist but no eager loading strategy found (selectinload/joinedload/lazy=\"raise\")" >&2
      echo "  Fix: use selectinload() in queries or set lazy='raise' on relationships to prevent N+1" >&2
      exit 1
    fi
  fi
fi

# --- T16. [部署 L2] Compose healthcheck 指令 (至少 2 个服务) ---
if [[ -f "$PROJECT_DIR/compose.yaml" ]]; then
  hc_count=$(grep -c "healthcheck:" "$PROJECT_DIR/compose.yaml" 2>/dev/null || echo "0")
  if [[ "$hc_count" -lt 2 ]]; then
    echo "FAIL: compose.yaml has only $hc_count healthcheck directives (minimum 2 required: DB + app)" >&2
    echo "  Fix: add healthcheck with test, interval, timeout, retries to mysql/redis/backend services" >&2
    exit 1
  fi
fi

# --- T17. [部署 L1] Backend Dockerfile 多阶段构建 ---
if [[ -f "$PROJECT_DIR/backend/Dockerfile" ]]; then
  from_count=$(grep -c '^FROM' "$PROJECT_DIR/backend/Dockerfile" 2>/dev/null || echo "0")
  if [[ "$from_count" -lt 2 ]]; then
    echo "FAIL: backend/Dockerfile has only $from_count FROM stage(s) — multi-stage build required" >&2
    echo "  Fix: use FROM python:3.12-slim AS builder ... FROM python:3.12-slim AS runtime" >&2
    exit 1
  fi
fi

# --- T18. [质量 P0] 软删除机制（升级为硬门禁） ---
if [[ -d "$PROJECT_DIR/backend/app/models" ]]; then
  if ! grep -R -E -q "deleted_at|is_deleted|SoftDeleteMixin" "$PROJECT_DIR/backend/app/models" \
    --include='*.py' 2>/dev/null; then
    echo "FAIL: No soft delete mechanism found in backend models (deleted_at/is_deleted/SoftDeleteMixin required)" >&2
    echo "  Fix: add SoftDeleteMixin with deleted_at column to core business models (User, primary entities)" >&2
    exit 1
  fi
fi

# --- T19. [质量 L2] 异常场景测试证据 ---
if [[ -d "$PROJECT_DIR/backend/tests" ]]; then
  if ! grep -R -E -q "IntegrityError|HTTPException|status_code.*(4[0-9][0-9]|5[0-9][0-9])|redis.*error|Timeout|ConnectionError" \
    "$PROJECT_DIR/backend/tests" --include='*.py' 2>/dev/null; then
    echo "FAIL: No exception scenario test evidence found in backend/tests/" >&2
    echo "  Fix: add tests for error paths (4xx/5xx responses, DB integrity errors, Redis failures)" >&2
    exit 1
  fi
fi

# --- T20. [部署 P0] 生产环境 compose 覆盖文件 ---
found_prod_compose=0
for candidate in "$PROJECT_DIR/compose.prod.yml" "$PROJECT_DIR/docker-compose.prod.yml" "$PROJECT_DIR/compose.production.yml"; do
  if [[ -f "$candidate" ]]; then
    found_prod_compose=1
    break
  fi
done
if [[ "$found_prod_compose" -eq 0 ]]; then
  echo "FAIL: No production compose override found (compose.prod.yml / docker-compose.prod.yml)" >&2
  echo "  Fix: create compose.prod.yml with resource limits, no exposed ports, stop_grace_period" >&2
  exit 1
fi

# --- T21. [部署 P0] 生产环境变量模板 ---
found_prod_env=0
for candidate in "$PROJECT_DIR/.env.production.example" "$PROJECT_DIR/.env.production" "$PROJECT_DIR/deploy/.env.production.example"; do
  if [[ -f "$candidate" ]]; then
    found_prod_env=1
    break
  fi
done
if [[ "$found_prod_env" -eq 0 ]]; then
  echo "FAIL: No production env template found (.env.production.example)" >&2
  echo "  Fix: create .env.production.example with COOKIE_SECURE=true, safe defaults, placeholder secrets" >&2
  exit 1
fi

# --- T22. [部署 P0] ENVIRONMENT 配置字段 ---
found_env_field=0
for candidate in "$PROJECT_DIR/backend/app/core/config.py" "$PROJECT_DIR/backend/app/core/settings.py"; do
  if [[ -f "$candidate" ]] && grep -q "ENVIRONMENT" "$candidate" 2>/dev/null; then
    found_env_field=1
    break
  fi
done
if [[ "$found_env_field" -eq 0 ]]; then
  echo "FAIL: No ENVIRONMENT config field in backend config/settings" >&2
  echo "  Fix: add ENVIRONMENT: str = 'development' to Settings with production validation" >&2
  exit 1
fi

# --- T23. [后端 P1] 结构化日志 RequestIdFilter 已激活 ---
found_request_id_filter=0
for candidate in "$PROJECT_DIR/backend/app/core/request_context.py" "$PROJECT_DIR/backend/app/core/logging.py" "$PROJECT_DIR/backend/app/core/middleware.py"; do
  if [[ -f "$candidate" ]] && grep -q "class RequestIdFilter" "$candidate" 2>/dev/null; then
    found_request_id_filter=1
    break
  fi
done
if [[ "$found_request_id_filter" -eq 0 ]]; then
  echo "FAIL: No RequestIdFilter class found — structured logging is incomplete" >&2
  echo "  Fix: add class RequestIdFilter(logging.Filter) that injects request_id into log records" >&2
  exit 1
fi

# 禁止 if False 禁用日志格式
if [[ -f "$PROJECT_DIR/backend/app/main.py" ]]; then
  if grep -E -q "if False.*request_id|if False.*RequestId|if False.*req=" "$PROJECT_DIR/backend/app/main.py" 2>/dev/null; then
    echo "FAIL: Structured logging disabled by 'if False' guard in main.py" >&2
    echo "  Fix: remove the 'if False' guard and properly wire RequestIdFilter into logging.basicConfig" >&2
    exit 1
  fi
fi

# --- T24. [安全 P1] 审计日志模型 ---
found_audit_model=0
for candidate in "$PROJECT_DIR/backend/app/models/audit_log.py" "$PROJECT_DIR/backend/app/models/audit.py"; do
  if [[ -f "$candidate" ]]; then
    found_audit_model=1
    break
  fi
done
if [[ "$found_audit_model" -eq 0 ]]; then
  echo "FAIL: No audit log model found (app/models/audit_log.py or audit.py)" >&2
  echo "  Fix: create AuditLog model with user_id, action, resource_type, resource_id, ip_address, details" >&2
  exit 1
fi

# 验证审计表声明
if [[ "$found_audit_model" -eq 1 ]]; then
  if ! grep -R -E -q "audit_logs|audit_log" "$PROJECT_DIR/backend/app/models" --include='*.py' 2>/dev/null; then
    echo "FAIL: audit_log model file exists but no audit table declaration found" >&2
    exit 1
  fi
fi

# --- T25. [安全 P1] 审计日志 migration ---
if [[ -d "$PROJECT_DIR/backend/migrations/versions" ]]; then
  if ! grep -R -E -q "audit_logs|create_table.*audit" "$PROJECT_DIR/backend/migrations/versions" \
    --include='*.py' 2>/dev/null; then
    echo "FAIL: No audit log migration found in migrations/versions/" >&2
    echo "  Fix: create migration that creates audit_logs table with proper indexes" >&2
    exit 1
  fi
fi

# ============================================================
# PHASE 3: 审查报告驱动补充 (2026-04-30)
# 来源: fullstack-review-v1 + v2 共性扣分项 → 模板级审计强制
# ============================================================

# --- U1. [安全 L2] Nginx 必须配置 HSTS ---
if [[ -d "$PROJECT_DIR/infra/nginx" ]]; then
  assert_any_grep "Nginx HSTS header" "Strict-Transport-Security" \
    "$PROJECT_DIR/infra/nginx"
fi

# --- U2. [安全 L2] CSP 禁止 script-src unsafe-inline ---
if [[ -d "$PROJECT_DIR/infra/nginx" ]]; then
  if grep -E -q "script-src[^;]*'unsafe-inline'" "$PROJECT_DIR/infra/nginx"/*.conf 2>/dev/null; then
    echo "FAIL: CSP script-src contains 'unsafe-inline' — React SPA should not need inline scripts" >&2
    echo "  Fix: remove 'unsafe-inline' from script-src in nginx.conf; keep it only in style-src if needed for Tailwind" >&2
    exit 1
  fi
fi

# --- U3. [安全 L2] /metrics 端点必须有 IP 限制 ---
if [[ -d "$PROJECT_DIR/infra/nginx" ]]; then
  if grep -q '/metrics' "$PROJECT_DIR/infra/nginx"/*.conf 2>/dev/null; then
    if ! grep -A8 '/metrics' "$PROJECT_DIR/infra/nginx"/*.conf 2>/dev/null | grep -q 'deny\|allow'; then
      echo "FAIL: /metrics endpoint in Nginx has no IP access control (allow/deny)" >&2
      echo "  Fix: add 'allow 10.0.0.0/8; allow 172.16.0.0/12; deny all;' to /metrics location block" >&2
      exit 1
    fi
  fi
fi

# --- U4. [安全 WARN] 生产 Redis 必须配置认证 ---
if [[ -f "$PROJECT_DIR/.env.production.example" ]]; then
  if grep -q 'REDIS' "$PROJECT_DIR/.env.production.example" 2>/dev/null; then
    if ! grep -E -q 'REDIS_PASSWORD|requirepass|redis://:[^@]*@' "$PROJECT_DIR/.env.production.example" 2>/dev/null; then
      echo "WARNING: .env.production.example has Redis config but no REDIS_PASSWORD or auth in REDIS_URL" >&2
      echo "  Fix: add REDIS_PASSWORD= with '# REQUIRED: change in production' comment, and include password in REDIS_URL" >&2
    fi
  fi
fi

# --- U5. [后端 L1] 禁止 PostgreSQL 方言特有索引参数 ---
if [[ -d "$PROJECT_DIR/backend/app/models" ]]; then
  if grep -R -E -q "postgresql_where|postgresql_using|postgresql_ops|mssql_include" \
    "$PROJECT_DIR/backend/app/models" --include='*.py' 2>/dev/null; then
    echo "FAIL: PostgreSQL-specific index parameters found in models — project uses MySQL, these are silently ignored" >&2
    echo "  Fix: replace postgresql_where with cross-database UniqueConstraint + application-level logic" >&2
    exit 1
  fi
fi

# --- U6. [安全 WARN] 核心 write service 必须调用审计日志 ---
if [[ -d "$PROJECT_DIR/backend/app/services" ]]; then
  has_audit_model=$(grep -R -l "AuditLog\|audit_service\|AuditService" "$PROJECT_DIR/backend/app" --include='*.py' 2>/dev/null | head -1 || true)
  if [[ -n "$has_audit_model" ]]; then
    for svc_file in "$PROJECT_DIR"/backend/app/services/*.py; do
      [[ ! -f "$svc_file" ]] && continue
      [[ "$(basename "$svc_file")" == "__init__.py" ]] && continue
      [[ "$(basename "$svc_file")" == "audit.py" ]] && continue
      has_create=$(grep -c -E "async def create_|async def add_|async def register" "$svc_file" 2>/dev/null || echo 0)
      if [[ "$has_create" -gt 0 ]]; then
        has_audit_call=$(grep -c -E "audit_service|AuditService|audit_log" "$svc_file" 2>/dev/null || echo 0)
        if [[ "$has_audit_call" -eq 0 ]]; then
          echo "WARNING: Service $(basename "$svc_file") has create/write methods but no audit log calls" >&2
          echo "  Fix: add audit_service.log() calls for all create/update/delete operations" >&2
        fi
      fi
    done
  fi
fi

# --- U7. [部署 WARN] CI 依赖审计禁止 || true ---
for ci_file in "$PROJECT_DIR/.github/workflows/ci.yml" "$PROJECT_DIR/.gitlab-ci.yml"; do
  if [[ -f "$ci_file" ]]; then
    if grep -E -q '(pip-audit|npm audit).*\|\| true' "$ci_file" 2>/dev/null; then
      echo "WARNING: $(basename "$ci_file") uses '|| true' to suppress dependency audit failures — high-severity vulnerabilities will be silently ignored" >&2
      echo "  Fix: use 'continue-on-error: true' (GitHub Actions) or 'allow_failure: true' (GitLab CI) instead" >&2
    fi
  fi
done

# --- U8. [部署 WARN] compose.prod.yml 必须配置 stop_grace_period ---
if [[ -f "$PROJECT_DIR/compose.prod.yml" ]]; then
  if ! grep -q "stop_grace_period" "$PROJECT_DIR/compose.prod.yml" 2>/dev/null; then
    echo "WARNING: compose.prod.yml missing stop_grace_period for graceful shutdown" >&2
    echo "  Fix: add 'stop_grace_period: 30s' to backend, frontend, and nginx services" >&2
  fi
fi

# --- U9. [AI WARN] 缺少 CHANGELOG.md ---
if [[ ! -f "$PROJECT_DIR/CHANGELOG.md" ]]; then
  echo "WARNING: No CHANGELOG.md found — version history helps track releases and changes" >&2
  echo "  Fix: create CHANGELOG.md with initial v1.0.0 entry listing core features" >&2
fi

# --- U10. [AI WARN] 缺少 .claude/memory 目录 ---
if [[ ! -d "$PROJECT_DIR/.claude/memory" ]]; then
  echo "WARNING: No .claude/memory/ directory found — Claude memory files help maintain cross-session context" >&2
  echo "  Fix: create .claude/memory/ with PLANNING.md, DECISIONS.md, PROGRESS.md" >&2
fi

# --- U11. [AI WARN] 缺少 .mcp.json ---
if [[ ! -f "$PROJECT_DIR/.mcp.json" ]]; then
  echo "WARNING: No .mcp.json found — MCP configuration enables AI tool server integration" >&2
  echo "  Fix: create .mcp.json with minimal { \"mcpServers\": {} }" >&2
fi

echo "Template-level audit passed for $PROJECT_DIR"
