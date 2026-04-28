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
- 同步生成 migration、健康检查和启动所需的最小基础设施
- 补充必要测试与启动说明
