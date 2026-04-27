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
cd generated/<project-slug>/backend && pytest && ruff check .

# 前端
cd generated/<project-slug>/frontend && npm run build && npm run lint

# 整体
cd generated/<project-slug> && docker compose up --build
```

## 重要文件索引

| 文件 | 用途 |
|------|------|
| `AGENTS.md` | 完整 AI 编码规则（必读） |
| `prompts/00-generate-from-requirement.md` | 全量生成 prompt |
| `prompts/07-fix-and-verify.md` | 修复验证 prompt |
| `docs/ai-workflow.md` | 工作流说明 |
| `docs/frontend-style-guide.md` | 前端设计规范 |
| `docs/design-tokens.md` | 默认主题 token 参考（色值、字号、间距等） |
| `docs/component-patterns.md` | 交互模式与组件质量标准 |
| `docs/page-blueprints.md` | 页面结构蓝图 |
| `docs/generation-quality.md` | 质量保障策略 |
| `requirements/requirement.md` | 业务需求输入 |
