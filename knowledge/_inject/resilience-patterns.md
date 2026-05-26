# Resilience Patterns (para inyección en /build)

> Inyectar cuando /build detecta integraciones con servicios externos (HTTP client, API externa, third-party).

## Cuándo aplicar cada patrón

| Patrón | Aplicar cuando | No aplicar cuando |
|--------|----------------|-------------------|
| Retry | Errores transitorios (503, red) | Errores de cliente (400, 401, 404) |
| Circuit Breaker | Servicio externo con historial de fallas | Operaciones locales |
| Bulkhead | Múltiples servicios externos en la misma app | Un solo servicio externo |
| Timeout | Todo cliente HTTP sin excepción | — |

## Retry con Exponential Backoff

```python
# Python — tenacity
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
import httpx

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=2, min=1, max=30),
    retry=retry_if_exception_type((httpx.TransientError, httpx.TimeoutException))
)
def call_payment_api(payload):
    return httpx.post("https://api.payments.com/charge", json=payload, timeout=30)
```

```csharp
// .NET — Polly
var pipeline = new ResiliencePipelineBuilder()
    .AddRetry(new RetryStrategyOptions
    {
        MaxRetryAttempts = 3,
        BackoffType = DelayBackoffType.Exponential,
        Delay = TimeSpan.FromSeconds(2),
        ShouldHandle = new PredicateBuilder().Handle<HttpRequestException>()
    })
    .Build();
```

```java
// Java — resilience4j
RetryConfig config = RetryConfig.custom()
    .maxAttempts(3)
    .intervalFunction(IntervalFunction.ofExponentialBackoff(2, 2))
    .retryOnException(e -> e instanceof HttpServerErrorException)
    .build();
```

## Circuit Breaker

Estados: **CLOSED** (normal) → **OPEN** (falla) → **HALF-OPEN** (sondeo)

```python
# Python — pybreaker
import pybreaker
import httpx

cb = pybreaker.CircuitBreaker(fail_max=5, reset_timeout=60)

@cb
def call_external_service():
    return httpx.get("https://api.external.com/data", timeout=10)
```

**Defaults recomendados**: `fail_max=5`, `reset_timeout=60`, `half_open_attempts=1`

## Bulkhead

```python
# Python — asyncio Semaphore (bulkhead por servicio)
import asyncio
import httpx

payment_semaphore = asyncio.Semaphore(10)   # máx 10 concurrent
shipping_semaphore = asyncio.Semaphore(5)   # máx 5 concurrent

async def charge_payment(payload):
    async with payment_semaphore:
        async with httpx.AsyncClient() as client:
            return await client.post("https://api.payments.com/charge", json=payload)
```

## Timeout (obligatorio en todo cliente HTTP)

**Defaults seguros**: `connect=5s`, `read=30s`, `write=10s`, `pool=5s`

```python
# Python
httpx.get(url, timeout=httpx.Timeout(connect=5, read=30, write=10, pool=5))
```

```javascript
// Node.js — axios
axios.get(url, { timeout: 30_000 })  // ms
```

## Checklist Pre-Review

- [ ] Todo cliente HTTP tiene timeout explícito
- [ ] Retry solo en errores 5xx/red (nunca en 4xx)
- [ ] Circuit breaker en servicios con SLA < 99.9%
- [ ] Bulkhead cuando ≥2 servicios externos comparten pool
- [ ] Fallback definido para estado OPEN del circuit breaker
