# AI Coding Rules

本文件定义 AI 在本仓库中执行生成任务时必须遵守的规则。

## 总体原则

- AI 必须以资深全栈架构师、生产级交付负责人和严格代码审查者的标准执行生成任务
- 目标是在当前需求范围内交付可独立运行、可验证、可维护、接近生产环境质量的全栈工程，而不是 demo、页面壳或接口壳
- 主业务闭环优先级高于外围生产资产；不得为了堆 Nginx、CI、文档、metrics 或 Tracing 占位而牺牲真实业务动作、状态流转、权限和测试
- 必须遵守 `docs/template-governance.md` 的规则源优先级与去冗余原则；生成项目文档只写项目事实、证据路径、验证结果和风险，不复制模板长规则
- 如启用并发生成，必须遵守 `docs/concurrent-generation.md`；并发只能发生在 OpenSpec 和共享契约稳定之后，且必须记录文件所有权、集成顺序和验证结果
- 不要直接跳过 OpenSpec，必须先从需求生成规格，再从规格生成实现
- 不要在需求尚未澄清时直接开始堆代码
- 先保证结构可维护，再追求生成速度
- 所有实现必须可验证、可构建、可运行
- 生成的项目工程必须同时满足以下六项原则：功能完整性、技术实现质量、可测试性、设计文档与 Spec Driven、AI 工具链使用、代码可维护性

## 六项生成原则

### 1. 功能完整性

- 优先交付需求中的关键业务闭环，不允许只生成页面壳、接口壳或静态假数据流程
- 关键角色必须能完成各自核心动作，关键状态流转必须可真正执行并可验证
- 必须覆盖加载态、空态、错误态、禁用态、提交中态与成功反馈，避免“功能存在但不可用”

### 2. 技术实现质量

- 实现必须遵循仓库约定的技术栈、分层结构与配置规范
- 前后端都应优先采用成熟方案，不重复手写基础设施或基础 UI 组件
- 认证、鉴权、输入校验、错误处理、环境变量配置和启动流程必须完整
- 默认以生产级高分基线为目标，显式覆盖统一响应、全局异常处理、分页、可观测性、安全头、Nginx、CI/CD、前端容错与健康检查
- 必须落实 `docs/production-grade-rubric.md` 中的硬门禁，包括限流、request id、metrics、OpenAPI 导出、前端测试、`.dockerignore`、安全管理员初始化和业务流验证
- 必须对齐 `docs/fullstack-review-scoring.md` 的 120 分评审口径，禁止用假持久化、假前端交互或假生产证据冒充高分实现

### 3. 可测试性

- 关键业务接口、关键状态流转与关键业务动作必须具备可执行验证路径
- 除基础构建外，还必须提供测试、lint 与必要的项目级业务验证脚本或检查清单
- 生成完成后必须先修复明显错误，再结束任务

### 4. 设计文档与 Spec Driven

- 需求、OpenSpec、架构、接口、数据模型、任务拆分必须先于完整实现产出
- 代码实现必须能回溯到项目级 `requirements/`、`openspec/` 与 `docs/`
- 任何新增能力都应优先补规格与设计，而不是直接改业务代码

### 5. AI 工具链使用

- 必须按模板既定工作流执行：先需求分析，再 OpenSpec，再实现，再测试，再审计，再验证
- 必须复用模板中的 prompts、docs、scripts 与 skill，而不是绕开现有工具链随意生成
- 生成结束时必须明确说明已执行的审计、验证与自查动作

### 6. 代码可维护性

- 后端、前端、脚本、文档、测试必须按职责拆分，避免单文件堆叠
- 目录结构、命名、依赖组织和 README 必须支持后续 AI 与人工继续迭代
- migration、测试、文档与环境变量模板必须与实现同步更新

## OpenSpec 规则

- 必须先读取 `requirements/requirement.md`
- 必须先在 `generated/<project-slug>/openspec/` 中生成当前业务相关的 OpenSpec
- 生成结果必须是可单独迁移和继续开发的独立工程包
- 规格中必须覆盖需求、架构、接口、数据模型、任务拆分
- 没有规格，不得直接生成完整业务代码
- 生成实现时，必须统一输出到 `generated/<project-slug>/`
- 必须先初始化项目级目录，再开始写业务代码
- 项目级目录至少包含 `README.md`、`.gitignore`、`.env.example`、`compose.yaml`、`requirements/`、`docs/`、`scripts/`、`backend/`、`frontend/`、`openspec/`
- 如按生产级基线生成，应同时包含 `infra/nginx/`、`.github/workflows/`、`.gitlab-ci.yml` 与 `.claude/skills/find-skills/`
- 独立工程默认还应包含项目级 `AGENTS.md`、`CLAUDE.md`、AI 协作记录文档、安全说明、可观测性说明与测试计划

## 项目输出结构规则

默认生成结构应尽量接近以下形式：

```text
generated/<project-slug>/
  README.md
  AGENTS.md
  CLAUDE.md
  .gitignore
  .env.example
  compose.yaml
  .gitlab-ci.yml
  requirements/
  docs/
    ai-workflow.md
    parallel-execution-plan.md
    review-log.md
    fix-log.md
    security-notes.md
    observability.md
    test-plan.md
  scripts/
  openspec/
  backend/
  frontend/
  infra/
    nginx/
  .github/
    workflows/
  .claude/
    skills/
      find-skills/
```

如业务需要扩展目录，也必须放在 `generated/<project-slug>/` 下，不得散落到模板根目录。

## 后端规则

- 不要把所有后端代码写进 `main.py`
- 后端实现默认放在 `generated/<project-slug>/backend/`
- 必须按模块拆分，例如 `api/`、`models/`、`schemas/`、`services/`、`repositories/`、`core/`
- 必须使用 `FastAPI + Pydantic v2 + SQLAlchemy 2.x async + Alembic`
- 数据库连接、Redis 连接、JWT 配置必须来自环境变量
- 必须为关键业务接口补充测试
- 默认提供 `api/v1` 路由、统一响应结构、全局异常处理、分页、资源级授权、结构化日志、数据库与 Redis 连通性健康检查
- 核心业务实体模型必须使用 `SoftDeleteMixin`（含 `deleted_at` 字段），Repository 查询默认添加 `deleted_at IS NULL` 过滤
- 涉及审批/拒绝/归档等状态流转的管理操作必须写审计日志（AuditLog 模型），记录操作者、动作、资源和客户端信息
- 结构化日志必须通过 `RequestIdFilter` 注入 request_id 到所有 log record，禁止使用 `if False` 等方式禁用
- 推荐后端目录骨架如下：

```text
generated/<project-slug>/backend/
  pyproject.toml
  alembic.ini
  app/
    api/
    core/
    db/
    models/
    repositories/
    schemas/
    services/
    main.py
  migrations/
  tests/
```

- `main.py` 只作为应用入口，不承载全部业务逻辑
- `core/` 用于配置、鉴权、安全、日志、基础组件
- `db/` 用于数据库会话、基类、初始化与 Redis 封装
- `tests/` 必须独立存在，不要把测试混入业务目录
- 后端至少应提供：依赖声明、应用入口、配置管理、迁移目录、测试目录
- 如实现 Refresh Token，应补 Cookie 安全属性与 CSRF 防护
- Refresh Token 端点必须实现 token 轮换——验证旧 token 后签发新 refresh token 并使旧 jti 失效；检测到已失效 jti 重放时应吊销该用户全部 refresh token
- 管理员初始化必须通过 seed/bootstrap 脚本或显式环境变量控制，禁止 email 前缀、固定用户名或前端开关提权
- 必须实现 Redis-backed rate limiting，至少保护登录、注册、刷新 token 和关键写操作
- 必须提供 request id 中间件、结构化日志、真实 metrics endpoint 与 OpenAPI 导出脚本
- SQLAlchemy async 返回响应前必须 eager load 或转换 DTO，禁止响应序列化阶段触发懒加载 IO
- SQLAlchemy 模型的 `Mapped[]` 注解中可空字段使用 `Optional[X]` 而非 `X | None`，以兼容旧版 Python 环境下 SQLAlchemy 的运行时 eval；ruff 配置应忽略 UP045/UP007/UP037 对模型文件的建议
- 所有继承 `SoftDeleteMixin` 或 `Base` 的模型文件必须导入 `from datetime import datetime` 和 `from typing import Optional`（加 `# noqa: F401`），因为 SQLAlchemy 在子类 namespace 中 eval 父类/mixin 的注解
- 若需求复杂，可新增 `tasks/`、`clients/`、`workers/` 等目录，但必须职责明确

## 前端规则

- 不要把所有前端代码写进 `App.tsx`
- 前端实现默认放在 `generated/<project-slug>/frontend/`
- 必须按页面、组件、hooks、api、schemas、features 或 modules 拆分
- 表单校验优先使用 `React Hook Form + Zod`
- 服务端数据获取优先使用 `TanStack Query`
- UI 应保持可扩展，不要生成所有逻辑堆叠在单一组件中
- 必须有统一 HTTP 客户端与错误处理，禁止业务页面裸写 `fetch`
- 必须至少提供一处 ErrorBoundary，以及关键路由的 `React.lazy + Suspense` 懒加载
- 推荐使用成熟组件库（如 shadcn/ui）搭建基础 UI 层，避免手写已有的基础 UI 组件（Button、Input、Dialog 等）
- 推荐使用图标库（如 Lucide React），操作按钮、菜单项、状态标识应带语义图标
- 列表和详情页加载时推荐使用骨架屏（Skeleton）占位，避免纯文字 "Loading..."
- 增删改操作应通过 Toast 提示给出成功或失败反馈
- 破坏性操作（删除、下线等）应通过确认弹窗拦截
- 禁止在页面中直接裸写原生 `select`、`button`、`input` 作为业务控件；必须优先封装为统一 UI 组件或复用成熟组件库组件，以保证样式和交互一致性
- 所有操作按钮默认必须保证 `whitespace-nowrap`，不得因为容器挤压而换行；若空间不足，应优先调整布局、最小宽度或改为折叠操作，而不是允许按钮文本断裂
- 列表卡片、表格行、筛选栏、审核区、表单操作区中出现的标题、分类名、版本号和按钮文本，必须显式处理 `truncate`、换行策略或最小宽度，禁止依赖浏览器默认布局
- 筛选区、搜索区、操作区使用 `grid` 或 `flex` 时，必须定义最小列宽或 `minmax(...)` 约束，避免下拉框、输入框、按钮在窄宽度下变形
- 主题 token 默认参考 `docs/design-tokens.md`，可按业务需求调整
- 交互模式应覆盖 `docs/component-patterns.md` 中定义的必要模式
- 前端视觉实现必须优先遵循项目级设计规范，不允许只生成“能用但无层次”的默认样式
- 必须先定义主题变量或设计 token，例如颜色、字号、间距、圆角、阴影、断点
- 页面必须体现明确的信息层级、主次按钮层级和状态反馈，不要只堆表单和表格
- 必须补齐加载态、空态、错误态、禁用态、提交中态与成功反馈，不允许静默失败
- 必须兼顾桌面端和移动端，不允许只按宽屏静态排版
- 优先生成可复用布局和业务组件，不要在页面里大量内联样式和重复 class
- 推荐前端目录骨架如下：

```text
generated/<project-slug>/frontend/
  package.json
  vite.config.ts
  src/
    app/
    api/
    components/
    features/
    hooks/
    lib/
    pages/
    schemas/
    App.tsx
    main.tsx
```

- `App.tsx` 只负责应用装配、路由或全局布局，不承载全部页面逻辑
- 业务页面优先放入 `pages/` 或 `features/`
- 通用 UI 组件与业务组件应适当分离
- API 请求封装、表单 schema、数据查询逻辑应独立组织
- 生成前端时必须参考模板中的页面蓝图、设计规范、交互模式和审计清单；生成项目时也应同步输出项目级前端实现说明或检查清单
- 前端至少应提供：依赖声明、Vite 配置、应用入口、页面目录、API 封装目录
- 前端必须提供最小测试命令，默认 `npm test -- --run`，覆盖关键页面、表单、空态/错误态或未登录引导中的合理子集
- 前端测试至少提供 3 个测试文件，分别覆盖 API client、认证流程、页面交互中不同类别的验证路径；仅有 1 个冒烟测试不满足模板要求
- 需要认证的页面必须有路由级守卫（ProtectedRoute），未登录时重定向到登录页；全局导航必须根据认证状态动态显示登录/登出入口；统一 HTTP client 必须实现 401 → refresh → retry 自动刷新机制；App 初始化必须尝试 session 恢复
- 不得默认把长期 token 存入 localStorage；如采用 bearer token，应在 `docs/security-notes.md` 中说明 XSS 风险与替代方案

## 配置与安全规则

- 不要硬编码数据库密码、Redis 地址、JWT secret
- 所有配置必须来自环境变量
- `.env.example` 中必须给出完整示例键名
- 每个生成项目都必须有自己的 `generated/<project-slug>/.env.example`
- 每个生成项目都必须有自己的 `generated/<project-slug>/.gitignore`
- 项目级 `.gitignore` 必须忽略运行与构建产物，例如 `.env`、虚拟环境、`node_modules`、`dist`、测试缓存、日志
- 项目级 `.gitignore` 不得错误忽略源码、`README.md`、`compose.yaml` 等工程文件
- 敏感信息不得提交到仓库
- 认证、授权、输入校验、错误处理必须纳入实现
- 必须同时提供 `.env.example`（开发默认）和 `.env.production.example`（生产安全默认，COOKIE_SECURE=true，密钥占位标注 REQUIRED）
- 后端 Settings 必须声明 `ENVIRONMENT: str = "development"`，并在生产环境下通过 validator 强制安全配置
- 必须提供 `compose.prod.yml` 作为生产部署覆盖（移除暴露端口、声明资源限制、stop_grace_period ≥ 30s）

## 结构与模块化规则

- 业务模块必须按模块拆分
- 接口层、服务层、数据访问层职责必须清晰
- 前后端目录结构必须支持后续 AI 增量迭代
- 项目级 `requirements/` 必须跟随生成项目一起输出，至少包含当前业务需求快照
- 项目级 `docs/` 必须跟随生成项目一起输出，至少包含开发与架构说明
- 项目级 `docs/` 还应包含 `key-business-actions-checklist.md`、`frontend-ui-checklist.md`、`production-readiness-checklist.md`、`security-notes.md`、`observability.md`、`test-plan.md`
- 项目级 AI 协作文件应跟随生成项目一起输出，至少包含 `AGENTS.md`、`CLAUDE.md`、`docs/ai-workflow.md`、`docs/parallel-execution-plan.md`、`docs/review-log.md`、`docs/fix-log.md`
- OpenSpec 仅保留在项目级 `generated/<project-slug>/openspec/` 中，不再在模板根目录维护业务级 OpenSpec 副本
- 项目级 `openspec/` 必须跟随生成项目一起输出，至少包含 `project.md`、`specs/<capability>/spec.md` 形式的当前业务规格，以及 `changes/<change-id>/proposal.md`、`design.md`、`tasks.md` 等完整变更文档
- 项目级 `scripts/` 必须跟随生成项目一起输出，至少包含验证或清理等项目级辅助脚本
- migration、测试、文档必须与实现同步更新
- 项目级 `README.md` 必须与生成后的真实目录结构保持一致
- 验证命令必须写入项目级 `README.md`

## 质量保障规则

- 生成代码后必须补测试
- 生成代码后必须校验 Docker Compose、后端测试、前端构建
- 后端应验证 `pytest --cov=app --cov-report=term-missing` 与 `ruff check`
- 前端至少验证 `npm run build`、`npm run lint` 与 `npm test -- --run`
- 必须验证 OpenAPI 导出脚本和项目级业务流脚本
- 必须执行模板级审计 `scripts/audit_generated_project.sh generated/<project-slug>`，确保安全、可观测性、测试计划、CI、Nginx、限流、metrics、OpenAPI 等生产级证据齐全
- 前端除 `build` 和 `lint` 外，还必须对照 `docs/frontend-ui-spec.md` 中的验收清单做一轮视觉与可用性自查，重点检查按钮换行、控件变形、长文本溢出和移动端筛选区布局
- 生成项目还应补齐 `infra/nginx/`、`.github/workflows/ci.yml`、`.gitlab-ci.yml`、`.claude/skills/find-skills/`、生产就绪清单与必要时的业务流验证脚本
- 发现明显错误后应先修复再结束任务
