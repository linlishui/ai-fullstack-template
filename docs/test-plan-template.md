# Test Plan Template

本模板用于生成项目级测试计划，输出到：

`generated/<project-slug>/docs/test-plan.md`

## 使用规则

测试计划必须映射真实需求和关键风险，不得只列命令。

至少覆盖：

- 后端不少于 8 个关键用例，覆盖成功、认证失败、越权、非法输入、重复/冲突、状态非法流转、依赖异常或超时中的合理子集。
- 前端至少包含 smoke/component 测试或页面级可用性验证脚本。
- 主业务流脚本必须自包含、可重复执行、无需人工 token。
- 覆盖率命令与目标线，默认后端覆盖率目标不低于 70%。
- 每个未自动化的检查项必须标明人工验证方式和风险。

## 推荐模板

```md
# Test Plan

## Backend Tests

- Success path:
- Auth failure:
- Authorization failure:
- Validation failure:
- Conflict:
- Illegal state transition:
- Dependency failure:
- Health / readiness:
- Coverage command:

## Frontend Tests

- Smoke:
- Component:
- ErrorBoundary:
- Loading / empty / error states:
- Mobile layout:

## Business Flow

- Script:
- Roles:
- State transitions:
- Repeatability:

## Manual Checks

- Item:
- Why not automated:
- Risk:
```
