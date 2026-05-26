# Context7 — Documentación en Vivo

Directorio para integración con Context7 MCP, que provee documentación actualizada de librerías.

## Contenido

| Archivo | Generado por | Propósito |
|---------|--------------|-----------|
| `library-registry.md` | `/genesis` | IDs pre-resueltos de librerías del proyecto |

> `library-registry.md` se crea dinámicamente durante `/genesis`.
> No existe hasta que se ejecuta genesis en un proyecto con dependencias detectables.

## Inject

El archivo `_inject/context7-essentials.md` se inyecta en @developer y @architect durante `/genesis`,
enseñándoles cuándo y cómo consultar Context7.

## Flujo

```
/genesis
  │
  ├─ Detectar dependencias (package.json, requirements.txt, etc.)
  ├─ resolve-library-id() para cada librería principal (max 10)
  ├─ Crear library-registry.md con IDs resueltos
  │
  └─ Inyectar context7-essentials.md en agents

Durante desarrollo:
  │
  ├─ Agent consulta registry para obtener ID
  ├─ query-docs(id, pregunta) para docs actualizadas
  └─ Aplica resultado al código
```

## Cuándo NO usar Context7

- Knowledge estático (`universal/`, `stacks/`) ya cubre el tema
- La pregunta es conceptual, no de API específica
- No se necesita información actualizada (patrones SOLID, testing, etc.)
- El MCP no está configurado (degradación elegante a knowledge estático)

## Requisitos

- Servidor MCP configurado en `.mcp.json` (raíz del proyecto)
- Node.js disponible para `npx`

## Ver también

- Inject: `knowledge/_inject/context7-essentials.md`
- MCP config: `.mcp.json`
- Genesis skill: `skills/genesis/SKILL.md` (paso 6, PHASE 3)
