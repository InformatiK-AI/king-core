---
name: a11y-audit
version: 1.0
description: "Audita accesibilidad WCAG 2.2 AA del proyecto. Produce a11y-report.json que alimenta el CASTLE S sub-score y el gate de /promote."
---

# A11y Audit — WCAG 2.2 AA (CASTLE S Sub-Score)

Detecta violaciones WCAG 2.2 AA en componentes UI del proyecto. Produce `a11y-report.json` en `.king/castle/`. El reporte es consumido por `/castle-report` (Phase 1) y por `/promote` (Phase 2b).

> **Path resolution**: Paths `.king/castle/` son relativos al proyecto donde se invoca el skill.

---

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Si alguna es TRUE, DETENER inmediatamente con el resultado indicado

- [ ] El proyecto NO tiene archivos UI (`.html`, `.jsx`, `.tsx`, `.vue`, `.svelte`) → exit 0 silencioso con nota "No UI components detected — a11y-audit skipped"
- [ ] `.king/accessibility.yaml` NO existe → exit 0 + WARN "No a11y config found — run /genesis to configure. Skipping gate." + escribir `a11y-report.json` con `status: "skipped"`

### ABSOLUTE RESTRICTIONS
> Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA bloquear si `.king/accessibility.yaml` no existe (grace period en primera ejecución)
- NUNCA modificar `rules/accessibility-gate.md` — este skill lo extiende, no lo reemplaza
- NUNCA omitir el campo `wcag_url` en cada violation
- NUNCA escribir `a11y-report.json` con schema diferente al definido en este skill (contrato M-28 consumido por castle-report)

### REQUIRED OUTPUTS

- [ ] Tabla de violaciones en terminal (si hay UI y config existe)
- [ ] `.king/castle/a11y-report.json` escrito con schema completo

### PHASES OVERVIEW

```
Phase 1: Detect UI         → verificar si el proyecto tiene componentes con output HTML/UI
Phase 2: Read Config       → leer .king/accessibility.yaml (grace period si no existe)
Phase 3: Scan Violations   → analizar archivos UI buscando violaciones WCAG 2.2 AA
Phase 4: Build Report      → construir a11y-report.json con violations + summary
Phase 5: Display Table     → mostrar tabla en terminal
Phase 6: Write Output      → escribir .king/castle/a11y-report.json
Phase 7: Enforce Gate      → exit 0 (pass/warn) o exit 2 (block si enforcement=block)
FINAL CHECKPOINT
Execution Summary
```

---

## Phase 1: Detect UI Components

Buscar en el proyecto archivos con extensiones: `.html`, `.jsx`, `.tsx`, `.vue`, `.svelte`.

- Si NO se encuentran archivos UI → **exit 0** con mensaje "No UI components detected — a11y-audit skipped". NO escribir `a11y-report.json`.
- Si SE encuentran → continuar a Phase 2.

---

## Phase 2: Read Config

Leer `.king/accessibility.yaml`.

**Grace period**: Si el archivo NO existe:
- Imprimir: "No a11y config found — run /genesis to configure. Skipping gate."
- Escribir `a11y-report.json` con `status: "skipped"`, `violations: []`, `enforcement: "warn"`
- **exit 0** — NO bloquear

Si existe, leer:
- `standard` (default: `wcag_2_2_aa`)
- `enforcement` (default: `block`)
- `exceptions[]` — violaciones aprobadas (tienen `approved_by` + `expires`)

Config de referencia:
```yaml
standard: wcag_2_2_aa
enforcement: block   # block | warn
exceptions:
  - element: "img[src=legacy-logo.png]"
    wcag: "1.1.1"
    approved_by: "arch-team"
    expires: "2025-12-31"
    reason: "Legacy asset pending redesign Q4 2025"
```

---

## Phase 3: Scan Violations

Analizar los archivos UI detectados buscando las siguientes violaciones WCAG 2.2 AA. Filtrar violations que coincidan con `exceptions[]` activas (no expiradas).

### Violations a detectar

| Check | WCAG | Impact | Descripción |
|-------|------|--------|-------------|
| `<img>` sin `alt` o con `alt=""` vacío | 1.1.1 | critical | Image missing alt text |
| `<button>` o `<a>` con solo icono/emoji sin `aria-label` | 2.4.6 | serious | Missing accessible name on interactive element |
| `<input>`, `<select>`, `<textarea>` sin `<label>` asociado | 1.3.1 | serious | Form control missing associated label |
| Colores hardcoded que pueden tener bajo contraste (requiere revisión manual) | 1.4.3 | moderate | Hardcoded color — verify contrast ratio manually |
| `<div>` o `<span>` con `onClick`/`onKeyDown` sin `role` ARIA | 4.1.2 | serious | Interactive div missing ARIA role |
| Jerarquía de headings con saltos (e.g., h1 → h3 sin h2) | 2.4.6 | moderate | Heading hierarchy skipped level |

### Formato de cada violation

```json
{
  "element": "<img src='hero.jpg' />",
  "impact": "critical",
  "wcag": "1.1.1",
  "wcag_url": "https://www.w3.org/WAI/WCAG22/Understanding/non-text-content",
  "description": "Image missing alt text",
  "file": "src/components/Hero.jsx",
  "line": 42
}
```

### WCAG URLs de referencia

| Criterio | URL |
|----------|-----|
| 1.1.1 | https://www.w3.org/WAI/WCAG22/Understanding/non-text-content |
| 1.3.1 | https://www.w3.org/WAI/WCAG22/Understanding/info-and-relationships |
| 1.4.3 | https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum |
| 2.4.6 | https://www.w3.org/WAI/WCAG22/Understanding/headings-and-labels |
| 4.1.2 | https://www.w3.org/WAI/WCAG22/Understanding/name-role-value |

---

## Phase 4: Build Report

Construir el objeto `a11y-report.json`:

```
summary.critical  = count(violations donde impact == "critical")
summary.serious   = count(violations donde impact == "serious")
summary.moderate  = count(violations donde impact == "moderate")
summary.minor     = count(violations donde impact == "minor")

status = "fail"  si critical > 0 OR serious > 0
status = "pass"  si critical == 0 AND serious == 0
```

---

## Phase 5: Display Table

Mostrar en terminal antes de escribir el JSON:

```
A11y Audit — WCAG 2.2 AA (S Gate)
-----------------------------------
critical  1.1.1  <img src="hero.jpg" />     Image missing alt text
serious   2.4.6  <button>icon</button>      Missing accessible name
-----------------------------------
Violations: 2 (1 critical, 1 serious) | FAIL — /promote BLOCKED
```

Si `violations: []`:
```
A11y Audit — WCAG 2.2 AA (S Gate)
-----------------------------------
No violations found.
-----------------------------------
Status: PASS
```

---

## Phase 6: Write Output

Crear `.king/castle/` si no existe. Escribir `.king/castle/a11y-report.json`:

```json
{
  "violations": [
    {
      "element": "<img src='hero.jpg' />",
      "impact": "critical",
      "wcag": "1.1.1",
      "wcag_url": "https://www.w3.org/WAI/WCAG22/Understanding/non-text-content",
      "description": "Image missing alt text",
      "file": "src/components/Hero.jsx",
      "line": 42
    }
  ],
  "summary": {
    "critical": 1,
    "serious": 0,
    "moderate": 0,
    "minor": 0
  },
  "enforcement": "block",
  "status": "fail",
  "checked_at": "2025-01-15T14:30:00Z"
}
```

**Schema INMUTABLE** — este contrato es consumido por `/castle-report` (M-34). No agregar ni remover campos de primer nivel.

---

## Phase 7: Enforce Gate

```
SI enforcement == "block" AND (critical > 0 OR serious > 0):
  → exit 2

SI enforcement == "warn" OR (critical == 0 AND serious == 0):
  → exit 0
```

---

## FINAL CHECKPOINT

- [ ] `a11y-report.json` escrito en `.king/castle/`
- [ ] Schema correcto: `violations[]`, `summary`, `enforcement`, `status`, `checked_at`
- [ ] `rules/accessibility-gate.md` NO fue modificado
- [ ] Grace period respetado: sin `.king/accessibility.yaml` → exit 0

---

## Execution Summary

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `SKIPPED` \| `BLOCKED` |
| Violations | _(N critical, M serious, ...)_ |
| Artifacts | `.king/castle/a11y-report.json` |
| Next Recommended | Si `status: fail`: ejecutar `/a11y-fix`; si `status: pass`: continuar flujo normal |
| Risks | Violations moderate/minor no bloquean pero reducen CASTLE S sub-score |
