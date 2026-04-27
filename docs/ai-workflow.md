# AI Workflow

## 标准工作流

### 阶段 0：质量预期

- 先确认本次目标是生成“可验证工程”，不是只生成代码片段
- 优先保证当前需求里最关键的业务闭环，再补次优先级功能
- 生成完成后必须通过模板级审计与项目级验证

这里的“业务闭环”应由当前需求决定，而不是固定等同于认证流程。
如果需求包含认证，则认证属于关键动作之一；如果需求重点不在认证，则不应默认把大量时间消耗在注册/登录环节。

### 阶段 1：输入需求

- 将完整业务需求写入 `requirements/requirement.md`

### 阶段 2：分析需求

- 使用 `prompts/01-analyze-requirement.md` 分析业务目标、角色、模块、实体与约束

### 阶段 3：生成 OpenSpec

- 使用 `prompts/02-generate-openspec.md` 生成规格、设计和任务

### 阶段 4：生成实现

- 在 `generated/<project-slug>/` 下创建当前需求对应的实现目录
- 使用 `prompts/03-generate-backend.md`
- 使用 `prompts/04-generate-frontend.md`
- 使用 `prompts/05-generate-docker.md`
- 使用 `prompts/06-generate-tests.md`
- 在 `generated/<project-slug>/docs/key-business-actions-checklist.md` 中输出基于当前需求的关键业务动作回归清单

### 阶段 5：修复与验证

- 使用 `prompts/07-fix-and-verify.md`
- 使用 `prompts/08-security-review.md`
- 修复后必须重新核对关键业务动作回归清单，而不只是重跑构建命令

### 阶段 6：模板级审计

- 执行 `./scripts/audit_generated_project.sh generated/<project-slug>`
- 确认目录、OpenSpec、README、环境变量模板、核心入口文件齐全

### 阶段 7：项目级验证

- 执行 `./scripts/verify_project.sh generated/<project-slug>`
- 如需验证容器启动，再执行 `./scripts/verify_project.sh generated/<project-slug> --with-compose-up`
- 如果生成项目存在 `generated/<project-slug>/scripts/check_business_flow.sh`，验证脚本会在 `--with-compose-up` 场景下自动执行它

## 推荐入口

通常直接从 `prompts/00-generate-from-requirement.md` 作为总控入口，让 AI 串行完成上述阶段。

## 一键入口

如果本机已安装 `codex` CLI，可直接运行：

```bash
./scripts/run_full_flow.sh
```

该脚本会依次调用总控提示词与修复验证提示词。

## 补充说明

- `run_full_flow.sh` 解决“生成 + 修复验证”的主流程
- `audit_generated_project.sh` 解决“结构与规范是否达标”的模板级质量门禁
- `verify_project.sh` 解决“项目是否真的可执行”的工程级质量门禁
- `verify_project.sh` 也作为业务校验入口，自动调用项目级 `scripts/check_business_flow.sh`
- `docs/business-checklist-template.md` 提供“需求驱动”的关键业务动作回归模板
