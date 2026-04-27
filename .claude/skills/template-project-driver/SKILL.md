---
name: template-project-driver
description: 驱动本仓库从业务需求到全栈项目生成的端到端工作流。当用户需要基于 requirements/requirement.md 生成项目、询问如何运行生成流程、需要修复或验证已生成项目、或要求执行 OpenSpec 优先的全量生成时触发。负责协调需求分析、OpenSpec 生成、后端/前端/部署/测试输出，并在 generated/<project-slug>/ 下产出独立可迁移的工程包。
---

# Template Project Driver — 全栈项目生成驱动（Claude Code 版）

这是 Claude Code 侧的 skill 入口；对应的 Codex 侧 skill 位于 `skills/template-project-driver/`。

先读取共享工作流契约：

- [共享核心](../../../skills/shared/template-project-driver-core.md)
- [共享工作流地图](../../../skills/shared/template-project-driver-workflow-map.md)

本模板仓库同时兼容 Codex 与 Claude Code，双端 skill 必须遵守同一套工作流契约与产出约束。

## Claude Code 执行策略

本 Skill 运行于 Claude Code 交互式环境，应充分利用以下能力：

| 场景 | 推荐工具 |
|------|----------|
| 读取需求、规格、文档 | `Read` |
| 搜索文件结构和代码模式 | `Glob` / `Grep` |
| 创建新文件（代码、配置、文档） | `Write` |
| 修改已存在的文件 | `Edit`（先 `Read` 再 `Edit`） |
| 运行验证命令（pytest、ruff、npm build 等） | `Bash` |
| 需要用户决策（slug 确认、需求澄清、方案选择） | `AskUserQuestion` |
| 跟踪多阶段进度 | `TaskCreate` / `TaskUpdate` |
| 并行执行独立子任务（如同时生成后端和前端骨架） | `Agent` |
| 复杂实现前的方案设计 | `EnterPlanMode` |

### 交互式执行要点

1. 主动汇报进度。
2. 遇到歧义主动提问，不猜测。
3. 每个主要阶段完成后增量验证，不攒到最后。
4. 验证失败后立即修复并重试。
5. 将本文件视为薄适配层；共享契约变化时，优先修改共享源而不是再次复制正文。
