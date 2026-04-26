# Architecture Overview

本模板仓库采用“需求驱动 + 规格驱动 + 自动实现”的三层流程：

1. 需求层：业务方将需求写入 `requirements/requirement.md`
2. 规格层：AI 将需求转换为 OpenSpec 风格的项目规格与变更任务
3. 实现层：AI 按规格生成后端、前端、部署、测试与文档

## 目标架构

- 后端服务：基于 FastAPI 提供 REST API、认证、业务逻辑、数据访问
- 数据存储：MySQL 存储业务数据，Redis 支持缓存、会话或异步辅助能力
- 前端应用：React + TypeScript 提供页面、表单、状态管理与接口集成
- 容器部署：通过 Docker Compose 统一编排 frontend、backend、mysql、redis

## 架构约束

- 先规格，后实现
- 先模块化，后细节填充
- 所有配置由 `.env` 驱动
- 生成结果必须具备测试和构建验证能力

## 模板与实现分层

- 模板资产包括 `requirements/`、`prompts/`、`docs/`、`scripts/`
- 生成资产包括 `generated/<project-slug>/` 下的全部业务代码与部署文件
- OpenSpec 只在生成资产中的 `generated/<project-slug>/openspec/` 维护
- 模板资产应尽量稳定，生成资产允许多次重建或迁移
- 仓库内文档和提示词不应依赖当前机器绝对路径
