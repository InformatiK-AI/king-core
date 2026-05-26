# Observability Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `universal/observability.md`

## Pilares de Observabilidad

| Pilar | Propósito | Herramientas |
|-------|-----------|--------------|
| Logs | Qué pasó | Winston, Pino, console.log estructurado |
| Metrics | Cuánto/Cuándo | Prometheus, DataDog, CloudWatch |
| Traces | Cómo fluyó | OpenTelemetry, Jaeger, Zipkin |

## Patterns Rápidos

```typescript
// Logging estructurado - SIEMPRE
logger.info('User action', {
  action: 'login',
  userId: user.id,
  ip: req.ip,
  timestamp: new Date().toISOString()
});

// Error logging - Con contexto
logger.error('Payment failed', {
  error: err.message,
  stack: err.stack,
  orderId: order.id,
  amount: order.total
});

// Métricas - Counters y timers
const requestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests',
  labelNames: ['method', 'route', 'status']
});
```

## Niveles de Log

| Nivel | Cuándo usar | Ejemplo |
|-------|-------------|---------|
| ERROR | Fallo que afecta usuario | Payment failed |
| WARN | Potencial problema | Rate limit approaching |
| INFO | Eventos de negocio | User logged in |
| DEBUG | Detalles técnicos | Query executed |

## Señales de Alerta

- `console.log` sin estructura en producción
- Logs sin timestamp o request ID
- Métricas sin labels
- Errores sin stack trace
- Sin correlation ID entre servicios

## Liveness vs. Readiness

| Probe | Endpoint | Verifica deps | Fallo → |
|-------|----------|--------------|---------|
| Liveness | `/health` | ❌ NUNCA | Pod restart |
| Readiness | `/ready` | ✅ Siempre | Fuera del LB |

Contrato: `/health` → `{status:"ok", version, timestamp}` · `/ready` → `{status, checks:{dep:"ok|fail"}}` (503 si falla)
> Detalle completo: `knowledge/universal/observability.md` → "Liveness vs. Readiness"

## Checklist Pre-Deploy

- [ ] Logs estructurados (JSON)
- [ ] Error tracking configurado (Sentry, etc.)
- [ ] Health endpoints `/health` (liveness) y `/ready` (readiness) — ver `/health-check-setup`
- [ ] Métricas básicas expuestas
- [ ] Alertas configuradas para errores críticos
