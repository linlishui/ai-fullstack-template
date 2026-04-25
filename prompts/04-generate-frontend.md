# 提示词：生成前端

请基于现有 OpenSpec 规格生成前端实现。

要求：

- 输出到 `generated/<project-slug>/frontend/`
- 使用 React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 不要把所有前端代码写进 `App.tsx`
- 按页面、组件、hooks、api、schema 或 feature 拆分
- 页面、表单、接口调用与权限控制要符合规格
- 保证构建脚本与 lint 脚本可用
