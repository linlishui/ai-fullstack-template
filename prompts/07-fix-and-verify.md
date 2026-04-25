# 提示词：修复并验证生成结果

请对当前仓库中已经生成的全栈项目执行自动修复与验证。

必须至少检查以下内容：

- `cd generated/<project-slug> && docker compose config`
- `cd generated/<project-slug> && docker compose up --build`
- `cd generated/<project-slug>/backend && pytest`
- `cd generated/<project-slug>/backend && ruff check .`
- `cd generated/<project-slug>/frontend && npm run build`
- `cd generated/<project-slug>/frontend && npm run lint`

执行要求：

- 逐项运行并记录结果
- 如果发现明显错误，优先直接修复
- 修复后重新执行相关检查
- 不要跳过失败项
- 如果某项因依赖缺失或外部环境限制无法完成，需要明确说明阻塞原因

输出要求：

- 列出已执行的检查项
- 列出已修复的问题
- 列出仍未解决的问题
- 给出建议的下一步操作
