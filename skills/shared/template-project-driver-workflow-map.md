# Template Project Driver Workflow Map

Use this file as the source-of-truth map for the current repository when running the template generation workflow.

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

## Backend, Testing, And Deployment Guidance

Read these before generating non-trivial backend, verification, or runtime work:

- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/deployment-spec.md`

Use them as the primary rule sources for:

- backend layering, contracts, security, data consistency, migrations, and health checks
- test coverage priorities, key business-action regression, and verification gates
- compose structure, Dockerfiles, Nginx, CI assets, environment variables, startup flow, and runtime validation

## Frontend Guidance

Read these before generating non-trivial frontend work:

- `docs/frontend-ui-spec.md`
- `docs/design-tokens.md`
- `docs/component-patterns.md`
- `docs/frontend-anti-patterns.md`

Use `docs/frontend-ui-spec.md` as the main frontend rule source, then use the others to shape theme tokens, interaction patterns, and visual expression.

## Prompt Entry Points

- `prompts/00-generate-from-requirement.md`
  - Main orchestration prompt.
  - Enforces: read requirement, analyze, initialize `generated/<project-slug>/`, produce OpenSpec, generate backend, frontend, deployment, and tests, then self-check.
- `prompts/01-analyze-requirement.md`
  - Requirement analysis stage.
- `prompts/02-generate-openspec.md`
  - OpenSpec generation stage.
- `prompts/03-generate-backend.md`
  - Backend generation stage.
  - Read together with `docs/backend-spec.md`, `docs/testing-spec.md`, and `docs/deployment-spec.md`.
- `prompts/04-generate-frontend.md`
  - Frontend generation stage.
- `prompts/05-generate-docker.md`
  - Compose and deployment stage.
  - Read together with `docs/deployment-spec.md`, `docs/backend-spec.md`, and `docs/testing-spec.md`.
- `prompts/06-generate-tests.md`
  - Test generation stage.
  - Read together with `docs/testing-spec.md`, `docs/backend-spec.md`, `docs/frontend-ui-spec.md`, and `docs/deployment-spec.md`.
- `prompts/07-fix-and-verify.md`
  - Repair and verification stage.
  - Cross-check against backend, testing, deployment, and frontend spec entrypoints before final handoff.
- `prompts/08-security-review.md`
  - Security review stage.

## Script Entry Points

- `scripts/audit_generated_project.sh generated/<project-slug>`
  - Checks required project-level files, directories, OpenSpec paths, review checklists, env keys, CI/Nginx assets, and README verification command references.
- `scripts/verify_project.sh generated/<project-slug>`
  - Runs `docker compose config`, backend `pytest`, backend `ruff check .`, frontend `npm run build`, and frontend `npm run lint`.
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
  requirements/
  docs/
  scripts/
  openspec/
  backend/
  frontend/
  infra/nginx/
  .github/workflows/
```

Minimum synchronized project context:

- `requirements/requirement.md`
- `docs/architecture.md`
- `docs/development.md`
- `docs/key-business-actions-checklist.md`
- `docs/frontend-ui-checklist.md`
- `docs/production-readiness-checklist.md`
- `docs/ai-workflow.md`
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

## Common Failure Patterns

- Skipping OpenSpec and jumping directly into code
- Writing business implementation outside `generated/<project-slug>/`
- Leaving project-level docs, env example, or helper scripts incomplete
- Omitting CI workflow, Nginx assets, or production-readiness checklist while claiming production-grade output
- Omitting project-level AI rules and review/fix trace files, leaving the standalone project without AI collaboration context
- Building UI without required loading, empty, error, or submitting feedback
- Generating frontend code without ErrorBoundary, route lazy loading, or unified HTTP error handling
- Generating backend code without spec-driven module boundaries, migration discipline, or resource-level authorization
- Shipping backend code without unified responses, global exception handling, pagination, or dependency-aware health checks
- Treating tests as optional after build passes, or skipping project-level business-flow regression
- Shipping compose files without complete env examples, health checks, or startup instructions
- Overbuilding authentication when auth is not the requirement's main loop
- Passing static build checks while main business actions still cannot be executed
