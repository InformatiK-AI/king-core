---
name: db-optimize
description: "Database Excellence: analiza schema y queries, detecta FK sin índice y slow queries, sugiere CREATE INDEX (naming idx_{table}_{cols}), caching (Redis/Memcached + TTL + cache-aside) y estrategias avanzadas (partitioning, materialized views). Reusa /explain-query para N+1 y genera el payload de handoff a /db-migrate de king-infra"
argument-hint: "[target] [--dialect postgres|mysql|mariadb|sqlite|mssql|oracle] [--connection <env-var>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Skill, Agent]
---

# /db-optimize

Lleva la base de datos del proyecto a un estado saludable. Descubre el **schema completo** (migrations,
Prisma/SQLAlchemy/TypeORM/Drizzle models, introspección live, o inferencia desde queries), recolecta las
**queries reales** del código (repositories, services, handlers), cruza queries contra los índices existentes
(cobertura), confirma **N+1** delegando en `/explain-query`, y produce: **`CREATE INDEX`** con naming
canónico, **estrategia de caching** (qué cachear, store, TTL, código cache-aside) y **estrategias avanzadas**
(partitioning, materialized views). Cierra generando el **payload de handoff a `/db-migrate`** de
`king-infra`. Este skill ANALIZA y PROPONE — NUNCA aplica DDL a la DB. Alimenta **CASTLE A (Architecture)** y
**CASTLE T (Testing)**.

## Instrucciones

1. Invocar el skill `db-optimize` usando la herramienta Skill
2. Argumentos:
   - `[target]`: schema file, migration file, modelo ORM (Prisma/SQLAlchemy/TypeORM/Drizzle), o directorio de queries/repositorios. Si se omite, descubre el schema y las queries automáticamente
   - `--dialect <d>`: fuerza el dialecto (`postgres`, `mysql`, `mariadb`, `sqlite`, `mssql`, `oracle`). Default: auto-detectado desde `.king/knowledge/stack.md`
   - `--connection <env-var>`: variable de entorno con la conexión DB (ej. `DATABASE_URL`). Si está disponible, `/explain-query` corre `EXPLAIN` real; si no, todo el análisis degrada a `static`
3. Seguir todas las fases del skill en orden:
   - Discover schema → Collect queries → Analyze coverage → N+1 detection (`/explain-query`) → Suggest indexes → Suggest caching → Suggest advanced → Generate handoff
   - Sin conexión DB el skill NO falla: degrada a análisis estático LLM y marca el output como `static`
4. Agentes coordinados: @performance (principal: coste de queries, candidatos de caching, invoca `/explain-query` para N+1), @architect (valida que índices/partitioning/MV respeten el modelo de datos y los límites de agregado), @developer (aplica refactors y corre el handoff con `/db-migrate`, fuera de este skill)
5. IMPORTANTE: nunca aplicar `CREATE INDEX`/DDL ni correr migrations (solo proponer + handoff); nunca re-implementar el N+1 inline (delegar a `/explain-query`); nunca embeber credenciales/connection strings en el output, el código de caching o el payload; nunca recomendar partitioning/MV sin justificar el umbral

La confirmación de N+1 se delega SIEMPRE a `/explain-query` (ya existe). El payload de handoff a
`/db-migrate` es una PROPUESTA: el developer la confirma y la corre con el skill de migración de king-infra,
que la envuelve en el sistema de migraciones detectado del proyecto.

## Ejemplos

### Optimización completa con auto-descubrimiento (sin target)

```
/db-optimize
```

(descubre schema + queries, cruza cobertura, confirma N+1, sugiere índices/caching/avanzado y arma el handoff)

### Sobre un schema Prisma con conexión real

```
/db-optimize prisma/schema.prisma --connection DATABASE_URL
```

### Sobre un directorio de repositorios, dialecto forzado, sin conexión (static)

```
/db-optimize src/repositories --dialect postgres
```

## Ejemplo guía: FK sin índice → CREATE INDEX + caching de dashboard

Schema Postgres donde `orders` referencia `users(id)` pero `orders.user_id` NO tiene índice (Postgres no lo
crea solo al declarar la FK). Además hay una query de dashboard agregada sobre `orders` de los últimos 30
días que es costosa y se llama en cada carga.

**1) FK sin índice → `CREATE INDEX` (handoff a `/db-migrate`)**

```
Hallazgo:  [major] FK orders.user_id → users(id) SIN índice
           → cada JOIN orders↔users hace Seq Scan sobre orders
Remediación:
           CREATE INDEX idx_orders_user_id ON orders(user_id);
```

**2) Query de dashboard agregada → caching (Redis, TTL 5 min, cache-aside)**

```
Hallazgo:  [caching] agregación 30d sobre orders — alta frecuencia + alto costo + tolerante a staleness
Sugerencia: Redis, TTL 5 min, cache-aside

// Antes: cada request corre la agregación completa (~300ms)
const stats = await db.query(DASHBOARD_AGG_SQL);

// Después (cache-aside):
let stats = await redis.get("dashboard:orders:30d");
if (!stats) {
  stats = await db.query(DASHBOARD_AGG_SQL);
  await redis.set("dashboard:orders:30d", JSON.stringify(stats), "EX", 300); // TTL 5 min
} else {
  stats = JSON.parse(stats);
}
// Invalidación: TTL pasivo (5 min) o DEL "dashboard:orders:30d" al crear una orden
```

**3) Payload de handoff generado para `/db-migrate` (king-infra)**

```yaml
# Handoff → /db-migrate — PROPUESTA (requiere confirmación del developer)
dialect: postgres
migration_system: prisma
migrations:
  - name: add_idx_orders_user_id
    reason: "FK orders.user_id → users(id) sin índice — JOIN hace Seq Scan"
    up:   "CREATE INDEX idx_orders_user_id ON orders(user_id);"
    down: "DROP INDEX idx_orders_user_id;"
# Ejecutar con:  /db-migrate --from-handoff <payload>
```

## Naming canónico de índices

| Patrón | Ejemplo |
|--------|---------|
| `idx_{table}_{column}` | `idx_orders_user_id` |
| `idx_{table}_{col1}_{col2}` | `idx_orders_status_created_at` (compuesto, orden por selectividad) |
| `uniq_{table}_{column}` | `uniq_users_email` |

## Handoff a king-infra/db-migrate

`/db-optimize` NO aplica cambios a la DB. Genera un payload estructurado (`dialect`, `migration_system`
detectado, migrations `up`/`down` ordenadas por dependencia) que `/db-migrate` de **king-infra** consume y
envuelve en el sistema de migraciones del proyecto (Flyway/Alembic/Prisma/Knex/Drizzle). El developer
confirma el payload y corre `/db-migrate`. La confirmación de N+1 se delega a `/explain-query`. Detalle de
patrones de ORM y caching en `knowledge/domain/orm-patterns.md` y `knowledge/_inject/performance-essentials.md`.
