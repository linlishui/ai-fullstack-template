# Deployment Spec

本文件是模板仓库的部署与运行总入口规范。目标不是把所有项目都提升到复杂平台编排，而是要求 AI 生成的工程至少达到主流行业对本地开发、容器化交付和环境配置的基本标准。

如果你只读一份部署规范，优先读本文件；如果需要补充上下文，再继续看以下文档：

- `docs/backend-spec.md`
- `docs/testing-spec.md`
- `docs/frontend-ui-spec.md`
- `docs/generation-quality.md`

## 1. 目标

部署与运行必须同时满足三件事：

- 可启动：开发者按 README 即可在本地完成最小启动
- 可验证：容器配置、健康检查和依赖关系可被脚本验证
- 可交接：环境变量、端口、卷、启动顺序和运行说明完整

## 2. 通用原则

- 先保证本地开发与验证链路成立，再考虑扩展部署形态
- 所有运行配置必须显式声明，不依赖作者本机隐式环境
- 服务边界、依赖关系和健康检查必须可读、可验证
- 默认优先选择简单、稳定、可维护的容器方案

## 3. 默认交付基线

每个生成项目默认至少交付：

- `generated/<project-slug>/compose.yaml`
- `generated/<project-slug>/.env.example`
- `generated/<project-slug>/README.md`
- `generated/<project-slug>/backend/Dockerfile`
- `generated/<project-slug>/frontend/Dockerfile`
- `generated/<project-slug>/infra/nginx/`
- `generated/<project-slug>/.github/workflows/`

Compose 服务至少包含：

- `nginx`
- `frontend`
- `backend`
- `mysql`
- `redis`

## 4. 环境变量与配置规则

- 数据库、Redis、JWT、CORS、运行端口、前端 API 地址等配置必须来自环境变量
- `.env.example` 必须覆盖启动所需完整键名，并提供合理示例值
- 不允许把密码、密钥、主机地址或跨域来源写死在源码或 Compose 中
- 区分前端构建期变量和后端运行期变量，命名应清晰

## 5. 容器化规则

### 5.1 Dockerfile

- 每个主要服务应有自己的 Dockerfile
- Dockerfile 默认优先使用多阶段构建
- 镜像构建步骤应尽量稳定、可缓存、可复现
- 不要把本地开发垃圾文件打进镜像
- 启动命令应显式，不依赖人工进入容器后再执行

### 5.2 Compose

- `docker compose config` 必须可通过
- 服务名称、端口映射、依赖关系和卷定义必须清晰
- 对数据库、缓存、后端等关键服务应提供健康检查
- Nginx 应负责前端静态资源与 API 反向代理，并补基础安全头
- `depends_on` 只解决启动顺序，不等于可用性；关键服务应结合健康检查或启动脚本处理就绪问题
- 如前后端存在联调依赖，前端指向后端的地址必须与容器网络和本地访问方式一致
- 如资源约束不是明显不适用，Compose 应声明合理的内存/CPU 限制或至少在文档中说明部署建议

## 6. 运行与初始化规则

- 首次启动所需 migration 必须有明确执行路径
- 如果关键页面依赖种子数据、分类或管理员账号，必须说明初始化方式
- 不允许要求使用者手工建表、手工改容器配置或临时修改源码才能启动
- README 中必须写明最小启动步骤、验证命令和常见故障入口

## 7. 安全与发布底线

- 不提交真实密钥、数据库密码或第三方凭据
- 默认使用非生产示例值，并要求使用者在真实环境覆盖
- 跨域、Cookie、JWT 过期时间和调试开关等必须可配置
- 不要在镜像或日志中泄漏敏感信息
- CI 工作流中应预留 lint、test、build 基本流水线，必要时再扩展部署阶段

## 8. 可观测性与健康检查

- 后端至少应提供应用级健康检查端点
- Compose 中的健康检查应体现真实依赖是否可用，而不只是进程存在
- 日志输出应便于定位启动失败、连接失败、迁移失败和端口冲突
- 如项目存在业务校验脚本，应支持在容器启动后执行

## 9. 发布前验证规则

至少执行以下命令：

- `docker compose config`
- `docker compose up --build`
- `backend pytest`
- `backend ruff check`
- `frontend npm run build`
- `frontend npm run lint`

如需验证主链路动作，应在 `docker compose up --build` 后执行项目级 `scripts/check_business_flow.sh`。

## 10. 常见错误

- Compose 能解析，但服务启动后因依赖未就绪立即失败
- `.env.example` 缺关键变量，导致新环境无法启动
- 前端容器里写死本机地址，换机器后不可用
- 只给出 `docker compose up`，没有 migration、验证或故障排查说明
- 健康检查只测端口，不测应用或依赖状态

## 11. 生成时的最小执行顺序

生成部署与运行文件时，建议至少按这个顺序执行：

1. 读取本文件 `docs/deployment-spec.md`
2. 读取 `requirements/requirement.md`
3. 读取当前项目 OpenSpec 与架构说明
4. 读取 `docs/backend-spec.md`
5. 读取 `docs/testing-spec.md`
6. 生成 `.env.example`、Dockerfile、`compose.yaml`
7. 在 README 中写明启动、验证、迁移和故障排查入口

## 12. 验收清单

生成完成后，至少自查以下问题：

- `compose.yaml`、`.env.example`、Dockerfile 是否齐全且互相一致
- Nginx 配置、CI 工作流与健康检查是否齐全
- 数据库、Redis、JWT、前端 API 地址等是否全部来自环境变量
- 关键服务是否有健康检查和清晰依赖关系
- 首次启动的 migration、种子数据或管理员初始化是否有明确路径
- `docker compose config` 和 `docker compose up --build` 是否可执行
- README 是否包含启动、验证和常见故障处理说明
