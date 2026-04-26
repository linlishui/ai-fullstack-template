#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify_project.sh generated/<project-slug>
  ./scripts/verify_project.sh generated/<project-slug> --with-compose-up

This script runs:
1. docker compose config
2. backend pytest
3. backend ruff check .
4. frontend npm run build
5. frontend npm run lint

Optional:
6. docker compose up --build -d
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

PROJECT_DIR="$1"
WITH_COMPOSE_UP=false

if [[ $# -eq 2 ]]; then
  case "$2" in
    --with-compose-up)
      WITH_COMPOSE_UP=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $2" >&2
      usage >&2
      exit 1
      ;;
  esac
fi

if [[ "$PROJECT_DIR" == "-h" || "$PROJECT_DIR" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/compose.yaml" ]]; then
  echo "Missing compose.yaml in $PROJECT_DIR" >&2
  exit 1
fi

run_backend_check() {
  local backend_dir="$1"

  if [[ -x "$backend_dir/.venv/bin/pytest" && -x "$backend_dir/.venv/bin/ruff" ]]; then
    (
      cd "$backend_dir"
      ./.venv/bin/pytest
      ./.venv/bin/ruff check .
    )
    return
  fi

  (
    cd "$backend_dir"
    pytest
    ruff check .
  )
}

echo "Running docker compose config in $PROJECT_DIR"
docker compose --env-file "$PROJECT_DIR/.env.example" -f "$PROJECT_DIR/compose.yaml" config >/dev/null

if [[ "$WITH_COMPOSE_UP" == true ]]; then
  echo "Running docker compose up --build -d in $PROJECT_DIR"
  docker compose --env-file "$PROJECT_DIR/.env.example" -f "$PROJECT_DIR/compose.yaml" up --build -d
fi

echo "Running backend checks in $PROJECT_DIR/backend"
run_backend_check "$PROJECT_DIR/backend"

echo "Running frontend checks in $PROJECT_DIR/frontend"
(
  cd "$PROJECT_DIR/frontend"
  npm run build
  npm run lint
)

echo "Verification completed for $PROJECT_DIR"
