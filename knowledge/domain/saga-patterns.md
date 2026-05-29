# Saga Patterns — Guía de Transacciones Distribuidas

> Versión completa. Para inyección en agents usar `knowledge/_inject/saga-patterns.md`.
>
> Una transacción distribuida coordina cambios de estado en múltiples servicios o
> bases de datos que NO comparten un único motor transaccional. El problema central:
> no existe un `COMMIT` global. Estos 9 patrones cubren el espectro desde "una sola
> base de datos" hasta "saga orquestada con compensaciones".

---

## Mapa de Decisión Rápida

```
¿Todo el cambio cabe en UNA base de datos?
  └─ SÍ  → ACID local (1). No inventes un saga.
  └─ NO  → ¿Múltiples servicios deben cambiar estado de forma consistente?
            └─ SÍ → Saga. Elegí estilo:
                     ├─ ¿Pocos pasos, dominios desacoplados? → Choreography (3)
                     └─ ¿Flujo complejo, necesitás visibilidad? → Orchestration (4)
            └─ NO → ¿Solo necesitás publicar un evento de forma fiable?
                     └─ Outbox (6) + Inbox (7) en el consumidor.
```

**Regla transversal innegociable**: cualquier saga que publique eventos para
coordinar pasos DEBE usar **Outbox Pattern (6)** para garantizar entrega
*at-least-once*. No es opcional ni un feature flag. Y como el delivery es
*at-least-once*, todo handler y toda compensación DEBE ser **idempotente**.

---

## 1. ACID Local

Una única transacción contra un único motor de base de datos. `BEGIN … COMMIT`
con garantías Atomicity, Consistency, Isolation, Durability reales del motor.

### Isolation Levels (PostgreSQL / SQL estándar)

| Nivel | Previene | Permite todavía | Cuándo |
|-------|----------|-----------------|--------|
| Read Committed (default PG) | Dirty reads | Non-repeatable reads, phantom reads | CRUD estándar |
| Repeatable Read | + Non-repeatable reads | Phantom reads (PG los previene vía snapshot) | Reportes consistentes, lectura-luego-escritura |
| Serializable | Todo | Nada (puede abortar con `40001`) | Invariantes cruzados entre filas, contabilidad |

### Trade-offs

- **A favor**: garantía REAL de atomicidad. Rollback automático. Sin compensaciones
  que escribir, sin estado intermedio que limpiar. Es lo más simple y lo más correcto.
- **En contra**: solo funciona dentro de UN motor. No cruza servicios ni bases.
  `Serializable` puede abortar transacciones bajo contención (hay que reintentar).

### Cuándo NO usarlo

- Cuando el cambio toca **dos o más servicios** con bases independientes: ACID local
  no puede coordinar eso. Forzarlo lleva a *distributed monolith* (un servicio
  escribiendo en la DB de otro).
- Cuando se intenta extender ACID entre servicios vía 2PC sobre microservicios HTTP
  → ver patrón 2 (por qué es problemático).

> **Principio**: si el cambio cabe en una sola base de datos, NO diseñes un saga.
> Un saga introduce estados intermedios visibles, compensaciones y complejidad
> operativa que ACID local te regala gratis.

---

## 2. Two-Phase Commit (2PC)

Un coordinador transaccional pregunta a todos los participantes "¿pueden
commitear?" (fase prepare), y si todos dicen sí, ordena el commit (fase commit).
Garantiza atomicidad distribuida fuerte.

```
Coordinator                  Participant A        Participant B
    │── prepare ──────────────────▶│                   │
    │── prepare ──────────────────────────────────────▶│
    │◀── vote-yes ──────────────────│                   │
    │◀── vote-yes ──────────────────────────────────────│
    │── commit ───────────────────▶│ (locks held all   │
    │── commit ───────────────────────────────────────▶│  this time)
```

### Trade-offs

- **A favor**: atomicidad fuerte real (todos commitean o nadie lo hace). Consistencia
  inmediata sin estados intermedios visibles.
- **En contra (graves)**:
  - **Blocking**: los participantes mantienen *locks* desde `prepare` hasta `commit`.
    Si el coordinador cae entre fases, los recursos quedan bloqueados (in-doubt)
    indefinidamente.
  - **Coordinator SPOF**: el coordinador es un único punto de fallo. Su caída
    paraliza la transacción.
  - **Latencia y throughput**: dos round-trips síncronos + locks → escala mal.
  - **Acoplamiento**: requiere que todos los participantes hablen el mismo protocolo
    transaccional (XA). HTTP/REST y la mayoría de message brokers NO lo soportan.

### Cuándo NO usarlo

- **En microservicios sobre HTTP/REST/gRPC**: no hay protocolo XA; emularlo es frágil.
- Cuando la disponibilidad importa más que la consistencia inmediata (teorema CAP:
  2PC sacrifica disponibilidad). Para la inmensa mayoría de sistemas distribuidos
  modernos, **preferí un saga con consistencia eventual** sobre 2PC.
- Casos donde aún tiene sentido: transacciones distribuidas dentro de un mismo
  motor con soporte XA nativo (p. ej. múltiples datasources en un monolito Java/JTA),
  no entre servicios autónomos.

---

## 3. Saga Choreography

Cada servicio reacciona a eventos y publica los suyos. No hay coordinador central:
el flujo emerge de la cadena de eventos. Servicio A termina → publica evento →
Servicio B reacciona → publica evento → Servicio C reacciona, etc.

```
OrderCreated ─▶ [Inventory] ─ InventoryReserved ─▶ [Payment] ─ PaymentCharged ─▶ [Shipping]
                     │                                  │
                     └─ InventoryFailed ◀───── PaymentFailed (compensación hacia atrás)
```

### Trade-offs

- **A favor**: máximo desacoplamiento. Cada servicio solo conoce sus eventos de
  entrada/salida. No hay componente central que mantener. Escala bien para flujos
  cortos y estables.
- **En contra**:
  - **Debugging difícil**: el flujo está distribuido en N servicios. No hay un lugar
    único que muestre "en qué paso estoy". Trazas distribuidas (OpenTelemetry) pasan
    de "lindo a tener" a OBLIGATORIO.
  - **Acoplamiento implícito por eventos**: agregar un paso intermedio obliga a
    reconfigurar quién escucha qué. El "contrato" es el conjunto de eventos.
  - **Dependencias cíclicas** fáciles de introducir sin querer.
  - **Razonamiento global complejo**: nadie es dueño del flujo completo.

### Cuándo NO usarlo

- Flujos con **muchos pasos** (>4-5) o con ramificación condicional: el espagueti de
  eventos se vuelve inmanejable. Usá **Orchestration (4)**.
- Cuando el negocio exige **visibilidad del estado del saga** (dashboards de "órdenes
  en proceso", soporte que necesita ver dónde se atascó algo).
- Equipos sin tracing distribuido maduro: vas a quedar ciego ante fallos.

---

## 4. Saga Orchestration

Un **orquestador** (coordinador) explícito dirige el flujo: invoca cada paso, espera
su resultado, decide el siguiente y dispara compensaciones ante fallos. El estado del
saga vive en un solo lugar.

```
                 ┌──────────────────────────────┐
                 │      Saga Orchestrator        │
                 │  (state machine + persistencia)│
                 └──────────────────────────────┘
                   │ 1.reserve   │ 2.charge   │ 3.ship
                   ▼             ▼            ▼
            [Inventory]     [Payment]    [Shipping]
                   │             │
            (ante fallo: compensa 2 y luego 1 en orden inverso)
```

### Tecnologías

- **Temporal.io**: workflows como código durable; el orquestador "recuerda" su
  posición tras un crash (event sourcing del workflow). Retries y timers nativos.
- **AWS Step Functions**: definición declarativa (ASL JSON) con `Catch`/`Retry`
  por estado. Serverless, managed.
- **Camunda / Zeebe (BPMN)**: modelado visual del proceso con *compensation events*.
- **Custom**: state machine propia + persistencia del estado + outbox + polling/CDC.
  Es el default de King cuando no hay infra de workflow engine.

### Trade-offs

- **A favor**: flujo **visible y centralizado**. Debugging directo (el estado del saga
  está en una tabla/workflow). Maneja flujos complejos y condicionales con claridad.
  Punto natural para retry policies y timeout handling.
- **En contra**:
  - El orquestador puede volverse un **acoplamiento central** (god service) si absorbe
    lógica de negocio que pertenece a los servicios.
  - Punto adicional que mantener y escalar (mitigable: el estado se persiste, no es un
    SPOF si está bien diseñado con recuperación).
  - Más infraestructura que choreography.

### Cuándo NO usarlo

- Flujos **triviales de 2 pasos** entre dominios muy desacoplados: la orquestación es
  overkill, choreography basta.
- Cuando se cae en la tentación de meter TODA la lógica de negocio en el orquestador
  → deja de ser coordinación y se vuelve un monolito disfrazado.

> **Default de King**: orchestration sobre choreography. Razón: la *debuggeabilidad*
> y la visibilidad del estado valen más que el desacoplamiento extremo en la mayoría
> de los casos reales de negocio.

---

## 5. Compensating Transactions

Un saga no puede hacer `ROLLBACK` distribuido. En su lugar, cada paso forward tiene
una **compensación**: una acción de negocio que revierte (semánticamente) su efecto.
Si el paso 3 falla, se ejecutan las compensaciones de 2 y 1 en orden inverso.

### Undo vs. Compensate — NO son lo mismo

- **Undo (rollback)**: borra el efecto como si nunca hubiera ocurrido. Solo posible
  dentro de ACID local.
- **Compensate**: emite una NUEVA transacción de negocio que neutraliza el efecto,
  dejando rastro. No "deshace": *corrige*.
  - Pago cobrado → compensación = **reembolso** (no "borrar el cobro"; el cobro
    existió y queda en el ledger, el reembolso lo neutraliza).
  - Inventario reservado → compensación = **liberar la reserva**.
  - Email enviado → **no se puede compensar** (un email enviado no se desenvía).
    Estos pasos van AL FINAL del saga, después del último punto de fallo posible.

### Idempotencia — OBLIGATORIA

Como el delivery es *at-least-once* (ver Outbox), una compensación puede ejecutarse
**más de una vez**. Debe ser idempotente: ejecutarla N veces deja el mismo estado que
ejecutarla una vez.

```typescript
// MAL: doble ejecución → doble reembolso
async function compensatePayment(sagaId: string, amount: number) {
  await paymentGateway.refund(amount); // sin control de duplicados
}

// BIEN: idempotente por saga_id, sin depender de estado del paso original
async function compensatePayment(sagaId: string) {
  const charge = await db.charges.findBySaga(sagaId);
  if (!charge || charge.status === 'refunded') return; // ya compensado → no-op
  await paymentGateway.refund({ idempotencyKey: `refund-${sagaId}` });
  await db.charges.markRefunded(sagaId);
}
```

### Trade-offs

- **A favor**: la única forma realista de "rollback" en sistemas distribuidos sin 2PC.
- **En contra**:
  - **No hay aislamiento**: entre el paso forward y su compensación, otros pueden ver
    el estado intermedio (*dirty reads* a nivel negocio). Mitigación: estados
    "pending"/"reserved" semánticos, o el patrón TCC (8).
  - Escribir compensaciones correctas e idempotentes es trabajo real y propenso a bugs.
  - Algunas acciones son **irreversibles** (emails, llamadas a terceros sin refund).

### Cuándo NO usarlo

- Cuando ACID local resuelve el caso: no inventes compensaciones para algo que cabe
  en una transacción.
- No es que "no se use" — en un saga las compensaciones son obligatorias. El error es
  diseñarlas dependiendo del estado en memoria del paso original (no sobreviven a un
  restart). **Una compensación debe poder ejecutarse solo con el `saga_id`**.

---

## 6. Outbox Pattern — OBLIGATORIO

El problema del *dual write*: si escribís en la DB y LUEGO publicás al broker como
dos operaciones separadas, un crash entre ambas deja inconsistencia (DB cambió pero
el evento se perdió, o viceversa). No hay transacción que abarque DB + broker.

**Solución**: escribí el evento en una tabla `outbox` **dentro de la misma
transacción** del cambio de estado. Un proceso aparte (relay) lee la outbox y publica
al broker. Si el relay falla, reintenta → *at-least-once delivery* garantizado.

```sql
BEGIN;
  UPDATE orders SET status = 'reserved' WHERE id = $1;       -- cambio de negocio
  INSERT INTO outbox (id, aggregate_id, type, payload, created_at)
    VALUES (gen_random_uuid(), $1, 'InventoryReserved', $2, now()); -- evento
COMMIT;  -- ambos o ninguno: ATÓMICO dentro de UNA base
```

### Publicación: dos mecanismos

- **Polling Publisher**: un worker hace `SELECT … FROM outbox WHERE published_at IS
  NULL ORDER BY created_at` cada N ms, publica y marca como enviado. Simple, funciona
  en cualquier DB.
- **CDC (Change Data Capture)**: herramientas como Debezium leen el WAL/binlog y
  publican los inserts de la outbox sin polling. Menor latencia, más infraestructura.

### Ordering

- El `ORDER BY created_at` (o un secuencial monótono) preserva el orden de emisión.
- Para orden estricto por agregado, particioná el broker por `aggregate_id`
  (p. ej. Kafka key = aggregate_id) → mismo agregado, misma partición, orden preservado.

### Trade-offs

- **A favor**: elimina el dual-write. Garantiza que NINGÚN evento se pierde
  (*at-least-once*). El relay puede reiniciarse sin perder eventos.
- **En contra**:
  - Entrega *at-least-once*, NO *exactly-once*: los consumidores recibirán duplicados
    eventualmente → exige **Inbox/idempotencia** del lado consumidor (patrón 7).
  - Latencia de polling (mitigable con CDC).
  - La tabla outbox crece → necesita limpieza (archivar/borrar eventos publicados).

### Cuándo NO usarlo

- **NUNCA se omite** cuando un saga publica eventos para coordinar. El delivery fiable
  no es opcional. Saltarse outbox = aceptar pérdida silenciosa de eventos = saga rota.
- El ÚNICO caso donde no aplica: no estás publicando eventos (todo es ACID local).

> **King MANDA Outbox**. En `/saga-design` el outbox es no-opcional, sin feature flag.
> Un saga sin outbox no garantiza entrega y, por tanto, no es un saga correcto.

---

## 7. Inbox Pattern

El contrapeso del Outbox. Como el delivery es *at-least-once*, el consumidor recibirá
mensajes duplicados. El Inbox **deduplica** registrando los IDs de mensajes ya
procesados antes de actuar.

```sql
BEGIN;
  -- idempotency key = message_id (único por evento del productor)
  INSERT INTO inbox (message_id, processed_at) VALUES ($1, now())
    ON CONFLICT (message_id) DO NOTHING;   -- ya procesado → no inserta
  -- Si la fila ya existía (rowcount = 0), abortar: es un duplicado.
  -- Si es nueva, procesar el efecto de negocio EN LA MISMA transacción:
  UPDATE accounts SET balance = balance - $2 WHERE id = $3;
COMMIT;
```

### Idempotency Key

- Usá un identificador estable del mensaje (`message_id` del productor, o el
  `saga_id + step`). NO el offset del broker (cambia entre reintentos).
- La inserción en `inbox` y el efecto de negocio deben estar en la MISMA transacción,
  o el dedupe no protege contra crashes a mitad de procesamiento.

### Trade-offs

- **A favor**: convierte *at-least-once* en *effectively-exactly-once* a nivel de
  efecto de negocio. Es la pieza que hace seguro al Outbox.
- **En contra**:
  - Tabla inbox crece → requiere retención/limpieza (TTL de IDs procesados).
  - El dedupe es por consumidor: cada consumidor mantiene su propio inbox.

### Cuándo NO usarlo

- Cuando el handler ya es **naturalmente idempotente** por su lógica (p. ej. un `SET
  status = 'shipped'` que es idempotente por definición), el inbox puede ser
  innecesario. Pero ante la duda, deduplicá: es más barato que un doble cobro.
- No es alternativa al Outbox: son complementarios (productor=outbox, consumidor=inbox).

---

## 8. TCC (Try-Confirm-Cancel)

Un saga de dos fases a nivel de negocio (no de protocolo XA). Cada participante expone
tres operaciones:

1. **Try**: reserva los recursos sin aplicar el efecto definitivo (p. ej. "congelar"
   el monto del pago, "reservar" el stock).
2. **Confirm**: aplica el efecto usando lo reservado en Try. Debe ser idempotente y
   no debe fallar por reglas de negocio (ya se validó en Try).
3. **Cancel**: libera lo reservado en Try si algún participante no pudo confirmar.

```
Try-all ──▶ ¿todos OK?
              ├─ SÍ  → Confirm-all  (aplica)
              └─ NO  → Cancel-all   (libera reservas)
```

### TCC vs. Saga con Compensaciones

- TCC **reserva primero** → reduce las *dirty reads*: el recurso queda "apartado",
  nadie más lo toma. Da un aislamiento de negocio que el saga compensatorio puro no
  tiene.
- Saga compensatorio aplica el efecto real de una y compensa después → ventana de
  inconsistencia mayor.

### Trade-offs

- **A favor**: mejor aislamiento (reservas), menos estados intermedios "sucios".
  Confirm/Cancel son operaciones acotadas y predecibles.
- **En contra**:
  - **Triple esfuerzo**: cada servicio debe implementar 3 operaciones en vez de 1+1.
  - **Timeouts de reserva**: una reserva en estado Try debe expirar si nunca llega
    Confirm/Cancel (el coordinador cae) → reaper que libera reservas vencidas.
  - Acoplamiento al contrato TCC: todos los participantes deben soportarlo.

### Cuándo NO usarlo

- Cuando los recursos **no son reservables** (no podés "apartar" un email, ni
  pre-reservar una llamada a un tercero sin API de hold). TCC necesita un concepto de
  reserva.
- Flujos simples donde una saga compensatoria basta: TCC triplica el código por un
  aislamiento que quizás no necesitás.
- Servicios de terceros que no exponen Try/Confirm/Cancel.

---

## 9. Saga Coordinator (State Machine)

La implementación concreta del orquestador (patrón 4) cuando se hace **custom**. Es
una máquina de estados persistida que conoce: en qué paso está cada saga, qué viene
después, cómo reintentar y cuándo abortar hacia compensaciones.

### Componentes

```
┌─ Saga State (persistido) ─────────────────────────────┐
│  saga_id, current_step, status (running/compensating/  │
│  completed/failed), payload, step_results, attempts     │
└────────────────────────────────────────────────────────┘
        │ avanza/retrocede según resultado de cada paso
        ▼
┌─ Retry Policy ──────────────┐   ┌─ Timeout Handling ──────────┐
│ max_attempts, backoff       │   │ por paso: si no responde en  │
│ exponencial + jitter,       │   │ T → reintento o compensación │
│ qué errores son retriables  │   │ saga global: deadline total  │
└─────────────────────────────┘   └──────────────────────────────┘
```

### State Machine

```
            ┌─────────┐   step ok    ┌──────────┐   all steps ok   ┌───────────┐
   start ──▶│ RUNNING │─────────────▶│ RUNNING  │─────────────────▶│ COMPLETED │
            └─────────┘   (next)     └──────────┘                  └───────────┘
                 │ step fail (no retriable o agotó retries)
                 ▼
            ┌──────────────┐  compensaciones en orden inverso  ┌────────┐
            │ COMPENSATING │──────────────────────────────────▶│ FAILED │
            └──────────────┘                                   └────────┘
```

### Retry Policy

- Distinguí errores **retriables** (timeout de red, 503) de **no-retriables** (400,
  regla de negocio violada). Solo reintentá los primeros.
- Backoff **exponencial con jitter** para no martillar un servicio caído.
- `max_attempts` acotado → al agotarlo, transición a `COMPENSATING`.

### Timeout Handling

- **Por paso**: si un paso no responde dentro de su deadline, el coordinador decide
  (reintentar o iniciar compensación). Clave: el paso pudo ejecutarse igual → la
  idempotencia del handler y el inbox del lado receptor protegen.
- **Global**: deadline del saga completo para evitar sagas "zombi" eternos.
- **Recuperación tras crash**: como el estado está persistido, al reiniciar el
  coordinador retoma cada saga `RUNNING`/`COMPENSATING` desde su `current_step`.

### Trade-offs

- **A favor**: control total. Sin dependencia de un workflow engine externo. El estado
  es una tabla que podés consultar/auditar. Sobrevive a crashes (estado persistido).
- **En contra**:
  - **Reinventás** lo que Temporal/Step Functions ya resuelven (durabilidad, retries,
    timers). Mucho código de plomería propenso a bugs sutiles (race conditions,
    timeouts mal manejados).
  - Mantener la state machine + el relay del outbox + los reapers de timeout es carga
    operativa real.

### Cuándo NO usarlo

- Si ya tenés (o podés adoptar) **Temporal, Step Functions o Camunda**: usalos. Un
  coordinator custom solo se justifica cuando no hay infra de workflow engine o los
  requisitos son muy específicos.
- Para sagas de 2-3 pasos sin retries complejos, choreography puede ser suficiente y
  evita construir toda la máquina de estados.

---

## Tabla Comparativa

| Patrón | Consistencia | Acoplamiento | Complejidad impl. | Debuggeabilidad | Cuándo usar | Cuándo NO |
|--------|--------------|--------------|-------------------|-----------------|-------------|-----------|
| **ACID local** | Fuerte (inmediata) | N/A (1 DB) | Mínima | Trivial | Cambio cabe en una sola DB | Cruza servicios/bases |
| **2PC** | Fuerte (inmediata) | Alto (XA) | Media | Media | Datasources XA en un proceso | Microservicios HTTP; alta disponibilidad |
| **Saga Choreography** | Eventual | Bajo (vía eventos) | Media | Difícil | Pocos pasos, dominios desacoplados | >4-5 pasos; sin tracing distribuido |
| **Saga Orchestration** | Eventual | Medio (orquestador) | Media-Alta | Alta (estado central) | Flujos complejos, necesitás visibilidad | Flujo trivial de 2 pasos |
| **Compensating Tx** | Eventual | — (parte del saga) | Media | Media | Todo saga (rollback distribuido) | Cabe en ACID local; compensar irreversibles |
| **Outbox** | At-least-once | Bajo | Baja-Media | Alta | **SIEMPRE que un saga publique eventos** | Solo si NO publicás eventos |
| **Inbox** | Effectively-once | Bajo | Baja | Alta | Consumidor de eventos at-least-once | Handler ya idempotente por naturaleza |
| **TCC** | Eventual (con reserva) | Alto (3 ops) | Alta | Media | Recursos reservables, necesitás aislamiento | Recursos no reservables; flujos simples |
| **Saga Coordinator** | Eventual | Medio | Alta | Alta | Orquestación custom sin workflow engine | Ya tenés Temporal/Step Functions |

### Reglas de oro (innegociables)

1. **Si cabe en una DB → ACID local.** No diseñes un saga por moda.
2. **Outbox es OBLIGATORIO**, no opcional, en cualquier saga que publique eventos.
   Garantiza *at-least-once delivery*. Saltárselo = pérdida silenciosa de eventos.
3. **Compensaciones e idempotencia van de la mano.** Como el delivery es
   *at-least-once*, toda compensación y todo handler DEBEN ser idempotentes (por
   `saga_id` / `message_id`), y NO deben depender del estado en memoria del paso
   original — solo del `saga_id` persistido.
4. **At-least-once (Outbox) + dedupe (Inbox) = effectively-exactly-once.** Son
   complementarios: nunca uno sin pensar en el otro.
5. **Default de King: orchestration custom + outbox.** Priorizamos debuggeabilidad y
   entrega fiable sobre el desacoplamiento extremo de choreography.

---

## Integración con CASTLE C (Contracts)

Cuando un agente detecta una operación que **modifica estado en múltiples servicios
sin un saga documentado**, CASTLE C emite un **WARNING** sugiriendo ejecutar
`/saga-design`. Señales típicas a vigilar:

- Dos o más llamadas de escritura a servicios distintos en el mismo handler sin
  outbox ni compensación.
- Dual write (DB + publish al broker) fuera de una transacción → exige Outbox.
- Compensaciones ausentes o que dependen de estado en memoria → no sobreviven a crash.
- Consumidores de eventos sin deduplicación (falta Inbox/idempotency key).
