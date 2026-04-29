# 提示词：生成后端

请基于现有 OpenSpec 规格生成后端实现。

开始前先读取：

- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/deployment-spec.md`
- `docs/production-grade-rubric.md`

要求：

- 输出到 `generated/<project-slug>/backend/`
- 使用 Python 3.12+、FastAPI、Pydantic v2、SQLAlchemy 2.x async、Alembic
- 不要把所有后端代码写进 `main.py`
- 按模块拆分目录
- 使用环境变量管理数据库、Redis、JWT 配置
- 生成模型、schema、路由、service、repository、core 配置
- 核心业务接口必须真实使用 SQLAlchemy async session、service 与 repository；禁止使用 `MemoryStore`、模块级 dict/list、JSON 文件或进程内全局变量承载用户、业务实体、状态流转、安装、审核、统计等核心数据
- API route 不得直接操作 ORM 或内存状态；route 只负责参数/依赖/响应组装，事务边界放在 service，数据访问放在 repository
- 默认补齐 `api/v1` 路由结构、统一响应封装、全局异常处理、分页 schema、资源级授权、结构化日志、依赖可用性健康检查
- 必须补齐 request id/correlation id 中间件，并在日志和响应头中输出
- 必须补齐 Redis-backed rate limiting，至少保护登录、注册、刷新 token 和关键写操作
- 如果使用 Redis，必须落到限流、会话、刷新令牌或短期缓存等真实用途，不允许空接入
- 必须提供真实 `/metrics` endpoint；指标标签必须使用路由模板或低基数字段，禁止直接使用 `request.url.path` 作为 label；Tracing 至少有可启用 extension point
- 健康检查必须真实探测数据库和 Redis，例如执行 `SELECT 1` 与 Redis ping；禁止返回 `database: configured` 这类静态配置状态
- 必须提供 OpenAPI 导出脚本或项目级 `scripts/export_openapi.sh`
- 管理员初始化必须通过 seed/bootstrap 脚本或环境变量控制，禁止 email 前缀提权
- JWT/Refresh Token/Cookie/CSRF 策略必须符合 `docs/production-grade-rubric.md`
- 密码哈希默认使用 Argon2id；如因依赖或平台原因使用 bcrypt/PBKDF2，必须在 `docs/security-notes.md` 中说明取舍，并保证文档与代码算法一致
- SQLAlchemy async 返回 DTO 前必须 eager load 关联，避免响应序列化触发 lazy loading
- FastAPI 启停逻辑优先使用 lifespan，避免新增已废弃的 `@app.on_event`
- 同步生成 migration、健康检查和启动所需的最小基础设施
- 后端生产 Dockerfile 必须使用非 root 用户运行，且不得依赖 editable install
- 补充不少于 8 个后端关键测试：成功、认证失败、越权、非法输入、冲突、非法状态流转、限流或依赖异常
- 管理页面需要的专用数据视图（如 pending 审核列表、按状态筛选等）必须有独立 API 端点，不得让前端复用公共列表接口后在客户端过滤
- Rate limiting 的 INCR + EXPIRE 必须使用 Redis pipeline 原子执行，禁止分两步独立操作（TOCTOU 竞态可导致 key 永久无 TTL）
- Refresh token 端点必须从数据库重新加载用户并校验其是否存在且未被禁用，不得仅凭 token 有效就直接签发
- OpenAPI 导出脚本必须从 FastAPI app 实例调用 `app.openapi()` 导出真实 spec；禁止用 `printf`/`echo`/`cat` 手写静态 JSON
