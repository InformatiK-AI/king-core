# Auth Patterns — Python

> Patrones de implementación de autenticación para proyectos Python.
> Conceptos base y reglas absolutas: ver `../../_inject/auth-essentials.md`

---

## OAuth2 + PKCE

```python
import secrets
import hashlib
import base64
from urllib.parse import urlencode

# CORRECTO: secrets.token_urlsafe usa CSPRNG — NUNCA random.random()
def generate_code_verifier() -> str:
    """Genera code_verifier: 32 bytes CSPRNG → base64url (43 chars)."""
    return secrets.token_urlsafe(32)

def generate_code_challenge(verifier: str) -> str:
    """SHA256 del verifier → base64url sin padding (method=S256)."""
    digest = hashlib.sha256(verifier.encode()).digest()
    return base64.urlsafe_b64encode(digest).rstrip(b"=").decode()

def initiate_oauth(provider: str, session: dict) -> str:
    """BFF pattern: servidor genera verifier, devuelve authorization_url."""
    state = secrets.token_hex(16)           # CSRF protection
    verifier = generate_code_verifier()
    challenge = generate_code_challenge(verifier)

    # Almacenar en session server-side — destruir post-exchange
    session["oauth"] = {"state": state, "verifier": verifier, "provider": provider}

    params = urlencode({
        "client_id": os.environ[f"{provider.upper()}_CLIENT_ID"],
        "redirect_uri": os.environ[f"{provider.upper()}_CALLBACK_URL"],
        "response_type": "code",
        "scope": "openid email profile",
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",  # Siempre S256, nunca plain
    })
    return f"{PROVIDER_AUTH_URLS[provider]}?{params}"
```

Frameworks compatibles:
- **FastAPI**: Depends(), OAuth2AuthorizationCodeBearer, HTTPBearer
- **Django**: django-allauth, django-oauth-toolkit
- **Flask**: Flask-Dance, Authlib

---

## JWT con RS256 (PyJWT)

```python
import jwt
import os
from pathlib import Path

# Cargar claves desde env vars — NUNCA hardcodear
def _load_key(env_var: str, path_var: str) -> bytes:
    if val := os.environ.get(env_var):
        import base64
        return base64.b64decode(val)
    if path := os.environ.get(path_var):
        return Path(path).read_bytes()
    raise RuntimeError(f"JWT key not configured. Set {env_var} or {path_var}")

PRIVATE_KEY = _load_key("JWT_PRIVATE_KEY", "JWT_PRIVATE_KEY_PATH")
PUBLIC_KEY  = _load_key("JWT_PUBLIC_KEY",  "JWT_PUBLIC_KEY_PATH")

def issue_access_token(user_id: str, roles: list[str]) -> str:
    import secrets
    from datetime import datetime, timedelta, timezone

    return jwt.encode(
        {
            "sub": user_id,
            "roles": roles,
            "jti": secrets.token_hex(16),
            "iat": datetime.now(timezone.utc),
            "exp": datetime.now(timezone.utc) + timedelta(minutes=15),  # Max 15 min
            "iss": os.environ["JWT_ISSUER"],
            "aud": os.environ["JWT_AUDIENCE"],
        },
        PRIVATE_KEY,
        algorithm="RS256",  # RS256 — nunca HS256 para sistemas con múltiples servicios
    )

def verify_access_token(token: str) -> dict:
    return jwt.decode(
        token,
        PUBLIC_KEY,
        algorithms=["RS256"],  # Lista explícita — nunca vacía (previene alg:none)
        issuer=os.environ["JWT_ISSUER"],
        audience=os.environ["JWT_AUDIENCE"],
        options={"require": ["exp", "iat", "sub", "jti"]},
    )
```

Generar par RSA como parte del scaffold:
```bash
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem
# IMPORTANTE: agregar private.pem a .gitignore INMEDIATAMENTE
```

---

## FastAPI — Dependencias de Auth

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2AuthorizationCodeBearer, HTTPBearer

oauth2_scheme = OAuth2AuthorizationCodeBearer(
    authorizationUrl="/auth/{provider}",
    tokenUrl="/auth/token",
)

async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    try:
        payload = verify_access_token(token)
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

def require_permission(resource: str, action: str):
    async def _check(user: dict = Depends(get_current_user)):
        if not check_permission(user.get("roles", []), resource, action):
            raise HTTPException(status_code=403, detail="Forbidden")
        return user
    return _check
```

---

## Sessions con Redis (Starlette)

```python
from starlette.middleware.sessions import SessionMiddleware
import os

# Para FastAPI/Starlette
app.add_middleware(
    SessionMiddleware,
    secret_key=os.environ["SESSION_SECRET"],   # Min 32 chars aleatorios
    session_cookie="__Secure-session",
    max_age=15 * 60,                           # 15 minutos
    same_site="lax",                           # 'lax' mínimo
    https_only=os.environ.get("ENV") == "production",  # Secure en prod
    # httponly siempre True (default de SessionMiddleware)
)
```

Para Django:
```python
# settings.py
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = not DEBUG            # True en producción
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_AGE = 15 * 60                # 15 minutos
SESSION_ENGINE = "django.contrib.sessions.backends.cache"
SESSION_CACHE_ALIAS = "redis_sessions"      # Redis como backend
```

---

## Refresh Token Rotation (SQLAlchemy)

Schema:
```python
from sqlalchemy import Column, String, Enum, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import uuid

class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id          = Column(UUID, primary_key=True, default=uuid.uuid4)
    token_hash  = Column(String(64), nullable=False, unique=True)  # SHA256, no el raw token
    user_id     = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    family_id   = Column(UUID, nullable=False)   # Grupo de tokens relacionados
    status      = Column(Enum("active","used","revoked", name="token_status"), default="active")
    created_at  = Column(DateTime(timezone=True), default=func.now())
    expires_at  = Column(DateTime(timezone=True), nullable=False)
    replaced_by = Column(UUID, ForeignKey("refresh_tokens.id"), nullable=True)
```

Lógica de rotación:
```python
import hashlib
import secrets
from datetime import datetime, timedelta, timezone

async def rotate_refresh_token(raw_token: str, db: AsyncSession):
    token_hash = hashlib.sha256(raw_token.encode()).hexdigest()

    async with db.begin():
        stored = await db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        )
        stored = stored.scalar_one_or_none()

        if not stored:
            raise UnauthorizedError("Invalid refresh token")

        if stored.status == "used":
            # Detección de reuso — revocar TODA la familia
            await db.execute(
                update(RefreshToken)
                .where(RefreshToken.family_id == stored.family_id)
                .values(status="revoked")
            )
            raise UnauthorizedError("Token reuse detected. Please login again.")

        if stored.status == "revoked":
            raise UnauthorizedError("Token revoked")

        if stored.expires_at < datetime.now(timezone.utc):
            raise UnauthorizedError("Token expired")

        # Marcar como usado
        stored.status = "used"

        # Emitir nuevo token en la misma familia
        new_raw = secrets.token_urlsafe(32)
        new_hash = hashlib.sha256(new_raw.encode()).hexdigest()
        new_token = RefreshToken(
            token_hash=new_hash,
            user_id=stored.user_id,
            family_id=stored.family_id,
            status="active",
            expires_at=datetime.now(timezone.utc) + timedelta(days=30),
        )
        db.add(new_token)

    return {"access_token": issue_access_token(str(stored.user_id), []), "refresh_token": new_raw}
```

---

## 6 Endpoints Generados

| Método | Path | Descripción | Rate Limit |
|--------|------|-------------|------------|
| `POST` | `/auth/{provider}` | Inicia flujo OAuth2, devuelve authorization_url | 10/IP/min |
| `GET`  | `/auth/{provider}/callback` | Callback OAuth2, intercambia code por tokens | 20/IP/min |
| `POST` | `/auth/refresh` | Rota refresh token, emite nuevo par | 30/IP/15min |
| `POST` | `/auth/logout` | Revoca refresh token actual | 10/IP/min |
| `GET`  | `/auth/me` | Datos del usuario autenticado | 60/IP/min |
| `POST` | `/auth/token/verify` | Verifica validez de un access token | 30/IP/min |

---

## RBAC — checkPermission

```python
# rbac_matrix.py — archivo separado, no inline en routes
from typing import Literal

Role     = Literal["admin", "editor", "viewer", "guest"]
Resource = Literal["posts", "users", "settings", "analytics"]
Action   = Literal["create", "read", "update", "delete"]

# Deny by default — todo lo no listado está denegado
PERMISSIONS: dict[str, dict[str, list[str]]] = {
    "admin":  {"posts": ["create","read","update","delete"], "users": ["create","read","update","delete"], "settings": ["read","update"], "analytics": ["read"]},
    "editor": {"posts": ["create","read","update"], "analytics": ["read"]},
    "viewer": {"posts": ["read"], "analytics": ["read"]},
    "guest":  {"posts": ["read"]},
}

def check_permission(role: str, resource: str, action: str) -> bool:
    """Deny by default si rol, recurso o acción no están en la matriz."""
    return action in PERMISSIONS.get(role, {}).get(resource, [])

# Decorador para FastAPI
def require_permission(resource: str, action: str):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, user=Depends(get_current_user), **kwargs):
            if not check_permission(user.get("role", "guest"), resource, action):
                raise HTTPException(status_code=403, detail="Forbidden")
            return await func(*args, user=user, **kwargs)
        return wrapper
    return decorator
```

---

## OPA Client (fail-closed)

```python
import httpx
import os

OPA_URL = os.environ.get("OPA_URL", "http://localhost:8181")
OPA_TIMEOUT = 0.1  # 100ms máximo — fail-closed si timeout

async def evaluate_policy(policy: str, input_data: dict) -> bool:
    """
    FAIL-CLOSED: si OPA no responde dentro de 100ms → denegar acceso.
    Esto es correcto y esperado — nunca fail-open.
    """
    try:
        async with httpx.AsyncClient(timeout=OPA_TIMEOUT) as client:
            response = await client.post(
                f"{OPA_URL}/v1/data/{policy}",
                json={"input": input_data},
            )
            return response.json().get("result") is True  # Solo True explícito
    except Exception:
        return False  # OPA no responde → DENEGAR
```
