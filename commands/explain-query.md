---
name: explain-query
description: "Analiza una query SQL o ORM con EXPLAIN PLAN. Detecta full table scans, índices faltantes y N+1, y sugiere CREATE INDEX + refactors de batching"
argument-hint: "[query|file] [--dialect postgres|mysql|mariadb|sqlite|mssql|oracle] [--mode explain|explain-analyze]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /explain-query

Analiza una query SQL o una llamada ORM con `EXPLAIN PLAN`. Detecta full table scans, índices
faltantes y el anti-patrón N+1. Sugiere sentencias `CREATE INDEX` listas para usar y refactors de
batching. Alimenta la capa **CASTLE T** (check "no queries in loops"). Degrada graciosamente sin
conexión DB usando análisis estático LLM.

## Instrucciones

1. Invocar el skill `explain-query` usando la herramienta Skill
2. Argumentos:
   - `[query|file]`: SQL string entre comillas, una llamada ORM, o la ruta a un archivo con la(s) query(s). Si es archivo, se analizan TODAS las queries (incluidas las dentro de loops)
   - `--dialect <postgres|mysql|mariadb|sqlite|mssql|oracle>`: fuerza el dialecto. Default: auto-detectado desde `.king/knowledge/stack.md`
   - `--mode <explain|explain-analyze>`: `explain` (default, no corre la query) o `explain-analyze` (CORRE la query — requiere confirmación; NUNCA en prod sin OK explícito)
3. Seguir todas las fases del skill en orden:
   - Detect dialect → Parse query → Run EXPLAIN → Analyze → Suggest
4. Agentes coordinados: @performance (principal: interpreta el plan, detecta N+1), @architect (valida índices vs modelo de datos), @developer (aplica refactors/migraciones, fuera de este skill)
5. IMPORTANTE: nunca incluir credenciales ni connection strings literales en el output; nunca aplicar los `CREATE INDEX` (solo proponerlos)

Si no hay conexión DB disponible, el skill NO falla: degrada a análisis estático LLM y marca el
output como `source: static`. Si no se detecta el dialecto ni se pasa `--dialect`, lo infiere de la
sintaxis (`$1`→postgres, `?`→mysql/sqlite, `@p1`→mssql, `:1`→oracle).

## Ejemplos

### Query directa con índice faltante

```
/explain-query "SELECT * FROM orders WHERE user_id = $1 AND status = $2" --dialect postgres
```

### Archivo con N+1 (loop ORM)

```
/explain-query src/services/dashboard.ts
```

## Ejemplo de output (caso N+1 detectado)

Input: `src/services/dashboard.ts` (Prisma, dialecto auto-detectado: `postgres`, sin conexión DB → `static`).

```ts
// src/services/dashboard.ts:18-22
const users = await prisma.user.findMany();
for (const u of users) {
  u.orders = await prisma.order.findMany({ where: { userId: u.id } }); // ← 1 query por usuario
}
```

```
EXPLAIN PLAN — /explain-query                          source: static (no DB connection)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Query 1  prisma.user.findMany()
  → SELECT * FROM "users"
  → Seq Scan on users  (cost≈ rows=N)   OK (carga base, sin filtro)

Query 2  prisma.order.findMany({ where: { userId } })   [DENTRO DE LOOP — líneas 18-22]
  → SELECT * FROM "orders" WHERE "user_id" = $1
  → Seq Scan on orders  (cost alto · sin índice en user_id)
  → Ejecutada 1 vez POR usuario  ⇒  1 + N queries

Problemas detectados
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[CRITICAL]  N+1 Query           dashboard.ts:18-22   findMany dentro de for → 1 + N queries
[CRITICAL]  Full Table Scan     orders               WHERE user_id = $1 sin índice (Seq Scan)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CASTLE T: "no queries in loops" → VIOLADO (N+1)

Sugerencias
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1) Índice para el filtro WHERE user_id (postgres):

   CREATE INDEX idx_orders_user_id ON orders (user_id);

   Impacto estimado: orders WHERE user_id pasa de Seq Scan a Index Scan.
   En tabla de ~1M filas, latencia por query ~baja de O(n) a O(log n).

2) Refactor N+1 → batch (1 + N  ⇒  1 query con eager-load):

   - ANTES (1 + N queries):
     const users = await prisma.user.findMany();
     for (const u of users) {
       u.orders = await prisma.order.findMany({ where: { userId: u.id } });
     }

   + DESPUÉS (1 query):
     const users = await prisma.user.findMany({
       include: { orders: true },
     });

   Equivalente SQL: SELECT ... FROM users LEFT JOIN orders ON orders.user_id = users.id
   (Prisma resuelve el include en 1-2 queries, no 1+N.)

Verificá los índices existentes antes de aplicar. Análisis estático: re-ejecutá con DATABASE_URL
para validar el plan real (EXPLAIN).
```

El report es advisory por defecto. Cuando `@performance` lo invoca durante `/review` y confirma el
N+1, eleva el check CASTLE T "no queries in loops" a violación bloqueante.
