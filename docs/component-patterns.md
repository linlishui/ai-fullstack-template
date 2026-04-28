# Component Patterns

本文件补充 `docs/frontend-ui-spec.md`，只负责“组件与交互模式”。总入口中的硬规则依然有效；本文件不重复总规范、反模式和审查清单。

## 1. 组件库选型

推荐方案（按优先级）：

1. **shadcn/ui** — 基于 Radix UI + Tailwind，与模板技术栈高度契合
2. **Radix UI + 自定义样式** — 更灵活，需自行处理样式
3. **Headless UI** — 轻量，适合简单项目

选择任何方案后，至少需要覆盖以下基础组件：Button、Input、Label、Textarea、Select、Dialog、DropdownMenu、Table、Card、Badge、Tabs、Skeleton、Toast、Tooltip、Separator。

禁止在项目中手写以上已有基础组件的简化版本。

## 2. 图标

推荐方案：

1. **Lucide React** — 与 shadcn/ui 生态一致，图标丰富
2. **Heroicons** — Tailwind 官方推荐
3. **Phosphor Icons** — 多风格支持

必须满足：
- 操作按钮带语义图标（如 Plus、Trash、Edit、Search、Filter、ChevronDown）
- 状态标识带图标（如 CheckCircle、AlertTriangle、XCircle、Info）
- 导航菜单项带图标
- 空态页面带大尺寸装饰图标

## 3. 骨架屏加载（Skeleton）

列表页、详情页、Dashboard 在数据加载时必须展示骨架屏占位，禁止只显示纯文字 "Loading..." 或空白。

推荐实现：

```tsx
// 列表骨架屏示例
function SkillCardSkeleton() {
  return (
    <div className="rounded-lg border p-5 animate-pulse">
      <div className="mb-3 flex items-center justify-between">
        <div className="h-5 w-20 rounded bg-neutral-200" />
        <div className="h-4 w-12 rounded bg-neutral-200" />
      </div>
      <div className="h-6 w-3/4 rounded bg-neutral-200" />
      <div className="mt-2 space-y-2">
        <div className="h-4 w-full rounded bg-neutral-100" />
        <div className="h-4 w-2/3 rounded bg-neutral-100" />
      </div>
    </div>
  );
}

// 在列表页中使用
{isLoading ? (
  <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
    {Array.from({ length: 6 }).map((_, i) => <SkillCardSkeleton key={i} />)}
  </div>
) : data?.length ? (
  <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
    {data.map(item => <SkillCard key={item.id} skill={item} />)}
  </div>
) : (
  <EmptyState />
)}
```

验收标准：骨架屏形状应与实际内容布局一致，使用 `animate-pulse` 或等效动画。

## 4. 空态（Empty State）

数据为空时必须展示结构化空态组件，禁止只显示 "No data" 或 "暂无数据"。

推荐实现：

```tsx
import { PackageOpen } from "lucide-react"; // 或同类图标

function EmptyState({
  icon: Icon = PackageOpen,
  title = "暂无数据",
  description = "当前列表为空",
  action,
}: {
  icon?: React.ElementType;
  title?: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <Icon className="h-12 w-12 text-neutral-300" />
      <h3 className="mt-4 text-lg font-semibold text-neutral-800">{title}</h3>
      <p className="mt-1 text-sm text-neutral-500">{description}</p>
      {action && <div className="mt-6">{action}</div>}
    </div>
  );
}

// 使用示例
<EmptyState
  title="还没有技能"
  description="发布你的第一个技能，开始在市场中展示"
  action={<Button><Plus className="mr-2 h-4 w-4" />发布技能</Button>}
/>
```

验收标准：空态必须包含图标、标题、说明文字，关键列表还应提供引导操作按钮。

## 5. 操作反馈（Toast）

增删改操作完成后必须通过 Toast 给出即时反馈，禁止静默成功或仅 `console.log`。

推荐方案：`sonner`（轻量）或 shadcn/ui 内置 Toast。

必须覆盖的场景：
- 创建成功 → success toast
- 更新成功 → success toast
- 删除成功 → success toast
- 操作失败 → error toast，含简要错误描述
- 网络异常 → error toast，含重试引导

推荐实现：

```tsx
import { toast } from "sonner"; // 或等效方案

async function handleDelete(id: string) {
  try {
    await api.deleteSkill(id);
    toast.success("技能已删除");
  } catch (error) {
    toast.error("删除失败，请稍后重试");
  }
}
```

验收标准：每个写操作（POST/PUT/PATCH/DELETE）对应的 UI 触发点都应有 toast 反馈。

## 6. 危险操作确认（Confirm Dialog）

破坏性操作（删除、下线、重置、批量清除等）必须弹窗确认，禁止直接执行。

推荐实现：

```tsx
<AlertDialog>
  <AlertDialogTrigger asChild>
    <Button variant="destructive" size="sm">
      <Trash className="mr-2 h-4 w-4" />删除
    </Button>
  </AlertDialogTrigger>
  <AlertDialogContent>
    <AlertDialogHeader>
      <AlertDialogTitle>确认删除？</AlertDialogTitle>
      <AlertDialogDescription>
        此操作不可撤销，该技能将从市场中永久移除。
      </AlertDialogDescription>
    </AlertDialogHeader>
    <AlertDialogFooter>
      <AlertDialogCancel>取消</AlertDialogCancel>
      <AlertDialogAction onClick={handleDelete}>确认删除</AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

验收标准：所有 DELETE 操作和状态不可逆变更必须有确认弹窗，弹窗需说明操作后果。

确认弹窗还必须满足基础可访问性要求：优先使用 Radix AlertDialog、shadcn/ui AlertDialog 或等价组件；必须有遮罩、焦点陷阱、ESC 关闭、语义化触发按钮和键盘可操作路径。禁止用 `span onClick`、无 role 的 div 或只靠视觉样式伪装弹窗。

## 7. 按钮变体（Button Variants）

至少提供以下 5 种按钮变体，保证操作层级清晰：

| 变体 | 用途 | 视觉特征 |
|------|------|----------|
| primary (default) | 主要操作（提交、创建、确认） | 实心主色背景，白色文字 |
| secondary | 次要操作（取消、返回、筛选） | 浅色背景或边框，深色文字 |
| outline | 辅助操作（导出、更多） | 透明背景 + 边框 |
| destructive | 危险操作（删除、下线） | 红色背景或红色文字 |
| ghost | 内联操作（编辑、查看详情） | 无背景无边框，hover 时显现 |

验收标准：同一页面中主按钮不超过 1 个，次要和辅助操作有明确层级区分。

## 8. 补充交互要求

- **表格行操作**：使用 DropdownMenu 收纳多个行级操作（编辑、删除、查看详情等），不要在每行排列多个并列按钮
- **表单提交中态**：按钮显示 loading spinner + 禁用，文字改为进行时态（如 "提交中..."）
- **页面过渡**：列表项和卡片使用 `transition` 实现 hover 效果（如轻微上浮、阴影加深）
- **响应式菜单**：移动端使用 Sheet（侧边抽屉）替代顶部水平导航

## 9. 受限操作提示

未登录、无权限或缺少前置条件时，点击操作不能静默失败，也不能只是“按钮点了没反应”。

推荐处理方式：

- 未登录：跳转登录页或弹出登录弹窗，并提示“登录后可继续此操作”
- 无权限：保留控件可见性，但通过 Tooltip、Inline Message 或 Toast 说明权限限制
- 缺少前置条件：明确提示缺什么，并提供下一步入口，例如“请先选择项目”“请先完成安装”
- 默认禁用的控件：附近需要有可见说明文字，不能只靠灰色态表达原因

推荐实现：

```tsx
import { toast } from "sonner";

function handleInstallClick() {
  if (!session) {
    toast.info("请先登录后再安装 Skill");
    navigate("/login", { state: { redirectTo: location.pathname } });
    return;
  }

  if (!selectedWorkspaceId) {
    toast.warning("请先选择工作区");
    return;
  }

  mutateInstall();
}
```

验收标准：用户点击受限操作后，必须在 1 次交互内知道“为什么不能做”和“下一步该做什么”。

与布局稳定性、按钮不换行、长文本截断、原生控件禁用等通用硬规则相关的内容，以 `docs/frontend-ui-spec.md` 和 `docs/frontend-anti-patterns.md` 为准。
