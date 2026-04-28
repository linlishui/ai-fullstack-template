# 提示词：修复并验证生成结果

请对当前仓库中已经生成的全栈项目执行自动修复与验证。

你必须以资深全栈架构师、生产级交付负责人和严格代码审查者的标准执行。修复目标不是把清单文字补满，而是让生成项目在当前需求范围内成为可独立运行、可验证、可维护、接近生产环境质量的工程。

修复优先级按三层执行：

- 不可降级硬门禁优先：主业务闭环、数据库-backed 持久化、真实前端 API/mutation、认证授权、输入校验、关键测试、业务流脚本、模板审计。
- 默认生产增强其次：限流、request id、日志、metrics、Tracing extension point、Nginx、Docker、CI、OpenAPI、生产就绪/安全/可观测性/测试文档。
- 按需扩展最后：复杂认证体验、后台任务、复杂缓存、运营 BI、细粒度权限矩阵、多租户等；没有需求或风险依据时不要为追求“看起来完整”而扩展。

修复文档时必须遵守 `docs/template-governance.md`：不要用复制模板规则来冒充修复；项目级文档只能补项目事实、证据路径、验证结果和剩余风险。

在开始前，先识别目标项目目录，并优先读取：

- `generated/<project-slug>/requirements/` 下的需求快照
- `generated/<project-slug>/openspec/` 下的规格文档
- `generated/<project-slug>/AGENTS.md`
- `generated/<project-slug>/CLAUDE.md`
- `generated/<project-slug>/docs/key-business-actions-checklist.md`
- `generated/<project-slug>/docs/production-readiness-checklist.md`
- `generated/<project-slug>/docs/security-notes.md`
- `generated/<project-slug>/docs/observability.md`
- `generated/<project-slug>/docs/test-plan.md`
- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/deployment-spec.md`
- `docs/frontend-ui-spec.md`
- `docs/template-governance.md`
- `docs/production-grade-rubric.md`
- `docs/fullstack-review-scoring.md`
- 按 `docs/frontend-ui-spec.md` 的引用关系按需读取前端细分文档，并优先使用其中的验收清单做前端验收
- 如果存在，读取 `generated/<project-slug>/docs/frontend-ui-checklist.md`
- 如果存在，读取 `generated/<project-slug>/docs/ai-workflow.md`、`docs/review-log.md`、`docs/fix-log.md`
- 如果存在，读取 `generated/<project-slug>/.github/workflows/ci.yml` 与 `generated/<project-slug>/infra/nginx/`

如果 `generated/<project-slug>/docs/key-business-actions-checklist.md` 不存在，必须先基于当前需求补生成一份，再继续修复与验证。
如果 `generated/<project-slug>/docs/frontend-ui-checklist.md` 不存在，必须先补生成一份前端 UI 检查清单，再继续修复与验证。
如果 `generated/<project-slug>/docs/production-readiness-checklist.md` 不存在，必须先补生成一份生产就绪清单，再继续修复与验证。
如果 `generated/<project-slug>/docs/security-notes.md`、`docs/observability.md` 或 `docs/test-plan.md` 不存在，必须先补齐，并确保内容能回溯到代码、配置、测试和 CI。
如果项目级 `AGENTS.md`、`CLAUDE.md`、`docs/ai-workflow.md`、`docs/review-log.md`、`docs/fix-log.md` 缺失，必须先补齐，再继续修复与验证。

必须至少检查以下内容：

- `cd generated/<project-slug> && docker compose config`
- `cd generated/<project-slug> && docker compose up --build`
- `cd generated/<project-slug>/backend && pytest`
- `cd generated/<project-slug>/backend && ruff check .`
- `cd generated/<project-slug>/frontend && npm run build`
- `cd generated/<project-slug>/frontend && npm run lint`
- `cd generated/<project-slug>/frontend && npm test -- --run`
- `generated/<project-slug>/scripts/export_openapi.sh`
- `scripts/audit_generated_project.sh generated/<project-slug>`
- 如果存在 `generated/<project-slug>/scripts/check_business_flow.sh`，在服务启动后必须执行它
- 对照前端审计清单检查页面结构、视觉一致性、状态完整性与响应式风险
- 对照生产就绪清单检查统一响应、全局异常处理、Logging/Metrics/Tracing、CORS、安全头、Refresh Token、CSRF、Nginx、CI、健康检查与资源限制
- 检查项目级 AI 规则文件与 review/fix 记录模板是否齐全且与当前项目结构一致
- 检查项目级安全说明、可观测性说明和测试计划是否与实际代码、配置、测试、CI 对齐
- 检查未登录、无权限和缺少前置条件时，关键点击是否会给出明确提示或跳转引导
- 检查生产级硬门禁是否真实落地：限流、OpenAPI 导出、request id、metrics、`.dockerignore`、前端测试、安全管理员初始化、业务流脚本自包含
- 检查满分导向硬门禁是否真实落地：核心后端 API 是否使用数据库-backed service/repository，是否仍有 `MemoryStore`/模块全局状态；核心前端动作是否仍用 `setTimeout`/静态 toast/硬编码统计或分类；readiness 是否真实探测 DB/Redis；metrics 是否避免 raw URL path label；后端 Dockerfile 是否非 root；前端是否有标准 `index.html` 和 lockfile

执行要求：

- 先执行 `scripts/check_prerequisites.sh`，确认 `docker`、`docker compose`、`python3`、`node`、`npm` 可用；如果缺失，先记录阻塞原因并停止后续验证
- 先根据当前需求确认 3-5 个关键业务动作，并对照项目级回归清单核对它们的验证状态
- 先按 `docs/backend-spec.md` 核对后端分层、配置、安全、迁移和健康检查是否缺项
- 先按 `docs/testing-spec.md` 核对关键测试、业务流脚本和回归路径是否缺项
- 先按 `docs/deployment-spec.md` 核对环境变量、Compose 依赖、健康检查和启动说明是否缺项
- 先按 `docs/production-grade-rubric.md` 核对生产级高分项，并把缺项直接修复为代码/脚本/配置
- 先按 `docs/fullstack-review-scoring.md` 核对 120 分评审维度，把“假持久化、假交互、假生产证据”作为最高优先级修复项
- 先核对项目级前端 UI 检查清单，并按 `docs/frontend-ui-spec.md` 校验是否缺失主题 token、状态设计、移动端适配和页面结构落地
- 先核对项目级生产就绪清单，并按三色风险标记未完成的生产级要求
- 先核对项目级 AI 协作文件是否可支撑后续 AI 继续迭代，而不是只依赖模板仓库
- 逐项运行并记录结果
- 如果发现明显错误，优先直接修复
- 修复后重新执行相关检查
- 修复后必须重新检查受影响的关键业务动作，不允许只重跑构建命令就结束
- 不要跳过失败项
- 不要把“文档说明”当成通过；评审项必须能在代码、配置、测试、脚本或 CI 中找到落地证据
- 如果某项因依赖缺失或外部环境限制无法完成，需要明确说明阻塞原因

输出要求：

- 先列出关键业务动作回归清单中的动作与最新验证状态
- 列出前端 UI 检查清单中的主要项与最新状态
- 列出生产就绪清单中的主要项与最新状态
- 列出项目级 AI 工具链文件与记录模板的状态
- 列出已执行的检查项
- 列出已修复的问题
- 列出仍未解决的问题
- 给出建议的下一步操作
