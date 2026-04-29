# Concurrent Generation Strategy

本文件定义模板在保持高分门禁不降级的前提下，如何用并发提高独立工程生成效率。并发只改变执行编排，不改变规则优先级、OpenSpec-first、真实业务闭环或验证门禁。

## 1. 基本原则

- OpenSpec 之前不得并发写业务实现。需求分析、`project-slug`、输出目录初始化、OpenSpec、关键业务动作和模块边界必须先串行确定。
- 并发任务必须基于同一份 `generated/<project-slug>/openspec/`、需求快照和项目级任务拆分执行。
- 每个并发任务必须有明确文件责任边界，禁止两个任务同时改同一文件或同一目录下的同一配置入口。
- 并发任务不得降低生产级要求。限流、request id、metrics、OpenAPI、CI、Nginx、前端测试、业务流脚本和模板审计仍是硬门禁。
- 并发只用于非阻塞、可独立推进的实现或审查工作；下一步马上依赖的阻塞事项由主控流程本地完成。

## 2. 串行关口

以下阶段必须串行完成，不能交给多个任务各自解释：

1. 读取并分析 `requirements/requirement.md`。
2. 判定需求完整性、列出假设和待确认项。
3. 生成稳定的 `project-slug`。
4. 初始化 `generated/<project-slug>/` 基础目录。
5. 生成或更新 OpenSpec：`openspec/project.md`、`openspec/specs/<capability>/spec.md`、`openspec/changes/<change-id>/`。
6. 从 OpenSpec 提炼 3-5 个关键业务动作、共享数据模型、权限边界和 API 合约。
7. 生成 `docs/parallel-execution-plan.md`，记录任务分片、文件所有权、依赖、集成顺序和风险。
8. 最终集成、安全审查、修复、模板审计和项目级验证。

## 3. 推荐并发分片

OpenSpec 完成后，可按以下分片并发推进。实际分片应以需求规模和文件冲突风险为准。

| 分片 | 主要责任 | 写入范围 | 依赖 |
| --- | --- | --- | --- |
| Backend Core | 模型、migration、repository、service、API、认证授权、健康检查、metrics、rate limiting | `backend/`、必要的 `scripts/export_openapi.sh` | OpenSpec 数据模型、接口和权限 |
| Frontend App | 页面、组件、API client、hooks、表单、状态反馈、前端测试 | `frontend/`、`docs/frontend-ui-checklist.md` | OpenSpec 页面、接口和状态 |
| Runtime Delivery | Compose、Dockerfile、Nginx、CI、环境变量、README 运行命令 | `compose.yaml`、`infra/`、`.github/`、`.env.example`、README 部分 | 后端/前端端口、健康检查、脚本约定 |
| Verification | 后端测试、业务流脚本、OpenAPI 导出检查、清单证据 | `backend/tests/`、`scripts/`、`docs/test-plan.md`、`docs/production-readiness-checklist.md` | 关键业务动作、API 合约 |
| Review Sidecar | 安全、可观测性、前端可用性和假实现风险审查 | `docs/review-log.md`、`docs/fix-log.md`，必要时提交修复建议 | 初始实现产物 |

## 4. 文件所有权规则

- 同一轮并发中，一个文件只能有一个 owner。
- 共享文件采用主控集成策略：`README.md`、`.env.example`、`compose.yaml`、`docs/production-readiness-checklist.md`、`docs/security-notes.md`、`docs/observability.md` 需要在并发任务完成后由主控统一合并。
- 如果任务必须修改共享文件，必须在 `docs/parallel-execution-plan.md` 中提前声明章节范围，例如“只维护 README 的 Frontend commands 小节”。
- 并发任务不得删除、重命名或重写其他任务的输出；发现接口不一致时记录冲突并交回主控集成。

## 5. 集成顺序

并发任务完成后，主控必须按以下顺序收口：

1. 对齐后端 API、前端 API client、OpenSpec 接口和 OpenAPI 导出。
2. 对齐环境变量、Compose、Dockerfile、Nginx、CI 和 README 命令。
3. 对齐关键业务动作清单、前端 UI 清单、生产就绪清单、安全说明、可观测性说明和测试计划。
4. 执行安全审查和假实现检查，优先修复 MemoryStore、静态 toast、硬编码统计、静态 readiness、raw URL metrics label 等高风险问题。
5. 执行 `scripts/audit_generated_project.sh generated/<project-slug>`。
6. 执行 `scripts/verify_project.sh generated/<project-slug>`，需要启动服务时再执行 `--with-compose-up`。

## 6. 并发计划文档

每个生成项目必须包含：

```text
generated/<project-slug>/docs/parallel-execution-plan.md
```

该文件记录：

- 本轮是否启用并发；未启用时说明原因。
- 每个任务的 owner、目标、输入、写入范围和不得触碰的文件。
- 任务之间的依赖关系和集成顺序。
- 共享契约：API、数据模型、环境变量、端口、脚本名和关键业务动作。
- 冲突与解决记录。
- 并发完成后的审计、验证命令和结果。

并发计划是交付证据，不是替代实现或验证的说明。模板审计只检查其存在和基本内容；项目是否高分仍由代码、配置、测试、脚本和 CI 证据决定。
