# 提示词：修复并验证生成结果

请对当前仓库中已经生成的全栈项目执行自动修复与验证。

在开始前，先识别目标项目目录，并优先读取：

- `generated/<project-slug>/requirements/` 下的需求快照
- `generated/<project-slug>/openspec/` 下的规格文档
- `generated/<project-slug>/docs/key-business-actions-checklist.md`

如果 `generated/<project-slug>/docs/key-business-actions-checklist.md` 不存在，必须先基于当前需求补生成一份，再继续修复与验证。

必须至少检查以下内容：

- `cd generated/<project-slug> && docker compose config`
- `cd generated/<project-slug> && docker compose up --build`
- `cd generated/<project-slug>/backend && pytest`
- `cd generated/<project-slug>/backend && ruff check .`
- `cd generated/<project-slug>/frontend && npm run build`
- `cd generated/<project-slug>/frontend && npm run lint`
- 如果存在 `generated/<project-slug>/scripts/check_business_flow.sh`，在服务启动后必须执行它

执行要求：

- 先根据当前需求确认 3-5 个关键业务动作，并对照项目级回归清单核对它们的验证状态
- 逐项运行并记录结果
- 如果发现明显错误，优先直接修复
- 修复后重新执行相关检查
- 修复后必须重新检查受影响的关键业务动作，不允许只重跑构建命令就结束
- 不要跳过失败项
- 如果某项因依赖缺失或外部环境限制无法完成，需要明确说明阻塞原因

输出要求：

- 先列出关键业务动作回归清单中的动作与最新验证状态
- 列出已执行的检查项
- 列出已修复的问题
- 列出仍未解决的问题
- 给出建议的下一步操作
