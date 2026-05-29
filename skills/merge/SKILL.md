---
name: merge
description: "Workflow de merge con quality gates. Usar cuando se necesite: hacer merge de un branch, integrar cambios a develop, mergear un PR, o combinar branches con verificación de calidad."
version: 2.0
api_version: 1.0.0
---

# Merge — Integración con Quality Gates

Workflow para mergear branches con verificaciones de calidad pre y post merge.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/conventions.md` | Code and commit conventions to verify in the merge | Yes | project |
| `knowledge/_inject/git-essentials.md` | Git branching, merge strategies and conflict resolution patterns | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] QA no aprobado (veredicto REJECTED o CASTLE BREACHED)
- [ ] Existen conflictos de merge sin resolver
- [ ] Source o target branch detrás del remote (sync validation fallida)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA hacer merge a `develop` o `main` con conflictos sin resolver manualmente
- NUNCA proceder si hay tests fallando en la rama de origen

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Feature branch mergeada a `develop`
- [ ] PR cerrado/merged en GitHub (si aplica)
- [ ] Session document creado (via session-management Phase N+1)

---


## Agentes involucrados
- **@developer** → Ejecuta merge y verifica código
- **@qa** → Verifica tests post-merge

## CASTLE: _·A·_·T·_·_ — [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

> **Pre-checks obligatorios** (antes de Fase 1):
> 1. Ejecutar `validation/pre-checks/git.md` (checks 1-5)
> 2. Ejecutar `validation/pre-checks/merge.md` (checks 1-5) — reemplaza `git.md` check #6
>
> Si cualquier check retorna **ERROR**, DETENER y mostrar remediación al usuario.
> Si hay WARNs, mostrar y pedir confirmación antes de continuar.

### GATE IN — Pre-conditions para ejecutar /merge
> Si alguna condición no se cumple, DETENER y reportar al usuario.

- [ ] QA aprobado para el feature branch (evidencia: `/qa` CASTLE FORTIFIED o CONDITIONAL)
- [ ] No hay conflictos de merge no resueltos entre el feature branch y el target branch
- [ ] El feature branch está sincronizado con el upstream (no divergido)
- [ ] El target branch (develop/main) existe y es accesible

### Fase 1: Pre-merge Checks

#### MUST DO
> ⚠️ All actions are MANDATORY

**1a. Validación GitFlow (BLOQUEANTE)**
Verificar que el merge respeta el flujo GitFlow:
```bash
# Detectar tipo de branch y target correcto
BRANCH=$(git branch --show-current)
# feature/* → develop (squash)
# hotfix/* → master (merge commit) + back-merge a develop
# release/* → master (merge commit)
# develop → solo via release/*
```

| Branch origen | Target válido | Método |
|---------------|--------------|--------|
| `feature/*` | `develop` | Squash merge (PR) |
| `hotfix/*` | `master` + `develop` | Merge commit (PR) |
| `release/*` | `master` | Merge commit (PR) |

Si el target no coincide → **BLOQUEAR** y advertir al usuario.
Si existe un PR, verificar que `baseRefName` coincide con el target esperado:
```bash
gh pr view [PR#] --json baseRefName | jq -r '.baseRefName'
# Si baseRefName != target esperado → ADVERTIR
```

**1b. Verificar conflictos:**
```bash
git merge --no-commit --no-ff [branch] 2>&1
git merge --abort 2>/dev/null
```

**1c. Remote Sync Validation (BLOQUEANTE)**

> Ejecutada vía `validation/pre-checks/merge.md` (checks 2-3). El resultado ya está disponible
> del pre-check obligatorio ejecutado antes de Fase 1. Documentar en el reporte.

Resumen de los checks ejecutados:

```bash
# Fetch único para ambos branches
git fetch origin $SOURCE_BRANCH $TARGET

# Source sincronizado con remote
BEHIND=$(git rev-list HEAD..origin/$SOURCE_BRANCH --count)
# Si BEHIND>0 → ⛔ BLOQUEAR con SOURCE_BEHIND_REMOTE

# Target sincronizado con remote
TARGET_BEHIND=$(git rev-list $TARGET..origin/$TARGET --count)
# Si TARGET_BEHIND>0 → ⛔ BLOQUEAR con TARGET_BEHIND_REMOTE
```

Si source **o** target están detrás del remote, mostrar mensaje de bloqueo:
```
⛔ MERGE BLOQUEADO: Sincronización requerida

  Source ($SOURCE_BRANCH): $BEHIND commits detrás de origin/$SOURCE_BRANCH
  Target ($TARGET): $TARGET_BEHIND commits detrás de origin/$TARGET

  Solución:
    git pull origin $SOURCE_BRANCH          # Sincronizar source

    git checkout $TARGET                    # Sincronizar target
    git pull origin $TARGET
    git checkout $SOURCE_BRANCH             # Volver al source

    Con worktrees:
    cd .worktrees/environments/dev && git pull origin $TARGET

  Después de sincronizar, reintenta: /merge
```

**1d.** Verificar que todos los tests pasan en el branch

**1e.** Verificar que el PR (si existe) tiene aprobaciones y `baseRefName` correcto

#### CHECKPOINT
- [ ] Pre-merge checks passed — GitFlow validated, no conflicts, branches synchronized, tests passing

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Pre-merge check failed — merge blocked by one or more conditions
Cause: GitFlow target mismatch, unresolved merge conflicts, source or target branch behind remote, or tests failing on the branch.
Recovery:
  [ ] Option A: If sync issue — run `git pull origin [branch]` for whichever branch is behind remote, then retry pre-checks
  [ ] Option B: If merge conflicts detected — resolve conflicts in the listed files, run tests to confirm resolution, then retry
  [ ] Option C: If GitFlow target is wrong — do not proceed; ask user to confirm the correct target branch, update the PR base if needed (`gh pr edit [PR#] --base [correct-target]`), then retry

### Fase 2: Architecture Check (via @architect)

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar dependency direction post-merge
2. [ ] Verificar que no hay conflictos de patrones
3. [ ] Verificar que los módulos/archivos mantienen su estructura

#### CHECKPOINT
- [ ] Dependency direction and pattern consistency verified post-merge

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Architecture violations detected post-merge — dependency direction broken
Cause: Merging the feature branch introduced imports or dependencies that violate the established layer hierarchy.
Recovery:
  [ ] Option A: Identify the specific file and import causing the violation — fix the dependency direction before proceeding with merge execution
  [ ] Option B: If the violation is minor and intentional, create an ADR documenting the exception and get user approval before continuing
  [ ] Option C: If the violation cannot be fixed without significant rework, abort the merge and return to @developer with the architectural finding

### Fase 3: Merge Execution

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Para branches normales:
   ```bash
   git checkout develop
   git merge --no-ff [branch] -m "merge: integrar [branch] a develop"
   ```
2. [ ] Para branches protegidos (main):
   - **REQUIERE confirmación del usuario**
   - Mostrar diff completo antes de proceder
3. [ ] Para PRs en GitHub:
   ```bash
   gh pr merge [PR#] --squash  # para features
   gh pr merge [PR#] --merge   # para releases
   ```

#### CHECKPOINT
- [ ] Merge executed without conflicts — branch integrated into target

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Merge execution failed — git operation did not complete
Cause: Unexpected conflicts emerged during merge, protected branch rules blocked the operation, or `gh pr merge` failed due to auth or PR status.
Recovery:
  [ ] Option A: Run `git status` to see conflict state — if conflicts, resolve each file, `git add` resolved files, then `git merge --continue`
  [ ] Option B: If `gh pr merge` failed, check PR status (`gh pr view [PR#]`) — ensure PR has required approvals and all checks pass, then retry
  [ ] Option C: If branch protection rules block the merge, do not bypass them — ask user to approve the PR through GitHub UI, then re-run post-merge verification steps manually

### Fase 3.5: Issue Closure (GitFlow + Local)

> **Contexto GitFlow**: GitHub solo auto-cierra issues con `Closes #N` al mergear al branch **default** (`master`). En GitFlow, features mergean a `develop`, por lo que los issues referenciados NO se cierran automáticamente. Este paso lo compensa.

**Solo ejecutar si el target es `develop`** (features). Para merges a `master` (releases, hotfixes), GitHub maneja el cierre automáticamente.

#### MUST DO
> ⚠️ All actions are MANDATORY

**MODO GITHUB:**
1. [ ] Detectar issues referenciados en el PR:
   ```bash
   gh pr view [PR#] --json body -q '.body' | grep -oiE '(closes|fixes|resolves)\s+#[0-9]+' | grep -oE '[0-9]+' | sort -u
   ```
2. [ ] Para cada issue detectado:
   ```bash
   gh issue close N --comment "Cerrado al mergear PR #[PR#] a develop (squash merge)."
   ```
3. [ ] Si no se detectan issues: documentar "Sin issues referenciados en el PR" en el reporte.

**MODO LOCAL (si existen `.king/issues/`):**
1. [ ] Detectar STORY-NNN referenciadas en commits o PR body
2. [ ] Para cada STORY detectada:
   - Actualizar `Status:` a `closed` en `.king/issues/STORY-NNN.md`
   - Actualizar la columna Status en `.king/issues/INDEX.md`
   - Si todas las Stories de un Epic están cerradas, actualizar el Epic Status a `closed`
3. [ ] Si no se detectan issues locales: documentar "Sin issues locales referenciados" en el reporte.

#### CHECKPOINT
- [ ] Related issues closed (GitHub or local) or documented as not applicable

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Issue closure failed — issues referenced in PR not closed
Cause: `gh issue close` command failed, or STORY-NNN file could not be updated (permission or path error).
Recovery:
  [ ] Option A: Retry `gh issue close N --comment "[message]"` individually for each failing issue — verify `gh auth status` first
  [ ] Option B: If local STORY-NNN.md cannot be updated, check file permissions and path — update manually if needed
  [ ] Option C: If no issues were detected but the PR body contains references, parse the body manually and close them — document any issues that could not be closed in the merge report

### Fase 4: Post-merge Verification

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar que el build funciona:
   ```bash
   cd [project-root] && npm run build 2>&1
   ```
2. [ ] Verificar sintaxis:
   ```bash
   [comando de verificación del proyecto - ver CLAUDE.md]
   ```
3. [ ] Verificar que no hay regresiones
4. [ ] Si hay conflictos resueltos: verificar que la resolución es correcta

#### CHECKPOINT
- [ ] Post-merge build and syntax verification passed — no regressions

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Post-merge verification failed — build broken or regressions detected
Cause: Merge introduced an integration conflict between previously separate changes that was not visible in the pre-merge checks.
Recovery:
  [ ] Option A: Show build error output — identify whether the failure is in integration code (imports, API calls between modules) or in individual unit logic
  [ ] Option B: If regression in tests, identify which tests fail on the merged branch but passed on the feature branch — fix the integration issue
  [ ] Option C: If build cannot be fixed quickly, revert the merge (`git revert -m 1 HEAD`) to restore the target branch to a working state, then investigate and fix on the feature branch before re-attempting

### Fase 5: Report

#### MUST DO
> ⚠️ All actions are MANDATORY

```
## Merge Report

### Branch: [branch] → [target]
### Método: [merge|squash|rebase]

### Pre-merge
- Remote Sync: [SYNCED|BEHIND source N|BEHIND target N|OFFLINE]
- Conflictos: [NINGUNO|RESUELTOS]
- Tests: [PASS|FAIL]
- PR status: [APPROVED|PENDING]

### Post-merge
- Build: [OK|FAIL]
- Sintaxis: [OK|FAIL]
- Regresiones: [NINGUNA|LISTA]

### Issues Cerrados (GitFlow)
| Issue | Titulo | Estado |
|-------|--------|--------|
| #N | [titulo] | CERRADO / N/A (target=master, auto-cierre) |

### Resultado: [EXITOSO|FALLIDO]
```

#### CHECKPOINT
- [ ] Merge report generated — pre-merge, merge, post-merge and issue closure documented

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Merge report not completed — required sections missing
Cause: One or more report sections (Remote Sync status, conflict resolution, build result, issue closure) could not be assembled.
Recovery:
  [ ] Option A: Reconstruct missing sections from what was executed in this session — git log, build output, and gh issue list will provide the data
  [ ] Option B: If the merge was successful but the report is incomplete, output a partial report with Status: PARTIAL — the merge result itself is what matters most
  [ ] Option C: Never skip the report — even a one-line summary ("Merge successful, report incomplete due to [reason]") is required

---

## FINAL CHECKPOINT

> Verificar TODOS los items antes de reportar el merge como exitoso.

- [ ] Merge ejecutado sin conflictos
- [ ] Post-merge verification pasada (tests, build si aplica)
- [ ] Reporte de merge generado
- [ ] Issues relacionados cerrados (si aplica)
- [ ] Branch feature eliminado o marcado para eliminación (si aplica)

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

### Fase 6: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 7: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para merge:
| Condición | Próximo Skill |
|-----------|---------------|
| Merge exitoso | `/promote` (o acumular más features antes de promover) |

## Templates

- **PR Description**: `templates/pr-template.md` — Formato estándar para describir el PR en GitHub
