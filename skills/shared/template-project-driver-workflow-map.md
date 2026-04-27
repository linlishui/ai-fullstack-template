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

## Frontend Guidance

Read these before generating non-trivial frontend work:

- `docs/design-tokens.md`
- `docs/component-patterns.md`
- `docs/page-blueprints.md`
- `docs/frontend-style-guide.md`
- `docs/frontend-review-checklist.md`

Use them to shape theme tokens, page hierarchy, interaction patterns, and quality checks.

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
- `prompts/04-generate-frontend.md`
  - Frontend generation stage.
- `prompts/05-generate-docker.md`
  - Compose and deployment stage.
- `prompts/06-generate-tests.md`
  - Test generation stage.
- `prompts/07-fix-and-verify.md`
  - Repair and verification stage.
- `prompts/08-security-review.md`
  - Security review stage.

## Script Entry Points

- `scripts/audit_generated_project.sh generated/<project-slug>`
  - Checks required project-level files, directories, OpenSpec paths, env keys, and README verification command references.
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

Minimum synchronized project context:

- `requirements/requirement.md`
- `docs/architecture.md`
- `docs/development.md`
- `docs/key-business-actions-checklist.md`
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
- Building UI without required loading, empty, error, or submitting feedback
- Overbuilding authentication when auth is not the requirement's main loop
- Passing static build checks while main business actions still cannot be executed
