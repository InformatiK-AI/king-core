# Capa C — Contracts Checks

## C1: API Schema Match
**Severidad**: BLOQUEANTE
**Descripción**: Los endpoints del servidor deben cumplir con sus contratos documentados.

### Checks:
- `{YOUR_API_ENDPOINT}`: Body acepta `{REQUEST_SCHEMA}` (campos requeridos y tipos documentados), responde con `{RESPONSE_SCHEMA}` (campos y tipos documentados)
- Ejemplo de endpoint secundario (health, status, etc.): responde con el schema documentado para ese endpoint
- Response codes: 200 (ok), 400 (bad request), 429 (rate limited), 500 (server error)
- Content-Type: application/json en todas las respuestas

### Cómo verificar:
1. Leer `{your-server-file}` y verificar que los handlers coinciden con los schemas documentados
2. Verificar que los campos del body se validan antes de proxy al servicio externo
3. Verificar que los códigos de error son correctos
4. Verificar Content-Type headers

---

## C2: Inter-Module Contracts
**Severidad**: WARNING
**Descripción**: Los contratos entre frontend y backend deben ser consistentes.

### Checks:
- Las llamadas desde el cliente usan el schema correcto del endpoint (`{REQUEST_SCHEMA}`)
- Los campos enviados coinciden con lo que el servidor espera
- Los campos de respuesta que el cliente consume existen en la respuesta real (`{RESPONSE_SCHEMA}`)
- Timeout del cliente es consistente con el timeout del servidor

### Cómo verificar:
1. Verificar el body enviado en las llamadas al API
2. Comparar con el handler de `{PROJECT_ENDPOINT}` en `{your-server-file}`
3. Verificar que el frontend maneja todos los posibles response codes

---

## C3: Breaking Changes Detection
**Severidad**: BLOQUEANTE
**Descripción**: Cambios que rompen contratos existentes deben ser detectados.

### Checks:
- ¿Se removió algún campo de request/response?
- ¿Se cambió el tipo de algún campo?
- ¿Se modificó el comportamiento de un endpoint sin versionar?
- ¿Se cambió el rate limiting sin documentar?

### Cómo verificar:
1. Comparar diff del servidor con los schemas documentados
2. Si hay breaking changes, verificar que el frontend se actualizó en paralelo
3. Documentar breaking changes en el PR

---

## C4: Compliance
**Severidad**: WARNING
**Descripción**: El código debe cumplir con estándares de la industria aplicables.

### Checks:
- Body limit documentado y enforced
- Rate limiting documentado y configurable
- Timeouts documentados
- Error messages no exponen información interna
