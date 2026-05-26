# GitFlow Strategy — King

## Flujo de branches

```
feature/* ──→ develop ──→ release/* ──→ main
                                          │
hotfix/* ──────────────────────────────→ main + develop
```

## Reglas de branches

### `main` (producción)
- Branch protegido — merge solo via PR aprobado
- Solo recibe merges de `release/*` y `hotfix/*`
- Cada merge genera un tag de versión
- Worktree: `.worktrees/environments/prod/` (READONLY)

### `develop` (desarrollo activo)
- Branch base para features
- Recibe merges de `feature/*`
- Recibe back-merges de `main` después de releases/hotfixes
- Worktree: `.worktrees/environments/dev/`

### `feature/*` (features)
- Se crean desde `develop`
- Naming: `feature/[issue-number]-descripcion-corta`
- Merge a develop via PR con squash
- Se eliminan después de merge
- Worktree opcional: `.worktrees/features/[nombre]/`

### `release/*` (releases)
- Se crean desde `develop`
- Naming: `release/vX.Y.Z`
- Requieren CASTLE FORTIFIED
- Merge a `main` con merge commit (preservar historia)
- Back-merge a `develop` después de merge a main

### `hotfix/*` (fixes urgentes)
- Se crean desde `main`
- Naming: `hotfix/[issue-number]-descripcion`
- Merge a `main` via PR
- Cherry-pick o merge a `develop`

## Convenciones de merge

| Tipo | Método | Destino |
|------|--------|---------|
| feature → develop | Squash merge | develop |
| release → main | Merge commit | main |
| hotfix → main | Merge commit | main |
| main → develop | Merge (back-merge) | develop |

## Validación GitFlow — Targets de PR (BLOQUEANTE)

**NUNCA** crear un PR con un target incorrecto. Validar ANTES de `gh pr create`:

| Branch origen | Target CORRECTO | Target PROHIBIDO |
|---------------|----------------|-----------------|
| `feature/*` | `develop` | `master`/`main` ← NUNCA |
| `hotfix/*` | `master`/`main` | — |
| `release/*` | `master`/`main` | — |
| `develop` | `release/*` (indirecto) | `master` directamente |

**Por qué importa:** Un merge directo de feature a master crea SHAs divergentes con develop, causando conflictos innecesarios en todo el historial compartido. Siempre respetar: `feature → develop → release → master`.

## Cierre de Issues en GitFlow

> **Limitación de GitHub**: Los keywords `Closes #N`, `Fixes #N`, `Resolves #N` solo auto-cierran issues al mergear al branch **default** del repositorio (`master`).

En GitFlow, features mergean a `develop` (no a `master`). Esto significa:
- Un PR de `feature/login` a `develop` con `Closes #5` **NO cerrará** el issue #5
- El issue permanecerá abierto hasta que un `release/*` se mergee a `master`

**Solución del framework**: El skill `/merge` incluye **Fase 3.5: Issue Closure** que:
1. Parsea el body del PR buscando `Closes #N`, `Fixes #N`, `Resolves #N`
2. Ejecuta `gh issue close N` explícitamente para cada issue referenciado
3. Agrega comentario al issue con link al PR

**Recomendación**: Mantener `Closes #N` en los PR bodies — sigue siendo útil como documentación y funciona para merges a master (releases/hotfixes).

## Worktree management

```
.worktrees/
├── environments/
│   ├── dev/    → develop (writable)
│   ├── qa/     → origin/develop (promote target)
│   └── prod/   → origin/main (READONLY)
└── features/
    └── feature-X/ → feature/X (efímero)
```
