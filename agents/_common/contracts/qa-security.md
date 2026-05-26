# QA-Security Contract

## Propósito
Define el protocolo de interacción entre @qa y @security para coordinación del Security Gate, deep reviews, y gestión de findings de seguridad.

> **Nota:** Este contrato complementa `security/qa-security-integration.md`
> que define el orden de ejecución y precedencia de resultados.
> Este documento se enfoca en formatos de comunicación y protocolos de handoff.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Deep review en env mode | @qa | @security | Invocation | Sí |
| Security finding report | @security | @qa | Report | Sí |
| Dispute: finding vs false positive | @qa | @security | Consultation | Sí |
| Remediation guidance request | @qa | @security | Consultation | No |
| Security Gate escalation | @qa | @security | Escalation | Sí |

---

## Deep Review Invocation (QA → Security)

### Cuándo usar
- `/qa --env qa` en modo ENV
- @security fue activado durante `/genesis`
- Security Gate básico ya fue ejecutado

### Invocation Format (@qa → @security)

```yaml
# Deep Review Invocation
type: "deep_review_request"
from: "@qa"
to: "@security"
timestamp: "{ISO}"
context:
  skill: "/qa --env qa"
  environment: "qa"
  scope: "full_codebase"

gate_results:
  executed: true
  result: "PASS|FAIL"
  checks:
    secrets: "PASS|FAIL"
    dependencies: "PASS|FAIL"
    code_patterns: "PASS|FAIL"
    sensitive_files: "PASS|FAIL"
  notes: "{Notas relevantes del Gate}"

project_context:
  type: "{web app|API|CLI|library}"
  stack: "{stack tecnológico}"
  compliance: ["{GDPR|HIPAA|PCI|SOC2|none}"]
  features_included: ["{features promovidos a qa}"]

review_scope:
  - "STRIDE Threat Modeling"
  - "OWASP Top 10 verification"
  - "Auth/AuthZ review"
  - "Secrets management audit"
  - "Compliance check"
  - "Cross-feature attack surface"
  - "Dependency supply chain"

output_expected: "Security Review Report"
blocking: true
```

### Report Format (@security → @qa)

```yaml
# Security Review Report
type: "deep_review_report"
from: "@security"
to: "@qa"
timestamp: "{ISO}"
in_response_to: "{request_timestamp}"

executive_summary: |
  {1-2 oraciones con resultado general}

result: "PASS|FAIL"

findings:
  - id: "SEC-{N}"
    severity: "{CRITICAL|HIGH|MEDIUM|LOW}"
    category: "{STRIDE|OWASP|Compliance|Supply Chain}"
    location: "{path:line}"
    description: |
      {Descripción del hallazgo}
    evidence: |
      {Código o configuración problemática}
    mitigation: |
      {Recomendación concreta}
    effort: "{LOW|MEDIUM|HIGH}"

metrics:
  critical: 0
  high: 0
  medium: 0
  low: 0
  total: 0

recommendations:
  - priority: 1
    description: "{Recomendación más urgente}"
  - priority: 2
    description: "{Segunda recomendación}"

compliance_status:
  gdpr: "{COMPLIANT|NON_COMPLIANT|N_A}"
  hipaa: "{COMPLIANT|NON_COMPLIANT|N_A}"
  pci: "{COMPLIANT|NON_COMPLIANT|N_A}"
```

---

## Security Gate Escalation

### Cuándo @qa escala a @security
- Security Gate falla repetidamente y @developer no puede resolverlo
- Pattern detection flag parece ser falso positivo pero @qa no puede confirmar
- Dependency vulnerability sin fix disponible

### Escalation Format (@qa → @security)

```yaml
# Gate Escalation
type: "gate_escalation"
from: "@qa"
to: "@security"
timestamp: "{ISO}"

failed_check: "{Secrets|Dependencies|Code Patterns|Sensitive Files}"
details: |
  {Qué detectó el Gate}

developer_context: |
  {Qué dice @developer sobre el finding}

question: |
  {Pregunta específica: ¿es falso positivo? ¿hay workaround seguro?}

blocking: true
```

### Response Format (@security → @qa)

```yaml
# Gate Escalation Response
type: "gate_escalation_response"
from: "@security"
to: "@qa"

verdict: "{CONFIRM_FINDING|FALSE_POSITIVE|NEEDS_EXCEPTION}"

justification: |
  {Por qué es o no es un problema real}

action:
  if_confirm: |
    {Qué debe hacer @developer para resolverlo}
  if_false_positive: |
    {Agregar a security/exceptions.yml con razón}
  if_exception: |
    {Documentar bypass temporal con fecha de expiración}

exception_template:
  file: "{path en exceptions.yml}"
  pattern: "{patrón a exceptuar}"
  reason: "{justificación}"
  expires: "{ISO date}"
  approved_by: "@security"
```

---

## Dispute Resolution

### Cuándo @qa disputa un finding de @security
- @qa cree que un finding es falso positivo
- @qa cree que la severidad es incorrecta
- @qa cree que la mitigación no es viable

### Format (@qa → @security)

```yaml
# Dispute
type: "dispute"
from: "@qa"
to: "@security"
finding_id: "SEC-{N}"

dispute_type: "{FALSE_POSITIVE|SEVERITY_OVERRIDE|MITIGATION_INFEASIBLE}"

argument: |
  {Por qué @qa disputa este finding}

evidence: |
  {Evidencia que soporta la disputa}
```

```yaml
# Dispute Resolution
type: "dispute_resolution"
from: "@security"

finding_id: "SEC-{N}"
original_severity: "{severity}"
resolution: "{UPHELD|DOWNGRADED|DISMISSED}"
new_severity: "{severity|null}"

justification: |
  {Razonamiento de la decisión}

# @security tiene veto en temas de seguridad
final: true
```

**Regla:** @security tiene la última palabra en disputas de seguridad. Si @qa no está de acuerdo con la resolución, escala a usuario.

---

## Remediation Guidance

### Cuándo @qa pide guidance a @security
- Necesita explicar a @developer cómo corregir un finding
- Necesita contexto adicional sobre un finding para el reporte

### Format (simplificado)

```yaml
# Remediation Query
type: "quick"
from: "@qa"
to: "@security"
finding_id: "SEC-{N}"
question: "{Pregunta específica sobre remediación}"
blocking: false
```

```yaml
# Remediation Response
type: "quick_response"
from: "@security"
remediation_steps:
  1. "{Paso concreto}"
  2. "{Paso concreto}"
code_example: |
  {Código de ejemplo si aplica}
```

---

## Iteration Loop

### Máximo 1 disputa por finding

```
@security report → @qa acepta o disputa
  → Si disputa: @security resuelve (final)
  → Si @qa aún no está de acuerdo: escalar a usuario
```

**No hay ciclos infinitos.** @security tiene veto, @qa puede escalar a usuario.

---

## Timeouts y Fallbacks

| Situación | Timeout | Fallback |
|-----------|---------|----------|
| Deep review sin respuesta | N/A (blocking) | @qa registra: "Deep review no completado" y procede solo con Gate básico |
| Gate escalation sin respuesta | N/A (blocking) | Escalar a usuario |
| Dispute sin resolución | N/A (blocking) | @security resuelve o escalar a usuario |
| @security no disponible | N/A | Solo Security Gate básico + warning en sesión |

---

## Ver también

- **QA-Security Integration**: `security/qa-security-integration.md` (orden de ejecución y precedencia)
- **Security Gate**: `security/SECURITY-GATE.md`
- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **Developer-QA Contract**: `agents/_common/contracts/developer-qa.md`
