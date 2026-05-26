# Developer-Architect Contract

## Propósito
Define el protocolo de interacción entre @developer y @architect para consultas de factibilidad y decisiones arquitectónicas.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Decisión de arquitectura | @developer | @architect | Pre-Decision | Sí |
| Validación de approach | @developer | @architect | Quick Consultation | No |
| Cambio de patrón | @architect | @developer | Post-Decision | Sí |
| Trade-off técnico | @developer | @architect | Pre-Decision | Sí |
| Refactor significativo | @developer | @architect | Pre-Decision | Sí |
| Feedback de implementación | @developer | @architect | Iteration | No |

---

## Pre-Decision Consultation

### Cuándo usar
- Antes de implementar algo que afecta arquitectura
- Cuando hay múltiples approaches válidos
- Cuando el approach tiene implicaciones de largo plazo
- Cuando el approach afecta otros módulos/features

### Request Format (@developer → @architect)

```yaml
# Pre-Decision Consultation Request
type: "pre_decision"
from: "@developer"
to: "@architect"
timestamp: "{ISO}"
context:
  skill: "/{skill}"
  issue: "#{number}"
  phase: "{implementation_phase}"

question: |
  {Descripción clara de la decisión necesaria}

current_understanding:
  - "{Lo que ya sé del problema}"
  - "{Constraints que conozco}"

options_considered:
  - name: "{Option A}"
    description: "{Qué implica}"
    pros: ["{pro1}", "{pro2}"]
    cons: ["{con1}", "{con2}"]
    effort: "{LOW|MEDIUM|HIGH}"
  - name: "{Option B}"
    description: "{Qué implica}"
    pros: ["{pro1}"]
    cons: ["{con1}"]
    effort: "{LOW|MEDIUM|HIGH}"

preferred: "{Option A|B|none}"  # Si tienes preferencia
reason_for_preference: "{Por qué}"

urgency: "{CRITICAL|HIGH|MEDIUM|LOW}"
blocking: true  # No continúo hasta tener respuesta
```

### Response Format (@architect → @developer)

```yaml
# Pre-Decision Consultation Response
type: "pre_decision_response"
from: "@architect"
to: "@developer"
timestamp: "{ISO}"
in_response_to: "{request_timestamp}"

decision: "{Option elegida}"
confidence: "{HIGH|MEDIUM|LOW}"

justification: |
  {Por qué esta opción es la mejor}

trade_offs_accepted:
  - "{Trade-off 1 y por qué es aceptable}"
  - "{Trade-off 2}"

implementation_guidance:
  pattern: "{Nombre del patrón}"
  key_files:
    - path: "{path}"
      role: "{qué hace}"
  steps:
    1. "{Paso 1}"
    2. "{Paso 2}"
  watch_out_for:
    - "{Cosa a evitar}"

adr_created: "{path to ADR|null}"  # Si la decisión merece ADR

follow_up_needed: false
follow_up_reason: "{Si true, qué más se necesita}"

return_to_developer:
  action: "continue_implementation"
  with_guidance: true
```

---

## Iteration Loop

### Máximo 2 iteraciones

Si después de la respuesta inicial hay dudas:

```yaml
# Iteration Request
type: "iteration"
iteration: 1  # o 2
from: "@developer"
to: "@architect"
original_decision: "{referencia}"

clarification_needed: |
  {Qué no quedó claro}

specific_question: |
  {Pregunta puntual}

code_context: |
  {Snippet relevante si aplica}
```

```yaml
# Iteration Response
type: "iteration_response"
iteration: 1
from: "@architect"
to: "@developer"

clarification: |
  {Respuesta a la duda}

adjusted_guidance: |
  {Si algo cambió en la guía}

final: true  # Si esto resuelve todo
```

**Regla:** Después de 2 iteraciones, si no hay claridad, escalar a usuario.

---

## Quick Consultation (Sync)

### Cuándo usar
- Validar un approach que ya decidiste
- Confirmar que algo no viola arquitectura
- Preguntas simples de "¿esto está bien?"

### Format (simplificado)

```yaml
# Quick Consultation
type: "quick"
from: "@developer"
question: "{Pregunta directa}"
context: "{Contexto mínimo}"
blocking: false
```

```yaml
# Quick Response
type: "quick_response"
from: "@architect"
answer: "{YES|NO|DEPENDS}"
note: "{Nota breve si aplica}"
```

---

## Post-Decision Handback

### Cuándo @architect devuelve a @developer

Después de tomar una decisión, @architect entrega:

```yaml
# Post-Decision Handback
type: "handback"
from: "@architect"
to: "@developer"
decision_ref: "{ADR-id o timestamp}"

summary: |
  {Resumen de la decisión en 2-3 líneas}

your_next_steps:
  1. "{Acción concreta 1}"
  2. "{Acción concreta 2}"
  3. "{Acción concreta 3}"

files_to_create:
  - path: "{path}"
    purpose: "{para qué}"
    pattern: "{patrón a seguir}"

files_to_modify:
  - path: "{path}"
    changes: "{qué cambiar}"

dependencies:
  - "{Dependencia si hay}"

tests_expected:
  - "{Tipo de test}"
  - "{Coverage esperado}"

definition_of_done:
  - "{Criterio 1}"
  - "{Criterio 2}"

escalate_back_if:
  - "{Condición para volver a consultar}"
```

---

## Señales de Escalación

### @developer debe consultar @architect cuando:

| Señal | Ejemplo | Acción |
|-------|---------|--------|
| Nuevo patrón | "No hay ejemplo de esto en el codebase" | Pre-Decision |
| Múltiples formas | "Podría usar X o Y" | Pre-Decision |
| Afecta otros módulos | "Esto cambiaría cómo funciona Z" | Pre-Decision |
| Performance concern | "Esto podría ser lento con muchos datos" | Quick Consultation |
| Breaking change | "Esto rompe la API actual" | Pre-Decision |
| Nueva dependencia | "Necesito agregar librería X" | Quick Consultation |

### @developer NO necesita consultar cuando:

| Situación | Por qué |
|-----------|---------|
| Seguir patrón existente | Ya hay decisión previa |
| Bug fix simple | No afecta arquitectura |
| Refactor local | No afecta otros módulos |
| Tests | Responsabilidad de @developer |
| Estilo de código | Hay reglas definidas |

---

## Timeouts y Fallbacks

| Situación | Timeout | Fallback |
|-----------|---------|----------|
| Pre-Decision sin respuesta | N/A (blocking) | Escalar a usuario |
| Quick Consultation sin respuesta | Continuar sin | Usar approach conservador |
| Iteration 3+ | N/A | Escalar a usuario |

---

## Ejemplos

### Ejemplo: Decisión de caché

**@developer:**
```yaml
type: "pre_decision"
question: "¿Dónde almacenar tokens de sesión?"
options_considered:
  - name: "Redis"
    pros: ["Distribuido", "TTL"]
    cons: ["Nueva infra"]
  - name: "Memory"
    pros: ["Simple"]
    cons: ["No persiste"]
preferred: "Redis"
urgency: "HIGH"
```

**@architect:**
```yaml
type: "pre_decision_response"
decision: "Memory + httpOnly cookie para refresh"
justification: "No necesitamos Redis aún. Memoria para access, cookie para refresh."
implementation_guidance:
  pattern: "Dual-token"
  steps:
    1. "Crear TokenContext"
    2. "Implementar refresh endpoint"
adr_created: "king-framework/docs/architecture/ADR-008.md"
```

---

## Ver también

- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **RADAR Protocol**: `agents/_common/protocols/radar.md`
