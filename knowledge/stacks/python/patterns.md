# Python Patterns Knowledge Base

## Propósito
Conocimiento experto de Python que se inyecta en agents durante /genesis.
Se usa cuando el proyecto incluye Python en su stack.

---

## Principios Pythonicos

### The Zen of Python (relevantes)
```python
# Explícito es mejor que implícito
# Simple es mejor que complejo
# Legibilidad cuenta
# Los errores nunca deben pasar silenciosamente
# Si la implementación es difícil de explicar, es mala idea
```

### Type hints (Python 3.9+)
```python
# BIEN: Tipos explícitos en funciones públicas
def calculate_total(items: list[Item], discount: float = 0.0) -> Decimal:
    """Calcula el total con descuento opcional."""
    subtotal = sum(item.price for item in items)
    return subtotal * Decimal(1 - discount)

# BIEN: Optional para valores que pueden ser None
def find_user(user_id: str) -> User | None:
    return db.users.get(user_id)

# BIEN: TypedDict para diccionarios estructurados
from typing import TypedDict

class UserData(TypedDict):
    id: str
    name: str
    email: str
    active: bool
```

---

## Async/Await Patterns

### Siempre manejar errores
```python
# MAL: Sin manejo de errores
async def fetch_data():
    data = await client.get("/api")  # Si falla, excepción no manejada
    return data

# BIEN: Con manejo estructurado
async def fetch_data() -> dict | None:
    try:
        response = await client.get("/api")
        response.raise_for_status()
        return response.json()
    except httpx.HTTPStatusError as e:
        logger.error("HTTP error", status=e.response.status_code)
        raise AppError("FETCH_FAILED", str(e))
    except httpx.RequestError as e:
        logger.error("Request failed", error=str(e))
        raise AppError("CONNECTION_ERROR", str(e))
```

### Concurrencia con asyncio
```python
import asyncio

# Sequential (lento)
user = await get_user(id)
orders = await get_orders(id)
reviews = await get_reviews(id)
# Tiempo: t1 + t2 + t3

# Parallel (rápido)
user, orders, reviews = await asyncio.gather(
    get_user(id),
    get_orders(id),
    get_reviews(id)
)
# Tiempo: max(t1, t2, t3)

# Con manejo de errores individuales
results = await asyncio.gather(
    fetch_optional_data1(),
    fetch_optional_data2(),
    return_exceptions=True
)
for result in results:
    if isinstance(result, Exception):
        logger.warning(f"Task failed: {result}")
```

### Semaphore para rate limiting
```python
import asyncio

# Máximo 5 requests concurrentes
semaphore = asyncio.Semaphore(5)

async def fetch_with_limit(url: str) -> dict:
    async with semaphore:
        return await fetch(url)

# Procesar múltiples URLs
results = await asyncio.gather(*[
    fetch_with_limit(url) for url in urls
])
```

---

## Context Managers

### Para recursos que necesitan cleanup
```python
# MAL: Sin cleanup garantizado
file = open("data.txt")
data = file.read()
file.close()  # No se ejecuta si hay excepción

# BIEN: Context manager garantiza cleanup
with open("data.txt") as file:
    data = file.read()

# BIEN: Múltiples recursos
with open("input.txt") as src, open("output.txt", "w") as dst:
    dst.write(src.read().upper())
```

### Custom context manager
```python
from contextlib import contextmanager
from typing import Generator

@contextmanager
def database_transaction() -> Generator[Connection, None, None]:
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

# Uso
with database_transaction() as conn:
    conn.execute("INSERT INTO users ...")
```

### Async context manager
```python
from contextlib import asynccontextmanager
from typing import AsyncGenerator

@asynccontextmanager
async def get_db_session() -> AsyncGenerator[Session, None]:
    session = Session()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()

# Uso
async with get_db_session() as session:
    await session.execute(query)
```

---

## Error Handling

### Custom exceptions
```python
class AppError(Exception):
    """Base exception para errores de aplicación."""

    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = 500,
        details: dict | None = None
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)


class NotFoundError(AppError):
    def __init__(self, resource: str, resource_id: str):
        super().__init__(
            code="NOT_FOUND",
            message=f"{resource} with id '{resource_id}' not found",
            status_code=404,
            details={"resource": resource, "id": resource_id}
        )


class ValidationError(AppError):
    def __init__(self, errors: list[dict]):
        super().__init__(
            code="VALIDATION_ERROR",
            message="Request validation failed",
            status_code=400,
            details={"errors": errors}
        )
```

### Exception handler (FastAPI)
```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    logger.error(
        "Application error",
        code=exc.code,
        message=exc.message,
        path=request.url.path
    )
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
                **exc.details
            }
        }
    )

@app.exception_handler(Exception)
async def unhandled_error_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled error", path=request.url.path)
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred"
            }
        }
    )
```

---

## Data Classes & Pydantic

### Dataclasses para estructuras internas
```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    id: str
    email: str
    name: str
    created_at: datetime = field(default_factory=datetime.utcnow)
    active: bool = True

    def __post_init__(self):
        # Validación básica
        if not self.email or "@" not in self.email:
            raise ValueError("Invalid email")


@dataclass(frozen=True)  # Inmutable
class Coordinate:
    lat: float
    lon: float
```

### Pydantic para validación de entrada
```python
from pydantic import BaseModel, EmailStr, Field, field_validator

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=8)

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Name cannot be blank")
        return v.strip()


class UserResponse(BaseModel):
    id: str
    email: str
    name: str

    model_config = {"from_attributes": True}
```

### Settings con Pydantic
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "MyApp"
    debug: bool = False

    # Database
    database_url: str
    db_pool_size: int = 20

    # JWT
    jwt_secret: str
    jwt_expires_minutes: int = 15

    # Redis
    redis_url: str = "redis://localhost:6379"

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8"
    }


settings = Settings()  # Carga automáticamente de env vars
```

---

## FastAPI Patterns

### Router organization
```python
# routes/users.py
from fastapi import APIRouter, Depends, HTTPException

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    service: UserService = Depends(get_user_service)
) -> UserResponse:
    user = await service.find_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# main.py
from fastapi import FastAPI
from routes import users, orders

app = FastAPI()
app.include_router(users.router)
app.include_router(orders.router)
```

### Dependency injection
```python
from fastapi import Depends
from typing import Annotated

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    payload = verify_token(token)
    user = await db.get(User, payload["sub"])
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# Type alias para reusar
CurrentUser = Annotated[User, Depends(get_current_user)]
DB = Annotated[AsyncSession, Depends(get_db)]

@router.get("/me")
async def get_me(user: CurrentUser) -> UserResponse:
    return user
```

### Middleware
```python
import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class RequestIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("x-request-id", str(uuid4()))
        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["x-request-id"] = request_id
        return response


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - start

        logger.info(
            "Request completed",
            method=request.method,
            path=request.url.path,
            status=response.status_code,
            duration_ms=round(duration * 1000, 2)
        )
        return response


app.add_middleware(RequestIdMiddleware)
app.add_middleware(LoggingMiddleware)
```

---

## Database Patterns

### SQLAlchemy async
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

engine = create_async_engine(
    settings.database_url,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True
)

async_session = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)
```

### Repository pattern
```python
from abc import ABC, abstractmethod

class UserRepository(ABC):
    @abstractmethod
    async def find_by_id(self, user_id: str) -> User | None: ...

    @abstractmethod
    async def find_by_email(self, email: str) -> User | None: ...

    @abstractmethod
    async def create(self, data: CreateUserRequest) -> User: ...


class SQLAlchemyUserRepository(UserRepository):
    def __init__(self, session: AsyncSession):
        self.session = session

    async def find_by_id(self, user_id: str) -> User | None:
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        row = result.scalar_one_or_none()
        return User.from_orm(row) if row else None

    async def create(self, data: CreateUserRequest) -> User:
        user = UserModel(
            email=data.email,
            name=data.name,
            password_hash=hash_password(data.password)
        )
        self.session.add(user)
        await self.session.flush()
        return User.from_orm(user)
```

### Transaction management
```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def transaction():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

# Uso
async with transaction() as session:
    repo = SQLAlchemyUserRepository(session)
    user = await repo.create(user_data)
    await repo.update_stats(user.id)
```

---

## Testing Patterns

### Pytest fixtures
```python
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest.fixture
def sample_user() -> User:
    return User(
        id="test-123",
        email="test@test.com",
        name="Test User"
    )
```

### Unit test structure
```python
class TestUserService:
    @pytest.fixture
    def mock_repo(self, mocker):
        return mocker.Mock(spec=UserRepository)

    @pytest.fixture
    def service(self, mock_repo):
        return UserService(mock_repo)

    async def test_create_user_hashes_password(
        self,
        service: UserService,
        mock_repo
    ):
        # Arrange
        request = CreateUserRequest(
            email="test@test.com",
            name="Test",
            password="password123"
        )
        mock_repo.create.return_value = User(id="1", **request.dict())

        # Act
        user = await service.create(request)

        # Assert
        mock_repo.create.assert_called_once()
        call_args = mock_repo.create.call_args[0][0]
        assert call_args.password != request.password  # Was hashed
```

### Integration tests
```python
@pytest.mark.asyncio
async def test_create_user_endpoint(client: AsyncClient, db_session):
    # Act
    response = await client.post(
        "/api/users",
        json={
            "email": "new@test.com",
            "name": "New User",
            "password": "password123"
        }
    )

    # Assert
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "new@test.com"
    assert "password" not in data


@pytest.mark.asyncio
async def test_create_user_invalid_email(client: AsyncClient):
    response = await client.post(
        "/api/users",
        json={"email": "not-an-email", "name": "Test", "password": "pass123"}
    )

    assert response.status_code == 422
```

---

## Logging

### Structured logging with structlog
```python
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Uso
logger.info("User created", user_id=user.id, email=user.email)
logger.error("Failed to process", error=str(e), request_id=request_id)
```

---

## Checklist Python

### Por módulo
- [ ] Type hints en funciones públicas
- [ ] Docstrings en clases y funciones públicas
- [ ] Errores manejados con excepciones tipadas
- [ ] Context managers para recursos

### Por endpoint
- [ ] Input validado con Pydantic
- [ ] Errores retornan JSON estructurado
- [ ] Logging de request/response
- [ ] Response model definido

### Testing
- [ ] Unit tests para lógica de negocio
- [ ] Integration tests para endpoints
- [ ] Fixtures reutilizables
- [ ] Mocks para dependencias externas

### Operacional
- [ ] Settings validadas al iniciar
- [ ] Health check endpoint
- [ ] Logs estructurados (JSON)
- [ ] Graceful shutdown
