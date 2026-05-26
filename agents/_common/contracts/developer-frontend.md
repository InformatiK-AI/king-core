# Developer-Frontend Contract

## Propósito
Define el protocolo de interacción entre @developer y @frontend para implementación accesible, consultas de patrones ARIA y validación de WCAG compliance durante desarrollo.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Implementación de componente UI | @developer | @frontend | Consultation | No |
| Violación WCAG A detectada | @frontend | @developer | Remediation | Sí |
| Violación WCAG AA detectada | @frontend | @developer | Recommendation | No |
| Patrón ARIA complejo | @developer | @frontend | Quick Consultation | No |
| Implementación de formulario | @developer | @frontend | Pre-Implementation | No |

---

## Pre-Implementation Consultation

### Cuándo usar
- Antes de implementar componentes interactivos complejos (modales, tabs, dropdowns)
- Cuando se crean formularios con validación
- Cuando se implementan notificaciones o contenido dinámico
- Cuando el componente tiene estados visuales que comunican información

### Request Format (@developer → @frontend)

```yaml
# Accessibility Consultation
type: "a11y_consultation"
from: "@developer"
to: "@frontend"
timestamp: "{ISO}"
context:
  skill: "/{skill}"
  issue: "#{number}"
  component: "{ComponentName}"

description: |
  {Qué componente se va a implementar}

ui_elements:
  - type: "{form|modal|tab|dropdown|notification|table}"
    interactions: ["{click|keyboard|hover|focus}"]
    dynamic_content: true|false

question: |
  {Pregunta específica sobre accesibilidad}

blocking: false
```

### Response Format (@frontend → @developer)

```yaml
# Accessibility Guidance
type: "a11y_guidance"
from: "@frontend"
to: "@developer"
timestamp: "{ISO}"

component: "{ComponentName}"

aria_pattern:
  role: "{role requerido}"
  attributes:
    - name: "{aria-attribute}"
      value: "{value}"
      reason: "{por qué es necesario}"
  keyboard:
    - key: "{Tab|Enter|Escape|Arrow}"
      action: "{qué debe hacer}"

html_semantics: |
  {Elemento HTML semántico recomendado vs div genérico}

focus_management: |
  {Cómo manejar focus si aplica}

checklist:
  - "[ ] {Verificación específica para este componente}"
```

---

## Remediation (UX-Accessibility → Developer)

### Cuándo usar
- Accessibility audit detecta violación WCAG nivel A (bloqueante)
- Accessibility audit detecta violación WCAG nivel AA (importante)

### Finding Format (@frontend → @developer)

```yaml
# Accessibility Finding
type: "a11y_finding"
from: "@frontend"
to: "@developer"
timestamp: "{ISO}"

finding:
  wcag_criterion: "{N.N.N}"
  level: "{A|AA|AAA}"
  severity: "{BLOQUEANTE|IMPORTANTE|RECOMENDADO}"
  location: "{path:line}"
  description: |
    {Qué violación se encontró}
  impact: |
    {Quién se ve afectado y cómo}
  fix: |
    {Cómo remediar con código concreto}

blocking: true  # Solo para nivel A
```

### Fix Confirmation (@developer → @frontend)

```yaml
# Accessibility Fix
type: "a11y_fix"
from: "@developer"
to: "@frontend"
in_response_to: "{finding_timestamp}"

fix_applied:
  location: "{path:line}"
  changes: |
    {Qué se cambió}
  tested:
    keyboard_navigation: true|false
    screen_reader: true|false

ready_for_recheck: true
```

---

## Quick Consultation

### Cuándo usar
- Verificar si un patrón ARIA es correcto
- Preguntar qué role usar para un componente
- Confirmar si el contraste es suficiente
- Preguntar sobre focus management

### Format (simplificado)

```yaml
# Quick A11y Consultation
type: "quick"
from: "@developer"
to: "@frontend"
question: "{Pregunta directa}"
code_snippet: |
  {HTML/JSX relevante si aplica}
blocking: false
```

---

## Iteration Loop

### Máximo 2 ciclos para findings bloqueantes (WCAG A)

```
@frontend finding → @developer fix → @frontend verify (ciclo 1)
  → Si persiste:
@frontend finding → @developer fix → @frontend verify (ciclo 2)
  → Si persiste: escalar a usuario
```

Para findings WCAG AA: no hay iteración forzada, se documentan como recomendaciones.

---

## Señales de Escalación

### @developer consulta @frontend cuando:

| Señal | Ejemplo | Acción |
|-------|---------|--------|
| Componente interactivo | "¿Qué ARIA role uso para este widget?" | Quick Consultation |
| Formulario complejo | "¿Cómo hago accesible este multi-step form?" | Pre-Implementation |
| Contenido dinámico | "¿Necesito aria-live para este toast?" | Quick Consultation |

### @frontend escala a usuario cuando:

| Señal | Ejemplo |
|-------|---------|
| Trade-off UX vs diseño | "El diseño pedido no permite contraste suficiente" |
| 2 ciclos sin resolver WCAG A | "Developer no logra hacer el componente accesible" |
| Requisito contradice a11y | "Feature requiere autoplay que viola WCAG" |

---

## Timeouts y Fallbacks

| Situación | Timeout | Fallback |
|-----------|---------|----------|
| WCAG A finding sin fix | Blocking | Escalar a usuario |
| WCAG AA finding sin fix | No blocking | Documentar como deuda técnica |
| Quick Consultation sin respuesta | Continuar sin | Usar HTML semántico + patrones básicos ARIA |
| @frontend no activado | N/A | Basic Accessibility Gate en /qa (4 checks) |

---

## Ver también

- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **Frontend Agent**: `agents/frontend.md`
- **Developer-QA Contract**: `agents/_common/contracts/developer-qa.md`
- **Knowledge**: `knowledge/universal/accessibility.md`
