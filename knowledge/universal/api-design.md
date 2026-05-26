# API Design Knowledge Base

## Propósito
Conocimiento experto de diseño de APIs que se inyecta en agents durante /genesis.
Este conocimiento aplica a TODOS los proyectos que exponen APIs.

---

## Principios REST

### Recursos, no acciones
```
✓ GET  /users/123         (obtener usuario)
✓ POST /users             (crear usuario)
✗ GET  /getUser?id=123    (verbo en URL)
✗ POST /createUser        (verbo en URL)
```

### Sustantivos plurales
```
✓ /users
✓ /orders
✓ /products

✗ /user
✗ /getOrders
✗ /product-list
```

### Jerarquía de recursos
```
/users/{userId}/orders           # Órdenes de un usuario
/users/{userId}/orders/{orderId} # Orden específica
/orders/{orderId}/items          # Items de una orden
```

---

## Métodos HTTP

### Semántica correcta
```
┌────────┬───────────────┬────────────────┬──────────────┐
│ Método │ Acción        │ Idempotente    │ Safe         │
├────────┼───────────────┼────────────────┼──────────────┤
│ GET    │ Leer          │ Sí             │ Sí           │
│ POST   │ Crear         │ No             │ No           │
│ PUT    │ Reemplazar    │ Sí             │ No           │
│ PATCH  │ Actualizar    │ No*            │ No           │
│ DELETE │ Eliminar      │ Sí             │ No           │
└────────┴───────────────┴────────────────┴──────────────┘

* PATCH puede ser idempotente si se diseña así
```

### PUT vs PATCH
```typescript
// PUT: Reemplaza TODO el recurso
PUT /users/123
{
  "name": "John",
  "email": "john@test.com",
  "age": 30
  // Si omites campo, se borra/null
}

// PATCH: Actualiza campos específicos
PATCH /users/123
{
  "age": 31
  // Solo actualiza age, resto queda igual
}
```

---

## Status Codes

### Códigos esenciales
```
2xx Success
───────────────────────────
200 OK           → Request exitoso con body
201 Created      → Recurso creado (POST)
204 No Content   → Éxito sin body (DELETE)

4xx Client Error
───────────────────────────
400 Bad Request  → Input inválido, mal formato
401 Unauthorized → No autenticado
403 Forbidden    → Autenticado pero sin permiso
404 Not Found    → Recurso no existe
409 Conflict     → Conflicto (duplicado, estado)
422 Unprocessable → Validación de negocio falló
429 Too Many     → Rate limit excedido

5xx Server Error
───────────────────────────
500 Internal     → Error inesperado del servidor
502 Bad Gateway  → Upstream falló
503 Unavailable  → Servidor no disponible
504 Gateway Timeout → Upstream timeout
```

### Cuándo usar 4xx vs 5xx
```
4xx: El cliente hizo algo mal
    → Puede corregir y reintentar
    → Loggear como warning

5xx: El servidor falló
    → Cliente no puede corregir
    → Loggear como error, investigar
```

---

## Formato de Respuestas

### Respuesta exitosa (single)
```json
{
  "data": {
    "id": "123",
    "type": "user",
    "attributes": {
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

### Respuesta exitosa (collection)
```json
{
  "data": [
    { "id": "1", "name": "Item 1" },
    { "id": "2", "name": "Item 2" }
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "perPage": 20,
    "totalPages": 8
  },
  "links": {
    "self": "/items?page=1",
    "next": "/items?page=2",
    "last": "/items?page=8"
  }
}
```

### Respuesta de error
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "age",
        "message": "Must be a positive integer"
      }
    ]
  }
}
```

### Nunca exponer detalles internos
```json
// MAL - expone stack trace
{
  "error": "Error: ECONNREFUSED postgres://user:pass@db:5432"
}

// BIEN - mensaje genérico, detalles en logs
{
  "error": {
    "code": "DATABASE_ERROR",
    "message": "Unable to process request",
    "requestId": "req-abc123"  // Para correlacionar en logs
  }
}
```

---

## Paginación

### Offset-based (simple)
```
GET /users?page=2&limit=20

Pros: Fácil de implementar, permite "ir a página X"
Cons: Inconsistente si datos cambian, lento en offset grande
```

### Cursor-based (escalable)
```
GET /users?cursor=eyJpZCI6MTIzfQ&limit=20

Pros: Consistente, eficiente en cualquier página
Cons: No permite saltar a página específica

Response:
{
  "data": [...],
  "cursors": {
    "next": "eyJpZCI6MTQzfQ",
    "hasMore": true
  }
}
```

### Implementación cursor
```typescript
// Cursor = base64 del último ID
const cursor = Buffer.from(JSON.stringify({ id: lastItem.id })).toString('base64');

// Decodificar
const { id } = JSON.parse(Buffer.from(cursor, 'base64').toString());

// Query
SELECT * FROM users WHERE id > ? ORDER BY id LIMIT ?
```

---

## Filtrado y Búsqueda

### Filtros simples
```
GET /products?category=electronics&minPrice=100&maxPrice=500
GET /users?status=active&role=admin
```

### Filtros avanzados (si es necesario)
```
GET /products?filter[price][gte]=100&filter[price][lte]=500
GET /orders?filter[status][in]=pending,processing
```

### Búsqueda
```
GET /products?search=laptop
GET /users?q=john  # Búsqueda general
```

### Ordenamiento
```
GET /products?sort=price        # Ascendente
GET /products?sort=-price       # Descendente
GET /products?sort=-createdAt,name  # Múltiples campos
```

---

## Versionado

### Estrategias
```
URL Path (recomendado):
GET /v1/users
GET /v2/users

Header:
GET /users
Accept: application/vnd.api+json; version=2

Query param (menos común):
GET /users?version=2
```

### Cuándo versionar
```
Mayor versión (v1 → v2):
- Breaking changes en estructura
- Campos removidos
- Cambios de tipos

NO requiere nueva versión:
- Agregar campos opcionales
- Agregar endpoints
- Mejoras de performance
```

### Deprecación
```http
HTTP/1.1 200 OK
Deprecation: true
Sunset: Sat, 1 Jan 2025 00:00:00 GMT
Link: </v2/users>; rel="successor-version"
```

---

## Autenticación

### Bearer Token
```http
GET /users HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### API Key
```http
GET /users HTTP/1.1
X-API-Key: sk_live_abc123...
```

### Errores de auth
```json
// 401 - No autenticado
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Missing or invalid authentication token"
  }
}

// 403 - Autenticado pero sin permiso
{
  "error": {
    "code": "FORBIDDEN",
    "message": "You don't have permission to access this resource"
  }
}
```

---

## Rate Limiting

### Headers estándar
```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

### Respuesta cuando se excede
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "retryAfter": 60
  }
}
```

---

## Operaciones Async

### Para operaciones largas
```http
POST /reports HTTP/1.1

HTTP/1.1 202 Accepted
Location: /jobs/abc123
{
  "jobId": "abc123",
  "status": "processing",
  "statusUrl": "/jobs/abc123"
}
```

### Polling del status
```http
GET /jobs/abc123 HTTP/1.1

HTTP/1.1 200 OK
{
  "jobId": "abc123",
  "status": "completed",
  "result": "/reports/xyz789"
}
```

---

## Documentación

### OpenAPI/Swagger
```yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
```

### Documentar siempre
- Todos los endpoints
- Parámetros con tipos y ejemplos
- Respuestas posibles (éxito y error)
- Autenticación requerida
- Rate limits

---

## Validación

### Input validation
```typescript
// Validar en el borde (controller)
const schema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().positive().optional()
});

const result = schema.safeParse(req.body);
if (!result.success) {
  return res.status(400).json({
    error: {
      code: 'VALIDATION_ERROR',
      details: result.error.issues
    }
  });
}
```

### Sanitización
```typescript
// Escapar/limpiar input
const sanitizedHtml = DOMPurify.sanitize(input);
const trimmedName = name.trim();
const normalizedEmail = email.toLowerCase().trim();
```

---

## HATEOAS (Hypermedia)

### Links en respuestas
```json
{
  "data": {
    "id": "123",
    "name": "Order #123"
  },
  "links": {
    "self": "/orders/123",
    "customer": "/users/456",
    "items": "/orders/123/items",
    "cancel": "/orders/123/cancel"
  }
}
```

### Beneficios
- API auto-descubrible
- Cliente no hardcodea URLs
- Evolucion sin romper clientes

---

## Anti-Patterns

### Evitar
```
# Verbos en URLs
POST /createUser        → POST /users
GET /getUsers           → GET /users
POST /updateUser/123    → PUT /users/123

# Anidamiento excesivo
/company/123/dept/456/team/789/member/012
→ /members/012?team=789

# IDs secuenciales expuestos
/users/1, /users/2, /users/3
→ /users/abc123 (UUID)

# Exponer modelo de datos interno
{ "user_id": 1, "_internal_flag": true }
→ Transformar a DTO

# Inconsistencia
/users/123
/User/123
/user-profile/123
→ Elegir una convención y mantener
```

---

## Checklist de API

### Diseño
- [ ] URLs son recursos (sustantivos)
- [ ] Métodos HTTP correctos
- [ ] Status codes apropiados
- [ ] Respuestas consistentes
- [ ] Paginación en colecciones
- [ ] Versionado definido

### Seguridad
- [ ] HTTPS obligatorio
- [ ] Autenticación en endpoints privados
- [ ] Rate limiting
- [ ] Input validado
- [ ] No exponer datos internos

### Documentación
- [ ] OpenAPI/Swagger spec
- [ ] Ejemplos de request/response
- [ ] Errores documentados
- [ ] Autenticación explicada

### Operaciones
- [ ] Health check endpoint
- [ ] Logs de requests
- [ ] Métricas de latencia
- [ ] Alertas en errores
