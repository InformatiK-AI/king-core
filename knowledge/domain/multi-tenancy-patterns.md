# Multi-Tenancy Patterns — Guía de Arquitectura SaaS

> Versión completa. Para inyección en agents usar `knowledge/_inject/multi-tenancy.md`.

---

## Estrategias de Aislamiento

| Estrategia | Aislamiento | Costo | Cuándo usar |
|------------|-------------|-------|-------------|
| Database por tenant | Máximo | Alto | Compliance estricto, enterprise |
| Schema por tenant | Alto | Medio | <500 tenants, mismo motor DB |
| RLS por tenant | Medio-Alto | Bajo | SaaS estándar, crecimiento rápido |
| Columna tenant_id | Básico | Mínimo | MVPs, bajo riesgo regulatorio |

**King recomienda RLS** para SaaS estándar: balance óptimo entre aislamiento, costo operativo y velocidad de desarrollo.

---

## PostgreSQL Row Level Security

### Habilitación y Políticas

```sql
-- Paso 1: habilitar RLS en la tabla
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY; -- FORCE afecta también al owner

-- Paso 2: política de aislamiento
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id')::uuid)
  WITH CHECK (tenant_id = current_setting('app.tenant_id')::uuid);

-- Paso 3: política de solo lectura para auditoría (opcional)
CREATE POLICY audit_read ON audit_log
  FOR SELECT
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

### Rol de Aplicación (sin superuser)

```sql
-- El rol de la aplicación NO debe ser superuser ni bypassrls
CREATE ROLE app_user LOGIN PASSWORD '...';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- RLS aplica automáticamente a roles que no tienen BYPASSRLS
```

### Manejo de Errores RLS

```sql
-- Si app.tenant_id no está seteado, current_setting lanza error
-- Usar la forma con default para evitar errores en contextos sin tenant
current_setting('app.tenant_id', true)  -- retorna NULL si no existe
-- En producción preferir la forma estricta (sin true) para fail-fast
```

---

## Middleware de Contexto de Tenant

### Flujo de Datos Completo

```
┌──────────┐    JWT      ┌────────────────┐   SET LOCAL   ┌──────────────┐
│  Client  │────────────▶│ Tenant         │──────────────▶│  PostgreSQL  │
│          │             │ Middleware     │               │  (RLS activo)│
└──────────┘             └────────────────┘               └──────────────┘
                               │
                               │ tenant_id validado
                               ▼
                         ┌────────────────┐
                         │  Business      │
                         │  Logic Layer   │
                         │  (no filtra,   │
                         │  RLS lo hace)  │
                         └────────────────┘
```

### Implementación Node.js / Express

```typescript
import { Pool, PoolClient } from 'pg';
import jwt from 'jsonwebtoken';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

export async function tenantMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      res.status(401).json({ error: 'Authorization required' });
      return;
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET!) as {
      sub: string;
      tenant_id: string;
    };

    if (!payload.tenant_id) {
      res.status(401).json({ error: 'tenant_id missing in token' });
      return;
    }

    // Validar UUID format antes de pasarlo a SET LOCAL
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(payload.tenant_id)) {
      res.status(401).json({ error: 'Invalid tenant_id format' });
      return;
    }

    req.tenantId = payload.tenant_id;
    req.userId = payload.sub;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Helper: obtener cliente con contexto de tenant
export async function withTenantContext<T>(
  tenantId: string,
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    // SET LOCAL limita el scope a esta transacción
    await client.query('BEGIN');
    await client.query('SET LOCAL app.tenant_id = $1', [tenantId]);
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
```

### Implementación Python / FastAPI

```python
from fastapi import Depends, HTTPException, Header
from jose import jwt, JWTError
import re

UUID_RE = re.compile(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    re.IGNORECASE
)

async def get_tenant_id(authorization: str = Header(...)) -> str:
    try:
        token = authorization.removeprefix("Bearer ")
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
        tenant_id = payload.get("tenant_id")
        if not tenant_id or not UUID_RE.match(tenant_id):
            raise HTTPException(status_code=401, detail="Invalid tenant_id")
        return tenant_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

# En cada endpoint:
@router.get("/orders")
async def list_orders(
    tenant_id: str = Depends(get_tenant_id),
    db: AsyncSession = Depends(get_db)
):
    await db.execute(text("SET LOCAL app.tenant_id = :tid"), {"tid": tenant_id})
    return await db.execute(select(Order))  # RLS filtra automáticamente
```

---

## Attribute-Based Access Control (ABAC)

### Modelo de Atributos

```
Sujeto (Subject)    → quién: userId, tenantId, roles[], plan
Recurso (Resource)  → qué: type, tenantId, ownerId, classification
Acción (Action)     → operación: read | write | delete | admin | share
Contexto (Context)  → cuándo/cómo: timestamp, ip, mfa_verified
```

### Implementación con OPA (Open Policy Agent)

```rego
# policy.rego
package authz

default allow = false

# Regla 1: cross-tenant SIEMPRE denegado
deny[reason] {
  input.subject.tenant_id != input.resource.tenant_id
  reason := "cross-tenant access denied"
}

# Regla 2: permisos por rol dentro del tenant
allow {
  not deny[_]
  role_has_permission(input.subject.roles[_], input.action, input.resource.type)
}

role_has_permission("admin", _, _)                         { true }
role_has_permission("editor", action, _)                   { action != "admin" }
role_has_permission("viewer", "read", _)                   { true }
role_has_permission("viewer", "read", "public_resource")   { true }
```

### Implementación sin OPA (políticas propias)

```typescript
interface ABACPolicy {
  roles: Record<string, string[]>; // rol → acciones permitidas
}

const defaultPolicy: ABACPolicy = {
  roles: {
    admin:  ['read', 'write', 'delete', 'admin', 'share'],
    editor: ['read', 'write', 'share'],
    viewer: ['read'],
  }
};

export function evaluateABAC(
  subject: { tenantId: string; roles: string[] },
  resource: { tenantId: string; type: string },
  action: string,
  policy = defaultPolicy
): { allowed: boolean; reason: string } {
  // Cross-tenant: denegado siempre
  if (subject.tenantId !== resource.tenantId) {
    return { allowed: false, reason: 'cross-tenant-denied' };
  }

  // Verificar permiso por rol
  const allowed = subject.roles.some(role =>
    policy.roles[role]?.includes(action)
  );

  return {
    allowed,
    reason: allowed ? 'role-permitted' : 'insufficient-permissions'
  };
}
```

---

## Testing de Aislamiento

```typescript
describe('Tenant Isolation', () => {
  it('usuario de tenant A no puede ver datos de tenant B', async () => {
    const tenantA = await createTestTenant();
    const tenantB = await createTestTenant();
    const orderB = await createOrder({ tenantId: tenantB.id });

    const result = await withTenantContext(tenantA.id, client =>
      client.query('SELECT * FROM orders WHERE id = $1', [orderB.id])
    );

    expect(result.rows).toHaveLength(0); // RLS filtra
  });

  it('query sin contexto de tenant falla (fail-safe)', async () => {
    await expect(
      pool.query('SELECT * FROM orders')
    ).rejects.toThrow(); // current_setting sin valor lanza error
  });
});
```

---

## Anti-Patterns a Evitar

| Anti-Pattern | Problema | Corrección |
|-------------|---------|-----------|
| `SET app.tenant_id` sin `LOCAL` | Persiste entre transacciones en connection pool | Usar `SET LOCAL` siempre |
| ABAC con `default: true` | Fail-open: acceso por defecto | Usar `default: false` |
| tenant_id del body de la request | Suplantación trivial | Siempre del JWT verificado |
| `SECURITY DEFINER` sin RLS | Bypass de políticas | Auditar todas las funciones DEFINER |
| Índice sin tenant_id | Performance degradada + leak potencial | `CREATE INDEX ON table (tenant_id, id)` |
| Superuser como rol de app | Bypass RLS completo | Rol de app sin BYPASSRLS |

---

## Checklist de Implementación Completa

### Base de Datos
- [ ] RLS habilitado con `ENABLE` y `FORCE` en todas las tablas con tenant_id
- [ ] Política `USING` y `WITH CHECK` en cada tabla
- [ ] Rol de aplicación sin `SUPERUSER` ni `BYPASSRLS`
- [ ] Índices compuestos `(tenant_id, id)` en tablas de alta frecuencia

### Application Layer
- [ ] Middleware extrae tenant_id del JWT (no del body)
- [ ] Validación de formato UUID antes de `SET LOCAL`
- [ ] `SET LOCAL` (no `SET`) en cada transacción
- [ ] `withTenantContext` helper centraliza la propagación

### ABAC
- [ ] `default: false` (deny by default)
- [ ] Cross-tenant siempre denegado antes de evaluar roles
- [ ] Decisión auditable (log de cada evaluación en producción)

### Testing
- [ ] Test: usuario A no ve datos de tenant B
- [ ] Test: query sin contexto lanza error (fail-fast)
- [ ] Test: ABAC deniega cross-tenant sin excepción
- [ ] Test: admin puede, viewer no puede (por acción)
