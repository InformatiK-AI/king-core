---
name: sdd-new
description: "Iniciar un nuevo cambio SDD. Crea la estructura OpenSpec y ejecuta sdd-init → sdd-explore → sdd-propose en secuencia."
version: 1.0.0
api_version: 1.0.0
argument-hint: "<change-name>"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
---

# /sdd-new — Nuevo Cambio SDD

Meta-comando SDD. Orquesta el inicio de un nuevo cambio desde cero.

## Parámetros

| Parámetro | Requerido | Descripción |
|-----------|-----------|-------------|
| `<change-name>` | SÍ | Nombre kebab-case del cambio (ej: `add-user-auth`) |

## Secuencia de ejecución

```
sdd-init → sdd-explore → sdd-propose
```

## Instrucciones

1. Verificar que se proporcionó `<change-name>`. Si no, pedir al usuario.

2. **Cargar orquestador**: Leer `agents/_common/protocols/sdd-orchestrator.md` para las reglas de estado y DAG.

3. **Ejecutar sdd-init**: Cargar `skills/sdd-init/SKILL.md` y ejecutar con el `<change-name>` dado.
   - Crea `.king/sdd/<change-name>/` con estructura OpenSpec
   - Genera `state.yaml` inicial

4. **Ejecutar sdd-explore**: Cargar `skills/sdd-explore/SKILL.md` y ejecutar.
   - Explora el codebase relacionado con el cambio
   - Documenta hallazgos en `exploration.md`

5. **Ejecutar sdd-propose**: Cargar `skills/sdd-propose/SKILL.md` y ejecutar.
   - Genera propuesta de diseño inicial
   - Registra en `proposal.md`

6. Al completar, mostrar resumen del estado del cambio y los próximos pasos disponibles.

## Estado resultante

Después de `/sdd-new <change-name>`:
- `.king/sdd/<change-name>/state.yaml` con fases `init`, `explore`, `propose` completadas
- Listo para `/sdd-ff <change-name>` o `/sdd-continue <change-name>`

## Ver también

- Orquestador: `agents/_common/protocols/sdd-orchestrator.md`
- Continuar: `skills/sdd-continue/SKILL.md`
- Fast-forward: `skills/sdd-ff/SKILL.md`
