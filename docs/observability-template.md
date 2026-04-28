# Observability Template

本模板用于生成项目级可观测性说明，输出到：

`generated/<project-slug>/docs/observability.md`

## 使用规则

可观测性必须有代码或配置支撑，不能只写计划。

至少覆盖：

- Request ID / Correlation ID 中间件与响应头。
- 结构化访问日志与错误日志字段。
- `/metrics` Prometheus 指标端点。
- 健康检查：live、ready、数据库、Redis。
- Tracing extension point：若未接入真实 collector，必须说明开关、环境变量和接入位置。
- Nginx access/error log 与 proxy timeout。
- CI 或验证脚本中的可观测性检查。

## 推荐模板

```md
# Observability

## Request Context

- Header:
- Middleware:
- Log field:

## Logs

- Format:
- Access log fields:
- Error log fields:
- Sensitive fields redacted:

## Metrics

- Endpoint:
- Library:
- Key metrics:

## Health Checks

- Live:
- Ready:
- Database:
- Redis:

## Tracing

- Status:
- Config:
- Integration point:

## Operations

- Nginx logs:
- Proxy timeout:
- Verification command:
```
