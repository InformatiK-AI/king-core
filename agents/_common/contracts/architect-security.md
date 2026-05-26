# Architect-Security Contract

## Propósito
Define el protocolo de interacción entre @architect y @security para decisiones de diseño con implicaciones de seguridad, threat modeling y validación de superficies de ataque.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Nuevo flujo de datos sensibles | @architect | @security | Pre-Design | Sí |
| Hallazgo CRITICAL durante review | @security | @architect | Escalation | Sí |
| Cambio en autenticación/autorización | @architect | @security | Pre-Design | Sí |
| Nueva dependencia externa | @architect | @security | Quick Consultation | No |
| Threat model de componente nuevo | @architect | @security | Collaboration | No |

---

## Pre-Design Security Review

### Cuándo @architect consulta @security
- Antes de diseñar cualquier flujo que maneje autenticación, autorización o secrets
- Antes de introducir un nuevo punto de entrada externo (API, webhook, file upload)
- Cuando el diseño implica almacenamiento de datos sensibles

### Request Format (@architect → @security)

```yaml
type: "pre_design_security_review"
from: "@architect"
to: "@security"

component: "{Nombre del componente o flujo}"
data_flow: |
  {Descripción del flujo de datos sensibles}

threat_surface:
  external_inputs: ["{Fuentes de input externo}"]
  sensitive_data: ["{Tipos de datos sensibles}"]
  auth_required: true|false

design_options:
  - name: "{Opción A}"
    description: "{Cómo funciona}"
  - name: "{Opción B}"
    description: "{Cómo funciona}"

question: |
  {Pregunta específica de seguridad}
```

### Response Format (@security → @architect)

```yaml
type: "pre_design_security_response"
from: "@security"
to: "@architect"

threats_identified:
  - category: "{OWASP A0X}"
    stride: "{S|T|R|I|D|E}"
    description: "{Amenaza}"
    cvss_estimate: "{score}"
    applies_to: "{Opción A|B|ambas}"

recommendation:
  preferred_option: "{Opción A|B}"
  justification: |
    {Por qué desde perspectiva de seguridad}
  mitigations_required:
    - "{Mitigación 1 obligatoria}"
    - "{Mitigación 2}"

verdict: "APPROVED | CONDITIONAL | BLOCKED"
```

---

## Escalation: @security → @architect (Hallazgos Estructurales)

### Cuándo @security escala a @architect
- Hallazgo CRITICAL (CVSS ≥9.0) causado por decisión arquitectónica
- Dependency direction que crea superficie de ataque
- Pattern de diseño que es sistemáticamente inseguro

### Escalation Format

```yaml
type: "security_architectural_escalation"
from: "@security"
to: "@architect"
severity: "CRITICAL|HIGH"

finding: |
  {Descripción del hallazgo}

root_cause: |
  {Cómo la arquitectura causa este problema}

architectural_change_required: |
  {Qué debe cambiar en el diseño}

blocking: true  # Merge bloqueado hasta resolución
```

---

## Ver también

- **Developer-Security Contract**: `contracts/developer-security.md`
- **QA-Security Contract**: `contracts/qa-security.md`
- **Escalation Matrix**: `_common/escalation-matrix.md`
- **Security Gate**: `../../security/SECURITY-GATE.md`
