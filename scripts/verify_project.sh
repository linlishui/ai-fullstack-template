#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify_project.sh generated/<project-slug>
  ./scripts/verify_project.sh generated/<project-slug> --with-compose-up

This script runs:
1. template-level generated project audit
2. docker compose config
3. backend pytest
4. backend ruff check .
5. frontend npm run build
6. frontend npm run lint
7. frontend npm test if a test script exists
8. OpenAPI export script if present
9. project business flow checks if generated/<project-slug>/scripts/check_business_flow.sh exists and services are started

Optional:
10. docker compose up --build -d
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

cleanup_compose() {
  if [[ "$WITH_COMPOSE_UP" == true ]]; then
    echo "Stopping compose services in $PROJECT_DIR"
    (
      cd "$PROJECT_DIR"
      docker compose --env-file .env.example down
    )
  fi
}

if [[ "$WITH_COMPOSE_UP" == true ]]; then
  trap cleanup_compose EXIT
fi

echo "Running prerequisite checks"
"$SCRIPT_DIR/check_prerequisites.sh"

echo "Running template-level audit in $PROJECT_DIR"
"$SCRIPT_DIR/audit_generated_project.sh" "$PROJECT_DIR"

run_backend_check() {
  local backend_dir="$1"

  if [[ -x "$backend_dir/.venv/bin/pytest" && -x "$backend_dir/.venv/bin/ruff" ]]; then
    (
      cd "$backend_dir"
      if ./.venv/bin/python -c "import pytest_cov" >/dev/null 2>&1; then
        ./.venv/bin/pytest --cov=app --cov-report=term-missing
      else
        ./.venv/bin/pytest
      fi
      ./.venv/bin/ruff check .
    )
    return
  fi

  (
    cd "$backend_dir"
    if python -c "import pytest_cov" >/dev/null 2>&1; then
      pytest --cov=app --cov-report=term-missing
    else
      pytest
    fi
    ruff check .
  )
}

run_frontend_checks() {
  local frontend_dir="$1"

  (
    cd "$frontend_dir"
    npm run build
    npm run lint
    if npm run | grep -qE '^[[:space:]]+test'; then
      npm test -- --run
    else
      echo "No frontend test script found; production-grade generation should add one." >&2
      exit 1
    fi
  )
}

run_openapi_export() {
  local project_dir="$1"

  if [[ -x "$project_dir/scripts/export_openapi.sh" ]]; then
    "$project_dir/scripts/export_openapi.sh"
    return
  fi

  if [[ -f "$project_dir/backend/scripts/export_openapi.py" ]]; then
    (
      cd "$project_dir/backend"
      if [[ -x .venv/bin/python ]]; then
        .venv/bin/python scripts/export_openapi.py
      else
        python scripts/export_openapi.py
      fi
    )
    return
  fi

  echo "Missing OpenAPI export script; production-grade generation must provide scripts/export_openapi.sh or backend/scripts/export_openapi.py" >&2
  exit 1
}

wait_for_health() {
  local base_url="${BASE_URL:-http://localhost:8080}"

  echo "Waiting for health endpoint at ${base_url}/api/v1/health/ready"
  for _ in {1..60}; do
    if curl -fsS "${base_url}/api/v1/health/ready" >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done

  echo "Timed out waiting for ${base_url}/api/v1/health/ready" >&2
  exit 1
}

run_business_flow_check() {
  local project_dir="$1"
  local script_path="$project_dir/scripts/check_business_flow.sh"
  local with_compose_up="$2"

  if [[ ! -f "$script_path" ]]; then
    echo "No project business flow check script found at $script_path, skipping business flow verification."
    return
  fi

  if [[ "$with_compose_up" != true ]]; then
    echo "Project business flow check script found, but services were not started by this run. Re-run with --with-compose-up to execute business flow verification."
    return
  fi

  if [[ ! -x "$script_path" ]]; then
    echo "Project business flow check script is not executable: $script_path" >&2
    exit 1
  fi

  echo "Running project business flow checks in $project_dir"
  "$script_path"
}

echo "Running docker compose config in $PROJECT_DIR"
(
  cd "$PROJECT_DIR"
  docker compose --env-file .env.example config >/dev/null
)

if [[ "$WITH_COMPOSE_UP" == true ]]; then
  echo "Running docker compose up --build -d in $PROJECT_DIR"
  (
    cd "$PROJECT_DIR"
    docker compose --env-file .env.example up --build -d
  )
  wait_for_health
fi

echo "Running backend checks in $PROJECT_DIR/backend"
run_backend_check "$PROJECT_DIR/backend"

echo "Running frontend checks in $PROJECT_DIR/frontend"
run_frontend_checks "$PROJECT_DIR/frontend"

echo "Running OpenAPI export check in $PROJECT_DIR"
run_openapi_export "$PROJECT_DIR"

run_business_flow_check "$PROJECT_DIR" "$WITH_COMPOSE_UP"

echo "Verification completed for $PROJECT_DIR"
