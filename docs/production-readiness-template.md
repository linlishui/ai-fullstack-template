# Production Readiness Checklist Template

本模板用于把生成项目的生产级高风险项显式记录到：

`generated/<project-slug>/docs/production-readiness-checklist.md`

## 使用规则

### 1. 重点记录“容易失分但不应被遗漏”的能力

必须覆盖：

- Logging / Metrics / Tracing
- 统一响应结构与全局异常处理
- API 版本化与分页
- CORS、安全头、JWT/Refresh Token、Cookie、CSRF
- 审计日志与资源级授权
- 健康检查、Nginx、CI 工作流、Docker 多阶段构建
- 资源限制、验证命令与业务流脚本
- Redis-backed rate limiting
- Request ID / Correlation ID
- OpenAPI 导出
- 生产 Dockerfile 非 editable install
- backend/frontend `.dockerignore`

### 2. 每项都要标状态

推荐使用：

- `passed`
- `partial`
- `missing`
- `manual-check`

### 3. 不要只写“已实现”

每项至少写清：

- 实现位置
- 当前状态
- 剩余风险或待确认项

## 推荐模板

```md
# Production Readiness Checklist

## Observability

- Logging:
- Metrics:
- Tracing:

## API And Runtime

- Versioned routes:
- Response envelope:
- Global exception handling:
- Pagination:
- Health checks:

## Security

- CORS allowlist:
- Security headers:
- JWT / Refresh Token:
- Cookie settings:
- CSRF protection:
- Audit logs:

## Deployment

- Docker multi-stage:
- Nginx:
- CI workflow:
- Resource limits:

## Verification

- Compose config:
- Pytest:
- Backend coverage:
- Ruff:
- Frontend build:
- Frontend lint:
- Frontend tests:
- OpenAPI export:
- Business flow script:
- Template audit:

## Open Risks

- Item:
- Action needed:
```
