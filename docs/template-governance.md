# Template Governance

本文件定义模板规则源、生成资产边界和去冗余原则。目标是在保持 120 分高分门禁的同时，避免提示词、文档和生成项目资产互相复制、互相漂移。

## 1. 规则源优先级

当规则重复或冲突时，按以下顺序判断：

1. `AGENTS.md`：仓库级硬规则和不可违背约束。
2. `docs/ai-workflow.md`：阶段顺序、质量分层和执行路径。
3. `docs/fullstack-review-scoring.md`：120 分评分口径、取舍优先级和一票否决项。
4. `docs/production-grade-rubric.md`：生产级硬门禁。
5. 领域规范：`docs/backend-spec.md`、`docs/frontend-ui-spec.md`、`docs/testing-spec.md`、`docs/deployment-spec.md`。
6. prompts：阶段执行入口，只应引用和落实规则源，不应成为另一套长期维护的规则副本。
7. 生成项目文档：记录当前项目事实、证据位置、验证结果和剩余风险，不应复制模板规则全文。

## 2. 生成资产职责

生成项目必须保留必要的独立工程资产，但每个资产应职责清晰：

- `README.md`：运行、验证、目录、环境变量、业务入口和故障排查。
- `AGENTS.md` / `CLAUDE.md`：项目级 AI 协作入口，只写本项目技术栈、验证命令、禁止事项和增量开发规则。
- `docs/architecture.md`：当前项目架构事实、模块边界和关键设计决策。
- `docs/development.md`：本地开发、依赖安装、迁移、种子数据和常见任务。
- `docs/key-business-actions-checklist.md`：当前需求提炼出的 3-5 个关键业务动作和验证状态。
- `docs/frontend-ui-checklist.md`：当前页面的状态、布局、真实 API 对接和已知 UI 风险。
- `docs/production-readiness-checklist.md`：生产级证据索引，按项链接到代码、配置、CI、脚本或测试。
- `docs/security-notes.md`：当前项目安全实现、取舍和剩余风险。
- `docs/observability.md`：当前项目日志、metrics、health、tracing 和验证方式。
- `docs/test-plan.md`：当前项目测试矩阵、命令、覆盖范围和未自动化风险。
- `docs/review-log.md` / `docs/fix-log.md`：审查与修复记录，只记录本轮事实，不复制规范。

## 3. 去冗余原则

- 不复制模板长规则：生成项目文档只写本项目事实、证据路径和风险。
- 不写空泛清单：每个 checklist 项必须有状态、文件路径、命令或明确风险。
- 不为“看起来完整”增加资产：新目录、新文档、新服务必须服务于当前需求、验证或生产级硬门禁。
- 不重复维护同一规则：通用规则留在模板 `docs/`，项目文档用相对路径或简短说明引用。
- 不让文档替代实现：任何生产级声明必须能在代码、配置、测试、脚本或 CI 中找到证据。

## 4. 资产规模控制

默认生成结构保持完整，但内容应按需求复杂度收敛：

- 小型需求：保留全部必要文件，但文档以证据索引和风险摘要为主，避免长篇模板化描述。
- 中型需求：补齐主要设计说明、测试矩阵和生产就绪证据。
- 复杂需求：再展开细粒度权限、后台任务、审计检索、复杂缓存、扩展部署等按需资产。

无论规模如何，不得降低不可降级硬门禁：OpenSpec-first、真实业务闭环、真实持久化、真实前端 API/mutation、关键测试、业务流脚本和模板审计。
