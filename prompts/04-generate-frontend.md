# 提示词：生成前端

请基于现有 OpenSpec 规格生成前端实现。

在动手前，先读取并遵循以下模板文档：

- `docs/frontend-ui-spec.md`

其中：

- `docs/frontend-ui-spec.md` 是前端生成的统一规则入口与单一事实来源
- 其余前端文档仅作为展开说明与验收参考，按 `docs/frontend-ui-spec.md` 中的引用关系按需读取，不要再把它们视为并列规则源

要求：

- 输出到 `generated/<project-slug>/frontend/`
- 使用 React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 不要把所有前端代码写进 `App.tsx`
- 按页面、组件、hooks、api、schema 或 feature 拆分
- 页面、表单、接口调用与权限控制要符合规格
- 前端视觉、交互、状态、响应式、组件模式、反模式与验收要求，以 `docs/frontend-ui-spec.md` 为准
- 必须提供统一 HTTP 客户端与错误处理，禁止在业务页面裸写 `fetch`
- 必须至少提供一处 ErrorBoundary，以及关键路由的 `React.lazy + Suspense` 懒加载
- 未登录、无权限或缺少前置条件的交互不得静默失败；点击后必须提示原因，并给出登录、跳转或下一步引导
- 主题 token 或 CSS 变量必须先定义再使用，默认参考 `docs/design-tokens.md`
- 推荐使用成熟组件库（如 shadcn/ui）初始化基础组件，避免手写 Button、Input、Dialog 等基础 UI 组件
- 推荐安装图标库（如 Lucide React），页面操作按钮和状态标识应带语义图标
- 在 `generated/<project-slug>/docs/frontend-ui-checklist.md` 输出项目级前端实现清单，至少记录主题方向、页面映射、关键状态设计与剩余风险
- 保证构建脚本与 lint 脚本可用
