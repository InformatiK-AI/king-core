---
name: sdd-ff
description: "Fast-forward SDD: ejecuta propose → spec → design → tasks en secuencia para cambios bien entendidos."
version: 1.0.0
api_version: 1.0.0
argument-hint: "<change-name>"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
---

# /sdd-ff — Fast-Forward SDD

Meta-comando SDD fast-forward. Para cambios donde el alcance ya está claro y se quiere avanzar rápidamente hasta tener las tareas listas.

## Parámetros

| Parámetro | Requerido | Descripción |
|-----------|-----------|-------------|
| `<change-name>` | SÍ | Nombre del cambio existente en `.king/sdd/` |

## Secuencia de ejecución

```
sdd-propose → sdd-spec ║ sdd-design (paralelo) → sdd-tasks
```

## Instrucciones

1. Verificar que se proporcionó `<change-name>`. Si no, listar cambios disponibles en `.king/sdd/` y pedir al usuario.

2. **Cargar orquestador**: Leer `agents/_common/protocols/sdd-orchestrator.md`.

3. **Verificar estado**: Leer `.king/sdd/<change-name>/state.yaml`. El cambio debe existir y tener al menos `sdd-init` completado.

4. **Ejecutar sdd-propose** (si no completado): Cargar `skills/sdd-propose/SKILL.md`.

5. **Ejecutar sdd-spec y sdd-design en paralelo**: Cargar ambos skills y ejecutarlos con agentes concurrentes si es posible.
   - `skills/sdd-spec/SKILL.md` → genera especificación técnica
   - `skills/sdd-design/SKILL.md` → genera diseño arquitectónico

6. **Ejecutar sdd-tasks**: Cargar `skills/sdd-tasks/SKILL.md` una vez que spec y design estén completos.
   - Genera el plan de tareas implementables

7. Al completar, mostrar resumen y confirmar que el cambio está listo para `/sdd-apply`.

## Estado resultante

Después de `/sdd-ff <change-name>`:
- Fases `propose`, `spec`, `design`, `tasks` completadas en `state.yaml`
- Listo para `/sdd-apply <change-name>`

## Ver también

- Orquestador: `agents/_common/protocols/sdd-orchestrator.md`
- Aplicar: `skills/sdd-apply/SKILL.md`
- Continuar desde estado actual: `skills/sdd-continue/SKILL.md`
