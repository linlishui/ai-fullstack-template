# 提示词：安全审查

请对当前生成项目执行安全审查，重点检查：

- 先读取 `docs/production-grade-rubric.md`，按生产级硬门禁逐项审查
- 是否存在硬编码密码、Redis 地址、JWT secret
- 环境变量是否完整
- JWT、认证、授权实现是否存在明显缺陷
- Refresh Token、Cookie、CSRF、防暴力破解与资源级授权是否存在明显缺陷
- 是否存在 email 前缀、固定用户名、前端隐藏入口等隐式管理员提权
- 是否存在长期 token localStorage 存储且无风险说明
- 是否真实实现 Redis-backed rate limiting，而不是只预留 Redis 连接
- 输入校验是否缺失
- 错误处理是否泄漏敏感信息
- Docker、Nginx、Compose 与 CI 配置是否暴露不必要风险
- 依赖安全审计是否执行并记录，npm/pip 中高危漏洞是否阻断

输出要求：

- 高风险问题
- 中风险问题
- 低风险问题
- 建议修复项
- 每个高风险问题必须给出文件路径、利用场景、修复方案和验证命令
