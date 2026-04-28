# High Quality Generation

## 目标

本模板的目标不是“尽快吐出代码”，而是让 AI 在固定约束下生成一个：

- 有规格依据
- 结构稳定
- 可以验证
- 可以继续迭代
- 能暴露风险与缺口

的独立工程包。

生成时的默认角色是资深全栈架构师、生产级交付负责人和严格代码审查者。判断标准不是文件数量，而是当前需求的主业务闭环是否真实可执行，工程资产是否能支撑实际开发、验证和交接。

## 质量原则

### 1. 先规格后实现

- 先分析 `requirements/requirement.md`
- 先生成 `generated/<project-slug>/openspec/`
- 没有规格，不进入完整业务实现

### 1.5 六项工程原则必须同时成立

生成结果不能只满足其中一部分，必须同时满足：

- 功能完整性：关键角色、关键动作、关键状态流转真正可执行
- 技术实现质量：技术栈、分层、配置、安全与异常处理达标
- 可测试性：测试、lint、构建、业务验证路径齐全
- 设计文档与 Spec Driven：需求、规格、设计、任务拆分可追溯
- AI 工具链使用：按模板工作流、脚本、文档和 skill 执行
- 代码可维护性：目录、模块边界、命名、README、迁移和测试支持持续演进

### 2. 先主链路后次优先级

优先保证业务闭环：

- 需求中最关键的用户动作
- 核心实体创建、编辑或提交
- 关键状态流转
- 关键角色的审批、确认、发布、分配或其他权限动作
- 关键列表、详情页、工作台或看板中的可见性一致性

不要先堆边角功能、装饰性页面或统计面板。

主链路优先级高于外围生产资产。Nginx、CI、文档、metrics、Tracing extension point 等默认要补，但不能先于真实持久化、真实 API 对接、关键状态流转和关键测试完成。

如果认证不是当前需求的核心目标，而只是访问控制或基础能力的一部分，则只应实现最小可用认证，不应把大量生成预算消耗在注册、登录、找回密码、认证体验打磨等扩展项上。

### 2.5 分层质量模型

- 不可降级硬门禁：OpenSpec-first、真实业务闭环、数据库-backed 持久化、真实前端 API/mutation 动作、认证授权、输入校验、关键测试、业务流脚本和模板审计。
- 默认生产增强：限流、request id、日志、metrics、Tracing extension point、Nginx、Docker、CI、OpenAPI、生产就绪清单、安全说明、可观测性说明和测试计划。
- 按需扩展：复杂认证体验、后台任务、复杂缓存、运营统计/BI、细粒度权限矩阵、多租户和复杂插件生态。只有需求或风险明确需要时才展开。

### 3. 只接受可验证产物

至少满足：

- `docker compose config`
- `backend pytest`
- `backend ruff check`
- `frontend npm run build`
- `frontend npm run lint`

如果需求允许生成更完整的工程资产，默认还应具备：

- Nginx 反向代理配置
- CI 工作流文件
- 项目级 AI 规则文件与协作记录模板
- 前端 UI 自查清单
- 生产就绪清单
- 健康检查依赖验证
- Logging / Metrics / Tracing 的接入位或说明

对应规则入口：

- 后端实现与分层：`docs/backend-spec.md`
- 测试与验证：`docs/testing-spec.md`
- 部署与容器：`docs/deployment-spec.md`
- 前端 UI：`docs/frontend-ui-spec.md`
- 生产级评分门禁：`docs/production-grade-rubric.md`
- fullstack reviewer 评分口径：`docs/fullstack-review-scoring.md`

### 4. 不允许静默失败

生成结果必须避免以下常见问题：

- 页面有表单，但提交无反馈
- 按钮存在，但无法走通业务状态流转
- 前端显示某状态，但数据库实际仍是另一状态
- 依赖某个初始化数据，但系统首次启动不会自动准备

## 模板级检查清单

每次生成后，应先执行模板级审计：

```bash
./scripts/audit_generated_project.sh generated/<project-slug>
```

模板级审计关注：

- 项目级文件是否齐全
- OpenSpec 是否齐全，且至少同时包含 `project.md`、`specs/<capability>/spec.md`、`changes/<change-id>/proposal.md`
- 需求快照、文档、脚本是否同步输出
- 前端是否同步输出页面质量相关说明或检查清单
- 是否同步输出生产就绪清单
- 是否包含 `.github/workflows/` 与 `infra/nginx/`
- 是否包含项目级 `AGENTS.md`、`CLAUDE.md`、`docs/ai-workflow.md`、`docs/review-log.md`、`docs/fix-log.md`
- 前后端核心入口是否存在
- 后端安全、错误处理、统一响应、健康检查等基础模块是否存在
- `.env.example` 是否覆盖关键配置
- README 是否包含验证命令

## 项目级验证清单

模板级审计通过后，再执行：

```bash
./scripts/verify_project.sh generated/<project-slug>
```

项目级验证关注：

- Docker Compose 配置是否可解析
- 后端测试与 lint 是否通过
- 前端构建与 lint 是否通过
- 前端是否对照 `docs/frontend-ui-spec.md` 中的验收清单补做了结构、视觉、状态和响应式检查
- 后端是否对照 `docs/backend-spec.md` 完成分层、配置、安全、迁移和接口契约自查
- 测试是否对照 `docs/testing-spec.md` 覆盖关键业务动作、异常与回归路径
- 部署是否对照 `docs/deployment-spec.md` 补齐环境变量、健康检查、启动说明和容器依赖
- 如果项目存在 `generated/<project-slug>/scripts/check_business_flow.sh`，是否已在服务启动后执行关键业务动作检查
- 如有需要，再加 `--with-compose-up` 验证容器启动

除此之外，还应检查项目级回归清单：

- `generated/<project-slug>/docs/key-business-actions-checklist.md` 是否存在
- 清单中的关键业务动作是否来自当前需求，而不是套用固定样例
- 修复后是否重新标注了动作验证状态

## AI 自查重点

在结束前，AI 应至少自查这些问题：

- 是否已经从当前需求中提炼出 3-5 个最关键的业务动作，并逐一验证
- 是否已经把这些动作写入 `generated/<project-slug>/docs/key-business-actions-checklist.md`
- 需求中的核心角色是否都能完成自己的关键动作
- 关键状态是否有明确入口触发，而不是只存在后端接口或数据库状态
- 关键接口是否有权限校验和输入校验
- 是否存在统一响应结构、全局异常处理、分页与资源级授权
- 是否为关键模型补齐 `created_at/updated_at`，必要时补软删除语义
- 是否已覆盖 Logging、Metrics、Tracing、安全头、Refresh Token 和 CSRF 等生产级要求
- 是否已把 `docs/production-grade-rubric.md` 中的安全、测试、OpenAPI、限流、Docker 与可观测性要求落到代码和脚本，而不是只写在文档中
- 是否已把 AI 工具链规则和审查/修复记录下沉到生成项目本身，而不是只保留在模板仓库
- 关键列表、详情、工作台、审批或运营视图是否与真实状态一致
- 空数据、重复数据、越权访问、失败提交是否有反馈
- 初始化项目后，系统是否能以最小步骤跑起来
- 六项工程原则是否各自对应到明确产物，例如 OpenSpec、架构文档、测试、验证脚本、README、模块化目录，而不是停留在描述层

## 典型高风险点

### 表单与交互

- 自定义输入组件未正确转发 `ref`，导致表单值无法提交
- 表单校验失败或接口失败没有错误提示
- 只在前端做权限控制，后端未校验
- 把支撑性表单误当成主链路，导致真正关键业务动作被弱化

### 生命周期与状态流转

- 实体创建后停在某个中间状态，但前端没有继续流转入口
- 不同状态在列表、详情、工作台中的显示逻辑不一致
- 某个关键动作已经成功，但结果没有同步到应出现的视图中

### 启动与初始化

- 应用启动依赖数据库表，但 migration 尚未执行
- 默认种子数据缺失导致关键页面为空
- Compose 端口、健康检查、环境变量不一致

## 满分导向硬门禁

结合 fullstack reviewer 的评分范式，生成流程必须把“看起来完整”和“真实可用”区分开。以下情况即使目录、文档、模型和构建都存在，也不能判定为高分：

- 后端主业务路由仍使用 `MemoryStore`、模块级 dict/list、JSON 文件或进程内全局变量，数据库模型、migration、repository 只是摆设
- 前端核心按钮只执行 `setTimeout`、静态 toast、硬编码统计值、硬编码分类或本地假数据，没有真实 API/hook/mutation
- 登录态只有模块变量 token，没有注册/登录入口、会话状态、退出、401/refresh 策略或安全说明
- readiness 只返回配置状态，未真实探测数据库和 Redis
- metrics 使用 `request.url.path` 等高基数标签
- Dockerfile 以 root 用户运行生产服务，或 Nginx CSP 在生产默认配置中硬编码 localhost
- `index.html`、前端 lockfile、关键前端测试、业务流验证脚本缺失

生成和修复时，优先让关键业务闭环在真实数据层、真实 API 和真实 UI 交互之间跑通，再补统计面板、装饰性页面或二级能力。

## 推荐改进节奏

如果生成结果没有一次达标，优先按以下顺序修：

1. 修复启动与验证失败
2. 修复主链路不可用
3. 修复权限与状态不一致
4. 修复交互反馈问题
5. 再处理体验优化与扩展功能
