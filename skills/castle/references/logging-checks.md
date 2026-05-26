# Capa L — Logging Checks

## L1: Structured Logging
**Severidad**: WARNING
**Descripción**: Los logs deben ser estructurados y útiles para debugging.

### Checks:
- Logs del servidor incluyen: timestamp, level, message, context
- No se usa `console.log` para logging de producción (usar logger estructurado)
- Logs no contienen datos sensibles (API keys, passwords, PII)
- Niveles de log apropiados: ERROR para errores, WARN para advertencias, INFO para operaciones normales

### Estado actual de King:
El servidor usa `console.log` y `console.error` directamente. Esto es aceptable para la fase actual pero se debe mejorar.

### Cómo verificar:
1. Buscar `console.log` y `console.error` en server/index.js
2. Verificar que los logs incluyen contexto suficiente
3. Verificar que no se loggean datos sensibles

---

## L2: Error Handling
**Severidad**: WARNING
**Descripción**: Los errores deben manejarse de forma consistente y útil.

### Checks:
- Todas las llamadas async tienen catch/error handling
- Errores de Anthropic API se traducen a mensajes útiles para el usuario
- El servidor retorna códigos HTTP apropiados (400, 429, 500)
- Errores en el frontend se capturan por ErrorBoundary
- Stack traces no se envían al cliente en producción

### Cómo verificar:
1. Buscar `await` sin try/catch en server/index.js
2. Verificar que el error boundary captura errores de render
3. Verificar que los error responses del servidor son informativos pero no exponen internals

---

## L3: Health Endpoints
**Severidad**: WARNING
**Descripción**: Los health endpoints deben reportar estado útil.

### Checks:
- `GET /api/health` está implementado y responde
- Health check verifica que la API key está configurada
- Health check reporta uptime
- Health check es ligero (no hace llamadas a Anthropic API)

### Cómo verificar:
1. Leer el handler de `/api/health` en server/index.js
2. Verificar que los campos están presentes: status, apiKeyConfigured, uptime

---

## L4: Metric Baselines
**Severidad**: WARNING
**Descripción**: Métricas básicas deben estar disponibles para monitoreo.

### Checks:
- Stats de tokens y costos se trackean (GET /api/stats)
- Request count se trackea
- Los stats se resetean al reiniciar (aceptable para fase actual)
- Pricing está actualizado ($3/MTok input, $15/MTok output)

### Cómo verificar:
1. Leer el handler de `/api/stats` en server/index.js
2. Verificar que el pricing está correcto para los modelos actuales
