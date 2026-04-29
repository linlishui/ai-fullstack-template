---
name: fullstack-review-v2
version: 2.1.0
description: |
  对 generated/ 下的独立工程进行"生产级严格全栈审查"，驱动 6 个并行 Sub-agent 分析
  后端/前端/安全/部署/质量/AI 工程化共 6 个维度，最终生成带评分、门禁结论和优先整改
  清单的 Markdown 报告。用于考核前自评和生产级模板质量把关。
  L1 失败项即触发红色警告，通过本审查视为可上线。
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Write
  - Agent
---

## 审查目标

**审查对象**：`generated/<project-slug>/` 下的独立工程，而非模板仓库本身。

通过本 skill 的项目，需满足以下标准：

- L1 硬门禁全部通过（无红色警告）
- 总分 ≥ 80（B 级及以上）
- 具备完整的可观测性三支柱：Logging / Metrics / Tracing
- 生产安全基线：认证、密码存储、安全头、CORS 均已配置
- 部署链路完整：Docker + Nginx + CI/CD
- 质量底线：测试目录存在、文档完整、迁移可回滚

---

## Step 0：定位审查目标项目 & 环境初始化

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
echo "模板仓库根目录: $REPO_ROOT"

# 自动探测 generated/ 下的项目
PROJECTS=$(ls -d "$REPO_ROOT"/generated/*/ 2>/dev/null | grep -v '.DS_Store')
echo "已发现的 generated 项目:"
echo "$PROJECTS"
```

**项目选择规则**：
1. 如果用户明确指定了项目名（如 `generated/skillsops`），直接使用
2. 如果 `generated/` 下只有一个项目目录，自动选中
3. 如果有多个项目，提示用户选择

```bash
PROJECT_ROOT="$REPO_ROOT/generated/<project-slug>"  # 替换为实际 slug
REPORT_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$REPO_ROOT/generated/docs/fullstack-review-v2-${REPORT_TIMESTAMP}.md"
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "REPORT_FILE: $REPORT_FILE"
mkdir -p "$REPO_ROOT/generated/docs"
```

> **重要**：后续所有文件读取、路径引用、Sub-agent 扫描和报告输出均以 `$PROJECT_ROOT` 为根目录。

---

## Step 1：快速结构预扫描

在启动 Sub-agent 之前，执行一次结构预扫描，获取全局上下文：

```bash
cd "$PROJECT_ROOT"
echo "=== 后端结构 ===" && ls backend/ 2>/dev/null
echo "=== 前端结构 ===" && ls frontend/src/ 2>/dev/null || ls frontend/ 2>/dev/null
echo "=== 部署资产 ===" && ls compose.yaml docker-compose.yml infra/nginx/ .github/ 2>/dev/null
echo "=== 测试目录 ===" && ls backend/tests/ 2>/dev/null
echo "=== AI 工程资产 ===" && ls openspec/ CLAUDE.md AGENTS.md .claude/ 2>/dev/null
echo "=== Git 状态 ===" && git log --oneline -5
```

将此次扫描结果作为后续 Sub-agent 的上下文背景。

---

## Step 2：并行启动 6 个审查 Sub-agent

以下 6 个 Sub-agent **同时启动**，互不依赖。每个 Sub-agent 只聚焦自己的维度。

> **所有 Sub-agent 的文件路径均相对于 `$PROJECT_ROOT`（即 `generated/<project-slug>/`）。**

### Agent 1 — backend-reviewer

**审查域**：后端 API、ORM、日志、限流、异常、可观测性、连接池

必须逐项核查以下检查点：

**L1（硬门禁）**

- [ ] 主应用入口文件存在（检查 `main.py`、`app.py`、`server.py` 等）
- [ ] API 路由版本化（检查 `/api/v1/`、`/v1/`、`/api/` 等前缀）
- [ ] 数据库迁移机制（检查 `migrations/`、`alembic/`、`migrate/` 目录）
- [ ] 统一响应结构（检查 Response Schema、ApiResponse、通用响应格式）
- [ ] 结构化日志输出（检查日志包含 request_id、trace_id、correlation_id 等追踪字段）

**L2（进阶要求）**

- [ ] 全局异常处理机制（检查全局异常处理器、错误中间件）
- [ ] HTTP 状态码规范使用（检查 2xx/4xx/5xx 状态码语义正确性）
- [ ] API 限流保护（检查限流中间件、Rate Limiting 实现）
- [ ] 数据库连接池配置（检查连接池参数、超时设置）
- [ ] 异步 I/O 架构（检查 async/await 使用、非阻塞调用）
- [ ] 查询性能优化（检查 N+1 查询预防、关联查询优化）
- [ ] 分页实现（列表类接口如 `list_messages`、`list_conversations` 必须有 `page`/`limit` 参数）
- [ ] 模型字段完整性（检查关键模型是否有 `updated_at` 字段用于追踪修改时间）

**L3（生产加分）**

- [ ] 应用性能监控（检查 APM 集成、异常追踪服务）
- [ ] 业务指标埋点（检查 Metrics、监控指标、RED/USE 方法论）
- [ ] 容错机制实现（检查重试策略、熔断器、超时处理）
- [ ] 优雅关机支持（检查 Graceful Shutdown、信号处理）
- [ ] 健康检查完善（检查 Health Check 包含依赖服务连通性验证）

**检测脚本**：
```bash
cd "$PROJECT_ROOT"

# 自动检测健康检查接口（兼容多种路径结构）
HEALTH_FILE=$(find backend/app -name 'health.py' -path '*/routes/*' -o -name 'health.py' -path '*/api/*' 2>/dev/null | head -1)
if [[ -n "$HEALTH_FILE" ]] && grep -q "mysql\|redis\|SELECT.*1\|\.ping" "$HEALTH_FILE" 2>/dev/null; then
    echo "PASS: Health check includes dependency verification ($HEALTH_FILE)"
else
    echo "FAIL: Health check missing real dependency probes - 需要在健康检查中添加 MySQL SELECT 1 / Redis ping"
fi

# 自动检测 N+1 查询问题（搜索 services 和 repositories）
if grep -rq "selectinload\|joinedload\|subqueryload" backend/app/services/ backend/app/repositories/ 2>/dev/null; then
    echo "PASS: Query optimization implemented"
else
    echo "WARN: Potential N+1 queries - backend/app/services/ 或 repositories/ 未见 eager loading"
fi

# 检测 CI/CD 配置
if ls .github/workflows/*.yml >/dev/null 2>&1; then
    echo "PASS: CI/CD pipeline configured"
else
    echo "FAIL: No CI/CD pipeline - 需要创建 .github/workflows/ci.yml"
fi

# 检测分页实现（兼容 routes 和 api 目录结构）
if grep -rq "page\|limit\|offset\|paginate" backend/app/routes/ backend/app/api/ 2>/dev/null; then
    echo "PASS: Pagination implemented"
else
    echo "FAIL: No pagination found - 列表接口需要分页参数"
fi

# 检测 updated_at 字段
if grep -rn "updated_at" backend/app/models/ 2>/dev/null; then
    echo "PASS: Models have updated_at"
else
    echo "FAIL: Models missing updated_at - 应添加 updated_at 字段用于追踪修改时间"
fi
```

**输出格式要求**：
每项输出 `PASS/FAIL/WARN`，FAIL 附上文件路径 + 具体缺失内容 + 修复建议。

---

### Agent 2 — frontend-reviewer

**审查域**：组件、TypeScript 类型、状态管理、API 对接、错误兜底、性能

**L1（硬门禁）**

- [ ] `$PROJECT_ROOT/frontend/src/` 存在，且 TypeScript 配置文件完整
- [ ] 至少一处 ErrorBoundary（`componentDidCatch` / `getDerivedStateFromError`）
- [ ] 全局 HTTP 请求统一封装（Axios 实例 / React Query），禁止裸 `fetch`
- [ ] API 响应错误统一处理，不允许静默吞掉 HTTP 错误

**L2（进阶要求）**

- [ ] 路由懒加载（`React.lazy + Suspense`），关键路由已分包
- [ ] Loading 态处理（骨架屏 / Spinner），禁止白屏加载
- [ ] 表单校验库接入（React Hook Form / Ant Design Form）
- [ ] TypeScript 无 `any` 滥用，Props / API 响应均有类型定义

**L3（生产加分）**

- [ ] 状态管理方案明确（Zustand / Jotai / Redux Toolkit）
- [ ] 关键接口有 optimistic update 或 loading/error/success 三态管理
- [ ] 打包产物体积可控（关键路由 chunk < 200KB）

**输出格式要求**：同 Agent 1。

---

### Agent 3 — security-reviewer

**审查域**：认证、密码安全、CORS、安全头、审计日志、依赖扫描

**L1（硬门禁）**

- [ ] JWT 或 Session 认证体系完整（生成、校验、过期处理）
- [ ] 密码使用 bcrypt / argon2 哈希存储（禁止明文或 MD5/SHA1）
- [ ] CORS 配置存在且非 `allow_origins=["*"]`（生产环境必须白名单）
- [ ] SQL 注入防护：全程使用 ORM 参数绑定，禁止字符串拼接 SQL

**L2（进阶要求）**

- [ ] Token 刷新机制（Refresh Token）或 Token 黑名单吊销
- [ ] 安全响应头配置（`X-Content-Type-Options` / `X-Frame-Options` / `CSP`）
- [ ] 权限控制体系（RBAC / 角色枚举），路由层有权限校验
- [ ] XSS 防护：前端渲染不信任服务端数据，避免 `dangerouslySetInnerHTML`
- [ ] 密钥管理：无硬编码密钥，`.env.example` 包含所有必填环境变量
- [ ] Cookie 安全配置：`refresh_token` Cookie 必须设置 `secure=True`、`sameSite=strict`、`httponly=True`
- [ ] Refresh Token 端点必须有 CSRF 保护（Origin 校验或自定义 token）

**L3（生产加分）**

- [ ] 关键操作审计日志（用户 ID + 操作类型 + 时间戳 + IP）
- [ ] 依赖漏洞检测报告（`pip-audit` / `npm audit` 纳入 CI）

**输出格式要求**：同 Agent 1。安全类 FAIL 项额外标注 [SECURITY RISK] 标签。

**拉开差距的安全审查要点：**
- Cookie 安全属性配置（`secure`、`httpOnly`、`sameSite`）
- refresh_token 是否使用签名机制防止伪造
- 敏感信息是否在日志中泄露
- API 限流是否到位（防暴力破解）
- 依赖包是否有已知漏洞

**检测脚本**：
```bash
cd "$PROJECT_ROOT"

# 查找 auth 路由文件（兼容多种路径结构）
AUTH_FILE=$(find backend/app -name 'auth.py' -path '*/routes/*' -o -name 'auth.py' -path '*/api/*' 2>/dev/null | head -1)
if [[ -z "$AUTH_FILE" ]]; then
    echo "WARN: No auth route file found"
    AUTH_FILE="backend/app/api/v1/routes/auth.py"  # fallback for grep
fi

# 检测 Cookie secure 属性（应为环境感知配置，非硬编码 False）
if grep -n "secure=False\|secure = False" "$AUTH_FILE" 2>/dev/null; then
    echo "FAIL: Cookie secure=False - $AUTH_FILE: 必须使用环境变量控制或 secure=True"
elif grep -n "settings.ENVIRONMENT\|ENVIRONMENT == \|settings.COOKIE_SECURE\|cookie_secure" "$AUTH_FILE" 2>/dev/null | grep -q "secure"; then
    echo "PASS: Cookie secure is environment-aware"
else
    echo "PASS: Cookie secure=True"
fi

# 检测 sameSite 配置
if grep -n 'samesite="lax"\|samesite="none"' "$AUTH_FILE" 2>/dev/null; then
    echo "FAIL: Cookie sameSite too permissive - 应使用 sameSite='strict'"
else
    echo "PASS: Cookie sameSite is strict"
fi

# 检测 delete_cookie 与 set_cookie 的 secure 配置一致性
if grep -A2 "delete_cookie" "$AUTH_FILE" 2>/dev/null | grep -q "secure=settings\|secure=True"; then
    echo "PASS: delete_cookie has consistent secure setting"
else
    echo "WARN: delete_cookie may not match set_cookie secure setting"
fi

# 检测 refresh 端点是否有 CSRF 保护
if grep -A5 "/refresh\|refresh_token" "$AUTH_FILE" 2>/dev/null | grep -q "Origin\|origin\|csrf\|CSRF"; then
    echo "PASS: Refresh endpoint has Origin/CSRF check"
else
    echo "FAIL: Refresh endpoint missing CSRF protection - 需要检查 Origin header"
fi
```

---

### Agent 4 — deploy-reviewer

**审查域**：Docker、Nginx、CI/CD、健康检查、零停机

**L1（硬门禁）**

- [ ] `compose.yaml` / `docker-compose.yml` 包含 app/db/redis/nginx 完整编排
- [ ] `backend/Dockerfile` 存在，使用多阶段构建压缩镜像体积
- [ ] Nginx 反向代理配置（`infra/nginx/`）：API 代理 + 前端静态资源 + 基础安全头
- [ ] 环境变量通过 `.env` 注入，不硬编码进镜像

**L2（进阶要求）**

- [ ] CI 流水线（GitLab CI），至少覆盖 lint → test → build
- [ ] 多环境配置区分（dev / staging / prod 至少两套）
- [ ] 容器健康检查（`healthcheck` 指令在 compose 中配置）
- [ ] 数据库 Volume 持久化配置正确（不使用默认匿名 volume）

**L3（生产加分）**

- [ ] CI 流水线自动部署（push to main → deploy to staging）
- [ ] 优雅关机与零停机部署（`stop_grace_period` / 滚动更新策略）
- [ ] 镜像 tag 规范（使用 git commit SHA，禁止 `latest` 进生产）
- [ ] 资源限制配置（`mem_limit` / CPU 限制在 compose 中声明）

**输出格式要求**：同 Agent 1。

---

### Agent 5 — quality-reviewer

**审查域**：测试覆盖率、代码规范、文档、迁移回滚、软删除

**L1（硬门禁）**

- [ ] `$PROJECT_ROOT/backend/tests/` 存在，包含至少 auth / users / 核心业务的测试文件
- [ ] README.md 包含：技术架构、本地启动步骤、API 说明、部署方式
- [ ] Alembic 每次迁移都有 `downgrade()` 函数实现

**L2（进阶要求）**

- [ ] 测试覆盖关键 happy path + 至少一条 error path
- [ ] 代码规范工具配置（`ruff` / `black` / `eslint` / `prettier`）
- [ ] API 文档完整（FastAPI 自动 Swagger，Schema 描述字段无空缺）
- [ ] 核心数据模型有软删除字段（`deleted_at` / `is_deleted`）
- [ ] 异常场景测试覆盖：数据库错误、Redis 不可用等边界条件必须被测试

**L3（生产加分）**

- [ ] 单元测试覆盖率 ≥ 80%（pytest-cov 报告）
- [ ] 集成测试使用真实 DB/Redis，不全量 Mock
- [ ] E2E 测试覆盖完整用户流程（至少注册/登录/核心业务一条链路）
- [ ] CHANGELOG.md 或版本记录文件存在
- [ ] 测试本身可读性（描述清晰，断言明确，有 mock 外部依赖的意识）

**拉开差距的质量审查要点：**
- 异常场景测试覆盖（数据库错误、Redis 不可用）**必须实际检查测试文件内容**
- 边界条件测试（空数据、最大值、超时）
- 测试本身可读性（描述清晰，断言明确）
- 是否有 mock 外部依赖的意识
- **检测脚本**：
```bash
cd "$PROJECT_ROOT"

# 检测异常场景测试覆盖
if grep -rq "timeout\|redis\|AsyncSession\|IntegrityError\|HTTPException\|status_code.*4[0-9][0-9]" backend/tests/ 2>/dev/null; then
    echo "PASS: Exception scenario tests found"
else
    echo "FAIL: No exception scenario tests - backend/tests/ 需要补充 Redis/DB 异常测试"
fi

# 检测 migration downgrade 完整性
MISSING_DOWNGRADE=0
for mfile in backend/migrations/versions/*.py; do
    [[ -f "$mfile" ]] || continue
    if ! grep -q "def downgrade" "$mfile"; then
        echo "FAIL: Migration missing downgrade: $mfile"
        MISSING_DOWNGRADE=1
    fi
done
[[ "$MISSING_DOWNGRADE" -eq 0 ]] && echo "PASS: All migrations have downgrade()"
```

**输出格式要求**：同 Agent 1。

---

### Agent 6 — ai-reviewer

**审查域**：AI 工程化文件体系、SDD 工作流资产、Agent 配置规范

**L1（硬门禁）**

- [ ] `$PROJECT_ROOT/openspec/` 目录存在，包含需求规格或接口设计文档
- [ ] AI 协作规约文件存在（`CLAUDE.md` / `AGENTS.md` / `.claude/` / `.cursor/` / `.qoder/` 任一即可，位于 `$PROJECT_ROOT` 下）

**L2（进阶要求）**

- [ ] 协作规约文件包含：项目背景 / coding 规范 / testing 规则 / 禁止行为
- [ ] Skills 目录（`.claude/skills/` / `.cursor/skills/` / `.qoder/skills/`）有可执行的工作流封装
- [ ] openspec 文档结构清晰，有对应代码的可追踪性
- [ ] 有 AI 驱动开发证据（commit 信息 / SDD 工作流记录）

**L3（生产加分）**

- [ ] Memory 文件体系（PLANNING / DECISIONS / PROGRESS 等）
- [ ] MCP 配置（`.mcp.json` 或 MCP 服务已集成）
- [ ] Sub-agent 编排方案（多 agent 并行开发记录）

**拉开差距的 AI 工程化审查要点：**
- AI 配置文件是否有实质性约束（不是空文件）
- 是否有对 AI 输出进行 review 和修正的证据
- 是否使用了 Hooks、skills、自定义命令等高阶功能
- 是否利用 AI 做了测试生成、文档生成等高阶用法

**输出格式要求**：同 Agent 1。

---

## Step 3：等待并汇聚所有 Agent 结果

收集 6 个 Sub-agent 的结构化输出，按如下维度聚合：

- 各维度 PASS/FAIL/WARN 项计数
- 全量 L1 失败项列表（即"硬门禁失败项"）
- 按 L1 → L2 → L3 优先级排序的 Top 整改清单
- 综合评分计算

**评分规则**：

| 等级 | 权重 |
|------|------|
| L1 项 | 10 分/项（不通过则扣全部） |
| L2 项 | 7 分/项 |
| L3 项 | 5 分/项 |

最终得分 = `(实际得分 / 满分) × 100`

---

## Step 4：生成审查报告

将汇聚结果写入 `$REPO_ROOT/generated/docs/fullstack-review-v2-YYYYMMDD-HHMMSS.md`，格式如下：

```markdown
# Fullstack 生产级审查报告（YYYY-MM-DD）

## 概览

| 项目         | 结果         |
|--------------|-------------|
| 总分          | XX/100 (XX%) |
| 等级          | A/B/C/D      |
| 风险等级      | 低/中/高     |
| L1 硬门禁失败 | N 项         |
| 审查维度      | 6 个         |

## 1) 各维度评分

| 维度     | 得分 | 满分 | 通过/总数 | 达成率 |
|----------|------|------|-----------|--------|
| 后端能力 |      |      |           |        |
| 前端能力 |      |      |           |        |
| 安全能力 |      |      |           |        |
| 部署运维 |      |      |           |        |
| 质量工程 |      |      |           |        |
| AI 工程化|      |      |           |        |

## 2) L1 硬门禁失败项

> 以下每项失败均代表不可上线的红色风险，必须优先清零。

- [维度-ID] 标题
  - 失败证据：<具体文件路径或缺失现象>
  - 修复动作：<精确到文件+行为的整改指令>

## 3) Top 优先整改清单

按 L1 失败 → 高权重 L2 失败 → L2 WARN → L3 缺失 排序，最多输出 15 条。

1. [ID] 标题 — `维度`/`L1`
   - 失败证据：
   - 修复动作：

## 4) 全量检查明细

| ID | 维度 | 等级 | 分值 | 结果 | 证据摘要 |
|----|------|------|------|------|----------|

## 5) 做得好的地方

> 列出项目中设计合理的部分，鼓励好的实践

## 6) 审查结论

- 通过/未通过（含下一步行动指引）
- 建议下一轮整改后重新执行：`python scripts/fullstack_review.py`
```

---

## Step 5：运行自动化扫描脚本（可选加强）

在报告基础上，额外执行静态扫描脚本以获得更精确的文件级证据：

```bash
# 从模板仓库根目录执行审计脚本，传入项目路径
cd "$REPO_ROOT"
./scripts/audit_generated_project.sh "$PROJECT_ROOT"
./scripts/verify_project.sh "$PROJECT_ROOT"
```

若脚本得分与 Sub-agent 分析有偏差，以 Sub-agent 人工分析为准，脚本结果作为辅助参考。

---

## Step 6：向用户呈现摘要

完成报告写入后，在对话中输出以下摘要（报告详情见文件）：

```
FULLSTACK REVIEW COMPLETE
═══════════════════════════════
项目：generated/<project-slug>/
报告：generated/docs/fullstack-review-v2-YYYYMMDD-HHMMSS.md

总分：XX/100 (XX%) — 等级 [A/B/C/D]
风险：[低/中/高]
L1 门禁失败：N 项

最紧急整改项（前 3）：
1. [ID] 标题 — <一句话说清楚要做什么>
2. [ID] 标题 — <一句话说清楚要做什么>
3. [ID] 标题 — <一句话说清楚要做什么>

[通过 / 未通过 — 建议完成 P0 整改后重新执行]
═══════════════════════════════
```

---

## 铁律（严格执行，不可绕过）

1. **审查对象是 `generated/<project-slug>/` 下的独立工程**，不审查模板仓库本身的 `prompts/`、`scripts/`、`docs/` 等基础设施。
2. **L1 失败不允许给出"可上线"结论**，哪怕总分超过 90 分。
3. **修复建议必须可执行**：必须精确到"在哪个文件、加什么代码"，禁止模糊建议。文件路径以 `$PROJECT_ROOT` 为基准。
4. **证据必须来自实际文件内容**，不允许推测性表述（"可能有"、"应该是"）。
5. **每轮整改后重新执行全量审查**，不接受局部自评代替完整审查。
6. **不做"模糊通过"**：命中条件不充分即 FAIL，不允许因"意图正确"给 PASS。

---

## 审查态度与原则

**站在合作者的角度，而非批评者：**
- 假设开发者是聪明的，只是经验尚不足，而非不负责任
- 解释"为什么"这是问题，而不只是"这是错的"
- 给出可落地的修复建议，而非泛泛而谈

**区分"必须修"和"最好修"：**
- 生产安全漏洞、数据丢失风险 → 🚨 高优先级（L1）
- 性能瓶颈、设计缺陷、缺少关键功能 → ⚠️ 中优先级（L2）
- 代码风格、可维护性改进、最佳实践 → 💡 低优先级（L3）

**对前端背景开发者特别关注：**
- 服务端特有的概念（事务、连接池、并发）要简单解释
- 性能问题要结合具体场景说明影响
- 安全问题要说清楚实际攻击场景，而不只是"这不安全"

**如果项目文件不全：**
- 基于已有信息尽力审查，对无法判断的地方明确说明
- 提出需要用户补充提供的关键信息

---

## 参考资料（审查时可引用）

- 阿里巴巴 Java 开发规范：https://alibaba.github.io/p3c/
- Node.js 安全（Egg.js）：https://www.eggjs.org/zh-CN/core/security
- Docker 从入门到实践：https://yeasy.gitbook.io/docker_practice
- 高性能数据库表设计：https://cloud.tencent.com/developer/article/1799495
- The Twelve-Factor App（现代应用架构圣经）：https://12factor.net/zh_cn/
- Testing Trophy（前端测试分层）：https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications
- SDD 实践合集：https://km.netease.com/v4/topic/5496
- Claude Code 官方文档：https://code.claude.com/docs/zh-CN/overview
- Cursor Agent 最佳实践：https://cursor.com/cn/blog/agent-best-practices

---

## Completion Status

完成后使用以下格式报告：

- **DONE** — 报告已生成至 `generated/docs/`，摘要已输出，所有维度已覆盖
- **DONE_WITH_CONCERNS** — 报告已生成，但某 Sub-agent 扫描失败或数据不完整
- **BLOCKED** — `generated/` 下无项目或项目结构无法识别，无法执行扫描
