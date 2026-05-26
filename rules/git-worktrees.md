---
name: git-worktrees
description: "Reglas para el uso de git worktrees en desarrollo aislado de features"
---

# Git Worktrees — Reglas de Uso

## Aplica a
Proyectos que usan el sistema de git worktrees de King Framework para aislamiento de features en ambientes dev/qa/prod.

## Reglas

### R1: Estructura de Directorios Obligatoria
El sistema debe seguir esta estructura exacta:
```
.worktrees/
├── .meta/
│   ├── config.json
│   ├── active-features.json
│   └── promotions.json
├── environments/
│   ├── dev/
│   ├── qa/
│   └── prod/
└── features/
```
- `dev/` → branch real (develop) — único ambiente que puede hacer merges
- `qa/` → HEAD desacoplado (detached) en origin/develop
- `prod/` → HEAD desacoplado (detached) en origin/main (readonly)

### R2: Tipos de Worktree
| Tipo | Propósito | Lifecycle |
|------|-----------|-----------|
| Ambiente (dev/qa/prod) | Permanente, refleja estado del branch | No se elimina |
| Feature | Temporal, trabajo aislado por issue | Se elimina post-merge |

### R3: Nomenclatura de Features
- Contiene "hotfix" o empieza con dígitos + guión → `hotfix/{nombre}`
- Todo lo demás → `feature/{nombre}`

Ejemplos:
| Input | Resultado |
|-------|-----------|
| `auth-login` | `feature/auth-login` |
| `hotfix-payment` | `hotfix/hotfix-payment` |
| `123-fix-crash` | `hotfix/123-fix-crash` |

### R4: Creación de Worktrees (Operación Atómica)
```bash
# CORRECTO: crear branch y worktree en una operación
git worktree add -b feature/{nombre} .worktrees/features/feature-{nombre} origin/develop

# INCORRECTO: crear branch separado y luego el worktree
git branch feature/{nombre}
git worktree add .worktrees/features/feature-{nombre} feature/{nombre}
```

### R5: Sincronización de Ambientes
```bash
# Sincronizar ambiente con su branch de origen
git fetch origin && git reset --hard origin/{branch}
```
- **Nunca** usar `git merge` en qa/ o prod/ (son detached HEAD)
- **Siempre** usar `reset --hard` para sincronizar ambientes

### R6: Registro Obligatorio
Cada worktree de feature debe registrarse en `.worktrees/.meta/active-features.json` al crear y desregistrarse al eliminar.

### R7: Ignorar el directorio
`.worktrees/` debe estar en `.gitignore`. Los worktrees son entornos locales, no se commitean.

## Ejemplos

### Correcto
```bash
# Crear feature con operación atómica
git worktree add -b feature/user-auth .worktrees/features/feature-user-auth origin/develop

# Sincronizar ambiente qa con develop
cd .worktrees/environments/qa
git fetch origin && git reset --hard origin/develop
```

### Incorrecto
```bash
# No usar git checkout para cambiar entre worktrees
cd /proyecto && git checkout feature/user-auth  # MAL: trabaja en repo principal

# No usar git merge en ambientes qa/prod
cd .worktrees/environments/qa && git merge develop  # MAL: detached HEAD
```

## Razón
Los git worktrees permiten trabajar en múltiples features simultáneamente sin cambiar el branch del repo principal. La estructura dev/qa/prod garantiza que cada ambiente refleja exactamente el estado correcto del pipeline GitFlow. El uso de detached HEAD en qa/ y prod/ previene el error `fatal: 'develop' is already checked out`.

## Cuando romper las reglas
- **R7 (gitignore)**: En monorepos donde los worktrees deben compartirse entre desarrolladores (raro)
- **R5 (reset --hard)**: Si qa/ necesita cherry-pick selectivo de commits (usar con precaución y documentar en CHANGELOG)
