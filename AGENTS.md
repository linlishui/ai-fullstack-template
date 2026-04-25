# AI Coding Rules

本文件定义 AI 在本仓库中执行生成任务时必须遵守的规则。

## 总体原则

- 不要直接跳过 OpenSpec，必须先从需求生成规格，再从规格生成实现
- 不要在需求尚未澄清时直接开始堆代码
- 先保证结构可维护，再追求生成速度
- 所有实现必须可验证、可构建、可运行

## OpenSpec 规则

- 必须先读取 `requirements/requirement.md`
- 必须先更新 `openspec/project.md`、`openspec/specs/` 与必要的 `openspec/changes/`
- 规格中必须覆盖需求、架构、接口、数据模型、任务拆分
- 没有规格，不得直接生成完整业务代码
- 生成实现时，必须统一输出到 `generated/<project-slug>/`
- 必须先初始化项目级目录，再开始写业务代码
- 项目级目录至少包含 `README.md`、`.env.example`、`compose.yaml`、`backend/`、`frontend/`

## 项目输出结构规则

默认生成结构应尽量接近以下形式：

```text
generated/<project-slug>/
  README.md
  .env.example
  compose.yaml
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
- 前端至少应提供：依赖声明、Vite 配置、应用入口、页面目录、API 封装目录

## 配置与安全规则

- 不要硬编码数据库密码、Redis 地址、JWT secret
- 所有配置必须来自环境变量
- `.env.example` 中必须给出完整示例键名
- 每个生成项目都必须有自己的 `generated/<project-slug>/.env.example`
- 敏感信息不得提交到仓库
- 认证、授权、输入校验、错误处理必须纳入实现

## 结构与模块化规则

- 业务模块必须按模块拆分
- 接口层、服务层、数据访问层职责必须清晰
- 前后端目录结构必须支持后续 AI 增量迭代
- migration、测试、文档必须与实现同步更新
- 项目级 `README.md` 必须与生成后的真实目录结构保持一致
- 验证命令必须写入项目级 `README.md`

## 质量保障规则

- 生成代码后必须补测试
- 生成代码后必须校验 Docker Compose、后端测试、前端构建
- 后端至少验证 `pytest` 与 `ruff check`
- 前端至少验证 `npm run build` 与 `npm run lint`
- 发现明显错误后应先修复再结束任务
