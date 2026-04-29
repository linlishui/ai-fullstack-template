# AI Workflow

## 标准工作流

### 阶段 0：质量预期

- 以资深全栈架构师、生产级交付负责人和严格代码审查者的标准执行；目标是交付可独立运行、可验证、可维护、接近生产环境质量的工程，而不是 demo
- 先确认本次目标是生成“可验证工程”，不是只生成代码片段
- 优先保证当前需求里最关键的业务闭环，再补次优先级功能
- 主业务闭环优先级高于外围生产资产；不得为了堆 Nginx、CI、文档或可观测性占位而牺牲真实业务动作、状态流转、权限和测试
- 生成完成后必须通过模板级审计与项目级验证
- 生成结果必须同时满足六项原则：功能完整性、技术实现质量、可测试性、设计文档与 Spec Driven、AI 工具链使用、代码可维护性
- 生产级高分项以 `docs/production-grade-rubric.md` 为硬门禁，不得只在文档中声明已覆盖
- 120 分 fullstack reviewer 评分口径以 `docs/fullstack-review-scoring.md` 为参考，重点防止假持久化、假前端交互和假生产证据
- 规则源、生成资产边界和去冗余原则以 `docs/template-governance.md` 为准；生成项目文档只记录项目事实、证据路径、验证结果和风险，不复制模板长规则
- 并发生成编排以 `docs/concurrent-generation.md` 为准；并发只允许发生在 OpenSpec 和共享契约确定之后，不能降低任何质量门禁

这里的“业务闭环”应由当前需求决定，而不是固定等同于认证流程。
如果需求包含认证，则认证属于关键动作之一；如果需求重点不在认证，则不应默认把大量时间消耗在注册/登录环节。

质量要求按三层执行：

- 不可降级硬门禁：OpenSpec-first、真实业务闭环、数据库-backed 持久化、真实 API/mutation 前端动作、认证授权与输入校验、可执行测试和模板审计。
- 默认生产增强：限流、request id、日志、metrics、Tracing extension point、Nginx、Docker、CI、OpenAPI、生产就绪/安全/可观测性/测试文档。
- 按需扩展：复杂认证体验、后台任务、复杂缓存、运营 BI、细粒度权限矩阵、多租户等，只有需求或风险明确需要时展开。

执行时按阶段读取规则：先读工作流、评分和生产门禁，再在对应阶段读取后端、前端、测试或部署规范。不要在每个阶段重复加载和复述全部模板规则。

### 阶段 1：输入需求

- 将完整业务需求写入 `requirements/requirement.md`

### 阶段 2：分析需求

- 使用 `prompts/01-analyze-requirement.md` 分析业务目标、角色、模块、实体与约束

### 阶段 3：生成 OpenSpec

- 使用 `prompts/02-generate-openspec.md` 生成规格、设计和任务

### 阶段 3.5：并发计划

- 读取 `docs/concurrent-generation.md`
- 在 `generated/<project-slug>/docs/parallel-execution-plan.md` 中记录本轮是否启用并发、任务分片、文件所有权、共享契约、依赖关系、集成顺序和风险
- 如果启用并发，必须以 OpenSpec 中的 API、数据模型、权限和关键业务动作为唯一共享契约
- 不允许多个并发任务同时改同一文件；README、`.env.example`、`compose.yaml`、生产就绪清单、安全说明和可观测性说明由主控最终统一合并

### 阶段 4：生成实现

- 在 `generated/<project-slug>/` 下创建当前需求对应的实现目录
- 后端实现先读取 `docs/backend-spec.md`
- 后端实现同时读取 `docs/production-grade-rubric.md`
- 后端实现同时读取 `docs/fullstack-review-scoring.md`
- 使用 `prompts/03-generate-backend.md`
- 前端实现先读取 `docs/frontend-ui-spec.md`
- 使用 `prompts/04-generate-frontend.md`
- 部署实现先读取 `docs/deployment-spec.md`
- 使用 `prompts/05-generate-docker.md`
- 测试实现先读取 `docs/testing-spec.md`
- 测试实现同时读取 `docs/production-grade-rubric.md`
- 测试实现同时读取 `docs/fullstack-review-scoring.md`
- 使用 `prompts/06-generate-tests.md`
- 在 `generated/<project-slug>/AGENTS.md` 与 `generated/<project-slug>/CLAUDE.md` 中输出项目级 AI 协作规则
- 在 `generated/<project-slug>/docs/ai-workflow.md`、`docs/review-log.md`、`docs/fix-log.md` 中输出项目级 AI 工作流与记录模板
- 在 `generated/<project-slug>/docs/key-business-actions-checklist.md` 中输出基于当前需求的关键业务动作回归清单
- 在 `generated/<project-slug>/docs/frontend-ui-checklist.md` 中输出前端 UI 自查清单
- 在 `generated/<project-slug>/docs/production-readiness-checklist.md` 中输出生产就绪清单，至少覆盖 Logging、Metrics、Tracing、安全、Nginx、CI、健康检查、资源限制、限流、OpenAPI、前端测试和 `.dockerignore`
- 在 `generated/<project-slug>/docs/security-notes.md`、`docs/observability.md` 与 `docs/test-plan.md` 中记录安全取舍、token 存储策略、审计日志、rate limiting、metrics/tracing、测试覆盖和生产部署注意事项
- 项目级文档必须按 `docs/template-governance.md` 输出为证据索引和项目事实，不得复制模板规范全文；每个清单项都应有状态、证据路径、验证命令或风险说明
- OpenSpec 和并发计划完成后，可以并发推进后端、前端、部署、测试或审查分片；并发任务必须遵守 `docs/parallel-execution-plan.md` 的写入范围
- 并发任务完成后必须回到主控串行集成，统一核对 API、环境变量、文档证据、测试和部署资产

### 阶段 5：修复与验证

- 使用 `prompts/07-fix-and-verify.md`
- 使用 `prompts/08-security-review.md`
- 修复后必须重新核对关键业务动作回归清单，而不只是重跑构建命令
- 修复后必须重新核对生产就绪清单中的高风险项，而不只是确认文件存在

### 阶段 6：模板级审计

- 执行 `./scripts/audit_generated_project.sh generated/<project-slug>`
- 确认目录、OpenSpec、README、环境变量模板、核心入口文件齐全
- 确认生产级代码/配置证据齐全：rate limiting、request id、metrics、OpenAPI 导出、`.dockerignore`、Nginx gzip、安全管理员初始化、前端测试和业务流脚本
- 确认真实闭环证据齐全：核心 API 使用数据库-backed service/repository，前端核心动作调用真实 API/hook/mutation，readiness 探测 DB/Redis，metrics 避免 raw URL path，后端容器非 root，前端 `index.html` 与 lockfile 齐全

### 阶段 7：项目级验证

- 执行 `./scripts/verify_project.sh generated/<project-slug>`
- 如需验证容器启动，再执行 `./scripts/verify_project.sh generated/<project-slug> --with-compose-up`
- 如果生成项目存在 `generated/<project-slug>/scripts/check_business_flow.sh`，验证脚本会在 `--with-compose-up` 场景下自动执行它
- 验证脚本会执行前端测试和 OpenAPI 导出；缺失这些能力时会失败
- `verify_project.sh` 会先自动执行 `scripts/check_prerequisites.sh`，预检 `docker`、`docker compose`、`python3`、`node`、`npm` 是否存在；缺失时直接失败

## 推荐入口

通常直接从 `prompts/00-generate-from-requirement.md` 作为总控入口，让 AI 串行完成上述阶段。

在 Codex 中，也可显式使用 `$template-project-driver`；在 Claude Code 中，也可显式要求使用 `template-project-driver` skill，由 skill 按阶段驱动完整流程。

## 补充说明

- `audit_generated_project.sh` 解决”结构与规范是否达标”的模板级质量门禁，并检查前端 UI 清单、生产就绪清单、安全说明、可观测性说明、测试计划、CI/Nginx、限流、metrics、OpenAPI 等高分资产
- `verify_project.sh` 解决”项目是否真的可执行”的工程级质量门禁
- `verify_project.sh` 也作为业务校验入口，自动调用项目级 `scripts/check_business_flow.sh`
- `docs/project-asset-templates.md` 提供项目级 AI 协作、关键业务动作、前端 UI、生产就绪、安全、可观测性和测试计划资产模板
- `docs/concurrent-generation.md` 提供 OpenSpec 后的并发分片、文件所有权和集成顺序规则
- `docs/backend-spec.md`、`docs/testing-spec.md`、`docs/deployment-spec.md` 共同补齐后端、验证和交付阶段的规则入口
- `docs/fullstack-review-scoring.md` 用于把 fullstack reviewer 评分维度转成生成优先级和一票否决项
- `docs/template-governance.md` 用于控制规则源优先级、生成资产职责和去冗余策略
- 六项原则不是额外备注，而是每次生成、修复、审计和交付时都必须逐项映射到实际产物与验证动作的硬约束
