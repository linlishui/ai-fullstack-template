---
name: template-project-driver
description: Drive this repository's AI template workflow from business requirement to generated fullstack project. Use when Codex needs to manage or execute the current template's end-to-end generation process, including reading requirements/requirement.md, producing OpenSpec before implementation, creating generated/<project-slug>/ as a standalone project package, coordinating backend/frontend/docker/tests output, and enforcing template-level audit plus project-level verification.
---

# Template Project Driver

This is the Codex-facing skill entry. The Claude Code counterpart lives at `.claude/skills/template-project-driver/`.

Read the shared workflow contract first:

- [Core workflow](../shared/template-project-driver-core.md)
- [Workflow map](../shared/template-project-driver-workflow-map.md)

Keep the workflow contract aligned across both entries because this template repository supports both runtimes.

## Codex-Specific Notes

- Invoke this skill explicitly as `$template-project-driver` when you want the repository workflow to take precedence over freeform generation.
- Use `skills/template-project-driver/agents/openai.yaml` as the Codex display metadata for this skill.
- Follow the shared contract before making any substantial implementation or verification decision.
- Treat this file as a thin adapter layer. When the shared contract changes, update platform-specific notes only when Codex behavior actually differs.
