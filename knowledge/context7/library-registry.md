# Context7 Library Registry

> Generado por `/genesis`. IDs pre-resueltos para consultas rapidas.
>
> Este archivo es un template inicial. Al ejecutar `/genesis` en un proyecto
> con dependencias detectables (package.json, requirements.txt, etc.),
> se reemplaza con los IDs reales de las librerias del proyecto.

## Estado

**No inicializado** — ejecuta `/genesis` en tu proyecto para resolver los IDs de tus librerias.

## Formato esperado (post-genesis)

| Library | Context7 ID | Resolved On |
|---------|-------------|-------------|
| _(vacio hasta ejecutar /genesis)_ | | |

## Como se genera

Durante `/genesis` Phase 3, paso 6:

1. Se detectan dependencias del proyecto (package.json, requirements.txt, etc.)
2. Se extraen las librerias principales (max 10)
3. Para cada una se ejecuta `resolve-library-id(nombre, query)`
4. Los IDs resueltos se registran en esta tabla
5. Se presenta al usuario para confirmacion

## Como usar (post-genesis)

```
1. Buscar libreria en la tabla de arriba
2. Si tiene ID → query-docs(id, "pregunta especifica")
3. Si no tiene ID → resolve-library-id(nombre, query) → agregar a esta tabla
```

## Requisitos

- Servidor MCP de Context7 configurado en `.mcp.json`
- Node.js disponible para `npx`

## Si Context7 no esta disponible

Los agentes usan knowledge estatico de `knowledge/` como fallback.
No es necesario tener Context7 para que el framework funcione.

## Ver también

- Inject para agents: `knowledge/_inject/context7-essentials.md`
- Context7 README: `knowledge/context7/README.md`
- Genesis (paso 6): `skills/genesis/GENERATION.md`
