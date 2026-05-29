---
name: idempotency
description: "Hace un endpoint/handler retry-safe: genera un middleware de deduplicación que distingue 'ya procesado' (resultado cacheado, replay) de 'en proceso' (202 + Retry-After), el schema de dedup con TTL, tests (misma key → mismo resultado, un solo registro en DB) y guía de cliente. 3 strategies: idempotency-key-header (default), request-hash, client-id+sequence"
argument-hint: "[file|endpoint] [--strategy idempotency-key-header|request-hash|client-id+sequence] [--store redis|postgres|in-memory] [--ttl <duración>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /idempotency

Hace que un endpoint o handler sea **retry-safe**: un cliente puede reenviar el mismo request (timeout,
red caída, retry automático) sin que la operación se ejecute dos veces. Genera un **middleware de
deduplicación** que distingue **"ya procesado"** (devuelve el resultado cacheado con el status/body
originales) de **"en proceso"** (responde **202 + `Retry-After`**, nunca re-ejecuta), el **schema de dedup
con TTL**, **tests** (misma key → mismo resultado y un solo registro en DB) y una **guía de cliente** para
generar keys correctas. 3 strategies: `idempotency-key-header` (default), `request-hash`,
`client-id+sequence`. Alimenta **CASTLE A (Architecture)** y **L (Logging)**.

## Instrucciones

1. Invocar el skill `idempotency` usando la herramienta Skill
2. Argumentos:
   - `[file|endpoint]`: ruta a un archivo con handler(s) o la firma de un endpoint (ej. `POST /orders`). Si es archivo, se detectan los handlers de escritura
   - `--strategy <s>`: cómo se deriva la key. `idempotency-key-header` (default — lee el header `Idempotency-Key`), `request-hash` (hash determinístico de método+ruta+body normalizado), `client-id+sequence` (identidad del cliente + secuencia monótona)
   - `--store <s>`: backend de dedup. `redis` (default si disponible), `postgres` (default si no hay Redis), `in-memory` (solo dev/single-instance — se advierte que no deduplica en cluster)
   - `--ttl <duración>`: ventana de retención de la key (default `24h`). Debe cubrir la ventana realista de reintentos del cliente
3. Seguir todas las fases del skill en orden:
   - Detect target + strategy → Resolve store + TTL → Design dedup schema → Generate middleware → Generate tests + client guide
4. Agentes coordinados: @architect (principal: estrategia de key, scope, store, atomicidad de la reserva), @developer (middleware + schema + integración), @qa (tests de concurrencia: misma key paralela → una sola ejecución)
5. IMPORTANTE: nunca tratar "en proceso" como "ya procesado"; la reserva de key SIEMPRE es atómica (`SET NX` / `INSERT ON CONFLICT`); la key se scopea por actor/tenant; el schema SIEMPRE tiene TTL; nunca embeber credenciales del store

El corazón del middleware es la **reserva atómica** de la key y el **contrato de 3 estados**: key nueva
(ejecuta + cachea), `completed` (replay del resultado), `in_progress` (202 + Retry-After). La idempotencia
convierte el *at-least-once* de la red en *exactly-once efectivo* en la semántica de negocio.

## Ejemplos

### POST retry-safe con idempotency-key-header (default) sobre Redis

```
/idempotency src/handlers/orders.ts --strategy idempotency-key-header --store redis
```

### Webhook legacy sin header del cliente → request-hash sobre Postgres

```
/idempotency POST /webhooks/payment --strategy request-hash --store postgres --ttl 72h
```

### Comandos de un dispositivo con orden por cliente

```
/idempotency src/handlers/commands.ts --strategy client-id+sequence --store redis
```

## Las 3 strategies

| Strategy | Cómo deriva la key | Cuándo |
|----------|--------------------|--------|
| `idempotency-key-header` (default) | El cliente envía un header `Idempotency-Key` (UUID v4 que él controla) | API pública, pagos, cualquier escritura con retry del cliente (estándar Stripe/PayPal) |
| `request-hash` | Hash determinístico de `método + ruta + body normalizado` | El cliente NO puede enviar header (webhooks legacy, forms) y el body identifica la operación |
| `client-id+sequence` | Identidad del cliente + número de secuencia monótono | Streams/colas con orden por cliente, dispositivos que numeran comandos |

## Contrato de estados (lo que distingue el middleware)

| Estado de la key | Respuesta | ¿Re-ejecuta? |
|------------------|-----------|--------------|
| No existe (la reserva atómica gana) | Ejecuta el handler, cachea y devuelve el resultado real | Sí (primera vez) |
| `completed` | **Replay**: mismo `response_status` + `response_body` (header `Idempotent-Replayed: true`) | No |
| `in_progress` | **202 Accepted + `Retry-After`** (la primera request sigue corriendo) | No |
| existe con `request_fingerprint` distinto | **422 Unprocessable Entity** (reuso de key con request diferente) | No |

> Devolver el resultado de una key `in_progress` sería devolver basura: la operación todavía no terminó.
> El 202 + Retry-After le dice al cliente "se está procesando, volvé a consultar" sin re-ejecutar el efecto.

## Ejemplo: middleware Express + Redis

Reserva atómica con `SET NX PX`, bifurcación de 3 caminos y replay del resultado cacheado:

```ts
// idempotency.middleware.ts — Express + ioredis
import type { Request, Response, NextFunction } from 'express';
import { createHash } from 'node:crypto';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);      // NUNCA hardcodear: env / {{SLOT}}
const TTL_MS = Number(process.env.IDEMPOTENCY_TTL_MS ?? 24 * 60 * 60 * 1000);
const RETRY_AFTER_S = 2;

const fingerprint = (req: Request) =>
  createHash('sha256').update(`${req.method}:${req.path}:${JSON.stringify(req.body)}`).digest('hex');

export function idempotency(req: Request, res: Response, next: NextFunction) {
  const clientKey = req.header('Idempotency-Key');     // strategy: idempotency-key-header
  if (!clientKey) return res.status(400).json({ error: 'Idempotency-Key header required' });

  const actor = (req as any).user?.id ?? 'anon';        // scope por actor (evita colisión entre clientes)
  const key = `idemp:${actor}:${req.method}:${req.path}:${clientKey}`;
  const fp = fingerprint(req);

  // RESERVA ATÓMICA: solo el primero gana el SET NX.
  redis.set(key, JSON.stringify({ status: 'in_progress', fingerprint: fp }), 'PX', TTL_MS, 'NX')
    .then(async (reserved) => {
      if (reserved === 'OK') {
        // ── Camino 1: key nueva → ejecutar handler y cachear el resultado al terminar
        const json = res.json.bind(res);
        res.json = (body: unknown) => {
          redis.set(key, JSON.stringify({
            status: 'completed', response_status: res.statusCode, response_body: body, fingerprint: fp,
          }), 'PX', TTL_MS).catch(() => void 0);
          return json(body);
        };
        res.on('finish', () => {
          // handler falló → liberar la reserva para permitir un retry legítimo
          if (res.statusCode >= 500) redis.del(key).catch(() => void 0);
        });
        return next();
      }

      // La key ya existía → leer su estado
      const stored = JSON.parse((await redis.get(key)) ?? '{}');

      if (stored.fingerprint && stored.fingerprint !== fp) {
        // misma key, request distinto → reuso indebido
        return res.status(422).json({ error: 'Idempotency-Key reused with a different request' });
      }
      if (stored.status === 'completed') {
        // ── Camino 2: YA PROCESADO → replay del resultado original (NO re-ejecuta)
        return res.status(stored.response_status).set('Idempotent-Replayed', 'true').json(stored.response_body);
      }
      // ── Camino 3: EN PROCESO → 202 + Retry-After (NO re-ejecuta, NO devuelve resultado vacío)
      return res.status(202).set('Retry-After', String(RETRY_AFTER_S))
        .json({ status: 'processing', retry_after: RETRY_AFTER_S });
    })
    .catch(next);
}
```

Uso en la ruta protegida:
```ts
app.post('/orders', idempotency, createOrderHandler);   // POST ahora es retry-safe
```

> Red de seguridad en DB: el cache deduplica, pero la tabla de negocio DEBE tener un constraint único
> (ej. `UNIQUE(idempotency_key)`) para garantizar un solo registro aunque el cache caiga.

## Schema de dedup (Redis + Postgres)

**Redis** (TTL nativo vía `PX`):
```
KEY:   idemp:{tenant?}:{actor}:{endpoint}:{key}
VALUE: {"status":"completed","response_status":201,"response_body":{...},"fingerprint":"sha256:..."}
reserva:  SET <key> '{"status":"in_progress","fingerprint":"..."}' NX PX <ttl_ms>
```

**Postgres** (TTL vía `expires_at` + sweep):
```sql
CREATE TABLE idempotency_keys (
  key                 TEXT PRIMARY KEY,         -- {tenant?}:{actor}:{endpoint}:{key}
  status              TEXT NOT NULL,            -- 'in_progress' | 'completed'
  response_status     INT,
  response_body       JSONB,
  request_fingerprint TEXT NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at          TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_idempotency_keys_expires_at ON idempotency_keys (expires_at);
-- reserva atómica: INSERT ... ON CONFLICT (key) DO NOTHING;
-- sweep: DELETE FROM idempotency_keys WHERE expires_at < now();
```

## Tests generados

| Test | Verifica |
|------|----------|
| Misma key dos veces → mismo resultado | El segundo request devuelve el MISMO `response_status` + `response_body`; no re-ejecuta |
| Un solo registro en DB | Tras dos requests con la misma key, la tabla de negocio tiene exactamente UNA fila |
| Keys distintas → independiente | Dos keys diferentes ejecutan ambas (no se deduplican entre sí) |
| Concurrencia (misma key en paralelo) | Uno ejecuta, el otro recibe 202/replay; NUNCA ambos ejecutan |
| Fingerprint mismatch | Misma key con body distinto → 422 |

## Guía de cliente — generar keys correctas

- Generá el UUID v4 **una vez por intento lógico** y reutilizalo en cada retry de ese intento. Re-aleatorizar la key en cada reintento ANULA la idempotencia (el server lo ve como operación nueva → doble ejecución).
- Respetá el `Retry-After` del `202` con backoff: significa "la primera request sigue corriendo".
- No reutilices una key para operaciones distintas (te devolverá `422`).

```ts
const idempotencyKey = uuidv4();              // UNA vez, FUERA del loop de retry
for (let attempt = 0; attempt < maxRetries; attempt++) {
  const res = await post('/orders', body, { headers: { 'Idempotency-Key': idempotencyKey } });
  if (res.status === 202) { await sleep(res.headers['retry-after'] * 1000); continue; }
  return res;                                  // 201 (nueva) o replay — mismo efecto
}
```

## at-least-once → exactly-once

La red y los brokers entregan **at-least-once**: un request/mensaje puede llegar varias veces. La
idempotencia lo convierte en **exactly-once efectivo** en la semántica de negocio. Por eso todo consumer de
un broker (`/event-broker-setup`) deduplica por idempotency key (Inbox Pattern) y toda compensación de un
saga (`/saga-design`) debe ser idempotente. La reserva atómica de la key bajo concurrencia es lo que vuelve
esto correcto. Detalle de deduplicación, distributed caching y delivery semantics en
`knowledge/domain/distributed-systems.md`; Inbox/Outbox en `knowledge/domain/saga-patterns.md`.
