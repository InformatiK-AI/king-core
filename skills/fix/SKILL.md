---
name: fix
description: "Workflow sistemático para corregir bugs. Usar cuando se necesite: fix de bug, corregir un error, resolver un issue, debugging, o arreglar un problema reportado."
version: 2.0
---

# Fix — Corrección Sistemática de Bugs

Workflow para corregir bugs de forma metódica, atacando la causa raíz y no solo el síntoma.

> **Path resolution**: Paths `skills/`, `agents/`, `knowledge/`, `rules/` son relativas a KING_FRAMEWORK_PATH (anunciado al inicio de sesión). Prepend ese valor al usar Read.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural context for understanding the bug root cause | Yes | project |
| `.king/knowledge/conventions.md` | Code conventions to follow in the fix | Yes | project |
| `knowledge/_inject/security-essentials.md` | Security patterns relevant to bug root cause analysis | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] El bug no pudo ser reproducido
- [ ] La causa raíz no fue identificada

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA aplicar el fix antes de reproducir el bug (Fase 1 obligatoria)
- NUNCA modificar más código del mínimo necesario para resolver el bug
- NUNCA proceder sin escribir el test de regresión (Fase 4)

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Fix implementado en el código
- [ ] Test de regresión que verifica el fix
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
Load      Reproduce  RootCause  Fix     Test      Regression Report   Session   Guide
```

---


## Agentes involucrados
- **@developer** → Implementa el fix
- **@qa** → Verifica que el fix funciona y no introduce regresiones

## CASTLE activo: _·A·S·T·_·_

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### Fase 1: Reproduce

#### GATE IN
- [ ] Fase 0 completada — contexto de sesión cargado y bug descrito con suficiente información

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Entender el bug reportado (issue, descripción, pasos)
2. [ ] Intentar reproducir el problema:
   - Si es de pipeline: usar test projects embebidos
   - Si es de API: probar con curl
   - Si es de UI: describir el flujo exacto
3. [ ] Documentar cómo reproducir el bug consistentemente
4. [ ] Si no se puede reproducir: pedir más información
5. [ ] Capturar evidencia visual del bug:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Bug-Reproduction
   Si se omite, documentar motivo en reporte de sesión.
   ---

#### CHECKPOINT
- [ ] Bug reproducido consistentemente — pasos de reproducción documentados

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Bug cannot be reproduced consistently
Cause: Missing environment setup, insufficient reproduction steps provided, or bug is intermittent/environment-specific.
Recovery:
  [ ] Option A: Ask user for more context — exact error message, OS, version, environment variables, and steps to trigger — then retry reproduction
  [ ] Option B: If intermittent, attempt reproduction 3 times and document the rate — if reproducible at least once, proceed with that evidence
  [ ] Option C: If bug is confirmed unreproducible in current environment, document findings and STOP — do not fix what cannot be verified; escalate to user

### Fase 2: Root Cause Analysis

#### GATE IN
- [ ] Bug reproducido consistentemente en Fase 1

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **NO saltar directo al fix** — Entender POR QUÉ ocurre
2. [ ] Trazar el flujo de datos que produce el bug:
   - ¿Dónde se origina? (input, estado, configuración)
   - ¿Por qué el código actual no lo maneja?
   - ¿Es un edge case, un error lógico, o un error de integración?
3. [ ] Identificar la causa raíz (no el síntoma)
4. [ ] Usar protocolo RADAR para analizar alternativas de fix

#### CHECKPOINT
- [ ] Causa raíz identificada — origen, tipo de error y alternativas de fix documentados

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Root cause not identified after analysis
Cause: Bug behavior is too complex, spans multiple layers, or the codebase context is insufficient to trace the data flow.
Recovery:
  [ ] Option A: Expand the trace — follow the data flow one layer deeper (e.g., check DB queries, network requests, or state transitions) and re-analyze
  [ ] Option B: If the root cause is in a third-party dependency, check the dependency's changelog/issues for known bugs matching the symptom
  [ ] Option C: Escalate to user with the partial analysis — document what is known (where it fails) vs unknown (why it fails) and ask for additional context or pair debugging

### Fase 3: Fix Implementation (via @developer)

#### GATE IN
- [ ] Causa raíz identificada en Fase 2

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Implementar la corrección MÍNIMA necesaria:
   - No refactorizar código circundante
   - No agregar features
   - Solo corregir el bug
2. [ ] Seguir convenciones del proyecto
3. [ ] Hacer commit con conventional commit:
   ```
   fix(scope): descripción del fix

   Fixes #[issue-number]
   ```

#### CHECKPOINT
- [ ] Fix mínimo implementado y commiteado con conventional commit

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Fix not committed — implementation artifact absent
Cause: Write operation failed, fix introduced a syntax error preventing commit, or the commit hook rejected the commit message format.
Recovery:
  [ ] Option A: Run `git status` — if files are modified but not staged, fix any syntax errors, then stage and commit with conventional format (`fix(scope): description`)
  [ ] Option B: If commit hook rejected the message, correct the format to match `fix(scope): description` and retry
  [ ] Option C: If the fix itself broke other things, revert to the pre-fix state (`git checkout -- [file]`), re-analyze, and apply a narrower fix

### Fase 4: Test

#### GATE IN
- [ ] Fix implementado en Fase 3

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Escribir/verificar test que reproduce el bug
2. [ ] Verificar que el test FALLA sin el fix
3. [ ] Verificar que el test PASA con el fix
4. [ ] Verificar sintaxis:
   ```bash
   [comando de verificación del proyecto - ver CLAUDE.md]
   ```
5. [ ] Capturar verificación visual del fix:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Fix-Verification
   Si se omite, documentar motivo en reporte de sesión.
   ---

#### CHECKPOINT
- [ ] Test pasa con el fix y falla sin él — comportamiento verificado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Test still fails after fix applied — fix did not resolve the bug
Cause: Fix addressed the symptom but not the actual root cause, or the test itself does not correctly reproduce the original bug scenario.
Recovery:
  [ ] Option A: Show last 20 lines of test failure output — compare with the original bug reproduction evidence to confirm the test is testing the right thing
  [ ] Option B: If the test is correct and still fails, return to Fase 2 Root Cause Analysis — the identified root cause was likely incorrect
  [ ] Option C: If the test was written incorrectly (does not isolate the bug), fix the test first, then re-verify fix behavior

### Fase 5: Regression Check

#### GATE IN
- [ ] Test de Fase 4 pasando con el fix aplicado

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar que funcionalidad existente no se rompió
2. [ ] Si el fix toca el pipeline: verificar con test projects
3. [ ] Si el fix toca la API: verificar endpoints
4. [ ] Build completo si es cambio significativo

#### CHECKPOINT
- [ ] Sin regresiones detectadas — funcionalidad existente verificada

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Regression detected — existing functionality broken by fix
Cause: The fix changed shared code, a utility, or a data structure that other features depend on.
Recovery:
  [ ] Option A: Identify exactly which test/behavior regressed — narrow the fix to avoid touching shared code, or add a guard condition that only applies the fix in the bug's specific scenario
  [ ] Option B: If regression is unavoidable, evaluate whether the fix approach needs to change — return to Fase 2 and consider an alternative fix strategy
  [ ] Option C: If regression affects a critical path, revert the fix (`git revert HEAD`), document the conflict, and escalate to user with both the original bug and the regression trade-off

### Fase 6: Report

#### GATE IN
- [ ] Regression Check de Fase 5 completado sin issues

#### MUST DO
> ⚠️ All actions are MANDATORY

```
## Fix Report

### Bug: [descripción]
### Issue: #[número]

### Causa raíz
[Explicación de por qué ocurría el bug]

### Fix aplicado
[Descripción del cambio mínimo]

### Archivos modificados
- [archivo]: [cambio]

### Verificación
- [ ] Bug reproducido antes del fix
- [ ] Bug resuelto después del fix
- [ ] Test escrito para prevenir regresión
- [ ] No regresiones detectadas
- [ ] Sintaxis válida
- [ ] Evidencia de reproducción capturada (screenshots pre-fix)
- [ ] Evidencia de verificación capturada (screenshots post-fix)

### Evidencia Visual
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### CASTLE Score: [resultado parcial A·S·T]
```

#### CHECKPOINT
- [ ] Reporte de fix generado — causa raíz, archivos modificados, verificación y CASTLE score incluidos

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Fix report not completed — required sections missing
Cause: One or more required report fields (root cause, modified files, test verification, CASTLE score) could not be assembled.
Recovery:
  [ ] Option A: Retrieve missing data from session artifacts — `git diff HEAD~1`, CASTLE output, and test run logs — and complete the report manually
  [ ] Option B: If CASTLE score is missing because the assessment was skipped, run the relevant CASTLE layers (A·S·T) now and add the result
  [ ] Option C: Output a partial report with Status: PARTIAL noting which sections are missing and why — never omit the report entirely

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Sesión registrada

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(copiar de CASTLE Assessment)_ |
| Artifacts | _(listar archivos modificados, branch, PR)_ |
| Next Recommended | _(copiar de tabla de flujo)_ |
| Risks | _(listar findings CONDITIONAL o BREACHED, o "None")_ |

### Fase 7: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 8: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para fix:
| Condición | Próximo Skill |
|-----------|---------------|
| Fix aplicado exitosamente | `/review` |
