# DevOps-Security Contract

## Propósito
Define el protocolo de interacción entre @devops y @security para asegurar que pipelines CI/CD, configuración de ambientes y operaciones de deploy no introducen vulnerabilidades de infraestructura.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Configuración de nuevo ambiente | @devops | @security | Pre-Config | No |
| Secrets en configuración detectados | @security | @devops | Escalation | Sí |
| Nueva variable de entorno con dato sensible | @devops | @security | Quick Consultation | No |
| Cambio en permisos de CI/CD | @devops | @security | Pre-Config | Sí |
| Audit de pipeline por compliance | @security | @devops | Audit Request | No |

---

## Pre-Config Security Review

### Cuándo @devops consulta @security
- Antes de configurar un nuevo ambiente con acceso a datos de producción
- Antes de cambiar permisos en pipeline CI/CD (variables secretas, tokens)
- Cuando se necesita agregar credenciales a la configuración de ambiente

### Request Format (@devops → @security)

```yaml
type: "pre_config_security_review"
from: "@devops"
to: "@security"

context:
  environment: "dev|qa|prod"
  change_type: "{Tipo de cambio de configuración}"

credentials_involved:
  - name: "{Nombre del secret}"
    storage: "{env file | vault | CI/CD variable}"
    exposed_to: ["{Procesos o ambientes con acceso}"]

question: |
  {¿Esta configuración de secrets es segura?}
```

### Response Format (@security → @devops)

```yaml
type: "security_config_response"
from: "@security"
to: "@devops"

verdict: "APPROVED | CONDITIONAL | BLOCKED"

findings:
  - severity: "CRITICAL|HIGH|MEDIUM|LOW"
    description: "{Problema detectado}"
    fix_required: "{Acción correctiva}"

approved_pattern: |
  {Patrón correcto de manejo de secret si aplica}
```

---

## Escalation: Secrets Detectados

### Cuándo @security escala a @devops por secrets en infraestructura

```yaml
type: "secret_exposure_escalation"
from: "@security"
to: "@devops"
severity: "CRITICAL"

finding: |
  {Secret encontrado en: config file | CI/CD log | worktree | .env commiteado}

evidence: "{path:line o log entry}"

immediate_actions_required:
  1. "{Revocar credencial comprometida}"
  2. "{Remover del historial git si aplica}"
  3. "{Rotar secret en todos los ambientes}"

blocking: true
```

---

## Quick Consultation: Nueva Variable de Entorno

```yaml
type: "quick_env_var_consultation"
from: "@devops"
to: "@security"
variable: "{NOMBRE_VARIABLE}"
sensitivity: "{API_KEY | PASSWORD | TOKEN | CONFIG | NON_SENSITIVE}"
question: "¿Requiere vault/secret manager o env var estándar es suficiente?"
```

```yaml
type: "quick_env_var_response"
from: "@security"
recommendation: "VAULT | CI_SECRET_VAR | STANDARD_ENV | NONE"
reason: "{Justificación}"
```

---

## Ver también

- **Developer-Security Contract**: `contracts/developer-security.md`
- **QA-Security Contract**: `contracts/qa-security.md`
- **DevOps-Mobile Contract**: `contracts/devops-mobile.md`
- **Escalation Matrix**: `_common/escalation-matrix.md`
- **Security Gate**: `../../security/SECURITY-GATE.md`
