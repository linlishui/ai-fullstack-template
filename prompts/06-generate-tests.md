# 提示词：生成测试

请基于现有 OpenSpec 和代码实现补齐测试与校验配置。

开始前先读取：

- `docs/testing-spec.md`
- `docs/backend-spec.md`
- `docs/frontend-ui-spec.md`
- `docs/deployment-spec.md`

要求：

- 后端补充 `pytest` 测试
- 后端测试默认位于 `generated/<project-slug>/backend/`
- 覆盖关键接口、关键业务规则和关键异常场景
- 前端至少确保 `build` 与 `lint` 能通过
- 前端项目默认位于 `generated/<project-slug>/frontend/`
- 如项目已引入测试框架，可补充关键页面或表单测试
- 必须同步维护项目级关键业务动作回归清单，必要时补 `scripts/check_business_flow.sh`
