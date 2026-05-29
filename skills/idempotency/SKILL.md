---
name: idempotency
version: 2.0
api_version: 1.0.0
description: "Agrega idempotency keys a endpoints y handlers para operaciones que pueden reintentarse de forma segura (exactly-once efectivo sobre at-least-once). Genera un middleware de deduplicación que DISTINGUE 'ya procesado' (resultado cacheado, replay del status original) de 'en proceso' (202 + Retry-After), el schema de dedup con TTL, tests (misma key → mismo resultado, un solo registro en DB) y una guía de cliente para generar keys correctas. 3 strategies: idempotency-key-header (default), request-hash, client-id+sequence. Usar cuando se necesite: idempotencia, retry seguro, exactly-once, hacer un POST retry-safe, evitar doble cobro/doble orden, o deduplicar requests. Alimenta CASTLE A (Architecture) y L (Logging)."
---

# /idempotency — Idempotency Keys, Middleware de Deduplicación y Schema con TTL

Hace que un endpoint o handler sea **retry-safe**: un cliente puede reenviar el mismo request (timeout,
red caída, reintento automático) sin que la operación se ejecute dos veces. Genera un **middleware de
deduplicación** que, ante una key repetida, distingue dos casos que NO son lo mismo: **"ya procesado"**
(devuelve el resultado cacheado con el status code y body originales) y **"en proceso"** (la primera
request sigue corriendo → responde **202 + `Retry-After`**, nunca re-ejecuta). Produce además el **schema
de dedup con TTL**, **tests** (misma key dos veces → mismo resultado y un solo registro en DB; keys
distintas → procesan independiente) y una **guía de cliente** para generar keys correctas (UUID v4
estable por intento lógico, NUNCA re-aleatorizado en cada retry).

> **Idempotencia = exactly-once efectivo sobre at-least-once**: la red garantiza *at-least-once*; nadie
> puede prometer que un request llega exactamente una vez. La idempotencia traslada la garantía a la
> SEMÁNTICA: el efecto observable ocurre una sola vez aunque el request llegue N veces. El estado de
> dedup (`in_progress` → `completed`) es lo que vuelve esto correcto bajo concurrencia — por eso la
> reserva atómica de la key es el corazón del middleware, no un detalle.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack del proyecto (framework HTTP y store) — fuente del store y del adapter de middleware auto-detectados | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de middlewares, tablas y headers del proyecto | No | project |
| `knowledge/domain/distributed-systems.md` | Delivery at-least-once, deduplicación, distributed caching y TTL (custom: este skill aplica la dedup at-least-once de esta base) | No | framework |
| `knowledge/domain/saga-patterns.md` | Inbox Pattern (7) — toda compensación/handler bajo at-least-once DEBE ser idempotente; este skill materializa esa regla | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[file|endpoint]` ni se detecta ningún handler/endpoint en el target indicado
- [ ] El target no es un handler de escritura (la idempotencia NO aplica a GET puro / operaciones ya idempotentes por naturaleza) y el usuario no confirma forzar
- [ ] Se pidió `--store redis` (o `postgres`) pero no hay store resoluble ni fallback `in-memory` aceptado por el usuario
- [ ] `--strategy client-id+sequence` pero el request no expone un `client-id` identificable (no hay de dónde derivar la identidad del cliente)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA tratar "en proceso" (`in_progress`) como "ya procesado": una key reservada pero sin resultado aún DEBE responder **202 + `Retry-After`**, jamás re-ejecutar el handler ni devolver un body vacío como si fuera el resultado
- NUNCA cachear/replayear respuestas de ERROR del cliente como resultado idempotente final salvo configuración explícita — un 4xx/5xx no debe "fijar" para siempre la respuesta de una key (la key debe poder reintentarse); solo los resultados terminales exitosos se cachean por defecto
- NUNCA omitir el TTL en el schema de dedup: una tabla/llave de idempotencia sin expiración crece sin límite y es un leak de almacenamiento
- NUNCA reservar la key de forma no-atómica (read-then-write con race): la reserva DEBE ser atómica (`SET NX` en Redis / `INSERT ... ON CONFLICT DO NOTHING` en Postgres) para que dos requests concurrentes con la misma key no ejecuten ambos
- NUNCA scopear la key globalmente cuando el sistema es multi-tenant / multi-usuario: la key se scopea por `{tenant?}:{actor}:{endpoint}:{key}` para que la key de un cliente no colisione con la de otro
- NUNCA incluir credenciales/connection strings literales del store en el middleware ni en los tests — usar variables de entorno / `{{SLOT}}`
- NUNCA aplicar el middleware a un endpoint sin verificar que la unicidad del resultado quede garantizada también en la capa de persistencia (constraint único) cuando el `--strategy` lo permite — la dedup en cache es defensa, el constraint en DB es la red de seguridad
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Middleware de idempotency: recibe la key (según `--strategy`), reserva atómicamente, distingue `completed` (resultado cacheado → replay del status/body originales) de `in_progress` (202 + `Retry-After`), y persiste el resultado al terminar
- [ ] Schema de dedup (tabla Postgres o estructura de key Redis) con TTL y estado (`in_progress` / `completed`)
- [ ] Tests: misma key dos veces → mismo resultado y UN SOLO registro en DB; keys distintas → procesan independiente; request concurrente con misma key → uno procesa, el otro recibe 202/replay
- [ ] Guía de cliente: cómo generar idempotency keys correctas (UUID v4 estable por intento lógico, NO re-aleatorizar en retry; qué header enviar)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Detect    (Resolve  (Design   (Generate (Generate (Session)  (Guide)
          target +   store +   dedup     middle-   tests +
          strategy)  TTL)      schema)   ware)     client
                                                   guide)
```

### PARÁMETROS
```
/idempotency [file|endpoint] [--strategy idempotency-key-header|request-hash|client-id+sequence] [--store redis|postgres|in-memory] [--ttl <duración>]
```
- `[file|endpoint]`: ruta a un archivo con handler(s), o la firma de un endpoint (ej. `POST /orders`). Si es archivo, se detectan los handlers de escritura
- `--strategy`: cómo se deriva la key. `idempotency-key-header` (default — lee el header `Idempotency-Key`), `request-hash` (hash determinístico del método+ruta+body normalizado), `client-id+sequence` (identidad del cliente + número de secuencia monótono)
- `--store`: backend de dedup. `redis` (default si está disponible), `postgres` (default si no hay Redis), `in-memory` (solo dev/single-instance — se advierte que no sirve en cluster)
- `--ttl`: ventana de retención de la key (default: `24h`). Define cuánto tiempo una key recordada bloquea/replay; tras el TTL la key se considera nueva

---

## CASTLE activo: _-A-_-_-L-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) es la capa central: el middleware introduce un componente transversal de
> deduplicación con un contrato de estado (`in_progress`/`completed`) que debe respetar atomicidad y scope
> de key. CASTLE L (Logging) cubre la observabilidad de hits/replays/in-progress (sin ella la idempotencia
> es invisible en incidentes). Veredicto CONDITIONAL si el store es `in-memory` en un sistema multi-instancia
> o si falta el constraint de unicidad en DB; BREACHED si la reserva de key no es atómica (race de doble
> ejecución) o si `in_progress` se trata como resultado final.

## Agentes
- **@architect** — Agente principal: decide la estrategia de key, el scope (tenant/actor), el store y garantiza la atomicidad de la reserva y el contrato de estados
- **@developer** — Genera el middleware, el schema/migración y la integración en el stack del proyecto
- **@qa** — Valida los tests de concurrencia (misma key concurrente → una sola ejecución) y que `in_progress` nunca devuelva resultado vacío como final

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Target & Strategy

### GATE IN
- [ ] Se recibió `[file|endpoint]` (BLOCKING CONDITION ya validó que existe input)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver el/los handler(s)** — si el target es un archivo, detectar los handlers de ESCRITURA (POST/PUT/PATCH/DELETE no idempotente); si es una firma de endpoint, localizar su handler. Descartar GET puro y advertir si el target ya es naturalmente idempotente
2. [ ] **Resolver `--strategy`** — `idempotency-key-header` (default) si no se pasa. Validar viabilidad: `client-id+sequence` requiere identidad de cliente identificable en el request; `request-hash` requiere body determinístico (normalizable)
3. [ ] **Detectar framework HTTP / adapter de middleware** desde `.king/knowledge/stack.md` (Express, Fastify, Koa, NestJS, FastAPI, Gin/Echo, Spring) para saber CÓMO se inyecta el middleware
4. [ ] **Detectar multi-tenancy / actor** — leer `.king/tenancy.yaml` si existe y el modelo de autenticación, para definir el scope de la key (`{tenant?}:{actor}:{endpoint}:{key}`)
5. [ ] **Marcar el efecto a proteger** — identificar la mutación principal (insert de orden, cobro, envío) cuya doble ejecución se quiere evitar; será la base del constraint de unicidad en DB

### CHECKPOINT
- [ ] `TARGET_HANDLERS[]` resuelto (handlers de escritura), GET puro descartado o forzado con WARN
- [ ] `STRATEGY` resuelto y viable para el request (identidad/body verificados)
- [ ] `HTTP_ADAPTER` identificado (cómo se monta el middleware en el stack)
- [ ] `KEY_SCOPE` definido (global / por actor / por tenant)
- [ ] `PROTECTED_EFFECT` identificado (la mutación a deduplicar)

### OUTPUTS
- Variables: `TARGET_HANDLERS[]`, `STRATEGY`, `HTTP_ADAPTER`, `KEY_SCOPE`, `PROTECTED_EFFECT`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el target o la estrategia.
Cause: el target no es un handler de escritura, `.king/knowledge/stack.md` ausente, o la `--strategy` elegida no es viable (sin client-id o body no determinístico).
Recovery:
  [ ] Option A: pedir al usuario el handler exacto y confirmar que la operación es no-idempotente por naturaleza (justifica el middleware)
  [ ] Option B: si la `--strategy` pedida no es viable, caer a `idempotency-key-header` (la más universal) con WARN explicando por qué
  [ ] Option C: si el framework no se detecta, pedir el stack HTTP al usuario y generar el middleware como función agnóstica + nota de cómo montarlo

---

## Phase 2: Resolve Store & TTL

### GATE IN
- [ ] `STRATEGY` resuelto (Phase 1)

### MUST DO
1. [ ] **Resolver `--store`** — `redis` si está disponible (detectar `REDIS_URL`/cliente en el stack); si no, `postgres` (detectar `DATABASE_URL`); `in-memory` solo si el usuario lo acepta para dev. Marcar `STORE`
2. [ ] **Advertir sobre `in-memory` en cluster** — si el sistema corre en múltiples instancias, `in-memory` NO deduplica entre instancias: emitir WARNING y recomendar Redis/Postgres
3. [ ] **Resolver `--ttl`** — default `24h`. Validar que el TTL cubra la ventana realista de reintentos del cliente (un retry más allá del TTL re-ejecuta)
4. [ ] **Definir la semántica de la reserva atómica** según `STORE`: Redis `SET key value NX PX <ttl>`; Postgres `INSERT ... ON CONFLICT (key) DO NOTHING` + columna `expires_at`; in-memory map con lock + expiración
5. [ ] **Decidir el constraint de unicidad en DB** para `PROTECTED_EFFECT` (ej. `UNIQUE(idempotency_key)` o `UNIQUE(client_id, sequence)`) como red de seguridad independiente del cache

### CHECKPOINT
- [ ] `STORE` resuelto (`redis` | `postgres` | `in-memory`) con WARN si `in-memory` en cluster
- [ ] `TTL` resuelto y justificado contra la ventana de retry
- [ ] Mecanismo de reserva atómica definido para el `STORE` elegido
- [ ] Constraint de unicidad en DB decidido para el efecto protegido

### OUTPUTS
- Variables: `STORE`, `TTL`, `ATOMIC_RESERVE`, `DB_UNIQUE_CONSTRAINT`

### IF FAILS
ERROR: No se pudo resolver el store de deduplicación.
Cause: ni Redis ni Postgres resolubles, y el usuario no acepta `in-memory`; o TTL inválido.
Recovery:
  [ ] Option A: pedir al usuario qué store usar y la variable de conexión (sin pegar credenciales — usar `{{SLOT}}`)
  [ ] Option B: generar el middleware contra una interfaz `IdempotencyStore` abstracta y proveer 2 adapters (Redis + Postgres) para que el usuario elija al cablear
  [ ] Option C: usar `in-memory` SOLO con WARN explícito de "no apto para múltiples instancias" y marcar la fase PARTIAL

---

## Phase 3: Design Dedup Schema

### GATE IN
- [ ] `STORE` y `TTL` resueltos (Phase 2)

### MUST DO
1. [ ] **Diseñar el schema de dedup** con los campos del contrato de estado: `key` (scopeada), `status` (`in_progress` | `completed`), `response_status` (HTTP code original), `response_body` (resultado cacheado), `request_fingerprint` (hash del request, para detectar reuso de key con payload distinto), `created_at`, `expires_at` (TTL), y `locked_by`/`lease` si aplica
2. [ ] **Materializar el schema según `STORE`** — Postgres: `CREATE TABLE idempotency_keys (...)` con `UNIQUE(key)` e índice sobre `expires_at`; Redis: estructura del value (JSON con `status`/`response`/`fingerprint`) + `PX <ttl>`
3. [ ] **Definir la detección de mismatch de payload** — si una key llega con `request_fingerprint` distinto al guardado, responder `422 Unprocessable Entity` (reuso de key con request diferente), NUNCA mezclar resultados
4. [ ] **Definir la política de expiración** — Redis vía PX nativo; Postgres vía `expires_at` + sweep (job/`DELETE WHERE expires_at < now()`), documentar el sweep
5. [ ] **Aplicar convenciones** de `.king/knowledge/conventions.md` (naming de tabla/header) si existe

### CHECKPOINT
- [ ] Schema con `key`, `status`, `response_status`, `response_body`, `request_fingerprint`, `expires_at`
- [ ] `UNIQUE(key)` (o la unicidad equivalente del `STORE`) presente para la reserva atómica
- [ ] TTL materializado (PX en Redis / `expires_at` + sweep en Postgres)
- [ ] Política de mismatch de payload definida (422 ante fingerprint distinto)

### OUTPUTS
- Archivos: schema/migración de dedup (DDL Postgres o spec de key Redis)
- Variables: `SCHEMA_FIELDS[]`

### IF FAILS
ERROR: No se pudo materializar el schema de dedup.
Cause: el `STORE` no soporta TTL nativo (requiere sweep) o conflicto con una tabla existente.
Recovery:
  [ ] Option A: en Postgres, agregar el job de sweep (`DELETE WHERE expires_at < now()`) y documentarlo como cron/scheduled task
  [ ] Option B: si ya existe una tabla de idempotencia, EXTENDERLA (añadir columnas faltantes) sin romper datos existentes
  [ ] Option C: generar el schema como migración pendiente + nota de revisión manual si hay conflicto de naming

---

## Phase 4: Generate Middleware

### GATE IN
- [ ] Schema de dedup diseñado (Phase 3)
- [ ] `HTTP_ADAPTER` y `ATOMIC_RESERVE` resueltos

### MUST DO
1. [ ] **Generar el middleware** en el adapter del stack (`HTTP_ADAPTER`). Flujo: derivar la key según `STRATEGY` → scopearla (`KEY_SCOPE`) → intentar **reserva atómica** (`ATOMIC_RESERVE`)
2. [ ] **Implementar la bifurcación de 3 caminos**:
   - **Reserva exitosa (key nueva)** → ejecutar el handler; al terminar, persistir `status=completed` + `response_status` + `response_body`; devolver el resultado
   - **Key existe con `status=completed`** → NO ejecutar el handler; **replay del resultado cacheado** con el `response_status` y `response_body` originales (idealmente con header `Idempotent-Replayed: true`)
   - **Key existe con `status=in_progress`** → NO ejecutar el handler; responder **`202 Accepted` + `Retry-After: <segundos>`** indicando que la primera request sigue en curso
3. [ ] **Verificar fingerprint** — si la key existe pero el `request_fingerprint` difiere, responder `422` (reuso indebido de key)
4. [ ] **Manejar fallo del handler** — si el handler falla, liberar/expirar la reserva (no dejarla `in_progress` colgada) para que un retry legítimo pueda reintentar; usar lease/timeout para `in_progress` huérfanas
5. [ ] **Emitir observabilidad (CASTLE L)** — loggear/contar: `idempotency_hit` (replay), `idempotency_in_progress` (202), `idempotency_new` (primera ejecución), con la key hasheada (no en claro si es sensible)
6. [ ] **Sin secretos** — la conexión al store se inyecta por env/DI, nunca hardcodeada

### CHECKPOINT
- [ ] Middleware con reserva ATÓMICA (sin race read-then-write)
- [ ] Los 3 caminos implementados: nueva → ejecuta + cachea; completed → replay; in_progress → 202 + Retry-After
- [ ] `in_progress` NUNCA devuelve resultado vacío como final; fingerprint mismatch → 422
- [ ] Reserva liberada/expirada ante fallo del handler (no quedan `in_progress` huérfanas)
- [ ] Métricas/logs de hit/in_progress/new emitidos (CASTLE L); sin credenciales literales

### OUTPUTS
- Archivos: middleware de idempotency + wiring en el endpoint/handler target

### IF FAILS
ERROR: No se pudo generar el middleware.
Cause: el adapter del framework no soporta el patrón de wrap requerido, o el store no expone la primitiva atómica.
Recovery:
  [ ] Option A: generar el middleware como decorator/wrapper de handler agnóstico del framework + nota de cómo montarlo en las rutas
  [ ] Option B: si el store no tiene atomicidad nativa, usar un lock distribuido explícito (documentando sus límites; NUNCA Redlock como única garantía — ver knowledge distributed-systems) o caer al constraint de DB como mecanismo primario
  [ ] Option C: generar la versión `completed`/`new` y marcar `in_progress` como TODO con el contrato documentado (PARTIAL) si la concurrencia no es resoluble en el stack

---

## Phase 5: Generate Tests & Client Guide

### GATE IN
- [ ] Middleware generado (Phase 4)

### MUST DO
1. [ ] **Test: misma key dos veces → mismo resultado** — dos requests secuenciales con la misma `Idempotency-Key` devuelven el MISMO `response_status` y `response_body`; el segundo no re-ejecuta el efecto
2. [ ] **Test: UN SOLO registro en DB** — tras los dos requests, verificar que `PROTECTED_EFFECT` produjo exactamente UNA fila (assert sobre la tabla de negocio, no solo la de dedup)
3. [ ] **Test: keys distintas → procesan independiente** — dos requests con keys diferentes ejecutan ambos (no se deduplican entre sí)
4. [ ] **Test: concurrencia (misma key en paralelo)** — dos requests concurrentes con la misma key: uno ejecuta y obtiene el resultado, el otro recibe `202` (in_progress) o el replay; NUNCA ambos ejecutan (assert: un solo registro)
5. [ ] **Test: fingerprint mismatch** — misma key con body distinto → `422`
6. [ ] **Generar la guía de cliente** — cómo generar la key correctamente: UUID v4 generado UNA vez por intento lógico y REUSADO en cada retry de ese intento (NUNCA `uuid()` nuevo por reintento, eso anula la idempotencia); qué header enviar (`Idempotency-Key`); ejemplo de cliente con retry + backoff que respeta el `Retry-After` del 202

### CHECKPOINT
- [ ] Test "misma key → mismo resultado" presente y verde
- [ ] Test "un solo registro en DB" (sobre la tabla de negocio) presente y verde
- [ ] Test "keys distintas → independiente" presente
- [ ] Test de concurrencia (una sola ejecución bajo misma key paralela) presente
- [ ] Guía de cliente con la regla "UUID estable por intento, no re-aleatorizar en retry" + manejo de 202/Retry-After

### OUTPUTS
- Archivos: suite de tests de idempotencia + guía de cliente (markdown o comentario doc)

### IF FAILS
ERROR: No se pudieron generar/pasar los tests de idempotencia.
Cause: el test de concurrencia requiere paralelismo real difícil de simular en el harness, o el efecto protegido no es observable en test.
Recovery:
  [ ] Option A: simular concurrencia con dos llamadas casi-simultáneas + un store real (testcontainers Redis/Postgres) en vez de mock
  [ ] Option B: si el harness no permite paralelismo real, testear la reserva atómica a nivel del store (dos `SET NX` → uno gana) y documentar la limitación
  [ ] Option C: generar los tests secuenciales (misma key, keys distintas, un solo registro) como mínimo y marcar el de concurrencia como pendiente de entorno (PARTIAL)

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Middleware de idempotency con reserva atómica y los 3 caminos (nueva / completed→replay / in_progress→202+Retry-After)
  - [ ] Schema de dedup con TTL y estado (`in_progress`/`completed`)
  - [ ] Tests: misma key → mismo resultado; un solo registro en DB; keys distintas independiente; concurrencia una sola ejecución
  - [ ] Guía de cliente (UUID estable por intento, header, manejo de 202)
- [ ] `in_progress` NUNCA se trató como `completed` (sin resultado vacío como final)
- [ ] La reserva de key es ATÓMICA (sin race de doble ejecución)
- [ ] La key está scopeada (no colisiona entre actores/tenants)
- [ ] El schema tiene TTL (no crece sin límite)
- [ ] Constraint de unicidad en DB presente como red de seguridad (cuando aplica)
- [ ] Ninguna credencial/connection string literal en middleware ni tests
- [ ] Ninguna versión de tooling / ruta absoluta / nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(middleware atómico + 3 caminos + TTL + tests verdes = FORTIFIED; store in-memory en cluster, falta constraint en DB, o test de concurrencia pendiente = CONDITIONAL; reserva no atómica o in_progress tratado como final = BREACHED)_ |
| Artifacts | _(middleware de idempotency; schema/migración de dedup; suite de tests; guía de cliente)_ |
| Next Recommended | `/contract-test-pact` (contrato del consumidor), `/event-broker-setup` (idempotency key en consumers + DLQ), o `/review` (CASTLE A/L) |
| Risks | _(store in-memory no deduplica en cluster; in_progress huérfanas si el lease no expira; TTL menor que la ventana de retry del cliente; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| El endpoint publica eventos a un broker | `/event-broker-setup` — propagar la idempotency key a los consumers (retry + DLQ + dedup en el consumidor, Inbox Pattern) |
| El handler es paso de una transacción distribuida | `/saga-design` — toda compensación/handler bajo at-least-once debe ser idempotente |
| Se necesita verificar el contrato consumidor↔proveedor | `/contract-test-pact` (M-36) |
| Store quedó en `in-memory` (single instance) | migrar a Redis/Postgres antes de ir a múltiples instancias |
| Middleware y tests listos | `/review` — validar CASTLE A (atomicidad/scope) y L (observabilidad de hits/replays) |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Las 3 strategies de key

| Strategy | Cómo deriva la key | Cuándo usarla | Cuidado |
|----------|--------------------|---------------|---------|
| `idempotency-key-header` (default) | El cliente envía un header `Idempotency-Key` (UUID v4 que él controla) | API pública, pagos, cualquier escritura donde el cliente puede reintentar — es el estándar de Stripe/PayPal | Depende de que el cliente la genere bien (estable por intento). Acompañar con la guía de cliente |
| `request-hash` | Hash determinístico de `método + ruta + body normalizado` | Cuando el cliente NO puede enviar un header (webhooks legacy, formularios) y el body identifica unívocamente la operación | Body NO determinístico (timestamps, nonces) rompe el hash; hay que normalizar/excluir esos campos |
| `client-id+sequence` | Identidad del cliente + número de secuencia monótono | Streams/colas con orden por cliente, o dispositivos que numeran sus comandos | Requiere que el cliente mantenga y reenvíe la misma `sequence` en el retry; detecta también huecos/orden |

> El `--strategy` por defecto es `idempotency-key-header` porque traslada el control al cliente sin
> acoplar la dedup al contenido del body. `request-hash` es el fallback cuando no hay header; `client-id+sequence`
> es para dominios con orden por emisor.

### Contrato de estados del middleware

```
request con key
      │
      ▼
 ┌─────────────────────────┐
 │ reserva atómica (SET NX) │
 └─────────────────────────┘
      │ ganó           │ ya existía
      ▼                ▼
  status=in_progress   ¿status?
  ejecuta handler   ┌──────────────┬─────────────────┐
      │             │ completed    │ in_progress     │
      ▼             ▼              ▼
  status=completed  replay         202 Accepted
  cachea response   (status+body   + Retry-After
  devuelve result   originales)    (NO re-ejecuta)
```

| Estado de la key | Respuesta | ¿Re-ejecuta? |
|------------------|-----------|--------------|
| No existe (reserva gana) | Ejecuta el handler, cachea y devuelve el resultado real | Sí (primera vez) |
| `completed` | **Replay**: mismo `response_status` + `response_body` (header `Idempotent-Replayed: true`) | No |
| `in_progress` | **202 Accepted + `Retry-After`** (la primera request sigue corriendo) | No |
| existe pero `request_fingerprint` distinto | **422 Unprocessable Entity** (reuso de key con request diferente) | No |

> La distinción `completed` vs `in_progress` es el núcleo del skill: devolver el resultado de una request
> que TODAVÍA no terminó sería devolver basura. El 202 + Retry-After le dice al cliente "tu request se está
> procesando, volvé a consultar" — sin re-ejecutar el efecto.

### Schema de dedup (referencia)

**Postgres** (con TTL vía `expires_at` + sweep):
```sql
CREATE TABLE idempotency_keys (
  key                 TEXT PRIMARY KEY,         -- scopeada: {tenant?}:{actor}:{endpoint}:{key}
  status              TEXT NOT NULL,            -- 'in_progress' | 'completed'
  response_status     INT,                      -- HTTP status original (null mientras in_progress)
  response_body       JSONB,                    -- resultado cacheado (null mientras in_progress)
  request_fingerprint TEXT NOT NULL,            -- hash del request para detectar reuso indebido
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at          TIMESTAMPTZ NOT NULL      -- created_at + TTL
);
CREATE INDEX idx_idempotency_keys_expires_at ON idempotency_keys (expires_at);
-- sweep periódico: DELETE FROM idempotency_keys WHERE expires_at < now();
-- reserva atómica: INSERT ... ON CONFLICT (key) DO NOTHING;
```

**Redis** (TTL nativo vía `PX`):
```
KEY:   idemp:{tenant?}:{actor}:{endpoint}:{key}
VALUE: {"status":"completed","response_status":201,"response_body":{...},"fingerprint":"sha256:..."}
reserva atómica:  SET <key> '{"status":"in_progress","fingerprint":"..."}' NX PX <ttl_ms>
al terminar:      SET <key> '{"status":"completed",...}' PX <ttl_ms>   (XX implícito: ya existe)
```

### Guía de cliente — generar keys correctas

| Regla | Por qué |
|-------|---------|
| Genera el UUID v4 UNA vez por intento lógico y REÚSALO en cada retry de ese intento | Si re-aleatorizás la key en cada reintento, el servidor la ve como una operación NUEVA → doble ejecución. Esto ANULA la idempotencia |
| La key vive en el scope de la operación (ej. "crear esta orden"), no de la conexión HTTP | Un timeout de red no debe cambiar la key; es el MISMO intento lógico |
| Respetá el `Retry-After` del `202` con backoff | El `202 in_progress` significa "la primera request sigue corriendo"; reintentar antes solo genera más 202 |
| No reutilices una key para operaciones distintas | El fingerprint mismatch te devolverá `422`; cada operación lógica = su propia key |

Ejemplo conceptual de cliente (retry-safe):
```
const idempotencyKey = uuidv4();           // UNA vez, fuera del loop de retry
for (let attempt = 0; attempt < maxRetries; attempt++) {
  const res = await post('/orders', body, { headers: { 'Idempotency-Key': idempotencyKey } });
  if (res.status === 202) { await sleep(res.headers['retry-after']); continue; } // sigue en proceso
  return res; // 201 (nueva) o replay del resultado original — mismo efecto
}
```

### at-least-once → exactly-once (relación con saga/broker)

La red y los brokers entregan **at-least-once**: un mensaje/request puede llegar varias veces. La
idempotencia es la pieza que convierte eso en **exactly-once efectivo** en la semántica de negocio. Por eso:
- Todo **consumer** de un broker (M-31 `/event-broker-setup`) debe deduplicar por idempotency key (Inbox Pattern).
- Toda **compensación** de un saga (M-34 `/saga-design`) debe ser idempotente (puede reintentarse).
- El **Outbox Pattern** garantiza la publicación at-least-once; la idempotencia del consumidor cierra el círculo.

Detalle de deduplicación, distributed caching y delivery semantics en `knowledge/domain/distributed-systems.md`;
Inbox/Outbox en `knowledge/domain/saga-patterns.md`.

### Anti-patrones

| Anti-patrón | Consecuencia | Correcto |
|-------------|--------------|----------|
| Reserva read-then-write (`GET` luego `SET`) | Race: dos requests concurrentes leen "no existe" y ambos ejecutan | Reserva atómica: `SET NX` / `INSERT ON CONFLICT` |
| Devolver el resultado de una key `in_progress` | El cliente recibe un resultado incompleto/vacío como final | 202 + Retry-After hasta que esté `completed` |
| Key sin TTL | La tabla/keyspace crece sin límite (leak) | TTL (PX nativo en Redis / `expires_at` + sweep en Postgres) |
| Key global en sistema multi-tenant | La key de un cliente colisiona con la de otro → resultado cruzado | Scope `{tenant}:{actor}:{endpoint}:{key}` |
| Solo cache, sin constraint en DB | Si el cache cae/expira mal, hay doble efecto | `UNIQUE` en la tabla de negocio como red de seguridad |
| Re-aleatorizar la key en cada retry (cliente) | Cada reintento se ve como operación nueva → doble ejecución | UUID estable por intento lógico (guía de cliente) |
| Redlock como única garantía de exclusión | Conocido por sus fallos bajo GC pause/clock skew | Usar el constraint de DB / reserva atómica del store como verdad; lock solo como optimización |

### Relación con otros skills del arco M04

`/idempotency` materializa la regla transversal del bloque distributed-systems: bajo at-least-once, todo
handler y toda compensación DEBE ser idempotente. Se complementa con `/event-broker-setup` (M-31, idempotency
key en consumers + DLQ), `/saga-design` (M-34, compensaciones idempotentes), `/microservice-extract` (M-33,
contratos de servicios extraídos) y `/contract-test-pact` (M-36). El delta spec está en
`openspec/changes/m04-architecture/specs/distributed-systems/spec.md` (Requirement Skill `/idempotency`).
