# Backend Spec

本文件是模板仓库的后端总入口规范。目标不是限定某个业务项目的领域模型，而是为 AI 生成的后端工程提供一套可执行、可验证、可维护的默认标准。

如果你只读一份后端规范，优先读本文件；如果需要补充上下文，再继续看以下文档：

- `README.md` 与 `docs/ai-workflow.md`：模板层流程、分层与项目组织参考
- `docs/testing-spec.md`：测试策略、验证边界与质量门禁
- `docs/deployment-spec.md`：运行、容器、环境与发布约束
- `docs/generation-quality.md`：模板级与项目级总体质量要求
- `docs/production-grade-rubric.md`：生产级评分硬门禁

## 1. 目标

后端生成必须同时满足三件事：

- 可运行：本地与容器环境都能启动，依赖、迁移和配置完整
- 可演进：模块边界清晰，业务代码不会堆叠在入口文件中
- 可防错：鉴权、校验、异常处理和数据一致性具备明确约束

本规范默认适用于以下常见类型：

- 管理后台 API
- 内部工具平台 API
- 工作台 / 审批 / 运营系统 API
- 列表 + 详情 + 表单 + 状态流转组合型业务系统

## 2. 通用实现原则

- 先依据 OpenSpec 明确领域模型、角色权限和状态流转，再写接口
- 先建立分层与依赖边界，再填充业务逻辑
- 先保证真实业务闭环，再补外围能力
- 先处理输入、权限、异常和事务，再谈接口数量
- 先让核心业务读写真实数据库，再谈“生产级”外围证据；ORM model、migration 和 repository 不能只是摆设

## 3. 默认技术基线

- Python 3.12+
- FastAPI
- Pydantic v2
- SQLAlchemy 2.x async
- Alembic
- MySQL 8
- Redis 7
- pytest
- ruff
- prometheus-client 或等价 metrics 方案
- Redis-backed rate limiting 中间件

不要绕开既定技术栈重写基础设施，也不要引入与模板目标不一致的框架组合。

## 4. 必须稳定的工程结构

后端默认输出到 `generated/<project-slug>/backend/`，并至少满足以下结构：

```text
backend/
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

硬规则：

- `main.py` 只负责应用装配，不承载全部业务逻辑
- `api/` 负责路由与依赖注入，不直接写复杂业务
- `services/` 负责业务动作与状态流转
- `repositories/` 负责数据访问，不泄漏 HTTP 语义
- `schemas/` 负责输入输出契约
- `core/` 负责配置、安全、日志、错误基类和横切能力
- `db/` 负责会话、基类、初始化与 Redis 封装
- `tests/` 独立存在，不混入业务目录

## 5. API 与契约规则

### 5.1 接口设计

- API 必须从 OpenSpec 中可回溯，不允许接口先行、规格缺位
- API 默认应版本化组织，例如 `api/v1`
- 路由必须按业务模块组织，不要把所有接口堆在单一路由文件
- 请求体、响应体、分页结构、错误结构都应显式建模
- 默认应提供统一响应结构，至少对成功响应、分页响应和错误响应有稳定封装
- 列表接口必须明确分页、筛选、排序策略
- 状态流转接口必须体现触发条件、权限要求和失败分支
- 路由函数应显式声明 `response_model`，禁止多数端点返回 raw `dict`。缺少 `response_model` 会导致 OpenAPI 文档不完整、前端类型推断缺失。审计脚本会验证路由目录中存在 `response_model=` 使用证据。

### 5.2 输入校验

- 所有外部输入必须通过 Pydantic v2 schema 校验
- 枚举、长度、格式、数值范围和跨字段约束必须显式声明
- 不允许直接把原始 `dict` 穿透到 service 或 repository
- 对可选字段、默认值和更新语义必须明确区分

### 5.3 错误返回

- 业务错误必须有稳定错误语义，不允许只抛裸字符串
- 必须有全局异常处理机制，统一把验证错误、业务错误和基础设施错误映射为稳定响应
- 认证失败、鉴权失败、资源不存在、冲突、校验失败必须可区分
- 错误响应应便于前端映射为用户可理解反馈
- 不允许把数据库异常原样暴露给调用方

## 6. 认证、授权与安全规则

- 数据库、Redis、JWT、CORS 等配置必须来自环境变量
- 默认采用 Bearer Token / JWT 方案时，签名密钥、过期时间和算法必须可配置
- JWT 示例密钥必须达到 32 字节以上；测试可使用固定弱密钥但不得作为生产默认值
- 管理员初始化必须通过 seed 脚本、一次性 bootstrap token 或显式环境变量控制，禁止使用 email 前缀、用户名约定等隐式提权规则
- 如果实现 Refresh Token，默认要求单独的刷新密钥或明确的刷新令牌策略，并对刷新端点做 Origin/CSRF 防护
- Refresh token 端点在签发新 access token 前，必须从数据库重新加载用户并校验其是否存在且未被禁用；不得仅凭 token 解码有效就直接签发
- Refresh Token 端点**必须在验证通过后轮换 refresh token**——删除旧 jti、签发新 refresh token、设置新 cookie；旧 refresh token 不得继续有效。如检测到已失效 jti 被重放（即 jti 不存在于存储中但 token 签名有效），应立即吊销该用户所有 refresh token（replay detection），强制重新登录
- 如果 Refresh Token 使用 Cookie，必须设置 `HttpOnly`、`SameSite=Strict`、`Secure` 环境感知，并保证 logout/delete cookie 属性一致
- 登录、注册、刷新 token、关键写操作必须接入 Redis-backed rate limiting；不能只在文档中“预留”
- 鉴权必须同时覆盖接口入口和关键业务动作，不允许只在前端控制
- 关键资源必须校验归属权、角色或管理员权限
- 对创建、更新、审核、下线、删除等写操作，必须防止越权
- 默认应提供安全响应头、中间件或明确的代理层安全头方案
- 输入校验、输出脱敏、密码散列、密钥隔离和最小权限原则必须落地
- 密码哈希默认使用 Argon2id；如因依赖或平台限制选择 bcrypt/PBKDF2，必须在 `doc/security-notes.md` 说明取舍、参数强度和后续迁移计划。不得出现文档写 Argon2/bcrypt、代码实际使用弱化算法的偏差。

不要出现以下问题：

- 把 `JWT secret`、数据库密码、Redis 地址硬编码到代码中
- 只有登录校验，没有资源级授权
- 把管理员动作暴露给普通用户
- 把内部异常、堆栈或 SQL 错误直接返回给前端
- 使用 localStorage 存储长期 token 且没有风险说明或替代方案
- 依赖 email 前缀或固定测试账号获得管理员权限
- 通过 `MemoryStore`、全局 `dict/list`、进程内变量或 JSON 文件实现用户、业务实体、状态流转、评价、安装等核心数据

## 7. 数据模型与持久化规则

### 7.1 模型设计

- 模型必须能映射当前需求中的实体、关系和状态
- 状态字段必须有明确枚举或受控值域，不要使用含糊字符串
- 唯一约束、索引、外键和级联策略必须与业务规则一致
- 审计字段至少包含创建时间、更新时间；如有操作者语义，应补充创建人 / 更新人
- 核心业务实体（如用户、主要资源）必须默认提供 `SoftDeleteMixin`（含 `deleted_at` 字段和 `is_deleted` 属性）；Repository 查询默认过滤 `deleted_at IS NULL`。仅当业务明确不需要数据恢复/合规追溯时可豁免，但必须在生产就绪清单中说明风险
- 系统级参考数据（如分类字典）和追加式记录（如版本快照）可以不使用软删除
- 涉及敏感操作（审批/拒绝/归档/删除/权限变更）的业务必须提供审计日志模型（`AuditLog`），记录 user_id、action、resource_type、resource_id、ip_address、details 和时间戳
- 审计日志必须有独立 migration、Repository 和查询端点（admin-only）
- 审计记录是只追加的，不允许更新或删除
- SQLAlchemy relationship 的 `lazy` 策略不应全局设为 `selectin` 或 `joined`；应默认使用 `lazy="raise"` 或 `lazy="select"`，在需要关联数据的查询中显式 `.options(selectinload(...))`

### 7.2 事务与一致性

- 跨多表的关键业务动作必须在 service 层定义事务边界
- 计数、评分、库存、审批状态等容易失真的数据必须有一致性策略
- 幂等或重复提交风险明确的接口，必须至少有一种保护机制
- 不要在路由层分散提交事务

### 7.3 Migration

- 生成项目必须包含 Alembic 初始化配置和首批 migration
- 数据模型变更必须同步 migration，不允许“改模型不改迁移”
- migration 应可重复执行且顺序明确
- migration 必须包含 downgrade 回滚路径
- 首次启动依赖的数据结构不得靠手工建表
- 首次启动依赖的分类、字典、管理员账号等必须提供 seed 脚本或 bootstrap 命令

### 7.4 禁止“假持久化”

生成项目不得以“先用内存 store 跑通测试，模型和 migration 以后再接”的方式交付。以下情况视为未完成数据层：

- API route 或 service 直接导入 `store = MemoryStore()`、模块级 `dict/list` 或 JSON 文件仓储。
- Repository 层存在但没有被核心 service 调用。
- 测试只覆盖内存仓储，未覆盖数据库-backed service 的事务、唯一约束或状态变更。
- readiness 只返回 `database: configured`，没有执行 `SELECT 1` 或等价数据库探针。

允许的例外：测试 fixture 或 mock 可以使用内存对象，但必须位于 `tests/`、`fixtures/` 或明确的 mock 模块中，且生产 API 不得引用。

## 8. Redis 与异步基础能力

- Redis 接入必须有明确用途，例如缓存、会话、限流、任务状态或短期临时数据
- 生产级模板默认将 Redis 用于限流和短期安全状态；不接受只有 readiness ping 的空接入
- Redis 封装必须集中管理连接和序列化约束
- 不要为了“用了 Redis”而增加无价值缓存
- 如引入后台任务、事件或异步副作用，必须明确失败重试和可观测性边界
- Rate limiting 等需要 INCR + EXPIRE 的操作必须使用 Redis pipeline 或 Lua 脚本原子执行；禁止分两步独立操作，避免进程崩溃导致 key 永久无 TTL

## 9. 可观测性与运维基础

- 必须提供结构化日志，日志格式必须包含 `request_id`（通过 `RequestIdFilter` 注入）、时间戳、级别和模块名
- 禁止使用 `if False` 等守卫禁用已实现的日志格式化逻辑
- 必须提供 request id/correlation id 中间件，并在响应头和结构化日志中输出
- 必须提供 `/metrics` 端点，至少暴露进程存活、请求计数、请求耗时、错误计数等基础指标
- `/metrics` 端点不应对外网完全开放；应通过 Nginx 限制为内网访问、独立端口或 Bearer token 保护
- HTTP metrics 的 path 标签必须归一化为路由模板，禁止直接使用 `request.url.path` 作为指标标签，避免 `/resources/1`、`/resources/2` 形成高基数
- Tracing 可以通过配置开关启用，但必须有真实接入代码或明确 extension point，不接受空字符串 placeholder
- 启动日志应明确环境、服务端口和关键依赖状态
- 健康检查必须能区分进程存活与依赖可用性，并至少校验数据库与 Redis 连通性
- readiness 必须真实执行数据库和 Redis 探针；不能用“configured”“enabled”等静态字符串替代依赖检查
- 对关键失败路径，应记录必要上下文但避免泄漏敏感信息

## 10. 性能与稳定性底线

- 列表查询默认避免 N+1 问题
- 分页接口必须限制页大小上限
- 对高频列表查询，优先使用显式 eager loading、索引与受控排序，避免隐式懒加载失控
- SQLAlchemy async 响应序列化不得触发懒加载；返回前必须 eager load 或转换为 DTO
- 写操作不得依赖前端传入的派生字段作为唯一真实来源
- 对可能增长较快的查询条件、排序字段和关联字段，应考虑索引
- 文本搜索不得默认使用无索引 `LIKE '%keyword%'` 作为唯一方案；应使用 FULLTEXT/前缀索引/受控搜索字段或在文档中说明规模限制
- 不要为了”看起来简单”而把所有业务逻辑堆成一条超长函数
- 计数器字段（如 install_count、view_count）必须使用原子 SQL update（`SET count = count + 1`），禁止先读后写的内存级 `+= 1` 操作
- SQLAlchemy async engine 推荐惰性创建（在 lifespan 或首次请求时），避免模块导入时执行 `create_async_engine` 导致测试必须预设 `DATABASE_URL`
- 连接池应配置 `pool_recycle`（建议 ≤ 3600 秒）以适配 MySQL `wait_timeout`，`pool_size` 和 `max_overflow` 应可通过环境变量调整
- 数据库 engine 和 session factory 不得作为模块级可变全局变量通过 `global` 关键字管理；推荐封装为 `app.state` 属性或 lifespan 内的局部变量，确保测试隔离和多实例安全。直接 `import SessionLocal` 绕过 `dependency_overrides` 是常见的测试泄漏来源

## 11. 必须覆盖的测试与验证点

后端至少应对以下内容提供可执行验证：

- 关键接口成功路径
- 关键业务规则
- 关键状态流转
- 权限与越权场景
- 输入校验失败场景
- 关键异常或冲突场景
- 认证失败、越权、重复提交、非法状态流转、数据库唯一约束冲突、Redis 不可用或限流触发
- migration 与启动所需的最小初始化路径

详细策略见 `docs/testing-spec.md`。

## 12. 生成时的最小执行顺序

生成后端时，建议至少按这个顺序执行：

1. 读取本文件 `docs/backend-spec.md`
2. 读取 `requirements/requirement.md`
3. 读取当前项目的 OpenSpec 与设计文档
4. 读取 `docs/testing-spec.md`
5. 读取 `docs/deployment-spec.md`
6. 先搭建目录、配置、模型与迁移，再补路由和业务逻辑
7. 最后补测试、README 运行命令与容器启动约束

## 13. 验收清单

生成完成后，至少自查以下问题：

- 是否存在清晰分层，而不是把逻辑塞进 `main.py`、路由或单文件 service
- 关键接口是否都能回溯到 OpenSpec 中的业务动作和状态流转
- 所有外部输入是否通过 schema 校验
- 关键写操作是否有权限校验、事务边界和错误处理
- 是否同步生成了 Alembic migration、测试和启动说明
- `.env.example` 是否覆盖数据库、Redis、JWT、CORS 和运行端口
- 是否存在统一响应、全局异常处理、分页、资源级授权、限流或其明确接入点
- 是否提供了 request id、结构化日志、依赖可用性健康检查、真实 `/metrics` 和 Tracing extension point
- 是否提供 OpenAPI 导出脚本，并在 CI 或验证脚本中执行
- 是否没有隐式管理员提权、弱生产密钥、长期 token localStorage 默认方案等高危安全设计
- `pytest` 与 `ruff check` 是否可执行
- 健康检查和容器启动是否与 `docs/deployment-spec.md` 一致
