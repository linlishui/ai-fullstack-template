# AI Collaboration Assets Template

本模板用于约束生成项目必须输出项目级 AI 协作资产，而不是只依赖模板仓库本身。

建议至少输出：

- `generated/<project-slug>/AGENTS.md`
- `generated/<project-slug>/CLAUDE.md`
- `generated/<project-slug>/docs/ai-workflow.md`
- `generated/<project-slug>/docs/review-log.md`
- `generated/<project-slug>/docs/fix-log.md`
- `generated/<project-slug>/docs/security-notes.md`
- `generated/<project-slug>/docs/observability.md`
- `generated/<project-slug>/docs/test-plan.md`

## 目的

- 让独立工程迁移后仍保留 AI 工作规则
- 让后续 AI 和人工能够追踪 review、修复和验证记录
- 让评分中的 AI 工具链项在项目级有明确落地产物
- 让安全、可观测性和测试策略能被后续 AI 继续审计，而不是散落在 README 中

## review-log 建议字段

- 日期
- 触发原因
- 审查范围
- 发现问题
- 修复状态

## fix-log 建议字段

- 日期
- 问题编号
- 修复动作
- 影响范围
- 回归验证
