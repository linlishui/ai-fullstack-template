# AI Coding Rules

本文件定义 AI 在本仓库中执行生成任务时必须遵守的规则。

## 总体原则

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

## 项目输出结构规则

默认生成结构应尽量接近以下形式：

```text
generated/<project-slug>/
  README.md
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

如业务需要扩展目录，也必须放在 `generated/<project-slug>/` 下，不得散落到模板根目录。

## 后端规则

- 不要把所有后端代码写进 `main.py`
- 后端实现默认放在 `generated/<project-slug>/backend/`
- 必须按模块拆分，例如 `api/`、`models/`、`schemas/`、`services/`、`repositories/`、`core/`
- 必须使用 `FastAPI + Pydantic v2 + SQLAlchemy 2.x async + Alembic`
- 数据库连接、Redis 连接、JWT 配置必须来自环境变量
- 必须为关键业务接口补充测试
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
- 若需求复杂，可新增 `tasks/`、`clients/`、`workers/` 等目录，但必须职责明确

## 前端规则

- 不要把所有前端代码写进 `App.tsx`
- 前端实现默认放在 `generated/<project-slug>/frontend/`
- 必须按页面、组件、hooks、api、schemas、features 或 modules 拆分
- 表单校验优先使用 `React Hook Form + Zod`
- 服务端数据获取优先使用 `TanStack Query`
- UI 应保持可扩展，不要生成所有逻辑堆叠在单一组件中
- 推荐使用成熟组件库（如 shadcn/ui）搭建基础 UI 层，避免手写已有的基础 UI 组件（Button、Input、Dialog 等）
- 推荐使用图标库（如 Lucide React），操作按钮、菜单项、状态标识应带语义图标
- 列表和详情页加载时推荐使用骨架屏（Skeleton）占位，避免纯文字 "Loading..."
- 增删改操作应通过 Toast 提示给出成功或失败反馈
- 破坏性操作（删除、下线等）应通过确认弹窗拦截
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

## 结构与模块化规则

- 业务模块必须按模块拆分
- 接口层、服务层、数据访问层职责必须清晰
- 前后端目录结构必须支持后续 AI 增量迭代
- 项目级 `requirements/` 必须跟随生成项目一起输出，至少包含当前业务需求快照
- 项目级 `docs/` 必须跟随生成项目一起输出，至少包含开发与架构说明
- OpenSpec 仅保留在项目级 `generated/<project-slug>/openspec/` 中，不再在模板根目录维护业务级 OpenSpec 副本
- 项目级 `openspec/` 必须跟随生成项目一起输出，至少包含 `project.md`、`specs/<capability>/spec.md` 形式的当前业务规格，以及 `changes/<change-id>/proposal.md`、`design.md`、`tasks.md` 等完整变更文档
- 项目级 `scripts/` 必须跟随生成项目一起输出，至少包含验证或清理等项目级辅助脚本
- migration、测试、文档必须与实现同步更新
- 项目级 `README.md` 必须与生成后的真实目录结构保持一致
- 验证命令必须写入项目级 `README.md`

## 质量保障规则

- 生成代码后必须补测试
- 生成代码后必须校验 Docker Compose、后端测试、前端构建
- 后端至少验证 `pytest` 与 `ruff check`
- 前端至少验证 `npm run build` 与 `npm run lint`
- 发现明显错误后应先修复再结束任务
