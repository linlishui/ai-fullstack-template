# Project CLAUDE Template

本模板用于生成项目级 `CLAUDE.md`，为 Claude Code 或同类 AI 入口提供项目上下文。

建议输出到：

`generated/<project-slug>/CLAUDE.md`

## 至少覆盖的内容

- 项目概述
- 技术栈
- 关键目录索引
- 启动与验证命令
- 优先读取的项目级文档
- 生成后续迭代时必须遵守的规则
- 生产级质量门禁和禁止降级项

## 必须优先读取

- `requirements/requirement.md`
- `openspec/project.md`
- `docs/architecture.md`
- `docs/security-notes.md`
- `docs/observability.md`
- `docs/test-plan.md`
- `docs/production-readiness-checklist.md`

## 必须保持有效

- Redis-backed rate limiting
- Request ID / structured logs / `/metrics`
- Safe admin bootstrap or seed flow
- OpenAPI export
- Backend tests with coverage
- Frontend tests, lint and build
- Business flow script
