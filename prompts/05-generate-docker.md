# 提示词：生成 Docker 部署

请基于现有 OpenSpec 和生成代码，补齐 Docker 相关文件。

开始前先读取：

- `docs/deployment-spec.md`
- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/production-grade-rubric.md`

要求：

- 输出到 `generated/<project-slug>/`
- 生成 `generated/<project-slug>/compose.yaml`
- 服务至少包含 `nginx`、`frontend`、`backend`、`mysql`、`redis`
- 所有配置来自 `.env`
- 为主要服务提供合理的依赖关系、端口映射、资源限制和健康检查
- 补齐 `.env.example`、必要 Dockerfile、`infra/nginx/` 配置、`.github/workflows/ci.yml` 与 README 中的启动说明
- 必须生成 `backend/.dockerignore` 与 `frontend/.dockerignore`，排除本地依赖、构建产物、缓存、日志和 `.env`
- Dockerfile 默认优先使用多阶段构建；后端生产镜像不得依赖 editable install，优先 wheel/非 editable package install
- Nginx 负责 API 代理、前端静态资源、gzip、基础安全头、proxy timeout 和合理缓存策略
- CI 至少覆盖后端 lint/test/coverage、前端 lint/build/test、compose config、OpenAPI 导出检查、依赖安全审计或审计报告
- README 必须包含 `docker compose --env-file .env.example up --build`、健康检查、migration、seed/bootstrap、业务流验证和故障排查说明
- 保证 `docker compose config` 可通过
