---
name: castle-report
version: 1.0
api_version: 1.0.0
description: "Genera el CASTLE Score numérico reproducible leyendo sub-reports JSON. Agrega coverage, SOLID, a11y y performance en un score 0-100."
---

# CASTLE Score Report — Agregador Numérico

Produce el score CASTLE determinista leyendo sub-reports JSON existentes en `.king/castle/`. Graceful degradation: gates sin sub-report se excluyen del promedio — no bloquean la ejecución.

> **Path resolution**: Paths `.king/castle/` son relativos al proyecto donde se invoca el skill (no a KING_FRAMEWORK_PATH).

---

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Si alguna es TRUE, DETENER inmediatamente

- [ ] `.king/castle/` no existe Y ningún sub-report es accesible

### ABSOLUTE RESTRICTIONS
> Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA incluir `generated_at` en el cálculo del `castle_score`
- NUNCA fallar con exit error si un sub-report está ausente (`status: "missing"` es el resultado correcto)
- NUNCA cambiar la estructura del schema JSON (contrato consumido por M-24/M-28)
- NUNCA penalizar un gate ausente — solo los gates presentes participan en el promedio

### REQUIRED OUTPUTS

- [ ] Tabla de score en terminal
- [ ] `.king/castle/castle-report.json` escrito con schema completo

### PHASES OVERVIEW

```
Phase 1: Read Sub-Reports   → leer coverage-report.json + opcionalmente solid/a11y/perf
Phase 2: Calculate Scores   → score por gate según reglas de severidad
Phase 3: Aggregate Score    → castle_score = promedio de gates presentes
Phase 4: Determine Verdict  → FORTIFIED | CONDITIONAL | BREACHED
Phase 5: Display Table      → mostrar tabla en terminal
Phase 6: Write Output       → escribir castle-report.json
FINAL CHECKPOINT
Execution Summary
```

---

## Phase 1: Read Sub-Reports

Intentar leer los siguientes archivos. Si no existe, asignar `status: "missing"`.

| File | Gate | Required |
|------|------|----------|
| `.king/castle/coverage-report.json` | coverage | Yes (M-12) |
| `.king/castle/solid-report.json` | solid | No (M-24) |
| `.king/castle/a11y-report.json` | a11y | No (M-28) |
| `.king/castle/perf-report.json` | performance | No (M-27) |

### Campos esperados por sub-report

**coverage-report.json**:
```json
{ "coverage": 0.0, "threshold": 80, "status": "pass|fail" }
```

**solid-report.json**:
```json
{ "violations": [], "status": "pass|fail" }
```

**a11y-report.json**:
```json
{ "violations": [], "status": "pass|fail" }
```
Cada violation en a11y tiene campo `impact`: `"critical"` | `"serious"` | `"moderate"` | `"minor"`.

**perf-report.json**:
```json
{ "budget_exceeded": false, "status": "pass|fail" }
```

---

## Phase 2: Calculate Gate Scores

Para cada gate, aplicar las siguientes reglas:

### Si `status: "missing"` (archivo no encontrado)
- `score: null`
- `status: "missing"`
- NO participar en el promedio

### Si `status: "pass"`
- `score: 100`

### Si `status: "fail"`, calcular según gate:

**coverage**:
```
score = min(100, (coverage_actual / threshold) * 100)
```
Ejemplo: coverage=72%, threshold=80% → score = (72/80)*100 = 90

**solid**:
```
score = max(0, 100 - (count(violations) * 10))
```
Ejemplo: 3 violations → score = 70

**a11y**:
```
critical_count  = count(violations donde impact == "critical")
serious_count   = count(violations donde impact == "serious")
score = max(0, 100 - (critical_count * 25) - (serious_count * 10))
```
Ejemplo: 2 critical + 1 serious → score = 100 - 50 - 10 = 40

**performance**:
```
score: 0   si budget_exceeded == true y status == "fail"
```

---

## Phase 3: Aggregate Score

```
gates_presentes = [gate para gate en {coverage, solid, a11y, performance} si status != "missing"]
castle_score = promedio(score de gates_presentes)
```

Si NO hay ningún gate presente → `castle_score: 0`, `verdict: "BREACHED"` con nota "No sub-reports found".

Redondear `castle_score` a 1 decimal.

---

## Phase 4: Determine Verdict

| castle_score | verdict |
|---|---|
| >= 85 | `FORTIFIED` |
| 60 – 84 | `CONDITIONAL` |
| < 60 | `BREACHED` |

---

## Phase 5: Display Table

Mostrar en terminal antes de escribir el JSON:

```
CASTLE Score: {castle_score}/100 — {VERDICT}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Coverage    {icon} {coverage_pct}% / threshold {threshold}%   score: {score}
 SOLID       {icon} {n} violations                             score: {score}
 A11y        {icon} {estado}                                   score: {score}
 Performance {icon} {estado}                                   score: {score}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Baseline delta: {baseline_delta|"N/A (primera ejecución)"}
```

Iconos:
- `pass` → `[PASS]`
- `fail` → `[FAIL]`
- `missing` → `[MISSING]` con score `—`

---

## Phase 6: Write Output

Escribir `.king/castle/castle-report.json` con el siguiente schema (INMUTABLE — contrato M-34):

```json
{
  "schema_version": "1.0",
  "castle_score": 0.0,
  "gates": {
    "coverage":    { "score": 0.0, "threshold": 80, "status": "pass|fail|missing" },
    "solid":       { "score": 0.0, "violations": [], "status": "pass|fail|missing" },
    "a11y":        { "score": 0.0, "violations": [], "status": "pass|fail|missing" },
    "performance": { "score": 0.0, "budget_exceeded": false, "status": "pass|fail|missing" }
  },
  "verdict": "FORTIFIED|CONDITIONAL|BREACHED",
  "baseline_delta": null,
  "generated_at": "ISO8601"
}
```

Reglas de escritura:
- `castle_score` y scores por gate: NUNCA incluir timestamp ni ID de sesión — solo datos de sub-reports
- `baseline_delta`: `null` si no existe baseline previo guardado en Engram para este proyecto
- `generated_at`: timestamp ISO8601 de la ejecución actual (solo metadato, no afecta score)
- Para gates `status: "missing"`: `score: null`, `violations: null` (no `[]`), `budget_exceeded: null`

---

## FINAL CHECKPOINT

- [ ] castle-report.json escrito en `.king/castle/`
- [ ] `castle_score` es el promedio de gates con status != "missing"
- [ ] `generated_at` NO afecta el `castle_score`
- [ ] Schema válido aun con todos los gates opcionales ausentes

---

## Execution Summary

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Score | _(castle_score / verdict)_ |
| Artifacts | `.king/castle/castle-report.json` |
| Next Recommended | Si `verdict == BREACHED`: elevar a QA veredicto; si no: continuar flujo normal |
| Risks | Gates ausentes reducen confianza del score — documentar cuáles están `missing` |
