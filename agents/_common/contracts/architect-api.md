# Architect-API Contract

## Propósito
Define el protocolo de interacción entre @architect y @api para el diseño de contratos de API, schemas de interfaz y decisiones de versionado.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Diseño de nuevo endpoint | @architect | @api | Pre-Design | Sí |
| Breaking change en API pública | @api | @architect | Escalation | Sí |
| Validación de schema request/response | @api | @architect | Quick Consultation | No |
| Versionado de API | @api | @architect | Pre-Decision | Sí |
| Contrato MCP nuevo | @architect | @api | Collaboration | No |

---

## Pre-Design API Review

### Cuándo @architect consulta @api
- Antes de diseñar un nuevo endpoint que forma parte de una interfaz pública
- Cuando se necesita definir un schema complejo de request/response
- Antes de implementar un contrato MCP nuevo

### Request Format (@architect → @api)

```yaml
type: "api_pre_design"
from: "@architect"
to: "@api"

context:
  resource: "{Recurso o dominio del endpoint}"
  consumers: ["{Consumidor 1}", "{Consumidor 2}"]

proposed_design:
  method: "GET|POST|PUT|PATCH|DELETE"
  path: "{/api/v1/resource}"
  request_schema: |
    {Descripción o JSON Schema del request}
  response_schema: |
    {Descripción o JSON Schema del response}

questions:
  - "{¿Este diseño cumple REST conventions?}"
  - "{¿El schema es extensible sin breaking changes?}"
```

### Response Format (@api → @architect)

```yaml
type: "api_design_response"
from: "@api"
to: "@architect"

assessment: "APPROVED | CONDITIONAL | REDESIGN_REQUIRED"

issues:
  - type: "BREAKING_POTENTIAL | CONVENTION_VIOLATION | SCHEMA_ISSUE"
    description: "{Descripción del problema}"
    recommendation: "{Cómo resolverlo}"

approved_schema:
  request: |
    {Schema final aprobado}
  response: |
    {Schema final aprobado}

versioning_required: true|false
versioning_strategy: "{v1 preserved, v2 for new; vs. deprecation}"
```

---

## Escalation: Breaking Change Detection

### Cuándo @api escala a @architect

```yaml
type: "breaking_change_escalation"
from: "@api"
to: "@architect"

endpoint: "{path}"
change_detected: |
  {Descripción del breaking change propuesto}

consumers_affected: ["{Consumer 1}", "{Consumer 2}"]

options:
  - name: "Versionar (v1 → v2)"
    complexity: "MEDIUM"
    consumer_impact: "LOW"
  - name: "Deprecation period"
    complexity: "HIGH"
    consumer_impact: "MEDIUM"

recommendation: "{Opción recomendada con justificación}"

blocking: true  # Merge bloqueado hasta decisión
```

---

## Ver también

- **Developer-Architect Contract**: `contracts/developer-architect.md`
- **Escalation Matrix**: `_common/escalation-matrix.md`
- **API Design Essentials**: `../../knowledge/_inject/api-design-essentials.md`
