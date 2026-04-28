# Project Asset Templates

本文件集中定义生成项目的文档与 AI 协作资产模板，替代分散的单项模板文件。生成项目仍应输出对应文件，但内容必须按 `docs/template-governance.md` 保持“项目事实 + 证据路径 + 验证结果 + 风险”，不要复制模板长规则。

## 1. AI Collaboration Assets

输出位置：

- `generated/<project-slug>/AGENTS.md`
- `generated/<project-slug>/CLAUDE.md`
- `generated/<project-slug>/docs/ai-workflow.md`
- `generated/<project-slug>/docs/review-log.md`
- `generated/<project-slug>/docs/fix-log.md`

必须覆盖：

- 项目目标、技术栈、目录结构和主业务闭环。
- OpenSpec-first、真实持久化、真实前端 API/mutation、配置环境变量化、测试和验证规则。
- 本项目验证命令：compose、backend pytest/coverage/ruff、frontend build/lint/test、OpenAPI 导出、业务流脚本。
- review/fix 记录字段：日期、触发原因、范围、发现问题、修复动作、影响范围、回归验证。

## 2. Architecture And Development Docs

输出位置：

- `generated/<project-slug>/docs/architecture.md`
- `generated/<project-slug>/docs/development.md`

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

- `generated/<project-slug>/docs/key-business-actions-checklist.md`

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

- `generated/<project-slug>/docs/frontend-ui-checklist.md`

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

- `generated/<project-slug>/docs/production-readiness-checklist.md`

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

- `generated/<project-slug>/docs/security-notes.md`

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

- `generated/<project-slug>/docs/observability.md`

必须记录：

- Request context：header、middleware、log field。
- Logs：格式、access/error 字段、敏感字段脱敏。
- Metrics：endpoint、library、key metrics、path label strategy；禁止 raw URL path。
- Health checks：live、ready、database、Redis、probe evidence。
- Tracing：状态、配置、integration point。
- Operations：Nginx logs、proxy timeout、验证命令。

## 8. Test Plan

输出位置：

- `generated/<project-slug>/docs/test-plan.md`

必须映射真实需求和关键风险：

- Backend tests：success、auth failure、authorization failure、validation failure、conflict、illegal state transition、dependency failure、database-backed persistence、health/readiness、coverage command。
- Frontend tests：smoke、component、ErrorBoundary、loading/empty/error states、API hook/mutation path、auth/session or unauthorized flow、mobile layout。
- Business flow：script、roles、state transitions、repeatability。
- Manual checks：未自动化原因和风险。

最低要求：后端不少于 8 个关键用例，前端至少覆盖一个真实 API hook/mutation 驱动路径，业务流脚本自包含、可重复执行、无需人工 token。
