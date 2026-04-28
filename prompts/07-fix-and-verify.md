# 提示词：修复并验证生成结果

请对当前仓库中已经生成的全栈项目执行自动修复与验证。

在开始前，先识别目标项目目录，并优先读取：

- `generated/<project-slug>/requirements/` 下的需求快照
- `generated/<project-slug>/openspec/` 下的规格文档
- `generated/<project-slug>/docs/key-business-actions-checklist.md`
- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/deployment-spec.md`
- `docs/frontend-ui-spec.md`
- 按 `docs/frontend-ui-spec.md` 的引用关系按需读取前端细分文档，并优先使用其中的验收清单做前端验收
- 如果存在，读取 `generated/<project-slug>/docs/frontend-ui-checklist.md`

如果 `generated/<project-slug>/docs/key-business-actions-checklist.md` 不存在，必须先基于当前需求补生成一份，再继续修复与验证。
如果 `generated/<project-slug>/docs/frontend-ui-checklist.md` 不存在，必须先补生成一份前端 UI 检查清单，再继续修复与验证。

必须至少检查以下内容：

- `cd generated/<project-slug> && docker compose config`
- `cd generated/<project-slug> && docker compose up --build`
- `cd generated/<project-slug>/backend && pytest`
- `cd generated/<project-slug>/backend && ruff check .`
- `cd generated/<project-slug>/frontend && npm run build`
- `cd generated/<project-slug>/frontend && npm run lint`
- 如果存在 `generated/<project-slug>/scripts/check_business_flow.sh`，在服务启动后必须执行它
- 对照前端审计清单检查页面结构、视觉一致性、状态完整性与响应式风险
- 检查未登录、无权限和缺少前置条件时，关键点击是否会给出明确提示或跳转引导

执行要求：

- 先根据当前需求确认 3-5 个关键业务动作，并对照项目级回归清单核对它们的验证状态
- 先按 `docs/backend-spec.md` 核对后端分层、配置、安全、迁移和健康检查是否缺项
- 先按 `docs/testing-spec.md` 核对关键测试、业务流脚本和回归路径是否缺项
- 先按 `docs/deployment-spec.md` 核对环境变量、Compose 依赖、健康检查和启动说明是否缺项
- 先核对项目级前端 UI 检查清单，并按 `docs/frontend-ui-spec.md` 校验是否缺失主题 token、状态设计、移动端适配和页面结构落地
- 逐项运行并记录结果
- 如果发现明显错误，优先直接修复
- 修复后重新执行相关检查
- 修复后必须重新检查受影响的关键业务动作，不允许只重跑构建命令就结束
- 不要跳过失败项
- 如果某项因依赖缺失或外部环境限制无法完成，需要明确说明阻塞原因

输出要求：

- 先列出关键业务动作回归清单中的动作与最新验证状态
- 列出前端 UI 检查清单中的主要项与最新状态
- 列出已执行的检查项
- 列出已修复的问题
- 列出仍未解决的问题
- 给出建议的下一步操作
