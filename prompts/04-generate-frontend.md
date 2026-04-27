# 提示词：生成前端

请基于现有 OpenSpec 规格生成前端实现。

在动手前，先读取并遵循以下模板文档：

- `docs/frontend-style-guide.md`
- `docs/page-blueprints.md`
- `docs/frontend-review-checklist.md`

要求：

- 输出到 `generated/<project-slug>/frontend/`
- 使用 React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 不要把所有前端代码写进 `App.tsx`
- 按页面、组件、hooks、api、schema 或 feature 拆分
- 页面、表单、接口调用与权限控制要符合规格
- 先定义并统一使用主题 token 或 CSS 变量，不要到处硬编码颜色、阴影、圆角和间距
- 页面要有明确的信息层级、主次按钮层级和视觉焦点，不要退化成模板化的普通后台壳
- 必须补齐加载态、空态、错误态、禁用态、提交中态和成功反馈
- 列表页、详情页、表单页、工作台类页面应遵循页面蓝图，避免所有页面长得一样
- 保证桌面端和移动端都成立，不允许只做桌面排版
- 通用布局、状态组件、业务组件要分层复用，不要在单页内堆叠所有视觉和交互逻辑
- 在 `generated/<project-slug>/docs/frontend-ui-checklist.md` 输出项目级前端实现清单，至少记录主题方向、页面映射、关键状态设计与剩余风险
- 保证构建脚本与 lint 脚本可用
