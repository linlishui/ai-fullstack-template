# Security Notes Template

本模板用于生成项目级安全说明，输出到：

`generated/<project-slug>/docs/security-notes.md`

## 使用规则

安全说明必须记录真实实现和剩余风险，不得只写“已考虑安全”。

至少覆盖：

- 管理员初始化方式：必须是 seed、bootstrap token 或显式环境变量，不得依赖 email 前缀、用户名约定或前端隐藏按钮。
- JWT secret：`.env.example` 必须使用 32 字节以上示例值，并说明生产替换要求。
- Refresh Token：若使用 Cookie，说明 `HttpOnly`、`Secure`、`SameSite`、CSRF/Origin 校验；若不使用 refresh token，说明 access token 有效期和取舍。
- Token 存储：说明前端 token 存储位置；如果使用 `localStorage`，必须记录 XSS 风险、适用范围和替代方案。
- Rate limiting：说明登录、注册、刷新 token、写操作的 Redis-backed 限流策略。
- 授权边界：说明资源级授权规则和拒绝访问行为。
- 输入校验：说明后端 schema、前端表单 schema 和错误返回格式。
- 敏感信息：说明环境变量、日志脱敏和禁止提交 `.env`。

## 推荐模板

```md
# Security Notes

## Admin Bootstrap

- Mechanism:
- Required env:
- Forbidden shortcut checked:

## Token And Session

- Access token lifetime:
- Refresh token:
- Cookie settings:
- CSRF / Origin validation:
- Frontend storage:
- Known risks:

## Authorization

- Role model:
- Resource-level checks:
- Unauthorized response:

## Rate Limiting

- Backend:
- Redis key strategy:
- Protected endpoints:

## Input And Error Handling

- Backend validation:
- Frontend validation:
- Conflict handling:
- Internal error handling:

## Secrets And Logs

- Required secrets:
- Log redaction:
- Local files ignored:
```
