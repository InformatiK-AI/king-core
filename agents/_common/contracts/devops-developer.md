# DevOps-Developer Contract

## Propósito
Define el protocolo de interacción entre @devops y @developer para coordinación de ambientes, configuración de entorno de desarrollo, y resolución de problemas de infraestructura que bloquean el desarrollo.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Ambiente de dev bloqueado | @developer | @devops | Unblock Request | Sí |
| Nueva variable de entorno requerida | @developer | @devops | Config Request | No |
| Deploy de feature branch para testing | @developer | @devops | Deploy Request | No |
| Pipeline CI/CD fallando | @devops | @developer | Notification | No |
| Configuración de worktree para feature | @developer | @devops | Setup Request | No |

---

## Unblock Request: Ambiente Bloqueado

### Cuándo @developer solicita a @devops

```yaml
type: "environment_unblock_request"
from: "@developer"
to: "@devops"

environment: "dev|qa"
issue: |
  {Descripción del problema de ambiente que bloquea el desarrollo}

symptoms:
  - "{Síntoma 1: error message, servicio caído, etc.}"
  - "{Síntoma 2}"

already_tried:
  - "{Lo que intenté y no funcionó}"

blocking: true
urgency: "HIGH|MEDIUM|LOW"
```

### Response Format (@devops → @developer)

```yaml
type: "environment_unblock_response"
from: "@devops"
to: "@developer"

status: "RESOLVED | IN_PROGRESS | NEEDS_INVESTIGATION"

actions_taken:
  - "{Acción 1 ejecutada}"
  - "{Acción 2}"

environment_state:
  health_endpoint: "OK|FAIL"
  services: ["{servicio: estado}"]
  ready_for_development: true|false

next_steps_if_not_resolved: |
  {Qué hacer si el ambiente sigue bloqueado}
```

---

## Config Request: Nueva Variable de Entorno

```yaml
type: "env_var_config_request"
from: "@developer"
to: "@devops"

variable_name: "{NOMBRE_VARIABLE}"
purpose: "{Para qué se usa}"
required_in: ["dev", "qa", "prod"]
sensitivity: "SECRET | CONFIG"
default_value: "{Si aplica — NO para secrets}"

note: "Si es SECRET, @devops consultará @security antes de configurar"
```

---

## Deploy Request: Feature Branch

```yaml
type: "feature_deploy_request"
from: "@developer"
to: "@devops"

branch: "feature/XXX-descripcion"
target_environment: "dev|qa"
purpose: |
  {Por qué se necesita el deploy: demo, testing de integración, etc.}

pre_conditions:
  tests_passing: true
  castle_verdict: "FORTIFIED|CONDITIONAL"
```

```yaml
type: "feature_deploy_response"
from: "@devops"
to: "@developer"

status: "DEPLOYED | FAILED | QUEUED"
url: "{URL del ambiente si aplica}"
health_check: "OK|FAIL"
deployment_log: "{path al log}"
```

---

## Notification: CI/CD Pipeline Fallando

```yaml
type: "pipeline_failure_notification"
from: "@devops"
to: "@developer"

pipeline: "{nombre del pipeline}"
branch: "{branch afectado}"
failing_step: "{paso que falla}"
error_summary: |
  {Resumen del error}

action_required: |
  {Qué debe hacer @developer para resolver}
```

---

## Ver también

- **Developer-Architect Contract**: `contracts/developer-architect.md`
- **DevOps-Security Contract**: `contracts/devops-security.md`
- **DevOps-Mobile Contract**: `contracts/devops-mobile.md`
- **Escalation Matrix**: `_common/escalation-matrix.md`
