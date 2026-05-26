# Performance-Architect Contract

## Propósito
Define el protocolo de interacción entre @performance y @architect cuando los problemas de rendimiento tienen causa raíz arquitectónica, requieren cambios estructurales para resolverse.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Bottleneck con causa arquitectónica | @performance | @architect | Escalation | No |
| Decisión de caché layer nueva | @performance | @architect | Pre-Decision | Sí |
| Cambio de arquitectura que impacta latencia | @architect | @performance | Notification | No |
| Scalability review de diseño propuesto | @architect | @performance | Consultation | No |
| Threshold de performance imposible con stack actual | @performance | @architect + Usuario | Critical Escalation | Sí |

---

## Escalation: Bottleneck Arquitectónico

### Cuándo @performance escala a @architect
- El bottleneck no puede resolverse con optimizaciones locales (índices, caché, código)
- Requiere cambio en cómo los módulos se comunican o acceden a datos
- El patrón de acceso a datos viola dependency rule y genera N+1 por diseño

### Escalation Format (@performance → @architect)

```yaml
type: "architectural_performance_escalation"
from: "@performance"
to: "@architect"

bottleneck:
  description: |
    {Descripción del problema de performance}
  measured_impact: "{latencia actual vs threshold}"
  evidence: "{query log, profiler output, metric}"

root_cause_hypothesis: |
  {Por qué creo que es un problema de diseño, no de código}

local_optimizations_tried:
  - "{Optimización 1: resultado}%"
  - "{Optimización 2: resultado}%"

architectural_change_options:
  - name: "{Opción A: e.g., Agregar caching layer}"
    expected_improvement: "{~X ms}"
    complexity: "LOW|MEDIUM|HIGH"
  - name: "{Opción B: e.g., Desnormalizar schema}"
    expected_improvement: "{~Y ms}"
    complexity: "MEDIUM|HIGH"

recommendation: "{Opción preferida con justificación}"
blocking_release: false|true
```

### Response Format (@architect → @performance)

```yaml
type: "architect_performance_response"
from: "@architect"
to: "@performance"

decision: "{Opción elegida}"
justification: |
  {Por qué desde perspectiva arquitectónica}

trade_offs_accepted:
  - "{Trade-off de performance vs mantenibilidad}"

implementation_approach:
  assigned_to: "@developer"
  adr_created: "{path|null}"
  timeline: "{Urgente|Próximo sprint|Backlog}"

expected_improvement: "{~X ms / Y%}"
```

---

## Pre-Decision: Nueva Capa de Caché

### Cuándo @performance propone nueva infraestructura de caché

```yaml
type: "cache_layer_pre_decision"
from: "@performance"
to: "@architect"

current_problem: |
  {Qué se cachearía y por qué es necesario}

proposed_cache:
  type: "IN_MEMORY | REDIS | HTTP_CACHE | CDN"
  scope: "REQUEST | SESSION | GLOBAL"
  ttl: "{duración}"
  invalidation_strategy: "{cómo se invalida}"

performance_projection:
  current_p95: "{ms}"
  projected_p95: "{ms}"
  cache_hit_rate_expected: "{%}"
```

---

## Notification: Cambio Arquitectónico que Impacta Performance

### Cuándo @architect notifica @performance

```yaml
type: "architectural_change_performance_impact"
from: "@architect"
to: "@performance"

change: |
  {Descripción del cambio arquitectónico}

potential_performance_impact: |
  {Qué podría empeorar o mejorar}

benchmarks_requested:
  - "{Métrica a medir antes del cambio}"
  - "{Métrica a medir después}"

measurement_deadline: "{Cuándo se necesita el benchmark}"
```

---

## Critical Escalation: Threshold Imposible

### Cuándo el sistema no puede cumplir thresholds con la arquitectura actual

```yaml
type: "performance_threshold_impossible"
from: "@performance"
to: ["@architect", "usuario"]
severity: "CRITICAL"

threshold: "{threshold definido en environments.md}"
measured: "{valor actual}"
gap: "{diferencia}"

why_impossible: |
  {Por qué el stack/arquitectura actual no puede alcanzar el threshold}

options:
  - name: "{Aceptar threshold diferente}"
    implication: "{Trade-off de UX/SLA}"
  - name: "{Rediseño significativo}"
    implication: "{Costo y complejidad estimados}"
  - name: "{Cambio de stack}"
    implication: "{Migración mayor}"

decision_required_from: "usuario"
```

---

## Ver también

- **Developer-Performance Contract**: `contracts/developer-performance.md`
- **Developer-Architect Contract**: `contracts/developer-architect.md`
- **Escalation Matrix**: `_common/escalation-matrix.md`
- **Performance Essentials**: `../../knowledge/_inject/performance-essentials.md`
