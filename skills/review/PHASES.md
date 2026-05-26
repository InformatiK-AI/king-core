# Code Review — Phases (v2.0)

> Lógica detallada de las fases 1-6. Entry point: [SKILL.md](SKILL.md)

---

## Fase 1: Context

### GATE IN
- [ ] Diff o PR disponible para revisar

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Obtener el diff de los cambios (PR o branch)
2. [ ] Leer los archivos modificados completos (no solo diff)
3. [ ] Entender el propósito del cambio (issue, feature spec)
4. [ ] Identificar el alcance del impacto

### CHECKPOINT
- [ ] Archivos modificados leídos completos — propósito del cambio entendido

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Diff or PR not available for review
Cause: Branch does not exist, PR number is incorrect, or `gh` CLI is not authenticated.
Recovery:
  [ ] Option A: If reviewing a PR, run `gh pr view [PR#]` to confirm it exists and is accessible — fix authentication with `gh auth login` if needed
  [ ] Option B: If reviewing a branch diff directly, run `git diff develop...[branch]` — verify the branch name and that it is fetched from remote
  [ ] Option C: If neither PR nor branch is available, ask user to provide the diff or the correct PR number before continuing

---

## Fase 2: Architecture Review (via @architect)

### GATE IN
- [ ] Context de Fase 1 completo

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] ¿Los cambios siguen la arquitectura establecida?
2. [ ] ¿Se respeta dependency direction (UI → Logic → Data)?
3. [ ] ¿Los patrones son consistentes (prefijos, secciones)?
4. [ ] ¿El coupling es aceptable?
5. [ ] ¿Hay mejores alternativas arquitectónicas?

### CHECKPOINT
- [ ] Alineación arquitectónica evaluada — findings documentados (o 'ninguno')

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Architecture review could not be completed — findings not documented
Cause: Insufficient context to evaluate architectural alignment, or the changes touch layers not covered by current ADRs.
Recovery:
  [ ] Option A: Load `.king/knowledge/architecture.md` if not already loaded — re-evaluate with full architectural context and document all findings, even if finding is "no issues detected"
  [ ] Option B: If the change introduces a new pattern not covered by existing architecture docs, document it as a finding of type SUGGESTION with a note to create an ADR
  [ ] Option C: If @architect is unavailable, proceed with findings: "Architecture review skipped — @architect unavailable" and mark CASTLE A layer as CONDITIONAL

---

## Fase 3: Security Review (via @security)

### GATE IN
- [ ] Architecture Review de Fase 2 completado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] ¿Se introducen secrets o credenciales?
2. [ ] ¿Hay patrones OWASP vulnerables?
3. [ ] ¿Los inputs se validan?
4. [ ] ¿Los errores exponen información sensible?
5. [ ] ¿Las dependencias nuevas son seguras?

### CHECKPOINT
- [ ] Patrones OWASP verificados — findings documentados (o 'ninguno')

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Critical security vulnerabilities detected — review cannot pass
Cause: Changes introduce secrets, unvalidated inputs, OWASP Top 10 patterns, or insecure dependencies.
Recovery:
  [ ] Option A: Document each finding with severity (CRITICAL/HIGH/MEDIUM) and specific file+line — output as BLOQUEANTE findings in the report; do not approve until resolved
  [ ] Option B: If finding is a false positive, document the justification explicitly and mark as SUGERENCIA — get user acknowledgment before proceeding
  [ ] Option C: If CRITICAL vulnerability is found, set veredicto to CAMBIOS REQUERIDOS immediately and stop further review — security issues block all other findings

---

## Fase 4: Quality Review (via @qa)

### GATE IN
- [ ] Security Review de Fase 3 completado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] ¿Hay tests para los cambios?
2. [ ] ¿Los tests cubren edge cases?
3. [ ] ¿Se mantiene la cobertura existente?
4. [ ] ¿Las convenciones del proyecto se respetan?
5. [ ] ¿El i18n está completo (3 idiomas)?
6. [ ] Verificación visual (si los cambios afectan la UI):

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Smoke-Test
   Omitir si el cambio es puramente lógico/backend. Si se omite, documentar motivo en reporte de sesión.
   ---

7. [ ] Accessibility Gate (si los cambios afectan la UI):
   > Seguir instrucciones de `rules/accessibility-gate.md` — `critical` bloquea el review

8. [ ] Performance Budget Gate (conditional — solo si `LOAD-INDEX.md` existe):
   → Ver `rules/token-budget-gate.md` para el proceso completo
   → **`mode: warn` FORZADO** — este gate NUNCA bloquea una review, independientemente de `.king/token-budget.yaml`
   → Detectar si el PR diff incluye cambios a `.king/token-budget.yaml`:
      - Si thresholds fueron reducidos → WARN "token-budget.yaml: thresholds reduced — verify intentional"
      - Si `enabled` cambió de `true` a `false` → WARN "token-budget.yaml: gate disabled — verify intentional"
      - Si `mode` cambió → WARN "token-budget.yaml: mode changed — verify intentional"
   → Resultado del gate: incluir como observación INFO en el reporte (no afecta veredicto CASTLE)
   → Si LOAD-INDEX.md no existe: skip silencioso (no emitir warning al reviewer)

### CHECKPOINT
- [ ] Tests, cobertura y convenciones verificados — findings documentados
- [ ] Accessibility Gate completado o skip documentado con justificación
- [ ] Performance Budget Gate ejecutado o skip documentado (LOAD-INDEX.md ausente)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Quality review failed — tests missing, conventions not respected, or critical a11y violations
Cause: The implementation lacks tests for new code paths, existing tests are broken, project conventions are violated, or axe-core detected critical accessibility violations.
Recovery:
  [ ] Option A: Document each quality finding — missing tests as BLOQUEANTE, convention violations as WARNING — and output them in the report; do not suppress findings
  [ ] Option B: If tests exist but are insufficient (missing edge cases), document as WARNING with specific scenarios that should be covered
  [ ] Option C: If quality review cannot be completed (e.g., test runner fails), document "Quality review incomplete — [reason]" as a finding and mark CASTLE T layer as CONDITIONAL
  [ ] Option D: If Accessibility Gate found `critical` violations — document each violation (element, rule, `wcag_url`) as BLOQUEANTE; do not approve until all critical violations are fixed by @developer

---

## Fase 5: CASTLE Assessment

### GATE IN
- [ ] Fases 2-4 completadas con findings documentados

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar CASTLE con capas C·A·S·T
2. [ ] Documentar findings por capa

### CHECKPOINT
- [ ] CASTLE C·A·S·T evaluado — veredicto determinado (FORTIFIED/CONDITIONAL/BREACHED)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: CASTLE verdict cannot be determined — assessment incomplete
Cause: One or more of Fases 2-4 did not produce documented findings, leaving a CASTLE layer without data to evaluate.
Recovery:
  [ ] Option A: Identify which layer is missing findings — re-run that specific phase (Architecture, Security, or Quality) and document results before re-running CASTLE
  [ ] Option B: If a layer was intentionally skipped (e.g., no UI changes so frontend layer skipped), document the skip reason and mark that layer as N/A in the CASTLE output
  [ ] Option C: If CASTLE cannot be completed due to environment issues, output the partial assessment with a note — never leave the verdict field blank

---

## Fase 6: Report

### GATE IN
- [ ] CASTLE Assessment de Fase 5 completado

### MUST DO
> ⚠️ All actions are MANDATORY

Categorizar findings por severidad:

```
## Code Review Report

### BLOQUEANTES (deben resolverse antes de merge)
- [finding 1]
- [finding 2]

### WARNINGS (recomendados pero no bloqueantes)
- [finding 1]

### SUGERENCIAS (mejoras opcionales)
- [finding 1]

### CASTLE Score
[Resultado del assessment]

### Evidencia Visual (si aplica)
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### Veredicto: [APROBADO|CAMBIOS REQUERIDOS|RECHAZADO]
```

### CHECKPOINT
- [ ] Reporte generado con findings categorizados por severidad — veredicto final establecido

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Review report not generated — findings or verdict missing
Cause: One or more prior phases did not produce findings output, or the report template was not filled completely.
Recovery:
  [ ] Option A: Reconstruct missing sections from phase outputs already produced in this session — findings from Fases 2-4 and CASTLE from Fase 5
  [ ] Option B: If veredicto cannot be set because findings conflict, default to CAMBIOS REQUERIDOS with a note listing the unresolved conflicts
  [ ] Option C: Output the partial report with whatever sections are complete — never skip the report entirely; Status: PARTIAL is valid
