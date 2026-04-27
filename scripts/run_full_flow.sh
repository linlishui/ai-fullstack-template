#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIREMENT_FILE="$ROOT_DIR/requirements/requirement.md"
GENERATE_ONLY=false
AI_CLI="${AI_CLI:-auto}"
CLAUDE_PERMISSION_MODE="${CLAUDE_PERMISSION_MODE:-bypassPermissions}"
SNAPSHOT_BEFORE="$(mktemp)"
SNAPSHOT_AFTER="$(mktemp)"
trap 'rm -f "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER"' EXIT

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run_full_flow.sh
  ./scripts/run_full_flow.sh --generate-only

Environment variables:
  AI_CLI=auto|codex|claude
  CLAUDE_PERMISSION_MODE=<mode>   # used when AI_CLI=claude

This script runs:
1. Full project generation from requirements/requirement.md
2. Fix-and-verify pass
EOF
}

detect_ai_cli() {
  case "$AI_CLI" in
    auto)
      if command -v codex >/dev/null 2>&1; then
        echo "codex"
        return
      fi

      if command -v claude >/dev/null 2>&1; then
        echo "claude"
        return
      fi

      echo "No supported AI CLI found in PATH. Install codex or claude, or set AI_CLI explicitly." >&2
      exit 1
      ;;
    codex|claude)
      if ! command -v "$AI_CLI" >/dev/null 2>&1; then
        echo "Requested AI CLI '$AI_CLI' is not installed or not in PATH." >&2
        exit 1
      fi
      echo "$AI_CLI"
      ;;
    *)
      echo "Unsupported AI_CLI value: $AI_CLI" >&2
      echo "Expected one of: auto, codex, claude" >&2
      exit 1
      ;;
  esac
}

run_ai_prompt() {
  local cli="$1"
  local prompt="$2"

  case "$cli" in
    codex)
      codex exec --full-auto --cd "$ROOT_DIR" "$prompt"
      ;;
    claude)
      claude -p \
        --permission-mode "$CLAUDE_PERMISSION_MODE" \
        --add-dir "$ROOT_DIR" \
        "$prompt"
      ;;
    *)
      echo "Unsupported AI CLI: $cli" >&2
      exit 1
      ;;
  esac
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

if [[ ! -f "$REQUIREMENT_FILE" ]]; then
  echo "Missing requirement file: $REQUIREMENT_FILE" >&2
  exit 1
fi

if grep -q "在此文件中填写具体业务需求" "$REQUIREMENT_FILE"; then
  echo "requirements/requirement.md still looks like the default template. Please replace it with real requirements first." >&2
  exit 1
fi

cd "$ROOT_DIR"
SELECTED_AI_CLI="$(detect_ai_cli)"
echo "Using AI CLI: $SELECTED_AI_CLI"
find generated -mindepth 1 -maxdepth 1 -type d | sort >"$SNAPSHOT_BEFORE"

GENERATE_PROMPT="请读取并严格执行 prompts/00-generate-from-requirement.md，基于 requirements/requirement.md 生成完整项目实现，并将所有业务代码统一输出到 generated/<project-slug>/。"

echo "Running full project generation..."
run_ai_prompt "$SELECTED_AI_CLI" "$GENERATE_PROMPT"
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
run_ai_prompt "$SELECTED_AI_CLI" "$VERIFY_PROMPT"

echo "Flow completed for ${PROJECT_DIR}."
