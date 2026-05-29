# Resilience Patterns — Guía de Tolerancia a Fallos

> Versión completa. Para inyección en agents usar `knowledge/_inject/resilience.md`.
> Base de conocimiento del skill `/resilience-weave` (M-10) — *skill en king-arch, si está instalado*. Este knowledge queda en king-core (lo consume `hooks/resilience-check.sh`).

La resiliencia NO es "agregar retries". Es decidir, para CADA llamada externa, qué falla
podemos tolerar y cómo degradar sin propagar el fallo al usuario. La regla de oro: un
patrón mal aplicado (retry en operación no idempotente, circuit breaker sin monitoring)
es PEOR que no tener el patrón.

---

## Tabla de Librerías por Stack

| Stack | Retry | Circuit Breaker | Suite completa | Notas |
|-------|-------|-----------------|----------------|-------|
| Node.js | `p-retry` | `opossum` | `cockatiel` | `cockatiel` = mejor DX, combina policies (retry+CB+bulkhead+timeout+fallback) |
| Go | `retry-go` (avast) | `gobreaker` (sony) | `failsafe-go` | Usar `context.Context` para deadline propagation nativa |
| Python | `tenacity` / `stamina` | `pybreaker` | `tenacity`+`pybreaker` | `stamina` = wrapper opinado sobre `tenacity` con jitter por defecto |
| Java | Resilience4j | Resilience4j | Resilience4j | Decoradores funcionales componibles; sucesor de Hystrix (deprecado) |
| .NET | Polly | Polly | Polly | `ResiliencePipelineBuilder` une todas las strategies |
| Rust | `tower` (Retry layer) | `tower` (custom) | `tower` | Middleware stack componible vía `ServiceBuilder` |

**Regla de selección**: el skill detecta el stack desde `.king/knowledge/stack.md` y elige la
suite completa cuando teje 3+ patrones; las librerías mono-patrón solo si el stack ya las usa.

---

## 1. Retry — Reintentos con Backoff

Reintenta una operación que falló por una causa **transitoria** (red, timeout, 503).

### Cuándo SÍ
- La operación es **idempotente** (GET, PUT, DELETE bien diseñados, o POST con idempotency-key).
- El error es **transitorio**: timeout de red, `ECONNRESET`, 500/502/503/504, rate limit (429 con `Retry-After`).
- Hay capacidad de absorber la latencia extra del reintento.

### Cuándo NO
- La operación **NO es idempotente** (POST que crea recursos, transferencia de dinero, envío de email) → reintentar puede duplicar el efecto.
- El error es **permanente/de cliente**: 400, 401, 403, 404, 422 → reintentar nunca tendrá éxito y desperdicia recursos.
- Errores de validación de negocio → fail-fast, no reintentar.

### Estrategias de espera

| Estrategia | Fórmula | Problema que resuelve |
|-----------|---------|------------------------|
| Fixed | `delay = base` | Simple, pero martillea el servicio caído |
| Exponential backoff | `delay = base * 2^attempt` | Da tiempo a recuperarse; crece rápido |
| Backoff + **full jitter** | `delay = random(0, base * 2^attempt)` | Evita el **thundering herd** (todos reintentan al mismo tiempo) |
| Backoff + equal jitter | `delay = base*2^attempt/2 + random(0, base*2^attempt/2)` | Compromiso: menos varianza que full |
| Decorrelated jitter | `delay = min(cap, random(base, prev*3))` | Recomendado por AWS para alta concurrencia |

> **Siempre usar jitter.** Backoff exponencial sin jitter sincroniza a todos los clientes y
> genera picos coordinados que tumban el servicio justo cuando intenta recuperarse.

### Ejemplo (Node.js — `p-retry`)

```typescript
import pRetry, { AbortError } from 'p-retry';

async function fetchUser(id: string) {
  return pRetry(
    async () => {
      const res = await fetch(`https://api.example.com/users/${id}`);
      // 4xx = error de cliente: abortar, NO reintentar
      if (res.status >= 400 && res.status < 500) {
        throw new AbortError(`Client error ${res.status}`);
      }
      if (!res.ok) throw new Error(`Server error ${res.status}`); // sí reintenta
      return res.json();
    },
    {
      retries: 3,
      factor: 2,            // exponencial
      minTimeout: 100,
      maxTimeout: 2000,
      randomize: true,      // full jitter
    }
  );
}
```

---

## 2. Circuit Breaker — Cortacircuitos

Deja de llamar a un servicio que está fallando sistemáticamente, para no agotar recursos
esperando respuestas que no llegarán y dar tiempo a que se recupere.

### Máquina de estados

```
              fallos >= threshold
   ┌────────┐ ─────────────────────▶ ┌────────┐
   │ CLOSED │                         │  OPEN  │
   │(pasa   │ ◀───────────────────── │(rechaza│
   │ todo)  │   probe OK              │ rápido)│
   └────────┘                         └────────┘
        ▲                                  │
        │ probe OK            recovery_timeout expira
        │                                  ▼
        │  probe falla            ┌────────────┐
        └──────────────────────── │ HALF-OPEN  │
                                   │(deja pasar │
                                   │ 1 probe)   │
                                   └────────────┘
```

- **CLOSED**: tráfico normal. Cuenta fallos en una ventana. Si supera `failure_threshold` (%) con `min_throughput` mínimo de llamadas → abre.
- **OPEN**: rechaza inmediatamente (fail-fast), sin tocar el servicio. Tras `recovery_timeout` → pasa a HALF-OPEN.
- **HALF-OPEN**: deja pasar una llamada de prueba. Si tiene éxito → CLOSED; si falla → OPEN otra vez.

### Cuándo SÍ
- Dependencia externa con fallos en cascada potenciales (un servicio lento que satura tus threads).
- Quieres **fail-fast** en vez de acumular timeouts y agotar el pool de conexiones.
- Tienes un **fallback** razonable mientras el circuito está OPEN.

### Cuándo NO
- **Sin monitoring/alerting** del estado del circuito → un circuito OPEN silencioso oculta un outage; nadie se entera de que la dependencia está caída. (Ver anti-patrones.)
- Operaciones de baja frecuencia donde nunca alcanzarás `min_throughput` (el cálculo de % es ruidoso).
- Cuando el fallback es inaceptable y prefieres que el error se propague.

### Ejemplo (Go — `gobreaker`)

```go
import "github.com/sony/gobreaker"

cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "payment-api",
    MaxRequests: 1,                // probes permitidas en HALF-OPEN
    Interval:    60 * time.Second, // ventana de conteo
    Timeout:     30 * time.Second, // recovery_timeout (OPEN -> HALF-OPEN)
    ReadyToTrip: func(c gobreaker.Counts) bool {
        ratio := float64(c.TotalFailures) / float64(c.Requests)
        return c.Requests >= 10 && ratio >= 0.5 // min_throughput + 50%
    },
    OnStateChange: func(name string, from, to gobreaker.State) {
        metrics.RecordCircuitState(name, to.String()) // MONITORING obligatorio
    },
})

body, err := cb.Execute(func() (any, error) {
    return callPaymentAPI(ctx)
})
```

---

## 3. Bulkhead — Mamparos de Aislamiento

Aísla recursos por dependencia, como los compartimentos estancos de un barco: si una
dependencia se inunda (agota su pool), no hunde al resto de la aplicación.

### Dos implementaciones

| Tipo | Mecanismo | Cuándo |
|------|-----------|--------|
| **Semaphore** | Limita llamadas concurrentes (contador) | Llamadas async no bloqueantes; bajo overhead |
| **Thread pool** | Pool dedicado por dependencia | Llamadas bloqueantes; aísla también el tiempo de CPU/thread |

### Cuándo SÍ
- Varias dependencias compartiendo el mismo pool de threads/conexiones.
- Una dependencia lenta no debe consumir TODA la capacidad y matar de hambre a las demás.

### Cuándo NO
- Una sola dependencia y recursos abundantes (overhead sin beneficio).
- Si el límite de concurrencia se pone demasiado bajo → rechazas tráfico legítimo (mide antes).

### Ejemplo (Node.js — `cockatiel`)

```typescript
import { bulkhead } from 'cockatiel';

// Máx 10 concurrentes + cola de 5 esperando
const wall = bulkhead(10, 5);

await wall.execute(() => callExternalService());
// La llamada 16+ (10 activas + 5 en cola) lanza BulkheadRejectedError
```

---

## 4. Timeout — Límites de Espera

Nunca esperes indefinidamente. Un timeout convierte un "cuelgue" infinito en un fallo
manejable y libera el recurso (conexión, thread) para otra petición.

### Cuándo SÍ
- **Toda** llamada de red sin excepción. Sin timeout, una dependencia colgada agota tu pool.
- Necesitas **deadline propagation**: el timeout del request padre acota a TODOS los hijos.

### Cuándo NO
- Nunca hay un "cuándo NO" para tener timeout. El error es elegir el valor mal:
  - Demasiado corto → cancela operaciones legítimas y dispara retries innecesarios.
  - Demasiado largo → no protege (equivale a no tenerlo).

### Client timeout vs. deadline propagation

- **Client timeout**: límite local fijo (`5000ms`). Simple pero ignora cuánto tiempo le queda al request padre.
- **Deadline propagation**: el request entra con un deadline absoluto; cada llamada hija recibe `deadline - tiempo_ya_gastado`. Evita gastar tiempo en una llamada hija cuando el padre ya va a expirar (timeouts jerárquicos).

### Ejemplo (Go — deadline propagation con `context`)

```go
// El request padre define el deadline; se propaga a los hijos
ctx, cancel := context.WithTimeout(parentCtx, 5*time.Second)
defer cancel()

// La llamada hija respeta el tiempo RESTANTE del padre, no 5s nuevos
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
resp, err := http.DefaultClient.Do(req)
if errors.Is(err, context.DeadlineExceeded) {
    // deadline jerárquico expirado: no reintentar contra el reloj
}
```

---

## 5. Rate Limiting — Control de Tasa

Limita cuántas peticiones se aceptan/emiten por unidad de tiempo. Protege al servicio
(server-side) o respeta los límites de un proveedor (client-side).

### Algoritmos

| Algoritmo | Cómo funciona | Permite ráfagas | Uso típico |
|-----------|---------------|-----------------|------------|
| **Token bucket** | Tokens se rellenan a tasa fija; cada request consume uno | Sí (hasta el tamaño del bucket) | APIs que toleran bursts cortos |
| **Leaky bucket** | Cola FIFO drenada a tasa constante | No (suaviza la salida) | Output rate constante hacia un downstream frágil |
| **Sliding window** | Cuenta requests en ventana deslizante | Parcial | Límites precisos sin el "edge burst" de fixed window |
| Fixed window | Contador por intervalo (ej. 100/min) | Sí, en el borde (problema) | Simple, pero permite 2x en el cruce de ventana |

### Cuándo SÍ
- Proteger un recurso caro (DB, API de terceros con cuota, endpoint de auth).
- Respetar el rate limit de un proveedor para no recibir 429 / baneos.

### Cuándo NO
- Tráfico interno confiable y barato donde el límite solo agrega latencia.
- Como sustituto de capacity planning (limitar no escala; solo protege).

### Ejemplo (Python — token bucket simple)

```python
import time, threading

class TokenBucket:
    def __init__(self, rate: float, capacity: int):
        self.rate, self.capacity = rate, capacity
        self.tokens = capacity
        self.updated = time.monotonic()
        self.lock = threading.Lock()

    def allow(self) -> bool:
        with self.lock:
            now = time.monotonic()
            self.tokens = min(self.capacity, self.tokens + (now - self.updated) * self.rate)
            self.updated = now
            if self.tokens >= 1:
                self.tokens -= 1
                return True
            return False  # rechazar -> 429 con Retry-After
```

---

## 6. Throttling — Backpressure y Rechazo

Cuando la demanda supera la capacidad, throttling decide qué hacer con el exceso:
ralentizar al productor (backpressure) o rechazar (shedding).

### Backpressure vs. Rejection

| Estrategia | Qué hace | Cuándo |
|-----------|----------|--------|
| **Backpressure** | Frena al productor (pausa el stream, bloquea el enqueue) | Productor y consumidor acoplados; puedes ralentizar el origen |
| **Rejection (load shedding)** | Devuelve `429 Too Many Requests` + `Retry-After` | El cliente es externo y no puede ser frenado; preferible degradar a colapsar |

### Cuándo SÍ
- El sistema puede saturarse y prefieres degradar de forma controlada antes que caer.
- Tienes una cola/buffer cuyo crecimiento ilimitado causaría OOM.

### Cuándo NO
- Si puedes escalar horizontalmente a tiempo, throttling agresivo descarta trabajo válido.
- Backpressure cuando el productor NO puede frenar (ej. eventos de IoT que se pierden) → preferir buffer + shedding.

### Header obligatorio al rechazar

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 5
RateLimit-Remaining: 0
RateLimit-Reset: 1716800000
```

> El `Retry-After` es lo que permite al cliente reintentar con sensatez (alinea retry §1 con throttling §6).

---

## 7. Hedged Requests — Peticiones Cubiertas

Para recortar la **latencia de cola (P99)**: si la primera petición no responde en un
umbral (ej. el P95), se lanza una segunda copia en paralelo y se toma la que responda primero.

### Cuándo SÍ
- La operación es **idempotente** (igual que retry — una copia duplicada no debe causar efectos).
- El P99 es muy superior al P50 (cola larga) por nodos lentos intermitentes (GC pauses, hot shard).
- El costo de duplicar una fracción del tráfico es aceptable.

### Cuándo NO
- Operaciones **NO idempotentes** → duplicar = doble efecto (mismo riesgo que retry).
- Servicio ya saturado → hedging AGREGA carga justo cuando menos la tolera (puede causar tormenta).
- Sin cancelación de la copia perdedora → desperdicias recursos del downstream.

### Ejemplo (Go — hedge tras umbral)

```go
func hedged(ctx context.Context, call func(context.Context) (Result, error)) (Result, error) {
    ctx, cancel := context.WithCancel(ctx)
    defer cancel() // cancela la copia perdedora SIEMPRE

    out := make(chan result, 2)
    go func() { r, e := call(ctx); out <- result{r, e} }()

    select {
    case r := <-out:
        return r.val, r.err
    case <-time.After(p95Latency): // umbral: lanzar la segunda copia
        go func() { r, e := call(ctx); out <- result{r, e} }()
        r := <-out
        return r.val, r.err
    }
}
```

---

## 8. Graceful Degradation — Degradación Elegante

Cuando una dependencia no responde, devolver una versión reducida del servicio en vez de
un error total. El usuario percibe degradación, no caída.

### Tipos de fallback

| Tipo | Ejemplo | Cuándo |
|------|---------|--------|
| **Static value** | Lista vacía, default conocido | El dato no es crítico; mejor vacío que error |
| **Cached / stale** | Último valor cacheado (stale-while-revalidate) | El dato tolera estar desactualizado |
| **Feature toggle** | Apagar recomendaciones, mostrar UI base | Funcionalidad secundaria que puede ausentarse |
| **Explicit error** | Mensaje user-friendly | El dato ES crítico (pago) → fallar claro, no inventar |

### Cuándo SÍ
- El feature es secundario o tolera datos aproximados/cacheados.
- Mantener el servicio parcialmente vivo aporta más valor que un 500.

### Cuándo NO
- Datos **críticos de correctitud** (saldo, autorización, pago) → un fallback inventado es PEOR que un error honesto. Mejor `503` explícito.
- Cuando el fallback enmascara un outage que requiere acción inmediata (combinar siempre con alerting).

### Ejemplo (Node.js — `cockatiel` fallback + monitoring)

```typescript
import { fallback, handleAll } from 'cockatiel';

const policy = fallback(handleAll, () => {
  metrics.increment('recommendations.degraded'); // visibilidad del fallback
  return [];                                       // lista vacía, no 500
});

const recs = await policy.execute(() => recommendationService.get(userId));
// Si el servicio falla, el usuario ve la página SIN recomendaciones, no un error
```

---

## 9. Chaos Engineering — Ingeniería del Caos

Inyectar fallos controlados en producción (o staging realista) para VERIFICAR que los
patrones anteriores funcionan de verdad, antes de que un fallo real los ponga a prueba.

### Método científico

1. **Steady state**: define una métrica de negocio normal (ej. "99% de checkouts < 2s").
2. **Hypothesis**: "Si el servicio de pago tarda 3s, el circuit breaker abre y el steady state se mantiene".
3. **Inject fault**: latencia, error, kill de instancia, partición de red — en una fracción pequeña del tráfico (blast radius acotado).
4. **Verify**: ¿se mantuvo el steady state? Si no, encontraste un fallo de resiliencia ANTES de un incidente real.
5. **Blast radius**: empezar mínimo, tener botón de aborto, nunca experimentar sin observabilidad.

### Cuándo SÍ
- Ya tienes resiliencia tejida (§1-8) y monitoring → chaos VALIDA que funciona.
- Sistemas distribuidos donde los modos de fallo son emergentes e imposibles de razonar en teoría.

### Cuándo NO
- **Sin observabilidad** → inyectas caos a ciegas, no puedes medir el impacto: peligroso e inútil.
- **Sin steady state definido** → no sabes si el experimento "pasó".
- En producción sin blast radius acotado ni botón de aborto → estás causando un incidente, no un experimento.

### Ejemplo (tests de chaos generados por `/resilience-weave`, king-arch si está instalado)

```typescript
describe('chaos: payment-api', () => {
  it('circuit breaker abre tras latencia sostenida', async () => {
    mockPaymentApi.injectLatency(10_000); // > timeout de 5000ms
    for (let i = 0; i < 12; i++) await tryCheckout().catch(() => {});
    expect(circuit.state).toBe('OPEN');     // hipótesis verificada
    expect(await tryCheckout()).rejects.toThrow(/temporarily unavailable/); // fail-fast
  });

  it('degrada a fallback con errores intermitentes', async () => {
    mockRecommendations.injectErrorRate(1.0);
    const page = await renderHome(userId);
    expect(page.recommendations).toEqual([]); // graceful degradation, no 500
  });
});
```

---

## Composición: el orden importa

Al tejer varios patrones alrededor de una llamada, el orden de envoltura cambia el comportamiento.
Orden recomendado (de afuera hacia adentro):

```
Fallback ( Retry ( CircuitBreaker ( Bulkhead ( Timeout ( call ) ) ) ) )
```

- **Timeout** lo más adentro: cada intento individual está acotado.
- **Bulkhead** acota la concurrencia de cada intento.
- **CircuitBreaker** envuelve al bulkhead: cuenta fallos de los intentos ya acotados.
- **Retry** afuera del breaker: si el circuito está OPEN, falla rápido sin gastar reintentos.
- **Fallback** lo más afuera: captura cualquier fallo final y degrada.

> `cockatiel` (`wrap(...)`), `Resilience4j` (decorate) y Polly (`ResiliencePipelineBuilder`)
> respetan este orden por construcción.

---

## Anti-Patterns a Evitar

| Anti-Pattern | Problema | Corrección |
|-------------|---------|-----------|
| **Retry en operación NO idempotente** | Duplica efectos (doble cobro, doble email) | Clasificar idempotencia ANTES de tejer retry; usar idempotency-key o solo CB+timeout |
| Retry sin jitter | Thundering herd: todos reintentan sincronizados y tumban el servicio que se recuperaba | Backoff exponencial + full/decorrelated jitter |
| Retry sobre errores 4xx | Reintenta lo que nunca va a funcionar; desperdicia recursos | Reintentar solo transitorios (5xx, red, 429); abortar en 4xx |
| **Circuit breaker SIN monitoring** | Circuito OPEN silencioso oculta un outage; nadie se entera | `OnStateChange` → métricas + alerta en cada transición |
| Circuit breaker con `min_throughput` muy bajo | % de fallo ruidoso; abre por 1-2 errores aislados | Exigir mínimo de llamadas antes de calcular el ratio |
| Llamada de red SIN timeout | Una dependencia colgada agota el pool de conexiones/threads | Timeout en TODA llamada; preferir deadline propagation |
| Timeout sin propagación jerárquica | Llamada hija arranca con 5s nuevos cuando el padre ya expiró | Propagar el deadline restante (`context`, deadline absoluto) |
| Hedged requests no idempotentes | Doble efecto, igual que retry | Solo en operaciones idempotentes |
| Hedging sobre servicio saturado | Duplica carga justo cuando menos la tolera | Limitar % de tráfico cubierto; desactivar bajo alta carga |
| Fallback que inventa datos críticos | Un saldo/autorización falso es peor que un error | Fallback solo para datos no críticos; error explícito para los críticos |
| Retry envolviendo al timeout total (orden invertido) | Un solo intento puede consumir todo el presupuesto de tiempo | Timeout por intento (adentro), retry afuera |
| Chaos sin observabilidad ni steady state | Inyectar fallos a ciegas = causar un incidente, no un experimento | Definir steady state + métricas + blast radius + botón de aborto |

---

## Checklist de Resiliencia por Llamada Externa

### Clasificación (antes de tejer)
- [ ] ¿La operación es idempotente? (decide si retry y hedging son seguros)
- [ ] ¿Qué errores son transitorios (reintentables) vs. permanentes (abortar)?
- [ ] ¿Existe un fallback aceptable, o el fallo debe propagarse?

### Patrones tejidos
- [ ] **Timeout** en toda llamada (con deadline propagation si hay contexto padre)
- [ ] **Retry** solo si idempotente: backoff exponencial + jitter, excluye 4xx
- [ ] **Circuit breaker** con `failure_threshold`, `min_throughput`, `recovery_timeout`
- [ ] **Bulkhead** con concurrencia máxima por recurso externo
- [ ] **Fallback** degradado para datos no críticos / error explícito para críticos
- [ ] Orden de composición correcto: `Fallback(Retry(CB(Bulkhead(Timeout(call)))))`

### Observabilidad (NO opcional)
- [ ] Métrica + alerta en cada transición de estado del circuit breaker
- [ ] Contador de retries, de fallbacks activados y de rechazos del bulkhead
- [ ] Dashboard que muestre dependencias en estado OPEN/degradado

### Validación
- [ ] Test de chaos: inyecta latencia y verifica que el circuit breaker abre
- [ ] Test de chaos: inyecta errores y verifica el fallback (no 500)
- [ ] Test: retry NO se dispara en errores 4xx
- [ ] Test: operación no idempotente NO tiene retry tejido
