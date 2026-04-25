#!/usr/bin/env bash

set -euo pipefail

cat <<'EOF'
Suggested verification commands:

1. cd generated/<project-slug>
2. docker compose config
3. docker compose up --build
4. (cd backend && pytest)
5. (cd backend && ruff check .)
6. (cd frontend && npm run build)
7. (cd frontend && npm run lint)

If no generated project exists yet, run the generation prompts first.
EOF
