# 提示词：生成测试

请基于现有 OpenSpec 和代码实现补齐测试与校验配置。

开始前先读取：

- `docs/testing-spec.md`
- `docs/backend-spec.md`
- `docs/frontend-ui-spec.md`
- `docs/deployment-spec.md`
- `docs/production-grade-rubric.md`
- `docs/concurrent-generation.md`（当本阶段作为并发分片执行时）

要求：

- 后端补充 `pytest` 测试
- 如果作为并发分片执行，默认只写测试、业务流脚本、OpenAPI 验证脚本和测试/生产就绪清单中分配给验证的证据项；发现接口或数据模型不一致时记录冲突并交回主控集成
- 后端测试默认位于 `generated/<project-slug>/backend/`
- 覆盖关键接口、关键业务规则和关键异常场景
- 必须至少覆盖一条核心业务接口通过数据库-backed service/repository 写入后，再被查询或后续状态流转读取的路径；只测 `MemoryStore`、mock service 或路由存在性不算通过
- 后端测试不得少于 8 个关键用例；必须覆盖成功路径、认证失败、越权、非法输入、重复/冲突、非法状态流转、限流或依赖异常中的合理子集
- 至少覆盖一类数据库异常、Redis 异常、超时、限流触发或重复提交边界
- 后端应提供覆盖率命令，例如 `pytest --cov=app --cov-report=term-missing`
- 前端必须确保 `build`、`lint` 与 `test` 能通过
- 前端项目默认位于 `generated/<project-slug>/frontend/`
- 默认引入 Vitest/Testing Library 或等价测试框架，补充至少一个关键页面 smoke、表单校验、错误态/空态或未登录引导测试
- 前端测试至少覆盖一个真实 API hook/mutation 驱动的页面状态或提交路径，禁止用 `setTimeout`、静态 toast 或硬编码数据作为成功证据
- 必须同步维护项目级关键业务动作回归清单、前端 UI 清单和生产就绪清单
- 必须补 `scripts/check_business_flow.sh`；脚本应自包含、可重复执行、无需人工 token，覆盖关键角色差异和主状态流转

### 后端 conftest.py 硬性要求

- 后端测试目录必须包含 `tests/conftest.py`，至少提供以下 fixture：
  - `db_engine`：基于 `sqlite+aiosqlite:///:memory:` 的测试引擎，`create_all` 初始化表结构
  - `db_session`：绑定到测试引擎的 `AsyncSession`，每个测试结束后自动回滚或重建
  - `client`：通过 `httpx.AsyncClient` + `ASGITransport` 挂载 FastAPI app，并覆盖 `get_session` 依赖为测试 session
  - `auth_client` 或 `authenticated_client`：预注册测试用户并携带有效 JWT 的 client fixture
- `conftest.py` 必须导入 `app.main` 中的 app 实例和 `app.db` 中的 session 依赖与 Base 类
- 禁止在 conftest 中使用 `MemoryStore` 或模块级 dict 作为 session 替代

参考 conftest.py 最小模板：

```python
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.main import app
from app.db.session import get_session
from app.db.base import Base

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture
async def db_engine():
    engine = create_async_engine(TEST_DB_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest.fixture
async def db_session(db_engine):
    session_factory = async_sessionmaker(db_engine, expire_on_commit=False)
    async with session_factory() as session:
        yield session

@pytest.fixture
async def client(db_session):
    async def override():
        yield db_session
    app.dependency_overrides[get_session] = override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
```

### 假测试禁止

以下模式视为假测试，模板审计和验证脚本会自动拒绝：

- 测试文件中无任何 `from app.*` 或 `import app.*` 导入
- 测试只断言 Python 内置数据结构而不调用任何 service/repository/API
- 测试断言硬编码预期值等于自身（如 `assert [1,2,3] == [1,2,3]`）

每个测试函数必须至少包含一次对生产代码（routes/services/repositories）的调用或 HTTP 请求。

### 前端测试硬性要求

- 前端测试依赖必须安装到 `devDependencies`：至少包含 `vitest`、`@testing-library/react`、`@testing-library/jest-dom`、`jsdom`
- 至少有一个测试文件导入 `@testing-library/react` 的 `render` 或 `screen` 并渲染真实组件
- 测试组件必须包裹必要的 Provider（QueryClientProvider、AuthProvider 等）
- `package.json` 的 `test` 脚本必须调用 `vitest`（或 jest/mocha/cypress/playwright），禁止指向自定义静态检查脚本
- `build` 脚本必须调用真实构建工具（vite/tsc/next/webpack），禁止指向自定义静态检查脚本
- `lint` 脚本必须调用真实 lint 工具（eslint/biome/oxlint/tsc），禁止指向自定义静态检查脚本
