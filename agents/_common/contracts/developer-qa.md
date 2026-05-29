# Developer-QA Contract

## Propósito
Define el protocolo de interacción entre @developer y @qa para feedback de tests, correcciones y ciclos de re-validación.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| QA rechaza implementación | @qa | @developer | Feedback | Sí |
| Developer corrige y pide re-test | @developer | @qa | Re-validation | Sí |
| QA aprueba condicionalmente | @qa | @developer | Conditional | No |
| Consulta de testabilidad | @developer | @qa | Quick Consultation | No |
| Cobertura insuficiente | @qa | @developer | Feedback | Sí |

---

## QA Feedback (QA → Developer)

### Cuándo usar
- Tests fallan para uno o más ACs
- Security Gate detecta problemas en código del developer
- Cobertura de tests es insuficiente
- Calidad de código no cumple estándares

### Feedback Format (@qa → @developer)

```yaml
# QA Feedback
type: "qa_feedback"
from: "@qa"
to: "@developer"
timestamp: "{ISO}"
context:
  skill: "/qa"
  issue: "#{number}"
  result: "FAILED|CONDITIONAL"

summary: |
  {Resumen en 1-2 líneas del resultado}

failures:
  - ac: "AC-{N}"
    description: "{Qué falló}"
    evidence: "{Test output o detalle}"
    severity: "{BLOCKER|MAJOR|MINOR}"
    suggested_fix: |
      {Sugerencia concreta de cómo arreglar}
  - ac: "AC-{N}"
    description: "{Qué falló}"
    evidence: "{Detalle}"
    severity: "{BLOCKER|MAJOR|MINOR}"
    suggested_fix: |
      {Sugerencia}

security_findings:
  - check: "{Secrets|Dependencies|Code Patterns|Sensitive Files}"
    description: "{Qué se detectó}"
    file: "{path:line}"
    fix_required: true

coverage_gaps:
  - module: "{path}"
    current: "{N}%"
    expected: "{N}%"
    missing: ["{caso no cubierto}"]

action_required: "fix_and_resubmit"
blocking: true
```

### Response Format (@developer → @qa)

```yaml
# Fix Submission
type: "fix_submission"
from: "@developer"
to: "@qa"
timestamp: "{ISO}"
in_response_to: "{feedback_timestamp}"

fixes_applied:
  - ac: "AC-{N}"
    fix_description: "{Qué se cambió}"
    files_modified:
      - path: "{path}"
        changes: "{resumen del cambio}"
    tests_added: ["{test name}"]
    verified_locally: true

security_fixes:
  - check: "{check name}"
    fix: "{Qué se hizo}"
    file: "{path}"

coverage_changes:
  - module: "{path}"
    before: "{N}%"
    after: "{N}%"

ready_for_retest: true
```

---

## Conditional Approval

### Cuándo @qa aprueba condicionalmente
- Tests pasan pero cobertura es borderline
- Issues menores que no bloquean merge
- Sugerencias de mejora opcionales

### Format (@qa → @developer)

```yaml
# Conditional Approval
type: "conditional_approval"
from: "@qa"
to: "@developer"
result: "CONDITIONAL"

approved_acs: ["AC-1", "AC-2", "AC-3"]

conditions:
  - type: "{MUST_FIX|SHOULD_FIX|NICE_TO_HAVE}"
    description: "{Qué mejorar}"
    deadline: "{before_merge|next_sprint|backlog}"

notes: |
  {Contexto adicional}

action_required: "address_conditions"
blocking: false
```

---

## Quick Consultation (Developer → QA)

### Cuándo usar
- Preguntar si algo es testeable antes de implementar
- Confirmar estrategia de testing
- Preguntar sobre mocks/fixtures necesarios

### Format (simplificado)

```yaml
# Quick Consultation
type: "quick"
from: "@developer"
to: "@qa"
question: "{Pregunta directa}"
context: "{Contexto mínimo}"
blocking: false
```

```yaml
# Quick Response
type: "quick_response"
from: "@qa"
answer: "{Respuesta directa}"
testing_recommendation: "{Sugerencia de approach}"
```

---

## Iteration Loop

### Máximo 2 ciclos fix-retest

```
@qa feedback → @developer fix → @qa re-test (ciclo 1)
  → Si falla de nuevo:
@qa feedback → @developer fix → @qa re-test (ciclo 2)
  → Si falla de nuevo: escalar a usuario
```

**Regla:** Después de 2 ciclos sin resolución, @qa escala a usuario con:
- Historial de los 2 ciclos
- Qué sigue fallando y por qué
- Recomendación: refactorizar, cambiar approach, o aceptar deuda técnica

---

## Señales de Escalación

### @developer debe consultar @qa cuando:

| Señal | Ejemplo | Acción |
|-------|---------|--------|
| No sabe cómo testear algo | "¿Cómo testeo este efecto?" | Quick Consultation |
| Quiere cambiar test strategy | "¿Puedo usar snapshots aquí?" | Quick Consultation |
| Test flakey | "Este test falla intermitente" | Quick Consultation |

### @qa escala a @developer cuando:

| Señal | Ejemplo | Acción |
|-------|---------|--------|
| AC falla | "AC-2 no se cumple" | QA Feedback |
| Security Gate falla | "Detecté SQL injection" | QA Feedback |
| Cobertura baja | "Módulo X sin tests" | QA Feedback |

### @qa escala a usuario cuando:

| Señal | Ejemplo |
|-------|---------|
| 2 ciclos sin resolver | "Developer no puede arreglar AC-2 en 2 intentos" |
| AC parece incorrecto | "AC-3 contradice AC-1" |
| Bloqueo técnico | "No es posible testear esto sin infraestructura" |

---

## Timeouts y Fallbacks

| Situación | Timeout | Fallback |
|-----------|---------|----------|
| QA Feedback sin fix | N/A (blocking) | Escalar a usuario |
| Re-test sin resultado | N/A (blocking) | Escalar a usuario |
| Quick Consultation sin respuesta | Continuar sin | Usar approach conservador |
| 2 ciclos agotados | N/A | Escalar a usuario |

---

## Ver también

- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **Developer-Architect Contract**: `agents/_common/contracts/developer-architect.md`
- **QA-Security Integration**: `security/qa-security-integration.md`
