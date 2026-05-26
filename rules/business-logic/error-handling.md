---
name: error-handling
description: "Patrones de manejo de errores: estructurado, mensajes claros, sin swallow silencioso"
---

# Rule: Error Handling

**Severidad**: ERROR (ignorar errores = bug crítico potencial)

## Patrones obligatorios

1. **No swallow silencioso**: `catch(e) {}` está prohibido
2. **Mensajes de error útiles**: Incluir contexto suficiente para debug
3. **Errores específicos**: No usar `Error` genérico cuando hay un tipo más específico
4. **Logging de errores**: Loguear antes de re-throw o cuando se maneja

## Antipatrones prohibidos
```
// MAL: swallow silencioso
try { doSomething() } catch(e) {}

// MAL: mensaje sin contexto
throw new Error('Error')

// BIEN: mensaje con contexto
throw new Error(`Failed to process user ${userId}: ${e.message}`)
```

## Propagación
- Errores de dominio: manejar en la capa que tiene contexto
- Errores de infraestructura: propagar hacia arriba con contexto
- Errores de usuario (validación): retornar como respuesta, no lanzar excepción
