---
name: release
description: "Release GitFlow completo. Usar cuando se necesite: crear un release, publicar una versión, hacer release vX.Y.Z, certificar y publicar una versión del proyecto."
version: 2.0
---

# Release — GitFlow Release Completo

Workflow completo para crear un release certificado del proyecto.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/conventions.md` | Versioning conventions and release naming standards | Yes | project |
| `knowledge/_inject/git-essentials.md` | Tagging, branching and release branch patterns | No | framework |
| `knowledge/_inject/observability-essentials.md` | Post-release health check and smoke test patterns | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] Promote a producción no completado
- [ ] CASTLE no es FORTIFIED (6 capas) para el release

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA crear un release sin tag de versión semántica (semver)
- NUNCA publicar a `prod` sin que el GitHub Release esté creado y documentado
- NUNCA omitir los smoke tests post-deploy

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Tag de versión creado en git
- [ ] GitHub Release publicado con release notes
- [ ] CHANGELOG.md actualizado
- [ ] Session document creado (via session-management Phase N+1)

---


## Agentes involucrados
- Todos los agentes (certificación completa)

## CASTLE: C·A·S·T·L·E — FORTIFIED [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### GATE IN — Pre-conditions para ejecutar /release
> Si alguna condición no se cumple, DETENER y reportar al usuario.

- [ ] Promote a producción (o ambiente target) completado exitosamente
- [ ] CASTLE assessment: FORTIFIED requerido (no lanzar con CONDITIONAL o BREACHED)
- [ ] Versión semántica definida y sin conflictos con tags existentes
- [ ] CHANGELOG actualizado con todos los cambios del release
- [ ] Back-merge plan definido (develop ← master) post-release

### Fase 1: Pre-release Verification

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar que develop está estable:
   ```bash
   cd [project-root] && npm run build 2>&1
   [comando de verificación del proyecto - ver CLAUDE.md]
   ```
2. [ ] Verificar que todos los PRs planeados están mergeados
3. [ ] Verificar que no hay issues bloqueantes abiertos

#### CHECKPOINT
- [ ] develop branch stable — build passes and no blocking issues open

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Pre-release verification failed — develop is not stable
Cause: Build fails on develop, planned PRs are not merged, or blocking issues remain open.
Recovery:
  [ ] Option A: If build fails — fix the failing build on develop (do not create release branch from a broken state), then retry verification
  [ ] Option B: If PRs are not merged — merge the pending PRs through `/merge`, then retry this verification step
  [ ] Option C: If blocking issues remain open — resolve or explicitly defer them with user approval before proceeding; document deferred issues in the release report

### Fase 2: Branch Creation

#### MUST DO
> ⚠️ All actions are MANDATORY

```bash
git checkout develop
git pull origin develop
git checkout -b release/v[X.Y.Z]
```

#### CHECKPOINT
- [ ] release/v[X.Y.Z] branch created from latest develop

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Release branch creation failed
Cause: Uncommitted changes on develop, tag v[X.Y.Z] already exists, or git operation failed.
Recovery:
  [ ] Option A: Run `git status` — if uncommitted changes exist on develop, commit or stash them before creating the release branch
  [ ] Option B: If the branch name conflicts with an existing tag, verify the version number — increment the patch/minor version if the tag was already published
  [ ] Option C: If git operation fails, show `git status` and `git log --oneline -5` output — resolve any repository state issues before retrying branch creation

### Fase 3: CASTLE Certification

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar CASTLE completo (6 capas)
2. [ ] **FORTIFIED es OBLIGATORIO para release**
3. [ ] Si CONDITIONAL o BREACHED: resolver antes de continuar
4. [ ] Documentar resultado de cada capa

#### CHECKPOINT
- [ ] CASTLE Assessment = FORTIFIED (all 6 layers passing)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: CASTLE Certification failed — FORTIFIED not achieved for release
Cause: One or more CASTLE layers (C·A·S·T·L·E) have findings that prevent FORTIFIED status.
Recovery:
  [ ] Option A: Review each non-FORTIFIED layer's findings — fix the highest severity issue in each layer, then re-run CASTLE for just that layer
  [ ] Option B: If CONDITIONAL (not BREACHED), evaluate whether the conditional finding can be accepted for this release — get explicit user approval and document the exception in the release report
  [ ] Option C: If BREACHED, do not proceed — return to development cycle, fix the BREACHED findings via `/fix` or `/build`, then repeat the full CASTLE certification on the release branch

### Fase 4: Version Bump

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Actualizar version en package.json (root):
   ```json
   { "version": "X.Y.Z" }
   ```
2. [ ] Actualizar en client/package.json y server/package.json si existen
3. [ ] Commit:
   ```bash
   git commit -am "chore(release): bump version to vX.Y.Z"
   ```

#### CHECKPOINT
- [ ] Version bumped in all package.json files and committed

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Version bump commit failed — package.json not updated or commit rejected
Cause: package.json has a syntax error after edit, commit hook rejected the message, or file is not tracked by git.
Recovery:
  [ ] Option A: Verify the JSON syntax in each package.json — run `cat package.json | python3 -m json.tool` to detect syntax errors, fix them, then retry the commit
  [ ] Option B: If commit hook rejected the message, use the exact format `chore(release): bump version to vX.Y.Z` and retry
  [ ] Option C: If client/ or server/package.json do not exist, document "Single package.json project" and proceed with only the root bump

### Fase 5: Changelog

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Generar CHANGELOG desde conventional commits:
   ```bash
   git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD
   ```
2. [ ] Categorizar por tipo: Features, Fixes, Refactors, Breaking Changes
3. [ ] Escribir/actualizar CHANGELOG.md

#### CHECKPOINT
- [ ] CHANGELOG.md updated with categorized changes for this release

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Changelog could not be generated or written
Cause: No conventional commits found in the range, CHANGELOG.md is write-protected, or the git log command failed.
Recovery:
  [ ] Option A: If git log returns no commits, verify the tag range is correct — use `git log --oneline -20` to see recent commits and extract changes manually
  [ ] Option B: If CHANGELOG.md cannot be written, check file permissions — create it if it does not exist (`touch CHANGELOG.md`) and retry
  [ ] Option C: If commits are not in conventional format, categorize them manually by reading commit messages — do not skip the changelog for a release

### Fase 6: Build Verification

#### MUST DO
> ⚠️ All actions are MANDATORY

```bash
cd [project-root]
npm run build
# Verificar que client/dist/ se generó correctamente
ls -la client/dist/
```

#### CHECKPOINT
- [ ] Build successful on release branch — client/dist/ generated correctly

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Build failed on release branch
Cause: Release branch has a build error introduced by the version bump, changelog update, or an undetected integration issue.
Recovery:
  [ ] Option A: Show the last 20 lines of the build error — fix the specific error on the release branch and re-run the build
  [ ] Option B: If build error was present on develop before branching (regression), fix it on develop first, then cherry-pick or merge the fix to the release branch
  [ ] Option C: Do not proceed to PR creation with a failing build — a release with a broken build is not a valid release

### Fase 7: PR to main

#### MUST DO
> ⚠️ All actions are MANDATORY

```bash
gh pr create --title "release: v[X.Y.Z]" \
  --body "## Release v[X.Y.Z]

### CASTLE Certification: FORTIFIED
[Detalle por capa]

### Changelog
[Lista de cambios]

### Checklist
- [ ] Version bumped
- [ ] CASTLE FORTIFIED
- [ ] Build successful
- [ ] Changelog updated"
```

#### CHECKPOINT
- [ ] PR to main created with CASTLE certification and changelog in body

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: PR to main creation failed
Cause: `gh` CLI not authenticated, main branch protection rules prevent PR from non-release branches, or PR already exists.
Recovery:
  [ ] Option A: Run `gh auth status` — if not authenticated, run `gh auth login` and retry PR creation
  [ ] Option B: If a PR already exists for this version, run `gh pr view` to find it and update its body with the current CASTLE certification instead of creating a duplicate
  [ ] Option C: If branch protection rules prevent the operation, ask user to create the PR manually via GitHub UI using the exact PR body template — document the PR number in the release report

### Fase 8: Merge to main

#### MUST DO
> ⚠️ All actions are MANDATORY

- **REQUIERE confirmación del usuario** (branch protegido)
- Usar merge commit (no squash) para preservar historia:
  ```bash
  gh pr merge [PR#] --merge
  ```

#### CHECKPOINT
- [ ] Release branch merged to main — PR merged with merge commit

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Merge to main failed — PR merge blocked or rejected
Cause: User did not confirm, required PR checks did not pass, or branch protection rules require additional approvals.
Recovery:
  [ ] Option A: If user did not confirm — wait for explicit confirmation before retrying; never merge to main without user consent
  [ ] Option B: If required checks failed — identify which checks failed in the PR, fix the issues on the release branch, push the fix, and wait for checks to pass before retrying merge
  [ ] Option C: If additional approvals are required by branch protection — ask user to get the required approvals through GitHub UI, then retry `gh pr merge [PR#] --merge`

### Fase 9: Tag

#### MUST DO
> ⚠️ All actions are MANDATORY

```bash
git checkout main
git pull origin main
git tag -a v[X.Y.Z] -m "Release v[X.Y.Z]"
git push origin v[X.Y.Z]
```

#### CHECKPOINT
- [ ] Annotated tag v[X.Y.Z] created and pushed to remote

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Git tag creation or push failed
Cause: Tag already exists, push rejected due to auth, or main branch not fully synced before tagging.
Recovery:
  [ ] Option A: If tag already exists — verify the version with `git tag -l` — if the existing tag points to the wrong commit, delete it (`git tag -d vX.Y.Z` and `git push origin :refs/tags/vX.Y.Z`) and recreate on the correct commit
  [ ] Option B: If push is rejected due to authentication — run `gh auth login` or verify SSH keys, then retry `git push origin v[X.Y.Z]`
  [ ] Option C: If main is not synced — run `git pull origin main` before tagging and retry

### Fase 10: GitHub Release

#### MUST DO
> ⚠️ All actions are MANDATORY

```bash
gh release create v[X.Y.Z] --title "v[X.Y.Z]" --notes "[release notes]"
```

#### CHECKPOINT
- [ ] GitHub Release published at v[X.Y.Z] with release notes

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: GitHub Release creation failed
Cause: Tag not pushed yet, `gh` not authenticated, or a release for this tag already exists.
Recovery:
  [ ] Option A: Verify the tag exists on remote (`git ls-remote --tags origin`) — if not pushed, push it first with `git push origin v[X.Y.Z]`, then retry release creation
  [ ] Option B: If a draft release already exists for this tag, edit it with `gh release edit v[X.Y.Z] --notes "[release notes]"` and publish it
  [ ] Option C: If `gh` is not available, ask user to create the GitHub Release manually via the GitHub UI using the generated release notes from Fase 5

### Fase 11: Back-merge

#### MUST DO
> ⚠️ All actions are MANDATORY

```bash
git checkout develop
git merge main -m "merge: back-merge main to develop after release v[X.Y.Z]"
git push origin develop
```

#### CHECKPOINT
- [ ] Back-merge from main to develop completed and pushed

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Back-merge from main to develop failed
Cause: Merge conflicts between main and develop, or push to develop rejected.
Recovery:
  [ ] Option A: If merge conflicts — resolve them (the main version should take precedence for version-bump files), then complete the merge commit and push
  [ ] Option B: If push is rejected — run `git pull origin develop --rebase` to sync, then push the back-merge commit
  [ ] Option C: If back-merge cannot be completed automatically, ask user to perform it manually — document the manual step in the release report; this is important to avoid develop diverging from main

### Fase 12: Promote to Prod

#### MUST DO
> ⚠️ All actions are MANDATORY

Ejecutar skill `promote` con `--to prod` para sincronizar worktree de producción.

#### CHECKPOINT
- [ ] Production worktree synchronized via /promote — promote completed successfully

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Promote to prod failed — production worktree not synchronized
Cause: `/promote --to prod` failed due to worktree issues, security gate blocking, or environment config errors.
Recovery:
  [ ] Option A: Review the output from `/promote --to prod` — address the specific phase that failed (Security Gate, env config, deploy, health) following the promote skill's own IF FAILS blocks
  [ ] Option B: If promote is blocked by CASTLE (requires FORTIFIED for prod), confirm that Fase 3 CASTLE Certification was FORTIFIED — if it was, re-run promote
  [ ] Option C: If promote cannot complete, document the production deployment as PENDING in the release report and ask user to retry `/promote --to prod` manually

### Fase 13: Post-deploy Health

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Health checks en producción
2. [ ] Smoke tests completos

#### CHECKPOINT
- [ ] Production health checks passing — smoke tests completed successfully

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Post-deploy health checks failed in production
Cause: Application not starting correctly in production environment, API key missing, or smoke test failures.
Recovery:
  [ ] Option A: Check production health endpoint and server logs — identify whether failure is startup (config) or runtime (logic) and fix accordingly
  [ ] Option B: If smoke tests fail in production but passed in QA, compare the environment configs between QA and production — identify the configuration difference
  [ ] Option C: If production health cannot be restored quickly, execute rollback: revert the production worktree to the previous tag (`git checkout origin/v[previous] --detach`) and notify user immediately

### Fase 14: Report

#### MUST DO
> ⚠️ All actions are MANDATORY

```
## Release Report — v[X.Y.Z]

### CASTLE Certification: FORTIFIED
[Reporte completo por capa]

### Changelog
[Lista categorizada de cambios]

### Artifacts
- PR: [URL]
- Tag: v[X.Y.Z]
- Release: [URL]
- Build: client/dist/ (OK)

### Post-deploy
- Health: [OK]
- Smoke tests: [PASS]

### Release Status: [PUBLICADO|FALLIDO]
```

#### CHECKPOINT
- [ ] Release report generated — CASTLE certification, changelog, artifacts and post-deploy status documented

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Release report not completed — required sections missing
Cause: One or more required report fields (CASTLE certification, PR URL, tag, GitHub Release URL, build status, health check) could not be assembled.
Recovery:
  [ ] Option A: Retrieve each missing field from phase outputs — `gh pr view`, `git tag -l`, `gh release view v[X.Y.Z]`, and health check results
  [ ] Option B: If the release is complete but the report is partial, output what is available with Status: PARTIAL — the release artifacts (tag, GitHub Release) are the critical outputs
  [ ] Option C: Never skip the release report — it is the audit trail for the release and must exist even in a partial state

---

## FINAL CHECKPOINT

> Verificar TODOS los items antes de reportar el release como exitoso.

- [ ] Tag de versión creado y pusheado al repositorio
- [ ] GitHub Release publicado con release notes
- [ ] CHANGELOG actualizado y commiteado
- [ ] Back-merge a develop completado (master → develop)
- [ ] Post-deploy health check OK en producción
- [ ] Notificaciones de release enviadas (si aplica)

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

### Fase 15: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 16: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para release:
| Condición | Próximo Skill |
|-----------|---------------|
| Release completo | Ciclo completado — iniciar nuevo ciclo con `/brainstorm` |

## Templates

- **Release Notes**: `templates/release-notes.md` — Formato estándar con secciones de nuevas features, fixes, breaking changes y CASTLE certification
