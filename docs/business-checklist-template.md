# Key Business Actions Checklist

本模板用于约束生成项目在交付前必须完成“需求驱动”的业务闭环检查。

它不是固定业务清单，也不预设认证、审批、支付或其他某类流程一定存在。
每次生成时，都应基于当前 `requirements/requirement.md` 提炼出最关键的业务动作，再填充到项目级文档中。

建议在生成项目后输出到：

`generated/<project-slug>/docs/key-business-actions-checklist.md`

## 使用规则

### 1. 先提炼动作，再做实现

必须先从当前需求中提炼 `3-5` 个最关键业务动作。

动作应满足：

- 直接对应需求目标
- 能代表主链路是否闭环
- 能暴露角色、状态、权限或关键视图问题

### 2. 不要预设固定业务样例

以下内容不能默认写死为必选项：

- 注册
- 登录
- 审批
- 支付
- 评论
- 安装

只有当它们属于当前需求的关键动作时，才进入清单。

### 3. 每个动作都要同时检查四件事

- 是否有前端入口
- 是否有后端支撑
- 是否有正确状态变化
- 是否有可见反馈或结果视图

### 4. 支撑能力只做最小验证

如果认证、字典、上传、通知等只是支撑能力，不是当前需求主目标，则只验证其是否足以支撑主链路，不要让它吞掉主要实现预算。

## 推荐模板

生成项目时，建议按下面结构输出：

```md
# Key Business Actions Checklist

## Requirement Summary

- 项目目标：
- 关键角色：
- 关键状态：

## Action 1: <名称>

- Why it matters:
- Actor:
- Entry:
- Backend support:
- Expected state transition:
- Expected visible result:
- Failure feedback:
- Verification status:
- Notes:

## Action 2: <名称>
```

## 示例检查项

以下是通用字段，不是固定业务动作：

- `Why it matters`：为什么它属于主链路
- `Actor`：由谁触发
- `Entry`：页面、按钮、接口或工作台入口在哪里
- `Backend support`：对应接口、服务或任务是否存在
- `Expected state transition`：动作前后状态如何变化
- `Expected visible result`：结果应该出现在哪个列表、详情或面板
- `Failure feedback`：失败时用户能否看到明确提示
- `Verification status`：`pending`、`passed`、`failed`
- `Notes`：剩余风险、依赖或人工确认项

## 通过标准

只有当以下条件都满足时，才能认为“关键业务动作已闭环”：

- 至少覆盖 `3` 个关键业务动作
- 每个动作都能定位到前端入口和后端支撑
- 每个动作都说明状态变化与结果视图
- 每个动作都记录失败反馈方式
- 至少标明哪些动作已验证通过，哪些仍有风险
