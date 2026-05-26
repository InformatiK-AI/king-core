# API Design Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `universal/api-design.md`

## HTTP Methods

| Method | Uso | Idempotente |
|--------|-----|-------------|
| GET | Leer recurso | Sí |
| POST | Crear recurso | No |
| PUT | Reemplazar recurso | Sí |
| PATCH | Actualizar parcial | No* |
| DELETE | Eliminar recurso | Sí |

## Status Codes Esenciales

| Code | Significado | Cuándo usar |
|------|-------------|-------------|
| 200 | OK | GET/PUT/PATCH exitoso |
| 201 | Created | POST exitoso |
| 204 | No Content | DELETE exitoso |
| 400 | Bad Request | Input inválido |
| 401 | Unauthorized | No autenticado |
| 403 | Forbidden | Sin permisos |
| 404 | Not Found | Recurso no existe |
| 422 | Unprocessable | Validación fallida |
| 500 | Server Error | Error interno |

## Patterns Rápidos

```typescript
// Naming - SIEMPRE plural, sustantivos
GET    /users          // Lista
GET    /users/:id      // Detalle
POST   /users          // Crear
PUT    /users/:id      // Reemplazar
PATCH  /users/:id      // Actualizar
DELETE /users/:id      // Eliminar

// Nested resources
GET /users/:userId/orders

// Response envelope
{
  "data": { ... },
  "meta": { "page": 1, "total": 100 }
}

// Error response
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is invalid",
    "details": [{ "field": "email", "issue": "format" }]
  }
}
```

## Señales de Alerta

- Verbos en URLs (`/getUser`, `/createOrder`)
- POST para todo (no REST)
- 200 OK con error en body
- Sin versionado (`/v1/users`)
- Exponer IDs internos sensibles

## Checklist Pre-Deploy

- [ ] URLs usan sustantivos plurales
- [ ] Status codes correctos
- [ ] Errores tienen estructura consistente
- [ ] Paginación en listas
- [ ] Rate limiting configurado
