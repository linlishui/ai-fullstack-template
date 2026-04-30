# Project Asset Templates

本文件集中定义生成项目的文档与 AI 协作资产模板，替代分散的单项模板文件。生成项目仍应输出对应文件，但内容必须按 `docs/template-governance.md` 保持“项目事实 + 证据路径 + 验证结果 + 风险”，不要复制模板长规则。

## 1. AI Collaboration Assets

输出位置：

- `generated/<project-slug>/AGENTS.md`
- `generated/<project-slug>/CLAUDE.md`
- `generated/<project-slug>/doc/ai-workflow.md`
- `generated/<project-slug>/doc/parallel-execution-plan.md`
- `generated/<project-slug>/doc/review-log.md`
- `generated/<project-slug>/doc/fix-log.md`

必须覆盖：

- 项目目标、技术栈、目录结构和主业务闭环。
- OpenSpec-first、真实持久化、真实前端 API/mutation、配置环境变量化、测试和验证规则。
- 本项目验证命令：compose、backend pytest/coverage/ruff、frontend build/lint/test、OpenAPI 导出、业务流脚本。
- 并发生成计划：是否启用并发、任务 owner、写入范围、共享契约、冲突处理、集成顺序和验证结果。
- review/fix 记录字段：日期、触发原因、范围、发现问题、修复动作、影响范围、回归验证。

## 2. Architecture And Development Docs

输出位置：

- `generated/<project-slug>/doc/architecture.md`
- `generated/<project-slug>/doc/development.md`

`architecture.md` 必须记录：

- 当前项目目标和主业务闭环。
- 模块边界：backend、frontend、infra、scripts、openspec。
- 数据流和关键状态流转。
- 权限边界、外部依赖和关键设计取舍。
- 与代码对应的证据路径。

`development.md` 必须记录：

- 本地启动、依赖安装、migration、seed/bootstrap。
- 常用开发命令和验证命令。
- 环境变量说明入口。
- 常见故障和排查入口。
- 增量开发时必须同步更新的代码、测试、migration 和文档。

## 3. Key Business Actions Checklist

输出位置：

- `generated/<project-slug>/doc/key-business-actions-checklist.md`

必须包含当前需求提炼出的 3-5 个关键动作。每项至少记录：

- 角色：
- 前置条件：
- 触发入口：
- 预期状态变化：
- 后端/API 证据：
- 前端证据：
- 测试或脚本：
- 当前状态：`passed` / `partial` / `missing` / `manual-check`
- 风险：

## 4. Frontend UI Checklist

输出位置：

- `generated/<project-slug>/doc/frontend-ui-checklist.md`

必须记录：

- 主题 token 和组件复用状态。
- 页面映射、主操作、关键状态。
- ErrorBoundary、懒加载、统一 HTTP 错误处理、Toast/Dialog/Skeleton。
- 未登录、无权限、缺前置条件反馈。
- 真实 API/mutation 对接；不得有 `setTimeout`、静态 toast 或硬编码业务数据伪成功。
- Auth session layer、token 存储风险、query invalidation。
- 标准 `index.html`、lockfile、移动端布局和组件测试状态。

## 5. Production Readiness Checklist

输出位置：

- `generated/<project-slug>/doc/production-readiness-checklist.md`

必须按证据索引记录：

- Observability：Logging、Metrics、Tracing、Request ID。
- API/runtime：versioned routes、response envelope、global exception handling、pagination、real DB-backed persistence、health/readiness DB/Redis probes。
- Security：CORS、安全头、JWT/Refresh Token、Cookie、CSRF、审计日志、管理员 bootstrap、rate limiting。
- Deployment：Docker multi-stage、backend non-root runtime、Nginx、CSP connect-src、CI、resource limits、`.dockerignore`。
- Verification：compose、pytest、coverage、ruff、frontend build/lint/test、OpenAPI export、business flow script、template audit。
- Open risks：风险、影响、处理计划。

状态值建议：`passed`、`partial`、`missing`、`manual-check`。

## 6. Security Notes

输出位置：

- `generated/<project-slug>/doc/security-notes.md`

必须记录真实实现和剩余风险：

- Admin bootstrap：机制、环境变量、禁止 shortcut 检查。
- Token/session：access token、refresh token、cookie、CSRF/Origin、前端存储、已知风险。
- Password hashing：算法、参数、迁移计划；默认 Argon2id，使用 bcrypt/PBKDF2 时说明原因。
- Persistence boundary：核心业务数据库持久化、事务边界、禁止内存 shortcut 检查。
- Authorization：角色模型、资源级校验、拒绝访问响应。
- Rate limiting：Redis key 策略、保护端点。
- Input/error handling：后端 schema、前端 schema、冲突处理、内部错误处理。
- Secrets/logs：必需密钥、日志脱敏、本地文件忽略。

## 7. Observability

输出位置：

- `generated/<project-slug>/doc/observability.md`

必须记录：

- Request context：header、middleware、log field。
- Logs：格式、access/error 字段、敏感字段脱敏。
- Metrics：endpoint、library、key metrics、path label strategy；禁止 raw URL path。
- Health checks：live、ready、database、Redis、probe evidence。
- Tracing：状态、配置、integration point。
- Operations：Nginx logs、proxy timeout、验证命令。

## 8. Test Plan

输出位置：

- `generated/<project-slug>/doc/test-plan.md`

必须映射真实需求和关键风险：

- Backend tests：success、auth failure、authorization failure、validation failure、conflict、illegal state transition、dependency failure、database-backed persistence、health/readiness、coverage command。
- Frontend tests：smoke、component、ErrorBoundary、loading/empty/error states、API hook/mutation path、auth/session or unauthorized flow、mobile layout。
- Business flow：script、roles、state transitions、repeatability。
- Manual checks：未自动化原因和风险。

最低要求：后端不少于 8 个关键用例，前端至少覆盖一个真实 API hook/mutation 驱动路径，业务流脚本自包含、可重复执行、无需人工 token。

## 9. Parallel Execution Plan

输出位置：

- `generated/<project-slug>/doc/parallel-execution-plan.md`

必须记录：

- 并发状态：`enabled` / `disabled`，以及启用或未启用原因。
- 共享契约：OpenSpec 路径、关键业务动作、API、数据模型、权限、环境变量、端口和脚本名。
- 分片表：任务名、owner、目标、输入、写入范围、禁止触碰范围、依赖、状态。
- 共享文件策略：README、`.env.example`、compose、CI、生产就绪/安全/可观测性文档由谁最终集成。
- 冲突记录：冲突项、影响、解决人、解决结果。
- 集成与验证：安全审查、模板审计、项目验证、业务流脚本和剩余风险。

## 10. Frontend Page Screenshots

输出位置：

- `generated/<project-slug>/doc/screenshots/`

生成项目必须在 `doc/` 目录中补充主要前端页面运行截图，建议覆盖核心业务流程页面。截图用于直观展示前端实现效果，也是「功能完整性」维度评估的参考依据之一。

最低要求：

- 截图文件存放于 `doc/screenshots/` 目录。
- 至少覆盖 3-5 个核心页面，例如登录页、主列表页、详情页、工作台/Dashboard、表单提交页等关键业务流程页面。
- 截图应反映真实运行状态（含数据），不得使用空白页或未初始化状态。
- 项目级 `README.md` 必须包含「运行截图」章节，引用 `doc/screenshots/` 下的截图文件展示前端页面效果。
- 若未提供截图，将影响「功能完整性」维度的评分。

自动截图：

模板提供 `scripts/capture_screenshots.sh`，在服务启动后通过 Playwright 自动访问前端页面并截图。该脚本会从前端路由配置自动提取页面路径，尝试 API 登录以访问受保护页面。`verify_project.sh --with-compose-up` 流程会自动调用该脚本。也可单独执行：

```bash
./scripts/capture_screenshots.sh generated/<project-slug>
```

建议截图命名规范：

- `01-login.png` — 登录页
- `02-dashboard.png` — 工作台 / Dashboard
- `03-list.png` — 主列表页
- `04-detail.png` — 详情页
- `05-form.png` — 表单 / 创建页

## 11. Claude Skills Assets

输出位置：

- `generated/<project-slug>/.claude/skills/find-skills/SKILL.md`

生成项目必须包含模板仓库的 `find-skills` 技能副本，使独立工程开箱即可发现和安装 Agent 技能。

生成方式：

- 从模板仓库 `.claude/skills/find-skills/SKILL.md` 原样复制到生成项目对应路径。
- 不修改 frontmatter 中的 `name` 和 `description` 字段。
- 如模板仓库中 `find-skills` 内容有更新，重新生成时应同步最新版本。

## 12. CHANGELOG

输出位置：

- `generated/<project-slug>/CHANGELOG.md`

必须包含：

- 版本号（语义版本，如 v1.0.0）和日期。
- 按 Added / Changed / Fixed / Removed 分类的变更记录。
- 初始版本必须记录核心功能和已知限制。

示例结构：

```markdown
# Changelog

## [1.0.0] - 2026-XX-XX

### Added
- 用户认证（注册/登录/JWT/Refresh Token）
- 核心业务 CRUD + 状态流转
- 管理员后台
- Docker Compose 部署
- CI/CD 管线（GitHub Actions + GitLab CI）

### Known Limitations
- 未实现邮件通知
- 未集成外部支付
```

## 13. Claude Memory Assets

输出位置：

- `generated/<project-slug>/.claude/memory/PLANNING.md`
- `generated/<project-slug>/.claude/memory/DECISIONS.md`
- `generated/<project-slug>/.claude/memory/PROGRESS.md`

`PLANNING.md` 记录项目开发计划、里程碑和优先级排序。`DECISIONS.md` 记录关键架构和技术选型决策及其理由（如"选择 bcrypt 而非 Argon2id 的原因"）。`PROGRESS.md` 记录当前开发进度、已完成项和待办事项。

这些文件帮助 Claude 在跨会话开发时保持上下文连续性。初始生成时应包含项目创建阶段的关键决策记录。

## 14. MCP Configuration

输出位置：

- `generated/<project-slug>/.mcp.json`

生成项目应包含 MCP 配置文件，定义项目可用的 AI 工具服务器。最低要求为空配置：

```json
{
  "mcpServers": {}
}
```

如项目有特殊的工具需求（如数据库查询、API 测试），可在此配置对应的 MCP server。
