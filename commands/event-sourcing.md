---
name: event-sourcing
description: "Configura Event Sourcing para un aggregate: event store schema (id, aggregate_id, aggregate_type, event_type, payload, sequence, created_at), rehydration por apply methods, snapshot strategy cada N eventos, projections, projection rebuild command y tests. HACE 3 preguntas de validación y RECHAZA si hay < 2 'sí', sugiriendo audit log simple"
argument-hint: "[aggregate-name] [--events e1,e2,...] [--store-backend postgres|eventstore|dynamodb|in-memory] [--snapshot-every N]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /event-sourcing

Configura **Event Sourcing** para un aggregate: el estado se deriva de la **secuencia inmutable de
eventos**. Genera el **event store schema** (append-only), la **rehydration** vía `apply` methods (fold
del stream), una **snapshot strategy** (cada N eventos), una o más **projections**, un **projection
rebuild command** y los **tests** (rehydration, snapshot, rebuild).

> ANTES de scaffoldear NADA, el skill HACE 3 PREGUNTAS de validación y RECHAZA proceder con menos de 2
> "sí", sugiriendo un **audit log simple** como alternativa.

## Instrucciones

1. Invocar el skill `event-sourcing` usando la herramienta Skill
2. Argumentos:
   - `[aggregate-name]`: aggregate a event-sourcear (ej. `Order`, `Account`). Obligatorio
   - `--events <e1,e2,...>`: lista de domain events (ej. `OrderCreated,ItemAdded,OrderPaid`). Default: detectados desde un `/ddd-tactical` previo o inferidos del aggregate
   - `--store-backend <postgres|eventstore|dynamodb|in-memory>`: backend del event store. Default: `postgres`
   - `--snapshot-every <N>`: cada cuántos eventos se persiste un snapshot. Default: `100`
3. Seguir todas las fases del skill en orden:
   - Validate adoption (3 preguntas — GATE) → Resolve backend & events → Event store schema → Rehydration & snapshots → Projections & rebuild → Tests
4. Agentes coordinados: @architect (principal: conduce las 3 preguntas, aplica el veto, diseña el store y la snapshot strategy), @developer (genera schema, apply methods, projections, rebuild), @qa (valida replay determinista, snapshot como cache, rebuild idempotente)
5. IMPORTANTE: nunca proceder con < 2 "sí" (sugerir audit log simple y detener); el event store es append-only (nunca UPDATE/DELETE de un evento); el snapshot es CACHE, no fuente de verdad; los `apply` methods son puros (sin I/O); toda projection debe tener su rebuild command

## El gate de adopción (3 preguntas)

El skill pregunta y cuenta los "sí":

1. ¿Necesitás un **audit trail inmutable** (historial completo como requisito: finanzas/salud/compliance)?
2. ¿Necesitás **time-travel** (reconstruir el estado "como estaba" en cualquier momento del pasado)?
3. ¿Hay **CQRS activo** (o se va a adoptar)? (Event Sourcing casi nunca va sin CQRS)

- **< 2 "sí"** → RECHAZA el scaffolding y sugiere un **audit log simple** (tabla `audit_events` que
  registra qué cambió, quién y cuándo, SIN reconstruir estado desde eventos). NO se genera nada de ES.
- **2 "sí"** → procede con WARN de costo operativo (CASTLE CONDITIONAL).
- **3 "sí"** → procede; ES bien justificado.

## Ejemplos

### Aggregate con eventos explícitos y postgres por defecto

```
/event-sourcing Order --events OrderCreated,ItemAdded,OrderPaid
```

### Aggregate con backend EventStoreDB y snapshots más frecuentes

```
/event-sourcing Account --events AccountOpened,MoneyDeposited,MoneyWithdrawn --store-backend eventstore --snapshot-every 50
```

### Eventos detectados desde un /ddd-tactical previo, store in-memory para dev

```
/event-sourcing Cart --store-backend in-memory
```

## Ejemplo de event store schema — Postgres

Tabla `events` append-only con las 7 columnas obligatorias. `UNIQUE (aggregate_id, sequence)` da
concurrencia optimista; `payload JSONB` es autosuficiente para reproducir el estado. Nunca `UPDATE`/`DELETE`
de un evento (para corregir, evento compensatorio):

```sql
CREATE TABLE events (
    id              BIGSERIAL    PRIMARY KEY,           -- orden global de inserción
    aggregate_id    UUID         NOT NULL,              -- instancia del aggregate
    aggregate_type  TEXT         NOT NULL,              -- 'Order', 'Account', ...
    event_type      TEXT         NOT NULL,              -- 'OrderCreated' — selecciona el apply()
    payload         JSONB        NOT NULL,              -- dato del evento (autosuficiente)
    sequence        BIGINT       NOT NULL,              -- orden monótono POR aggregate
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),-- cuándo ocurrió (time-travel)
    UNIQUE (aggregate_id, sequence)                     -- concurrencia optimista
);

CREATE INDEX idx_events_aggregate ON events (aggregate_id, sequence);
```

## Ejemplo de rehydration — apply method + fold (TypeScript)

`decide()` valida invariantes y EMITE eventos; `apply()` muta el estado de forma PURA (sin I/O);
`rehydrate()` hace fold del stream para reconstruir el estado actual:

```ts
// Order.aggregate.ts
class Order {
  private constructor(
    public readonly id: string,
    private status: 'created' | 'paid',
    private items: OrderItem[],
    public version: number,           // = sequence del último evento aplicado
  ) {}

  // apply: PURO — un caso por event_type, solo muta estado en memoria
  private static apply(state: Order, e: DomainEvent): Order {
    switch (e.type) {
      case 'OrderCreated': return new Order(e.aggregateId, 'created', [], e.sequence);
      case 'ItemAdded':    return new Order(state.id, state.status, [...state.items, e.payload.item], e.sequence);
      case 'OrderPaid':    return new Order(state.id, 'paid', state.items, e.sequence);
      default:             return state;   // eventos desconocidos no rompen el replay
    }
  }

  // rehydrate: fold determinista del stream → estado actual
  static rehydrate(events: DomainEvent[]): Order {
    return events.reduce(Order.apply, Order.empty());
  }
}
```

El mismo stream SIEMPRE produce el mismo estado (replay determinista): es la base de los snapshots
(estado cacheado cada N eventos) y del projection rebuild (re-aplicar desde el evento #1). Detalle de
patrones y trade-offs en `knowledge/domain/architecture-patterns.md` §5.
