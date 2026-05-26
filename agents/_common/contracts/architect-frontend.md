# Architect-Frontend Contract

## Propósito
Define el protocolo de interacción entre @architect y @frontend para decisiones de componentes que cruzan la frontera arquitectónica frontend ↔ backend/sistema.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Nuevo componente con estado global | @frontend | @architect | Pre-Design | Sí |
| Nueva dependencia de librería UI | @frontend | @architect | Quick Consultation | No |
| Cambio en contrato de API que afecta UI | @architect | @frontend | Notification | No |
| Componente con acceso directo a Data layer | @architect | @frontend | Escalation | Sí |
| Design system cross-cutting | @frontend | @architect | Collaboration | No |

---

## Pre-Design Consultation (@frontend → @architect)

### Cuándo usar
- El componente necesita acceder a estado global cross-módulo
- Se necesita una nueva librería que aumenta bundle size significativamente
- El componente tiene lógica de negocio que podría pertenecer al backend

### Request Format

```yaml
type: "frontend_pre_design"
from: "@frontend"
to: "@architect"

component: "{Nombre del componente}"
concern: |
  {Descripción de la decisión arquitectónica necesaria}

options:
  - name: "{Opción A: Manejar en frontend}"
    pros: ["{pro}"]
    cons: ["{con}"]
  - name: "{Opción B: Mover lógica a backend}"
    pros: ["{pro}"]
    cons: ["{con}"]

question: |
  {¿Dónde debe vivir esta responsabilidad?}
```

### Response Format

```yaml
type: "architect_frontend_response"
from: "@architect"
to: "@frontend"

decision: "{Opción elegida}"
justification: |
  {Razonamiento desde separation of concerns y dependency rule}

boundary_definition: |
  {Dónde está la frontera frontend/backend para este componente}

contract_to_respect:
  file: "{contrato de interfaz o API contract si aplica}"
  key_points: ["{punto clave del contrato}"]
```

---

## Notification: Cambio en Contrato de API

### Cuándo @architect notifica @frontend

```yaml
type: "api_contract_change_notification"
from: "@architect"
to: "@frontend"

change_type: "BREAKING | NON_BREAKING | ADDITIVE"
affected_endpoint: "{endpoint o interfaz}"
change_description: |
  {Qué cambió}

frontend_action_required:
  - "{Actualización requerida en componente X}"
  - "{Nuevo campo disponible Y}"

migration_deadline: "{before_merge|next_sprint}"
```

---

## Escalation: Violación de Dependency Rule

### Cuándo @architect bloquea a @frontend

```yaml
type: "dependency_rule_violation"
from: "@architect"
to: "@frontend"
severity: "BLOCKING"

violation: |
  {Componente frontend X importa directamente de Data layer Y}

required_fix: |
  {Pasar a través de Logic layer Z; crear servicio intermediario}

blocking: true
```

---

## Ver también

- **Developer-Frontend Contract**: `contracts/developer-frontend.md`
- **Developer-Architect Contract**: `contracts/developer-architect.md`
- **Escalation Matrix**: `_common/escalation-matrix.md`
