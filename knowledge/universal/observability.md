# Observability Knowledge Base

## Propósito
Conocimiento experto de observabilidad que se inyecta en agents durante /genesis.
Este conocimiento aplica a TODOS los proyectos, independiente del stack.

---

## Los Tres Pilares

```
┌─────────────────────────────────────────────────────────────┐
│                     OBSERVABILITY                           │
├───────────────────┬───────────────────┬────────────────────┤
│      LOGS         │     METRICS       │     TRACES         │
│   (Qué pasó)      │   (Cuánto)        │   (Dónde)          │
├───────────────────┼───────────────────┼────────────────────┤
│ Eventos discretos │ Valores numéricos │ Request journey    │
│ Debugging         │ Alerting          │ Distributed debug  │
│ Audit trail       │ Dashboards        │ Performance        │
└───────────────────┴───────────────────┴────────────────────┘
```

---

## Logging

### Niveles de log
| Nivel | Uso | Ejemplo |
|-------|-----|---------|
| ERROR | Fallas que requieren acción | DB connection failed |
| WARN | Problemas potenciales | Retry attempt 3/5 |
| INFO | Eventos de negocio | User created, Order placed |
| DEBUG | Desarrollo/troubleshooting | Request payload, Query executed |
| TRACE | Muy detallado (raro) | Loop iterations |

### Reglas de uso
```typescript
// ERROR: El sistema NO puede continuar normalmente
logger.error('Payment processing failed', { orderId, error: err.message });

// WARN: El sistema puede continuar pero algo está mal
logger.warn('Rate limit approaching', { current: 90, limit: 100 });

// INFO: Eventos de negocio significativos
logger.info('User registered', { userId, email });

// DEBUG: Solo en desarrollo o troubleshooting
logger.debug('Cache miss', { key, ttl });
```

### Structured Logging
```typescript
// MAL: Log como string
console.log(`User ${userId} created order ${orderId} for $${amount}`);

// BIEN: Log estructurado
logger.info('Order created', {
  userId,
  orderId,
  amount,
  currency: 'USD',
  timestamp: new Date().toISOString()
});

// Output JSON (parseable por log aggregators)
// {"level":"info","message":"Order created","userId":"123","orderId":"456",...}
```

### Contexto mínimo por log
```typescript
// Siempre incluir
{
  timestamp: '2024-01-15T10:30:00Z',  // ISO 8601
  level: 'info',
  message: 'Event description',

  // Identificadores de trazabilidad
  requestId: 'req-123',     // Correlación de request
  userId: 'user-456',       // Quién

  // Contexto específico del evento
  action: 'order.created',
  resourceId: 'order-789'
}
```

### Qué NO loggear
```typescript
// NUNCA loggear
- Passwords (ni hasheados)
- Tokens de acceso completos
- Números de tarjeta
- SSN, datos de salud
- Datos personales sensibles (GDPR)

// Si necesitas referencia, truncar
logger.info('Token validated', {
  tokenPrefix: token.substring(0, 8) + '...'
});
```

### Log Rotation
```typescript
// Configurar rotación para evitar llenado de disco
const logger = winston.createLogger({
  transports: [
    new winston.transports.File({
      filename: 'app.log',
      maxsize: 10 * 1024 * 1024,  // 10MB
      maxFiles: 5,                 // Mantener 5 archivos
      tailable: true
    })
  ]
});
```

---

## Metrics

### Tipos de métricas
| Tipo | Uso | Ejemplo |
|------|-----|---------|
| Counter | Valores que solo incrementan | Requests totales, errores |
| Gauge | Valores que suben/bajan | Conexiones activas, memoria |
| Histogram | Distribución de valores | Latencias, tamaños |
| Summary | Percentiles precalculados | P50, P95, P99 latencia |

### RED Method (Request-oriented)
Para servicios:
```
Rate      → Requests por segundo
Errors    → Tasa de errores
Duration  → Latencia (histograma)
```

### USE Method (Resource-oriented)
Para recursos (CPU, memoria, disco):
```
Utilization → % de uso
Saturation  → Cola de espera
Errors      → Errores del recurso
```

### Métricas esenciales
```typescript
// Requests
http_requests_total{method, path, status}
http_request_duration_seconds{method, path}

// Errores
errors_total{type, component}

// Negocio
orders_created_total
users_registered_total
payment_processed_total{status}

// Recursos
process_cpu_usage
process_memory_bytes
db_connections_active
cache_hit_ratio
```

### Nomenclatura
```
<namespace>_<name>_<unit>

# Ejemplos
api_requests_total           # Counter de requests
api_request_duration_seconds # Histograma de duración
cache_size_bytes            # Gauge de tamaño
```

---

## Tracing

### Conceptos
```
TRACE (viaje completo)
└── SPAN (operación individual)
    ├── SPAN (sub-operación)
    │   └── SPAN (sub-sub-operación)
    └── SPAN (otra sub-operación)
```

### Propagación de contexto
```typescript
// El trace ID viaja entre servicios
// Request headers
{
  'x-trace-id': 'abc-123',
  'x-span-id': 'span-456',
  'x-parent-id': 'span-123'
}
```

### Instrumentación básica
```typescript
// Inicio de span
const span = tracer.startSpan('processOrder', {
  attributes: {
    'order.id': orderId,
    'user.id': userId
  }
});

try {
  // Operación
  const result = await processOrder(orderId);
  span.setStatus({ code: SpanStatusCode.OK });
  return result;
} catch (error) {
  span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
  span.recordException(error);
  throw error;
} finally {
  span.end();
}
```

### Qué instrumentar
1. **Entradas** - HTTP handlers, message consumers
2. **Salidas** - DB queries, HTTP clients, queues
3. **Operaciones críticas** - Lógica de negocio importante

---

## Alerting

### Filosofía
- Alertar sobre **síntomas**, no causas
- Cada alerta debe ser **actionable**
- Evitar **alert fatigue** (demasiadas alertas)

### SLIs, SLOs, SLAs
```
SLI (Indicator) = Métrica que mide calidad
                  Ej: % requests < 200ms

SLO (Objective) = Target para el SLI
                  Ej: 99.9% requests < 200ms

SLA (Agreement) = Contrato con consecuencias
                  Ej: 99.9% uptime o reembolso
```

### Umbrales recomendados
```yaml
# Disponibilidad
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
  for: 5m
  annotations:
    summary: "Error rate > 1%"

# Latencia
- alert: HighLatency
  expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 2
  for: 5m
  annotations:
    summary: "P99 latency > 2s"

# Saturación
- alert: HighMemoryUsage
  expr: process_memory_bytes / node_memory_total_bytes > 0.9
  for: 5m
  annotations:
    summary: "Memory usage > 90%"
```

---

## Health Checks

### Liveness vs. Readiness — Distinción crítica

| Probe | Endpoint | Propósito | Verifica dependencias | Respuesta fallo |
|-------|----------|-----------|----------------------|-----------------|
| **Liveness** | `GET /health` | ¿El proceso está vivo? | ❌ NUNCA | Kubernetes reinicia el pod |
| **Readiness** | `GET /ready` | ¿Puede recibir tráfico? | ✅ Siempre | Kubernetes saca el pod del LB |

**Regla de oro**: `/health` nunca toca base de datos ni servicios externos. Si lo hace, un fallo de DB mata el pod en cascada.

### Contrato de respuesta estándar (King Framework)

```
GET /health → HTTP 200
{ "status": "ok", "version": "<app-version>", "timestamp": "<iso-8601>" }

GET /ready (OK) → HTTP 200
{ "status": "ok", "checks": { "db": "ok", "cache": "ok" } }

GET /ready (dep caída) → HTTP 503
{ "status": "not_ready", "checks": { "db": "fail", "cache": "ok" } }
```

**Reglas de seguridad**:
- `checks` usa solo `"ok" | "fail"` — NUNCA exponer IPs, mensajes del driver, stack traces
- Cache del resultado de `/ready` (TTL 5s default vía `HEALTH_CACHE_TTL`) — evita DoS contra dependencias
- Suprimir `/health` y `/ready` del access log — evitan contaminar el trail de auditoría

### Endpoints estándar (implementación)
```typescript
// Liveness: ¿El proceso está vivo?
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: process.env.npm_package_version,
    timestamp: new Date().toISOString()
  });
});

// Readiness: ¿Puede recibir tráfico?
app.get('/ready', async (req, res) => {
  const dbOk = await checkDatabase();   // solo "ok" | "fail" — sin detalles del driver
  const cacheOk = await checkCache();

  const allOk = dbOk && cacheOk;
  res.status(allOk ? 200 : 503).json({
    status: allOk ? 'ok' : 'not_ready',
    checks: { db: dbOk ? 'ok' : 'fail', cache: cacheOk ? 'ok' : 'fail' }
  });
});
```

### Checks típicos
```typescript
const healthChecks = {
  database: async () => {
    await db.query('SELECT 1');
    return true;
  },
  cache: async () => {
    await redis.ping();
    return true;
  },
  externalApi: async () => {
    const resp = await fetch(API_URL + '/health');
    return resp.ok;
  }
};
```

---

## Dashboards

### Dashboard de servicio (Golden Signals)
```
┌─────────────────────────────────────────────────────────────┐
│  SERVICE: order-service                                     │
├────────────────┬────────────────┬───────────────────────────┤
│   REQUEST RATE │   ERROR RATE   │   LATENCY P50/P95/P99     │
│   1.2k req/s   │     0.1%       │   45ms / 120ms / 450ms    │
├────────────────┴────────────────┴───────────────────────────┤
│   SATURATION                                                │
│   CPU: 45%  │  Memory: 60%  │  Connections: 80/100          │
└─────────────────────────────────────────────────────────────┘
```

### Dashboard de negocio
```
┌─────────────────────────────────────────────────────────────┐
│  BUSINESS METRICS                                           │
├────────────────┬────────────────┬───────────────────────────┤
│   ORDERS/hour  │  REVENUE/day   │   CONVERSION RATE         │
│      523       │    $45,230     │       3.2%                │
├────────────────┴────────────────┴───────────────────────────┤
│   TOP ERRORS   │   SLOWEST ENDPOINTS                        │
│   - PaymentFailed: 12                                       │
│   - InventoryError: 5                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Debugging en Producción

### Runbook mental
```
1. ¿Hay alertas activas?
   → Revisar dashboard de alertas

2. ¿Cambió algo recientemente?
   → Revisar deploys, config changes

3. ¿Es un problema de un usuario o general?
   → Filtrar logs por user/request ID

4. ¿Dónde está el cuello de botella?
   → Revisar traces, métricas de latencia

5. ¿Es un problema de recursos?
   → Revisar CPU, memoria, conexiones
```

### Queries útiles
```
# Logs: Errores de las últimas 2 horas
level:error AND @timestamp:[now-2h TO now]

# Logs: Requests lentos de un usuario
userId:123 AND duration:>1000

# Traces: Requests con errores
status:error AND service:order-service

# Métricas: Rate de errores
rate(http_requests_total{status="500"}[5m])
```

---

## Checklist de Observability

### Por servicio
- [ ] Logs estructurados en JSON
- [ ] Request ID en todos los logs
- [ ] Métricas RED expuestas
- [ ] Health check endpoints
- [ ] Traces instrumentados

### Por ambiente
- [ ] Log aggregation configurado
- [ ] Dashboards de servicio
- [ ] Alertas básicas activas
- [ ] Retention policies definidas

### Antes de producción
- [ ] Logs no contienen secrets
- [ ] Log levels apropiados
- [ ] Alertas probadas
- [ ] Runbooks documentados
