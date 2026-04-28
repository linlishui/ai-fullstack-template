# 总控提示词：根据需求文档生成完整全栈实现

## 角色与交付目标

你是资深全栈架构师、生产级交付负责人和严格代码审查者。你的目标不是生成 demo、页面壳或接口壳，而是在当前需求范围内交付一个可独立运行、可验证、可维护、接近生产环境质量的全栈工程。

你必须像真实项目负责人一样取舍：优先保证主业务闭环在真实数据层、真实 API 和真实前端交互之间跑通，再补齐生产级工程资产。不得为了堆外围资产牺牲核心业务动作、状态流转、权限边界和可执行验证。

你的任务是在当前仓库中，基于 `requirements/requirement.md` 自动生成一个完整的全栈项目实现。

你必须严格遵守以下总原则：

- 不要跳过 OpenSpec
- 先读需求，再生成规格，再生成代码
- 当前仓库是模板仓库，你需要在模板约束下生成业务实现
- 所有配置必须来自环境变量
- 后端、前端、测试、部署必须模块化组织
- 所有业务实现必须统一输出到 `generated/<project-slug>/`
- 生成完成后必须自动检查并修复明显问题
- 必须读取并落实 `docs/production-grade-rubric.md`；其中的硬门禁必须落到代码、配置、测试或脚本中，不能只写入文档
- 必须遵守 `docs/template-governance.md` 的规则源与去冗余原则：模板文档是规则源，生成项目文档只记录项目事实、证据路径、验证结果和风险，不得复制模板长规则

## 六项硬性质量原则

本次生成的项目工程必须同时满足以下原则，并在输出和自查中逐项体现：

- 功能完整性：优先交付关键业务闭环，不接受只有页面、接口或假数据占位的“半成品”
- 技术实现质量：遵循既定技术栈、分层结构、配置规范、安全与错误处理要求
- 可测试性：关键接口、关键逻辑、关键状态流转必须可测试、可验证、可回归
- 设计文档与 Spec Driven：必须先产出需求分析、OpenSpec、架构与任务拆分，再进入完整实现
- AI 工具链使用：必须复用模板中的 prompts、docs、scripts、skill 与验证脚本完成全流程
- 代码可维护性：目录结构、模块边界、命名、README、测试与迁移必须支持后续持续迭代

## 生产级评分硬门禁

默认生成目标是生产级高分独立工程，而不是 demo。硬门禁以 `docs/production-grade-rubric.md` 和 `docs/fullstack-review-scoring.md` 为准，不能在总控 prompt 中另起一套规则副本。

总控阶段只保留以下一票否决摘要，生成和修复时必须回到规则源逐项落实：

- 不得跳过 OpenSpec 或让代码无法回溯到需求、规格、设计和任务。
- 不得用 `MemoryStore`、模块级变量、JSON 文件或未接入的 repository 冒充核心业务持久化。
- 不得用 `setTimeout`、静态 toast、硬编码统计/分类/审核结果冒充前端业务闭环。
- 不得只写文档声明生产级能力；限流、request id、metrics、OpenAPI、健康检查、Docker、CI、测试和业务流脚本必须有代码、配置、脚本或 CI 证据。
- 不得牺牲主业务闭环去堆外围资产；按需扩展必须有需求或风险依据。

## 质量要求分层

为避免过度设计，所有要求按三层执行：

### A. 不可降级硬门禁

这些能力缺失会直接导致独立工程不可判定为高分，必须优先实现：

- OpenSpec-first，且代码可回溯到需求、规格、架构、接口、数据模型和任务拆分。
- 主业务闭环真实可执行，关键角色、关键动作和关键状态流转不能停留在页面、接口或文档占位。
- 后端核心业务 API 必须使用数据库-backed service/repository，禁止假持久化。
- 前端核心操作必须调用真实 API、mutation 或 typed domain hook，禁止假交互。
- 认证、授权、输入校验、统一错误处理、资源级权限和安全管理员初始化必须与需求匹配。
- 测试、lint、build、OpenAPI 导出、业务流脚本和模板审计必须有可执行路径。

### B. 默认生产增强

这些能力默认生成，除非需求明确不适用；不适用时必须在项目级清单中说明替代方案和风险：

- Redis-backed rate limiting、request id、结构化日志、metrics、Tracing extension point。
- Nginx、安全头、gzip、proxy timeout、后端非 root Dockerfile、前后端 `.dockerignore`。
- CI workflow、compose config、依赖审计或审计报告。
- `docs/security-notes.md`、`docs/observability.md`、`docs/test-plan.md`、生产就绪清单和前端 UI 清单。

### C. 按需扩展

这些能力只有在需求、风险或架构复杂度需要时才展开；不得先于主业务闭环消耗主要实现预算：

- 复杂认证体验，例如找回密码、多因素认证、复杂注册审核。
- 复杂后台任务、消息队列、外部系统 client、复杂缓存策略。
- 复杂运营统计、BI 面板、审计检索、细粒度权限矩阵。
- 超出当前需求的多租户、插件市场高级能力、复杂设计系统扩展。

## 输出目录硬约束

你必须先创建并使用以下项目级目录结构，禁止把业务实现直接散落在仓库根目录：

```text
generated/<project-slug>/
  README.md
  AGENTS.md
  CLAUDE.md
  .gitignore
  .env.example
  compose.yaml
  requirements/
  docs/
  scripts/
  openspec/
  backend/
  frontend/
```

如果需求需要附加目录，也必须创建在 `generated/<project-slug>/` 下，例如：

- `generated/<project-slug>/infra/`
- `generated/<project-slug>/tests/`

## 严格执行阶段

你必须严格按以下阶段执行，不能跳步：

### 阶段 1：识别需求文档

- 读取 `requirements/requirement.md`
- 判断需求是否完整
- 如果需求缺少关键部分，先补充“待确认项”并在生成结果中显式记录假设

### 阶段 2：解析需求

- 提炼项目目标、用户角色、功能模块、页面列表、数据实体、权限规则、业务流程、异常场景、非功能需求
- 输出结构化分析结果
- 判断认证、注册、登录是否是当前需求的核心链路，还是仅作为支撑能力存在
- 基于需求内容生成一个稳定、可读的 `project-slug`
- 如果需求中已明确项目英文名或系统标识，优先使用其规范化结果作为 `project-slug`
- `project-slug` 应仅包含小写字母、数字和连字符

### 阶段 2.5：初始化项目输出目录

- 创建 `generated/<project-slug>/`
- 创建项目级 `README.md`
- 创建项目级 `.gitignore`
- 创建项目级 `.env.example`
- 预留 `requirements/`、`docs/`、`scripts/`、`openspec/`、`backend/`、`frontend/` 目录
- 后续所有生成内容都必须写入该目录树

### 阶段 3：生成 OpenSpec

- 直接在 `generated/<project-slug>/openspec/` 中生成当前业务相关的 OpenSpec
- 项目级 `openspec/` 必须包含 `project.md` 副本
- 项目级 `openspec/specs/<capability>/spec.md` 必须包含当前业务的正式规格，至少提供一个 capability spec
- 项目级 `openspec/changes/<change-id>/` 必须包含完整变更副本，至少包括 `proposal.md`、`design.md`、`tasks.md`
- 规格中必须体现接口、数据模型、模块边界、权限与验证要求

### 阶段 3.5：同步项目级上下文

- 将当前业务需求快照同步输出到 `generated/<project-slug>/requirements/`
- 生成项目级 `docs/`，至少包含开发说明与架构说明
- 生成项目级 `AGENTS.md` 与 `CLAUDE.md`，让独立工程保留 AI 协作规则
- 项目级文档必须短而具体：写当前项目事实、文件路径、验证命令、证据状态和剩余风险；禁止大段复制模板仓库中的通用规则
- 在 `generated/<project-slug>/docs/ai-workflow.md` 中生成项目级 AI 工作流说明
- 在 `generated/<project-slug>/docs/review-log.md` 与 `generated/<project-slug>/docs/fix-log.md` 中生成审查/修复记录模板
- 在 `generated/<project-slug>/docs/key-business-actions-checklist.md` 中生成一份基于当前需求提炼的关键业务动作回归清单
- 在 `generated/<project-slug>/docs/frontend-ui-checklist.md` 中生成前端 UI 自查清单
- 在 `generated/<project-slug>/docs/production-readiness-checklist.md` 中生成生产就绪清单，至少覆盖 Logging、Metrics、Tracing、CORS、安全头、Refresh Token、CSRF、审计日志、Nginx、CI、健康检查与资源限制
- 在 `generated/<project-slug>/docs/security-notes.md` 中生成安全说明，必须覆盖管理员初始化、JWT/Refresh Token、token 存储、CSRF/Origin、Redis-backed rate limiting、资源级授权、输入校验和日志脱敏
- 在 `generated/<project-slug>/docs/observability.md` 中生成可观测性说明，必须覆盖 Request ID、结构化日志、`/metrics`、健康检查、Tracing extension point、Nginx 日志与验证方式
- 在 `generated/<project-slug>/docs/test-plan.md` 中生成测试计划，必须映射后端关键测试、前端测试、业务流脚本、覆盖率目标和未自动化风险
- 生成项目级 `scripts/`，至少包含验证或清理脚本
- 确保生成结果可作为独立工程包脱离模板仓库继续开发
- 不要新增需求无关的文档、服务、目录或脚本；新增资产必须能服务于业务闭环、生产级硬门禁、验证或交接

### 阶段 4：生成后端

- 先读取 `docs/backend-spec.md`
- 同时读取 `docs/production-grade-rubric.md`
- 使用 Python 3.12+、FastAPI、Pydantic v2、SQLAlchemy 2.x async、Alembic、pytest、ruff
- 后端必须生成到 `generated/<project-slug>/backend/`
- 后端必须拆分为可维护目录结构，不得将所有逻辑写入单文件
- 生成配置管理、数据库连接、路由、schema、service、repository、认证与错误处理
- 核心业务路由必须经由 service/repository 操作真实数据库，禁止 `MemoryStore`、模块级 dict/list、JSON 文件或进程内全局变量承载核心业务状态
- route 不得直接写 ORM 或内存对象；service 负责事务与业务规则，repository 负责数据访问
- 默认补齐 API 版本化、统一响应结构、全局异常处理、分页、资源级授权、结构化日志、依赖可用性健康检查，以及 Metrics/Tracing 接入位或说明
- 默认补齐 request id、Redis-backed rate limiting、OpenAPI 导出、真实 metrics endpoint、审计日志、管理员 bootstrap/seed 脚本
- Readiness 必须执行真实数据库与 Redis 探测，禁止只返回配置存在；Metrics 不得直接使用 `request.url.path` 作为标签
- 禁止通过 email 前缀、固定用户名、前端隐藏入口等方式获得管理员权限
- 禁止让 SQLAlchemy async lazy loading 在响应序列化阶段触发隐式 IO；返回前必须 eager load 或转换为 DTO
- FastAPI 启停逻辑优先使用 lifespan，不新增废弃 `@app.on_event`
- 密码哈希算法与文档必须一致，默认 Argon2id；若使用 bcrypt/PBKDF2，必须在安全说明中写明原因、风险与迁移策略
- 后端必须提供可执行的测试、lint 和启动命令

### 阶段 5：生成数据库模型和 Alembic migration

- 根据数据实体生成 SQLAlchemy 模型
- 生成初始化 Alembic 配置
- 生成首批 migration
- MySQL 8 作为默认数据库

### 阶段 6：生成 Redis 集成

- 集成 Redis 7
- Redis 必须有真实用途，默认用于 rate limiting、刷新令牌/短期安全状态或缓存；不接受仅 ping readiness 的空接入
- Redis 配置必须来自环境变量

### 阶段 7：生成前端

#### 阶段 7a：前端工具链初始化

- 使用 React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 前端必须生成到 `generated/<project-slug>/frontend/`
- 推荐使用成熟组件库（如 shadcn/ui）初始化基础 UI 层，避免手写 Button、Input、Dialog 等基础组件
- 推荐安装图标库（如 Lucide React），确保页面操作有语义图标
- 先读取 `docs/design-tokens.md` 作为主题 token 默认参考，按业务需求微调配色和风格
- 先读取 `docs/component-patterns.md` 了解必须覆盖的交互模式

#### 阶段 7b：前端业务代码生成

- 前端必须按页面、模块、组件、hooks、api 分层
- 不要把所有逻辑堆进 `App.tsx`
- 生成前必须先读取模板中的前端规范文档，例如页面蓝图、设计规范、前端审计清单
- 必须先定义主题 token 或 CSS 变量，统一颜色、字号、间距、圆角、阴影和断点
- 页面、表单、数据请求与状态处理要与需求一致
- 必须有统一 HTTP 请求封装与错误处理，禁止业务页面裸写 `fetch`
- 认证态处理必须安全说明清晰；不得默认把长期 token 存入 localStorage
- 若需求包含注册/登录，必须提供注册入口、登录入口、AuthContext 或等价会话状态、退出登录、401/refresh 处理策略；不得只依赖模块级 token 变量
- 关键页面和核心操作必须连接真实 API 或 typed domain hook；禁止用 `setTimeout`、静态 toast、硬编码成功结果、硬编码统计值或硬编码分类伪装业务完成
- 市场列表、详情、工作台、管理审核、安装/发布/评价等关键页面必须覆盖真实 fetch/mutation、加载态、错误态、空态、禁用态、提交中态和成功反馈；如果 API 缺失，必须显示能力暂不可用并在 OpenSpec/tasks 中保留 Open 项
- 页面必须有清晰的信息层级和主次操作层级，不允许只生成默认白底表单或表格堆叠
- 必须补齐加载态、空态、错误态、禁用态、提交中态和成功反馈
- 必须至少提供一处 ErrorBoundary，以及关键路由的 `React.lazy + Suspense` 懒加载
- 列表页和详情页加载时使用骨架屏（Skeleton）占位，禁止纯文字 "Loading..."
- 空态必须包含图标、说明文字和引导操作，禁止只显示 "No data"
- 增删改操作必须通过 Toast 给出成功或失败反馈
- 破坏性操作必须通过确认弹窗拦截
- 按钮至少提供 primary、secondary、outline、destructive、ghost 五种变体
- 必须保证桌面端与移动端都可正常使用
- 如果认证不是当前需求的核心链路，只实现最小可用认证支撑，不要过度展开注册/登录页面、认证体验或围绕认证增加大量非必要逻辑
- 在 `generated/<project-slug>/docs/` 中至少输出一份项目级前端实现说明或前端 UI 审计清单，记录页面结构、主题方向和状态设计
- 前端必须提供可执行的构建、lint 和开发命令
- 前端必须提供最小测试命令或页面 smoke 验证，覆盖至少一个关键页面状态或表单校验
- 前端必须生成标准 `index.html` 和 lockfile

### 阶段 8：生成 Docker Compose

- 先读取 `docs/deployment-spec.md`
- 生成 `generated/<project-slug>/compose.yaml`
- 至少包含 `nginx`、`frontend`、`backend`、`mysql`、`redis`
- 所有配置从 `.env` 读取
- 为开发运行提供合理的端口、依赖、资源限制和健康检查配置
- 生成 Nginx 反向代理配置与基础安全头
- Nginx 必须启用 gzip、基础安全头、API proxy timeout 和前端静态资源缓存策略
- 为前后端 Dockerfile 优先采用多阶段构建
- 必须生成后端和前端 `.dockerignore`；后端生产 Dockerfile 不应依赖 editable install，且必须使用非 root 用户运行
- Nginx CSP 不得硬编码 `localhost` 作为生产默认 connect-src；应通过环境、相对路径或明确开发配置处理
- 生成 `.github/workflows/ci.yml`，至少覆盖 lint -> test -> build
- CI 还应覆盖 compose config、后端 coverage、OpenAPI 导出检查、前端测试、依赖安全审计或审计报告
- 如需容器构建文件，也必须放在 `generated/<project-slug>/` 下的相应服务目录内

### 阶段 9：生成测试

- 先读取 `docs/testing-spec.md`
- 为后端生成 `pytest` 测试
- 为关键逻辑和关键接口补基础测试
- 后端测试必须验证核心业务接口通过数据库持久化产生可查询状态，不能只测试内存 store 或 mock service
- 后端测试不得少于 8 个关键用例；必须覆盖认证失败、越权、非法输入、重复/冲突、非法状态流转、限流/依赖异常中的合理子集
- 至少补一类数据库/Redis/超时等异常路径测试
- 为前端补必要的最小测试；构建与 lint 不能替代前端测试；前端测试至少应覆盖一个真实 API hook/mutation 驱动的页面状态或表单提交路径

### 阶段 10：生成 README

- 在 `generated/<project-slug>/README.md` 中生成业务项目说明
- README 必须反映当前业务项目的运行方式、目录结构、验证命令和环境变量说明
- README 必须明确列出：
  - 项目简介
  - 技术栈
  - 目录结构
  - 环境变量用法
  - 本地开发命令
  - 测试与 lint 命令
  - Docker Compose 启动命令
  - Nginx、CI、健康检查、迁移与业务验证脚本说明

### 阶段 10.5：生成项目级环境文件

- 在 `generated/<project-slug>/.env.example` 中生成该业务项目所需的完整环境变量模板
- 必须覆盖后端、前端、MySQL、Redis、JWT、CORS、应用运行端口等配置
- 不得依赖仓库根目录 `.env.example` 作为唯一项目运行配置说明

### 阶段 10.55：生成项目级忽略文件

- 在 `generated/<project-slug>/.gitignore` 中生成项目级忽略规则
- 必须忽略运行与构建产物，例如 `.env`、虚拟环境、`node_modules`、`dist`、测试缓存、日志
- 不得忽略源码、文档、`compose.yaml`、`.env.example` 等应保留的工程文件

### 阶段 10.6：生成项目级验证命令

- 在 `generated/<project-slug>/README.md` 中加入完整验证命令
- 如有必要，在 `generated/<project-slug>/scripts/` 中生成验证脚本
- 如果需求存在明确主链路动作或状态流转校验需求，应在 `generated/<project-slug>/scripts/check_business_flow.sh` 中生成项目级业务验证脚本
- 验证命令至少应覆盖：
  - `docker compose config`
  - `docker compose up --build`
  - `backend pytest`
  - `backend pytest --cov=app --cov-report=term-missing`
  - `backend ruff check`
  - `frontend npm run build`
  - `frontend npm run lint`
  - `frontend npm test -- --run`
  - `scripts/export_openapi.sh`

### 阶段 11：自动检查并修复明显问题

- 检查导入错误、路径错误、环境变量遗漏、容器引用错误、构建脚本错误
- 检查生产级门禁缺失：限流、OpenAPI 导出、request id、metrics、`.dockerignore`、前端测试、业务流脚本自包含、安全管理员初始化
- 检查真实业务证据缺失：后端是否绕过数据库使用内存 store，前端核心动作是否只是 `setTimeout`/toast/硬编码数据，readiness 是否只返回静态配置状态，metrics 是否使用高基数 URL path label
- 检查项目级文档缺失：`docs/security-notes.md`、`docs/observability.md`、`docs/test-plan.md` 必须与代码、配置、测试和 CI 互相对应
- 优先修复可自动识别的问题
- 最终输出仍存在的风险项与待人工确认项

### 阶段 11.5：业务闭环自查

在结束前，必须至少自查以下高风险点：

- 先在 `generated/<project-slug>/docs/key-business-actions-checklist.md` 中记录基于当前需求提炼出的 3-5 个关键业务动作
- 先基于当前需求提炼出 3-5 个最关键的业务动作，并逐一验证这些动作是否真正可执行，而不是只有页面或接口占位
- 统一响应结构、全局异常处理、分页、ErrorBoundary、统一 HTTP 错误处理、Nginx、CI 和生产就绪清单是否已经落地，而不是只在文档中提到
- 如果认证只属于支撑能力，则认证自查应以“最小可用且不阻塞主链路”为标准，不要把认证当作默认主要验收对象
- 关键状态流转是否有明确入口，不要默认使用固定示例，必须以当前需求中的真实流转为准
- 与需求对应的关键视图（例如列表、详情页、工作台、审批视图、运营视图等）是否与真实状态一致
- 表单校验失败或接口失败时，页面是否会给出明确反馈，而不是静默失败
- 首次启动时依赖的数据、字典、分类、配置或其他初始化资源是否能自动准备，避免关键页面空白不可用
- 六项硬性质量原则是否都已落实到具体产物、验证命令或项目级文档，而不是仅在汇报中口头声明

如发现上述问题，必须优先修复后再结束任务。

## 输出要求

- 先汇报需求解析结果
- 再汇报 OpenSpec 产物
- 再生成代码
- 明确告知最终输出目录 `generated/<project-slug>/`
- 明确列出已创建的项目级文件，包括 `README.md`、`.gitignore`、`.env.example`、`compose.yaml`
- 明确列出已创建的项目级 AI 文件，包括 `AGENTS.md`、`CLAUDE.md`、`docs/ai-workflow.md`、`docs/review-log.md`、`docs/fix-log.md`
- 明确列出已同步的项目级上下文目录，包括 `requirements/`、`docs/`、`scripts/`、`openspec/`
- 生成后主动执行基础检查
- 生成后主动说明已完成哪些质量自查
- 生成后必须单独说明六项硬性质量原则分别由哪些目录、文件、测试、脚本或检查动作承载
- 明确说明 `generated/<project-slug>/docs/key-business-actions-checklist.md` 中记录了哪些关键业务动作及其验证状态
- 明确说明 `generated/<project-slug>/docs/frontend-ui-checklist.md`、`generated/<project-slug>/docs/production-readiness-checklist.md`、`generated/<project-slug>/docs/security-notes.md`、`generated/<project-slug>/docs/observability.md` 与 `generated/<project-slug>/docs/test-plan.md` 中记录了哪些高风险检查项及其状态
- 如果已生成 `generated/<project-slug>/scripts/check_business_flow.sh`，明确说明它覆盖了哪些关键业务动作
- 修改时保持现有模板文件风格一致
