---
name: worktree
version: 2.0
api_version: 1.0.0
structure: command-based
description: "Gestión de Git Worktrees para desarrollo aislado. Maneja ambientes permanentes (dev, qa, prod) y worktrees temporales por feature."
---

# Worktree - Gestión de Git Worktrees

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/environments.md` | Environment configuration and worktree paths | Yes | project |
| `knowledge/_inject/git-essentials.md` | Git worktree management and branching patterns | No | framework |

## QUICK REFERENCE

> **Nota estructural**: Este skill usa estructura basada en comandos (no fases)
> porque gestiona operaciones interactivas discretas.

### BLOCKING CONDITIONS
> Si alguna es TRUE, DETENER inmediatamente

**`init`:**
- [ ] No es un repositorio Git
- [ ] Branch main no existe

**`create {nombre}`:**
- [ ] Sistema de worktrees no inicializado
- [ ] Branch con ese nombre ya existe

**`delete {nombre}`:**
- [ ] Worktree es un ambiente (dev/qa/prod)
- [ ] Cambios sin commit (requiere confirmación)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA escribir directamente en el worktree de `prod` — solo lectura
- NUNCA eliminar un worktree sin verificar que no hay cambios sin commit
- NUNCA ejecutar `git reset --hard` en un worktree sin confirmación explícita del usuario

### REQUIRED OUTPUTS

**`init`:**
- [ ] `.worktrees/environments/dev/` existe
- [ ] `.worktrees/environments/qa/` existe
- [ ] `.worktrees/environments/prod/` existe
- [ ] `.worktrees/.meta/config.json` existe

**`create {nombre}`:**
- [ ] `.worktrees/features/{tipo}-{nombre}/` existe
- [ ] `.worktrees/.meta/active-features.json` actualizado

### COMMANDS OVERVIEW
```
init ─────► create {feature} ─────► update {feature} ─────► delete {feature}
  │              │                       │                       │
  └─► list       └─► switch              └─► status              └─► cleanup
                                              │
                                              └─► env sync {env}
```

---

## Overview

Gestiona Git Worktrees para desarrollo aislado de features con ambientes permanentes para dev, qa y prod. Integra GitFlow.

## Comandos

| Comando | Descripción | Uso |
|---------|-------------|-----|
| `init` | Configura estructura inicial | Una vez por proyecto |
| `create {nombre}` | Crea worktree feature/hotfix | Por cada feature |
| `list` | Lista worktrees activos | Consulta |
| `switch {nombre}` | Muestra path del worktree | Navegación |
| `delete {nombre}` | Elimina worktree temporal | Cleanup manual |
| `cleanup` | Limpia huérfanos | Mantenimiento |
| `update {nombre}` | Sincroniza feature con develop | Antes de merge |
| `env sync {env}` | Sincroniza ambiente | dev/qa/prod |
| `status` | Estado completo | Diagnóstico |

---

## COMMAND ROUTER

> **Excepción v2.0 documentada**: Este skill usa COMMAND ROUTER con carga modular por sub-archivos.
> Justificación: entry point ~900 tokens; carga total ~3890 tokens.
> Los sub-archivos se cargan on-demand según el comando invocado.

| Comando | Sub-archivo |
|---------|-------------|
| init, create, list, switch, update, delete, cleanup, env sync, status + IF FAILS | [COMMANDS.md](COMMANDS.md) |
| status (detalle completo), integración, nomenclatura | [REFERENCE.md](REFERENCE.md) |

---

## FINAL CHECKPOINT (por comando)

**Para `init`:**
- [ ] Estructura `.worktrees/` creada
- [ ] Ambientes dev/qa/prod creados con HEAD correcto
- [ ] config.json y promotions.json inicializados
- [ ] `.worktrees/` agregado a .gitignore

**Para `create`:**
- [ ] Worktree creado en `.worktrees/features/`
- [ ] Branch creado con prefijo correcto (feature/ o hotfix/)
- [ ] active-features.json actualizado

**Para `delete`:**
- [ ] Worktree removido
- [ ] Branch eliminado (si se confirmó)
- [ ] active-features.json actualizado

**Para `status`:**
- [ ] Estado de ambientes mostrado
- [ ] Features activos listados
- [ ] Solapamiento de archivos detectado (si aplica)
- [ ] Acciones sugeridas mostradas

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(copiar de CASTLE Assessment)_ |
| Artifacts | _(listar archivos modificados, branch, PR)_ |
| Next Recommended | _(ver Guide Next Step)_ |
| Risks | _(riesgos activos o "None")_ |

---

## Archivos del skill

| Archivo | Contenido |
|---------|-----------|
| `SKILL.md` | Entry point — este archivo (~900t) |
| `COMMANDS.md` | Lógica detallada de los 9 comandos + IF FAILS por comando |
| `REFERENCE.md` | Status detallado, integración, nomenclatura, principios |

## Ver también

- **Reference**: `skills/worktree/REFERENCE.md` (status detallado, integración, nomenclatura, principios)
- **Rules**: `rules/git-worktrees.md`
- **Skill anterior**: `skills/merge/SKILL.md`
- **Skill siguiente**: `skills/promote/SKILL.md`
- **Validación**: `validation/VALIDATION.md`
- **Session template**: `skills/session-management/SKILL.md`
