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
├── CLAUDE.md
├── .gitignore
├── .env.example
├── .claude/
│   └── skills/
│       └── template-project-driver/
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
│   ├── audit_generated_project.sh
│   ├── verify_project.sh
│   └── clean_generated.sh
├── generated/
│   └── .gitkeep
├── skills/
│   ├── shared/
│   │   ├── template-project-driver-core.md
│   │   └── template-project-driver-workflow-map.md
│   └── template-project-driver/
└── docs/
    ├── architecture.md
    ├── development.md
    ├── ai-workflow.md
    ├── backend-spec.md
    ├── business-checklist-template.md
    ├── deployment-spec.md
    ├── frontend-ui-spec.md
    ├── frontend-anti-patterns.md
    ├── generation-quality.md
    ├── testing-spec.md
    └── requirement-template.md
```

## 使用流程

### 第一步：把需求写入 `requirements/requirement.md`

根据 `docs/requirement-template.md` 填写业务需求，不要直接开始生成代码。

### 第二步：让 AI CLI 执行 `prompts/00-generate-from-requirement.md`

在 Codex 或 Claude Code 中明确要求其读取并执行 `prompts/00-generate-from-requirement.md`，让其基于 `requirements/requirement.md` 自动完成规格和实现生成。

### 第三步：让 AI CLI 执行 `prompts/07-fix-and-verify.md`

生成完成后，再让同一端 AI 继续读取并执行 `prompts/07-fix-and-verify.md`，自动检查、修复并验证项目。

### 第四步：进入生成项目目录并运行 `docker compose up --build`

生成完成后，AI 应将实现统一输出到 `generated/<project-slug>/`。确认该目录中的 `.env` 已配置后，在该项目目录执行：

```bash
cd generated/<project-slug>
docker compose up --build
```

## 显式调用 Skill

当前模板工程同时兼容 Codex 与 Claude Code。两端都使用同名 skill `template-project-driver`，但仓库内的挂载位置不同：

- Codex skill：`skills/template-project-driver/`
- Claude Code skill：`.claude/skills/template-project-driver/`
- 统一目标：读取 `requirements/requirement.md`，先生成 `generated/<project-slug>/openspec/`，再生成 `generated/<project-slug>/` 下的独立工程，并执行审计与验证

推荐把“要调用 skill”直接写进提示词，避免 AI 只按自然语言自由发挥。

Codex 推荐写法：

```text
Use $template-project-driver for this repository. Read requirements/requirement.md, generate OpenSpec first in generated/<project-slug>/openspec/, then generate the standalone project in generated/<project-slug>/ and run audit plus verification.
```

Claude Code 推荐写法：

```text
请使用 template-project-driver skill 执行当前模板流程：先读取 requirements/requirement.md，在 generated/<project-slug>/openspec/ 中生成 OpenSpec，再把完整项目输出到 generated/<project-slug>/，最后执行模板级审计与项目级验证。
```

如果不显式点名 skill，至少也应明确要求 AI 遵守“先 OpenSpec、后实现、最后验证”的顺序。

## 推荐工作方式

1. 先执行 `scripts/check_prerequisites.sh` 检查本地工具链
2. 编写或更新 `requirements/requirement.md`
3. 在 Codex 中显式使用 `$template-project-driver`，或在 Claude Code 中显式要求使用 `template-project-driver` skill；也可手动执行 `prompts/00-generate-from-requirement.md`
4. 进入 `generated/<project-slug>/` 执行 `docker compose up --build`
5. 执行 `scripts/audit_generated_project.sh generated/<project-slug>` 做模板级结构审计

## 模板层与生成层

为了方便后续迁移到其他目录继续开发，当前仓库按两层组织：

- 模板层：`requirements/`、`prompts/`、`docs/`、`scripts/`
- 生成层：`generated/<project-slug>/` 下的全部业务实现文件

这意味着：

- 模板层负责定义工作流、规范、提示词和需求入口
- OpenSpec 仅存在于生成层的 `generated/<project-slug>/openspec/`
- 生成层负责承载具体业务代码与部署实现
- 每次生成时，应按需求内容创建 `generated/<project-slug>/`
- 典型输出包括 `generated/<project-slug>/requirements/`、`generated/<project-slug>/docs/`、`generated/<project-slug>/docs/key-business-actions-checklist.md`、`generated/<project-slug>/scripts/`、`generated/<project-slug>/openspec/project.md`、`generated/<project-slug>/openspec/specs/<capability>/spec.md`、`generated/<project-slug>/openspec/changes/<change-id>/`、`generated/<project-slug>/backend/`、`generated/<project-slug>/frontend/`、`generated/<project-slug>/compose.yaml`、`generated/<project-slug>/.env.example`、`generated/<project-slug>/.gitignore`、`generated/<project-slug>/README.md`
- 迁移仓库位置时，不依赖机器本地绝对路径
- 如需重新生成项目，可保留模板层，仅清理生成层
- 生成层的目标是形成一个可单独拎走继续开发的独立工程包，而不仅仅是代码输出目录

模板级验证脚本也支持直接对某个生成项目执行检查：

```bash
./scripts/audit_generated_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug> --with-compose-up
```

建议顺序：

1. `./scripts/audit_generated_project.sh generated/<project-slug>`
2. `./scripts/verify_project.sh generated/<project-slug>`

如果生成项目提供了 `generated/<project-slug>/scripts/check_business_flow.sh`，模板验证脚本会在 `--with-compose-up` 场景下自动执行它，把关键业务动作检查纳入正式验证流程。
另外，`verify_project.sh` 会在开始时自动调用 `scripts/check_prerequisites.sh`；如果缺少 `docker`、`docker compose`、`python3`、`node` 或 `npm`，验证会直接中止并输出缺失项。`codex` 和 `claude` 仅作为可选 CLI 提示，不会阻断验证。

## 注意事项

- 当前仓库是模板仓库，不包含具体业务实现
- 规格必须先于代码生成
- 所有敏感配置必须通过环境变量注入
- 生成后必须保留可验证的测试与构建流程
- 前端生成应以 `docs/frontend-ui-spec.md` 为总入口，并主动避开 `docs/frontend-anti-patterns.md` 中列出的反模式
- 推荐把 `docs/frontend-ui-spec.md` 作为前端规范总入口，再按其中指引读取细分文档
- 后端生成应以 `docs/backend-spec.md` 为总入口
- 测试与验证应以 `docs/testing-spec.md` 为总入口
- 部署与运行应以 `docs/deployment-spec.md` 为总入口

## 质量门禁

为了提高通过 AI 生成项目的一次成功率，建议把质量检查拆成两层：

- 模板级审计：检查目录、OpenSpec、README、环境变量模板、核心入口文件是否齐全
- 项目级验证：检查 compose、pytest、ruff、npm build、npm lint 是否真正可执行；如果项目提供业务校验脚本，则在服务启动后自动执行关键业务动作检查

此外，还应保留一份需求驱动的关键业务动作回归清单：

- 模板参考：`docs/business-checklist-template.md`
- 项目输出：`generated/<project-slug>/docs/key-business-actions-checklist.md`
- 作用：避免 AI 只完成静态结构和构建通过，却遗漏真正的主链路动作与状态流转

详细策略见：

- [docs/ai-workflow.md](docs/ai-workflow.md)
- [docs/generation-quality.md](docs/generation-quality.md)
- [docs/backend-spec.md](docs/backend-spec.md)
- [docs/testing-spec.md](docs/testing-spec.md)
- [docs/deployment-spec.md](docs/deployment-spec.md)
