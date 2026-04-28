# Claude Code Project Context

## 项目概述

AI Fullstack Auto Implementation Template — 从业务需求自动生成可部署的全栈 Web 应用。

## 技术栈

- 后端: Python 3.12+, FastAPI, Pydantic v2, SQLAlchemy 2.x async, Alembic, MySQL, Redis
- 前端: React, TypeScript, Vite, Tailwind CSS, shadcn/ui, TanStack Query
- 部署: Docker Compose

## 编码规则

**必读**: 完整的 AI 编码规则定义在 [AGENTS.md](./AGENTS.md)，所有规则同样适用于 Claude Code。

核心要点:
- 所有生成代码输出到 `generated/<project-slug>/`
- 必须先生成 OpenSpec 规格，再生成实现
- 后端按 api/models/schemas/services/repositories/core 拆分，禁止全部堆进 main.py
- 前端按 pages/components/features/hooks/api 拆分，禁止全部堆进 App.tsx
- 配置必须来自环境变量，禁止硬编码
- 生成目标默认对齐生产级高分基线，需显式覆盖安全、可观测性、前端容错、Nginx、CI/CD 与关键业务回归

## Skill 调用

当前模板工程同时兼容 Codex 与 Claude Code，两端共享同一个工作流约束名：`template-project-driver`。

- Claude Code skill 路径：`.claude/skills/template-project-driver/`
- Codex 对应 skill 路径：`skills/template-project-driver/`
- 调用目标一致：先读 `requirements/requirement.md`，先产出 `generated/<project-slug>/openspec/`，再生成 `generated/<project-slug>/` 下的独立工程并执行审计与验证

推荐直接在提示词里显式说明：

```text
请使用 template-project-driver skill 执行当前模板流程：读取 requirements/requirement.md，先生成 OpenSpec，再把完整项目输出到 generated/<project-slug>/，最后执行模板级审计与项目级验证。
```

## 验证命令

```bash
# 后端
cd generated/<project-slug>/backend && pytest --cov=app --cov-report=term-missing && ruff check .

# 前端
cd generated/<project-slug>/frontend && npm run build && npm run lint && npm test -- --run

# 整体
./scripts/audit_generated_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug> --with-compose-up
```

## 重要文件索引

| 文件 | 用途 |
|------|------|
| `AGENTS.md` | 完整 AI 编码规则（必读） |
| `prompts/00-generate-from-requirement.md` | 全量生成 prompt |
| `prompts/07-fix-and-verify.md` | 修复验证 prompt |
| `docs/ai-workflow.md` | 工作流说明 |
| `docs/backend-spec.md` | 后端总规范与验收入口 |
| `docs/testing-spec.md` | 测试与验证总规范入口 |
| `docs/deployment-spec.md` | 部署与运行总规范入口 |
| `docs/frontend-ui-spec.md` | 前端总规范与验收入口 |
| `docs/business-checklist-template.md` | 关键业务动作与项目级回归清单模板 |
| `docs/frontend-ui-checklist-template.md` | 前端 UI 清单模板 |
| `docs/production-readiness-template.md` | 生产就绪清单模板 |
| `docs/security-notes-template.md` | 项目级安全说明模板 |
| `docs/observability-template.md` | 项目级可观测性说明模板 |
| `docs/test-plan-template.md` | 项目级测试计划模板 |
| `docs/project-agents-template.md` | 项目级 AGENTS 模板 |
| `docs/project-claude-template.md` | 项目级 CLAUDE 模板 |
| `docs/ai-collaboration-template.md` | 项目级 AI 协作资产模板 |
| `docs/design-tokens.md` | 默认主题 token 参考（色值、字号、间距等） |
| `docs/component-patterns.md` | 交互模式与组件质量标准 |
| `docs/frontend-anti-patterns.md` | 前端反模式与禁止项 |
| `docs/generation-quality.md` | 质量保障策略 |
| `docs/production-grade-rubric.md` | 生产级评分硬门禁 |
| `requirements/requirement.md` | 业务需求输入 |
