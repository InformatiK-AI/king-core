# Multi-Tenancy Essentials (para inyección)

> Versión compacta optimizada para inyección en agents. Guía completa en `knowledge/domain/multi-tenancy-patterns.md`.

## Principio Fundamental

**Fail-safe by default**: toda query SIN tenant_id debe ser imposible — el sistema lo rechaza, no lo ignora.

## PostgreSQL — Row Level Security (RLS)

```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON users
  USING (tenant_id = current_setting('app.tenant_id')::uuid);

SET LOCAL app.tenant_id = '<uuid>'; -- NUNCA SET sin LOCAL
```

## Application-Level — Middleware de Contexto

```typescript
// Auth middleware previo (ej. passport-jwt) ya verificó el JWT y populó req.user.
// ⚠️  NO llamar SET LOCAL aquí — sin BEGIN, PostgreSQL lo ignora. Usar withTenantContext.
async function tenantMiddleware(req, res, next) {
  const tenantId = req.user?.tenant_id;
  if (!tenantId) return res.status(401).json({ error: 'tenant_id required' });
  req.tenantId = tenantId;
  next();
}
```

## ABAC — Attribute-Based Access Control

```typescript
// req: { subject: {tenantId, roles[]}, resource: {tenantId}, action }
function evaluate(req): boolean {
  if (req.subject.tenantId !== req.resource.tenantId) return false; // cross-tenant denegado
  return rolePermissions[req.action]?.includes(req.subject.roles[0]) ?? false;
}
```

## Quick Reference

| NUNCA | SIEMPRE |
|-------|---------|
| `SET app.tenant_id` sin `LOCAL` | `SET LOCAL` — scope por transacción |
| tenant_id del request body | tenant_id del JWT verificado |
| ABAC `default: true` | ABAC `default: false` (deny-first) |
| Query sin tenant_id posible | RLS + fail-fast en middleware |
| `SECURITY DEFINER` sin RLS | Auditar todas las funciones DEFINER |
| Tests sin aislamiento entre tenants | Test: usuario A no ve datos de tenant B |
