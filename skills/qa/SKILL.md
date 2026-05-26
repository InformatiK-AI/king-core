---
name: qa
description: "QA estándar para una feature o cambio individual. Usar cuando se necesite: ejecutar QA, verificar calidad de una feature, validar una implementación, o hacer quality assurance de un cambio."
version: 2.0
---

# QA Standard — Calidad por Feature

Evaluación de calidad para una feature o cambio individual.

> **Path resolution**: Paths `skills/`, `agents/`, `knowledge/`, `rules/` son relativas a KING_FRAMEWORK_PATH (anunciado al inicio de sesión). Prepend ese valor al usar Read.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural context for QA assessment | Yes | project |
| `.king/knowledge/conventions.md` | Code and quality conventions to verify | Yes | project |
| `knowledge/_inject/security-essentials.md` | Security patterns for security verification | No | framework |
| `knowledge/_inject/testing-essentials.md` | Testing strategies and coverage requirements | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No hay implementación para evaluar
- [ ] Los acceptance criteria no están definidos

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA marcar como CASTLE FORTIFIED si algún criterio de aceptación obligatorio no fue verificado
- NUNCA omitir la verificación de regresiones en funcionalidad existente

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] QA Report con veredicto APPROVED/REJECTED/CONDITIONAL
- [ ] Tests ejecutados con resultados documentados
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 3b → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
Load      Strategy  Execution  Coverage  SpecComp   SecGate   CASTLE   Report   Session   Guide
```

---


## Agentes involucrados
- **@qa** → Ejecuta verificaciones de calidad
- **@security** → Ejecuta Security Gate

## CASTLE: C·A·S·T·L·_ — [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### Fase 1: Strategy

#### GATE IN
- [ ] Implementación a evaluar existe

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Identificar qué cambió (diff del branch/PR)
2. [ ] Determinar qué testear basado en los cambios:
   - Cambios en pipeline → tests con test projects embebidos
   - Cambios en API → tests de endpoints
   - Cambios en UI → verificación visual y de i18n
   - Cambios en config → verificación de ambientes
3. [ ] Listar acceptance criteria del issue si existe

#### CHECKPOINT
- [ ] Acceptance criteria listados — estrategia de testing determinada

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Acceptance criteria not defined — QA strategy cannot be determined
Cause: The issue or feature has no Gherkin scenarios, no DoD, and no ACs defined; or the implementation cannot be identified from the provided context.
Recovery:
  [ ] Option A: Check the issue file (`.king/issues/STORY-NNN.md` or `gh issue view N`) for ACs — if present, extract and list them now
  [ ] Option B: If ACs are truly absent, ask user to define at least 2 acceptance criteria before continuing — QA cannot proceed without a verifiable spec
  [ ] Option C: If the feature is clearly scoped but has no formal ACs, derive ACs from the feature description (Happy path + 1 edge case) and get user confirmation before proceeding

### Fase 2: Execution

#### GATE IN
- [ ] Estrategia de Fase 1 definida

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificación de sintaxis:
   ```bash
   [comando de verificación del proyecto - ver CLAUDE.md]
   ```
2. [ ] Verificación de servidor (si aplica):
   ```bash
   cd [project-root] && timeout 5 node server/index.js 2>&1 || true
   ```
3. [ ] Verificación de build (si aplica):
   ```bash
   cd [project-root] && npm run build 2>&1
   ```
4. [ ] Para cada AC: verificar que se cumple con evidencia
5. [ ] Captura visual de resultados:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture QA-Execution
   Si se omite, documentar motivo en reporte de sesión.
   ---

#### CHECKPOINT
- [ ] Tests ejecutados — cada AC verificado con evidencia

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Tests or build failed during QA execution
Cause: Syntax error, missing dependency, server startup failure, or one or more ACs not satisfied by the current implementation.
Recovery:
  [ ] Option A: Show last 20 lines of the failing command's stderr — identify whether the failure is infrastructure (missing tool, wrong path) or logic (AC not implemented)
  [ ] Option B: If infrastructure failure (e.g., `npm run build` fails), fix the environment issue first — verify tool versions and config, then re-run
  [ ] Option C: If an AC is not satisfied, document it as FAIL with actual vs expected output, then return the finding to @developer for fix before re-running QA

### Fase 3: Coverage

#### GATE IN
- [ ] Execution de Fase 2 completada

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Analizar si hay tests para cada cambio
2. [ ] Verificar que tests existentes no se rompieron
3. [ ] Identificar gaps de cobertura
4. [ ] Si hay funciones do* nuevas: verificar con test projects

#### CHECKPOINT
- [ ] Gaps de cobertura identificados — tests existentes verificados sin regresión

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Regression detected — previously passing tests now fail
Cause: The new implementation changed shared code, utilities, or data structures that existing tests depend on.
Recovery:
  [ ] Option A: Identify exactly which tests regressed (test name + file) — show the diff of what changed that caused the regression
  [ ] Option B: Return finding to @developer: list the regressed tests and the code change that caused them — request a fix before QA continues
  [ ] Option C: If the regression is in a test that was already broken before this change (pre-existing failure), document it as a pre-existing issue and exclude it from the regression count — verify with git blame

### Fase 3b: Spec Compliance Check

#### GATE IN
- [ ] Coverage de Fase 3 analizada

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Buscar specs bajo `.king/sdd/{change-name}/specs/` y `.king/sdd/specs/`
2. [ ] IF no existen specs: registrar `"No specs found — skipping compliance matrix"` → continuar a Fase 4
3. [ ] IF existen specs:
   a. Por cada requisito y escenario en specs: buscar test correspondiente en resultados de Fase 2
   b. Asignar compliance: ✅ COMPLIANT (test pasó) / ❌ FAILING (test falló) / ❌ UNTESTED (sin test) / ⚠️ PARTIAL (cobertura parcial)
   c. Producir tabla: `Requirement | Scenario | Test | Result`
   d. Registrar resumen: `"{N}/{total} scenarios compliant"`

#### CHECKPOINT
- [ ] Compliance Matrix producida O `"No specs found"` registrado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Spec Compliance Check could not complete
Cause: Spec files found but unreadable, or test results from Fase 2 unavailable.
Recovery:
  [ ] Option A: Re-leer spec files individualmente — omitir archivos ilegibles con WARNING
  [ ] Option B: Si resultados de Fase 2 no disponibles, marcar todos los escenarios como ❌ UNTESTED y continuar
  [ ] Option C: Documentar "Spec Compliance Check: PARTIAL — {reason}" en QA Report y continuar a Fase 4

### Fase 4: Security Gate

#### GATE IN
- [ ] Coverage de Fase 3 analizado

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar Security Gate completo (5 checks)
2. [ ] Documentar cualquier finding

#### CHECKPOINT
- [ ] Security Gate completado — resultado documentado (SECURE/REVIEW/VULNERABLE)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Security Gate result is VULNERABLE — QA cannot pass
Cause: The implementation introduces secrets, OWASP-pattern vulnerabilities, or unsafe dependencies.
Recovery:
  [ ] Option A: Document the specific finding (type, file, line) — return it to @developer with a BLOQUEANTE severity label; QA verdict is RECHAZADO until resolved
  [ ] Option B: If finding is a false positive, document the justification and get explicit user approval before reclassifying as REVIEW
  [ ] Option C: If Security Gate tool fails to run (command error), document "Security Gate could not execute — [reason]" and mark result as REVIEW, not SECURE — never assume SECURE when the gate cannot run

### Fase 5: CASTLE Assessment

#### GATE IN
- [ ] Security Gate de Fase 4 completado

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar CASTLE con capas C·A·S·T·L
2. [ ] Para capa T: incorporar resultado de Fase 3b en el veredicto
   - Sin specs (skipped) → T basado solo en cobertura de tests (Fase 3)
   - UNTESTED en Compliance Matrix → T: ⚠️ WARNING
   - FAILING en Compliance Matrix → T: ❌ BREACH
   - Todos COMPLIANT → T: ✅ PASS (combinado con Fase 3)
3. [ ] Documentar resultado por capa

#### CHECKPOINT
- [ ] CASTLE C·A·S·T·L evaluado — veredicto determinado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: CASTLE verdict cannot be determined — one or more layers not evaluated
Cause: Fases 2-4 did not produce complete findings for all required CASTLE layers (C·A·S·T·L).
Recovery:
  [ ] Option A: Identify which layer is missing data — re-run the corresponding phase and document results before re-running CASTLE
  [ ] Option B: If a layer is intentionally not applicable (e.g., no architecture changes), document it as N/A with justification — N/A counts as evaluated
  [ ] Option C: If CASTLE cannot be completed, output a partial verdict with layers evaluated so far and mark the session as Status: PARTIAL

### Fase 6: Report

#### GATE IN
- [ ] CASTLE Assessment de Fase 5 completado

#### MUST DO
> ⚠️ All actions are MANDATORY

```
## QA Standard Report

### Feature/Cambio: [descripción]
### Fecha: [fecha]

### Acceptance Criteria
| # | Criterio | Estado | Evidencia |
|---|----------|--------|-----------|
| 1 | ... | PASS/FAIL | ... |

### Verificaciones técnicas
- [ ] Sintaxis válida
- [ ] Servidor inicia sin errores
- [ ] Build exitoso
- [ ] No regresiones

### Spec Compliance Matrix
[Si existen specs — incluir tabla:]
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| ... | ... | ... | ✅ COMPLIANT |

**Compliance summary**: {N}/{total} scenarios compliant

[Si no existen specs — omitir esta sección completa]

### Security Gate: [SECURE|REVIEW|VULNERABLE]
### CASTLE Score: [FORTIFIED|CONDITIONAL|BREACHED]

### Evidencia Visual
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### Veredicto: [APROBADO|OBSERVACIONES|RECHAZADO]
```

#### CHECKPOINT
- [ ] QA Report generado — veredicto APROBADO/OBSERVACIONES/RECHAZADO establecido

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: QA Report not generated — required sections missing
Cause: One or more required report fields (AC table, technical verifications, Security Gate result, CASTLE score, veredicto) could not be assembled.
Recovery:
  [ ] Option A: Reconstruct missing sections from phase outputs already available in this session — AC results from Fase 2, coverage from Fase 3, security from Fase 4, CASTLE from Fase 5
  [ ] Option B: If veredicto cannot be determined because findings are conflicting, default to OBSERVACIONES with a note listing the open questions
  [ ] Option C: Output a partial QA Report with Status: PARTIAL — document what was evaluated and what remains; never skip the report entirely

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
| Artifacts | _(review report generado, o qa report generado)_ |
| Next Recommended | _(copiar de tabla de flujo)_ |
| Risks | _(listar findings CONDITIONAL o BREACHED, o "None")_ |

---

### Fase 7: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 8: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para qa:
| Condición | Próximo Skill |
|-----------|---------------|
| CASTLE >= CONDITIONAL | `/merge` |
| CASTLE BREACHED | `/fix` → luego repetir `/qa --standard` |
