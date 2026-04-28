# Development Guide

## 本地使用建议

1. 执行 `scripts/check_prerequisites.sh`
2. 根据模板补充 `requirements/requirement.md`
3. 在 Codex 或 Claude Code 中执行 `prompts/00-generate-from-requirement.md`
4. 在同一端 AI 中继续执行 `prompts/07-fix-and-verify.md`
5. 根据 `scripts/verify_project.sh` 对 `generated/<project-slug>/` 完成验证；如项目提供 `scripts/check_business_flow.sh`，可通过 `--with-compose-up` 自动一并执行
6. 先读取 `docs/frontend-ui-spec.md`，再对照其中的验收清单检查生成页面是否满足结构、状态、响应式和视觉一致性要求
7. 生成后端、测试、部署时，分别以 `docs/backend-spec.md`、`docs/testing-spec.md`、`docs/deployment-spec.md` 作为对应阶段的规则入口

`scripts/verify_project.sh` 会在开始时自动调用 `scripts/check_prerequisites.sh`。如果缺少 `docker`、`docker compose`、`python3`、`node` 或 `npm`，验证会直接中止并输出缺失项。

## 开发原则

- 不直接从空白开始写业务代码
- 不绕过 OpenSpec
- 不将配置写死在代码中
- 不省略 migration、测试和 README 更新
- 不绕过后端、测试、部署规范文档各自定义的质量门禁

## 生成后最低验证标准

- 生成结果必须包含 `generated/<project-slug>/README.md`
- 生成结果必须包含 `generated/<project-slug>/.env.example`
- 在 `generated/<project-slug>/` 中执行 `docker compose config`
- 在 `generated/<project-slug>/` 中执行 `docker compose up --build`
- 在 `generated/<project-slug>/backend/` 中执行 `pytest`
- 在 `generated/<project-slug>/backend/` 中执行 `ruff check`
- 在 `generated/<project-slug>/frontend/` 中执行 `npm run build`
- 在 `generated/<project-slug>/frontend/` 中执行 `npm run lint`
