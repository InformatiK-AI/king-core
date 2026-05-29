---
name: db-optimize
version: 2.0
api_version: 1.0.0
description: "Analiza schema y queries del proyecto, detecta slow queries y FK sin índice, sugiere índices (CREATE INDEX con naming canónico idx_{table}_{cols}), caching (Redis/Memcached con TTL + código cache-aside) y estrategias avanzadas (partitioning, materialized views). Reusa /explain-query para confirmar N+1. Genera el payload de handoff a /db-migrate de king-infra. Usar cuando se necesite: optimizar la base de datos, detectar slow queries, encontrar FK sin índice, decidir qué cachear, evaluar particionado/materialized views, o preparar migrations de índices. Degrada graciosamente sin conexión DB con análisis estático LLM."
---

# /db-optimize — Database Excellence (schema, índices, caching, particionado, handoff a /db-migrate)

Analiza el **schema completo** y las **queries** del proyecto para llevar la base de datos a un estado
saludable. Descubre el modelo (migration files, Prisma schema, SQLAlchemy/TypeORM models, o lo infiere de
las queries), recolecta las queries reales del código (repositories, services, API handlers), cruza queries
contra índices existentes (cobertura), confirma patrones **N+1** delegando en `/explain-query`, y produce:
**`CREATE INDEX`** con naming canónico, **estrategia de caching** (qué cachear, en qué store, con qué TTL,
con código cache-aside), y **estrategias avanzadas** (partitioning para tablas grandes, materialized views
para agregaciones costosas). Cierra generando el **payload de handoff a `/db-migrate`** de `king-infra` con
las migrations sugeridas — este skill NO aplica nada a la DB, solo propone y arma el handoff.

> **Separación de responsabilidades**: `/db-optimize` ANALIZA y PROPONE; `/db-migrate` (king-infra) APLICA.
> El veredicto de índices y migrations sale de aquí como un payload de handoff explícito; el developer lo
> confirma y lo corre con el skill de migración de king-infra. Este skill jamás ejecuta DDL contra la DB.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack, motor de DB y ORM del proyecto — fuente del `dialect` auto-detectado | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de índices, migraciones y rutas de output | No | project |
| `knowledge/domain/orm-patterns.md` | 4 patrones + 4 anti-patrones (N+1, Query in Loop, God/Anemic Repository) + guías por ORM (custom: este skill cruza queries con estos anti-patrones antes de delegar el N+1 a `/explain-query`) | No | framework |
| `knowledge/_inject/performance-essentials.md` | Heurísticas de coste de query, latencia y candidatos de caching | No | framework |
| `knowledge/_inject/db-migrations-essentials.md` | Detección del sistema de migraciones del proyecto (custom: necesario para armar el payload de handoff a `/db-migrate`) | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[target]` ni se puede descubrir ningún schema/migration/modelo ni ninguna query en el proyecto
- [ ] El `[target]` no es un schema/migration/modelo/directorio de queries reconocible (ej. texto plano arbitrario)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA aplicar `CREATE INDEX` / DDL contra la DB ni ejecutar las migrations — este skill SOLO propone y arma el handoff a `/db-migrate`
- NUNCA ejecutar las queries analizadas como parte del flujo; cuando hay conexión, usar `EXPLAIN` plano (vía `/explain-query`), nunca `EXPLAIN ANALYZE` en `staging`/`prod` sin confirmación explícita
- NUNCA incluir credenciales / connection strings literales en el output, el payload de handoff o el código de caching (usar variables de entorno / `{{SLOT}}`)
- NUNCA fallar con error si no hay conexión DB — degradar a análisis estático LLM y marcar el output como `static`
- NUNCA sugerir partitioning o materialized views sin justificar el umbral (filas estimadas / coste de agregación) — recomendaciones avanzadas SIEMPRE con evidencia
- NUNCA re-implementar la lógica de detección de N+1 inline — delegar la confirmación a `/explain-query`
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Inventario del schema: tablas, columnas, FKs e índices existentes (real o inferido)
- [ ] Reporte de cobertura: queries cruzadas contra índices — WHERE/JOIN sin índice y FK sin índice detectados
- [ ] N+1 confirmados vía `/explain-query` (o "ninguno detectado")
- [ ] Lista de índices faltantes con `CREATE INDEX` (naming `idx_{table}_{columns}`)
- [ ] Sugerencias de caching: queries candidatas, store (Redis/Memcached), TTL y código cache-aside antes/después
- [ ] Sugerencias avanzadas: partitioning y/o materialized views con su justificación de umbral (o "no aplica")
- [ ] Payload de handoff a `/db-migrate` con las migrations sugeridas (formato estructurado)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8 → Phase N+1 → Phase N+2
(Context)(Discover  (Collect   (Analyze   (N+1       (Suggest   (Suggest   (Suggest   (Generate  (Session)  (Guide)
          schema)    queries)   coverage)  detection) indexes)   caching)   advanced)  handoff)
                                           →/explain-query
```

### PARÁMETROS
```
/db-optimize [target] [--dialect postgres|mysql|mariadb|sqlite|mssql|oracle] [--connection <env-var>]
```
- `[target]`: schema file, migration file, modelo ORM (Prisma/SQLAlchemy/TypeORM/Drizzle), o directorio de queries/repositorios. Si se omite, descubre el schema y las queries automáticamente
- `--dialect`: fuerza el dialecto (default: auto-detectado desde `.king/knowledge/stack.md`)
- `--connection`: nombre de la variable de entorno con la conexión DB (ej. `DATABASE_URL`). Si está disponible, `/explain-query` corre `EXPLAIN` real; si no, todo el análisis degrada a `static`

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) vigila que los índices y el particionado respeten el modelo de datos y los límites
> de agregado; CASTLE T (Testing) hereda el check "no queries in loops" (N+1) vía `/explain-query`. Veredicto
> CONDITIONAL si hay FK sin índice, índices faltantes o N+1; el veredicto es advisory salvo que `@performance`
> o `@architect` lo eleven durante `/review`. El skill nunca BREACHEA por sí mismo porque no aplica cambios.

## Agentes
- **@performance** — Agente principal: evalúa coste de queries, clasifica candidatos de caching e invoca `/explain-query` para confirmar N+1
- **@architect** — Valida que los índices, el partitioning y las materialized views respeten el modelo de datos y los límites de agregado; decide la estrategia avanzada
- **@developer** — Aplica los refactors y, vía el handoff, corre las migrations con `/db-migrate` (fuera de este skill)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Discover Schema

### GATE IN
- [ ] Se recibió `[target]` o el proyecto tiene schema/migrations/modelos descubribles (BLOCKING CONDITION ya validó que hay algo que analizar)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver `DIALECT` y `ORM`** desde `--dialect`/`.king/knowledge/stack.md`. Soportar los 6 dialectos: `postgres`, `mysql`, `mariadb`, `sqlite`, `mssql`, `oracle`
2. [ ] **Descubrir el schema** según `[target]` o por cascada: migration files (Flyway/Alembic/Prisma migrate/Knex/etc.), Prisma `schema.prisma`, modelos SQLAlchemy/TypeORM/Drizzle/GORM, o `\d`/DDL si hay conexión. Si nada de eso existe, **inferir** las tablas/columnas desde las queries del código
3. [ ] **Construir el inventario** — por tabla: columnas, PKs, **foreign keys** (origen → destino), e **índices existentes** (incluyendo los implícitos de PK/unique)
4. [ ] **Detectar `DB_MODE`** — verificar si `--connection` (o `DATABASE_URL` homóloga) está disponible. Marcar `DB_MODE = live | static`. Sin conexión NO es error: el análisis degrada a estático

### CHECKPOINT
- [ ] `DIALECT` resuelto (uno de los 6) — si ambiguo, asumido con WARN explícito
- [ ] Inventario del schema disponible: tablas, columnas, FKs, índices existentes (o marcado como `inferred` si vino de queries)
- [ ] `DB_MODE` definido (`live` o `static`)

### OUTPUTS
- Variables: `DIALECT`, `ORM`, `DB_MODE`, `SCHEMA_INVENTORY` (tablas/columnas/FKs/índices)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo descubrir el schema del proyecto.
Cause: `[target]` ausente, sin migrations/modelos detectables, `.king/knowledge/stack.md` sin motor de DB, y sin conexión para introspección.
Recovery:
  [ ] Option A: pedir al usuario el path al schema/migration/modelo o el DDL de las tablas relevantes
  [ ] Option B: inferir el schema desde las queries del código (Phase 2 primero) y marcar el inventario como `inferred` (PARTIAL)
  [ ] Option C: asumir `postgres` como dialecto por defecto y continuar con análisis tentativo, marcándolo en el output

---

## Phase 2: Collect Queries

### GATE IN
- [ ] Phase 1 completada — `SCHEMA_INVENTORY` (o `inferred`) disponible

### MUST DO
1. [ ] **Recolectar queries** del código: SQL crudo y llamadas ORM en repositories, services, API handlers, y archivos del `[target]` si es un directorio
2. [ ] **Transpilar ORM → SQL** (apoyándose en `knowledge/domain/orm-patterns.md`) lo necesario para identificar tablas, columnas en `WHERE`/`JOIN ... ON`/`ORDER BY`/`GROUP BY` y agregaciones
3. [ ] **Anotar contexto de loop** — toda llamada ORM dentro de `for`/`forEach`/`map`/comprehension se registra con archivo + líneas exactas como **candidato N+1** (a confirmar en Phase 4)
4. [ ] **Anotar frecuencia/criticidad estimada** por query (path caliente vs batch/cron) — alimenta la clasificación de caching de Phase 6

### CHECKPOINT
- [ ] Lista de queries recolectadas (SQL normalizado) con su ubicación (archivo + líneas)
- [ ] Candidatos N+1 anotados con líneas exactas (si los hay)
- [ ] Cada query con tablas/columnas y agregaciones extraídas

### OUTPUTS
- Variables: `QUERIES[]` (SQL + ubicación + frecuencia estimada), `LOOP_CANDIDATES[]`

### IF FAILS
ERROR: No se pudieron recolectar queries del proyecto.
Cause: no hay queries en el código, ORM no reconocido, o el `[target]` no contiene queries.
Recovery:
  [ ] Option A: pedir al usuario el directorio de repositories/services o queries representativas
  [ ] Option B: continuar SOLO con análisis de schema (FKs sin índice) y marcar la cobertura de queries como PARTIAL
  [ ] Option C: si el ORM no se reconoce, analizar las llamadas de forma estática buscando solo el patrón de loop (N+1) y marcar el resto inconcluso

---

## Phase 3: Analyze Coverage

### GATE IN
- [ ] `SCHEMA_INVENTORY` (Phase 1) y `QUERIES[]` (Phase 2) disponibles

### MUST DO
1. [ ] **Cruzar queries con índices existentes** — por cada query, verificar si las columnas de `WHERE`/`JOIN`/`ORDER BY` tienen índice de soporte
2. [ ] **Detectar FK sin índice** — toda foreign key del inventario cuya columna NO tenga índice es un hallazgo `major` (los JOINs sobre ella hacen full scan). Esta es la detección estrella del skill
3. [ ] **Detectar full scan candidatos** — `WHERE`/`JOIN` sin índice sobre tablas no triviales; oportunidad de índice **compuesto** cuando hay múltiples columnas en `WHERE` con AND
4. [ ] **Asignar severidad** por hallazgo: `critical` (full scan en path caliente o N+1 candidato), `major` (FK sin índice / índice compuesto faltante en query frecuente), `minor` (índice subóptimo)

### CHECKPOINT
- [ ] Cada query marcada como cubierta o NO cubierta por índice
- [ ] FKs sin índice listadas explícitamente (o "todas las FK tienen índice")
- [ ] Hallazgos con severidad asignada (o "cobertura completa — sin gaps")

### OUTPUTS
- Variables: `COVERAGE_FINDINGS[]` (tipo, severidad, tabla, columnas, evidencia), `FK_WITHOUT_INDEX[]`

### IF FAILS
ERROR: No se pudo cruzar queries con índices.
Cause: inventario `inferred` incompleto (no se conocen los índices existentes) o queries sin tablas resolubles.
Recovery:
  [ ] Option A: pedir al usuario el DDL / `\d {tabla}` de las tablas críticas para conocer índices existentes
  [ ] Option B: emitir hallazgos tentativos marcados como "verificar índices existentes antes de aplicar" (PARTIAL)
  [ ] Option C: limitar la cobertura a las FKs sin índice (detectables del schema) y diferir el resto

---

## Phase 4: N+1 Detection

### GATE IN
- [ ] `QUERIES[]` y `LOOP_CANDIDATES[]` disponibles (Phase 2)

### MUST DO
1. [ ] **Delegar a `/explain-query`** por cada `LOOP_CANDIDATE` — invocar el skill `/explain-query` con la query/llamada ORM y su contexto de loop para CONFIRMAR el N+1 (no re-implementar la heurística aquí)
2. [ ] **Consolidar el veredicto** — marcar cada candidato como `N+1 confirmado` o `descartado` según el resultado de `/explain-query`
3. [ ] **Recoger el refactor de batching** — `/explain-query` produce el refactor antes/después (`findMany` + `WHERE IN` / eager-load del ORM); incorporarlo al reporte
4. [ ] **Heredar el `source`** (`live`/`static`) del análisis de `/explain-query` para etiquetar la confiabilidad

### CHECKPOINT
- [ ] Cada `LOOP_CANDIDATE` evaluado por `/explain-query` (confirmado o descartado)
- [ ] N+1 confirmados con su refactor de batching antes/después
- [ ] `source` heredado y registrado por hallazgo

### OUTPUTS
- Variables: `N_PLUS_ONE[]` (ubicación + refactor + source)

### IF FAILS
ERROR: No se pudo confirmar el/los N+1 vía /explain-query.
Cause: `/explain-query` no disponible, o la llamada ORM no transpilable.
Recovery:
  [ ] Option A: si `/explain-query` no está, aplicar la heurística mínima de `knowledge/domain/orm-patterns.md` (misma query repetida en loop) y marcar el N+1 como tentativo
  [ ] Option B: reportar los candidatos no confirmados como "sospecha de N+1 — revisar manualmente" (PARTIAL)
  [ ] Option C: si no hubo `LOOP_CANDIDATES`, registrar "ningún N+1 detectado" y continuar

---

## Phase 5: Suggest Indexes

### GATE IN
- [ ] `COVERAGE_FINDINGS[]` y/o `FK_WITHOUT_INDEX[]` disponibles (Phase 3)

### MUST DO
1. [ ] **Generar `CREATE INDEX`** por cada FK sin índice y cada índice faltante, con sintaxis del `DIALECT` y naming canónico `idx_{table}_{columns}` (ej. `idx_orders_user_id`). Para múltiples columnas en `WHERE AND`, proponer índice compuesto en orden de selectividad
2. [ ] **Estimar impacto** — reducción de filas escaneadas y latencia antes/después en lenguaje natural (cualitativo si `source: static`)
3. [ ] **Evitar índices redundantes** — no proponer un índice ya cubierto por el prefijo de uno existente; señalar índices candidatos a eliminación si son duplicados
4. [ ] **Marcar cada índice** con la migration que generará el handoff (Phase 8)

### CHECKPOINT
- [ ] ≥1 `CREATE INDEX` por cada FK sin índice e índice faltante (o "no index needed")
- [ ] Naming canónico `idx_{table}_{columns}` aplicado a todos
- [ ] Sin índices redundantes propuestos
- [ ] Impacto estimado por índice

### OUTPUTS
- Variables: `INDEX_SUGGESTIONS[]` (`CREATE INDEX` statement + tabla + impacto)

### IF FAILS
ERROR: No se pudieron generar los CREATE INDEX.
Cause: hallazgos sin remediación clara o índices existentes desconocidos.
Recovery:
  [ ] Option A: pedir el DDL existente para no duplicar índices y reintentar
  [ ] Option B: emitir los `CREATE INDEX` marcados como "verificar índices existentes antes de aplicar" (PARTIAL)
  [ ] Option C: si no hay gaps, reportar "cobertura de índices completa — sin CREATE INDEX necesarios"

---

## Phase 6: Suggest Caching

### GATE IN
- [ ] `QUERIES[]` con frecuencia/criticidad estimada disponible (Phase 2)

### MUST DO
1. [ ] **Clasificar cada query** por 3 ejes: **frecuencia** estimada (alta = path caliente), **costo** (agregación / JOIN amplio / full scan) y **estabilidad del dato** (cuánto tolera estar desactualizado)
2. [ ] **Seleccionar candidatos a caching** — alta frecuencia + alto costo + dato tolerante a staleness (ej. query de dashboard agregada sobre `orders`). Descartar datos volátiles que requieren consistencia fuerte
3. [ ] **Definir store y TTL** por candidato — Redis o Memcached según el stack, con TTL justificado por la estabilidad del dato (ej. dashboard agregado → Redis, TTL 5 min)
4. [ ] **Generar código cache-aside** antes/después — read-through con `get`/`miss → query → set TTL` y la estrategia de invalidación (TTL passivo o invalidación en escritura), sin secretos literales

### CHECKPOINT
- [ ] Cada query clasificada por frecuencia / costo / estabilidad
- [ ] Candidatos a caching seleccionados con store + TTL justificado (o "ninguna query candidata")
- [ ] Código cache-aside antes/después presente por candidato
- [ ] Sin credenciales / connection strings literales en el código de caching

### OUTPUTS
- Variables: `CACHE_SUGGESTIONS[]` (query + store + TTL + código cache-aside + invalidación)

### IF FAILS
ERROR: No se pudieron generar sugerencias de caching.
Cause: sin información de frecuencia/criticidad o queries no clasificables.
Recovery:
  [ ] Option A: pedir al usuario qué queries son las más llamadas (path caliente) y reintentar
  [ ] Option B: sugerir caching SOLO para las agregaciones costosas evidentes (GROUP BY / COUNT amplio) y diferir el resto
  [ ] Option C: si ninguna query es candidata, reportar "sin candidatos a caching — datos volátiles o queries baratas"

---

## Phase 7: Suggest Advanced

### GATE IN
- [ ] `SCHEMA_INVENTORY` y `QUERIES[]` disponibles (Phases 1–2)

### MUST DO
1. [ ] **Evaluar partitioning** — si una tabla supera el umbral estimado (`> 10M` filas) y tiene un eje natural (fecha, tenant, rango), recomendar la estrategia (range/list/hash) con la columna de partición y la justificación del umbral
2. [ ] **Evaluar materialized views** — si hay queries de agregación costosas y recurrentes (`GROUP BY` amplio, ventanas, rollups) sobre datos tolerantes a staleness, recomendar una materialized view con su política de refresh
3. [ ] **Justificar SIEMPRE el umbral** — toda recomendación avanzada cita la evidencia (filas estimadas / coste de agregación). Sin evidencia, NO se recomienda
4. [ ] **Marcar dependencias** — si una sugerencia avanzada implica una migration (crear MV, particionar), marcarla para el handoff de Phase 8

### CHECKPOINT
- [ ] Partitioning evaluado con umbral citado (o "no aplica — ninguna tabla supera el umbral")
- [ ] Materialized views evaluadas con queries candidatas (o "no aplica — sin agregaciones costosas recurrentes")
- [ ] Cada recomendación avanzada con su justificación de umbral

### OUTPUTS
- Variables: `ADVANCED_SUGGESTIONS[]` (tipo, tabla/query, estrategia, umbral/evidencia, refresh-policy)

### IF FAILS
ERROR: No se pudieron evaluar las estrategias avanzadas.
Cause: sin estimación de tamaño de tablas ni de coste de agregación.
Recovery:
  [ ] Option A: pedir conteos aproximados de filas de las tablas grandes y reintentar
  [ ] Option B: reportar partitioning/MV como "no concluyente — falta estimación de volumen" (PARTIAL)
  [ ] Option C: omitir las sugerencias avanzadas (son opcionales) y reportar "no evaluadas por falta de datos de volumen"

---

## Phase 8: Generate Handoff

### GATE IN
- [ ] Al menos `INDEX_SUGGESTIONS[]` o `ADVANCED_SUGGESTIONS[]` con migration asociada (si no hay migrations sugeridas, esta fase emite un handoff vacío con nota)

### MUST DO
1. [ ] **Detectar el sistema de migraciones** del proyecto usando `knowledge/_inject/db-migrations-essentials.md` (Flyway/Alembic/Prisma migrate/Knex/Drizzle/etc.) para que el payload sea consumible por `/db-migrate`
2. [ ] **Armar el payload de handoff a `/db-migrate`** — un bloque estructurado con: `dialect`, `migration_system` detectado, y la lista ordenada de migrations (cada una con `name` canónico, `up` = `CREATE INDEX`/DDL de MV/partition, y `down` = rollback)
3. [ ] **Ordenar las migrations** por dependencia (índices primero, luego MV/partitioning que pueden depender de ellos)
4. [ ] **Marcar el handoff como propuesta** — el developer DEBE confirmarlo y correrlo con `/db-migrate`; este skill NO lo ejecuta. Incluir el comando sugerido `/db-migrate` con el payload
5. [ ] **Componer el reporte final** — inventario + cobertura + N+1 + índices + caching + avanzado + payload de handoff, etiquetando todo con su `source` (`live`/`static`)

### CHECKPOINT
- [ ] `migration_system` detectado (o WARN "no detectado — payload genérico SQL")
- [ ] Payload de handoff a `/db-migrate` generado con migrations `up`/`down` ordenadas y naming canónico
- [ ] Handoff marcado explícitamente como propuesta (no aplicado)
- [ ] Reporte final ensamblado con TODOS los REQUIRED OUTPUTS
- [ ] Sin credenciales / connection strings literales en el payload

### OUTPUTS
- Artefacto: reporte de optimización + **payload de handoff a `/db-migrate`**
- Variable: `MIGRATION_HANDOFF` (payload estructurado)

### IF FAILS
ERROR: No se pudo armar el payload de handoff a /db-migrate.
Cause: sistema de migraciones no detectable o migrations no resolubles.
Recovery:
  [ ] Option A: emitir el payload como SQL plano (`CREATE INDEX` + DDL) con nota de que `/db-migrate` lo envuelva en el sistema del proyecto
  [ ] Option B: pedir al usuario el sistema de migraciones (Flyway/Alembic/Prisma/etc.) y reintentar
  [ ] Option C: entregar las migrations individualmente con `up`/`down` y diferir la integración al runner de `/db-migrate`

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Inventario del schema (tablas/columnas/FKs/índices)
  - [ ] Reporte de cobertura (FK sin índice + WHERE/JOIN sin índice)
  - [ ] N+1 confirmados vía `/explain-query` (o "ninguno")
  - [ ] `CREATE INDEX` por índice faltante con naming `idx_{table}_{columns}` (o "no index needed")
  - [ ] Sugerencias de caching con store + TTL + código cache-aside (o "sin candidatos")
  - [ ] Sugerencias avanzadas (partitioning / MV) con umbral justificado (o "no aplica")
  - [ ] Payload de handoff a `/db-migrate` con migrations `up`/`down`
- [ ] Cada análisis etiquetado con su `source` (`live` | `static`)
- [ ] Ningún `CREATE INDEX` / DDL fue aplicado a la DB (solo propuesto vía handoff)
- [ ] El N+1 fue confirmado por `/explain-query`, no re-implementado inline
- [ ] Ninguna credencial / connection string literal en el output ni en el payload
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(sin gaps de cobertura ni N+1 = FORTIFIED; FK/índices faltantes, N+1 o caching pendiente = CONDITIONAL; nunca BREACHED por sí mismo — no aplica cambios)_ |
| Artifacts | _(reporte de optimización + payload de handoff a `/db-migrate`; ninguno persistente salvo session document)_ |
| Next Recommended | `/db-migrate` (king-infra, aplicar el payload de migrations) o `/refactor` (corregir N+1) |
| Risks | _(análisis static sin DB = estimaciones cualitativas; índices/avanzado sugeridos sin conocer DDL/volumen real; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Índices / migrations sugeridas en el handoff | `/db-migrate` (king-infra) — confirmar y correr el payload de migrations |
| N+1 confirmado | `/refactor` el loop a `findMany` + `WHERE IN`, luego re-`/explain-query` |
| Caching aceptado | `/build` o `/refactor` — implementar el cache-aside con el store/TTL sugerido |
| Partitioning / MV recomendado | `/db-migrate` (crear MV/partición) + revisar con `@architect` |
| Análisis fue `static` (sin DB) | re-ejecutar con `--connection` para `EXPLAIN` real vía `/explain-query` |
| DB saludable | continuar; sin acción requerida |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Detección de schema (cascada)

El skill descubre el modelo de datos evaluando en este orden y usando el primer match:

| # | Fuente | Indicadores | Nota |
|---|--------|-------------|------|
| 1 | Migration files | `*/migrations/*.sql`, Flyway `V*__`, Alembic `versions/*.py`, Prisma `migrations/*/migration.sql`, Knex/Drizzle | Fuente más fiel del schema versionado |
| 2 | ORM schema/models | `schema.prisma`, modelos SQLAlchemy/TypeORM/Drizzle/GORM | Mapea entidades → tablas/columnas/relaciones |
| 3 | Introspección live | `--connection` disponible → `\d` / `information_schema` | Solo si hay conexión; el más preciso para índices reales |
| 4 | Inferencia desde queries | tablas/columnas deducidas del SQL del código | Marca el inventario como `inferred` (PARTIAL) |

### FK sin índice — la detección estrella

En la mayoría de los motores, declarar una `FOREIGN KEY` **NO** crea automáticamente un índice sobre la
columna origen (PostgreSQL y Oracle no lo hacen; MySQL/InnoDB sí lo crea). El resultado: cada `JOIN` sobre
esa FK y cada borrado en cascada hace un full scan. Es el hallazgo de mayor ratio impacto/esfuerzo:

```
FK detectada:  orders.user_id → users(id)   (sin índice en orders.user_id)
Hallazgo:      [major] FK sin índice — JOIN orders↔users hace Seq Scan sobre orders
Remediación:   CREATE INDEX idx_orders_user_id ON orders(user_id);
```

### Naming canónico de índices

| Patrón | Ejemplo | Cuándo |
|--------|---------|--------|
| `idx_{table}_{column}` | `idx_orders_user_id` | Índice de una columna (FK típica) |
| `idx_{table}_{col1}_{col2}` | `idx_orders_status_created_at` | Índice compuesto (orden por selectividad) |
| `uniq_{table}_{column}` | `uniq_users_email` | Índice único |

### Clasificación de caching (3 ejes)

| Eje | Pregunta | Favorece caching |
|-----|----------|------------------|
| Frecuencia | ¿Cuántas veces por minuto se llama? | Alta (path caliente) |
| Costo | ¿Agregación / JOIN amplio / full scan? | Alto |
| Estabilidad | ¿Cuánto tolera el dato estar desactualizado? | Alta (tolerante a staleness) |

> Candidato ideal = **alta frecuencia + alto costo + tolerante a staleness** (ej. dashboard agregado).
> Anti-candidato = dato volátil con consistencia fuerte (saldo de cuenta, stock en checkout).

Ejemplo cache-aside (dashboard agregado sobre `orders`, Redis TTL 5 min):

```
// Antes: cada request corre la agregación completa
const stats = await db.query(DASHBOARD_AGG_SQL);     // ~300ms, full scan + GROUP BY

// Después (cache-aside): get → miss → query → set TTL
let stats = await redis.get("dashboard:orders:30d");
if (!stats) {
  stats = await db.query(DASHBOARD_AGG_SQL);
  await redis.set("dashboard:orders:30d", JSON.stringify(stats), "EX", 300); // TTL 5 min
} else {
  stats = JSON.parse(stats);
}
// Invalidación: TTL pasivo (5 min) o DEL "dashboard:orders:30d" al crear una orden
```

### Umbrales de estrategias avanzadas

| Estrategia | Umbral / disparador | Justificación |
|------------|---------------------|---------------|
| Partitioning | tabla `> 10M` filas estimadas + eje natural (fecha/tenant/rango) | El índice ya no alcanza; particionar acota el scan a la partición relevante |
| Materialized View | agregación costosa recurrente (`GROUP BY` amplio, rollups) + dato tolerante a staleness | Precompute periódico vs recomputar en cada request |

> Toda recomendación avanzada DEBE citar su evidencia (filas / coste). Sin evidencia, no se recomienda.

### Formato del payload de handoff a `/db-migrate`

El skill genera un payload estructurado que `/db-migrate` (king-infra) consume directamente. Ejemplo:

```yaml
# Handoff → /db-migrate (king-infra) — PROPUESTA (requiere confirmación del developer)
dialect: postgres
migration_system: prisma        # detectado vía db-migrations-essentials.md
migrations:
  - name: add_idx_orders_user_id
    reason: "FK orders.user_id → users(id) sin índice — JOIN hace Seq Scan"
    up:   "CREATE INDEX idx_orders_user_id ON orders(user_id);"
    down: "DROP INDEX idx_orders_user_id;"
  - name: create_mv_orders_dashboard_30d
    reason: "Agregación de dashboard recurrente y costosa"
    up:   "CREATE MATERIALIZED VIEW mv_orders_dashboard_30d AS SELECT ...;"
    down: "DROP MATERIALIZED VIEW mv_orders_dashboard_30d;"
# Ejecutar con:  /db-migrate --from-handoff <payload>
```

> El payload es una PROPUESTA. `/db-optimize` NO lo aplica: el developer lo confirma y lo corre con
> `/db-migrate` de king-infra, que lo envuelve en el sistema de migraciones del proyecto.

### Reuso de `/explain-query` (N+1)

La confirmación de N+1 NO se re-implementa aquí: Phase 4 delega en `/explain-query`
(`skills/explain-query/SKILL.md`), que parsea la query, corre `EXPLAIN` (o análisis estático), confirma el
patrón de loop y produce el refactor de batching antes/después. `/db-optimize` solo orquesta la llamada y
consolida el resultado. Anti-patrones de ORM (N+1, Query in Loop, God/Anemic Repository) en
`knowledge/domain/orm-patterns.md`.

### Degradación sin conexión DB (análisis estático LLM)

Cuando `DB_MODE = static` (sin `--connection`/`DATABASE_URL`), el skill NO falla: infiere la cobertura, las
FKs sin índice (detectables del schema) y los candidatos de caching/avanzado de forma cualitativa, marca
TODO con `source: static (no DB connection)`, y recomienda re-ejecutar con conexión para validar planes
reales vía `/explain-query`. Los `CREATE INDEX`, el código de caching y el payload de handoff NO requieren
conexión, así que se generan igual.

### Relación con otros skills del arco M04 y con king-infra

`/db-optimize` (Database Excellence, M-31) es el punto de entrada de la salud de la DB: reusa
`/explain-query` (M-04) para N+1 y entrega su salida como **handoff explícito a `/db-migrate`** de
king-infra (que aplica las migrations). Se complementa con `/optimize` (aplicar refactors) y `/refactor`
(corregir N+1). El delta spec está en `openspec/changes/m04-architecture/specs/db-optimize/spec.md`.
