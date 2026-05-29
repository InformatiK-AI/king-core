---
name: saga-design
version: 2.0
api_version: 1.0.0
description: "Diseña un saga distribuido con pasos, compensaciones idempotentes, eventos outbox y handlers. Usar cuando se necesite: diseñar una transacción distribuida, coordinar una operación que modifica estado en múltiples servicios, agregar compensaciones a un flujo, implementar el patrón Saga (orchestration o choreography), o cuando CASTLE C detecta una transacción multi-servicio sin saga documentada."
---

# /saga-design — Distributed Saga con Compensaciones y Outbox

Descompone un flujo de negocio distribuido en pasos atómicos, diseña la compensación
idempotente de cada paso, genera el diagrama Mermaid (happy path + rollback path), los
handlers con idempotency key, el **Outbox Pattern** (no-opcional) para entrega at-least-once,
y los tests de compensación con escenarios de crash. Alimenta la capa **CASTLE C**.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/domain/saga-patterns.md` | 9 patrones de saga (Choreography, Orchestration, Compensating Tx, Outbox, Inbox, TCC, 2PC, Saga Coordinator, ACID local) con trade-offs y cuándo NO usar | Yes | framework |
| `.king/knowledge/architecture.md` | Límites de servicio y estilo arquitectónico del proyecto | No | project |
| `.king/knowledge/stack.md` | Stack del proyecto para elegir lenguaje de los handlers y librería de la tech | No | project |
| `.king/knowledge/conventions.md` | Naming y convenciones de tests del proyecto | No | project |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión previa de `/genesis` en el proyecto (`.king/` ausente)
- [ ] No hay `flow-description` (ni argumento ni descripción solicitable al usuario) → no hay nada que diseñar
- [ ] El flujo involucra **un solo servicio** sin estado distribuido → un saga no aplica; sugerir transacción ACID local y terminar (graceful, Status PARTIAL)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA hacer el Outbox Pattern opcional ni esconderlo tras un feature flag — el evento se publica en la MISMA transacción local del paso (no `commit` + `publish` separados)
- NUNCA generar una compensación que dependa del estado en memoria del paso original — debe reconstruirse desde el `saga_id` + datos persistidos
- NUNCA generar un handler (forward o compensación) sin `idempotency key` derivada de `saga_id` + `step`
- NUNCA omitir el rollback path del diagrama Mermaid — happy path Y rollback son obligatorios
- NUNCA generar tests sin al menos un escenario de crash (fallo a mitad del saga)

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] `.king/saga/{saga-name}.saga.md` — diseño del saga (tabla de pasos + decisiones)
- [ ] `.king/saga/{saga-name}.mermaid.md` — diagrama Mermaid con happy path Y rollback path
- [ ] `src/saga/{saga-name}/handlers.{ext}` — handlers forward + compensación con idempotency key y outbox
- [ ] `tests/saga/{saga-name}.saga.test.{ext}` — tests de compensación con escenarios de crash
- [ ] `.king/saga/castle-c-summary.md` — resumen para CASTLE C
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase N+1 → Phase N+2
(Context)(Analyze)(Steps)  (Comps)  (Mermaid)(Code)   (Tests)  (CASTLE C)(Session)  (Guide)
            flow            idempot   +rollbk  +outbox  +crash
```

### PARÁMETROS
```
/saga-design [flow-description] [--style orchestration|choreography] [--tech temporal|step-functions|camunda|custom] [--services <a,b,c>]
```
- `flow-description`: descripción en lenguaje natural del flujo de negocio (posicional)
- `--style`: `orchestration` (default — más debuggeable, un coordinador central) | `choreography` (eventos peer-to-peer)
- `--tech`: `temporal` | `step-functions` | `camunda` | `custom` (default — state machine manual con outbox + polling/CDC)
- `--services`: lista de servicios involucrados (si se omite, se infieren del flow-description)

---

## CASTLE activo: C-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.

## Agentes
- **@architect** — Agente principal: descompone el flujo, elige style/tech, define límites de servicio y consistencia
- **@api** — Define los eventos publicados, sus payloads y los contratos de cada paso forward/compensación
- **@qa** — Verifica que cada compensación tiene su test idempotente y que existe al menos un escenario de crash por paso

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

Resumen: Display header → Verificar `.king/` → Detectar/crear workflow → Cargar `context.md` → Inyectar Knowledge (incluyendo `knowledge/domain/saga-patterns.md`).

---

## Phase 1: Analyze Flow

> Descompone el flujo en pasos atómicos identificando participantes y datos de cada paso.

### GATE IN
- [ ] `.king/` existe (genesis ejecutado)
- [ ] `flow-description` disponible (argumento o solicitado al usuario)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver servicios** — usar `--services` si se dio; si no, inferir los participantes del `flow-description` y confirmar la lista con el usuario
2. [ ] **Descomponer en pasos atómicos** — cada paso debe modificar estado en EXACTAMENTE un servicio (atomicidad por servicio). Ej. "reservar inventario", "cobrar pago", "enviar confirmación"
3. [ ] **Identificar datos por paso** — qué input necesita cada paso y qué produce (para reconstruir la compensación sin estado en memoria)
4. [ ] **Elegir style** — `orchestration` (default) salvo que el flujo sea claramente reactivo/desacoplado; documentar el porqué citando `saga-patterns.md`
5. [ ] **Elegir tech** — `custom` (default) salvo `--tech` explícito; mapear a la plantilla correspondiente (ver REFERENCE)
6. [ ] **Marcar el punto de no retorno** — identificar si hay un paso "pivot" tras el cual no hay compensación (ej. envío de email ya despachado → compensación = acción correctiva, no revert)

### CHECKPOINT
> ✅ Verify before continuing

- [ ] Lista de servicios confirmada
- [ ] ≥2 pasos atómicos, cada uno toca un solo servicio
- [ ] Cada paso tiene input y output identificados
- [ ] `style` y `tech` elegidos y justificados

### OUTPUTS
- Variables: `SAGA_NAME`, `SERVICES[]`, `STEPS[]` (con input/output), `STYLE`, `TECH`, `EXT`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo descomponer el flujo en pasos atómicos.
Cause: flow-description ambiguo, o un "paso" toca múltiples servicios (no atómico).
Recovery:
  [ ] Option A: pedir al usuario que detalle la secuencia paso a paso, un servicio por paso
  [ ] Option B: dividir el paso multi-servicio en sub-pasos atómicos
  [ ] Option C: si es un solo servicio → BLOCKING CONDITION (sugerir transacción ACID local), terminar Status PARTIAL

---

## Phase 2: Design Steps

> Para cada paso define: acción forward, datos necesarios, evento emitido, compensación correspondiente.

### GATE IN
- [ ] `STEPS[]` no vacío (Phase 1)

### MUST DO
1. [ ] **Definir acción forward** de cada paso — la operación que avanza el saga
2. [ ] **Definir evento publicado** de cada paso — nombre + payload (debe incluir `saga_id` y los datos para la compensación)
3. [ ] **Asociar compensación** a cada paso forward — el nombre de la operación que lo deshace (se diseña en Phase 3)
4. [ ] **Definir timeout** por paso — tiempo máximo antes de considerar el paso fallido y disparar rollback
5. [ ] **Construir la tabla de pasos** con columnas: `#`, `servicio`, `acción forward`, `evento publicado`, `compensación`, `timeout`

### CHECKPOINT
- [ ] Cada paso tiene acción forward, evento, compensación asociada y timeout
- [ ] Cada payload de evento incluye `saga_id` y datos suficientes para compensar
- [ ] Tabla de pasos completa

### OUTPUTS
- Variable: `STEP_TABLE` (tabla forward/evento/compensación/timeout)

### IF FAILS
ERROR: Un paso no tiene compensación o evento definido.
Cause: paso pivot sin acción correctiva, o evento sin datos para compensar.
Recovery:
  [ ] Option A: para paso pivot → definir acción correctiva (forward recovery) en vez de revert
  [ ] Option B: enriquecer el payload del evento con los datos faltantes para la compensación
  [ ] Option C: ver `skills/_shared/if-fails-templates.md` → FAIL-VALIDATION

---

## Phase 3: Design Compensations

> Asegura que cada compensación sea idempotente y NO requiera el estado en memoria del paso original.

### GATE IN
- [ ] `STEP_TABLE` con compensaciones asociadas (Phase 2)

### MUST DO
1. [ ] **Idempotencia** — cada compensación debe poder ejecutarse N veces con el mismo `saga_id` produciendo el mismo estado final (usar tabla de `compensated` keys o estado del saga como guardia)
2. [ ] **Sin estado en memoria** — la compensación reconstruye lo que necesita desde `saga_id` + datos persistidos en el evento/saga state, nunca desde variables del proceso forward
3. [ ] **Orden inverso** — definir el rollback como compensación de los pasos completados en orden inverso (LIFO) al de ejecución
4. [ ] **Compensaciones semánticas** — documentar que una compensación deshace el EFECTO de negocio (ej. "reembolsar cobro"), no necesariamente borra el registro físico (audit trail)
5. [ ] **Pasos no compensables** — para el paso pivot, documentar la acción correctiva (forward recovery) y que la compensación de los pasos previos NO se dispara una vez cruzado el pivot

### CHECKPOINT
- [ ] Cada compensación es idempotente (guardia por `saga_id`/`step` documentada)
- [ ] Ninguna compensación depende de estado en memoria del forward
- [ ] Orden de rollback definido (inverso al forward)
- [ ] Paso(s) no compensable(s) documentado(s) con su acción correctiva

### OUTPUTS
- Variable: `COMPENSATIONS[]` (con guardia de idempotencia y orden inverso)

### IF FAILS
ERROR: Compensación no idempotente o dependiente de estado en memoria.
Cause: la compensación asume datos del proceso forward o no tiene guardia anti-doble-revert.
Recovery:
  [ ] Option A: agregar guardia `IF saga.step_state == compensated THEN noop`
  [ ] Option B: persistir los datos necesarios en el evento/saga state y leerlos por `saga_id`
  [ ] Option C: marcar el paso como pivot/no-compensable y usar forward recovery

---

## Phase 4: Generate Mermaid

> Diagrama con happy path, rollback path y timeouts.

### GATE IN
- [ ] `STEP_TABLE` y `COMPENSATIONS[]` listos (Phases 2-3)

### MUST DO
1. [ ] **Generar happy path** — secuencia de pasos forward con sus eventos publicados (orchestration: coordinador → servicio; choreography: servicio → servicio)
2. [ ] **Generar rollback path** — desde el punto de fallo, las compensaciones en orden inverso de los pasos ya completados
3. [ ] **Anotar timeouts** — marcar el timeout de cada paso en el diagrama
4. [ ] **Marcar el pivot** — si existe, indicar el punto de no retorno en el diagrama
5. [ ] **Escribir** `.king/saga/{SAGA_NAME}.mermaid.md` con el bloque ```mermaid``` (sequenceDiagram o stateDiagram-v2)

### CHECKPOINT
- [ ] El diagrama incluye happy path COMPLETO
- [ ] El diagrama incluye rollback path COMPLETO (compensaciones en orden inverso)
- [ ] Timeouts anotados
- [ ] `.king/saga/{SAGA_NAME}.mermaid.md` existe

### OUTPUTS
- `.king/saga/{SAGA_NAME}.mermaid.md`

### IF FAILS
ERROR: Diagrama Mermaid incompleto (falta rollback path).
Cause: solo se generó el happy path, violando ABSOLUTE RESTRICTIONS.
Recovery:
  [ ] Option A: derivar el rollback path desde `COMPENSATIONS[]` en orden inverso y regenerar
  [ ] Option B: validar sintaxis Mermaid (sequenceDiagram/stateDiagram-v2) si el render falla
  [ ] Option C: ver `skills/_shared/if-fails-templates.md` → FAIL-ARTIFACT-MISSING

---

## Phase 5: Generate Code

> Handlers con idempotency key, outbox publishing y estado del saga. Outbox NO-opcional.

### GATE IN
- [ ] Diseño completo (Phases 1-4)
- [ ] `STACK`/`EXT` resuelto (o lenguaje pedido al usuario)

### MUST DO
1. [ ] **Generar saga state** — estructura persistida con `saga_id`, paso actual, estado (`running|compensating|completed|failed`) y datos por paso
2. [ ] **Generar handlers forward** — uno por paso, cada uno con `idempotency key = hash(saga_id + step)` y guardia anti-reproceso
3. [ ] **Generar handlers de compensación** — uno por paso, idempotentes, leyendo datos por `saga_id` (de Phase 3)
4. [ ] **Implementar Outbox Pattern (NO-OPCIONAL)** — el evento se inserta en la tabla `outbox` dentro de la MISMA transacción local que el cambio de estado del paso; un relay (polling/CDC) publica desde la outbox con at-least-once
5. [ ] **Generar el coordinador** (si `orchestration`) o los listeners de eventos (si `choreography`) según `STYLE`
6. [ ] **Aplicar plantilla de `TECH`** — adaptar a temporal/step-functions/camunda/custom (ver REFERENCE)
7. [ ] **Escribir** `src/saga/{SAGA_NAME}/handlers.{EXT}` y el diseño en `.king/saga/{SAGA_NAME}.saga.md` (con la tabla de pasos)

### CHECKPOINT
- [ ] Cada handler (forward y compensación) tiene idempotency key derivada de `saga_id`
- [ ] El evento se publica vía outbox EN LA MISMA TRANSACCIÓN del cambio de estado (no commit+publish separados)
- [ ] Existe el saga state persistido
- [ ] Coordinador (orchestration) o listeners (choreography) generados según STYLE
- [ ] `src/saga/{SAGA_NAME}/handlers.{EXT}` y `.king/saga/{SAGA_NAME}.saga.md` existen

### OUTPUTS
- `src/saga/{SAGA_NAME}/handlers.{EXT}`
- `.king/saga/{SAGA_NAME}.saga.md`

### IF FAILS
ERROR: Outbox separado de la transacción del paso (dual-write).
Cause: el código hace `commit()` del estado y luego `publish()` por separado → riesgo de pérdida de evento.
Recovery:
  [ ] Option A: mover el INSERT en `outbox` a la misma transacción del cambio de estado y mover la publicación a un relay
  [ ] Option B: si la tech maneja la durabilidad (temporal/step-functions), documentar cómo sustituye al outbox y por qué es equivalente at-least-once
  [ ] Option C: ver `skills/_shared/if-fails-templates.md` → FAIL-VALIDATION

---

## Phase 6: Generate Tests

> Escenarios de compensación con mock de fallos en cada paso (crash scenarios).

### GATE IN
- [ ] `src/saga/{SAGA_NAME}/handlers.{EXT}` existe (Phase 5)

### MUST DO
1. [ ] **Test happy path** — todos los pasos completan, saga state = `completed`
2. [ ] **Test de compensación por paso** — para CADA paso, simular fallo en ese paso y verificar que los pasos previos se compensan en orden inverso
3. [ ] **Test de idempotencia** — llamar cada compensación DOS veces con el mismo `saga_id` y verificar estado final idéntico (no doble revert)
4. [ ] **Test de crash** — simular crash entre el cambio de estado y la publicación; verificar que el outbox relay re-publica el evento (at-least-once) y los handlers lo procesan idempotentemente sin duplicar efectos
5. [ ] **Test de timeout** — simular un paso que excede su timeout y verificar disparo del rollback
6. [ ] **Escribir** `tests/saga/{SAGA_NAME}.saga.test.{EXT}`

### CHECKPOINT
- [ ] Existe test de happy path
- [ ] Existe un test de compensación por cada paso
- [ ] Existe test de idempotencia (doble llamada con mismo `saga_id`)
- [ ] Existe al menos un escenario de crash (outbox re-publish + procesamiento idempotente)
- [ ] `tests/saga/{SAGA_NAME}.saga.test.{EXT}` existe

### OUTPUTS
- `tests/saga/{SAGA_NAME}.saga.test.{EXT}`

### IF FAILS
ERROR: Faltan escenarios de crash o de idempotencia.
Cause: los tests cubren solo el happy path.
Recovery:
  [ ] Option A: generar un test por paso inyectando un mock que lanza fallo en ese paso
  [ ] Option B: agregar el test de doble compensación con mismo `saga_id`
  [ ] Option C: agregar el test de crash que verifica re-publicación desde la outbox

---

## Phase 7: CASTLE C Report

> Evalúa la capa Contracts: transacción multi-servicio cubierta por saga documentado.

### GATE IN
- [ ] Saga, handlers y tests generados (Phases 4-6)

### MUST DO
1. [ ] **Verificar cobertura** — cada cambio de estado multi-servicio del flujo tiene paso + compensación documentados
2. [ ] **Verificar eventos** — cada evento publicado tiene payload contractualmente definido (consumible por otros servicios)
3. [ ] **Escribir** `.king/saga/castle-c-summary.md` con: pasos, compensaciones, cobertura, veredicto
4. [ ] **Asignar veredicto CASTLE C** — `PASS` si todos los pasos tienen compensación idempotente + outbox; `CONDITIONAL` si hay paso pivot sin acción correctiva documentada o compensación sin test (nunca BREACH en v1)

### CHECKPOINT
- [ ] `.king/saga/castle-c-summary.md` existe
- [ ] Veredicto C asignado (PASS | CONDITIONAL)

### OUTPUTS
- `.king/saga/castle-c-summary.md`

### IF FAILS
ERROR: No se pudo evaluar CASTLE C.
Cause: conteo de pasos/compensaciones inconsistente.
Recovery:
  [ ] Option A: recontar desde `STEP_TABLE` y `COMPENSATIONS[]`
  [ ] Option B: emitir summary con veredicto CONDITIONAL y nota de incertidumbre

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] `.king/saga/{SAGA_NAME}.saga.md`
  - [ ] `.king/saga/{SAGA_NAME}.mermaid.md` (happy path Y rollback path)
  - [ ] `src/saga/{SAGA_NAME}/handlers.{EXT}`
  - [ ] `tests/saga/{SAGA_NAME}.saga.test.{EXT}`
  - [ ] `.king/saga/castle-c-summary.md`
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Outbox en la misma transacción del paso (no dual-write)
- [ ] Cada compensación es idempotente y sin estado en memoria
- [ ] Tests incluyen al menos un escenario de crash
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(copiar de Phase 7: PASS=FORTIFIED, WARNING=CONDITIONAL)_ |
| Artifacts | _(saga.md, mermaid.md, handlers, tests, castle-c-summary)_ |
| Next Recommended | `/contract-test` (contratos de los eventos) o `/qa` |
| Risks | _(paso pivot sin acción correctiva, compensación sin test, o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Saga generado y tests de compensación en verde | `/contract-test` (contractualizar los eventos entre servicios) |
| Eventos publicados sin contrato definido | `/contract-test --consumer ... --provider ...` |
| Handlers necesitan resiliencia (retry/timeout/circuit breaker) | `/resilience-weave` sobre las llamadas inter-servicio |
| Saga listo para validar end-to-end | `/qa` (CASTLE C verifica la transacción distribuida) |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Plantillas por tecnología (`--tech`)

| Tech | Modelo | Compensación | Durabilidad / Outbox |
|------|--------|--------------|----------------------|
| `temporal` | Workflow + Activities, retry policies, timers | Activities de compensación en `defer`/saga helper | Temporal persiste el estado del workflow (event sourcing); el outbox local sigue aplicando para efectos hacia sistemas externos |
| `step-functions` | ASL state machine con `Catch`/`Retry` | Estados de compensación tras `Catch` | El servicio durable de AWS persiste transiciones; outbox para escrituras a la DB del servicio |
| `camunda` | BPMN process con compensation events (boundary + throw) | `bpmn:compensateEventDefinition` por tarea | El engine persiste el proceso; outbox para los side effects de cada service task |
| `custom` (default) | State machine manual en código | Handler de compensación por paso, disparado por el coordinador | **Outbox Pattern explícito**: tabla `outbox` + relay (polling o CDC con Debezium) |

> El Outbox Pattern es **no-opcional**. Para `custom` se implementa explícitamente.
> Para techs durables (temporal/step-functions/camunda), el engine cubre la durabilidad del estado del saga,
> pero el outbox local SIGUE aplicando para publicar eventos/efectos hacia la DB y sistemas externos del propio servicio.

### Outbox Pattern — invariante

```
BEGIN TX (DB del servicio)
  UPDATE estado_negocio ...           -- el efecto del paso
  INSERT INTO outbox (saga_id, event, payload, created_at)  -- el evento, MISMA TX
COMMIT
-- relay aparte (polling/CDC) lee outbox y publica al broker → at-least-once
-- el consumidor es idempotente (inbox/dedupe por saga_id+event)
```

Esto elimina el **dual-write problem** (commit del estado + publish del evento como operaciones separadas,
donde un crash entre ambas pierde el evento o lo publica sin el estado).

### Idempotency key

```
idempotency_key = hash(saga_id + step_name)
```
El handler guarda las keys procesadas (tabla/inbox); si la key ya existe → `noop` (devuelve el resultado previo).
Esto hace que tanto el reintento del forward como la doble compensación sean seguros.

### Orchestration vs Choreography

| Aspecto | Orchestration (default) | Choreography |
|---------|-------------------------|--------------|
| Coordinación | Coordinador central dirige cada paso | Cada servicio reacciona a eventos |
| Debuggeabilidad | Alta (un punto de control) | Baja (lógica distribuida) |
| Acoplamiento | Coordinador conoce todos los pasos | Servicios acoplados por eventos |
| Cuándo | Flujos complejos, muchos pasos, necesidad de visibilidad | Flujos simples, servicios autónomos, bajo acoplamiento |

Ver `knowledge/domain/saga-patterns.md` para la comparativa completa y cuándo NO usar cada patrón.

### Integración con CASTLE C

Regla: toda función que modifica estado en ≥2 servicios sin saga documentado produce un WARNING
de CASTLE C (veredicto CONDITIONAL, nunca BREACH en v1) con el mensaje
"transacción distribuida sin saga detectada" y la sugerencia de ejecutar `/saga-design` sobre el flujo.
Ver `skills/castle/SKILL.md` capa C.

### Degradación grácil

Si `knowledge/domain/saga-patterns.md` no existe, el skill continúa con los defaults
(orchestration/custom) y emite WARN recomendando regenerar el knowledge del framework.
Si el stack no se detecta, el skill pregunta el lenguaje de los handlers antes de generar código.
