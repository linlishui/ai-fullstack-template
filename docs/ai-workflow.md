# AI Workflow

## 标准工作流

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

### 阶段 5：修复与验证

- 使用 `prompts/07-fix-and-verify.md`
- 使用 `prompts/08-security-review.md`

## 推荐入口

通常直接从 `prompts/00-generate-from-requirement.md` 作为总控入口，让 AI 串行完成上述阶段。
