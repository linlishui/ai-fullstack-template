# 提示词：生成 Docker 部署

请基于现有 OpenSpec 和生成代码，补齐 Docker 相关文件。

开始前先读取：

- `docs/deployment-spec.md`
- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/production-grade-rubric.md`
- `docs/concurrent-generation.md`（当本阶段作为并发分片执行时）

要求：

- 输出到 `generated/<project-slug>/`
- 如果作为并发分片执行，主要负责 `compose.yaml`、Dockerfile、`.dockerignore`、`infra/nginx/`、`.github/workflows/`、`.gitlab-ci.yml`、运行相关 README 小节和环境变量模板；不得改写业务代码，除非集成时发现容器入口必须调整并记录在 `doc/parallel-execution-plan.md`
- 生成 `generated/<project-slug>/compose.yaml`
- 服务至少包含 `nginx`、`frontend`、`backend`、`mysql`、`redis`
- 所有配置来自 `.env`
- 为主要服务提供合理的依赖关系、端口映射、资源限制和健康检查
- 补齐 `.env.example`、必要 Dockerfile、`infra/nginx/` 配置、`.github/workflows/ci.yml`、`.gitlab-ci.yml` 与 README 中的启动说明
- `.gitlab-ci.yml` 必须与 `.github/workflows/ci.yml` 覆盖相同质量门禁：backend lint/test/coverage、frontend lint/build/test、compose config、OpenAPI export、dependency audit
- 必须生成 `backend/.dockerignore` 与 `frontend/.dockerignore`，排除本地依赖、构建产物、缓存、日志和 `.env`
- Dockerfile 默认优先使用多阶段构建；后端生产镜像不得依赖 editable install，优先 wheel/非 editable package install
- 前端 Dockerfile 多阶段构建的构建阶段必须先 `COPY package*.json ./` 再 `RUN npm ci`，然后 `COPY . .` 和 `RUN npm run build`；禁止跳过 `npm ci` 直接执行构建
- 后端 Dockerfile 必须通过 `COPY pyproject.toml .` + `pip install --no-cache-dir .`（或 pip-compile lockfile）安装依赖；禁止在 Dockerfile 中内联 `pip install fastapi uvicorn ...` 列出包名
- `compose.yaml` 中 `env_file` 应指向 `.env`（gitignored 的真实配置），不应直接引用 `.env.example`；README 中应说明从 `.env.example` 复制为 `.env` 的步骤
- 后端生产镜像必须使用非 root 用户运行，并在 Dockerfile 中显式 `USER`
- Nginx 负责 API 代理、前端静态资源、gzip、基础安全头、proxy timeout 和合理缓存策略；生产默认 CSP 不得硬编码 `localhost` 作为 `connect-src`
- 后端 readiness/healthcheck 必须真实探测数据库和 Redis，禁止只检查进程或配置存在
- CI 至少覆盖后端 lint/test/coverage、前端 lint/build/test、compose config、OpenAPI 导出检查、依赖安全审计或审计报告；GitHub Actions 与 GitLab CI 必须同时生成
- README 必须包含 `docker compose --env-file .env.example up --build`、健康检查、migration、seed/bootstrap、业务流验证和故障排查说明
- 保证 `docker compose config` 可通过
