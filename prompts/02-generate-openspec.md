# 提示词：生成 OpenSpec

请基于 `requirements/requirement.md` 直接在 `generated/<project-slug>/openspec/` 中生成或更新 OpenSpec 风格规格文档。

要求：

- 不跳过需求分析
- 必须同时生成项目级上下文、业务规格和变更文档三层内容
- 项目级 `openspec/` 至少包含 `project.md`
- 业务规格必须落到 `generated/<project-slug>/openspec/specs/<capability>/spec.md`
- 变更文档必须落到 `generated/<project-slug>/openspec/changes/<change-id>/`，至少包含 `proposal.md`、`design.md`、`tasks.md`
- 规格必须覆盖需求、设计、任务
- 明确模块边界、接口、数据模型、权限规则、异常场景
- 对关键能力同时补充安全、可观测性、部署与验证约束，例如统一响应、全局异常处理、分页、健康检查、ErrorBoundary、Nginx、CI、业务验证脚本
- `spec.md` 不能只用 `changes/` 替代；如果当前需求只有一个核心能力，也必须至少生成一个 capability spec
- 规格质量要求：
  - 接口定义必须包含请求/响应结构、HTTP 方法、URL 路径和错误码
  - 数据模型必须包含字段名、类型、约束（唯一、非空、默认值）和关联关系
  - 权限规则必须按角色说明哪些动作可执行、哪些资源可见
  - 状态流转必须用状态机或列表说明合法转换路径、触发条件和失败分支
  - 必须标注关键业务动作（3-5 个），后续测试和验证以此为回归基准
- 输出你新增或更新了哪些 OpenSpec 文件
