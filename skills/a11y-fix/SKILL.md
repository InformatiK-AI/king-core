---
name: a11y-fix
version: 1.0
api_version: 1.0.0
description: "Remedia violaciones de accesibilidad encontradas por /a11y-audit. Lee a11y-report.json y aplica fixes automáticos donde sea posible."
---

# A11y Fix — Accessibility Remediation

Lee `.king/castle/a11y-report.json` producido por `/a11y-audit` y aplica remediaciones automáticas donde es posible. Para violations no auto-fixables, genera instrucciones manuales específicas. Re-invoca `/a11y-audit` al terminar para verificar.

> **Prerequisito**: `/a11y-audit` debe haber sido ejecutado primero.

---

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Si alguna es TRUE, DETENER inmediatamente con el resultado indicado

- [ ] `.king/castle/a11y-report.json` no existe → error: "Run /a11y-audit first — a11y-report.json not found"
- [ ] `violations: []` en el report → "No violations to fix — a11y is clean. Run /a11y-audit to confirm current state."

### ABSOLUTE RESTRICTIONS
> Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA hacer cambios de estilo o refactoring más allá del fix de accesibilidad
- NUNCA agregar alt text genérico como `alt="image"` o `alt="foto"` — debe ser descriptivo del contenido
- NUNCA crear excepciones en `.king/accessibility.yaml` sin aprobación explícita del usuario
- NUNCA modificar `rules/accessibility-gate.md`

### REQUIRED OUTPUTS

- [ ] Resumen de fixes aplicados y pendientes en terminal
- [ ] Re-ejecución de `/a11y-audit` al final para verificar

### PHASES OVERVIEW

```
Phase 1: Read Report       → leer .king/castle/a11y-report.json
Phase 2: Auto-Fix          → aplicar remediaciones automáticas por tipo de violation
Phase 3: Manual List       → listar violations no auto-fixables con instrucciones
Phase 4: Verify            → re-invocar /a11y-audit
Phase 5: Report            → mostrar "N fixed, M remaining"
FINAL CHECKPOINT
Execution Summary
```

---

## Phase 1: Read Report

Leer `.king/castle/a11y-report.json`.

- Si no existe → BLOCKING: "Run /a11y-audit first — a11y-report.json not found"
- Si `violations: []` → "No violations to fix — a11y is clean."
- Si `status: "skipped"` → "A11y audit was skipped (no config or no UI). Run /a11y-audit to get a full report."

---

## Phase 2: Auto-Fix

Para cada violation en `violations[]`, aplicar la remediación automática según el tipo:

### Fix: `<img>` sin alt text (WCAG 1.1.1)

**Detectar**: `impact: "critical"`, criterio 1.1.1

**Auto-fix**:
1. Extraer el nombre del archivo del `src` (e.g., `hero.jpg` → "Hero image")
2. Si el elemento está dentro de un `<figure>` con `<figcaption>` → usar el texto del caption como alt
3. Si es imagen decorativa pura (nombre contiene: `bg`, `background`, `divider`, `separator`) → agregar `alt=""`  + `role="presentation"`
4. Caso general → generar alt descriptivo basado en filename: `src="team-photo.jpg"` → `alt="Team photo"`
5. Insertar el atributo `alt` en el elemento encontrado en `file` + `line`

### Fix: Button/link sin nombre accesible (WCAG 2.4.6)

**Detectar**: `impact: "serious"`, criterio 2.4.6

**Auto-fix**:
1. Analizar el contenido del elemento:
   - Solo icono SVG sin texto → agregar `aria-label` basado en el nombre del icono o contexto del botón
   - Solo emoji → agregar `aria-label` con descripción del emoji + acción (e.g., `aria-label="Confirmar"`)
2. Si es `<a>` sin texto → agregar `aria-label` basado en el `href` o contexto circundante

### Fix: Form control sin label (WCAG 1.3.1)

**Detectar**: `impact: "serious"`, criterio 1.3.1

**Auto-fix**:
1. Verificar si el input tiene `id`
2. Si tiene `id` → generar `<label for="{id}">` antes del input con texto humanizado del `id` o `name` (e.g., `id="email"` → `<label for="email">Email</label>`)
3. Si no tiene `id` → agregar `id` generado + `<label for="{id}">` correspondiente
4. Si ya existe label por `aria-label` o `aria-labelledby` → skip (falso positivo)

### Fix: Heading hierarchy (WCAG 2.4.6)

**Detectar**: `impact: "moderate"`, criterio 2.4.6, description contiene "heading hierarchy"

**Auto-fix**:
1. Listar todos los headings del archivo en orden
2. Identificar el salto (e.g., h1 → h3)
3. Si el h3 puede ser h2 semánticamente → cambiar a h2
4. Si la jerarquía es intencional por diseño → NO tocar; agregar a lista de fixes manuales

### NO auto-fixable (lista manual)

Las siguientes violations requieren intervención humana:

- **WCAG 1.4.3** (color contrast): No se puede calcular el ratio de contraste sin renderizar. Proveer instrucción: "Verify contrast ratio between foreground `{color}` and background `{color}` using https://webaim.org/resources/contrastchecker/ — minimum 4.5:1 for normal text, 3:1 for large text"
- **WCAG 4.1.2** (div interactivo sin role): Requiere decisión arquitectónica. Proveer instrucción: "Add `role='button'` + `tabindex='0'` + keyboard event handlers (`onKeyDown`) to `{element}` in `{file}:{line}`"
- Cualquier violation donde el contexto semántico no sea determinable sin ejecutar el componente

---

## Phase 3: Manual List

Para violations no auto-fixadas, mostrar lista estructurada:

```
Manual fixes required:
----------------------
1. [WCAG 1.4.3] src/components/Button.jsx:15
   Verify contrast: color #999 on #fff — use https://webaim.org/resources/contrastchecker/
   Minimum ratio: 4.5:1 (normal text) | 3:1 (large text, 18px+ or 14px+ bold)

2. [WCAG 4.1.2] src/components/Dropdown.jsx:33
   Add role="button" tabindex="0" onKeyDown handler to <div onClick={...}>
```

---

## Phase 4: Verify

Re-invocar `/a11y-audit` después de aplicar todos los auto-fixes para confirmar el estado.

---

## Phase 5: Report

Mostrar resumen final:

```
A11y Fix — Results
-------------------
Auto-fixed:  3 violations
Remaining:   2 violations (manual action required — see list above)
-------------------
Re-running /a11y-audit to verify...
[resultado de /a11y-audit]
```

---

## FINAL CHECKPOINT

- [ ] Cada auto-fix aplicado referenciado por `file` + `line` del report
- [ ] Lista de fixes manuales con instrucciones específicas y accionables
- [ ] `/a11y-audit` re-invocado al final
- [ ] NUNCA agregado alt text genérico (`alt="image"`)

---

## Execution Summary

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| Fixed | _(N auto-fixed)_ |
| Remaining | _(M manual)_ |
| Artifacts | `.king/castle/a11y-report.json` (actualizado por /a11y-audit post-fix) |
| Next Recommended | Si remaining > 0: aplicar fixes manuales + re-ejecutar `/a11y-fix`; si remaining == 0: `/promote` |
