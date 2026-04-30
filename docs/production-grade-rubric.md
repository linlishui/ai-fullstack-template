# Production Grade Rubric

本文件把严格全栈评审中的高频扣分项转成模板硬门禁。后续生成项目时，AI 不应把这些能力只写进文档或清单，而应默认落到代码、配置、测试和验证脚本中。

## 1. Hard Gates

生成项目必须默认满足以下门禁；若业务明确不需要某项，必须在 `docs/production-readiness-checklist.md` 中写明替代方案与风险。

- 认证与授权：不得使用 email 前缀、用户名约定、前端隐藏按钮等方式获得管理员权限；管理员初始化必须通过 seed 脚本、一次性 bootstrap token 或显式环境变量控制。
- 密钥安全：`.env.example` 必须包含 32 字节以上示例 JWT secret，并明确生产必须替换；不得在代码中硬编码真实密钥。
- Refresh Token：若使用 Cookie，必须设置 `HttpOnly`、`Secure` 环境感知、`SameSite=Strict`，并在 refresh/logout 端点做 Origin/CSRF 校验；refresh 端点必须在每次成功验证后**轮换 refresh token**（删除旧 jti、签发新 token、更新 cookie），旧 refresh token 不得继续有效；若检测到已失效 jti 被重放，应吊销该用户全部 refresh token。若不实现 refresh token，必须缩短 access token 有效期并记录取舍。
- Token 存储：前端不得默认把长期 token 放进 `localStorage`；如为了内部工具使用 bearer token，必须在文档中标注 XSS 风险和替代方案。
- Rate Limiting：登录、注册、刷新 token、写操作必须有 Redis-backed rate limiting 或明确的中间件实现，不接受“预留”。
- 真实持久化：业务 API 必须通过数据库-backed service/repository 执行核心读写，不得使用 `MemoryStore`、模块级 `dict/list`、JSON 文件或进程内全局变量承载用户、业务实体、状态流转、安装、评价等核心数据。内存 fake 仅允许出现在测试 fixture、mock 或演示脚本中。
- 统一异常：不得让 `IntegrityError`、SQLAlchemy async lazy loading、内部堆栈以 500 原样泄露；数据库唯一约束冲突必须映射为稳定业务错误。
- 可观测性：必须有 request id 中间件、结构化访问日志、`/metrics` 可被 Prometheus 抓取；Tracing 可以是可开关集成，但必须有真实接入代码或清晰 extension point。
- Metrics 标签：HTTP metrics 的 path 标签必须使用路由模板（例如 `/api/v1/skills/{skill_id}`）而不是实际 URL（例如 `/api/v1/skills/123`），避免高基数。
- OpenAPI：FastAPI 项目必须保留 `/openapi.json`，并提供 `scripts/export_openapi.sh` 导出到 `docs/openapi.json`。
- Nginx：必须启用 gzip、基础安全头，生产配置应包含合理缓存策略和 API proxy 超时。
- Docker：必须提供 `.dockerignore`；生产 Dockerfile 不应依赖 editable install；镜像构建不应复制 `.venv`、`node_modules`、`dist` 等本地产物；后端运行镜像默认必须使用非 root 用户。
- 测试：后端测试不得少于 8 个关键用例，必须覆盖成功、认证失败、越权、非法输入、重复/冲突、状态非法流转、依赖异常或超时中的合理子集。
- 前端测试：至少提供 3 个测试文件，覆盖 API client、认证流程、页面交互中至少 3 个不同类别；仅有 `build`/`lint` 或仅 1 个冒烟测试不视为完整前端验证。
- 前端真实闭环：需求中的核心页面和关键按钮必须调用真实 API 或明确的 domain action hook；禁止用 `setTimeout`、静态 toast、硬编码统计数字、硬编码分类选项伪造创建、审核、安装、评价、统计等核心动作。
- 前端认证闭环：如需求包含注册/登录，必须提供注册入口、登录入口、认证状态上下文、未登录引导、登出和 refresh/401 处理策略；access token 可保存在内存，但刷新后必须能通过 refresh cookie 恢复会话或明确短 token 取舍。统一 HTTP client 必须实现 401 → refresh → retry 自动刷新机制；App 初始化必须尝试 session 恢复；需要认证的路由必须有路由级守卫（ProtectedRoute），未登录时重定向到登录页。
- 前端 HTML 基线：Vite `index.html` 必须包含标准 `<!DOCTYPE html>`、`html lang`、`meta charset`、`meta viewport` 和 `title`。
- 依赖锁定：前端必须提交 `package-lock.json`、`pnpm-lock.yaml` 或 `yarn.lock`；后端应使用 lock/constraints 或在 README/CI 中说明可复现安装策略。
- 业务流：如果需求存在主链路，`scripts/check_business_flow.sh` 必须自包含、可重复执行、无需人工 token，且覆盖关键角色差异。
- 软删除：核心业务实体模型必须包含 `SoftDeleteMixin` 或等价 `deleted_at` 字段，Repository 查询默认过滤已删除记录。
- 审计日志：涉及状态流转审批（approve/reject/archive）或权限变更的业务必须有 AuditLog 模型、独立 migration 和 admin 查询端点。
- 多环境配置：必须同时提供 `.env.example`（开发）和 `.env.production.example`（生产）；后端 Settings 必须声明 `ENVIRONMENT` 字段；必须存在 `compose.prod.yml` 生产覆盖。

## 2. Scoring Targets

生成目标不是“能跑”，而是默认达到以下分数基线：

- 功能完整性与交互设计：关键页面必须有真实状态流转入口，不允许只有后端接口。
- 安全性：默认不得存在高危项；中危项必须有修复计划和风险说明。
- 性能：列表分页必须有最大 page size；搜索避免无索引全表扫描，必要时建立 FULLTEXT/前缀索引或说明限制。
- API 设计：必须有版本化 API、统一响应、统一错误码、OpenAPI 导出和演进策略说明。
- 数据层：外键、唯一约束、索引、事务边界、migration 回滚必须齐全，且核心 API 必须真实使用这些模型和 repository；“模型/migration 存在但业务不用数据库”按原型处理，不得判定为生产就绪。
- CI/CD 与部署：CI 必须覆盖后端 lint/test、前端 lint/build、compose config、OpenAPI 导出检查。生成项目必须同时提供 GitHub Actions（`.github/workflows/ci.yml`）和 GitLab CI（`.gitlab-ci.yml`）两套配置，覆盖相同门禁。
- 可测试性：业务测试优先于存在性测试；测试文件数量不是目标，覆盖关键风险才是目标。
- AI 工具链：`AGENTS.md`、`CLAUDE.md` 不得是空泛说明，必须包含本项目技术栈、验证命令、禁止事项和增量开发流程。

## 3. Required Project Files

除基础目录外，生产级生成项目还必须包含：

- `backend/.dockerignore`
- `frontend/.dockerignore`
- `backend/app/core/rate_limit.py` 或等价限流模块
- `backend/app/core/request_context.py` 或等价 request id 中间件
- `backend/app/core/metrics.py` 或等价 metrics 模块
- `backend/app/db/session.py` 或等价数据库会话依赖，且业务 service/repository 必须被 API 调用
- `backend/scripts/export_openapi.py` 或项目级 `scripts/export_openapi.sh`
- `docs/openapi.json` 或 README 中要求生成该文件的命令
- `docs/security-notes.md`
- `docs/observability.md`
- `docs/test-plan.md`
- `scripts/check_business_flow.sh`
- `backend/app/db/base.py` 中的 `SoftDeleteMixin` 或等价软删除基类
- `backend/app/models/audit_log.py` 或等价审计日志模型
- `backend/migrations/versions/` 中包含审计日志表创建的 migration
- `.env.production.example`
- `compose.prod.yml` 或 `docker-compose.prod.yml`
- `.gitlab-ci.yml`

## 4. Verification Commands

项目级 README 和 CI 至少应包含：

```bash
docker compose --env-file .env.example config
backend pytest --cov=app --cov-report=term-missing
backend ruff check .
frontend npm run lint
frontend npm run build
frontend npm test -- --run
scripts/export_openapi.sh
scripts/verify_all.sh
scripts/check_business_flow.sh
```

如果某个命令因项目范围或依赖选择不适用，必须提供等价命令，不能静默删除。
