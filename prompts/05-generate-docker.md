# 提示词：生成 Docker 部署

请基于现有 OpenSpec 和生成代码，补齐 Docker 相关文件。

开始前先读取：

- `docs/deployment-spec.md`
- `docs/backend-spec.md`
- `docs/testing-spec.md`

要求：

- 输出到 `generated/<project-slug>/`
- 生成 `generated/<project-slug>/compose.yaml`
- 服务至少包含 `frontend`、`backend`、`mysql`、`redis`
- 所有配置来自 `.env`
- 为主要服务提供合理的依赖关系、端口映射和健康检查
- 补齐 `.env.example`、必要 Dockerfile 与 README 中的启动说明
- 保证 `docker compose config` 可通过
