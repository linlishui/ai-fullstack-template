# Project AGENTS Template

本模板用于生成项目级 `AGENTS.md`，让独立工程脱离模板仓库后仍保留 AI 协作规则。

建议输出到：

`generated/<project-slug>/AGENTS.md`

## 至少覆盖的内容

- 项目概述与目标
- 技术栈与目录结构
- OpenSpec-first 约束
- 后端、前端、部署、测试的项目级规则
- 环境变量与安全规则
- 验证命令
- 禁止行为
- 本项目的 AI 工作方式与交付要求
- 生产级硬门禁：安全、限流、可观测性、OpenAPI、Docker、CI、测试覆盖

## 推荐模板

```md
# Project AI Coding Rules

## Context

- Project:
- Goal:
- Main workflow:

## Stack

- Backend:
- Frontend:
- Infra:

## Non-Negotiable Rules

- Read `requirements/` and `openspec/` before major changes
- Keep code modular
- Do not hardcode secrets
- Keep tests and docs in sync with implementation
- Do not introduce implicit admin promotion through email prefixes or usernames
- Keep Redis-backed rate limiting, request id, metrics, OpenAPI export, and business-flow verification working

## Verification

- docker compose config
- backend pytest
- backend pytest coverage
- backend ruff check
- frontend npm run build
- frontend npm run lint
- frontend npm test
- scripts/export_openapi.sh
- scripts/check_business_flow.sh
```
