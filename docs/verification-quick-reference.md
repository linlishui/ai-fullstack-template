# Verification Pipeline Quick Reference

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  VERIFICATION PIPELINE LAYERS                   │
└─────────────────────────────────────────────────────────────────┘

Layer 1: TEMPLATE AUDIT (No execution required)
├─ ./scripts/audit_generated_project.sh <project>
├─ Checks: Structure, config keys, patterns, forbidden content
├─ Runtime: ~2-5 seconds (grep/find only)
└─ Exit: YES (fails fast on missing files or patterns)

Layer 2: PROJECT VERIFICATION (Execution required)
├─ ./scripts/verify_project.sh <project> [--with-compose-up]
├─ Checks: Tests pass, lint passes, build succeeds, quality gates
├─ Runtime: ~2-5 minutes (without compose up)
│          ~5-10 minutes (with compose up + health check)
└─ Exit: YES (fails on test/lint/build failure)

Layer 3: PROJECT SCRIPTS (Project-specific)
├─ ./generated/<slug>/scripts/verify_all.sh
├─ ./generated/<slug>/scripts/export_openapi.sh
├─ ./generated/<slug>/scripts/check_business_flow.sh
├─ Runtime: Varies by script
└─ Exit: YES (for error conditions)
```

## Execution Command Reference

### Pre-Verification
```bash
# 1. Check prerequisites (docker, python3, node, npm)
./scripts/check_prerequisites.sh
```

### Template-Level Verification (REQUIRED FIRST)
```bash
# 2. Audit project structure, config, patterns
./scripts/audit_generated_project.sh generated/<project-slug>
```

### Project-Level Verification (AFTER TEMPLATE PASSES)
```bash
# 3a. Verify without starting services (default)
./scripts/verify_project.sh generated/<project-slug>

# 3b. Verify WITH starting services (includes business flow)
./scripts/verify_project.sh generated/<project-slug> --with-compose-up
```

### Project-Level Convenience
```bash
# 4a. Project's one-shot verification (no compose up)
cd generated/<project-slug>
./scripts/verify_all.sh

# 4b. Export OpenAPI schema
./scripts/export_openapi.sh

# 4c. End-to-end business flow (requires services running)
./scripts/check_business_flow.sh
```

## What Each Layer Checks

### Layer 1: TEMPLATE AUDIT (~16 categories)

| Category | Checks | Fails On |
|----------|--------|----------|
| **File Structure** | 14 required dirs/files | Missing any |
| **OpenSpec** | project.md, specs/*/spec.md, changes/*/proposal/design/tasks.md | Incomplete spec |
| **Documentation** | 11 required docs files | Missing docs |
| **Backend Core** | pyproject.toml, alembic.ini, app/main.py, Dockerfile | Missing files |
| **Backend Modules** | Request ID, metrics, rate limit, security, health, error handling | Missing modules |
| **Frontend Core** | package.json, Dockerfile, index.html, vite.config.ts, lockfile | Missing files |
| **Configuration** | JWT_SECRET, DATABASE_URL, REDIS_URL, CORS, rate limit, VITE_API_BASE_URL | Missing env vars |
| **README References** | All verification commands documented | Missing docs |
| **Implementation Evidence (grep)** | request_id, metrics, /metrics, rate limit, bootstrap, health probes | No code patterns |
| **Nginx Security** | gzip enabled, security headers | Missing config |
| **CI Workflow** | compose config, pytest, ruff, npm lint/build/test, openapi, audit | Incomplete CI |
| **Security Docs** | Admin bootstrap, rate limiting | Missing notes |
| **Observability Docs** | Request ID, metrics | Missing docs |
| **Test Plan Docs** | Auth failures, authorization failures, frontend tests | Missing docs |
| **Frontend HTML** | DOCTYPE, lang attr, charset, viewport, title | Invalid HTML |
| **Docker Security** | Non-root USER in backend | Missing USER |
| **Forbidden Patterns** | MemoryStore, @app.on_event, fake async, implicit admin | Found forbidden |
| **Script Quality (C)** | build/lint/test call real tools | Fake tools |
| **Dead Code (D)** | <4 orphan files in backend/frontend | >3 orphans |
| **Dockerfile Semantics (E)** | Frontend has npm install, backend uses pyproject | Invalid Dockerfile |
| **List Controls Wired (F)** | Input/select has state binding | Unbound controls |
| **API Responses (G)** | At least one route uses response_model | No response_model |

### Layer 2: PROJECT VERIFICATION (~8 checks)

| Check | What | Fails On |
|-------|------|----------|
| **Prerequisites** | docker, python3, node, npm, docker compose | Missing tool |
| **Compose Config** | YAML syntax, service definitions | Invalid compose.yaml |
| **Compose Up** | Services start, containers build | Build/start failure |
| **Health Check** | `/api/v1/health/ready` responds | Timeout or 5xx error |
| **Backend Tests** | pytest pass, ≥8 tests, all import app module | <8 tests OR fake tests |
| **Backend Lint** | ruff check . passes | Lint errors |
| **Frontend Build** | npm run build creates dist/ with JS | Build failure OR no dist |
| **Frontend Lint** | npm run lint passes | Lint errors |
| **Frontend Tests** | npm test passes (if script exists) | Test failure OR missing test |
| **OpenAPI Export** | scripts/export_openapi.sh OR backend/scripts/export_openapi.py | Missing both |
| **Business Flow** | scripts/check_business_flow.sh completes (if exists, only with --with-compose-up) | Flow failure |

### Layer 3: PROJECT SCRIPTS (Varies)

| Script | When | Checks |
|--------|------|--------|
| **verify_all.sh** | Anytime | Compose config, backend tests/lint, frontend build/lint/test, openapi export |
| **export_openapi.sh** | Anytime (but should extract from running app) | OpenAPI schema generation |
| **check_business_flow.sh** | Only with services running | Happy path: auth → create → approve → install → review → version → delist |

## Template-Level vs Project-Level Distinction

### TEMPLATE-LEVEL (Layer 1)
- **What**: Structural + configuration + pattern detection
- **When**: Immediately after generation
- **Dependencies**: None (grep, find only)
- **Fail reason**: Generation incomplete or misconfigured
- **Script**: `audit_generated_project.sh`
- **Example fails**:
  - Missing `docs/architecture.md`
  - No OpenSpec specs/*/spec.md files
  - No `JWT_SECRET_KEY` in .env.example
  - `npm run build` script calls `echo "building"`
  - `localStorage.setItem('token'...)` without security doc

### PROJECT-LEVEL (Layer 2)
- **What**: Executable quality + test coverage + artifact validation
- **When**: After template audit passes
- **Dependencies**: docker, python3, node, npm installed
- **Fail reason**: Code quality issues, failing tests/lint, runtime errors
- **Script**: `verify_project.sh`
- **Example fails**:
  - pytest has only 5 tests (<8 minimum)
  - ruff lint errors
  - npm build fails
  - `dist/` not created
  - Health endpoint doesn't respond

## Gaps (10 Known Issues)

| Gap | Issue | Impact | Fix |
|-----|-------|--------|-----|
| **1** | `export_openapi.sh` is hardcoded stub, not real extraction | Schema doesn't reflect actual API | Extract from `/openapi.json` endpoint or use Python introspection |
| **2** | Business flow test has minimal validation | Doesn't catch wrong response fields | Add response field verification |
| **3** | Frontend tests not checked for fake tests (like backend B.2) | Empty tests could pass | Add import check for component/module files |
| **4** | Request ID grep only checks string presence | Could be commented-out code | Add runtime verification (middleware must add to logs) |
| **5** | Metrics route template grep patterns are vague | Could match comments | Parse actual metrics output for cardinality |
| **6** | Database/Redis readiness probes only checked for string | Could be commented-out | Add health check test that fails DB/Redis down |
| **7** | Frontend list controls only checked in `src/pages/` | Misses `src/features/` and binding→API | Extend scan paths and verify API call |
| **8** | Admin bootstrap only checked for string | Could be unused code | Add business flow verification of admin login |
| **9** | Token localStorage risk doc only checked for mention | Could be one word | Verify risk + mitigation strategy documented |
| **10** | Dockerfile USER only checked for presence | Could be commented out | Verify actual runtime user via `docker inspect` |

## CI/CD Integration

### GitHub Actions Workflow (`.github/workflows/ci.yml`)
```yaml
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - uses: actions/setup-node@v4
      - run: docker compose config --env-file .env.example
      - run: python -m pip install -e ".[dev]"  # backend
      - run: pytest --cov=app
      - run: ruff check .
      - run: npm ci --ignore-scripts  # frontend
      - run: npm run lint
      - run: npm run build
      - run: npm test -- --run
      - run: ./scripts/export_openapi.sh
      - run: npm audit --audit-level=high
      - run: pip-audit
```

**CI Coverage**:
- ✅ Compose config validation
- ✅ Backend pytest with coverage
- ✅ Backend ruff lint
- ✅ Frontend lint & build
- ✅ Frontend tests
- ✅ OpenAPI export
- ✅ Dependency audit (npm + pip)
- ❌ Health check endpoint
- ❌ Business flow (no docker compose up)

## Common Issues & Diagnostics

### "audit_generated_project.sh fails"
**Check these first**:
```bash
# Missing file?
find generated/<slug> -name "README.md" -o -name "AGENTS.md" -o -name "CLAUDE.md"

# Missing env key?
grep JWT_SECRET_KEY generated/<slug>/.env.example

# Pattern issue?
grep -r "request_id" generated/<slug>/backend/app
grep -r "response_model" generated/<slug>/backend/app
```

### "verify_project.sh fails on backend tests"
**Check these**:
```bash
cd generated/<slug>/backend
# Count tests
find tests -name "test_*.py" -exec grep -l "^def test_\|^async def test_" {} \; | wc -l

# Check for fake tests
grep -L "^from app\|^import app" tests/test_*.py
```

### "verify_project.sh fails on frontend build"
**Check these**:
```bash
cd generated/<slug>/frontend
# Check build script
grep "\"build\"" package.json

# Check for real tool
npm run build 2>&1 | grep -i "vite\|webpack\|esbuild"
```

### "Business flow check fails"
**Debug with**:
```bash
cd generated/<slug>
docker compose --env-file .env.example up -d

# Wait for health
curl -v http://localhost:8080/api/v1/health/ready

# Manual business flow steps
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@example.com","password":"ChangeMeAdminPassword123!"}'
```

## Recommended Verification Order

```
1. ./scripts/check_prerequisites.sh
   ↓
2. ./scripts/audit_generated_project.sh generated/<slug>
   ↓ (if PASS)
3. ./scripts/verify_project.sh generated/<slug>
   ↓ (if PASS and services needed)
4. ./scripts/verify_project.sh generated/<slug> --with-compose-up
   ↓ (if PASS)
5. cd generated/<slug> && ./scripts/check_business_flow.sh
```

## Environment Variables

### For Verification Scripts
```bash
BASE_URL=http://localhost:8080      # Health check & business flow endpoint (default shown)
INITIAL_ADMIN_EMAIL=admin@example.com
INITIAL_ADMIN_PASSWORD=ChangeMeAdminPassword123!
```

### For Generated Project
```bash
# Required in .env.example and docker environment
JWT_SECRET_KEY=<32+ byte key>
JWT_REFRESH_SECRET_KEY=<32+ byte key>
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
CORS_ALLOW_ORIGINS=localhost:3000
COOKIE_SECURE=true
RATE_LIMIT=100/hour
VITE_API_BASE_URL=http://localhost:8080
```

