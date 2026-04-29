# Template Project Driver Core

This file is the shared workflow contract for the `template-project-driver` skill across both Codex and Claude Code. Platform-specific skill entries must read this file first and must not weaken its rules.

## Purpose

Treat this skill as the control layer for the current template repository, not as a generic app builder.

Operate as a senior fullstack architect, production delivery owner, and strict reviewer. The goal is not to generate a demo; it is to deliver a standalone fullstack project that is runnable, verifiable, maintainable, and close to production quality within the current requirement scope.

Prioritize the main business loop over peripheral production assets. Do not spend the main implementation budget on Nginx, CI, docs, dashboards, or observability placeholders while the core role actions, state transitions, permissions, persistence, API integration, and tests remain incomplete.

Use it when the task is to manage or execute the repository's end-to-end generation flow from business requirement to generated fullstack project, including:

- reading `requirements/requirement.md`
- producing OpenSpec before implementation
- creating `generated/<project-slug>/` as a standalone project package
- coordinating backend, frontend, deployment, and tests
- enforcing template-level audit plus project-level verification

## Required Inputs

Read these before generating anything substantial:

1. `requirements/requirement.md`
2. `AGENTS.md`
3. `README.md`
4. `docs/ai-workflow.md`
5. `docs/generation-quality.md`
6. `docs/template-governance.md`
7. `docs/production-grade-rubric.md`
8. `docs/fullstack-review-scoring.md`

Read phase-specific specifications when entering that phase instead of loading every detailed rule up front:

- Backend: `docs/backend-spec.md`
- Frontend: `docs/frontend-ui-spec.md`
- Testing: `docs/testing-spec.md`
- Deployment: `docs/deployment-spec.md`

Also read the shared workflow map at `skills/shared/template-project-driver-workflow-map.md` when exact source-of-truth paths, stage mapping, or validation commands are needed.

## Workflow Contract

1. Read `requirements/requirement.md` first.
2. Refuse to jump directly into full business code when the requirement is still a blank template or misses critical business information.
3. Record assumptions and pending confirmations instead of silently inventing scope.
4. Derive a stable `project-slug` using lowercase letters, digits, and hyphens. Prefer an explicit project English name or system identifier from the requirement.
5. Initialize `generated/<project-slug>/` before implementation.
6. Generate OpenSpec in `generated/<project-slug>/openspec/` before writing backend or frontend business code.
7. Synchronize project-level context into `generated/<project-slug>/requirements/`, `docs/`, `scripts/`, and `openspec/`.
8. Generate implementation into `generated/<project-slug>/` only. Do not scatter business code into the repository root.
9. Treat production-grade review items as default requirements, not optional polish, especially for observability, security, frontend resilience, Nginx, Docker, tests, OpenAPI, rate limiting, and CI assets.
10. Apply quality requirements in three tiers:
    - Non-negotiable gates: OpenSpec-first, real business loop, DB-backed persistence, real frontend API/mutation actions, auth/authz/input validation, executable tests, and template audit.
    - Default production enhancements: rate limiting, request id, logs, metrics, tracing extension point, Nginx, Docker, CI, OpenAPI, and project-level security/observability/test docs.
    - On-demand extensions: complex auth UX, background workers, complex caching, BI dashboards, fine-grained permission matrices, and multi-tenancy only when the requirement or risk profile needs them.
11. Run `prompts/08-security-review.md` after generation and before final verification when the project includes auth, authorization, tokens, cookies, CSRF, admin bootstrap, rate limiting, CORS, logging, or other production security gates.
12. Run `prompts/07-fix-and-verify.md` to repair findings from security review, build, tests, lint, OpenAPI export, Compose, business-flow checks, and template audit.
13. Run template-level audit and project-level verification after generation and repair.
14. Fix obvious failures before stopping.
15. Keep generated project documentation evidence-led and concise. Do not copy long template rules into generated docs; record project facts, evidence paths, verification commands, status, and risks.
16. Report the final output directory, what was validated, and what risks or assumptions remain.

## Required Generated Project Shape

Initialize and keep this minimum structure:

```text
generated/<project-slug>/
  README.md
  AGENTS.md
  CLAUDE.md
  .gitignore
  .env.example
  compose.yaml
  requirements/
  docs/
  scripts/
  openspec/
  backend/
  frontend/
  infra/nginx/
  .github/workflows/
```

## Non-Negotiable Rules

- Generate OpenSpec before full implementation.
- Keep all business output inside `generated/<project-slug>/`.
- Treat the generated directory as a standalone engineering package, not a loose dump of files.
- Pull all secrets and runtime configuration from environment variables.
- Keep backend and frontend modular. Do not collapse the system into `main.py` or `App.tsx`.
- Generate verification artifacts together with implementation: tests, README commands, `.env.example`, and any project-level helper scripts.
- Generate production-grade artifacts together with implementation: rate limiting, request id logging, metrics, OpenAPI export, Docker ignore files, frontend tests, safe admin bootstrap, security notes, observability notes, and test plan.
- Core backend routes must use real SQLAlchemy-backed persistence through services/repositories. Do not use `MemoryStore`, process-global dict/list state, JSON files, or other in-memory stores for users, core business entities, workflow states, install/review actions, or statistics in production code.
- Core frontend actions must call real API clients, TanStack Query mutations, or typed domain hooks. Do not use `setTimeout`, static success toasts, hardcoded stats/categories, or local fake data to claim create/review/install/publish/audit workflows are complete.
- Readiness must probe database and Redis, metrics labels must avoid raw `request.url.path`, backend runtime containers must run as non-root, and generated frontends must include a standard `index.html` plus a lockfile.
- Generate review-oriented checklists together with implementation: `docs/key-business-actions-checklist.md`, `docs/frontend-ui-checklist.md`, `docs/production-readiness-checklist.md`, `docs/security-notes.md`, `docs/observability.md`, and `docs/test-plan.md`.
- Keep review-oriented checklists as evidence indexes, not duplicated rulebooks. Each item should name status, code/config/test/script evidence, and remaining risk.
- Generate project-level AI collaboration assets together with implementation: `AGENTS.md`, `CLAUDE.md`, `docs/ai-workflow.md`, `docs/review-log.md`, and `docs/fix-log.md`.
- Prefer minimal authentication when auth is only a supporting capability rather than the business core.
- Validate key business actions from the actual requirement, not from a fixed demo checklist.

## Stage Breakdown

### Stage 1: Analyze Requirement

- Extract project goal, user roles, modules, pages, entities, permissions, workflows, exception cases, and non-functional requirements.
- Identify the main business loop and the 3-5 highest-value business actions.
- Distinguish core workflow from support capabilities such as login or admin scaffolding.

### Stage 2: Produce OpenSpec

- Create `openspec/project.md`.
- Create at least one capability spec at `openspec/specs/<capability>/spec.md`.
- Create a change set under `openspec/changes/<change-id>/` with `proposal.md`, `design.md`, and `tasks.md`.
- Cover interfaces, data models, permissions, validation, module boundaries, and task breakdown.

### Stage 3: Generate Project Context

- Write project `README.md` that matches the actual generated structure.
- Write `.gitignore` with runtime and build ignores only.
- Write `.env.example` with backend, frontend, MySQL, Redis, JWT, refresh-token, CORS, cookie-security, and port-related keys as needed.
- Include rate-limit, metrics/tracing, bootstrap/seed, and secure cookie environment keys where applicable.
- Create `docs/architecture.md`, `docs/development.md`, `docs/key-business-actions-checklist.md`, `docs/frontend-ui-checklist.md`, `docs/production-readiness-checklist.md`, `docs/security-notes.md`, `docs/observability.md`, and `docs/test-plan.md`.
- Create project-level AI context files `AGENTS.md`, `CLAUDE.md`, `docs/ai-workflow.md`, `docs/review-log.md`, and `docs/fix-log.md`.
- Write generated docs as compact project-specific evidence. Avoid duplicating generic template rules; reference the generated project's own files, commands, and known risks.
- Add project-level scripts when validation or cleanup needs a stable entrypoint.

### Stage 4: Generate Backend

- Use `FastAPI + Pydantic v2 + SQLAlchemy 2.x async + Alembic`.
- Treat `docs/backend-spec.md` as the backend source of truth for layering, contracts, security, migrations, health checks, and verification expectations.
- Organize backend into clear modules such as `api/`, `core/`, `db/`, `models/`, `repositories/`, `schemas/`, `services/`, and `tests/`.
- Keep configuration, auth, persistence, and route handling separated.
- Default to versioned APIs, unified response structures, global exception handling, pagination, structured logging, dependency-aware health checks, and observability hooks.
- Default to request id middleware, Redis-backed rate limiting, safe admin bootstrap/seed scripts, OpenAPI export, real metrics, and async-safe DTO serialization.
- Implement real dependency-aware readiness checks. Do not return static states such as `database: configured`.
- Use route templates or similarly low-cardinality values for metrics path labels. Do not label metrics with raw request URLs.
- Prefer FastAPI lifespan for startup/shutdown hooks.
- Do not implement administrator promotion through email prefixes, fixed usernames, or frontend-only controls.
- Read settings from environment variables only.

### Stage 5: Generate Frontend

- Use `React + TypeScript + Vite`.
- Organize code into `app/`, `api/`, `components/`, `features/`, `hooks/`, `pages/`, `schemas/`, or equivalent modular structure.
- Prefer `TanStack Query`, `React Hook Form`, and `Zod`.
- Treat `docs/frontend-ui-spec.md` as the frontend source of truth. Read it first, then follow its referenced detailed documents such as `docs/design-tokens.md`, `docs/component-patterns.md`, and `docs/frontend-anti-patterns.md` as needed.
- Default to a unified HTTP layer, route-level lazy loading, ErrorBoundary coverage, and explicit unauthorized or blocked-action feedback.
- Add AuthContext/auth store or equivalent session handling when login/register exists, including logout and 401/refresh behavior.
- Ensure marketplace, detail, workspace, admin, install/review/publish, and stats views are driven by real API data or explicitly marked unavailable/open.
- Ensure loading, empty, error, disabled, submitting, and success states exist.
- Add frontend tests or smoke checks for at least one critical page/form/state.
- Do not default to long-lived localStorage token storage without explicit security notes and mitigation.
- Keep responsive behavior and visual hierarchy intentional; avoid placeholder-grade UI.

### Stage 6: Generate Deployment And Tests

- Treat `docs/deployment-spec.md` as the deployment and runtime source of truth.
- Treat `docs/testing-spec.md` as the testing and regression source of truth.
- Create `compose.yaml` for at least `nginx`, `frontend`, `backend`, `mysql`, and `redis`.
- Provide backend tests, `ruff check`, frontend build, and frontend lint support.
- Provide backend tests with coverage command, frontend tests, OpenAPI export check, and dependency audit/report support in local scripts and CI.
- Ensure `.env.example`, Dockerfiles, Nginx config, CI workflow, health checks, startup instructions, and key business-action validation paths align with those specs.
- Generate backend/frontend `.dockerignore`; Nginx must include gzip, security headers, and proxy timeout.
- Add `scripts/check_business_flow.sh` when the requirement defines business actions that can be asserted after startup.
- Business-flow scripts must be self-contained, repeatable, and not require manually supplied admin tokens.

### Stage 7: Security Review, Repair, And Verify

- Read and apply `prompts/08-security-review.md` before final handoff for production security review.
- Read and apply `prompts/07-fix-and-verify.md` after generation or after any security/review/test failure.
- Run `./scripts/audit_generated_project.sh generated/<project-slug>` for template-level completeness.
- Run `./scripts/verify_project.sh generated/<project-slug>` for executable validation, including frontend tests and OpenAPI export.
- Use `./scripts/verify_project.sh generated/<project-slug> --with-compose-up` when container startup and project business-flow checks should be exercised.
- Fix clear breakages before handoff.

## Repository Entry Points

- `prompts/00-generate-from-requirement.md` is the orchestration prompt for full-flow generation.
- `prompts/08-security-review.md` is the security review prompt and should run before final verification for production-grade generated projects.
- `prompts/07-fix-and-verify.md` is the repair and verification prompt.
- `scripts/audit_generated_project.sh` checks structure, spec, README, env completeness, security/observability/test-plan docs, CI gates, and production-grade code/config evidence.
- `scripts/verify_project.sh` checks template audit, compose, backend tests/lint, frontend build/lint/tests, OpenAPI export, and optional business-flow execution.

## Final Reporting

When finishing work with this skill, always state:

- the chosen `project-slug`
- the final generated directory
- whether OpenSpec was produced before code generation
- which audit and verification commands were run
- which key business actions were captured in `docs/key-business-actions-checklist.md`
- which frontend and production-readiness checklist items remain open
- any remaining assumption, risk, or manual follow-up
