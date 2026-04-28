# Template Project Driver Core

This file is the shared workflow contract for the `template-project-driver` skill across both Codex and Claude Code. Platform-specific skill entries must read this file first and must not weaken its rules.

## Purpose

Treat this skill as the control layer for the current template repository, not as a generic app builder.

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
6. `docs/backend-spec.md`
7. `docs/testing-spec.md`
8. `docs/deployment-spec.md`

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
9. Run template-level audit and project-level verification after generation.
10. Fix obvious failures before stopping.
11. Report the final output directory, what was validated, and what risks or assumptions remain.

## Required Generated Project Shape

Initialize and keep this minimum structure:

```text
generated/<project-slug>/
  README.md
  .gitignore
  .env.example
  compose.yaml
  requirements/
  docs/
  scripts/
  openspec/
  backend/
  frontend/
```

## Non-Negotiable Rules

- Generate OpenSpec before full implementation.
- Keep all business output inside `generated/<project-slug>/`.
- Treat the generated directory as a standalone engineering package, not a loose dump of files.
- Pull all secrets and runtime configuration from environment variables.
- Keep backend and frontend modular. Do not collapse the system into `main.py` or `App.tsx`.
- Generate verification artifacts together with implementation: tests, README commands, `.env.example`, and any project-level helper scripts.
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
- Write `.env.example` with backend, frontend, MySQL, Redis, JWT, CORS, and port-related keys as needed.
- Create `docs/architecture.md`, `docs/development.md`, and `docs/key-business-actions-checklist.md`.
- Add project-level scripts when validation or cleanup needs a stable entrypoint.

### Stage 4: Generate Backend

- Use `FastAPI + Pydantic v2 + SQLAlchemy 2.x async + Alembic`.
- Treat `docs/backend-spec.md` as the backend source of truth for layering, contracts, security, migrations, health checks, and verification expectations.
- Organize backend into clear modules such as `api/`, `core/`, `db/`, `models/`, `repositories/`, `schemas/`, `services/`, and `tests/`.
- Keep configuration, auth, persistence, and route handling separated.
- Read settings from environment variables only.

### Stage 5: Generate Frontend

- Use `React + TypeScript + Vite`.
- Organize code into `app/`, `api/`, `components/`, `features/`, `hooks/`, `pages/`, `schemas/`, or equivalent modular structure.
- Prefer `TanStack Query`, `React Hook Form`, and `Zod`.
- Treat `docs/frontend-ui-spec.md` as the frontend source of truth. Read it first, then follow its referenced detailed documents such as `docs/design-tokens.md`, `docs/component-patterns.md`, and `docs/frontend-anti-patterns.md` as needed.
- Ensure loading, empty, error, disabled, submitting, and success states exist.
- Keep responsive behavior and visual hierarchy intentional; avoid placeholder-grade UI.

### Stage 6: Generate Deployment And Tests

- Treat `docs/deployment-spec.md` as the deployment and runtime source of truth.
- Treat `docs/testing-spec.md` as the testing and regression source of truth.
- Create `compose.yaml` for at least `frontend`, `backend`, `mysql`, and `redis`.
- Provide backend tests, `ruff check`, frontend build, and frontend lint support.
- Ensure `.env.example`, Dockerfiles, health checks, startup instructions, and key business-action validation paths align with those specs.
- Add `scripts/check_business_flow.sh` when the requirement defines business actions that can be asserted after startup.

### Stage 7: Audit And Verify

- Run `./scripts/audit_generated_project.sh generated/<project-slug>` for template-level completeness.
- Run `./scripts/verify_project.sh generated/<project-slug>` for executable validation.
- Use `./scripts/verify_project.sh generated/<project-slug> --with-compose-up` when container startup and project business-flow checks should be exercised.
- Fix clear breakages before handoff.

## Repository Entry Points

- `prompts/00-generate-from-requirement.md` is the orchestration prompt for full-flow generation.
- `prompts/07-fix-and-verify.md` is the repair and verification prompt.
- `scripts/audit_generated_project.sh` checks structure, spec, README, and env completeness.
- `scripts/verify_project.sh` checks compose, backend, frontend, and optional business-flow execution.

## Final Reporting

When finishing work with this skill, always state:

- the chosen `project-slug`
- the final generated directory
- whether OpenSpec was produced before code generation
- which audit and verification commands were run
- which key business actions were captured in `docs/key-business-actions-checklist.md`
- any remaining assumption, risk, or manual follow-up
