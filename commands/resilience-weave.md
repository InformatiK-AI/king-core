---
name: resilience-weave
description: "Teje retry/circuit-breaker/bulkhead/timeout/fallback alrededor de llamadas a servicios externos. Clasifica idempotencia ANTES de tejer retry (no idempotente → sin retry, sugiere /idempotency). Genera apex.resilience.yaml y tests de chaos"
argument-hint: "[file|path] [--patterns retry,circuit-breaker,bulkhead,timeout,fallback] [--config apex.resilience.yaml]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /resilience-weave

Teje los 5 patrones de tolerancia a fallos (retry, circuit breaker, bulkhead, timeout, fallback)
alrededor de cada llamada a un servicio externo. La fase **Classify** determina la **idempotencia
ANTES** de tejer retry: si la operación NO es idempotente, NO agrega retry y sugiere `/idempotency`.
Genera `apex.resilience.yaml` con la configuración aplicada y tests de chaos que inyectan fallos.
Alimenta **CASTLE A·T·L** (Architecture, Testing, Logging/observabilidad).

## Instrucciones

1. Invocar el skill `resilience-weave` usando la herramienta Skill
2. Argumentos:
   - `[file|path]`: archivo o directorio con código de llamadas externas (HTTP, gRPC, DB, cache, queue, SDK). Si lo invoca el hook `resilience-check` o `/build`, default = archivos modificados
   - `--patterns <retry,circuit-breaker,bulkhead,timeout,fallback>`: patrones a tejer. Default: todos
   - `--config <apex.resilience.yaml>`: config existente para reusar/afinar valores. Default: `apex.resilience.yaml` en la raíz si existe, o parámetros inline
3. Seguir todas las fases del skill en orden:
   - Detect calls → Classify → Select library → Weave retry → Weave CB → Weave bulkhead → Weave timeout → Weave fallback → Generate config → Generate tests
4. Agentes coordinados: @architect (principal: clasifica idempotencia y valida composición), @developer (teje patrones + tests de chaos), @performance (valida timeouts/bulkhead)
5. IMPORTANTE:
   - NUNCA tejer retry en operación NO idempotente sin idempotency-key → solo CB + timeout, y sugerir `/idempotency`
   - NUNCA retry sobre 4xx; SIEMPRE backoff exponencial + jitter
   - NUNCA circuit breaker sin monitoring; NUNCA llamada de red sin timeout
   - NUNCA fallback que invente datos críticos (pago/saldo) → error explícito
   - Orden de composición: `Fallback(Retry(CB(Bulkhead(Timeout(call)))))`
   - Ningún secreto/connection string literal en código ni en `apex.resilience.yaml`

Si no se detecta el stack, el skill teje con primitivas del lenguaje y lo marca. Si una llamada no es
idempotente, NO falla: omite el retry, lo registra en el reporte y sugiere `/idempotency`.

## Ejemplos

### Tejer los 5 patrones sobre un archivo

```
/resilience-weave src/clients/payment-client.ts
```

### Solo retry + circuit breaker, reusando config previa

```
/resilience-weave src/clients/ --patterns retry,circuit-breaker --config apex.resilience.yaml
```

## Ejemplo de output (Node.js — `cockatiel`, llamada idempotente)

Input: `src/clients/payment-client.ts` (stack Node.js detectado, `GET /payments/:id` → **idempotente**).

```ts
// ANTES — src/clients/payment-client.ts (llamada fetch sin manejo de fallos)
export async function getPayment(id: string) {
  const res = await fetch(`https://payment-api/payments/${id}`);
  return res.json();
}
```

```
RESILIENCE WEAVE — /resilience-weave                              stack: node · lib: cockatiel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Llamada  getPayment → GET https://payment-api/payments/:id   [línea 2]
  Idempotencia : SÍ (GET)            → retry SEGURO
  Errores      : transitorios 5xx/red reintentables · 4xx abortan
  Fallback     : dato no crítico de display → static_value (null)
  Patrones     : retry ✓ · circuit-breaker ✓ · bulkhead ✓ · timeout ✓ · fallback ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CASTLE: A (composición correcta) · T (chaos test) · L (CB con OnStateChange) → CONDITIONAL→PASS
```

```ts
// DESPUÉS — src/clients/payment-client.ts (5 patrones tejidos con cockatiel)
import {
  retry, circuitBreaker, bulkhead, timeout,
  fallback, wrap, handleAll, ExponentialBackoff,
  ConsecutiveBreaker, TimeoutStrategy,
} from 'cockatiel';
import { metrics } from '../observability';

// Orden de composición: Fallback ( Retry ( CB ( Bulkhead ( Timeout ( call ) ) ) ) )
const retryPolicy = retry(handleAll, {
  maxAttempts: 3,
  backoff: new ExponentialBackoff({ initialDelay: 100, maxDelay: 2000 }), // exp + jitter
});

const breaker = circuitBreaker(handleAll, {
  halfOpenAfter: 30_000,                       // recovery_timeout
  breaker: new ConsecutiveBreaker(/* min_throughput + 50% */ 5),
});
breaker.onStateChange((s) => metrics.recordCircuitState('payment-api', s)); // MONITORING obligatorio

const wall = bulkhead(10, 5);                   // máx 10 concurrentes + cola 5
const time = timeout(5_000, TimeoutStrategy.Aggressive); // timeout lo más adentro

const fb = fallback(handleAll, () => {
  metrics.increment('payment.degraded');
  return null;                                  // dato no crítico → degradar, no 500
});

const policy = wrap(fb, retryPolicy, breaker, wall, time);

export async function getPayment(id: string) {
  return policy.execute(async () => {
    const res = await fetch(`https://payment-api/payments/${id}`);
    if (res.status >= 400 && res.status < 500) {
      throw new Error(`Client error ${res.status}`); // 4xx: NO reintentar
    }
    if (!res.ok) throw new Error(`Server error ${res.status}`); // 5xx: reintenta
    return res.json();
  });
}
```

```yaml
# apex.resilience.yaml (generado)
services:
  payment-api:
    retry: { max_attempts: 3, backoff: exponential, base_delay_ms: 100, max_delay_ms: 2000, jitter: full, retry_on: [500, 502, 503, 504, NetworkError, TimeoutError] }
    circuit_breaker: { failure_threshold: 50, min_throughput: 10, recovery_timeout_s: 30 }
    bulkhead: { max_concurrent: 10 }
    timeout: { total_ms: 5000 }
    fallback: { type: static_value, value: null }
```

```ts
// chaos test generado — payment-client.chaos.test.ts
describe('chaos: payment-api', () => {
  it('circuit breaker abre tras latencia sostenida', async () => {
    mockPaymentApi.injectLatency(10_000);              // > timeout 5000ms
    for (let i = 0; i < 12; i++) await getPayment('x').catch(() => {});
    expect(breaker.state).toBe('OPEN');                // hipótesis verificada
  });
  it('degrada a fallback con errores intermitentes', async () => {
    mockPaymentApi.injectErrorRate(1.0);
    expect(await getPayment('x')).toBeNull();          // graceful degradation, no 500
  });
  it('NO reintenta en 4xx', async () => {
    mockPaymentApi.injectStatus(422);
    await expect(getPayment('x')).rejects.toThrow();
    expect(mockPaymentApi.callCount).toBe(1);          // 1 sola llamada, sin retry
  });
});
```

## Ejemplo de output (caso NO idempotente — sin retry)

Input: `src/clients/order-client.ts` con `POST /orders` (sin idempotency-key).

```
RESILIENCE WEAVE — /resilience-weave                              stack: node · lib: cockatiel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Llamada  createOrder → POST https://order-api/orders
  Idempotencia : NO (POST sin Idempotency-Key)   → retry OMITIDO (evita órdenes duplicadas)
  Patrones     : retry ✗ · circuit-breaker ✓ · bulkhead ✓ · timeout ✓ · fallback ✓ (error explícito)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠ Retry NO tejido: la operación no es idempotente. Ejecutá /idempotency para agregar un
  Idempotency-Key y luego re-ejecutá /resilience-weave para tejer retry de forma SEGURA.
```

El output es accionable: indica exactamente qué se tejió, qué se omitió y por qué, con el siguiente
paso (`/idempotency`) cuando la idempotencia bloquea el retry.
