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
- 默认补齐 `api/v1` 路由结构、统一响应封装、全局异常处理、分页 schema、资源级授权、结构化日志、依赖可用性健康检查
- 必须补齐 request id/correlation id 中间件，并在日志和响应头中输出
- 必须补齐 Redis-backed rate limiting，至少保护登录、注册、刷新 token 和关键写操作
- 如果使用 Redis，必须落到限流、会话、刷新令牌或短期缓存等真实用途，不允许空接入
- 必须提供真实 `/metrics` endpoint；Tracing 至少有可启用 extension point
- 必须提供 OpenAPI 导出脚本或项目级 `scripts/export_openapi.sh`
- 管理员初始化必须通过 seed/bootstrap 脚本或环境变量控制，禁止 email 前缀提权
- JWT/Refresh Token/Cookie/CSRF 策略必须符合 `docs/production-grade-rubric.md`
- SQLAlchemy async 返回 DTO 前必须 eager load 关联，避免响应序列化触发 lazy loading
- 同步生成 migration、健康检查和启动所需的最小基础设施
- 补充不少于 8 个后端关键测试：成功、认证失败、越权、非法输入、冲突、非法状态流转、限流或依赖异常
