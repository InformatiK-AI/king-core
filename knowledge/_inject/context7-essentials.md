# Context7 Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `context7/README.md`

## Qué es

Dos herramientas MCP para consultar documentación actualizada de librerías:

| Herramienta | Propósito |
|-------------|-----------|
| `resolve-library-id` | Obtener el ID Context7 de una librería |
| `query-docs` | Consultar docs y ejemplos con ese ID |

## Cuándo usar

| Usar Context7 | NO usar Context7 |
|---------------|-------------------|
| API nueva o desconocida | Knowledge estático ya cubre el tema |
| Duda sobre sintaxis actual | Patrón genérico (SOLID, testing, etc.) |
| Breaking changes o migraciones | No requiere info actualizada |
| Librería no cubierta en knowledge/ | Pregunta conceptual, no de API |

## Cómo usar

```
1. Verificar registry → knowledge/context7/library-registry.md
2. Si librería tiene ID → query-docs(id, "pregunta específica")
3. Si no tiene ID → resolve-library-id(nombre, query) → query-docs
4. Aplicar resultado al código
```

## Reglas

- **Max 2 consultas por tarea** — ser específico en la query
- **Preferir knowledge estático** cuando existe y es suficiente
- **Query específica** — "How to use useFormStatus in React 19" > "React hooks"
- **Registrar libs nuevas** — si resuelves un ID nuevo, documentar en registry
- **Degradación elegante** — si MCP no disponible, usar knowledge estático

## Registry

Path: `knowledge/context7/library-registry.md`

Generado por `/genesis`. Contiene IDs pre-resueltos para las librerías del proyecto.
