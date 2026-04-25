# OpenSpec Project Definition

## 项目定位

本项目是一个“需求文档驱动的 AI 全栈自动实现模板仓库”。它的目标是让 AI 在读取业务需求文档后，先产出结构化规格，再自动生成可运行、可测试、可部署的全栈工程。

## 工程原则

- 规格优先：所有实现必须先基于 OpenSpec 规格产出
- 模块化优先：后端、前端、测试、部署均需结构化拆分
- 配置外置：所有配置、密钥、连接信息统一使用环境变量
- 自动验证：生成完成后必须具备基础验证命令与自动修复流程
- 可增量演进：后续新增需求应尽量通过更新规格与模块扩展完成

## 默认技术栈

### 后端

- Python 3.12+
- FastAPI
- Pydantic v2
- SQLAlchemy 2.x async
- Alembic
- MySQL 8
- Redis 7
- JWT 认证
- pytest
- ruff

### 前端

- React
- TypeScript
- Vite
- Tailwind CSS
- shadcn/ui
- TanStack Query
- React Hook Form
- Zod

### 部署

- Docker Compose
- 服务默认包含 `frontend`、`backend`、`mysql`、`redis`

## 架构约束

- 不允许跳过 `requirements/requirement.md -> OpenSpec -> implementation` 这条链路
- 生成代码统一输出到 `generated/<project-slug>/`
- 项目级输出至少包含 `README.md`、`.env.example`、`compose.yaml`、`backend/`、`frontend/`
- 后端不得将所有逻辑集中在单文件
- 前端不得将所有逻辑集中在单组件
- 必须生成数据库模型、迁移、配置管理、测试与构建脚本
- Docker 化部署必须使用环境变量驱动配置
- 所有业务实现都应可被后续 AI 继续理解和扩展
