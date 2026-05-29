---
name: explain-query
version: 2.0
api_version: 1.0.0
description: "Analiza una query SQL o llamada ORM con EXPLAIN PLAN. Detecta full table scans, índices faltantes y N+1. Genera CREATE INDEX listos para usar y refactors de batching. Usar cuando se necesite: explicar una query, diagnosticar una query lenta, detectar Seq Scan costoso, encontrar índices faltantes en WHERE/JOIN, o detectar queries en loops (N+1). Degrada graciosamente sin conexión DB usando análisis estático LLM."
---

# /explain-query — EXPLAIN PLAN, Full Table Scans, Índices y N+1

Analiza una query SQL o una llamada ORM. Detecta el dialecto, transpila el ORM a SQL si hace falta,
ejecuta `EXPLAIN` real cuando hay conexión DB (o realiza **análisis estático LLM** cuando no la hay),
identifica full table scans / Seq Scan costosos, ausencia de índices en `WHERE`/`JOIN` y patrones
**N+1**. Produce sugerencias concretas: `CREATE INDEX` listos para usar y refactors de batching.
Alimenta la capa **CASTLE T** (check "no queries in loops") y es invocable por `@performance` durante `/review`.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack y ORM del proyecto — fuente del dialecto auto-detectado | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de índices y migraciones | No | project |
| `knowledge/domain/orm-patterns.md` | 4 patrones + 4 anti-patrones (N+1, Query in Loop) + guías por ORM (custom: este skill detecta esos anti-patrones) | No | framework |
| `knowledge/_inject/performance-essentials.md` | Heurísticas de coste de query y latencia | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[query|file]` ni se detecta ninguna query en el archivo indicado
- [ ] El input no es una query SQL ni una llamada ORM reconocible (ej. texto plano arbitrario)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA ejecutar `EXPLAIN ANALYZE` (que CORRE la query) sobre `staging`/`prod` sin confirmación explícita del usuario — usar `EXPLAIN` plano por defecto
- NUNCA ejecutar la query analizada como parte del flujo (solo `EXPLAIN`; `EXPLAIN ANALYZE` solo bajo `--mode explain-analyze` confirmado)
- NUNCA modificar el esquema de la DB ni aplicar los `CREATE INDEX` sugeridos — solo proponerlos
- NUNCA incluir credenciales/connection strings literales en el output (usar variables de entorno / `{{SLOT}}`)
- NUNCA fallar con error si no hay conexión DB — degradar a análisis estático LLM y marcar el output como `static`
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] EXPLAIN PLAN parseado con interpretación en lenguaje natural (real o estático LLM)
- [ ] Lista de problemas detectados: full table scan / Seq Scan costoso, index not used, N+1
- [ ] Sugerencias de índices concretas con sentencia `CREATE INDEX` lista para usar
- [ ] Si hay N+1: patrón de batching sugerido con código antes/después
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Detect    (Parse    (Run      (Analyze) (Suggest) (Session)  (Guide)
          dialect)   query)    EXPLAIN)
```

### PARÁMETROS
```
/explain-query [query|file] [--dialect postgres|mysql|sqlite|mssql|oracle|mariadb] [--mode explain|explain-analyze]
```
- `[query|file]`: SQL string entre comillas, una llamada ORM, o la ruta a un archivo con la(s) query(s)
- `--dialect`: fuerza el dialecto (default: auto-detectado desde `.king/knowledge/stack.md`)
- `--mode`: `explain` (default, no corre la query) o `explain-analyze` (CORRE la query — requiere confirmación y nunca en prod sin OK)

---

## CASTLE activo: _-_-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> Alimenta CASTLE T con el check "no queries in loops" (N+1). Sin gate de bloqueo propio: el veredicto es advisory salvo que `@performance` lo eleve durante `/review`.

## Agentes
- **@performance** — Agente principal: interpreta el EXPLAIN PLAN, evalúa coste y detecta N+1
- **@architect** — Valida que los índices sugeridos respeten el modelo de datos y los límites de agregado
- **@developer** — Aplica los refactors de ORM y las migraciones de índice sugeridas (fuera de este skill)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Dialect

### GATE IN
- [ ] Se recibió `[query|file]` (BLOCKING CONDITION ya validó que existe input)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Leer `.king/knowledge/stack.md`** y extraer el motor de DB y el ORM (Prisma, Drizzle, SQLAlchemy, TypeORM, Hibernate, GORM)
2. [ ] **Resolver dialecto** desde `--dialect` si se pasó; si no, inferirlo del stack. Soportar los 6 dialectos: `postgres`, `mysql`, `mariadb`, `sqlite`, `mssql`, `oracle`
3. [ ] **Detectar conexión DB** — verificar si hay variable de entorno de conexión disponible (`DATABASE_URL` u homóloga). Marcar `DB_MODE = live | static`
4. [ ] **Resolver `--mode`** — `explain` por defecto; si `explain-analyze`, marcar para confirmación en Phase 3

### CHECKPOINT
- [ ] `DIALECT` resuelto (uno de los 6) — si ambiguo, asumido con WARN explícito
- [ ] `DB_MODE` definido (`live` o `static`)
- [ ] `MODE` definido (`explain` o `explain-analyze`)

### OUTPUTS
- Variables: `DIALECT`, `DB_MODE`, `MODE`, `ORM`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el dialecto de la query.
Cause: `.king/knowledge/stack.md` ausente o sin motor de DB declarado, y `--dialect` no provisto.
Recovery:
  [ ] Option A: pedir al usuario el dialecto (`--dialect`) entre los 6 soportados
  [ ] Option B: inferir el dialecto desde la sintaxis de la query (`$1` → postgres, `?` → mysql/sqlite, `@p1` → mssql, `:1` → oracle) y continuar con WARN
  [ ] Option C: asumir `postgres` (default más común), marcar el análisis como tentativo y continuar

---

## Phase 2: Parse Query

### GATE IN
- [ ] `DIALECT` resuelto (Phase 1)

### MUST DO
1. [ ] **Clasificar el input** — SQL string, llamada ORM, o archivo. Si es archivo, extraer TODAS las queries/llamadas ORM (incluyendo las dentro de loops)
2. [ ] **Transpilar ORM → SQL** si el input es una llamada ORM, usando el conocimiento del ORM detectado (`knowledge/domain/orm-patterns.md`). Registrar la query SQL resultante
3. [ ] **Normalizar** placeholders y extraer las cláusulas relevantes: tablas, columnas en `WHERE`, `JOIN ... ON`, `ORDER BY`, `GROUP BY`
4. [ ] **Marcar contexto de loop** — si una llamada ORM aparece dentro de `for`/`forEach`/`map`/comprehension, anotar líneas exactas como candidato N+1

### CHECKPOINT
- [ ] Query(s) SQL normalizada(s) disponible(s) para EXPLAIN
- [ ] Si era ORM: transpilación SQL registrada
- [ ] Candidatos N+1 anotados con líneas exactas (si los hay)

### OUTPUTS
- Variables: `SQL_QUERIES[]`, `LOOP_CONTEXT[]` (file + líneas)

### IF FAILS
ERROR: No se pudo parsear la query a SQL.
Cause: sintaxis ORM no reconocida para el ORM detectado, o SQL malformado.
Recovery:
  [ ] Option A: pedir al usuario la query SQL equivalente directamente
  [ ] Option B: analizar la llamada ORM de forma estática (sin transpilar) buscando solo el patrón N+1 y marcar el análisis de índices como PARTIAL
  [ ] Option C: si el archivo tiene múltiples queries y una falla, continuar con las demás y reportar la fallida

---

## Phase 3: Run EXPLAIN

### GATE IN
- [ ] `SQL_QUERIES[]` no vacío (Phase 2)

### MUST DO
1. [ ] **Si `DB_MODE = live`**: ejecutar `EXPLAIN` (o `EXPLAIN (FORMAT JSON)` en postgres) por cada query usando la conexión del entorno. Si `MODE = explain-analyze`, **confirmar con el usuario** y NUNCA correrlo contra prod sin OK explícito
2. [ ] **Si `DB_MODE = static`**: realizar **análisis estático LLM** — inferir el plan probable (Seq Scan vs Index Scan) a partir de la estructura de la query, las columnas filtradas y los índices presumibles. Marcar TODO el output con `source: static (no DB connection)`
3. [ ] **Capturar el plan** por query: tipo de scan, filas estimadas, coste, uso de índices, tipo de join

### CHECKPOINT
- [ ] Plan capturado por cada query (real o estático)
- [ ] Cada plan etiquetado con su `source` (`live` | `static`)
- [ ] Si `explain-analyze` se usó: confirmación del usuario registrada y entorno no-prod verificado

### OUTPUTS
- Variables: `PLANS[]` (con `source` por plan)

### IF FAILS
ERROR: No se pudo ejecutar EXPLAIN contra la DB.
Cause: conexión rechazada, credenciales ausentes, o la query referencia tablas inexistentes en el entorno.
Recovery:
  [ ] Option A: degradar a `DB_MODE = static` y continuar con análisis LLM (NO es un error — es el comportamiento de degradación esperado)
  [ ] Option B: verificar `DATABASE_URL`/credenciales vía variable de entorno y reintentar una vez
  [ ] Option C: si las tablas no existen en el entorno actual, marcar como static y notar la limitación en el output

---

## Phase 4: Analyze

### GATE IN
- [ ] `PLANS[]` disponible (Phase 3)

### MUST DO
1. [ ] **Detectar full table scan / Seq Scan costoso** — flag si hay Seq Scan con `> 1000` filas estimadas o sin filtro selectivo
2. [ ] **Detectar índices faltantes** — columnas en `WHERE`/`JOIN`/`ORDER BY` sin índice de soporte; identificar oportunidad de índice compuesto cuando hay múltiples columnas en `WHERE` con AND
3. [ ] **Detectar índices no usados** — el plan filtra por una columna indexada pero el optimizador elige Seq Scan (estadísticas obsoletas, función sobre la columna, type mismatch, leading-column wildcard)
4. [ ] **Detectar N+1** — usar `LOOP_CONTEXT[]`: una llamada ORM ejecutada por iteración es N+1. Confirmar que la misma query se repite con distinto parámetro
5. [ ] **Asignar severidad** por hallazgo: `critical` (Seq Scan > 1000 filas en path caliente o N+1 confirmado), `major` (índice compuesto faltante en query frecuente), `minor` (índice subóptimo o mejora marginal)

### CHECKPOINT
- [ ] Cada plan clasificado: scan type + filas + coste interpretados en lenguaje natural
- [ ] Lista de problemas detectados con severidad (o "No issues detected")
- [ ] N+1 evaluado contra `LOOP_CONTEXT[]`

### OUTPUTS
- Variables: `FINDINGS[]` (tipo, severidad, ubicación, evidencia)

### IF FAILS
ERROR: No se pudo interpretar el plan.
Cause: formato de EXPLAIN inesperado para el dialecto o plan vacío.
Recovery:
  [ ] Option A: caer al análisis estático LLM del SQL para la(s) query(s) sin plan interpretable
  [ ] Option B: reportar los hallazgos parciales que sí se pudieron derivar y marcar el resto como inconcluso (PARTIAL)
  [ ] Option C: mostrar el plan crudo al usuario y pedir contexto del esquema (índices existentes)

---

## Phase 5: Suggest

### GATE IN
- [ ] `FINDINGS[]` disponible (Phase 4)

### MUST DO
1. [ ] **Generar `CREATE INDEX`** por cada índice faltante, con sintaxis del `DIALECT` y naming `idx_{tabla}_{col1}_{col2}`. Para múltiples columnas en `WHERE AND`, proponer índice compuesto en orden de selectividad
2. [ ] **Estimar impacto** — latencia antes/después esperada y reducción de filas escaneadas en lenguaje natural (cualitativo si `source: static`)
3. [ ] **Si hay N+1**: generar refactor de batching con código **antes/después** — reemplazar el loop de `findById` por un `findMany` + `WHERE IN` (o `include`/eager-load del ORM), mostrando el patrón del ORM detectado
4. [ ] **Componer el reporte** — EXPLAIN PLAN parseado + interpretación + lista de problemas + `CREATE INDEX` + refactor N+1. Etiquetar claramente si fue `live` o `static`

### CHECKPOINT
- [ ] ≥1 `CREATE INDEX` por cada índice faltante detectado (o "no index needed")
- [ ] Si hubo N+1: refactor con código antes/después presente
- [ ] Reporte final ensamblado con todos los REQUIRED OUTPUTS
- [ ] Ninguna credencial/connection string literal en el output

### OUTPUTS
- Reporte de análisis (terminal) con plan, problemas, índices y refactor

### IF FAILS
ERROR: No se pudieron generar sugerencias accionables.
Cause: hallazgos sin remediación clara o esquema desconocido (no se sabe qué índices ya existen).
Recovery:
  [ ] Option A: pedir al usuario el DDL de la(s) tabla(s) o `\d {tabla}` para conocer índices existentes
  [ ] Option B: emitir sugerencias tentativas marcadas como "verificar índices existentes antes de aplicar"
  [ ] Option C: si no hay problemas detectados, reportar PASS con "query saludable — sin índices faltantes ni N+1"

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] EXPLAIN PLAN parseado + interpretación en lenguaje natural
  - [ ] Lista de problemas (full table scan / index not used / N+1) o "No issues detected"
  - [ ] `CREATE INDEX` por índice faltante (o "no index needed")
  - [ ] Refactor de batching antes/después si hubo N+1
- [ ] Cada análisis etiquetado con su `source` (`live` | `static`)
- [ ] `EXPLAIN ANALYZE` solo se usó con confirmación y nunca en prod sin OK
- [ ] Ningún `CREATE INDEX` fue aplicado a la DB (solo propuesto)
- [ ] Ninguna credencial literal en el output
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(sin issues=FORTIFIED; índices faltantes/Seq Scan=CONDITIONAL; N+1 crítico=CONDITIONAL, BREACHED solo si @performance lo eleva en /review)_ |
| Artifacts | _(reporte de análisis; ninguno persistente salvo session document)_ |
| Next Recommended | `/optimize` (aplicar índices/refactor) o `/refactor` (corregir N+1) |
| Risks | _(análisis static sin DB = estimaciones cualitativas; índices sugeridos sin conocer DDL existente; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Índices faltantes detectados | `/optimize` — aplicar `CREATE INDEX` vía migración |
| N+1 confirmado | `/refactor` el loop a `findMany` + `WHERE IN`, luego re-`/explain-query` |
| Seq Scan costoso persiste con índice | `/optimize` (revisar estadísticas, query rewrite) o M08 DB Excellence |
| Análisis fue `static` (sin DB) | re-ejecutar con conexión (`DATABASE_URL`) para `EXPLAIN` real |
| Query saludable | continuar; sin acción requerida |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Dialectos soportados y sintaxis de EXPLAIN

| Dialecto | Comando EXPLAIN | Placeholder | Nota |
|----------|-----------------|-------------|------|
| `postgres` | `EXPLAIN (FORMAT JSON)` / `EXPLAIN ANALYZE` | `$1` | Seq Scan vs Index Scan; `pg_stat` para estadísticas |
| `mysql` | `EXPLAIN FORMAT=JSON` / `EXPLAIN ANALYZE` (8.0+) | `?` | `type: ALL` = full table scan; `key` = índice usado |
| `mariadb` | `EXPLAIN FORMAT=JSON` / `ANALYZE` | `?` | Similar a MySQL; `Using filesort`/`Using temporary` = alarma |
| `sqlite` | `EXPLAIN QUERY PLAN` | `?` | `SCAN TABLE` = full scan; `SEARCH ... USING INDEX` = ok |
| `mssql` | `SET SHOWPLAN_XML ON` / Actual Execution Plan | `@p1` | `Table Scan`/`Clustered Index Scan` = alarma |
| `oracle` | `EXPLAIN PLAN FOR ...` + `DBMS_XPLAN.DISPLAY` | `:1` | `TABLE ACCESS FULL` = full scan |

### Anti-patrón N+1 — patrón de batching (referencia ORM)

El N+1 ocurre cuando se ejecuta 1 query para obtener N filas y luego 1 query por cada fila (1 + N).
El batching lo colapsa a 2 queries (1 + 1):

| ORM | Antes (N+1) | Después (batch) |
|-----|-------------|-----------------|
| Prisma | `for (u of users) await prisma.order.findMany({where:{userId:u.id}})` | `prisma.user.findMany({include:{orders:true}})` |
| Drizzle | loop con `db.select().where(eq(orders.userId, id))` | `db.query.users.findMany({with:{orders:true}})` |
| TypeORM | loop con `repo.findOne({where:{id}})` | `repo.find({where:{id: In(ids)}})` |
| SQLAlchemy | loop con `session.query(Order).filter_by(user_id=id)` | `selectinload(User.orders)` / `WHERE user_id IN (...)` |
| Hibernate | acceso lazy en loop | `JOIN FETCH` / `@BatchSize` |
| GORM | loop con `db.Where("user_id = ?", id).Find(&o)` | `db.Preload("Orders").Find(&users)` |

Detalle completo de anti-patrones (N+1, God Repository, Query in Loop, Anemic Repository) y guías por
ORM en `knowledge/domain/orm-patterns.md`.

### Heurísticas de severidad

| Hallazgo | Umbral | Severidad |
|----------|--------|-----------|
| Seq Scan / full table scan | `> 1000` filas estimadas en path caliente | `critical` |
| N+1 confirmado | llamada ORM dentro de loop, misma query repetida | `critical` |
| Índice compuesto faltante | `WHERE col1 = ? AND col2 = ?` en query frecuente, sin índice | `major` |
| Índice subóptimo | índice existe pero no es óptimo (orden de columnas, cobertura) | `minor` |

### Degradación sin conexión DB (análisis estático LLM)

Cuando `DB_MODE = static` (sin `DATABASE_URL` o conexión rechazada), el skill NO falla. En su lugar:
- Infiere el plan probable a partir de la estructura del SQL y las columnas filtradas
- Marca TODO el output con `source: static (no DB connection)` para que el usuario sepa que las estimaciones son cualitativas
- Sigue generando `CREATE INDEX` y refactors N+1 (estos no requieren ejecutar la query)
- Recomienda re-ejecutar con conexión para validar el plan real (`EXPLAIN`)

### Integración con @performance y CASTLE T

`agents/performance.md` invoca `/explain-query` automáticamente cuando detecta una llamada ORM dentro
de un loop durante `/review`. El check CASTLE T "no queries in loops" se marca como violación cuando se
confirma un N+1, con la sugerencia de `findMany` + `WHERE IN`. Ver el delta spec en
`openspec/changes/m04-architecture/specs/orm-patterns/spec.md`.
