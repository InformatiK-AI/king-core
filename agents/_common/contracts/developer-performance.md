# Developer-Performance Contract

## Propósito
Define el protocolo de interacción entre @developer y @performance para identificación de cuellos de botella, optimizaciones de código y validación de cambios con impacto en rendimiento.

---

## Escenarios de Interacción

| Escenario | Iniciador | Receptor | Tipo | Bloquea |
|-----------|-----------|----------|------|---------|
| Concern de performance detectado | @developer | @performance | Consultation | No |
| Profiling de ruta crítica | @performance | @developer | Analysis | No |
| Cambio arquitectónico para performance | @performance | @developer + @architect | Escalation | Sí |
| Validación de optimización propuesta | @developer | @performance | Pre-Implementation | No |
| Regresión de performance en build | @performance | @developer | Remediation | Sí |

---

## Performance Consultation

### Cuándo usar
- Antes de implementar loops sobre colecciones grandes
- Cuando se consulta base de datos con N+1 potencial
- Al agregar dependencias con footprint significativo
- Cuando se sospecha regresión de latencia

### Request Format (@developer → @performance)

```yaml
# Performance Consultation
type: "consultation"
from: "@developer"
to: "@performance"
context:
  skill: "/{skill}"
  issue: "#{number}"

concern: |
  {Descripción del concern: qué operación, qué volumen estimado}

code_path: "{archivo:línea relevante}"

metrics_context:
  estimated_data_size: "{Pequeño|Medio|Grande|Desconocido}"
  call_frequency: "{Una vez|Por request|Background}"
  latency_requirement: "{No crítico|<100ms|<50ms|<10ms}"

blocking: false
```

### Response Format (@performance → @developer)

```yaml
# Performance Guidance
type: "performance_guidance"
from: "@performance"
to: "@developer"

assessment: "OK|OPTIMIZE|CRITICAL"

findings:
  - type: "{N+1|full_scan|memory_leak|cpu_bound|io_bound}"
    location: "{path:line}"
    impact: "{Bajo|Medio|Alto}"
    recommendation: |
      {Optimización concreta sugerida}
    example: |
      {Código optimizado si aplica}

approved_to_continue: true
additional_profiling_needed: false
```

---

## Remediation (Performance → Developer)

### Cuándo usar
- Regresión detectada en métricas post-build
- Threshold de latencia superado en QA
- Memory leak identificado en profiling

### Finding Format

```yaml
# Performance Finding
type: "remediation_request"
from: "@performance"
to: "@developer"

finding:
  severity: "{CRITICAL|HIGH|MEDIUM|LOW}"
  metric: "{latency_p99|memory_mb|cpu_percent|query_count}"
  current_value: "{valor actual}"
  expected_threshold: "{umbral esperado}"
  location: "{path:line}"
  description: |
    {Qué se encontró y cuál es el impacto}
  fix: |
    {Optimización sugerida}

blocking: false  # Solo bloquea si severity=CRITICAL
```

---

## Señales de Activación para @performance

| Señal en código | Ejemplo | Acción |
|-----------------|---------|--------|
| Bucle sobre resultado de DB | `users.forEach(u => db.find(u.id))` | Consultar |
| Query sin índice | `WHERE unindexed_field = ?` | Alertar |
| Dependencia pesada agregada | `import heavyLib` | Evaluar footprint |
| Procesamiento en request thread | Operación CPU-intensiva sin async | Recomendar offload |

---

## Iteration Loop

Máximo 2 ciclos finding-optimize:
```
@performance finding → @developer optimize → @performance recheck (ciclo 1)
  → Si persiste: ciclo 2 → Si persiste: escalar a @architect
```

---

## Ver también

- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **Developer-Architect Contract**: `agents/_common/contracts/developer-architect.md`
