# 提示词：生成测试

请基于现有 OpenSpec 和代码实现补齐测试与校验配置。

要求：

- 后端补充 `pytest` 测试
- 后端测试默认位于 `generated/<project-slug>/backend/`
- 覆盖关键接口、关键业务规则和关键异常场景
- 前端至少确保 `build` 与 `lint` 能通过
- 前端项目默认位于 `generated/<project-slug>/frontend/`
- 如项目已引入测试框架，可补充关键页面或表单测试
