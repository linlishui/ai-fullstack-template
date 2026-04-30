# Template Project Driver Workflow Map

Use this file as the source-of-truth map for the current repository when running the template generation workflow.

Run the workflow as a senior fullstack architect, production delivery owner, and strict reviewer. The generated project should be a standalone, runnable, verifiable, maintainable, near-production engineering package within the current requirement scope.

Main business-loop correctness outranks peripheral asset volume. Nginx, CI, docs, metrics, tracing hooks, and dashboards are useful only when they support real persistence, real API wiring, real frontend actions, permissions, state transitions, and executable validation.

## Core Inputs

- `requirements/requirement.md`
  - Primary business requirement input.
  - Stop and flag the issue if this file is still the default template.

## Control Documents

- `AGENTS.md`
  - Repository-level AI rules.
  - Enforces OpenSpec-first generation, project output location, backend and frontend structure, env handling, and verification expectations.
- `CLAUDE.md`
  - Claude Code project context and dual-runtime skill invocation guidance.
- `README.md`
  - High-level workflow, output structure, and operator-facing usage.
- `docs/ai-workflow.md`
  - Defines the staged generation sequence and quality gates.
- `docs/generation-quality.md`
  - Defines main-loop priority, validation minimums, and typical high-risk failures.
- `docs/template-governance.md`
  - Defines rule-source priority, generated asset responsibilities, and anti-duplication boundaries.
- `docs/concurrent-generation.md`
  - Defines safe post-OpenSpec parallel generation, file ownership, shared contracts, and integration barriers.
- `docs/production-grade-rubric.md`
  - Converts strict fullstack review scoring into hard generation and verification gates.
- `docs/fullstack-review-scoring.md`
  - Maps the 120-point fullstack reviewer rubric to generation priorities and one-vote-fail examples.
  - Defines tiered quality requirements: non-negotiable gates, default production enhancements, and on-demand extensions.

## Backend, Testing, And Deployment Guidance

Read these before generating non-trivial backend, verification, or runtime work:

- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/deployment-spec.md`
- `docs/production-grade-rubric.md`

Use them as the primary rule sources for:

- backend layering, contracts, security, data consistency, migrations, and health checks
- test coverage priorities, key business-action regression, and verification gates
- compose structure, Dockerfiles, Nginx, CI assets, environment variables, startup flow, and runtime validation
- production-grade security, rate limiting, metrics, OpenAPI export, Docker ignore files, frontend tests, and business-flow script requirements
- real persistence requirements: core business APIs must use database-backed services/repositories, not in-memory stores or unused model/migration scaffolding
- real observability/runtime requirements: readiness probes must check database/Redis, metrics labels must avoid raw URL paths, backend containers must run as non-root
- project-level `security-notes.md`, `observability.md`, and `test-plan.md` content that must match code, config, tests, and CI

Generated project docs should be project-specific evidence indexes. Do not copy long sections from template docs into `generated/<project-slug>/docs/`; record status, paths, commands, and risks instead.

## Frontend Guidance

Read these before generating non-trivial frontend work:

- `docs/frontend-ui-spec.md`
- `docs/design-tokens.md`
- `docs/component-patterns.md`
- `docs/frontend-anti-patterns.md`

Use `docs/frontend-ui-spec.md` as the main frontend rule source, then use the others to shape theme tokens, interaction patterns, and visual expression.

Core frontend workflows must be wired to real API clients, TanStack Query mutations, or typed domain hooks. `setTimeout`, static success toasts, hardcoded stats/categories, local fake admin decisions, or module-only token state do not count as complete implementation.

## Prompt Entry Points

- `prompts/00-generate-from-requirement.md`
  - Main orchestration prompt.
  - Enforces: read requirement, analyze, initialize `generated/<project-slug>/`, produce OpenSpec, generate backend, frontend, deployment, and tests, then self-check.
- `prompts/01-analyze-requirement.md`
  - Requirement analysis stage. Required by: core.md Stage 1.
- `prompts/02-generate-openspec.md`
  - OpenSpec generation stage. Required by: core.md Stage 2.
- `docs/concurrent-generation.md`
  - Read after OpenSpec and before parallel backend/frontend/runtime/test work.
- `prompts/03-generate-backend.md`
  - Backend generation stage. Required by: core.md Stage 4.
  - Read together with `docs/backend-spec.md`, `docs/testing-spec.md`, `docs/deployment-spec.md`, and `docs/production-grade-rubric.md`.
- `prompts/04-generate-frontend.md`
  - Frontend generation stage. Required by: core.md Stage 5.
- `prompts/05-generate-docker.md`
  - Compose and deployment stage. Required by: core.md Stage 6.
  - Read together with `docs/deployment-spec.md`, `docs/backend-spec.md`, `docs/testing-spec.md`, and `docs/production-grade-rubric.md`.
- `prompts/06-generate-tests.md`
  - Test generation stage. Required by: core.md Stage 6.
  - Read together with `docs/testing-spec.md`, `docs/backend-spec.md`, `docs/frontend-ui-spec.md`, `docs/deployment-spec.md`, and `docs/production-grade-rubric.md`.
- `prompts/07-fix-and-verify.md`
  - Repair and verification stage.
  - Cross-check against backend, testing, deployment, and frontend spec entrypoints before final handoff.
- `prompts/08-security-review.md`
  - Security review stage.
  - Run after initial generation and before final repair/verification for projects with auth, authorization, token, cookie, CSRF, rate-limit, CORS, admin bootstrap, logging, or other production security gates.

## Script Entry Points

- `scripts/audit_generated_project.sh generated/<project-slug>`
  - Checks required project-level files, directories, OpenSpec paths, review checklists, security/observability/test-plan docs, env keys, CI/Nginx assets, README verification command references, and production-grade gates.
- `scripts/verify_project.sh generated/<project-slug>`
  - Runs template audit, `docker compose config`, backend `pytest`, backend `ruff check .`, frontend `npm run build`, frontend `npm run lint`, frontend tests, and OpenAPI export.
- `scripts/verify_project.sh generated/<project-slug> --with-compose-up`
  - Adds `docker compose up --build -d` and runs `generated/<project-slug>/scripts/check_business_flow.sh` when present.
- `scripts/check_prerequisites.sh`
  - Local toolchain preflight.
- `scripts/clean_generated.sh`
  - Cleanup helper for generated artifacts.

## Required Generated Project Shape

Every generated business project must stay under:

```text
generated/<project-slug>/
```

Minimum structure:

```text
generated/<project-slug>/
  README.md
  AGENTS.md
  CLAUDE.md
  .gitignore
  .env.example
  compose.yaml
  .gitlab-ci.yml
  requirements/
  docs/
  scripts/
  openspec/
  backend/
  frontend/
  infra/nginx/
  .github/workflows/
  .claude/skills/find-skills/
```

Minimum synchronized project context:

- `requirements/requirement.md`
- `docs/architecture.md`
- `docs/development.md`
- `docs/key-business-actions-checklist.md`
- `docs/frontend-ui-checklist.md`
- `docs/production-readiness-checklist.md`
- `docs/security-notes.md`
- `docs/observability.md`
- `docs/test-plan.md`
- `docs/ai-workflow.md`
- `docs/parallel-execution-plan.md`
- `docs/review-log.md`
- `docs/fix-log.md`
- `openspec/project.md`
- `openspec/specs/<capability>/spec.md`
- `openspec/changes/<change-id>/proposal.md`
- `openspec/changes/<change-id>/design.md`
- `openspec/changes/<change-id>/tasks.md`

## Minimum Verification Bar

Do not call the generated project complete unless the flow targets these checks:

```bash
读取并执行 prompts/08-security-review.md
读取并执行 prompts/07-fix-and-verify.md
./scripts/audit_generated_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug>
```

Add this when startup and business checks matter:

```bash
./scripts/verify_project.sh generated/<project-slug> --with-compose-up
```

At the project level, README should also expose:

- `docker compose config`
- `docker compose up --build`
- backend `pytest`
- backend `ruff check`
- frontend `npm run build`
- frontend `npm run lint`
- frontend `npm test -- --run`
- `scripts/export_openapi.sh`
- `scripts/check_business_flow.sh`

## Common Failure Patterns

- Skipping OpenSpec and jumping directly into code
- Writing business implementation outside `generated/<project-slug>/`
- Leaving project-level docs, env example, or helper scripts incomplete
- Omitting CI workflow, Nginx assets, or production-readiness checklist while claiming production-grade output
- Generating only GitHub Actions CI without the corresponding `.gitlab-ci.yml`, or vice versa
- Omitting `.claude/skills/find-skills/` from the generated project, leaving the standalone project without skill discovery capability
- Omitting project-level AI rules and review/fix trace files, leaving the standalone project without AI collaboration context
- Building UI without required loading, empty, error, or submitting feedback
- Claiming a workflow is complete while the UI only uses `setTimeout`, static toast, hardcoded stats/categories, or local fake data
- Providing login/register endpoints without a frontend session layer, logout, 401/refresh behavior, or matching security notes
- Generating frontend code without ErrorBoundary, route lazy loading, or unified HTTP error handling
- Generating backend code without spec-driven module boundaries, migration discipline, or resource-level authorization
- Generating models/migrations/repositories while the production routes still use `MemoryStore`, module globals, JSON files, or other fake persistence
- Shipping backend code without unified responses, global exception handling, pagination, or dependency-aware health checks
- Shipping backend code without rate limiting, request id logging, metrics, OpenAPI export, or safe administrator bootstrap
- Returning static readiness such as `database: configured` instead of probing DB/Redis, or labeling metrics with raw `request.url.path`
- Letting SQLAlchemy async lazy loading happen during response serialization
- Shipping frontend auth with long-lived localStorage tokens and no security notes
- Omitting `.dockerignore`, gzip, proxy timeout, non-root backend runtime user, frontend lockfile, or dependency audit/reporting
- Treating tests as optional after build passes, or skipping project-level business-flow regression
- Shipping compose files without complete env examples, health checks, or startup instructions
- Overbuilding authentication when auth is not the requirement's main loop
- Passing static build checks while main business actions still cannot be executed
- Running parallel work before OpenSpec is stable, or letting parallel tasks modify shared files without a documented owner and integration pass
- Shipping README, .env.example, or verification commands that were written before implementation and never reconciled with the final generated content
- Skipping business-loop self-check and declaring the project complete based only on build and lint passing
