# AI Fullstack Auto Implementation Template

本仓库用于基于需求文档，自动生成 `FastAPI + MySQL + Redis + React + Docker Compose` 的全栈项目。

当前阶段的目标不是实现某个具体业务，而是提供一个可复用的工程模板，让后续 AI 能够按照固定流程生成更接近生产环境评分标准的独立工程：

1. 从 `requirements/requirement.md` 读取需求
2. 先生成 OpenSpec 风格的规格、设计与任务
3. 基于规格生成并发计划，在明确文件所有权后并行推进后端、前端、部署与测试代码
4. 回到主控集成，自动修复明显问题并完成基础验证

同时，模板默认以“接近生产级高分实现”为目标，而不只是通过最基础的 build 和 lint。生成链路会显式约束安全、可观测性、前端容错、部署资产、测试覆盖、OpenAPI 导出、限流与关键业务回归路径。

生成流程默认把 AI 视为资深全栈架构师、生产级交付负责人和严格代码审查者。质量目标不是堆文件，而是在需求范围内交付可独立运行、可验证、可维护、接近生产环境质量的工程。主业务闭环优先级高于外围生产资产；Nginx、CI、metrics、文档和审计都必须服务于真实业务动作、状态流转、权限边界和可执行验证。

为避免过度设计和资产冗余，模板使用 `docs/template-governance.md` 约束规则源和生成资产职责：模板 `docs/` 是规则源，生成项目 `doc/` 是项目事实、证据路径、验证结果和风险索引，不复制模板长规则。

## 快速开始

最短路径：

1. 按 `docs/requirement-template.md` 填写 `requirements/requirement.md`
2. 在 Codex 或 Claude Code 中触发生成
3. 生成后继续触发修复验证
4. 进入 `generated/<project-slug>/` 启动和验证独立工程

Codex 推荐提示词：

```text
Use $template-project-driver for this repository.
Read requirements/requirement.md first.
Generate OpenSpec first in generated/<project-slug>/openspec/.
Then generate the standalone fullstack project in generated/<project-slug>/.
Strictly follow docs/production-grade-rubric.md and docs/fullstack-review-scoring.md.
Use docs/concurrent-generation.md after OpenSpec to parallelize only independent work with clear file ownership.
Run scripts/audit_generated_project.sh and scripts/verify_project.sh, then fix failures before final handoff.
```

Claude Code 推荐提示词：

```text
请使用 template-project-driver skill 执行当前模板流程。
先读取 requirements/requirement.md。
先在 generated/<project-slug>/openspec/ 中生成 OpenSpec。
再把完整独立工程输出到 generated/<project-slug>/。
必须严格遵守 docs/production-grade-rubric.md 和 docs/fullstack-review-scoring.md。
OpenSpec 完成后按 docs/concurrent-generation.md 规划可并发分片，先写清文件所有权再并行生成。
最后执行 scripts/audit_generated_project.sh 和 scripts/verify_project.sh；失败项必须先修复再结束。
```

生成后继续执行：

```text
读取并执行 prompts/07-fix-and-verify.md，自动检查、修复并验证项目。
重点核对：数据库-backed 持久化、真实 API/mutation 前端动作、DB/Redis readiness、低基数 metrics label、非 root Dockerfile、标准 index.html、lockfile、前端测试、业务流脚本。
修复后重新执行 scripts/audit_generated_project.sh generated/<project-slug> 和 scripts/verify_project.sh generated/<project-slug>。
```

本地运行：

```bash
cd generated/<project-slug>
docker compose up --build
```

## 默认技术栈

- 后端：Python 3.12+、FastAPI、Pydantic v2、SQLAlchemy 2.x async、Alembic、MySQL 8、Redis 7、JWT、pytest、ruff
- 前端：React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 部署：Docker Compose
- 配置：统一通过 `.env` 管理
- 规格管理：OpenSpec 风格组织需求、设计和任务

## 生产级默认基线

为减少评审高频失分项，模板默认要求生成项目尽量具备以下基线：

- 后端：版本化 API、统一响应结构、全局异常处理、分页、`created_at/updated_at` 审计字段、依赖可用性健康检查、Redis-backed 限流、request id、结构化日志、真实 Metrics 与 Tracing extension point
- 前端：统一 HTTP 客户端、ErrorBoundary、关键路由懒加载、Skeleton/Empty/Error/Toast/Confirm Dialog、未登录/无权限/缺少前置条件的显式提示
- 安全：环境变量化配置、非通配 CORS、JWT/Refresh Token、安全 Cookie、CSRF 防护、安全响应头、关键操作审计日志
- 部署：多阶段 Dockerfile、`compose.yaml`、Nginx 反向代理、CI 工作流、容器健康检查、README 中完整启动与验证说明
- 质量：后端 `pytest` + `ruff check`、前端 `npm run build` + `npm run lint`、项目级关键业务动作清单与必要时的 `scripts/check_business_flow.sh`
- 前端截图：生成项目 `doc/screenshots/` 必须包含至少 3-5 张核心流程页面运行截图，README 必须包含「运行截图」章节；缺失截图将影响「功能完整性」评分
- AI 工具链：项目级 `AGENTS.md`、`CLAUDE.md`、`doc/ai-workflow.md` 与 review/fix 记录模板，确保独立工程可继续被 AI 接手
- 并发效率：OpenSpec 后生成 `doc/parallel-execution-plan.md`，按后端、前端、运行交付、验证和审查分片并行推进，最后串行集成和验证

## 生产级硬门禁

严格评分下，仅完成目录、构建和基础业务流仍不够。模板现在把 `docs/production-grade-rubric.md` 作为硬门禁，并用 `docs/fullstack-review-scoring.md` 对齐 120 分 fullstack reviewer 评分口径，要求生成项目默认具备：

- Redis-backed Rate Limiting，覆盖登录、注册、刷新 token 和关键写操作
- 安全管理员 bootstrap/seed，不允许 email 前缀或固定用户名提权
- request id 中间件、结构化日志、真实 `/metrics`、Tracing extension point
- OpenAPI 导出脚本和 `doc/openapi.json` 或等价产物
- 后端/前端 `.dockerignore`，后端非 editable 生产安装，Nginx gzip/安全头/proxy timeout
- 后端不少于 8 个关键测试用例，前端至少一类 smoke/component/form/state 测试
- 自包含、可重复运行、无需人工 token 的 `scripts/check_business_flow.sh`
- 核心业务 API 真实使用数据库-backed service/repository，禁止用内存 store 冒充生产持久化
- 核心前端动作真实调用 API/hook/mutation，禁止用 `setTimeout`、静态 toast、硬编码统计或分类伪装业务闭环
- readiness 真实探测 DB/Redis，metrics 使用低基数路由模板标签，后端容器非 root 运行，前端包含标准 `index.html` 和 lockfile

如果某项因业务选择不适用，必须在生成项目的 `doc/production-readiness-checklist.md` 和 `doc/security-notes.md` 中说明替代方案和风险。

## 质量要求分层

- 不可降级硬门禁：OpenSpec-first、真实业务闭环、数据库-backed 持久化、真实前端 API/mutation 动作、认证授权、输入校验、关键测试、业务流脚本和模板审计。
- 默认生产增强：Redis-backed rate limiting、request id、结构化日志、metrics、Tracing extension point、Nginx、安全头、Docker、CI、OpenAPI、生产就绪/安全/可观测性/测试文档。
- 按需扩展：复杂认证体验、后台任务、复杂缓存、运营 BI、细粒度权限矩阵、多租户和复杂插件生态。只有需求或风险明确需要时展开，不得挤占主业务闭环。

生成项目中的 README、清单和说明文档应保持短而具体：每项写清状态、证据文件、验证命令或剩余风险，避免复制模板通用规则。

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
│   ├── capture_screenshots.sh
│   ├── clean_generated.sh
│   └── playwright/
│       ├── package.json
│       └── capture.mjs
├── generated/
│   └── .gitkeep
├── skills/
│   ├── shared/
│   │   ├── template-project-driver-core.md
│   │   └── template-project-driver-workflow-map.md
│   └── template-project-driver/
└── docs/
    ├── ai-workflow.md
    ├── backend-spec.md
    ├── component-patterns.md
    ├── concurrent-generation.md
    ├── deployment-spec.md
    ├── design-tokens.md
    ├── frontend-ui-spec.md
    ├── frontend-anti-patterns.md
    ├── fullstack-review-scoring.md
    ├── generation-quality.md
    ├── production-grade-rubric.md
    ├── project-asset-templates.md
    ├── template-governance.md
    ├── testing-spec.md
    └── requirement-template.md
```

## 使用流程

### 1. 填写需求

根据 `docs/requirement-template.md` 填写 `requirements/requirement.md`。需求应尽量包含角色、关键业务动作、数据实体、状态流转、权限规则、页面入口和异常场景。

### 2. 触发生成

优先使用“快速开始”中的 Codex 或 Claude Code 推荐提示词。它们会显式调用 `template-project-driver`，并要求先生成 OpenSpec，再输出 `generated/<project-slug>/` 独立工程。

如果不使用 skill，也可以直接要求 AI 执行：

```text
读取并执行 prompts/00-generate-from-requirement.md。
必须基于 requirements/requirement.md 先生成 OpenSpec，再按 docs/concurrent-generation.md 生成 generated/<project-slug>/doc/parallel-execution-plan.md，随后生成 generated/<project-slug>/ 独立工程。
生成后必须继续读取并执行 prompts/08-security-review.md，完成认证、鉴权、JWT/Refresh Token、Cookie/CSRF、管理员初始化、限流、CORS、日志脱敏和生产安全门禁审查。
随后读取并执行 prompts/07-fix-and-verify.md，修复安全审查、构建、测试、lint、OpenAPI、Compose、业务流和模板审计发现的问题。
最后执行 scripts/audit_generated_project.sh generated/<project-slug> 和 scripts/verify_project.sh generated/<project-slug>，失败项必须先修复并重新验证，不能跳过后结束。
```

### 3. 修复验证

生成完成后继续要求 AI 执行：

```text
读取并执行 prompts/07-fix-and-verify.md，自动检查、修复并验证项目。
```

重点确认真实持久化、真实前端 API/mutation、DB/Redis readiness、低基数 metrics label、非 root Dockerfile、标准 `index.html`、lockfile、前端测试和业务流脚本。

### 4. 启动独立工程

生成完成后，AI 应将实现统一输出到 `generated/<project-slug>/`。确认该目录中的 `.env` 已配置后执行：

```bash
cd generated/<project-slug>
docker compose up --build
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
- 典型输出包括 `generated/<project-slug>/requirements/`、`generated/<project-slug>/doc/`、`generated/<project-slug>/doc/key-business-actions-checklist.md`、`generated/<project-slug>/scripts/`、`generated/<project-slug>/openspec/project.md`、`generated/<project-slug>/openspec/specs/<capability>/spec.md`、`generated/<project-slug>/openspec/changes/<change-id>/`、`generated/<project-slug>/backend/`、`generated/<project-slug>/frontend/`、`generated/<project-slug>/compose.yaml`、`generated/<project-slug>/.env.example`、`generated/<project-slug>/.gitignore`、`generated/<project-slug>/README.md`
- 生产级增强输出通常还包括 `generated/<project-slug>/AGENTS.md`、`generated/<project-slug>/CLAUDE.md`、`generated/<project-slug>/doc/ai-workflow.md`、`generated/<project-slug>/doc/review-log.md`、`generated/<project-slug>/doc/fix-log.md`、`generated/<project-slug>/doc/frontend-ui-checklist.md`、`generated/<project-slug>/doc/production-readiness-checklist.md`、`generated/<project-slug>/doc/security-notes.md`、`generated/<project-slug>/doc/observability.md`、`generated/<project-slug>/doc/test-plan.md`、`generated/<project-slug>/doc/screenshots/`、`generated/<project-slug>/infra/nginx/`、`generated/<project-slug>/.github/workflows/`
- 并发生成输出还必须包括 `generated/<project-slug>/doc/parallel-execution-plan.md`，记录是否启用并发、任务分片、文件所有权、共享契约、集成顺序和验证结果
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
`--with-compose-up` 还会自动调用 `scripts/capture_screenshots.sh`，通过 Playwright 从前端路由配置自动提取页面路径并截图到 `doc/screenshots/`。截图脚本也可单独执行：

```bash
./scripts/capture_screenshots.sh generated/<project-slug>
```

另外，`verify_project.sh` 会在开始时自动调用 `scripts/check_prerequisites.sh`；如果缺少 `docker`、`docker compose`、`python3`、`node` 或 `npm`，验证会直接中止并输出缺失项。`codex` 和 `claude` 仅作为可选 CLI 提示，不会阻断验证。

生产级完整验证推荐：

```bash
./scripts/audit_generated_project.sh generated/<project-slug>
./scripts/verify_project.sh generated/<project-slug> --with-compose-up
```

`audit_generated_project.sh` 现在会检查生产级证据，包括安全说明、可观测性说明、测试计划、CI 门禁、限流、request id、metrics、OpenAPI 导出、`.dockerignore`、Nginx gzip、安全管理员初始化、前端测试和业务流脚本。旧项目如果只满足基础模板，可能无法通过新版审计，这是预期行为。

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
- 并发生成应以 `docs/concurrent-generation.md` 为总入口，且只能在 OpenSpec 和共享契约稳定后启用
- 满分导向评审应以 `docs/fullstack-review-scoring.md` 和 `docs/production-grade-rubric.md` 共同作为门禁来源
- 规则源与去冗余应以 `docs/template-governance.md` 为准

## 质量门禁

为了提高通过 AI 生成项目的一次成功率，建议把质量检查拆成两层：

- 模板级审计：检查目录、OpenSpec、README、环境变量模板、核心入口文件、前端 UI 清单、生产就绪清单、安全说明、可观测性说明、测试计划、CI 工作流与 Nginx 配置是否齐全
- 项目级验证：检查 compose、pytest/coverage、ruff、npm build、npm lint、npm test、OpenAPI 导出是否真正可执行；如果项目提供业务校验脚本，则在服务启动后自动执行关键业务动作检查

此外，生成项目应保留需求驱动的关键业务动作回归清单和项目级 AI/安全/可观测性/测试资产。模板参考统一收敛到 `docs/project-asset-templates.md`：

- 项目输出：`generated/<project-slug>/AGENTS.md`、`CLAUDE.md`、`doc/parallel-execution-plan.md`、`doc/key-business-actions-checklist.md`、`doc/frontend-ui-checklist.md`、`doc/production-readiness-checklist.md`、`doc/security-notes.md`、`doc/observability.md`、`doc/test-plan.md`、`doc/review-log.md`、`doc/fix-log.md`
- 作用：避免 AI 只完成静态结构和构建通过，却遗漏真正的主链路动作、状态流转、证据索引和风险记录

详细策略见：

- [docs/ai-workflow.md](docs/ai-workflow.md)
- [docs/generation-quality.md](docs/generation-quality.md)
- [docs/concurrent-generation.md](docs/concurrent-generation.md)
- [docs/production-grade-rubric.md](docs/production-grade-rubric.md)
- [docs/fullstack-review-scoring.md](docs/fullstack-review-scoring.md)
- [docs/template-governance.md](docs/template-governance.md)
- [docs/backend-spec.md](docs/backend-spec.md)
- [docs/testing-spec.md](docs/testing-spec.md)
- [docs/deployment-spec.md](docs/deployment-spec.md)
