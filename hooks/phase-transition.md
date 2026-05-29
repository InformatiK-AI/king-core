# PhaseTransition Hook

> Mecanismo convention-based de King Framework para interceptar transiciones entre fases del pipeline.  
> Implementado como dispatcher en `session-management/SKILL.md` (Paso N+1.5).  
> **Nota**: No es un evento nativo de Claude Code (que solo emite `SessionStart`, `PreToolUse`, `UserPromptSubmit`). Es una convención del dominio King generada internamente por `session-management`.

---

## Mecanismo

El dispatcher PhaseTransition se ejecuta en **Phase N+1, Paso N+1.5** de `session-management`, después de actualizar el Workflow Context (N+1.2) y antes de actualizar el Registry (N+1.3).

En ese punto del pipeline, el dispatcher tiene acceso completo a:
- El skill recién completado (`from_phase`)
- El próximo skill recomendado (`to_phase`)
- El resultado CASTLE de la sesión (`status`)
- El contexto del workflow activo (`project_name`, `branch`, `timestamp`)

El hook es **opt-in por proyecto**: solo se activa si existe `.king/hooks/phase-transition.yaml` en el proyecto con `enabled: true`.

---

## Payload Schema

El dispatcher construye el payload como **variables de entorno** pasadas al script configurado. Nunca como interpolación de string en shell.

| Variable de Entorno | Tipo | Descripción | Ejemplo |
|--------------------|------|-------------|---------|
| `KING_FROM_PHASE` | string | Skill recién completado | `build` |
| `KING_TO_PHASE` | string | Próximo skill recomendado | `review` |
| `KING_PROJECT_NAME` | string | Nombre del workflow activo | `issue-52-phase-transition-hook` |
| `KING_BRANCH` | string | Branch git actual | `feature/issue-52` |
| `KING_TIMESTAMP` | string | ISO 8601 del momento del dispatch | `2026-05-06T13:45:00Z` |
| `KING_STATUS` | string | Resultado CASTLE de la sesión | `FORTIFIED` |

### Valores posibles por campo

**`KING_FROM_PHASE` / `KING_TO_PHASE`** — Skills del pipeline King:
```
plan | build | review | qa | merge | promote | release
fix | refactor | optimize | audit | castle
```

**`KING_STATUS`** — Refleja el resultado bruto del skill completado. Puede ser un veredicto CASTLE o un estado de skill no-CASTLE:

```
# Veredictos CASTLE (skills con assessment completo):
FORTIFIED | CONDITIONAL | BREACHED

# Estados de skills sin CASTLE (resultado operacional):
EXITOSO    → /merge exitoso
PASS       → /review aprobado, /fix aplicado
BLOCKED    → /optimize sin hotspot encontrado
```

Los scripts que tomen decisiones basadas en `KING_STATUS` deben manejar ambos grupos.

---

## Configuración por Proyecto

Copiar `templates/hooks/phase-transition.yaml` a `.king/hooks/phase-transition.yaml` en el proyecto:

```yaml
enabled: true

on_phases:
  - build->review
  - qa->merge

run: notify-slack
async: true
timeout: 30
```

Ver template completo en: `templates/hooks/phase-transition.yaml`

---

## Comportamiento ante Errores (Fail-Safe)

El dispatcher PhaseTransition es **completamente fail-safe**. Ningún error en el hook bloquea el pipeline.

| Situación | Comportamiento |
|-----------|----------------|
| `.king/hooks/phase-transition.yaml` no existe | No-op silencioso. Pipeline continúa. |
| `enabled: false` | No-op silencioso. Pipeline continúa. |
| Transición no listada en `on_phases` | No-op. Solo se ejecuta si la transición matchea. |
| Campo `run` no pasa allowlist | Log WARN en session document. Pipeline continúa. |
| Script en `run` no existe | Error capturado. Log WARN. Pipeline continúa. |
| Script falla (exit code ≠ 0) | Error capturado. Log WARN. Pipeline continúa. |
| Script supera timeout (30s) | Proceso killed. Log WARN con timeout. Pipeline continúa. |

El error se registra en el session document bajo la sección **"PhaseTransition Hook"**, pero nunca interrumpe el flujo normal.

---

## Seguridad

### Campo `run` — Allowlist obligatoria

El campo `run` en la configuración YAML debe pasar la siguiente validación antes de ejecutarse:

```
Allowlist: [a-zA-Z0-9_.\-\/]
Prohibido explícito: ".." (path traversal), ; | & $() ` > < ! ? * { }
```

> El dot (`.`) permite paths como `.king/hooks/scripts/*.sh` y extensiones de archivo. La secuencia `..` queda explícitamente prohibida para prevenir path traversal.

Si el valor no pasa la validación, se logea un WARN y el hook se salta. No se ejecuta.

### Payload como ENV VARS — No interpolación shell

El script recibe el payload **exclusivamente** como variables de entorno. Ejemplo de uso correcto en el script:

```bash
#!/usr/bin/env bash
# notify-slack: notifica transición a Slack
echo "Transición: $KING_FROM_PHASE → $KING_TO_PHASE"
echo "Proyecto: $KING_PROJECT_NAME | Branch: $KING_BRANCH"
curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"King [$KING_PROJECT_NAME] $KING_FROM_PHASE→$KING_TO_PHASE ($KING_STATUS)\"}"
```

**NUNCA** construir comandos shell interpolando variables del payload directamente.

### Proceso hijo aislado

El script ejecuta con un entorno mínimo. No hereda secrets del proceso padre. Usar variables de entorno del sistema operativo para credenciales externas (Slack webhooks, tokens, etc.).

### Timeout

Timeout hard limit: **30 segundos**. Si el script no termina, se hace kill del proceso y se logea.

---

## Ejemplos de Uso

### Notificación a Slack al completar /build

```yaml
# .king/hooks/phase-transition.yaml
enabled: true
on_phases:
  - build->review
run: .king/hooks/scripts/notify-slack.sh
async: true
timeout: 30
```

### Gate de artefactos antes de /qa

```yaml
enabled: true
on_phases:
  - review->qa
run: .king/hooks/scripts/artifact-gate.sh
async: false
timeout: 30
```

### Token budget check antes de cualquier transición

```yaml
enabled: true
on_phases:
  - plan->build
  - build->review
  - review->qa
  - qa->merge
run: .king/hooks/scripts/token-budget-check.sh
async: false
timeout: 15
```

---

## Handlers Propuestos (referencia)

Basado en `mejora/02-ventaja-competitiva.md §3.3`:

| Handler | Propósito | Trigger sugerido |
|---------|-----------|-----------------|
| `gate-enforcement` | Verifica que la fase anterior produjo el artefacto requerido | Antes de cualquier fase |
| `token-budget-check` | Si sesión acumuló > N tokens, ofrece compactación | Antes de fases largas |
| `dependency-validate` | Verifica inputs requeridos de la fase siguiente | `review->qa`, `qa->merge` |
| `notify-slack` | Notificación de transición a canal del equipo | `build->review` |
| `write-phase-context` | Escribe signal file para activar @conductor | Todas las transiciones |

---

## Handler: gate-enforcement

Promueve a contrato documentado el handler listado arriba como propuesto. Verifica que la fase de origen produjo el artefacto requerido antes de registrar la transición.

| Transición | Artefacto requerido | Verificación |
|------------|---------------------|--------------|
| `ideacion → spec` | Scaffold de proyecto | `/genesis` ejecutado (estructura base + `.king/`) |
| `spec → mvp` | Código inicial | `commit_count > 0` |
| `mvp → produccion` | Release candidato | git tag `v*` existe **y** CASTLE main = `FORTIFIED` |
| `produccion → escala` | Madurez | `commit_count > 200` **y** ratio test/src > 0.6 |

**Comportamiento ante fallo del gate**: NO bloquea. Emite `WARN` en el session document bajo `### PhaseTransition Hook` indicando el artefacto faltante, y el pipeline continúa. Coherente con el fail-safe global (ver "Comportamiento ante Errores"). El gate es **advisory**: informa, no impone.

> Divergencia deliberada con `mejora/02-ventaja-competitiva.md §3.3`, que planteaba `gate-enforcement` como bloqueante. King prioriza el fail-safe: ningún hook detiene el pipeline.

---

## Handler: token-budget-check

Ofrece compactar el contexto antes de fases largas si la sesión acumuló uso significativo de tokens.

- **Threshold**: configurable, default **80%** del budget de la sesión.
- **Disparo**: antes de fases largas — `build`, `sdd-ff`, `sdd-continue`, `sdd-apply`.
- **Acción** (no bloqueante): si se supera el threshold, emitir al usuario:
  > "La sesión ha acumulado un uso significativo de tokens. ¿Querés compactar antes de continuar?"
- **Fail-safe**: si no hay dato de budget disponible, no-op silencioso.

---

## Schema project-state.json

`project-state.json` es el estado serializado del Modo Jarvis para un proyecto. Vive en `.king/jarvis/project-state.json` y es la **fuente única** de la fase del ciclo de vida. Lo leen `@conductor` (banner + algoritmo de fase, ver `agents/conductor.md §3.bis`) y el ciclo de actualización del roadmap.

```json
{
  "schema_version": "1.0",
  "project_slug": "mi-proyecto",
  "phase": "mvp",
  "roadmap_percent": 45,
  "next_skill": "/qa --standard",
  "castle_score": { "C": 4, "A": 4, "S": 3, "T": 2, "L": 4, "E": 3 },
  "castle_verdict": "CONDITIONAL",
  "skills_executed": ["genesis", "build", "review"],
  "transitions": [
    { "from": "spec", "to": "mvp", "at": "2026-05-28T10:00:00Z", "status": "FORTIFIED" }
  ],
  "session_started_at": "2026-05-28T22:00:00Z",
  "updated_at": "2026-05-28T22:33:55Z"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `schema_version` | string | Versión del schema (`"1.0"`) — para evolución futura |
| `project_slug` | string | Identificador del proyecto |
| `phase` | string | Fase actual. Valores: `ideacion`, `spec`, `mvp`, `produccion`, `escala` |
| `roadmap_percent` | number | Progreso 0-100 del pipeline |
| `next_skill` | string | Próximo skill King sugerido |
| `castle_score` | object | Las 6 capas CASTLE (Contracts, Architecture, Security, Testing, Logging, Environment), 0-5 cada una |
| `castle_verdict` | string | `FORTIFIED` \| `CONDITIONAL` \| `BREACHED` (ausente si no hay assessment) |
| `skills_executed` | string[] | Historial de skills ejecutados |
| `transitions` | object[] | Historial de transiciones: `{from, to, at, status}` |
| `session_started_at` | ISO 8601 | Inicio de la sesión actual (métrica TTFC) |
| `updated_at` | ISO 8601 | Última actualización del estado |

### Valores posibles de `phase`

| Fase | Significado | Señal típica |
|------|-------------|--------------|
| `ideacion` | Sin scaffold | `/genesis` no ejecutado |
| `spec` | Diseñando, sin código | genesis ejecutado, 0 commits |
| `mvp` | Construyendo | build ejecutado + commits > 0 |
| `produccion` | Release activo | git tag `v*` existe |
| `escala` | Madurez/optimización | tag + CASTLE FORTIFIED + commits > 200 |

### Inicialización
Si `project-state.json` no existe, se crea con `schema_version: "1.0"`, `phase` derivada por el algoritmo de @conductor (ver `conductor.md §3.bis`), `skills_executed: []` y `transitions: []`.

### Escritura atómica
La escritura DEBE ser atómica: escribir a `.king/jarvis/project-state.json.tmp` y luego `mv` (rename) sobre el destino. El rename es atómico en el filesystem y evita estados parciales si el proceso se interrumpe. NUNCA editar el JSON in-place.

### Merge ante conflicto
Cuando varios worktrees comparten el mismo `.king/` (ver `workflow_id` del signal file): para campos escalares (`phase`, `roadmap_percent`, `next_skill`, `castle_*`) gana el registro con `updated_at` más reciente; `skills_executed` y `transitions` se **unionan con dedup** (no se sobreescriben).

---

## Directorio .king/jarvis/

Estado runtime del Modo Jarvis en el proyecto del usuario. Se crea en ejecución (no vive en el repo de king-core).

| Archivo | Escrito por | ¿Versionar? |
|---------|-------------|-------------|
| `project-state.json` | @conductor / ciclo de actualización | **SÍ** — estado reproducible |
| `project-roadmap.md` | ciclo de actualización (desde el template) | NO — generado |
| `observations.jsonl` | hook contextual-observer (M-81) | NO — generado |
| `tech-debt.md` | @conductor (iteración futura) | NO — generado |
| `perf.log` | hooks (instrumentación) | NO — generado |

### .gitignore (aplicar en el proyecto que active Jarvis Mode)

```gitignore
.king/jarvis/project-roadmap.md
.king/jarvis/observations.jsonl
.king/jarvis/tech-debt.md
.king/jarvis/perf.log
# .king/jarvis/project-state.json  → SÍ se versiona (no ignorar)
```

---

## Listeners y Subscribers

El hook PhaseTransition soporta el patrón **signal file**: el script `run` escribe un JSON
estructurado en disco, y Claude lo consume en el Paso N+1.5b de `session-management` para
activar agentes proactivos como `@conductor`.

### Contrato del Signal File

**Path**: `.king/hooks/.conductor-context.json`
**Generado por**: `.king/hooks/scripts/write-phase-context.sh`
**Consumido por**: `session-management` Paso N+1.5b

**Schema v1.0**:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `schema_version` | string | Versión del schema (`"1.0"`) — para evolución futura |
| `workflow_id` | string | ID del workflow activo (ej: `WF-009`) — previene race conditions entre worktrees |
| `from_phase` | string | Skill recién completado |
| `to_phase` | string | Próximo skill recomendado |
| `project_name` | string | Nombre del workflow activo o branch |
| `branch` | string | Branch git actual |
| `status` | string | Resultado CASTLE o estado del skill |
| `timestamp` | ISO 8601 | Momento de la transición |

**Importante**: El signal file es consumido y eliminado por N+1.5b después de procesarlo.
El consumidor DEBE validar que `workflow_id` coincide con el workflow activo antes de procesar.
Esto previene activaciones cruzadas cuando múltiples worktrees comparten el mismo `.king/`.

### @conductor como Listener Built-in

`agents/conductor.md` es el subscriber por defecto del PhaseTransition hook.
Se activa cuando:

1. `.king/hooks/phase-transition.yaml` tiene `enabled: true`
2. El script `run` ejecuta y genera `.king/hooks/.conductor-context.json`
3. El Paso N+1.5b de `session-management` detecta el signal file y activa `conductor.md`

**Configuración mínima para activar @conductor**:

```yaml
# .king/hooks/phase-transition.yaml
enabled: true
on_phases:
  - from: build
    to: review
run: .king/hooks/scripts/write-phase-context.sh
async: true
timeout: 30
```

Ver template completo en: `templates/hooks/phase-transition.yaml`
Ver script dispatcher en: `.king/hooks/scripts/write-phase-context.sh` (gitignored — local al proyecto)

### ADR-003: Patrón hook→signal→agent

**Decisión**: Para futuros agentes proactivos en King Framework, el patrón canónico es:

```
script shell escribe JSON en disco → Claude lee el signal file → agente LLM razona
```

**Justificación**: El shell NUNCA puede invocar un agente LLM directamente. El signal file
es el mecanismo de desacoplamiento que permite que el dispatcher (shell) y el razonador (LLM)
operen en sus respectivos dominios. El schema fijo previene prompt injection.

**Precedente**: Implementado en `agents/conductor.md` (Issue #65 [S14] Jarvis Mode).
