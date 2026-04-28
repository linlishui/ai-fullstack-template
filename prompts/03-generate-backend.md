# 提示词：生成后端

请基于现有 OpenSpec 规格生成后端实现。

开始前先读取：

- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/deployment-spec.md`

要求：

- 输出到 `generated/<project-slug>/backend/`
- 使用 Python 3.12+、FastAPI、Pydantic v2、SQLAlchemy 2.x async、Alembic
- 不要把所有后端代码写进 `main.py`
- 按模块拆分目录
- 使用环境变量管理数据库、Redis、JWT 配置
- 生成模型、schema、路由、service、repository、core 配置
- 默认补齐 `api/v1` 路由结构、统一响应封装、全局异常处理、分页 schema、资源级授权、结构化日志、依赖可用性健康检查
- 如果使用 Redis，优先落到限流、会话、刷新令牌或短期缓存等真实用途
- 为 Logging、Metrics、Tracing 预留接入点、配置项或文档说明
- 同步生成 migration、健康检查和启动所需的最小基础设施
- 补充必要测试与启动说明
