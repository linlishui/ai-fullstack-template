#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIREMENT_FILE="$ROOT_DIR/requirements/requirement.md"
GENERATE_ONLY=false
SNAPSHOT_BEFORE="$(mktemp)"
SNAPSHOT_AFTER="$(mktemp)"
trap 'rm -f "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER"' EXIT

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run_full_flow.sh
  ./scripts/run_full_flow.sh --generate-only

This script runs:
1. Full project generation from requirements/requirement.md
2. Fix-and-verify pass
EOF
}

for arg in "$@"; do
  case "$arg" in
    --generate-only)
      GENERATE_ONLY=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI is not installed or not in PATH." >&2
  exit 1
fi

if [[ ! -f "$REQUIREMENT_FILE" ]]; then
  echo "Missing requirement file: $REQUIREMENT_FILE" >&2
  exit 1
fi

if grep -q "在此文件中填写具体业务需求" "$REQUIREMENT_FILE"; then
  echo "requirements/requirement.md still looks like the default template. Please replace it with real requirements first." >&2
  exit 1
fi

cd "$ROOT_DIR"
find generated -mindepth 1 -maxdepth 1 -type d | sort >"$SNAPSHOT_BEFORE"

GENERATE_PROMPT="请读取并严格执行 prompts/00-generate-from-requirement.md，基于 requirements/requirement.md 生成完整项目实现，并将所有业务代码统一输出到 generated/<project-slug>/。"

echo "Running full project generation..."
codex exec --full-auto --cd "$ROOT_DIR" "$GENERATE_PROMPT"
find generated -mindepth 1 -maxdepth 1 -type d | sort >"$SNAPSHOT_AFTER"

mapfile -t NEW_PROJECTS < <(comm -13 "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER")
mapfile -t ALL_PROJECTS <"$SNAPSHOT_AFTER"

PROJECT_DIR=""

if [[ ${#NEW_PROJECTS[@]} -eq 1 ]]; then
  PROJECT_DIR="${NEW_PROJECTS[0]}"
elif [[ ${#NEW_PROJECTS[@]} -eq 0 && ${#ALL_PROJECTS[@]} -eq 1 ]]; then
  PROJECT_DIR="${ALL_PROJECTS[0]}"
else
  echo "Unable to determine generated project directory automatically." >&2
  echo "Detected projects:" >&2
  printf '  %s\n' "${ALL_PROJECTS[@]}" >&2
  exit 1
fi

VERIFY_PROMPT="请读取并严格执行 prompts/07-fix-and-verify.md，对 ${PROJECT_DIR}/ 下的项目执行自动修复与验证，不要改为占位路径。"

if [[ "$GENERATE_ONLY" == true ]]; then
  echo "Generation finished at ${PROJECT_DIR}. Skipping fix-and-verify because --generate-only was set."
  exit 0
fi

echo "Running fix-and-verify..."
codex exec --full-auto --cd "$ROOT_DIR" "$VERIFY_PROMPT"

echo "Flow completed for ${PROJECT_DIR}."
