# Flujo de Ejecución de Skills — King Framework

Este archivo documenta el flujo típico de ejecución de skills dentro de King Framework.

## Pipeline canónico

```
genesis → brainstorm → plan → create-issues → build → review → qa → merge → qa-batch → promote-qa → qa-env → release → promote-prod
```

## Ciclo de vida de un feature

```
/genesis → /brainstorm → /plan → /create-issues → /build → /review → /qa → /merge → /qa --batch → /promote --to qa → /qa --env → /release → /promote --to prod
```

## Tabla de transiciones

| Skill actual       | Condición                   | Próximo skill          |
|--------------------|-----------------------------|------------------------|
| /genesis           | Siempre                     | /brainstorm            |
| /brainstorm        | Modo PROYECTO               | /brainstorm --feature  |
| /brainstorm        | Modo FEATURE sin UI         | /plan                  |
| /brainstorm        | Modo FEATURE con UI         | /frontend-design       |
| /frontend-design   | Siempre                     | /plan                  |
| /plan              | Siempre                     | /create-issues         |
| /create-issues     | Siempre                     | /build                 |
| /build             | Siempre                     | /review                |
| /review            | APROBADO                    | /qa                    |
| /review            | CAMBIOS REQUERIDOS          | /fix                   |
| /refactor          | Siempre                     | /review                |
| /qa                | CASTLE >= CONDITIONAL       | /merge                 |
| /qa                | CASTLE BREACHED             | /fix → /qa             |
| /fix               | Fix aplicado                | /review                |
| /merge             | Merge exitoso               | /qa --batch            |
| /qa --batch        | FORTIFIED                   | /promote --to qa       |
| /promote (qa)      | Health OK                   | /qa --env              |
| /qa --env          | FORTIFIED                   | /release               |
| /release           | Completo                    | /promote --to prod     |

## Skills standalone (sin workflow)

- `/castle` — Evaluación independiente
- `/radar` — Razonamiento estructurado
- `/gitflow` — Gestión de branches
- `/github-ops` — Operaciones GitHub
- `/worktree` — Gestión de worktrees
- `/audit` — Auditoría del proyecto

## Persistencia

Cada skill ejecuta las fases de sesión definidas en `skills/session-management/SKILL.md`:
- **Phase 0**: Load Context — leer `.king/registry.md` y workflow activo
- **Phase N+1**: Write Session — crear session document y actualizar registry
- **Phase N+2**: Guide Next Step — indicar próximo skill recomendado
