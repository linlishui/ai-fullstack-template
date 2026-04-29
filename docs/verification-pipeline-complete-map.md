# AI Fullstack Template: Complete Verification Pipeline Map

## Overview

The template defines a **three-layer verification architecture**:

1. **Template-level audit** (`audit_generated_project.sh`) - structural & config validation
2. **Project-level verification** (`verify_project.sh`) - executable quality checks
3. **Project-internal scripts** (in `generated/<slug>/scripts/`) - project-specific validation

---

## Layer 1: Template-Level Audit
**Script**: `./scripts/audit_generated_project.sh <project-dir>`  
**Purpose**: Verify generated project structure conforms to template standards  
**Runs**: FIRST, no dependencies (except basic file system)  
**Exit**: Yes (fails fast if structure incomplete)

### 1.1 Required Paths (file/dir existence)
```
PROJECT_DIR/
├── README.md
├── AGENTS.md
├── CLAUDE.md
├── .gitignore
├── .env.example
├── compose.yaml
├── requirements/
├── docs/
├── scripts/
├── openspec/
├── backend/
├── frontend/
├── infra/nginx/
└── .github/workflows/
```

### 1.2 OpenSpec Structure (must exist)
```
openspec/
├── project.md
├── specs/*/spec.md (glob)
├── changes/*/proposal.md (glob)
├── changes/*/design.md (glob)
└── changes/*/tasks.md (glob)
```

### 1.3 Documentation Structure
```
docs/
├── architecture.md
├── development.md
├── ai-workflow.md
├── review-log.md
├── fix-log.md
├── key-business-actions-checklist.md
├── frontend-ui-checklist.md
├── production-readiness-checklist.md
├── security-notes.md
├── observability.md
└── test-plan.md
```

### 1.4 Backend Core Files
```
backend/
├── pyproject.toml
├── alembic.ini
├── app/main.py
├── Dockerfile
├── .dockerignore
├── app/api/v1/ OR app/api/v1/__init__.py (versioned API)
├── app/schemas/{common,response}.py OR app/core/{response,responses}.py (envelope)
├── app/core/{errors,exceptions,error_handlers}.py (error handling)
├── app/core/{security,auth}.py (security module)
├── app/api/{routes/health,health}.py OR app/api/v1/{health}.py (health route)
├── app/core/{rate_limit,ratelimit}.py OR app/middleware/rate_limit.py (rate limiting)
├── app/core/{request_context,request_id}.py OR app/middleware/request_id.py (request ID)
├── app/core/metrics.py OR app/observability/metrics.py (metrics)
└── scripts/export_openapi.py OR ../scripts/export_openapi.sh
```

### 1.5 Frontend Core Files
```
frontend/
├── package.json
├── Dockerfile
├── .dockerignore
├── index.html
├── vite.config.ts
├── src/main.tsx
├── src/App.tsx OR src/app/App.tsx OR src/app/router.tsx (app assembly)
└── package-lock.json OR pnpm-lock.yaml OR yarn.lock (lockfile)
```

### 1.6 Configuration Validation
**`.env.example` must contain**:
- `JWT_SECRET_KEY`
- `JWT_REFRESH_SECRET_KEY`
- `DATABASE_URL`
- `REDIS_URL`
- `CORS_ALLOW_ORIGINS` OR `CORS_ORIGINS`
- `COOKIE_SECURE`
- `RATE_LIMIT`
- `VITE_API_BASE_URL`

### 1.7 README Requirements
Must reference verification commands:
- `docker compose config`
- `docker compose up --build`
- `pytest`
- `ruff check`
- `npm run build`
- `npm run lint`
- `npm test`
- `export_openapi`
- `check_business_flow`

### 1.8 Backend Implementation Evidence
Must contain (grep patterns):
- **Request ID usage**: `request_id` OR `correlation_id` OR `X-Request-ID`
- **Metrics endpoint**: `prometheus` OR `Counter` OR `Histogram` OR `/metrics`
- **Metrics route templates**: `scope.*route` OR `route\.path` OR `path_format` OR `APIRoute`
- **Rate limiting**: `rate_limit` OR `RateLimit` OR `Too Many Requests` OR `429`
- **Safe admin bootstrap**: `bootstrap` OR `seed_admin` OR `INITIAL_ADMIN` OR `ADMIN_BOOTSTRAP` (in backend or scripts)
- **Database readiness probe**: `SELECT 1` OR similar (in health check)
- **Redis readiness probe**: `redis.*\.ping\(` OR `redis.*ping\(`
- **Response models**: `response_model =` (in FastAPI routes)

### 1.9 Nginx Configuration Evidence
Must contain:
- **Gzip enabled**: `gzip on`
- **Security headers**: `X-Content-Type-Options` AND/OR `Content-Security-Policy` AND/OR `X-Frame-Options`

### 1.10 CI Workflow Coverage
`.github/workflows/*.yml` must contain:
- `docker compose config`
- `pytest`
- `ruff check`
- `npm run lint`
- `npm run build`
- `npm test` OR `npm run test`
- `export_openapi` OR `openapi`
- `pip-audit` OR `safety` OR `npm audit` (dependency audit)

### 1.11 Security & Observability Documentation Evidence
**`docs/security-notes.md` must mention**:
- Admin Bootstrap / 管理员初始化 / bootstrap / seed
- Rate Limiting / 限流

**`docs/observability.md` must mention**:
- Request ID / Correlation ID / request_id / correlation_id
- metrics / Prometheus / /metrics

**`docs/test-plan.md` must mention**:
- Auth failure / 认证失败 / Authorization failure / 越权
- Frontend Tests / 前端测试 / Component / Smoke

### 1.12 Frontend HTML Baseline
`frontend/index.html` must contain:
- `<!doctype html` OR `<!DOCTYPE html`
- `<html[^>]*lang=`
- `charset`
- `viewport`
- `<title>`

### 1.13 Docker Security Baseline
`backend/Dockerfile` must have:
- Non-root runtime user: `^USER[[:space:]][[:space:]]*`

### 1.14 Forbidden Patterns
**Backend (`assert_not_grep`)**:
- No `MemoryStore` or in-memory business store
- No `@app.on_event` (deprecated FastAPI startup/shutdown)
- No static database readiness (e.g., `"database": "configured"`)
- No raw URL metrics label (e.g., `request.url.path`)
- No hardcoded localhost in production CSP

**Frontend**:
- No fake async actions: `setTimeout` with success toast but no API/mutation evidence
- No implicit admin promotion: `endswith(...admin)` or `startswith(...admin)` or `@admin.local`
- No localStorage token without security note

### 1.15 Semantic Validations (Code Quality Checks)

#### C. Fake Frontend Scripts Detection
`assert_real_frontend_scripts()` checks `frontend/package.json`:
- **build**: must call `vite|tsc|next|webpack|rollup|esbuild|parcel`
- **lint**: must call `eslint|biome|oxlint|stylelint|tsc`
- **test**: must call `vitest|jest|mocha|cypress|playwright`

#### D. Dead Code Detection
`assert_no_excessive_dead_code()`:
- Backend: `.py` files not imported anywhere (except main, index, __init__, setup)
- Frontend: `.tsx/.jsx` files not imported anywhere
- Threshold: >3 orphan files = FAIL
- Skips test files, __pycache__, node_modules, .venv

#### E. Dockerfile Semantic Validation
- **Frontend**: Must contain `npm ci|npm install|yarn install|pnpm install`
- **Backend**: If inline `pip install fastapi|flask|django|...`, must use `pyproject.toml|requirements.txt|requirements.lock`

#### F. Frontend List Controls Wired
Pages matching `Market|List|Browse|Catalog|Explore`:
- Any `<input>` or `<Input>` must bind to state: `onChange|useState|useSearchParams|setKeyword|setSearch|setQuery|setFilter`
- Any `<select>` or `<Select>` must bind to state: `onChange|useState|setSort|setCategory|setFilter|useSearchParams`

#### G. API Response Consistency
At least one route must use: `response_model =`

### 1.16 Conditional Checks
If requirement includes registration/signup:
- Must provide auth session layer: `AuthContext|createContext|useAuth|authStore|SessionProvider`

If frontend uses localStorage for tokens:
- Must document in `docs/security-notes.md` with XSS risk warning

---

## Layer 2: Project-Level Verification
**Script**: `./scripts/verify_project.sh <project-dir> [--with-compose-up]`  
**Purpose**: Verify project runs, tests pass, and quality gates met  
**Runs**: AFTER template audit passes  
**Prerequisites**: Template audit passed, docker, python3, node, npm installed

### 2.1 Prerequisites Check
`check_prerequisites.sh`:
- `docker` (required)
- `python3` (required)
- `node` (required)
- `npm` (required)
- `docker compose` (required)
- `codex` / `claude` (optional AI CLIs)

### 2.2 Docker Compose Validation
```bash
cd $PROJECT_DIR
docker compose --env-file .env.example config
```
**Validates**: YAML syntax, service definitions, volume/network setup

### 2.3 Docker Compose Up (Optional)
```bash
cd $PROJECT_DIR
docker compose --env-file .env.example up --build -d
```
**Only if**: `--with-compose-up` flag provided  
**Validates**: Services start, container builds succeed  
**Cleanup**: Auto cleanup via trap on exit

### 2.4 Health Check (if compose up)
```bash
curl -fsS http://localhost:8080/api/v1/health/ready
```
**Timeout**: 60 seconds (2s poll interval, 30 attempts)  
**Endpoint**: `BASE_URL` env var (default: `http://localhost:8080`)

### 2.5 Backend Tests
**Path**: `$PROJECT_DIR/backend`

```bash
cd backend
./.venv/bin/pytest [--cov=app --cov-report=term-missing]  # if pytest-cov available
./.venv/bin/ruff check .
```

**Quality gates** (`validate_backend_test_quality()`):

#### B.1 Minimum Test Count
- **Requirement**: ≥8 test functions
- **Check**: `grep -R -c -E '^def test_|^async def test_'` in `backend/tests/`
- **Fail condition**: `test_count < 8`

#### B.2 Fake Test Detection
- **Requirement**: Every test file must import app module
- **Check**: Each `test_*.py` or `*_test.py` must match `^from app\.|^import app\.|^from app `
- **Exceptions**: `__init__.py`, `conftest.py`
- **Fail condition**: Any test file without app import = FAKE

#### B.3 Frontend Test Runner Verification
- **Requirement**: If `frontend/package.json` has test script, must be real runner
- **Check**: test script must call `vitest|jest|mocha|cypress|playwright`
- **Fail condition**: Test script exists but calls unknown runner

### 2.6 Frontend Build & Quality
**Path**: `$PROJECT_DIR/frontend`

#### A. Build Artifact Validation
```bash
cd frontend
npm run build
```

**Checks**:
1. **Real build tool**: `npm run build` script must call `vite|tsc|next|webpack|rollup|esbuild|parcel`
2. **Artifact exists**: `dist/` directory with `.js` or `.mjs` files

#### Lint
```bash
npm run lint
```

#### Tests (if script exists)
```bash
npm test -- --run
```

**Fail condition**: Test script missing (production-grade should provide one)

### 2.7 OpenAPI Export
**Script location** (tries in order):
1. `$PROJECT_DIR/scripts/export_openapi.sh`
2. `$PROJECT_DIR/backend/scripts/export_openapi.py`

**Must exist** (Fail condition: missing both)

### 2.8 Business Flow Check (if --with-compose-up and script exists)
**Path**: `$PROJECT_DIR/scripts/check_business_flow.sh`

**Conditions**:
- Only runs if services started (`--with-compose-up`)
- Only runs if script exists
- Must be executable
- Fail condition: script exists but not executable

---

## Layer 3: Project-Level Scripts
**Location**: `generated/<project-slug>/scripts/`  
**Purpose**: Project-specific automation post-generation

### 3.1 `verify_all.sh` (Project Convenience Script)
```bash
cd $PROJECT_DIR
docker compose --env-file .env.example config
cd $PROJECT_DIR/backend && ./.venv/bin/pytest --cov=app --cov-report=term-missing && ./.venv/bin/ruff check .
cd $PROJECT_DIR/frontend && npm run build && npm run lint && npm test -- --run
$PROJECT_DIR/scripts/export_openapi.sh
```

**Purpose**: One-shot verification (no compose up, no business flow)

### 3.2 `export_openapi.sh` (Project-Specific)
**Current implementation** (skillsops): Generates stub `openapi.json` with endpoints

**Real implementation should**: 
- Extract from FastAPI `/openapi.json` endpoint (requires running service), OR
- Use `scripts/export_openapi.py` to introspect app code

### 3.3 `check_business_flow.sh` (Project-Specific)
**Current implementation** (skillsops):
1. Login as admin
2. Create category
3. Register author, login
4. Create skill, submit, approve
5. Register user, install, review
6. Create version, delist

**Purpose**: End-to-end happy path verification (requires running services)

---

## Execution Order & Dependencies

```
Phase 1: Setup
├─ check_prerequisites.sh (docker, python, node, npm)
└─ [Optional] Manual: generate/setup project

Phase 2: Template Audit (MUST PASS)
└─ audit_generated_project.sh <project-dir>
   └─ Checks: structure, config, patterns, scripts, documentation

Phase 3: Project Verification
├─ docker compose config (parse YAML)
│  └─ [Optional] docker compose up (start services)
│     └─ wait_for_health (poll /api/v1/health/ready)
│
├─ Backend Quality
│  ├─ pytest (with coverage if available)
│  ├─ ruff check
│  └─ Test quality gates (≥8 tests, no fake tests, frontend runner check)
│
├─ Frontend Quality
│  ├─ npm run build (verify real build tool, dist artifacts)
│  ├─ npm run lint
│  └─ npm test (if exists)
│
├─ OpenAPI Export
│  └─ scripts/export_openapi.sh OR backend/scripts/export_openapi.py
│
└─ [Optional] Business Flow (if --with-compose-up and services running)
   └─ scripts/check_business_flow.sh (end-to-end workflow)

Phase 4: Project-Internal (Project's Convenience)
└─ scripts/verify_all.sh (convenience, no compose up)
```

---

## Template-Level vs Project-Level Classification

### Template-Level (Structural & Config Audit)
- **Who**: Template, runs on generated project
- **What**: File structure, configuration presence, code pattern detection
- **When**: After generation, before any execution
- **Fail**: Indicates generation failure (missing files, incomplete OpenSpec, etc.)
- **Script**: `audit_generated_project.sh`

**Checks**:
- 1.1-1.16: All structural, grep-based, no execution

### Project-Level (Executable Quality)
- **Who**: Template, runs on generated project
- **What**: Actual test/build/lint execution, code quality gates
- **When**: After template audit passes, requires tools installed
- **Fail**: Indicates implementation quality issues (failing tests, lint errors, etc.)
- **Script**: `verify_project.sh`

**Checks**:
- 2.1-2.8: All executable, requires running services/tools

### Project-Specific (Business Automation)
- **Who**: Generated project
- **What**: Project-specific convenience & business flow validation
- **When**: During development, after services running
- **Fail**: Indicates business logic issues
- **Scripts**: `verify_all.sh`, `export_openapi.sh`, `check_business_flow.sh`

---

## Gaps Between Specs and Implementation

### Gap 1: Export OpenAPI Implementation

**Spec** (`production-grade-rubric.md`):
> FastAPI project must preserve `/openapi.json` and provide `scripts/export_openapi.sh` to export to `docs/openapi.json`

**Current Reality** (skillsops):
- `scripts/export_openapi.sh` generates **static/hardcoded** OpenAPI JSON
- Does **NOT** extract from running FastAPI app
- Does **NOT** call `backend/scripts/export_openapi.py` or introspect app code

**Issue**:
- Stub `openapi.json` doesn't reflect actual API signatures
- Tests don't validate consistency between code routes and exported spec

**Fix Required**:
- Real `export_openapi.sh` should start backend health service, call `/openapi.json` endpoint, save result
- OR use `backend/scripts/export_openapi.py` to introspect FastAPI app and extract spec

### Gap 2: Business Flow Test Coverage

**Spec** (`production-grade-rubric.md`):
> `scripts/check_business_flow.sh` must be self-contained, repeatable, need no manual tokens, cover key role differences

**Current Reality** (skillsops):
- ✅ Self-contained with embedded login & token extraction
- ✅ Repeatable (uses timestamps for unique emails)
- ✅ Covers role differences: admin, author, user
- ✅ Covers key actions: create, submit, approve, install, review, version, delist

**Improvement Opportunity**:
- Currently minimal error handling (uses `|| true` in some places)
- No validation that returned objects are correct (just extracts IDs)
- Could add checks for response fields, status codes, resource consistency

### Gap 3: Frontend Test Quality Gate

**Spec** (`production-grade-rubric.md`):
> Frontend must provide smoke/component tests OR clear page-level availability verification script

**Verification in Script** (B.3):
```bash
if [[ -n "$test_cmd" ]] && ! echo "$test_cmd" | grep -qE 'vitest|jest|mocha|cypress|playwright'; then
  echo "FAIL: Frontend test script does not invoke a known test runner"
fi
```

**Gap**:
- Verifies test runner exists but **NOT** that tests actually run
- Verifies runner name but **NOT** test coverage or quality
- `npm test -- --run` might pass with empty/fake tests (equivalent to backend B.3 fake test detection)

**Missing Check**:
- Frontend should have parallel to backend B.2: "frontend tests must import/use actual components"
- Currently no grep pattern to catch `npm test` running zero tests or fake tests

### Gap 4: Request ID Middleware Evidence

**Spec** (`audit_generated_project.sh` L379):
```bash
assert_any_grep "request id usage" "request_id\|correlation_id\|X-Request-ID" "$PROJECT_DIR/backend/app"
```

**Issue**:
- Checks for the string but **NOT** that it's actually used in middleware/routes
- A file with `# TODO: add request_id` would pass
- No verification that request_id is actually added to log context or responses

### Gap 5: Metrics Route Template Validation

**Spec** (L381):
```bash
assert_any_egrep "metrics route template labels" "scope.*route|route\\.path|path_format|APIRoute"
```

**Issue**:
- Grep patterns are vague (e.g., `scope.*route` would match comments)
- No verification that metrics actually use route templates (not URLs)
- No test that verifies high-cardinality URL metrics don't exist

**Better Check**:
- Parse actual metrics output and validate label cardinality
- OR grep for `path_format()` usage in route decorator context

### Gap 6: Database & Redis Readiness Probes

**Spec** (L384-L385):
```bash
assert_any_egrep "database readiness probe" "SELECT[[:space:]]+1|..."
assert_any_egrep "redis readiness probe" "redis.*\\.ping\\(|..."
```

**Issue**:
- Only checks string presence, **NOT** that probes actually work
- A commented-out health check would pass
- No test that `/health/ready` actually fails if DB/Redis unavailable

### Gap 7: Frontend List Controls Binding

**Spec** (F. Frontend List Controls Wired, L193-L213):
- Checks for `<input>` without `onChange|useState|...`
- Checks for `<select>` without state binding

**Implementation**:
- Only scans pages in `src/pages/`
- Misses controls in `src/features/`, `src/components/`
- No verification that state is actually used (e.g., `setKeyword` declared but never passed to API)

**Missing Check**:
- Should verify state binding is **connected to API call** (not just local state)

### Gap 8: Admin Bootstrap Verification

**Spec** (L383):
```bash
assert_any_grep "safe admin bootstrap" "bootstrap\|seed_admin\|INITIAL_ADMIN\|ADMIN_BOOTSTRAP"
```

**Issue**:
- Only checks string presence in codebase
- No test that bootstrap actually works (no script execution)
- No verification that bootstrap is **idempotent** (can run multiple times safely)
- No check that admin credentials are truly initialized to env-var-controlled values

**Missing Test**:
- `check_business_flow.sh` should verify initial admin login works with expected credentials
- Should test bootstrap idempotency

### Gap 9: Token Storage Risk Documentation

**Spec** (L428-L432):
```bash
if grep -R -E -q "localStorage\\.setItem.*token|localStorage\\.getItem.*token"
  if [[ ! -f "$PROJECT_DIR/docs/security-notes.md" ]] || ! grep -q "localStorage" "$PROJECT_DIR/docs/security-notes.md"
    echo "Token localStorage usage requires explicit risk note"
```

**Issue**:
- Only checks for note existence, **NOT** quality/completeness
- A one-word mention of "localStorage" satisfies the check
- No verification of mitigation strategies or refresh token handling

### Gap 10: Dockerfile Non-Root User Verification

**Spec** (L409):
```bash
assert_any_grep "backend Dockerfile non-root runtime user" "^USER[[:space:]][[:space:]]*"
```

**Issue**:
- Regex only checks for presence of `USER` directive
- Could match `# USER app` (commented out)
- No verification that user is actually non-root
- No check in `/verify_project.sh` that containers actually start as non-root

---

## Summary Table: Verification Scope

| Check | Type | Template | Project | Executable | Issue |
|-------|------|----------|---------|------------|-------|
| File structure | Audit | ✅ | — | No | Complete |
| OpenSpec completeness | Audit | ✅ | — | No | Complete |
| Env config keys | Audit | ✅ | — | No | Complete |
| README references | Audit | ✅ | — | No | Complete |
| Pattern detection (request_id, metrics, etc.) | Audit | ✅ | — | No | Vague patterns, no execution |
| Fake frontend scripts | Audit | ✅ | — | No | Complete |
| Dead code | Audit | ✅ | — | No | Limited to 3+ orphans |
| Dockerfile semantics | Audit | ✅ | — | No | No non-root verification |
| Frontend list controls wired | Audit | ✅ | — | No | Only `src/pages/`, misses binding→API |
| Backend tests exist & pass | Verify | — | ✅ | Yes | Complete |
| Backend lint passes | Verify | — | ✅ | Yes | Complete |
| Frontend build succeeds | Verify | — | ✅ | Yes | Complete |
| Frontend lint passes | Verify | — | ✅ | Yes | Complete |
| Frontend tests pass | Verify | — | ✅ | Yes | No fake test detection (Gap 3) |
| OpenAPI export works | Verify | — | ✅ | Yes | Stub export (Gap 1) |
| Docker compose up works | Verify | — | ✅ | Yes | Only with --with-compose-up |
| Health check passes | Verify | — | ✅ | Yes | Only with --with-compose-up |
| Business flow works | Verify | — | ✅ | Yes | Only with --with-compose-up, minimal validation (Gap 2) |
| Database readiness probe works | Verify | — | — | No | No execution verification |
| Redis readiness probe works | Verify | — | — | No | No execution verification |
| Metrics cardinality | Verify | — | — | No | No actual metrics inspection |
| Admin bootstrap idempotent | Verify | — | — | No | No execution verification |

---

## Recommendations for Gap Closure

### High Priority (Production Safety)

1. **Real OpenAPI Export**: Generate shell out to `/openapi.json` endpoint or use proper Python introspection
   - Update `generated/*/scripts/export_openapi.sh`
   - Add schema validation test in CI

2. **Frontend Fake Test Detection**: Add check similar to backend B.2
   - Verify test files import actual component/module files
   - Fail if zero imports found

3. **Request ID & Metrics Execution Verification**:
   - Add runtime check in business flow or health endpoint validation
   - Export metrics endpoint output and validate cardinality

4. **Admin Bootstrap Test**: Include in business flow or startup script
   - Test with env-var-controlled admin creds
   - Verify idempotency

### Medium Priority (Quality)

5. **Database/Redis Probe Execution**: Add health check validation
   - Call `/health/ready` with services up and verify it fails when DB/Redis down
   - Document expected behavior

6. **Frontend List Controls → API Binding**: Enhance frontend-list-controls-wired check
   - Verify state is passed to API call, not just declared
   - Or add runtime test in business flow

7. **Metrics Cardinality Test**: Add metrics endpoint inspection
   - Export and parse `/metrics`, validate no high-cardinality path labels
   - Could be part of business flow or separate script

### Lower Priority (Documentation)

8. **Token Storage Risk Completeness**: 
   - Enhance check to validate risk + mitigation strategy documented
   - Check for refresh token strategy explanation

9. **Dockerfile Security Validation**:
   - Verify actual runtime user via `docker inspect`
   - Check CSP localhost hardcoding

