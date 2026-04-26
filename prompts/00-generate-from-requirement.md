# 总控提示词：根据需求文档生成完整全栈实现

你的任务是在当前仓库中，基于 `requirements/requirement.md` 自动生成一个完整的全栈项目实现。

你必须严格遵守以下总原则：

- 不要跳过 OpenSpec
- 先读需求，再生成规格，再生成代码
- 当前仓库是模板仓库，你需要在模板约束下生成业务实现
- 所有配置必须来自环境变量
- 后端、前端、测试、部署必须模块化组织
- 所有业务实现必须统一输出到 `generated/<project-slug>/`
- 生成完成后必须自动检查并修复明显问题

## 输出目录硬约束

你必须先创建并使用以下项目级目录结构，禁止把业务实现直接散落在仓库根目录：

```text
generated/<project-slug>/
  README.md
  .gitignore
  .env.example
  compose.yaml
  requirements/
  docs/
  scripts/
  openspec/
  backend/
  frontend/
```

如果需求需要附加目录，也必须创建在 `generated/<project-slug>/` 下，例如：

- `generated/<project-slug>/infra/`
- `generated/<project-slug>/tests/`

## 严格执行阶段

你必须严格按以下阶段执行，不能跳步：

### 阶段 1：识别需求文档

- 读取 `requirements/requirement.md`
- 判断需求是否完整
- 如果需求缺少关键部分，先补充“待确认项”并在生成结果中显式记录假设

### 阶段 2：解析需求

- 提炼项目目标、用户角色、功能模块、页面列表、数据实体、权限规则、业务流程、异常场景、非功能需求
- 输出结构化分析结果
- 基于需求内容生成一个稳定、可读的 `project-slug`
- 如果需求中已明确项目英文名或系统标识，优先使用其规范化结果作为 `project-slug`
- `project-slug` 应仅包含小写字母、数字和连字符

### 阶段 2.5：初始化项目输出目录

- 创建 `generated/<project-slug>/`
- 创建项目级 `README.md`
- 创建项目级 `.gitignore`
- 创建项目级 `.env.example`
- 预留 `requirements/`、`docs/`、`scripts/`、`openspec/`、`backend/`、`frontend/` 目录
- 后续所有生成内容都必须写入该目录树

### 阶段 3：生成 OpenSpec

- 直接在 `generated/<project-slug>/openspec/` 中生成当前业务相关的 OpenSpec
- 项目级 `openspec/` 必须包含 `project.md` 副本
- 项目级 `openspec/changes/` 必须包含完整变更副本，例如 `proposal.md`、`tasks.md` 与其他必要说明
- 规格中必须体现接口、数据模型、模块边界、权限与验证要求

### 阶段 3.5：同步项目级上下文

- 将当前业务需求快照同步输出到 `generated/<project-slug>/requirements/`
- 生成项目级 `docs/`，至少包含开发说明与架构说明
- 生成项目级 `scripts/`，至少包含验证或清理脚本
- 确保生成结果可作为独立工程包脱离模板仓库继续开发

### 阶段 4：生成后端

- 使用 Python 3.12+、FastAPI、Pydantic v2、SQLAlchemy 2.x async、Alembic、pytest、ruff
- 后端必须生成到 `generated/<project-slug>/backend/`
- 后端必须拆分为可维护目录结构，不得将所有逻辑写入单文件
- 生成配置管理、数据库连接、路由、schema、service、repository、认证与错误处理
- 后端必须提供可执行的测试、lint 和启动命令

### 阶段 5：生成数据库模型和 Alembic migration

- 根据数据实体生成 SQLAlchemy 模型
- 生成初始化 Alembic 配置
- 生成首批 migration
- MySQL 8 作为默认数据库

### 阶段 6：生成 Redis 集成

- 集成 Redis 7
- 为缓存、会话、验证码、任务状态或其他合理用途提供基础封装
- Redis 配置必须来自环境变量

### 阶段 7：生成前端

- 使用 React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 前端必须生成到 `generated/<project-slug>/frontend/`
- 前端必须按页面、模块、组件、hooks、api 分层
- 不要把所有逻辑堆进 `App.tsx`
- 页面、表单、数据请求与状态处理要与需求一致
- 前端必须提供可执行的构建、lint 和开发命令

### 阶段 8：生成 Docker Compose

- 生成 `generated/<project-slug>/compose.yaml`
- 至少包含 `frontend`、`backend`、`mysql`、`redis`
- 所有配置从 `.env` 读取
- 为开发运行提供合理的端口、依赖和健康检查配置
- 如需容器构建文件，也必须放在 `generated/<project-slug>/` 下的相应服务目录内

### 阶段 9：生成测试

- 为后端生成 `pytest` 测试
- 为关键逻辑和关键接口补基础测试
- 为前端补必要的最小测试或至少确保构建与 lint 可通过

### 阶段 10：生成 README

- 在 `generated/<project-slug>/README.md` 中生成业务项目说明
- README 必须反映当前业务项目的运行方式、目录结构、验证命令和环境变量说明
- README 必须明确列出：
  - 项目简介
  - 技术栈
  - 目录结构
  - 环境变量用法
  - 本地开发命令
  - 测试与 lint 命令
  - Docker Compose 启动命令

### 阶段 10.5：生成项目级环境文件

- 在 `generated/<project-slug>/.env.example` 中生成该业务项目所需的完整环境变量模板
- 必须覆盖后端、前端、MySQL、Redis、JWT、CORS、应用运行端口等配置
- 不得依赖仓库根目录 `.env.example` 作为唯一项目运行配置说明

### 阶段 10.55：生成项目级忽略文件

- 在 `generated/<project-slug>/.gitignore` 中生成项目级忽略规则
- 必须忽略运行与构建产物，例如 `.env`、虚拟环境、`node_modules`、`dist`、测试缓存、日志
- 不得忽略源码、文档、`compose.yaml`、`.env.example` 等应保留的工程文件

### 阶段 10.6：生成项目级验证命令

- 在 `generated/<project-slug>/README.md` 中加入完整验证命令
- 如有必要，在 `generated/<project-slug>/scripts/` 中生成验证脚本
- 验证命令至少应覆盖：
  - `docker compose config`
  - `docker compose up --build`
  - `backend pytest`
  - `backend ruff check`
  - `frontend npm run build`
  - `frontend npm run lint`

### 阶段 11：自动检查并修复明显问题

- 检查导入错误、路径错误、环境变量遗漏、容器引用错误、构建脚本错误
- 优先修复可自动识别的问题
- 最终输出仍存在的风险项与待人工确认项

## 输出要求

- 先汇报需求解析结果
- 再汇报 OpenSpec 产物
- 再生成代码
- 明确告知最终输出目录 `generated/<project-slug>/`
- 明确列出已创建的项目级文件，包括 `README.md`、`.gitignore`、`.env.example`、`compose.yaml`
- 明确列出已同步的项目级上下文目录，包括 `requirements/`、`docs/`、`scripts/`、`openspec/`
- 生成后主动执行基础检查
- 修改时保持现有模板文件风格一致
