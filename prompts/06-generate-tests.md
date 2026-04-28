# 提示词：生成测试

请基于现有 OpenSpec 和代码实现补齐测试与校验配置。

开始前先读取：

- `docs/testing-spec.md`
- `docs/backend-spec.md`
- `docs/frontend-ui-spec.md`
- `docs/deployment-spec.md`
- `docs/production-grade-rubric.md`

要求：

- 后端补充 `pytest` 测试
- 后端测试默认位于 `generated/<project-slug>/backend/`
- 覆盖关键接口、关键业务规则和关键异常场景
- 必须至少覆盖一条核心业务接口通过数据库-backed service/repository 写入后，再被查询或后续状态流转读取的路径；只测 `MemoryStore`、mock service 或路由存在性不算通过
- 后端测试不得少于 8 个关键用例；必须覆盖成功路径、认证失败、越权、非法输入、重复/冲突、非法状态流转、限流或依赖异常中的合理子集
- 至少覆盖一类数据库异常、Redis 异常、超时、限流触发或重复提交边界
- 后端应提供覆盖率命令，例如 `pytest --cov=app --cov-report=term-missing`
- 前端必须确保 `build`、`lint` 与 `test` 能通过
- 前端项目默认位于 `generated/<project-slug>/frontend/`
- 默认引入 Vitest/Testing Library 或等价测试框架，补充至少一个关键页面 smoke、表单校验、错误态/空态或未登录引导测试
- 前端测试至少覆盖一个真实 API hook/mutation 驱动的页面状态或提交路径，禁止用 `setTimeout`、静态 toast 或硬编码数据作为成功证据
- 必须同步维护项目级关键业务动作回归清单、前端 UI 清单和生产就绪清单
- 必须补 `scripts/check_business_flow.sh`；脚本应自包含、可重复执行、无需人工 token，覆盖关键角色差异和主状态流转
