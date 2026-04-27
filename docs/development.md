# Development Guide

## 本地使用建议

1. 执行 `scripts/check_prerequisites.sh`
2. 根据模板补充 `requirements/requirement.md`
3. 让 Codex 执行 `prompts/00-generate-from-requirement.md`
4. 让 Codex 执行 `prompts/07-fix-and-verify.md`
5. 根据 `scripts/verify_project.sh` 对 `generated/<project-slug>/` 完成验证；如项目提供 `scripts/check_business_flow.sh`，可通过 `--with-compose-up` 自动一并执行

## 开发原则

- 不直接从空白开始写业务代码
- 不绕过 OpenSpec
- 不将配置写死在代码中
- 不省略 migration、测试和 README 更新

## 生成后最低验证标准

- 生成结果必须包含 `generated/<project-slug>/README.md`
- 生成结果必须包含 `generated/<project-slug>/.env.example`
- 在 `generated/<project-slug>/` 中执行 `docker compose config`
- 在 `generated/<project-slug>/` 中执行 `docker compose up --build`
- 在 `generated/<project-slug>/backend/` 中执行 `pytest`
- 在 `generated/<project-slug>/backend/` 中执行 `ruff check`
- 在 `generated/<project-slug>/frontend/` 中执行 `npm run build`
- 在 `generated/<project-slug>/frontend/` 中执行 `npm run lint`
