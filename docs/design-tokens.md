# Design Tokens

本文件提供默认主题 token 参考值。生成前端时以此为起点，按业务需求微调配色与风格。

## 1. 中性色（Neutral）

基于暖灰色阶，适用于文字、边框、背景分层：

| Token | 色值 | 用途 |
|-------|------|------|
| neutral-50 | #FAFAF9 | 页面背景 |
| neutral-100 | #F5F5F4 | 卡片背景、斑马行 |
| neutral-200 | #E7E5E4 | 分割线、边框 |
| neutral-300 | #D6D3D1 | 禁用边框 |
| neutral-400 | #A8A29E | 占位文字 |
| neutral-500 | #78716C | 次要文字 |
| neutral-600 | #57534E | 辅助文字 |
| neutral-700 | #44403C | 正文文字 |
| neutral-800 | #292524 | 标题文字 |
| neutral-900 | #1C1917 | 强调文字 |

## 2. 主色（Primary）

默认 Indigo，专业通用，项目可替换为品牌色：

| Token | 色值 | 用途 |
|-------|------|------|
| primary-50 | #EEF2FF | 选中行背景、轻标签 |
| primary-100 | #E0E7FF | hover 背景 |
| primary-500 | #6366F1 | 主按钮、链接、激活态 |
| primary-600 | #4F46E5 | 主按钮 hover |
| primary-700 | #4338CA | 主按钮 active |

## 3. 语义色（Semantic）

| 语义 | Base | Light | Dark | 用途 |
|------|------|-------|------|------|
| success | #10B981 | #D1FAE5 | #065F46 | 成功状态、完成标签 |
| warning | #F59E0B | #FEF3C7 | #92400E | 警告提示、待处理标签 |
| danger | #EF4444 | #FEE2E2 | #991B1B | 错误提示、危险按钮、删除 |
| info | #0EA5E9 | #E0F2FE | #075985 | 信息提示、引导说明 |

## 4. 字体（Typography）

优先系统字体栈，无外部依赖：

```
--font-sans: "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", "PingFang SC", "Noto Sans SC", sans-serif;
--font-mono: "JetBrains Mono", ui-monospace, "SF Mono", "Cascadia Code", monospace;
```

字号与行高：

| Token | 大小 | 行高 | 用途 |
|-------|------|------|------|
| text-xs | 12px | 16px | 标签、辅助说明 |
| text-sm | 14px | 20px | 次要正文、表格内容 |
| text-base | 16px | 24px | 正文默认 |
| text-lg | 18px | 28px | 小标题、卡片标题 |
| text-xl | 20px | 28px | 区块标题 |
| text-2xl | 24px | 32px | 页面标题 |
| text-3xl | 30px | 36px | 大标题、数据指标 |
| text-4xl | 36px | 40px | 仅用于极少数强调场景 |

字重：`normal(400)` 正文、`medium(500)` 强调、`semibold(600)` 标题、`bold(700)` 极少使用。

## 5. 间距（Spacing）

基础单元 4px，常用档位：

| Token | 值 | 典型用途 |
|-------|-----|---------|
| 0.5 | 2px | 图标与文字间距 |
| 1 | 4px | 紧凑元素内间距 |
| 2 | 8px | 表单字段间距、按钮内间距 |
| 3 | 12px | 卡片内间距（紧凑） |
| 4 | 16px | 卡片内间距（标准） |
| 5 | 20px | 区块间距 |
| 6 | 24px | 页面区块间距 |
| 8 | 32px | 大区块间距 |
| 10 | 40px | 页面上下留白 |
| 12 | 48px | 主要区域分隔 |
| 16 | 64px | 页面级分隔 |

## 6. 圆角（Border Radius）

| Token | 值 | 用途 |
|-------|-----|------|
| rounded-sm | 4px | Badge、小标签 |
| rounded-md | 6px | 按钮、输入框 |
| rounded-lg | 8px | 卡片、下拉菜单 |
| rounded-xl | 12px | 对话框、大卡片 |
| rounded-full | 9999px | 头像、圆形按钮 |

## 7. 阴影（Box Shadow）

| Token | 值 | 用途 |
|-------|-----|------|
| shadow-sm | 0 1px 2px rgba(0,0,0,0.05) | 输入框、小按钮 |
| shadow-md | 0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.06) | 卡片、浮层 |
| shadow-lg | 0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05) | 对话框、下拉菜单 |

## 8. 断点（Breakpoints）

| Token | 值 | 用途 |
|-------|-----|------|
| sm | 640px | 大屏手机 |
| md | 768px | 平板竖屏 |
| lg | 1024px | 平板横屏 / 小笔记本 |
| xl | 1280px | 桌面端 |

## 9. 动效时序（Transition）

| Token | 值 | 曲线 | 用途 |
|-------|-----|------|------|
| duration-fast | 150ms | ease-out | hover 颜色变化、图标旋转 |
| duration-normal | 250ms | ease-out | 展开收起、弹窗出现 |
| duration-slow | 350ms | ease-in-out | 页面过渡、大面积布局变化 |

统一使用 `transition` 属性声明，避免 `animation` 与 `transition` 混用导致不一致。
