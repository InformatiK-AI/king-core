---
name: event-sourcing
version: 2.0
api_version: 1.0.0
description: "Configura Event Sourcing para un aggregate: event store schema (id, aggregate_id, aggregate_type, event_type, payload, sequence, created_at), rehydration por apply methods, snapshot strategy cada N eventos, projections, projection rebuild command y tests (rehydration, snapshot, rebuild). Soporta postgres/eventstore/dynamodb/in-memory. Usar cuando se necesite: montar un event store, event-sourcear un aggregate, agregar projections, snapshots o rebuild. HACE 3 PREGUNTAS de validación (audit trail inmutable? time-travel? CQRS activo?) y RECHAZA proceder si hay < 2 'sí', sugiriendo un audit log simple como alternativa."
---

# /event-sourcing — Event Store, Rehydration, Snapshots y Projections

Configura **Event Sourcing** para un aggregate: el estado deja de guardarse como snapshot actual y pasa
a derivarse de la **secuencia inmutable de eventos** que lo produjeron. Genera el **event store schema**
(append-only), la **rehydration** del aggregate vía `apply` methods (fold sobre los eventos), una
**snapshot strategy** (cada N eventos, configurable), una o más **projections** para las queries comunes,
un **projection rebuild command** (reconstruye desde el evento #1) y los **tests** de rehydration,
snapshot y rebuild.

> **Veto de adopción innegociable**: Event Sourcing es de los patrones más difíciles de operar bien.
> Antes de scaffoldear NADA, el skill HACE 3 PREGUNTAS de validación y RECHAZA proceder con menos de 2
> "sí", sugiriendo un **audit log simple** (una tabla `audit_events` que registra cambios sin reconstruir
> estado desde eventos). ES sin audit crítico, sin time-travel y sin CQRS es complejidad operativa
> (replay, snapshots, versionado, eventual consistency) sin retorno. Ver `knowledge/domain/architecture-patterns.md` §5.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack y lenguaje del proyecto — fuente del scaffolding y del store backend por defecto | Yes | project |
| `.king/knowledge/architecture.md` | Arquitectura existente y decisiones previas — detecta si ya hay CQRS, aggregates o un event store montado | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de eventos, tablas, migraciones y tests | No | project |
| `knowledge/domain/architecture-patterns.md` | Clean/Hexagonal/DDD/CQRS/ES con trade-offs (custom: este skill materializa el patrón Event Sourcing del §5 — event store append-only, fold para rehydration, snapshot como cache, projection rebuild — y aplica el veto de adopción del Mapa de Decisión Rápida) | Yes | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[aggregate-name]` (el nombre del aggregate a event-sourcear es obligatorio)
- [ ] El stack no es resoluble (ni `--stack` implícito vía store backend ni `.king/knowledge/stack.md` declaran lenguaje)
- [ ] Las 3 preguntas de validación obtuvieron **< 2 "sí"** (audit trail inmutable? / time-travel? / CQRS activo?) → RECHAZAR el scaffolding y sugerir audit log simple
- [ ] Ya existe un event store para ese `[aggregate-name]` y el usuario NO confirmó extenderlo/sobrescribir

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA proceder con el scaffolding de Event Sourcing si hubo **< 2 "sí"** en las 3 preguntas de validación — en ese caso sugerir SIEMPRE un audit log simple como alternativa y detener
- NUNCA generar el event store con operaciones `UPDATE` o `DELETE` sobre un evento existente — el store es append-only e inmutable; para corregir se emite un evento compensatorio nuevo
- NUNCA tratar el snapshot como fuente de verdad — el snapshot es CACHE (optimización); la fuente de verdad es SIEMPRE la secuencia de eventos
- NUNCA generar `apply` methods con efectos secundarios (I/O, llamadas externas): `apply(event)` solo muta el estado en memoria de forma pura para que el replay sea determinista
- NUNCA generar eventos sin `sequence` monótona por aggregate ni sin `created_at` — sin ellos no hay rehydration ordenada ni time-travel
- NUNCA generar una projection sin su rebuild command — una projection que no se puede reconstruir desde cero es una bomba de tiempo operativa
- NUNCA hardcodear el valor de N del snapshot, el store backend, rutas absolutas ni nombres de proyecto — usar `--snapshot-every`, `--store-backend`, `.king/knowledge/stack.md` y `{{SLOT}}`
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Resultado de las 3 preguntas de validación registrado (conteo de "sí" y veredicto PROCEED/REJECT)
- [ ] Event store schema con columnas: `id`, `aggregate_id`, `aggregate_type`, `event_type`, `payload`, `sequence`, `created_at` (append-only)
- [ ] Aggregate rehydration desde eventos: `apply(event)` methods + factory que hace fold del stream
- [ ] Snapshot strategy cada N eventos (N configurable vía `--snapshot-every`) con snapshot store
- [ ] ≥1 Projection para las queries más comunes del aggregate
- [ ] Projection rebuild command (reconstruye la(s) projection(s) desde el evento #1)
- [ ] Tests: rehydration (fold reproduce el estado), snapshot (cargar desde snapshot + eventos posteriores), projection rebuild (rebuild reproduce la vista)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase N+1 → Phase N+2
(Context)(Validate  (Resolve   (Event    (Rehydr.+ (Project. (Tests)   (Session)  (Guide)
          3 Qs —    backend+   store     snapshot) +rebuild)
          gate)     events)    schema)
```

### PARÁMETROS
```
/event-sourcing [aggregate-name] [--events e1,e2,...] [--store-backend postgres|eventstore|dynamodb|in-memory] [--snapshot-every N]
```
- `[aggregate-name]`: nombre del aggregate a event-sourcear (ej. `Order`, `Account`). Obligatorio
- `--events`: lista de domain events (ej. `OrderCreated,ItemAdded,OrderPaid`). Default: detectados desde un `/ddd-tactical` previo o inferidos del aggregate
- `--store-backend`: backend del event store. Default: `postgres`. Opciones: `postgres`, `eventstore`, `dynamodb`, `in-memory`
- `--snapshot-every`: cada cuántos eventos se persiste un snapshot. Default: `100`

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) es la capa central: el skill materializa un store append-only inmutable con
> rehydration por fold y snapshots/versionado, lo que CASTLE A vigila ("Event Sourcing sin versionado/
> snapshots = bomba de tiempo"). CASTLE T (Testing) cubre los tests de rehydration, snapshot y rebuild.
> Veredicto CONDITIONAL si las preguntas dieron exactamente 2/3 "sí" (adopción al límite) o si no se
> generó snapshot strategy. BREACHED si el store permite UPDATE/DELETE de eventos o si se procedió con < 2 "sí".

## Agentes
- **@architect** — Agente principal: conduce las 3 preguntas de validación, aplica el veto de adopción, decide el diseño del event store y la snapshot strategy, redacta el ADR si aplica
- **@developer** — Genera el event store schema, los `apply` methods de rehydration, las projections y el rebuild command
- **@qa** — Valida que el replay sea determinista (rehydration reproduce el estado), que el snapshot sea solo cache y que el rebuild reconstruya la projection desde cero

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Validate Adoption (3 Questions Gate)

### GATE IN
- [ ] Se recibió `[aggregate-name]` (BLOCKING CONDITION ya validó que existe)

### MUST DO
> ⚠️ All actions are MANDATORY — esta fase es el GATE de adopción; no se puede saltar

1. [ ] **Hacer las 3 preguntas de validación** al usuario (sí/no explícito por cada una):
   - Q1: ¿Necesitás un **audit trail inmutable** (historial completo como requisito, p. ej. finanzas/salud/compliance)?
   - Q2: ¿Necesitás **time-travel** (reconstruir el estado "como estaba" en cualquier momento del pasado)?
   - Q3: ¿Hay **CQRS activo** (o se va a adoptar) en este aggregate? (ES casi nunca va sin CQRS)
2. [ ] **Contar los "sí"** → `YES_COUNT`. Inferir señales del proyecto (`.king/knowledge/architecture.md`) para confirmar Q3 (¿hay command/query bus, read models, projectors?), pero el "sí" lo confirma el usuario
3. [ ] **Aplicar el veto de adopción**: si `YES_COUNT < 2` → **RECHAZAR** el scaffolding. NO continuar a Phase 2. Sugerir el **audit log simple** (tabla `audit_events` que registra qué cambió, quién y cuándo, SIN reconstruir estado desde eventos) y explicar por qué ES no se paga acá (replay, snapshots, versionado y eventual consistency sin retorno)
4. [ ] **Si `YES_COUNT >= 2`**: registrar `VERDICT = PROCEED`, anotar cuáles preguntas dieron "sí" para el ADR y la Execution Summary, y advertir el costo operativo permanente (versionado de eventos / upcasters) antes de continuar

### CHECKPOINT
- [ ] Las 3 preguntas fueron hechas y respondidas explícitamente (sí/no por cada una)
- [ ] `YES_COUNT` calculado (0–3)
- [ ] Si `YES_COUNT < 2`: scaffolding RECHAZADO, audit log simple sugerido, y skill detenido (BLOCKING CONDITION)
- [ ] Si `YES_COUNT >= 2`: `VERDICT = PROCEED` registrado con las preguntas afirmativas

### OUTPUTS
- Variables: `Q1`, `Q2`, `Q3` (bool), `YES_COUNT`, `VERDICT` (`PROCEED` | `REJECT`)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Las 3 preguntas de validación no se pudieron responder o el veredicto es ambiguo.
Cause: el usuario no respondió sí/no claro, o respondió "tal vez" a las tres.
Recovery:
  [ ] Option A: re-formular cada pregunta con un ejemplo concreto (ej. "audit: ¿un regulador puede pedirte el historial completo?") y exigir sí/no
  [ ] Option B: si el usuario no puede afirmar al menos 2, tratar como `YES_COUNT < 2` → RECHAZAR y sugerir audit log simple (es el comportamiento por defecto seguro, NO un error)
  [ ] Option C: si solo Q3 (CQRS) queda dudoso, ofrecer correr `/cqrs-setup` primero y re-evaluar este skill después

---

## Phase 2: Resolve Backend & Events

### GATE IN
- [ ] `VERDICT = PROCEED` (Phase 1 superó el gate de adopción con `YES_COUNT >= 2`)

### MUST DO
1. [ ] **Leer `.king/knowledge/stack.md`** y extraer el lenguaje principal y el module/package root
2. [ ] **Resolver `STORE_BACKEND`** desde `--store-backend` si se pasó; si no, `postgres` por defecto. Soportar `postgres`, `eventstore`, `dynamodb`, `in-memory`
3. [ ] **Resolver la lista de eventos** desde `--events` si se pasó; si no, detectarlos desde un `/ddd-tactical` previo (eventos del aggregate en `domain/{aggregate}/events/`) o inferirlos del aggregate. Normalizar nombres en pasado (`OrderCreated`, `ItemAdded`, `OrderPaid`)
4. [ ] **Resolver `SNAPSHOT_EVERY`** desde `--snapshot-every` si se pasó; si no, `100` por defecto
5. [ ] **Detectar event store existente** — leer `.king/knowledge/architecture.md` y el árbol del proyecto. Marcar `EXISTS = true|false` para `[aggregate-name]`

### CHECKPOINT
- [ ] `STORE_BACKEND` resuelto (uno de `postgres|eventstore|dynamodb|in-memory`)
- [ ] `EVENTS[]` resuelto (≥1 evento en pasado) — si vacío, asumido `{Aggregate}Created` con WARN
- [ ] `SNAPSHOT_EVERY` resuelto (entero ≥ 1)
- [ ] `EXISTS` definido (si `true`, requiere confirmación de extender/sobrescribir — BLOCKING CONDITION)

### OUTPUTS
- Variables: `STACK`, `STORE_BACKEND`, `EVENTS[]`, `SNAPSHOT_EVERY`, `MODULE_ROOT`, `EXISTS`

### IF FAILS
ERROR: No se pudo resolver el backend o la lista de eventos.
Cause: stack sin lenguaje declarado, o ningún evento provisto ni detectable.
Recovery:
  [ ] Option A: pedir al usuario el `--store-backend` (4 opciones) y al menos 1 domain event
  [ ] Option B: correr `/ddd-tactical [aggregate-name]` primero para modelar aggregate + domain events, luego volver
  [ ] Option C: asumir `postgres` + un único evento `{Aggregate}Created` como semilla y marcar el resto como TODO en la Execution Summary

---

## Phase 3: Event Store Schema

### GATE IN
- [ ] `STORE_BACKEND` y `EVENTS[]` resueltos (Phase 2)

### MUST DO
1. [ ] **Generar el event store schema** (append-only) con las columnas obligatorias:
   `id` (PK, secuencial global o UUID ordenado), `aggregate_id`, `aggregate_type`, `event_type`,
   `payload` (JSON/JSONB con el dato del evento), `sequence` (monótona POR aggregate, para orden de replay),
   `created_at` (timestamp del evento)
2. [ ] **Materializar el schema según `STORE_BACKEND`**:
   - `postgres` → migración SQL con tabla `events`, `PRIMARY KEY (id)`, índice `(aggregate_id, sequence)` y `UNIQUE (aggregate_id, sequence)` para concurrencia optimista, `payload JSONB`
   - `eventstore` → stream por aggregate (`{aggregate_type}-{aggregate_id}`), eventos como `event_type` + `data`
   - `dynamodb` → PK `aggregate_id`, SK `sequence`, atributos `event_type`, `payload`, `created_at`
   - `in-memory` → estructura append-only en memoria con la misma forma (para tests/dev)
3. [ ] **Generar la interfaz del event store**: `append(aggregateId, expectedSequence, events[])` (append-only, con concurrencia optimista vía `expectedSequence`) y `loadStream(aggregateId): Event[]` (ordenado por `sequence`)
4. [ ] **Garantizar inmutabilidad**: el schema y el código NO exponen `UPDATE`/`DELETE` de un evento; documentar que las correcciones se hacen con eventos compensatorios

### CHECKPOINT
- [ ] Schema con las 7 columnas: `id`, `aggregate_id`, `aggregate_type`, `event_type`, `payload`, `sequence`, `created_at`
- [ ] `sequence` es monótona por aggregate y hay garantía de unicidad `(aggregate_id, sequence)` (concurrencia optimista)
- [ ] El store es append-only: NO hay `UPDATE`/`DELETE` de eventos en schema ni en la interfaz
- [ ] `append` y `loadStream` declarados según `STORE_BACKEND`

### OUTPUTS
- Archivos: migración/definición del event store schema + interfaz del store (`append`/`loadStream`)

### IF FAILS
ERROR: No se pudo generar el event store schema.
Cause: backend sin convención de migración detectable o tipo de `payload` sin soporte (JSON) en el motor.
Recovery:
  [ ] Option A: generar el schema igualmente y documentar el comando de migración del backend
  [ ] Option B: si el motor no soporta JSON nativo, usar `payload` como TEXT con (de)serialización en el código y notarlo
  [ ] Option C: caer a `in-memory` para destrabar dev/tests y marcar el backend real como TODO

---

## Phase 4: Rehydration & Snapshots

### GATE IN
- [ ] Event store schema creado (Phase 3)

### MUST DO
1. [ ] **Generar la rehydration del aggregate**: un `apply(event)` method POR cada `event_type` que muta el estado en memoria de forma PURA (sin I/O), y un factory `rehydrate(events[])` que hace fold (`reduce`) del stream desde el evento #1 → estado actual
2. [ ] **Generar el método de decisión** (`decide`/comando → eventos): el aggregate valida invariantes y EMITE eventos nuevos (no muta estado directo); `apply` es el único que muta. Documentar la separación decide/apply
3. [ ] **Generar el snapshot store** y la snapshot strategy: persistir el estado serializado del aggregate cada `SNAPSHOT_EVERY` eventos. La carga hace `loadSnapshot(aggregateId)` (último snapshot) + `loadStream(aggregateId, fromSequence)` (eventos posteriores) y aplica solo esos
4. [ ] **Dejar explícito que el snapshot es CACHE**: si el snapshot se borra, el estado se reconstruye igual desde los eventos; la fuente de verdad es el stream

### CHECKPOINT
- [ ] Un `apply(event)` por cada `event_type` de `EVENTS[]`, todos puros (sin efectos secundarios)
- [ ] `rehydrate(events[])` hace fold determinista del stream → estado actual
- [ ] Separación decide (emite eventos) / apply (muta) respetada
- [ ] Snapshot store persiste cada `SNAPSHOT_EVERY` eventos; la carga combina snapshot + eventos posteriores
- [ ] El snapshot es cache (reconstruible desde eventos), NO fuente de verdad

### OUTPUTS
- Archivos: aggregate con `apply` methods + `rehydrate` factory + `decide`; snapshot store + strategy

### IF FAILS
ERROR: No se pudo generar la rehydration o la snapshot strategy.
Cause: eventos sin payload modelado, o aggregate sin estado claro para hacer fold.
Recovery:
  [ ] Option A: generar `apply` stubs (uno por evento) con el cambio de estado como TODO comentado y un `rehydrate` que ya itera el stream
  [ ] Option B: pedir al usuario el estado mínimo del aggregate (campos) para materializar el fold
  [ ] Option C: omitir snapshots (solo rehydration completa) y marcar la snapshot strategy como TODO, advirtiendo el costo de replay largo

---

## Phase 5: Projections & Rebuild

### GATE IN
- [ ] Rehydration generada (Phase 4)

### MUST DO
1. [ ] **Generar ≥1 projection** para las queries más comunes del aggregate: un projector que consume eventos (en orden) y construye/actualiza un read model desnormalizado (ej. `{aggregate}_summary`). Si hay CQRS activo (Q3), la projection alimenta el read model del lado Query
2. [ ] **Generar el projection rebuild command**: reconstruye la(s) projection(s) desde el evento #1 — limpia el read model y re-aplica todo el stream global (o por aggregate). Es el comando que se corre cuando la lógica de proyección cambia
3. [ ] **Hacer el rebuild idempotente**: correrlo dos veces produce el mismo read model (truncate + replay, o upsert por clave determinista)
4. [ ] **Aplicar convenciones de naming** de `.king/knowledge/conventions.md` si existe (tablas de read model, nombres de projector, comando de rebuild)

### CHECKPOINT
- [ ] ≥1 projection que construye un read model desde los eventos
- [ ] Projection rebuild command que reconstruye desde el evento #1
- [ ] El rebuild es idempotente (dos corridas → mismo read model)
- [ ] Si Q3 (CQRS) fue "sí": la projection se conecta al read model del lado Query

### OUTPUTS
- Archivos: projection(s)/projector(s) + read model + rebuild command

### IF FAILS
ERROR: No se pudo generar la projection o el rebuild command.
Cause: no hay query objetivo clara, o el read model no tiene forma definida.
Recovery:
  [ ] Option A: generar una projection genérica `{aggregate}_summary` (estado actual derivado del fold) + su rebuild
  [ ] Option B: pedir al usuario la query más frecuente para modelar el read model óptimo
  [ ] Option C: generar el rebuild command sobre la projection genérica y marcar projections específicas como TODO

---

## Phase 6: Tests

### GATE IN
- [ ] Projections y rebuild generados (Phase 5)

### MUST DO
1. [ ] **Test de rehydration**: dado un stream de eventos conocido, `rehydrate(events)` reproduce EXACTAMENTE el estado esperado (fold determinista)
2. [ ] **Test de snapshot**: cargar desde un snapshot + aplicar solo los eventos posteriores produce el MISMO estado que rehydratar el stream completo (snapshot es cache equivalente)
3. [ ] **Test de projection rebuild**: correr el rebuild desde el evento #1 reconstruye el read model esperado; correrlo dos veces da el mismo resultado (idempotencia)
4. [ ] **Test de inmutabilidad (si factible)**: intentar `UPDATE`/`DELETE` de un evento es rechazado o no está expuesto por la interfaz del store
5. [ ] **Aplicar el framework de test del stack** (Go: `testing`/`testify`; TS: vitest/jest; Python: pytest) según `.king/knowledge/stack.md`

### CHECKPOINT
- [ ] Test de rehydration presente y orientado a verificar el fold determinista
- [ ] Test de snapshot verifica equivalencia snapshot+eventos == stream completo
- [ ] Test de projection rebuild verifica reconstrucción desde #1 e idempotencia
- [ ] Los tests usan el framework del stack del proyecto

### OUTPUTS
- Archivos: tests de rehydration, snapshot y projection rebuild

### IF FAILS
ERROR: No se pudieron generar los tests.
Cause: framework de test no detectable o aggregate sin estado verificable.
Recovery:
  [ ] Option A: generar los tests con el framework más común del stack y fixtures de eventos de ejemplo
  [ ] Option B: generar al menos el test de rehydration (el núcleo del patrón) y marcar snapshot/rebuild como TODO
  [ ] Option C: si no hay runner de tests, generar los archivos de test igualmente y documentar el comando para ejecutarlos

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Resultado de las 3 preguntas registrado (`YES_COUNT` + veredicto) y `YES_COUNT >= 2`
  - [ ] Event store schema con las 7 columnas (`id`, `aggregate_id`, `aggregate_type`, `event_type`, `payload`, `sequence`, `created_at`)
  - [ ] Rehydration: `apply` methods + `rehydrate` fold
  - [ ] Snapshot strategy cada `SNAPSHOT_EVERY` eventos (cache, no fuente de verdad)
  - [ ] ≥1 projection + projection rebuild command (idempotente)
  - [ ] Tests: rehydration, snapshot, projection rebuild
- [ ] El event store es append-only (sin `UPDATE`/`DELETE` de eventos)
- [ ] El snapshot NO es fuente de verdad (el estado se reconstruye desde eventos)
- [ ] Ningún N de snapshot, store backend, ruta absoluta o nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(store append-only + rehydration determinista + snapshots + rebuild + tests = FORTIFIED; exactamente 2/3 "sí" o sin snapshot strategy = CONDITIONAL; store con UPDATE/DELETE de eventos o procedió con < 2 "sí" = BREACHED)_ |
| Artifacts | _(event store schema; aggregate con apply/rehydrate; snapshot store; projection(s) + rebuild command; tests)_ |
| Next Recommended | `/cqrs-setup` (si Q3 fue "no" pero querés el read side) o `/ddd-tactical [aggregate-name]` (enriquecer el aggregate y sus eventos) |
| Risks | _(versionado de eventos/upcasters es trabajo permanente; eventual consistency del read model; GDPR vs store inmutable; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Validación dio < 2 "sí" (RECHAZADO) | implementar un audit log simple (tabla `audit_events`), NO Event Sourcing |
| Q3 (CQRS) fue "no" pero se quiere el read side optimizado | `/cqrs-setup` — command/query bus + read models que las projections alimentan |
| El aggregate o sus eventos están pobres | `/ddd-tactical [aggregate-name]` — aggregate rico, VOs, domain events inmutables |
| Event store y projections listos | implementar handlers con `/build`; validar inmutabilidad y replay en `/review` |
| Historia de aggregates muy larga (replay lento) | ajustar `--snapshot-every` (snapshots más frecuentes) y re-ejecutar |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### El gate de adopción (3 preguntas → veto)

Event Sourcing es de los patrones más difíciles de operar bien (replay, snapshots, versionado de
eventos, eventual consistency). Por eso el skill NO scaffoldea nada hasta validar la adopción con 3
preguntas y el conteo de "sí":

| "sí" | Veredicto | Acción |
|------|-----------|--------|
| 3/3 | PROCEED (fuerte) | Scaffolding completo; ES bien justificado |
| 2/3 | PROCEED (al límite) | Scaffolding + WARN de costo operativo; CASTLE CONDITIONAL |
| 0–1/3 | **REJECT** | NO scaffoldear; sugerir **audit log simple** y detener |

> Las 3 preguntas vienen del "Cuándo usar" de `knowledge/domain/architecture-patterns.md` §5: audit
> trail crítico, time-travel, y "ya usás CQRS" (ES casi nunca va solo, Regla de oro #5). Menos de 2 "sí"
> significa que la complejidad operativa NO se paga: un audit log simple cubre la trazabilidad sin replay.

### Audit log simple (la alternativa cuando ES no se paga)

Cuando el veredicto es REJECT, la alternativa es una tabla `audit_events` que registra QUÉ cambió, QUIÉN
y CUÁNDO — pero el estado actual se sigue guardando como snapshot normal (UPDATE en la tabla del
aggregate). NO hay rehydration por fold, NO hay snapshots de replay, NO hay projections ni rebuild. Da
trazabilidad sin la carga operativa de Event Sourcing. Es la opción correcta para la mayoría de los
casos que "querían audit" sin necesitar time-travel ni reconstrucción de estado.

### Event store schema (las 7 columnas)

| Columna | Tipo (postgres) | Propósito |
|---------|-----------------|-----------|
| `id` | `BIGSERIAL` / UUID ordenado | identidad global del evento (orden de inserción) |
| `aggregate_id` | `UUID`/`TEXT` | a qué instancia de aggregate pertenece |
| `aggregate_type` | `TEXT` | tipo de aggregate (`Order`, `Account`) — permite múltiples tipos en una tabla |
| `event_type` | `TEXT` | nombre del evento en pasado (`OrderCreated`) — selecciona el `apply` |
| `payload` | `JSONB` | dato del evento, autosuficiente para reproducir el estado SIN consultar afuera |
| `sequence` | `BIGINT` | orden monótono POR aggregate; base de la rehydration y la concurrencia optimista |
| `created_at` | `TIMESTAMPTZ` | cuándo ocurrió — habilita time-travel |

> `UNIQUE (aggregate_id, sequence)` da concurrencia optimista: dos escrituras concurrentes con el mismo
> `expectedSequence` chocan, y una reintenta. El store es append-only: nunca `UPDATE`/`DELETE` de un
> evento (para corregir, evento compensatorio).

### Rehydration: decide vs apply (concepto)

Un aggregate event-sourced separa dos responsabilidades:
- **decide(command) → events[]**: valida invariantes y EMITE eventos nuevos. NO muta estado.
- **apply(event)**: muta el estado en memoria de forma PURA (sin I/O). Es el único que cambia el estado.

`rehydrate(events) = events.reduce(apply, initialState)` reconstruye el estado actual haciendo fold del
stream. Como `apply` es puro y determinista, el mismo stream SIEMPRE produce el mismo estado — base del
replay, los snapshots y el rebuild. Detalle en `knowledge/domain/architecture-patterns.md` §5.

### Snapshot strategy

El snapshot guarda el estado serializado del aggregate cada N eventos (`--snapshot-every`, default 100)
para no reproducir desde el evento #1 en aggregates con historia larga. La carga optimizada es:
`loadSnapshot(id)` (último snapshot, en `sequence = S`) + `loadStream(id, fromSequence = S+1)` (solo los
eventos posteriores) → `apply` sobre esos. El snapshot es **cache**: si se borra, el estado se
reconstruye igual desde los eventos. Nunca es fuente de verdad.

### Projections y rebuild

Una projection consume eventos en orden y construye un read model desnormalizado optimizado para una
query (ej. `order_summary`). Si la lógica de proyección cambia (o el read model se corrompe), el
**rebuild command** trunca el read model y re-aplica TODO el stream desde el evento #1 — por eso debe ser
idempotente. Con CQRS activo (Q3 "sí"), la projection es exactamente el projector del lado Query (ver
`knowledge/domain/architecture-patterns.md` §4 CQRS y la combinación "Event Sourcing + CQRS" de la tabla
de Combinaciones Comunes).

### Store backends soportados

| Backend | Forma del store | Cuándo |
|---------|-----------------|--------|
| `postgres` | tabla `events` (append-only) con `UNIQUE (aggregate_id, sequence)`, `payload JSONB` | default; transaccional, conocido, sin infra extra |
| `eventstore` | EventStoreDB: un stream por aggregate, subscriptions nativas para projections | ES como producto de primera clase, proyecciones nativas |
| `dynamodb` | PK `aggregate_id` + SK `sequence`; streams para projections | serverless/escala horizontal en AWS |
| `in-memory` | append-only en memoria, misma forma | tests y desarrollo local (no producción) |

### Integración con @architect y CASTLE A

`agents/architect.md` referencia `knowledge/domain/architecture-patterns.md` y puede invocar
`/event-sourcing` cuando detecta un requisito de audit crítico o time-travel sobre un dominio con CQRS.
CASTLE A vigila "Event Sourcing sin versionado/snapshots" como bomba de tiempo operativa: este skill
materializa los snapshots y deja el versionado de eventos documentado como trabajo permanente. El delta
spec del patrón está en `openspec/changes/m04-architecture/specs/architecture-patterns/spec.md`
(Requirement Skill `/event-sourcing`).

### Relación con otros skills del arco M04

`/event-sourcing` define CÓMO se persiste el estado (eventos), ortogonal a Clean/Hexagonal (dónde van las
dependencias) y a DDD Tactical (cómo se modela el aggregate). Casi siempre acompaña a `/cqrs-setup` (las
projections alimentan los read models) y se nutre de `/ddd-tactical` (los domain events que se persisten).
No es alternativa de ninguno: es una capa más (ver tabla de Combinaciones Comunes y Regla de oro #5 en
`knowledge/domain/architecture-patterns.md`).
