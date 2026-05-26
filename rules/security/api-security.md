---
name: api-security
description: "Reglas de seguridad para la API REST del servidor"
---

# Rule: API Security

> **Nota**: Los valores en `{PLACEHOLDER}` deben configurarse según tu proyecto.

**Alcance**: `{your-server-file}` y endpoints de la API
**Severidad**: BLOQUEANTE

## Directivas

1. **CORS**: Solo permitir origins explícitos via `{CORS_ALLOWED_ORIGINS}` env var (default configurable según tu entorno). NUNCA usar `*` como origin
2. **Rate limiting**: Máximo `{RATE_LIMIT_PER_MINUTE}` req/min por IP en endpoints sensibles (ajustar según tu caso de uso). Todo endpoint nuevo que acceda a recursos externos DEBE tener rate limiting
3. **Body limit**: `{MAX_BODY_SIZE}` máximo en requests (ajustar según payload esperado)
4. **Input validation**: Validar TODOS los campos del body antes de proxy a `{servicio externo que consumes}`:
   - Campos de tipo enumerado deben validarse contra `{ALLOWED_VALUES}` (definir según tu API)
   - Arrays requeridos deben ser no vacíos
   - Campos numéricos deben validarse según el rango esperado
5. **Timeout**: `{REQUEST_TIMEOUT_MS}` máximo por request a `{servicio externo que consumes}` (ajustar según SLA del servicio externo)
6. **Error handling**: NUNCA exponer stack traces o detalles internos en respuestas de error al cliente
7. **Headers**: Eliminar `X-Powered-By`, considerar security headers básicos
8. **Endpoints de métricas/estado**: No deben exponer información sensible
