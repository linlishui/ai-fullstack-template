# Frontend UI Checklist Template

本模板用于约束生成项目在交付前完成前端 UI 自查，并将结果输出到：

`generated/<project-slug>/docs/frontend-ui-checklist.md`

## 使用规则

### 1. 清单必须结合真实页面

- 不允许只写抽象结论
- 必须映射当前需求中的关键页面、关键操作与关键状态

### 2. 清单必须包含高风险前端项

至少覆盖：

- 主题 token 是否落地
- 统一 HTTP 错误处理是否落地
- 是否存在 ErrorBoundary
- 关键路由是否懒加载
- 加载态、空态、错误态、提交中态、成功反馈是否齐全
- 未登录、无权限、缺少前置条件时是否有明确提示
- 按钮换行、控件变形、长文本溢出、移动端布局风险

## 推荐模板

```md
# Frontend UI Checklist

## Theme Direction

- Primary tone:
- Supporting colors:
- Token status:

## Page Mapping

- Page:
  - Goal:
  - Main action:
  - Key states:

## Critical Checks

- ErrorBoundary:
- Lazy routes:
- Unified HTTP handling:
- Toast / Dialog / Skeleton:
- Unauthorized feedback:
- Mobile layout:

## Risks

- Open issues:
- Manual verification needed:
```
