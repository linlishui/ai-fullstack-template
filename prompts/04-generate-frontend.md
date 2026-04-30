# 提示词：生成前端

请基于现有 OpenSpec 规格生成前端实现。

在动手前，先读取并遵循以下模板文档：

- `docs/frontend-ui-spec.md`
- `docs/concurrent-generation.md`（当本阶段作为并发分片执行时）

其中：

- `docs/frontend-ui-spec.md` 是前端生成的统一规则入口与单一事实来源
- 其余前端文档仅作为展开说明与验收参考，按 `docs/frontend-ui-spec.md` 中的引用关系按需读取，不要再把它们视为并列规则源

要求：

- 输出到 `generated/<project-slug>/frontend/`
- 如果作为并发分片执行，默认只写 `generated/<project-slug>/frontend/` 和 `doc/frontend-ui-checklist.md` 中分配给前端的证据项；不得改后端、compose、CI 或共享文档，除非 `doc/parallel-execution-plan.md` 已明确授权
- 使用 React、TypeScript、Vite、Tailwind CSS、shadcn/ui、TanStack Query、React Hook Form、Zod
- 默认接入 Vitest + Testing Library 或等价测试方案
- 不要把所有前端代码写进 `App.tsx`
- 按页面、组件、hooks、api、schema 或 feature 拆分
- 页面、表单、接口调用与权限控制要符合规格
- 核心页面和核心按钮必须调用真实 API、TanStack Query mutation 或 typed domain hook；禁止用 `setTimeout`、静态 toast、硬编码成功结果、硬编码统计值或硬编码分类伪装业务完成
- 市场列表、详情、工作台、管理审核、安装/发布/评价等关键页面必须具备真实 fetch/mutation、加载态、错误态、空态和成功反馈；如果后端 API 尚未实现，必须显示“能力暂不可用”并在 OpenSpec/tasks 中标为 Open，不得前端假成功
- 若需求包含注册/登录，必须提供注册入口、登录入口、AuthContext 或等价会话状态、退出登录、401/refresh 处理策略；不得只把 access token 存在模块变量中且无会话恢复说明
- 前端视觉、交互、状态、响应式、组件模式、反模式与验收要求，以 `docs/frontend-ui-spec.md` 为准
- 必须提供统一 HTTP 客户端与错误处理，禁止在业务页面裸写 `fetch`
- 必须至少提供一处 ErrorBoundary，以及关键路由的 `React.lazy + Suspense` 懒加载
- 未登录、无权限或缺少前置条件的交互不得静默失败；点击后必须提示原因，并给出登录、跳转或下一步引导
- 不得默认把长期 token 存入 localStorage；如使用 bearer token，应限制有效期并在 `doc/security-notes.md` 中说明 XSS 风险和替代方案
- 主题 token 或 CSS 变量必须先定义再使用，默认参考 `docs/design-tokens.md`
- 推荐使用成熟组件库（如 shadcn/ui）初始化基础组件，避免手写 Button、Input、Dialog 等基础 UI 组件
- 推荐安装图标库（如 Lucide React），页面操作按钮和状态标识应带语义图标
- 在 `generated/<project-slug>/doc/frontend-ui-checklist.md` 输出项目级前端实现清单，至少记录主题方向、页面映射、关键状态设计与剩余风险
- 保证构建脚本与 lint 脚本可用
- 必须提供 `npm test -- --run` 或等价前端测试命令，至少覆盖一个关键页面 smoke、表单校验、空态/错误态或未登录引导
- 必须生成标准 `index.html`，包含 `<!doctype html>`、`<html lang>`、`charset`、`viewport` 和业务标题
- 必须提交前端 lockfile，例如 `package-lock.json`、`pnpm-lock.yaml` 或 `yarn.lock`
- 列表页搜索、分类筛选、排序和分页控件必须绑定受控 state 并注入 `useQuery` 参数；不得渲染无 `onChange` 的装饰性 `<input>` 或 `<select>`
- 前端测试依赖必须安装到 `devDependencies`：至少包含 `vitest`、`@testing-library/react`、`@testing-library/jest-dom`、`jsdom`；禁止只声明测试脚本但不安装测试库
- 破坏性操作（删除、下架、拒绝等）必须通过 AlertDialog 或等价确认弹窗拦截；如安装了 `@radix-ui/react-alert-dialog`，至少要在一处业务页面中使用
