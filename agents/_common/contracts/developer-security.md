# Developer-Security Contract

## Propósito
Define el protocolo de interacción entre @developer y @security para remediación de vulnerabilidades, consultas de código seguro y validación de patrones de seguridad.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Código con datos sensibles | @developer | @security | Consultation | No |
| Remediación de finding | @security | @developer | Remediation | Sí |
| Validación de patrón seguro | @developer | @security | Quick Consultation | No |
| Implementación de auth/crypto | @developer | @security | Pre-Implementation | Sí |
| Bypass de Security Gate | @developer | @security | Escalation | Sí |

---

## Pre-Implementation Consultation

### Cuándo usar
- Antes de implementar autenticación, autorización o criptografía
- Cuando se manejan datos sensibles (PII, tokens, passwords)
- Cuando se integran APIs de pago o servicios de terceros con credenciales
- Cuando se implementa sanitización de inputs

### Request Format (@developer → @security)

```yaml
# Pre-Implementation Security Consultation
type: "pre_implementation"
from: "@developer"
to: "@security"
timestamp: "{ISO}"
context:
  skill: "/{skill}"
  issue: "#{number}"

description: |
  {Qué se va a implementar y por qué necesita revisión de seguridad}

sensitive_data:
  - type: "{PII|credentials|tokens|payment}"
    handling: "{cómo se planea manejar}"

approach_considered:
  - name: "{Approach}"
    description: "{Detalle}"
    security_concern: "{Qué preocupa}"

blocking: true
```

### Response Format (@security → @developer)

```yaml
# Security Guidance
type: "security_guidance"
from: "@security"
to: "@developer"
timestamp: "{ISO}"

assessment: "APPROVED|NEEDS_CHANGES|BLOCKED"

guidance:
  - category: "{auth|crypto|input_validation|data_handling}"
    recommendation: |
      {Recomendación concreta}
    pattern: |
      {Código o patrón sugerido}
    avoid: |
      {Anti-patrón a evitar}

required_checks:
  - "{Check que debe pasar antes de merge}"

additional_notes: |
  {Contexto adicional}
```

---

## Remediation (Security → Developer)

### Cuándo usar
- Security Gate detecta vulnerabilidad en código del developer
- Deep review encuentra patrón inseguro
- Dependencia vulnerable requiere actualización

### Finding Format (@security → @developer)

```yaml
# Security Finding
type: "remediation_request"
from: "@security"
to: "@developer"
timestamp: "{ISO}"

finding:
  severity: "{CRITICAL|HIGH|MEDIUM|LOW}"
  category: "{secrets|dependencies|code_patterns|sensitive_files}"
  location: "{path:line}"
  description: |
    {Qué se encontró}
  impact: |
    {Impacto potencial}
  fix: |
    {Cómo remediar}
  deadline: "{immediate|before_merge|next_sprint}"

blocking: true  # CRITICAL y HIGH siempre bloquean
```

### Fix Confirmation (@developer → @security)

```yaml
# Remediation Confirmation
type: "fix_confirmation"
from: "@developer"
to: "@security"
in_response_to: "{finding_timestamp}"

fix_applied:
  location: "{path:line}"
  description: |
    {Qué se cambió}
  verified_locally: true

ready_for_recheck: true
```

---

## Quick Consultation

### Cuándo usar
- Verificar si un patrón es seguro
- Preguntar sobre sanitización de inputs
- Confirmar manejo de errores para datos sensibles

### Format (simplificado)

```yaml
# Quick Security Consultation
type: "quick"
from: "@developer"
to: "@security"
question: "{Pregunta directa sobre seguridad}"
code_snippet: |
  {Código relevante si aplica}
blocking: false
```

---

## Iteration Loop

### Máximo 2 ciclos finding-fix

```
@security finding → @developer fix → @security recheck (ciclo 1)
  → Si persiste:
@security finding → @developer fix → @security recheck (ciclo 2)
  → Si persiste: escalar a usuario con recomendación
```

---

## Señales de Escalación

### @developer consulta @security cuando:

| Señal | Ejemplo | Acción |
|-------|---------|--------|
| Implementa auth/crypto | "¿Cómo almaceno tokens?" | Pre-Implementation |
| Maneja datos sensibles | "¿Necesito encriptar este campo?" | Quick Consultation |
| Security Gate falla | "¿Cómo arreglo este finding?" | Remediation response |

### @security escala a usuario cuando:

| Señal | Ejemplo |
|-------|---------|
| Vulnerability CRITICAL no remediable | "Requiere cambio de arquitectura" |
| 2 ciclos sin resolución | "Developer no puede arreglar el finding" |
| Bypass solicitado sin justificación | "Se pide omitir Security Gate" |

---

## Timeouts y Fallbacks

| Situación | Timeout | Fallback |
|-----------|---------|----------|
| Pre-Implementation sin respuesta | Blocking | Escalar a usuario |
| Finding CRITICAL sin fix | Blocking | Escalar a usuario |
| Quick Consultation sin respuesta | Continuar sin | Usar patrón conservador + documentar |
| @security no activado en /genesis | N/A | @qa ejecuta Security Gate básico |

---

## Ver también

- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **Security Gate**: `security/SECURITY-GATE.md`
- **QA-Security Contract**: `agents/_common/contracts/qa-security.md`
