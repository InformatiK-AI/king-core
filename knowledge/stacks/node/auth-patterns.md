# Auth Patterns — Node.js

> Patrones de implementación de autenticación para proyectos Node.js.
> Conceptos base y reglas absolutas: ver `../../_inject/auth-essentials.md`

---

## OAuth2 + PKCE

```typescript
import { randomBytes, createHash } from 'crypto';

// CORRECTO: CSPRNG obligatorio — NUNCA Math.random()
function generateCodeVerifier(): string {
  return randomBytes(32).toString('base64url'); // 43 chars Base64URL
}

function generateCodeChallenge(verifier: string): string {
  return createHash('sha256')
    .update(verifier)
    .digest('base64url'); // base64url sin padding, method=S256
}

// BFF pattern: el servidor genera y almacena verifier; devuelve solo authorization_url
async function initiateOAuth(provider: string, req: Request): Promise<string> {
  const state = randomBytes(16).toString('hex'); // CSRF protection
  const verifier = generateCodeVerifier();
  const challenge = generateCodeChallenge(verifier);

  // Almacenar en session server-side — destruir post-exchange
  req.session.oauth = { state, verifier, provider };

  const params = new URLSearchParams({
    client_id: process.env[`${provider.toUpperCase()}_CLIENT_ID`]!,
    redirect_uri: process.env[`${provider.toUpperCase()}_CALLBACK_URL`]!,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    code_challenge: challenge,
    code_challenge_method: 'S256', // Siempre S256, nunca plain
  });

  return `${PROVIDER_AUTH_URLS[provider]}?${params}`;
}
```

Frameworks compatibles:
- **Express**: passport.js con passport-oauth2
- **Fastify**: fastify-oauth2
- **NestJS**: @nestjs/passport con passport-oauth2

---

## JWT con RS256

```typescript
import { sign, verify } from 'jsonwebtoken';
import { readFileSync } from 'fs';

// Cargar claves desde env vars — NUNCA hardcodear
const PRIVATE_KEY = process.env.JWT_PRIVATE_KEY
  ? Buffer.from(process.env.JWT_PRIVATE_KEY, 'base64')
  : readFileSync(process.env.JWT_PRIVATE_KEY_PATH!);

const PUBLIC_KEY = process.env.JWT_PUBLIC_KEY
  ? Buffer.from(process.env.JWT_PUBLIC_KEY, 'base64')
  : readFileSync(process.env.JWT_PUBLIC_KEY_PATH!);

if (!PRIVATE_KEY || !PUBLIC_KEY) {
  // Fail-fast en startup — no continuar sin claves
  throw new Error('JWT keys not configured. Set JWT_PRIVATE_KEY or JWT_PRIVATE_KEY_PATH');
}

function issueAccessToken(userId: string, roles: string[]): string {
  return sign(
    { sub: userId, roles, jti: randomBytes(16).toString('hex') },
    PRIVATE_KEY,
    {
      algorithm: 'RS256', // RS256 — nunca HS256 para sistemas con múltiples servicios
      expiresIn: '15m',   // Máximo 15 minutos para access tokens
      issuer: process.env.JWT_ISSUER!,
      audience: process.env.JWT_AUDIENCE!,
    }
  );
}

function verifyAccessToken(token: string) {
  return verify(token, PUBLIC_KEY, {
    algorithms: ['RS256'], // Array explícito — nunca vacío (previene alg:none attack)
    issuer: process.env.JWT_ISSUER!,
    audience: process.env.JWT_AUDIENCE!,
  });
}
```

Generar par RSA como parte del scaffold:
```bash
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem
# IMPORTANTE: agregar private.pem a .gitignore INMEDIATAMENTE
```

---

## Sessions con express-session + Redis

```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient({
  url: process.env.REDIS_URL,
});
redisClient.connect().catch(console.error);

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET!, // Min 32 chars aleatorios
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,                                         // Sin acceso desde JS
    secure: process.env.NODE_ENV === 'production',         // HTTPS solo en prod
    sameSite: 'lax',                                       // 'lax' mínimo
    maxAge: 15 * 60 * 1000,                               // 15 minutos
    path: '/api/auth',                                     // Path restrictivo
    // domain: NO hardcodear — usar default del servidor
  },
  name: '__Secure-session', // Prefijo __Secure- requiere Secure:true
}));
```

---

## Refresh Token Rotation

Schema de tabla DB:
```sql
CREATE TABLE refresh_tokens (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash   VARCHAR(64) NOT NULL UNIQUE, -- SHA256 del token, nunca el token crudo
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  family_id    UUID NOT NULL,               -- Grupo de tokens relacionados
  status       VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used', 'revoked')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at   TIMESTAMPTZ NOT NULL,
  replaced_by  UUID REFERENCES refresh_tokens(id) -- Audit trail
);

CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_family_id  ON refresh_tokens(family_id);
```

Lógica de rotación:
```typescript
import { createHash, randomBytes } from 'crypto';

async function rotateRefreshToken(
  rawToken: string,
  db: Database
): Promise<{ accessToken: string; refreshToken: string }> {
  const tokenHash = createHash('sha256').update(rawToken).digest('hex');

  return db.transaction(async (trx) => {
    const stored = await trx('refresh_tokens')
      .where({ token_hash: tokenHash })
      .first();

    if (!stored) throw new UnauthorizedError('Invalid refresh token');

    if (stored.status === 'used') {
      // Detección de reuso: revocar TODA la familia — posible token robado
      await trx('refresh_tokens')
        .where({ family_id: stored.family_id })
        .update({ status: 'revoked' });
      throw new UnauthorizedError('Token reuse detected. Please login again.');
    }

    if (stored.status === 'revoked') throw new UnauthorizedError('Token revoked');
    if (stored.expires_at < new Date()) throw new UnauthorizedError('Token expired');

    // Marcar como usado
    await trx('refresh_tokens').where({ id: stored.id }).update({ status: 'used' });

    // Emitir nuevo token en la misma familia
    const newRawToken = randomBytes(32).toString('base64url');
    const newHash = createHash('sha256').update(newRawToken).digest('hex');

    await trx('refresh_tokens').insert({
      token_hash: newHash,
      user_id: stored.user_id,
      family_id: stored.family_id, // Misma familia
      status: 'active',
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Max 30 días
      replaced_by: null,
    });

    const accessToken = issueAccessToken(stored.user_id, stored.roles);
    return { accessToken, refreshToken: newRawToken };
  });
}
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

```typescript
// rbac.matrix.ts — archivo separado, no inline en routes
export type Role = 'admin' | 'editor' | 'viewer' | 'guest';
export type Resource = 'posts' | 'users' | 'settings' | 'analytics';
export type Action = 'create' | 'read' | 'update' | 'delete';

// Matriz centralizada — deny by default (todo lo no listado está denegado)
const PERMISSIONS: Record<Role, Partial<Record<Resource, Action[]>>> = {
  admin:  { posts: ['create','read','update','delete'], users: ['create','read','update','delete'], settings: ['read','update'], analytics: ['read'] },
  editor: { posts: ['create','read','update'], analytics: ['read'] },
  viewer: { posts: ['read'], analytics: ['read'] },
  guest:  { posts: ['read'] },
};

export function checkPermission(role: Role, resource: Resource, action: Action): boolean {
  // Deny by default — si el rol o recurso no existe, denegar
  return PERMISSIONS[role]?.[resource]?.includes(action) ?? false;
}

// Middleware para Express/Fastify
export function requirePermission(resource: Resource, action: Action) {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user || !checkPermission(req.user.role, resource, action)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
}
```

---

## OPA Client (fail-closed)

```typescript
import axios from 'axios';

const OPA_URL = process.env.OPA_URL ?? 'http://localhost:8181';
const OPA_TIMEOUT_MS = 100; // 100ms máximo — fail-closed si timeout

async function evaluatePolicy(
  policy: string,
  input: Record<string, unknown>
): Promise<boolean> {
  try {
    const response = await axios.post(
      `${OPA_URL}/v1/data/${policy}`,
      { input },
      { timeout: OPA_TIMEOUT_MS }
    );
    // FAIL-CLOSED: solo allow si result.result === true explícitamente
    return response.data?.result === true;
  } catch {
    // OPA no responde → DENEGAR — esto es correcto y esperado
    // No loggear el error como crítico — puede ser transitorio
    return false;
  }
}
```
