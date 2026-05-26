# Protocolo CASTLE

# Protocolo CASTLE Assessment

CASTLE es el framework de evaluación de calidad de King Framework. Cada letra representa una capa de protección que se evalúa independientemente.

## Capas CASTLE

```
C - Contracts      → Contratos de API, schemas, interfaces
A - Architecture    → Estructura, patrones, dependency direction
S - Security        → Vulnerabilidades, secrets, OWASP Top 10
T - Testing         → Cobertura, calidad de tests, ACs
L - Logging         → Logs estructurados, error handling, health
E - Environment     → Ambientes, deploy, smoke tests, rollback
```

## Ownership de Capas (Responsables)

| Capa | Responsable Principal | Co-responsables | Veto |
|------|-----------------------|-----------------|------|
| C — Contracts | @architect | @security, @api | — |
| A — Architecture | @architect | @api, @frontend | — |
| S — Security | @security | — | ✓ (CRÍTICO) |
| T — Testing | @qa | @developer, @frontend | — |
| L — Logging | @performance | @devops, @qa | — |
| E — Environment | @devops | — | — |

El responsable principal lidera la evaluación de su capa y es quien firma el veredicto parcial.
@security tiene poder de VETO en la capa S: un FAIL en S puede bloquear el flujo independientemente de las otras capas.

## Configuración de Capas por Contexto

No todas las evaluaciones requieren las 6 capas. Cada skill define qué capas activa:

| Skill | C | A | S | T | L | E |
|-------|---|---|---|---|---|---|
| build | x | x | . | x | x | . |
| review | x | x | x | x | . | . |
| qa | x | x | x | x | x | . |
| qa-batch | x | x | x | x | x | x |
| qa-env | x | x | x | x | x | x |
| merge | . | x | . | x | . | . |
| fix | . | x | x | x | . | . |
| promote | . | . | x | . | . | x |
| release | x | x | x | x | x | x |
| refactor | . | x | . | x | . | . |

## Procedimiento de Evaluación

### Paso 1: Determinar capas activas
Según el skill que invoca CASTLE, activar solo las capas correspondientes.

### Paso 2: Ejecutar checks por capa
Para cada capa activa, ejecutar los checks definidos en `references/[capa]-checks.md`.

Cada check produce uno de:
- **PASS**: El check se cumple satisfactoriamente
- **WARNING**: El check tiene observaciones pero no es bloqueante
- **FAIL**: El check no se cumple — es bloqueante según severidad

### Paso 3: Calcular resultado por capa
- **PASS**: Todos los checks son PASS
- **WARNING**: Al menos un WARNING, ningún FAIL
- **FAIL**: Al menos un FAIL

### Paso 4: Determinar veredicto global

| Veredicto | Condición | Acción |
|-----------|-----------|--------|
| FORTIFIED | Todas las capas activas PASS | Proceder sin restricciones |
| CONDITIONAL | Solo WARNING, ningún FAIL | Proceder con observaciones documentadas |
| BREACHED | Al menos un FAIL en alguna capa | BLOQUEAR — no proceder hasta resolver |

## Formato de Reporte CASTLE

```
╔══════════════════════════════════════════╗
║           CASTLE Assessment              ║
╠══════════════════════════════════════════╣
║                                          ║
║  C  Contracts     [PASS|WARN|FAIL|----]  ║
║  A  Architecture  [PASS|WARN|FAIL|----]  ║
║  S  Security      [PASS|WARN|FAIL|----]  ║
║  T  Testing       [PASS|WARN|FAIL|----]  ║
║  L  Logging       [PASS|WARN|FAIL|----]  ║
║  E  Environment   [PASS|WARN|FAIL|----]  ║
║                                          ║
║  Veredicto: [FORTIFIED|CONDITIONAL|BREACHED]
║                                          ║
╚══════════════════════════════════════════╝
```

Donde `----` indica que la capa no fue evaluada (no activa para este contexto).

## Checks por Capa

Los checks detallados están en archivos separados dentro de `references/`:

- `references/contracts-checks.md` — Checks de capa C
- `references/architecture-checks.md` — Checks de capa A
- `references/security-checks.md` — Checks de capa S
- `references/testing-checks.md` — Checks de capa T
- `references/logging-checks.md` — Checks de capa L
- `references/environment-checks.md` — Checks de capa E

Leer el archivo correspondiente antes de ejecutar cada capa.

## Integración con el Pipeline

El CASTLE assessment se integra en estos puntos del flujo:

1. **Pre-merge**: Antes de merge a develop (capas según skill)
2. **Pre-promote**: Antes de promover a QA/prod (S + E mínimo)
3. **Pre-release**: Antes de release (6 capas completas, FORTIFIED requerido)
4. **Post-review**: Después de code review (capas del reviewer)
5. **On-demand**: Cuando el usuario ejecuta `/castle`

## Ejemplos de Uso

### Assessment completo
```
/castle
```
Ejecuta las 6 capas y reporta veredicto.

### Assessment de capa específica
```
/castle --layer S
```
Ejecuta solo la capa de Security.

### Assessment para pre-release
```
/castle --context release
```
Ejecuta las 6 capas con umbrales de release (más estrictos).

---

## Session Tracking

> Este skill es standalone. No genera ni participa en workflows.

Al completar un CASTLE Assessment:
1. Si `.king/registry.md` existe, registrar en "Sesiones Recientes"
2. No crear workflow ni context.md
3. Si se ejecutó DENTRO de otro skill (build, qa, etc.), el skill padre se encarga del tracking
4. Comunicar: "Assessment standalone completado. No hay próximo paso en un flujo."
