---
name: sdd-continue
description: "Continuar el SDD en la siguiente fase disponible del DAG. Detecta automáticamente qué fases están listas para ejecutar."
version: 1.0.0
argument-hint: "[change-name]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
---

# /sdd-continue — Continuar SDD

Meta-comando SDD. Detecta automáticamente el estado actual del cambio y ejecuta la siguiente fase disponible según el DAG.

> **Path resolution**: Paths `skills/`, `agents/`, `knowledge/` son relativas a KING_FRAMEWORK_PATH (anunciado al inicio de sesión). Prepend ese valor al usar Read.

## Parámetros

| Parámetro | Requerido | Descripción |
|-----------|-----------|-------------|
| `[change-name]` | Opcional | Nombre del cambio. Si se omite, detecta el cambio activo en `.king/sdd/` |

## DAG de fases

```
proposal → specs ║ design → tasks → apply → verify → archive
```

## Instrucciones

1. **Detectar cambio activo**:
   - Si se proporcionó `<change-name>`, usarlo directamente.
   - Si no, buscar en `.king/sdd/` el cambio con `status: in_progress` en `state.yaml`.
   - Si hay múltiples cambios in-progress, listarlos y pedir al usuario que elija.

2. **Cargar orquestador**: Leer `agents/_common/protocols/sdd-orchestrator.md`.

3. **Leer estado**: Leer `.king/sdd/<change-name>/state.yaml`.

4. **Detectar siguiente fase**: Según el DAG, identificar qué fases tienen todas sus dependencias completadas y aún no están completadas.

5. **Ejecutar la siguiente fase**: Cargar el SKILL.md correspondiente:
   | Fase | Skill |
   |------|-------|
   | proposal | `skills/sdd-propose/SKILL.md` |
   | spec | `skills/sdd-spec/SKILL.md` |
   | design | `skills/sdd-design/SKILL.md` |
   | tasks | `skills/sdd-tasks/SKILL.md` |
   | apply | `skills/sdd-apply/SKILL.md` |
   | verify | `skills/sdd-verify/SKILL.md` |
   | archive | `skills/sdd-archive/SKILL.md` |

6. Si spec y design ambos están disponibles (dependencias satisfechas), ejecutarlos en paralelo con agentes.

7. Si todas las fases están completadas, indicar que el cambio está archivado y no hay más fases.

8. Al completar la fase, mostrar el estado actualizado y el próximo paso disponible.

## Ver también

- Orquestador: `agents/_common/protocols/sdd-orchestrator.md`
- Iniciar nuevo cambio: `skills/sdd-new/SKILL.md`
- Fast-forward: `skills/sdd-ff/SKILL.md`
