---
name: mutation-test
version: 2.0
api_version: 1.0.0
description: "Ejecuta mutation testing para validar que los tests detectan bugs reales. Usar cuando se necesite: mutation testing, medir mutation score, validar calidad de la suite de tests, detectar tests débiles (assert true), encontrar mutantes sobrevivientes, o elevar CASTLE T de coverage a gate cuantitativo de calidad."
model: sonnet
---

# /mutation-test — Mutation Testing

Inyecta mutaciones en el código del scope seleccionado y verifica si los tests las
detectan. Un coverage alto con mutation score bajo significa tests que ejecutan código
sin verificar nada. Alimenta la capa **CASTLE T** con un gate cuantitativo.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/universal/testing-pyramid.md` | Por qué mutation > coverage y su relación con CASTLE T | No | framework |
| `knowledge/universal/coverage-gate.md` | Schema de `.king/coverage.yaml` que este skill extiende | No | framework |
| `.king/coverage.yaml` | Umbral `mutation_score_threshold` del proyecto | No | project |
| `.king/knowledge/stack.md` | Stack para elegir el motor de mutación correcto | No | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión previa de `/genesis` en el proyecto (`.king/` ausente)
- [ ] No existe una suite de tests ejecutable en el proyecto (mutation testing requiere tests previos)
- [ ] No se detecta motor de mutación para el stack ni se puede instalar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA ejecutar sobre el proyecto completo sin confirmación explícita del usuario (riesgo de timeout)
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA reportar PASS sin un mutation score numérico calculado
- NUNCA modificar el código de producción para "matar" mutantes — sólo se generan o sugieren TESTS

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] `.king/mutation/{timestamp}-report.json` — reporte machine-readable
- [ ] `.king/mutation/{timestamp}-summary.md` — resumen para CASTLE T
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Tool+Scope)(Run)(Parse)(Stubs)(CASTLE T)(Session) (Guide)
```

### PARÁMETROS
```
/mutation-test [--scope <path>] [--threshold <n>] [--full] [--stack <ts|python|java|go>]
```
- `--scope <path>`: archivo o módulo a mutar (default: changed files del branch)
- `--threshold <n>`: override del `mutation_score_threshold` (default: `.king/coverage.yaml` o 80)
- `--full`: ejecutar sobre el proyecto completo (requiere confirmación; advierte el costo)
- `--stack`: forzar stack si la autodetección falla

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.

## Agentes
- **@qa** — Agente principal: interpreta mutation score, prioriza mutantes críticos
- **@developer** — Genera los test stubs que matan los mutantes sobrevivientes

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Tool + Scope

### GATE IN
- [ ] `.king/` existe (genesis ejecutado)
- [ ] Existe suite de tests ejecutable

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Detectar stack** y mapear al motor de mutación (ver tabla en REFERENCE)
2. [ ] **Verificar instalación** del motor; si falta, guiar la instalación con el package manager del proyecto
3. [ ] **Resolver scope**: usar `--scope`; si no, derivar de `git diff` de changed files del branch
4. [ ] **Guard de scope completo**: si el scope es el proyecto entero (o `--full`), advertir el costo estimado ("puede tardar 30-60 min") y **solicitar confirmación explícita**
5. [ ] **Leer threshold**: `--threshold` > `.king/coverage.yaml::mutation_score_threshold` > default 80

### CHECKPOINT
- [ ] Motor de mutación detectado e instalado
- [ ] Scope acotado y confirmado (con confirmación explícita si es full)
- [ ] `THRESHOLD` numérico resuelto

### OUTPUTS
- Variables: `STACK`, `ENGINE`, `SCOPE`, `THRESHOLD`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo preparar el mutation testing.
Cause: motor no instalado, sin tests, o scope ambiguo.
Recovery:
  [ ] Option A: guiar instalación del motor (ver REFERENCE) y reintentar
  [ ] Option B: si no hay tests → BLOCKED, recomendar `sdd-apply`/`/qa` para crear suite primero
  [ ] Option C: si el scope es enorme → forzar `--scope` a un módulo específico

---

## Phase 2: Run Mutation Testing

### GATE IN
- [ ] Motor, scope y threshold definidos (Phase 1)

### MUST DO
1. [ ] **Ejecutar el motor** sobre el `SCOPE` con su comando nativo (ver REFERENCE)
2. [ ] **Capturar salida** (mutation score, mutantes totales, killed, survived, no-coverage, timeout)
3. [ ] **Manejar timeouts** — si el motor reporta timeouts masivos, reducir scope y reintentar una vez

### CHECKPOINT
- [ ] El motor terminó y produjo un reporte (JSON/XML/HTML según el tool)
- [ ] Mutation score numérico capturado

### OUTPUTS
- Salida cruda del motor (en `.king/mutation/`)

### IF FAILS
ERROR: El motor de mutación falló o no terminó.
Cause: timeout global, error de configuración, o tests flaky.
Recovery:
  [ ] Option A: reducir `SCOPE` a un único archivo y reintentar
  [ ] Option B: aumentar el timeout del motor en su config
  [ ] Option C: si los tests son flaky → recomendar `/fix` sobre los tests inestables primero

---

## Phase 3: Parse Surviving Mutants

### GATE IN
- [ ] Reporte del motor disponible

### MUST DO
1. [ ] **Normalizar** la salida del motor a `.king/mutation/{timestamp}-report.json` (schema en REFERENCE)
2. [ ] **Listar mutantes sobrevivientes** con archivo, línea, operador de mutación y código original→mutado
3. [ ] **Priorizar** top-10 por criticidad (lógica de negocio > glue code)

### CHECKPOINT
- [ ] `.king/mutation/{timestamp}-report.json` existe
- [ ] Lista de sobrevivientes con ubicación exacta

### OUTPUTS
- `.king/mutation/{timestamp}-report.json`

### IF FAILS
ERROR: No se pudieron parsear los resultados.
Cause: formato de salida inesperado del motor.
Recovery:
  [ ] Option A: leer el reporte HTML/texto del motor y extraer score + sobrevivientes manualmente
  [ ] Option B: emitir report.json parcial con lo disponible y marcar WARN

---

## Phase 4: Generate Missing Test Stubs

### GATE IN
- [ ] Lista de mutantes sobrevivientes (Phase 3)

### MUST DO
1. [ ] **Por cada mutante crítico**, generar un test stub que lo mataría (assert sobre el comportamiento que la mutación rompe)
2. [ ] **No tocar producción** — sólo crear/ampliar archivos de test
3. [ ] **Sugerir ≥3 tests** adicionales para los mutantes de mayor criticidad

### CHECKPOINT
- [ ] Stubs/sugerencias de test generados para los mutantes top
- [ ] Ningún archivo de producción modificado

### OUTPUTS
- Test stubs (en la carpeta de tests del proyecto) o sugerencias en el summary

### IF FAILS
ERROR: No se pudieron generar stubs.
Cause: no se identifica el comportamiento esperado del mutante.
Recovery:
  [ ] Option A: documentar el mutante en el summary y dejar el stub como TODO con contexto
  [ ] Option B: pedir al usuario el comportamiento esperado de la función afectada

---

## Phase 5: CASTLE T Gate

### GATE IN
- [ ] `report.json` con mutation score (Phase 3)

### MUST DO
1. [ ] **Evaluar gate**: `mutation_score >= THRESHOLD` → PASS; si menor → BREACH
2. [ ] **Escribir** `.king/mutation/{timestamp}-summary.md` con score, threshold, margen, top-10 sobrevivientes y tests sugeridos
3. [ ] **Asignar veredicto CASTLE T**: PASS (FORTIFIED) | BREACH (BLOCKED)

### CHECKPOINT
- [ ] `.king/mutation/{timestamp}-summary.md` existe
- [ ] Veredicto T asignado con score y threshold explícitos

### OUTPUTS
- `.king/mutation/{timestamp}-summary.md`

### IF FAILS
ERROR: No se pudo evaluar el gate.
Cause: score no numérico.
Recovery:
  [ ] Option A: recalcular score desde report.json (killed / (killed+survived))
  [ ] Option B: emitir summary CONDITIONAL con nota de incertidumbre

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] `.king/mutation/{timestamp}-report.json`
  - [ ] `.king/mutation/{timestamp}-summary.md`
- [ ] Mutation score numérico calculado y comparado contra threshold
- [ ] Ningún archivo de producción modificado por este skill
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(PASS=FORTIFIED, BREACH=BLOCKED)_ |
| Artifacts | _(report.json, summary.md, test stubs)_ |
| Next Recommended | `/property-test` (score bajo) o `/perf-test` (score OK) |
| Risks | _(mutantes sin matar, scope acotado, o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Mutation score ≥ threshold | `/perf-test` o continuar el pipeline (`/review`/`/merge`) |
| Mutation score < threshold | `/property-test` sobre los módulos con mutantes sobrevivientes |
| Mutantes en lógica crítica | `/fix` para agregar los tests sugeridos y re-ejecutar |
| Scope fue parcial (changed files) | Re-ejecutar con `--scope` ampliado antes de release |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Motor de mutación por stack

| Stack | Motor | Comando | Reporte nativo |
|-------|-------|---------|----------------|
| JS/TS | Stryker | `npx stryker run --mutate "{scope}"` | `reports/mutation/mutation.json` + HTML |
| Python | mutmut | `mutmut run --paths-to-mutate {scope}` | `mutmut results` / `mutmut junitxml` |
| Java | PIT (pitest) | `mvn org.pitest:pitest-maven:mutationCoverage -DtargetClasses={scope}` | `target/pit-reports/` |
| Go | go-mutesting | `go-mutesting {scope}` | stdout (parsear score) |

### Schema `.king/mutation/{timestamp}-report.json`

```json
{
  "timestamp": "2026-05-28T14:00:00Z",
  "stack": "ts",
  "engine": "stryker",
  "scope": "src/billing/calculate-discount.ts",
  "threshold": 80,
  "score": 65.0,
  "totals": { "killed": 13, "survived": 7, "noCoverage": 0, "timeout": 0 },
  "survivors": [
    { "file": "src/billing/calculate-discount.ts", "line": 24,
      "mutator": "ConditionalExpression", "original": "x > 0", "mutated": "x >= 0",
      "criticality": "high" }
  ],
  "verdict": "BREACH"
}
```

### Extensión de `.king/coverage.yaml` (T-13, coordinado con M01)

Este skill añade un campo opcional al schema de coverage (ver `knowledge/universal/coverage-gate.md`):

```yaml
# .king/coverage.yaml
thresholds:
  global: 80
  mutation_score_threshold: 80   # M05: mínimo mutation score (%) para CASTLE T PASS
  mutation_enforcement: warn     # warn | block  (block veta merge/promote)
```

Si el campo no existe, el skill usa default 80 / `warn` y lo documenta en el summary.

### Por qué scope acotado es obligatorio

Mutation testing re-ejecuta la suite una vez por cada mutante. Sobre 500 archivos puede
significar miles de ejecuciones (30-60 min+). El skill SIEMPRE acota a changed files o a un
módulo, y exige confirmación explícita para `--full`. Esto evita bloquear CI por timeout.

### Cálculo del mutation score

```
mutation_score = killed / (killed + survived) × 100
```
(Los mutantes `no-coverage` y `timeout` se reportan aparte; `no-coverage` indica además
una brecha de coverage que el Coverage Gate de M01 debería capturar.)
