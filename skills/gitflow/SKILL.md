---
name: gitflow
description: "GitFlow y gestión de worktrees. Usar cuando se necesite: ver estado de branches, crear branches feature/hotfix/release, sincronizar worktrees, verificar estado de ambientes, o gestionar el flujo GitFlow del proyecto."
version: "2.0"
api_version: 1.0.0
---

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/environments.md` | Worktree paths, ports, DB URLs and environment config | Yes | project |
| `knowledge/_inject/git-essentials.md` | GitFlow branching, merge strategies and worktree patterns | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe repositorio git en el directorio actual
- [ ] No se especificó comando o subcomando de gitflow

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA hacer `force push` a `main` o `develop`
- NUNCA hardcodear puertos, URLs o credenciales — usar `{{SLOT}}` convention (`slot-convention.md`)
- NUNCA escribir directamente en el worktree `prod` (`{{PROD_WORKTREE}}`) — solo lectura
- NUNCA eliminar un worktree de ambiente (dev/qa/prod) — son permanentes

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Operación git ejecutada correctamente (branch creado, sync completado, o status reportado)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW

```
Phase 0: Load Context
Phase 1: Status          → /gitflow status
Phase 2: Branch          → /gitflow branch [tipo] [nombre]
Phase 3: Sync            → /gitflow sync
FINAL CHECKPOINT
Execution Summary
Phase N+1: Write Session
Phase N+2: Guide Next Step
```

> **Nota**: Las fases se ejecutan según el comando solicitado. Fase 1, 2 o 3 son mutuamente excluyentes por ejecución — el GATE IN de cada fase determina cuál ejecutar.

---

## CASTLE: N/A (operacional) — [ver capas en `skills/_shared/castle-capas.md`]

---

## GitFlow del Proyecto

```
feature/* ──→ develop ──→ release/* ──→ main
                                          │
hotfix/* ──────────────────────────────→ main + develop
```

### Reglas de merge
- feature/* → develop: squash merge (via PR)
- develop → release/*: branch creation
- release/* → main: merge commit (via PR, CASTLE FORTIFIED)
- hotfix/* → main: merge commit (via PR, CASTLE S+T)
- main → develop: back-merge después de release/hotfix

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` Phase 0

---

## Fase 1: Status (`/gitflow status`)

### GATE IN
- [ ] Fase 0 completada
- [ ] Comando solicitado es `status`

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Branches activos** — Listar branches por fecha de commit:
   ```bash
   git branch -a --sort=-committerdate | head -20
   ```
2. [ ] **Worktrees** — Listar worktrees activos:
   ```bash
   git worktree list
   ```
3. [ ] **Estado por ambiente** — Mostrar commit actual en cada worktree:
   ```
   dev  (develop):     [commit hash] [fecha] [mensaje]
   qa   (origin/dev):  [commit hash] [fecha] [mensaje]
   prod (origin/main): [commit hash] [fecha] [mensaje]
   ```
4. [ ] **Diff entre ambientes** — Calcular commits pendientes:
   ```bash
   git log origin/main..develop --oneline  # pendiente para prod
   ```
5. [ ] **Reporte** — Presentar GitFlow Status Report (ver REFERENCE)

### CHECKPOINT
- [ ] Branches listados con fecha y tipo
- [ ] Estado de worktrees dev/qa/prod reportado
- [ ] Commits pendientes entre ambientes calculados

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Status incompleto
Cause: Repositorio sin remote configurado, o worktrees no inicializados
Recovery:
  [ ] Option A: `git remote -v` para verificar remote; `git fetch --all` para inicializar referencias
  [ ] Option B: Si worktrees no existen, ejecutar `/worktree init` primero
  [ ] Option C: Reportar solo la información disponible con nota de lo faltante

---

## Fase 2: Branch (`/gitflow branch [tipo] [nombre]`)

### GATE IN
- [ ] Fase 0 completada
- [ ] Comando solicitado es `branch`
- [ ] Tipo de branch especificado (`feature`, `hotfix` o `release`)
- [ ] Nombre de branch especificado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Ejecutar según tipo** — Crear branch con el flujo correcto:

   **Feature** (`feature/[nombre]`):
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/[nombre]
   # Opcionalmente crear worktree:
   git worktree add .worktrees/features/[nombre] feature/[nombre]
   ```

   **Hotfix** (`hotfix/[nombre]`):
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/[nombre]
   ```

   **Release** (`release/vX.Y.Z`):
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/v[X.Y.Z]
   ```

2. [ ] **Confirmar creación** — Verificar que el branch existe localmente

### CHECKPOINT
- [ ] Branch creado con nombre y tipo correctos
- [ ] Branch parte del origen correcto (develop para feature/release, main para hotfix)
- [ ] Worktree creado si fue solicitado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Branch no creado
Cause: Branch ya existe, origen desactualizado, o permisos insuficientes
Recovery:
  [ ] Option A: `git branch -a | grep [nombre]` — si existe, hacer checkout en vez de crear
  [ ] Option B: `git pull origin [origen]` para actualizar antes de reintentar
  [ ] Option C: Verificar permisos del repositorio y estado de git (`git status`)

---

## Fase 3: Sync (`/gitflow sync`)

### GATE IN
- [ ] Fase 0 completada
- [ ] Comando solicitado es `sync`
- [ ] Worktrees de ambiente inicializados ({{DEV_WORKTREE}}, {{QA_WORKTREE}}, {{PROD_WORKTREE}})

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Fetch remotes** — Actualizar referencias remotas:
   ```bash
   git fetch --all --prune
   ```
2. [ ] **Sincronizar dev** — Actualizar worktree de desarrollo:
   ```bash
   cd {{DEV_WORKTREE}} && git pull origin develop
   ```
3. [ ] **Sincronizar qa** — Actualizar worktree de QA (detached):
   ```bash
   cd {{QA_WORKTREE}} && git fetch origin && git reset --hard origin/develop
   ```
4. [ ] **Verificar prod** — Confirmar estado del worktree de prod (READONLY):
   ```bash
   cd {{PROD_WORKTREE}} && git fetch origin && git status
   ```
   > NUNCA escribir en prod. Solo verificar estado.

### CHECKPOINT
- [ ] `git fetch --all --prune` completado sin errores
- [ ] Dev worktree actualizado a HEAD de develop
- [ ] QA worktree actualizado a HEAD de origin/develop
- [ ] Prod worktree verificado (sin cambios locales)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Sync fallido en uno o más worktrees
Cause: Conflictos, worktrees no inicializados, o red no disponible
Recovery:
  [ ] Option A: `git worktree list` para verificar que los worktrees existen
  [ ] Option B: Si hay conflictos en dev — resolverlos manualmente antes de reintentar sync
  [ ] Option C: Si no hay red — reportar error y esperar conectividad

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen
- [ ] TODOS los CHECKPOINTS de la fase ejecutada pasaron
- [ ] Sesión registrada

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | N/A (operacional) |
| Artifacts | _(branch creado, sync completado, o status reportado)_ |
| Next Recommended | _(ver Guide Next Step)_ |
| Risks | _(riesgos activos o "None")_ |

---

## Fase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` Phase N+1

---

## Fase N+2: Guide Next Step

| Condición | Próximo Skill |
|-----------|---------------|
| Branch feature creado | `/build` — comenzar implementación |
| Branch hotfix creado | `/fix` — aplicar corrección |
| Branch release creado | `/release` — preparar release |
| Sync completado | `/promote` si hay cambios listos para QA/prod |
| Status revisado | Ninguno — acción informacional |

---

## REFERENCE

### Worktree Strategy

```
{{DEV_WORKTREE}}   → branch: develop (writable)
{{QA_WORKTREE}}    → branch: origin/develop (detached, sync con reset)
{{PROD_WORKTREE}}  → branch: origin/main (READONLY)
```

**Configuración por worktree**: cada worktree de ambiente lee su propio `.env`:
- Valores de puertos, URLs de DB y CORS: ver `.king/knowledge/environments.md`
- Usar slots `{{DEV_PORT}}`, `{{QA_PORT}}`, `{{PROD_PORT}}`, `{{DEV_DB_URL}}`, etc.

### GitFlow Status Report

```markdown
## GitFlow Status

### Branches
| Branch | Tipo | Último commit | Estado |
|--------|------|---------------|--------|
| develop | base | [hash] [msg] | activo |
| main | producción | [hash] [msg] | protegido |
| feature/X | feature | [hash] [msg] | en progreso |

### Worktrees
| Ambiente | Branch | Commit | Uptime |
|----------|--------|--------|--------|
| dev | develop | [hash] | [tiempo] |
| qa | origin/develop | [hash] | [tiempo] |
| prod | origin/main | [hash] | [tiempo] |

### Pendiente de promote
- develop → qa: [N] commits
- qa → prod: [N] commits
```

> **Session tracking**: Skill standalone. Ver convención en `skills/_shared/standalone-convention.md`.
