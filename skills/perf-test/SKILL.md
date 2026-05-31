---
name: perf-test
version: 2.0
api_version: 1.0.0
description: "Genera y ejecuta performance tests con gates p95/p99. Usar cuando se necesite: performance testing, load testing, smoke/load/spike tests, generar scripts k6/Artillery/Gatling, medir p50/p95/p99, gate de latencia que bloquea promote, o alimentar CASTLE E con evidencia de rendimiento."
model: sonnet
---

# /perf-test — Performance Testing con Gates p95/p99

Descubre endpoints, genera scripts de performance (k6 por defecto), ejecuta smoke/load/spike
y compara p50/p95/p99 contra los budgets de `.king/performance.yaml`. Alimenta la capa
**CASTLE E** y puede vetar `/promote`.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/universal/testing-pyramid.md` | Posición del performance testing en la estrategia | No | framework |
| `knowledge/universal/performance-budget.md` | Budgets de performance y su enforcement | No | framework |
| `knowledge/_inject/performance-essentials.md` | Patrones de performance y métricas | No | framework |
| `.king/performance.yaml` | Budgets p50/p95/p99 y enforcement del proyecto | No | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión previa de `/genesis` en el proyecto (`.king/` ausente)
- [ ] No se detectan endpoints ni se declaran manualmente
- [ ] No hay herramienta de performance disponible para el stack ni se puede instalar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA ejecutar load/spike contra `staging`/`prod` sin confirmación explícita del usuario
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA reportar PASS sin métricas p95 numéricas medidas
- NUNCA incluir secrets/tokens literales en los scripts generados (usar variables de entorno)

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] `tests/performance/{feature}-load.k6.js` — script de performance (default k6)
- [ ] `.king/perf/{timestamp}-{feature}-results.json` — resultados machine-readable
- [ ] `.king/perf/{timestamp}-{feature}-summary.md` — resumen para CASTLE E y `/promote`
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Discover)(Generate)(Smoke)(Load+Metrics)(Gate+CASTLE E)(Session)(Guide)
```

### PARÁMETROS
```
/perf-test [--feature <name>] [--env local|staging] [--tool k6|artillery|gatling] [--scenario smoke|load|spike|all]
```
- `--feature <name>`: nombre del feature/endpoint group a testear
- `--env`: entorno objetivo (default: `local`; `staging`/`prod` requieren confirmación)
- `--tool`: herramienta (default: k6; gatling para stacks JVM)
- `--scenario`: escenario a correr (default: `smoke` automático; `all` corre los tres)

---

## CASTLE activo: _-A-_-T-_-E

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.

## Agentes
- **@performance** — Agente principal: define escenarios, interpreta p50/p95/p99, evalúa el gate
- **@architect** — Identifica endpoints críticos y SLOs
- **@developer** — Sugiere optimizaciones ante regresiones (índices DB, connection pool, caching)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Discover Endpoints + Thresholds

### GATE IN
- [ ] `.king/` existe (genesis ejecutado)
- [ ] Endpoints detectables o `--feature` declarado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Detectar endpoints** del router/controller (Express/Fastify, FastAPI/Flask, Spring, router Go)
2. [ ] **Leer budgets** de `.king/performance.yaml`; si no existe, usar defaults seguros (ver REFERENCE) y proponer crear el archivo
3. [ ] **Resolver entorno** — `--env` (default `local`); si es `staging`/`prod`, marcar para confirmación en Phase 4
4. [ ] **Elegir herramienta** — `--tool` o k6 por defecto (gatling para stacks JVM)

### CHECKPOINT
- [ ] ≥1 endpoint identificado
- [ ] Budgets resueltos (de archivo o defaults)
- [ ] Herramienta y entorno definidos

### OUTPUTS
- Variables: `FEATURE`, `ENDPOINTS[]`, `BUDGETS`, `ENV`, `TOOL`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se detectaron endpoints.
Cause: router no reconocido o `--feature` ausente.
Recovery:
  [ ] Option A: pedir al usuario la lista de endpoints (método + path) a testear
  [ ] Option B: forzar `--tool`/`--feature` y reintentar
  [ ] Option C: si no hay API HTTP → performance testing no aplica; terminar PARTIAL

---

## Phase 2: Select Tool + Generate Scripts

### GATE IN
- [ ] Endpoints y herramienta definidos (Phase 1)

### MUST DO
1. [ ] **Generar scripts** desde las plantillas `templates/k6/{smoke,load,spike}.js` parametrizadas con `ENDPOINTS` y `BUDGETS`
2. [ ] **Escribir** `tests/performance/{FEATURE}-load.{tool-ext}` (k6: `.k6.js`; artillery: `.artillery.yaml`; gatling: `.gatling.scala`)
3. [ ] **Inyectar thresholds** del budget como `thresholds` nativos del tool (k6 falla el run si se exceden)
4. [ ] **Usar env vars** para base URL y auth — nunca hardcodear secrets

### CHECKPOINT
- [ ] Script(s) escritos en `tests/performance/`
- [ ] Thresholds del budget embebidos en el script
- [ ] Sin secrets literales

### OUTPUTS
- `tests/performance/{FEATURE}-load.{ext}`

### IF FAILS
ERROR: No se pudieron generar los scripts.
Cause: plantilla no encontrada o endpoints mal formados.
Recovery:
  [ ] Option A: usar la plantilla embebida en REFERENCE como fallback
  [ ] Option B: generar sólo smoke test mínimo y marcar WARN

---

## Phase 3: Run Smoke Test

### GATE IN
- [ ] Script generado (Phase 2)
- [ ] Entorno objetivo accesible

### MUST DO
1. [ ] **Ejecutar smoke** (1 VU, 30s) — ¿arranca y responde sin errores?
2. [ ] **Verificar disponibilidad** — si el target no responde, abortar antes del load
3. [ ] **Capturar** p50/p95/p99 y error rate del smoke

### CHECKPOINT
- [ ] Smoke ejecutado; error rate aceptable (< 1%)
- [ ] Métricas básicas capturadas

### OUTPUTS
- Resultados del smoke (parciales en `.king/perf/`)

### IF FAILS
ERROR: El smoke test falló.
Cause: servicio no levantado o endpoint roto.
Recovery:
  [ ] Option A: verificar que el servicio corre en el entorno (`--env`)
  [ ] Option B: si hay errores 5xx → recomendar `/fix` antes de medir performance
  [ ] Option C: ajustar base URL/auth via env vars

---

## Phase 4: Run Load Test + Collect Metrics

### GATE IN
- [ ] Smoke en verde (Phase 3)
- [ ] Si `ENV` es staging/prod → **confirmación explícita obtenida**

### MUST DO
1. [ ] **Confirmar entorno** — si staging/prod, advertir costo de infra y pedir confirmación
2. [ ] **Ejecutar load** (VUs crecientes hasta target, ~5min) y opcionalmente spike (10× pico, 30s)
3. [ ] **Recolectar** p50/p95/p99, throughput, error rate por endpoint
4. [ ] **Escribir** `.king/perf/{timestamp}-{FEATURE}-results.json`

### CHECKPOINT
- [ ] Load ejecutado; métricas por endpoint capturadas
- [ ] `.king/perf/{timestamp}-{FEATURE}-results.json` existe

### OUTPUTS
- `.king/perf/{timestamp}-{FEATURE}-results.json`

### IF FAILS
ERROR: El load test no completó.
Cause: saturación, timeouts, o entorno inestable.
Recovery:
  [ ] Option A: reducir VUs/duración y reintentar
  [ ] Option B: reportar resultados parciales del smoke con WARN
  [ ] Option C: si el sistema se rompe bajo carga → es un hallazgo; documentar y recomendar `/optimize`

---

## Phase 5: Gate Evaluation + CASTLE E

### GATE IN
- [ ] `results.json` con métricas (Phase 4 o smoke de Phase 3)

### MUST DO
1. [ ] **Comparar** p95 medido vs `BUDGETS` por endpoint
2. [ ] **Aplicar enforcement**: `warn` → CONDITIONAL (WARNING); `block` → registrar veto para `/promote`
3. [ ] **Escribir** `.king/perf/{timestamp}-{FEATURE}-summary.md` con tabla p50/p95/p99 vs budget, veredicto y optimizaciones sugeridas
4. [ ] **Asignar veredicto CASTLE E**: PASS si todos dentro de budget; CONDITIONAL/BREACH según enforcement

### CHECKPOINT
- [ ] `.king/perf/{timestamp}-{FEATURE}-summary.md` existe
- [ ] Veredicto E asignado con p95 vs budget explícito
- [ ] Si `block` y excede → veto registrado para `/promote`

### OUTPUTS
- `.king/perf/{timestamp}-{FEATURE}-summary.md`

### IF FAILS
ERROR: No se pudo evaluar el gate.
Cause: métricas incompletas o budget ausente.
Recovery:
  [ ] Option A: usar defaults seguros de budget y re-evaluar
  [ ] Option B: emitir summary CONDITIONAL con nota de incertidumbre

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] `tests/performance/{FEATURE}-load.{ext}`
  - [ ] `.king/perf/{timestamp}-{FEATURE}-results.json`
  - [ ] `.king/perf/{timestamp}-{FEATURE}-summary.md`
- [ ] p95 numérico medido y comparado contra budget
- [ ] Ningún secret literal en los scripts
- [ ] staging/prod sólo ejecutados con confirmación explícita
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(dentro de budget=FORTIFIED; excede+warn=CONDITIONAL; excede+block=BREACHED)_ |
| Artifacts | _(scripts, results.json, summary.md)_ |
| Next Recommended | `/promote` (si PASS) o `/optimize` (si regresión) |
| Risks | _(endpoints sobre budget, entorno usado, o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| p95 dentro de budget | `/promote` (el gate de perf pasa) |
| p95 excede budget | `/optimize` sobre el endpoint lento, luego re-`/perf-test` |
| Bottleneck en DB detectado | `/optimize` (índices, query) o M08 DB Excellence |
| Sistema se rompe bajo carga | `/fix` + revisar resiliencia (retry/CB/bulkhead) |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Herramienta por contexto

| Contexto | Herramienta | Plantilla |
|----------|-------------|-----------|
| APIs HTTP (default) | k6 | `templates/k6/{smoke,load,spike}.js` |
| YAML declarativo / CI simple | Artillery | `{feature}-load.artillery.yaml` |
| Stacks JVM, escenarios complejos | Gatling | `{feature}-load.gatling.scala` |

### `.king/performance.yaml` — schema y defaults

```yaml
budgets:
  api:
    p50_ms: 100
    p95_ms: 500
    p99_ms: 1000
  enforcement: warn   # warn | block  (block veta /promote a staging/prod)
# defaults seguros si el archivo no existe: p50=100 p95=500 p99=1000 enforcement=warn
```
Plantilla completa: `templates/performance.yaml`.

### Escenarios por defecto

1. **Smoke** — 1 VU, 30s. ¿arranca sin errores? (Phase 3, automático)
2. **Load** — VUs crecientes hasta target, 5min. Comportamiento bajo carga normal.
3. **Spike** — pico repentino al 10×, 30s. ¿se rompe o degrada gracefully?

### Integración con `/promote`

Ver `docs/promote-integration.md` (T-24). Resumen: si `enforcement: block` y el p95 del último
`.king/perf/*-summary.md` excede el budget, `/promote` a staging/prod se veta con el mensaje
`"Performance gate failed: p95 {x}ms > {budget}ms. Run /perf-test and fix before promoting."`.

### Schema `.king/perf/{timestamp}-{feature}-results.json`

```json
{
  "timestamp": "2026-05-28T14:00:00Z",
  "feature": "orders",
  "env": "local",
  "tool": "k6",
  "endpoints": [
    { "method": "POST", "path": "/orders",
      "p50_ms": 80, "p95_ms": 750, "p99_ms": 1100, "error_rate": 0.002,
      "budget_p95_ms": 500, "verdict": "WARNING" }
  ],
  "enforcement": "warn",
  "verdict": "CONDITIONAL"
}
```
