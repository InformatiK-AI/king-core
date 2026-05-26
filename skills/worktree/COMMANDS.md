# Worktree — Commands (v2.0)

> Lógica detallada de cada comando y su recuperación de errores. Entry point: [SKILL.md](SKILL.md)

---

## init

**Prerrequisitos:** Git repo con branch `main`

**Proceso:**
1. Verificar Git: `git rev-parse --is-inside-work-tree`
2. Crear estructura:
   ```
   .worktrees/
   ├── .meta/
   │   ├── config.json
   │   ├── active-features.json
   │   └── promotions.json
   ├── environments/{dev, qa, prod}
   └── features/
   ```
3. Crear branch develop si no existe
4. Crear worktrees de ambiente:
   - `dev` → branch develop (único dueño del branch)
     `git worktree add .worktrees/environments/dev develop`
   - `qa` → detached HEAD en origin/develop (se sincroniza con reset)
     `git worktree add --detach .worktrees/environments/qa origin/develop`
   - `prod` → detached HEAD en origin/main (readonly, se sincroniza con reset)
     `git worktree add --detach .worktrees/environments/prod origin/main`

   > **Nota**: Solo dev/ tiene un branch real (para poder hacer merges).
   > qa/ y prod/ usan HEAD desacoplado porque se sincronizan via `git reset --hard`
   > y no necesitan branch propio. Esto evita el error `fatal: 'develop' is already
   > checked out at...` que ocurre cuando dos worktrees intentan usar el mismo branch.
5. Guardar config en `.worktrees/.meta/config.json`:
   ```json
   {
     "initialized": true,
     "initializedAt": "2026-01-28T10:00:00Z",
     "mainBranch": "main",
     "developBranch": "develop",
     "environments": {
       "dev": { "branch": "develop", "detached": false, "path": ".worktrees/environments/dev" },
       "qa": { "branch": "develop", "detached": true, "path": ".worktrees/environments/qa" },
       "prod": { "branch": "main", "detached": true, "path": ".worktrees/environments/prod", "readonly": true }
     }
   }
   ```
   > `detached: true` indica worktree con HEAD desacoplado (creado con `--detach`).
   > Solo dev/ tiene `detached: false` para poder ejecutar merges directamente.
6. Inicializar `.worktrees/.meta/promotions.json`:
   ```json
   {
     "promotions": [],
     "lastSync": {
       "dev": null,
       "qa": null,
       "prod": null
     }
   }
   ```
7. Agregar `.worktrees/` a `.gitignore`

### init — IF FAILS
> ❌ What to do when init fails

ERROR: Worktree initialization failed
Cause: Branch `main` does not exist, worktree structure already exists, or git repository not initialized.
Recovery:
  [ ] Option A: If branch `main` does not exist — create it first: `git checkout -b main`, then retry `init`
  [ ] Option B: If `.worktrees/` already exists — run `/worktree cleanup` to remove orphan references, then retry `init`
  [ ] Option C: If `git rev-parse --is-inside-work-tree` fails — ensure you are inside a git repository before running `init`

---

## create {nombre}

**Tipo automático:**
- Contiene la palabra "hotfix" (case insensitive) → `hotfix/{nombre}`
- Nombre coincide con patrón `^\d+-` (empieza con dígitos seguidos de guión, ej: `123-fix-payment`) → `hotfix/{nombre}`
- Todo lo demás → `feature/{nombre}`

**Ejemplos:**
| Input | Resultado | Razón |
|-------|-----------|-------|
| `auth-login` | `feature/auth-login` | No empieza con número ni contiene "hotfix" |
| `hotfix-payment` | `hotfix/hotfix-payment` | Contiene "hotfix" |
| `123-fix-crash` | `hotfix/123-fix-crash` | Empieza con dígitos + guión |
| `123feature` | `feature/123feature` | Empieza con dígitos pero sin guión |
| `add-v2-api` | `feature/add-v2-api` | Número en medio, no al inicio |

> **Nota**: Git worktrees comparten el `.git` del repo principal, por lo que el espacio adicional es mínimo (solo los archivos de trabajo). No se requiere pre-check de espacio en disco para la mayoría de proyectos.

**Proceso:**
1. Verificar que branch no existe
2. Actualizar referencia de develop: `git fetch origin develop`
3. Crear branch y worktree en operación atómica:
   ```bash
   git worktree add -b {tipo}/{nombre} .worktrees/features/{tipo}-{nombre} origin/develop
   ```
   > **Importante**: Esta operación atómica NO cambia el HEAD del repo principal, evitando race conditions cuando se crean múltiples features simultáneamente.
4. Registrar en `active-features.json`

**Output:**
```
Worktree creado: {tipo}-{nombre}
Directorio: .worktrees/features/{tipo}-{nombre}
```

### create — IF FAILS
> ❌ What to do when create fails

ERROR: Worktree feature creation failed
Cause: Branch already exists, or branch is already checked out in another worktree.
Recovery:
  [ ] Option A: If branch already exists — change the feature name or run `/worktree delete {nombre}` if the existing worktree is orphaned
  [ ] Option B: If `fatal: ... is already checked out` — use `/worktree list` to locate which worktree is using the branch; switch to it or delete it first
  [ ] Option C: If `git fetch origin develop` fails — check network connectivity and retry; do not create the worktree without fetching latest develop

---

## list

Ejecuta `git worktree list` y formatea:

```
AMBIENTES (permanentes):
   dev  → develop  (branch)    .worktrees/environments/dev
   qa   → develop  (detached)  .worktrees/environments/qa
   prod → main     (detached)  .worktrees/environments/prod (readonly)

FEATURES (temporales):
   feature-auth → feature/auth  .worktrees/features/feature-auth
```

---

## switch {nombre}

Resuelve path y muestra instrucción:
- Ambiente: `.worktrees/environments/{nombre}`
- Feature: `.worktrees/features/feature-{nombre}` o `hotfix-{nombre}`

```
cd .worktrees/features/{tipo}-{nombre}
```

---

## update {nombre}

**Propósito:** Sincroniza un worktree de feature con los últimos cambios de develop.

**Proceso:**
1. Verificar que el worktree existe y es un feature (no ambiente)
2. Verificar que no hay operaciones git pendientes en el worktree
3. Sincronizar con develop:
   ```bash
   cd .worktrees/features/{tipo}-{nombre}
   git fetch origin develop
   git merge origin/develop --no-ff -m "chore: sync with develop"
   ```
4. Si hay conflictos → Mostrar archivos en conflicto y pedir resolución manual
5. Informar resultado

**Cuándo usar:**
- Antes de `/merge` (recomendado)
- Cuando otro feature se mergeó a develop y necesitas sus cambios
- Cuando `/worktree status` muestra divergencia con develop

### update — IF FAILS
> ❌ What to do when update fails

ERROR: Feature worktree sync with develop failed — merge conflict
Cause: Changes in develop conflict with uncommitted or committed changes in the feature branch.
Recovery:
  [ ] Option A: Resolve conflicts manually in `.worktrees/features/{tipo}-{nombre}`, then run `git add <files> && git merge --continue`
  [ ] Option B: If conflicts are too complex, abort the merge with `git merge --abort` and ask user for guidance on resolution strategy
  [ ] Option C: If the feature branch is significantly behind develop, consider rebasing instead: `git rebase origin/develop` — warn user that this rewrites history

---

## delete {nombre}

**Restricción:** No permite eliminar ambientes (dev/qa/prod)

**Proceso:**
1. Verificar cambios sin commit → confirmar si existen
2. `git worktree remove .worktrees/features/{tipo}-{nombre} --force`
3. Opcional: eliminar branch
4. Actualizar `active-features.json`

---

## cleanup

1. `git worktree prune --dry-run` → mostrar huérfanos
2. Confirmar limpieza
3. `git worktree prune`
4. Sincronizar `active-features.json`

---

## env sync {env}

**Válidos:** dev, qa, prod

**Proceso:**
1. Verificar cambios locales → confirmar descarte
2. `git fetch origin && git reset --hard origin/{branch}`
3. Post-sync: `npm install` o `pip install` si aplica

**prod:** Sincroniza pero recuerda que es readonly.

### env sync — IF FAILS
> ❌ What to do when env sync fails

ERROR: Environment worktree sync failed — local changes or network error
Cause: Local uncommitted changes exist, or `git fetch origin` failed due to network.
Recovery:
  [ ] Option A: If local changes exist — stash them (`git stash`) or explicitly discard (`git reset --hard`) before syncing; confirm with user before discarding
  [ ] Option B: If `git fetch origin` fails — check network connectivity and remote configuration (`git remote -v`), then retry
  [ ] Option C: If `prod` worktree has unexpected local changes — investigate origin (should be readonly); discard with `git reset --hard origin/main` after user confirmation

---

## status

> Comando extenso con cálculos de sincronización, solapamiento y sugerencias.
> Ver detalle completo: [REFERENCE.md](REFERENCE.md)

Muestra estado completo del sistema de worktrees: ambientes, features activos, solapamiento de archivos y acciones sugeridas.

---

## Cualquier comando — IF FAILS
> ❌ What to do when any worktree command fails with repository corruption

ERROR: Git worktree references corrupted — command fails with unexpected git errors
Cause: Orphaned worktree references in `.git/worktrees/`, or inconsistent `active-features.json`.
Recovery:
  [ ] Option A: Run `git worktree prune` to clean up stale worktree references, then retry the command
  [ ] Option B: If `active-features.json` is out of sync, run `/worktree list` to see actual state and manually update the JSON file
  [ ] Option C: If corruption persists, run `git worktree list --porcelain` to see all registered worktrees and remove specific orphans with `git worktree remove --force {path}`
