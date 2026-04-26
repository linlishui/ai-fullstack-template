# AI Fullstack Auto Implementation Template

本仓库用于基于需求文档，自动生成 `FastAPI + MySQL + Redis + React + Docker Compose` 的全栈项目。

当前阶段的目标不是实现某个具体业务，而是提供一个可复用的工程模板，让后续 AI 能够按照固定流程完成：

1. 从 `requirements/requirement.md` 读取需求
2. 先生成 OpenSpec 风格的规格、设计与任务
3. 再基于规格生成后端、前端、部署与测试代码
4. 自动修复明显问题并完成基础验证

## 默认技术栈

- 后端：Python 3.12+、FastAPI、Pydantic v2、SQLAlchemy 2.x async、Alembic、MySQL 8、Redis 7、JWT、pytest、ruff
- 前端：React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 部署：Docker Compose
- 配置：统一通过 `.env` 管理
- 规格管理：OpenSpec 风格组织需求、设计和任务

## 仓库结构

```text
.
├── README.md
├── AGENTS.md
├── .gitignore
├── .env.example
├── requirements/
│   └── requirement.md
├── prompts/
│   ├── 00-generate-from-requirement.md
│   ├── 01-analyze-requirement.md
│   ├── 02-generate-openspec.md
│   ├── 03-generate-backend.md
│   ├── 04-generate-frontend.md
│   ├── 05-generate-docker.md
│   ├── 06-generate-tests.md
│   ├── 07-fix-and-verify.md
│   └── 08-security-review.md
├── scripts/
│   ├── check_prerequisites.sh
│   ├── verify_project.sh
│   └── clean_generated.sh
├── generated/
│   └── .gitkeep
└── docs/
    ├── architecture.md
    ├── development.md
    ├── ai-workflow.md
    └── requirement-template.md
```

## 使用流程

### 第一步：把需求写入 `requirements/requirement.md`

根据 `docs/requirement-template.md` 填写业务需求，不要直接开始生成代码。

### 第二步：让 Codex 执行 `prompts/00-generate-from-requirement.md`

在 Codex CLI 中明确要求其读取并执行 `prompts/00-generate-from-requirement.md`，让其基于 `requirements/requirement.md` 自动完成规格和实现生成。

### 第三步：让 Codex 执行 `prompts/07-fix-and-verify.md`

生成完成后，再让 Codex 读取并执行 `prompts/07-fix-and-verify.md`，自动检查、修复并验证项目。

### 第四步：进入生成项目目录并运行 `docker compose up --build`

生成完成后，AI 应将实现统一输出到 `generated/<project-slug>/`。确认该目录中的 `.env` 已配置后，在该项目目录执行：

```bash
cd generated/<project-slug>
docker compose up --build
```

## 推荐工作方式

1. 先执行 `scripts/check_prerequisites.sh` 检查本地工具链
2. 编写或更新 `requirements/requirement.md`
3. 执行 `scripts/run_full_flow.sh`
4. 进入 `generated/<project-slug>/` 执行 `docker compose up --build`

## 一键执行

如果本机已安装并登录 `codex` CLI，可以直接执行：

```bash
./scripts/run_full_flow.sh
```

该脚本会顺序执行：

1. 基于 `requirements/requirement.md` 调用总控提示词生成项目
2. 调用修复验证提示词检查并修复生成结果

如果你只想执行生成，不想立即进入修复验证，可使用：

```bash
./scripts/run_full_flow.sh --generate-only
```

## 模板层与生成层

为了方便后续迁移到其他目录继续开发，当前仓库按两层组织：

- 模板层：`requirements/`、`prompts/`、`docs/`、`scripts/`
- 生成层：`generated/<project-slug>/` 下的全部业务实现文件

这意味着：

- 模板层负责定义工作流、规范、提示词和需求入口
- OpenSpec 仅存在于生成层的 `generated/<project-slug>/openspec/`
- 生成层负责承载具体业务代码与部署实现
- 每次生成时，应按需求内容创建 `generated/<project-slug>/`
- 典型输出包括 `generated/<project-slug>/requirements/`、`generated/<project-slug>/docs/`、`generated/<project-slug>/scripts/`、`generated/<project-slug>/openspec/`、`generated/<project-slug>/backend/`、`generated/<project-slug>/frontend/`、`generated/<project-slug>/compose.yaml`、`generated/<project-slug>/.env.example`、`generated/<project-slug>/.gitignore`、`generated/<project-slug>/README.md`
- 迁移仓库位置时，不依赖机器本地绝对路径
- 如需重新生成项目，可保留模板层，仅清理生成层
- 生成层的目标是形成一个可单独拎走继续开发的独立工程包，而不仅仅是代码输出目录

模板级验证脚本也支持直接对某个生成项目执行检查：

```bash
./scripts/verify_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug> --with-compose-up
```

## 注意事项

- 当前仓库是模板仓库，不包含具体业务实现
- 规格必须先于代码生成
- 所有敏感配置必须通过环境变量注入
- 生成后必须保留可验证的测试与构建流程
