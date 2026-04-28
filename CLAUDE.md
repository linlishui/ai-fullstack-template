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
- 以资深全栈架构师、生产级交付负责人和严格代码审查者的标准执行
- 主业务闭环优先级高于外围生产资产；Nginx、CI、metrics、文档和审计必须服务于真实业务动作、状态流转、权限和验证
- 所有生成代码输出到 `generated/<project-slug>/`
- 必须先生成 OpenSpec 规格，再生成实现
- 后端按 api/models/schemas/services/repositories/core 拆分，禁止全部堆进 main.py
- 前端按 pages/components/features/hooks/api 拆分，禁止全部堆进 App.tsx
- 配置必须来自环境变量，禁止硬编码
- 生成目标默认对齐生产级高分基线，需显式覆盖安全、可观测性、前端容错、Nginx、CI/CD 与关键业务回归
- 按三层取舍：不可降级硬门禁优先，默认生产增强其次，复杂认证、后台任务、BI、多租户等按需扩展
- 遵守 `docs/template-governance.md`：模板文档是规则源，生成项目文档只写项目事实、证据路径、验证结果和风险，不复制模板长规则

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
| `docs/project-asset-templates.md` | 项目级 AI、清单、安全、可观测性和测试资产模板 |
| `docs/design-tokens.md` | 默认主题 token 参考（色值、字号、间距等） |
| `docs/component-patterns.md` | 交互模式与组件质量标准 |
| `docs/frontend-anti-patterns.md` | 前端反模式与禁止项 |
| `docs/generation-quality.md` | 质量保障策略 |
| `docs/template-governance.md` | 规则源优先级、生成资产职责与去冗余策略 |
| `docs/production-grade-rubric.md` | 生产级评分硬门禁 |
| `docs/fullstack-review-scoring.md` | 120 分 fullstack reviewer 评分口径与一票否决项 |
| `requirements/requirement.md` | 业务需求输入 |
