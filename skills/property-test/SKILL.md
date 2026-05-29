---
name: property-test
version: 2.0
api_version: 1.0.0
description: "Genera property-based tests para funciones puras e invariantes de dominio. Usar cuando se necesite: property testing, property-based testing, generar tests con fast-check/hypothesis/jqwik/rapid, ejercitar boundary conditions, encontrar contraejemplos con shrinking, validar invariantes (round-trip, idempotencia, monotonía), o reforzar CASTLE T más allá de casos puntuales."
---

# /property-test — Property-Based Testing

Dada una función pura o una invariante de dominio, genera property tests que ejercitan
boundary conditions y valores extremos, con shrinking automático para reportar el
contraejemplo mínimo. Alimenta la capa **CASTLE T** con evidencia de invariantes.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/universal/testing-pyramid.md` | Posición del property testing y los 5 tipos de propiedades | No | framework |
| `knowledge/_inject/testing-essentials.md` | Patrones de testing base y naming | No | framework |
| `.king/knowledge/stack.md` | Stack para elegir la librería de property testing | No | project |
| `.king/knowledge/conventions.md` | Convenciones para nombrar y ubicar los tests generados | No | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión previa de `/genesis` en el proyecto (`.king/` ausente)
- [ ] No se identifica función objetivo ni invariante (ni por `--target` ni por contexto)
- [ ] No se detecta librería de property testing para el stack ni se puede instalar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA generar un property test sin una propiedad verificable (assert sobre invariante)
- NUNCA fijar una semilla aleatoria distinta en cada corrida — la semilla DEBE ser reproducible
- NUNCA reportar el contraejemplo original sin aplicar shrinking al mínimo

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] `tests/properties/{module}.property.test.{ext}` — suite de property tests
- [ ] `.king/sessions/.../property-summary.md` (o sección en session doc) con propiedades y contraejemplos
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Identify)(SelectTypes)(Generate)(Run+CE)(CASTLE T)(Session) (Guide)
```

### PARÁMETROS
```
/property-test [--target <path>] [--invariant "<texto>"] [--runs <n>] [--stack <ts|python|java|go>]
```
- `--target <path>`: función o módulo objetivo
- `--invariant "<texto>"`: invariante en lenguaje natural (ej: "el resultado nunca es negativo")
- `--runs <n>`: número de ejemplos por propiedad (default: 100)
- `--stack`: forzar stack si la autodetección falla

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.

## Agentes
- **@qa** — Agente principal: selecciona tipos de propiedad y valida cobertura de invariantes
- **@developer** — Identifica funciones puras y genera arbitraries tipados

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Identify Functions + Invariants

### GATE IN
- [ ] `.king/` existe (genesis ejecutado)
- [ ] `--target` o contexto con función identificable

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Detectar stack** y mapear a la librería de property testing (ver REFERENCE)
2. [ ] **Localizar la función objetivo** desde `--target` o del contexto; preferir funciones puras (sin side effects)
3. [ ] **Extraer firma** — tipos de entrada y salida para construir arbitraries
4. [ ] **Capturar invariantes** — de `--invariant` (lenguaje natural) y/o inferidas de la firma y el dominio

### CHECKPOINT
- [ ] Función objetivo localizada con firma conocida
- [ ] ≥1 invariante candidata identificada
- [ ] Librería de property testing del stack seleccionada

### OUTPUTS
- Variables: `STACK`, `LIB`, `TARGET`, `SIGNATURE`, `INVARIANTS[]`, `EXT`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se identificó función o invariante.
Cause: target ausente o función con demasiados side effects.
Recovery:
  [ ] Option A: pedir `--target` explícito al usuario
  [ ] Option B: si la función no es pura → sugerir extraer el núcleo puro antes de property-testear
  [ ] Option C: pedir al usuario una invariante en lenguaje natural con `--invariant`

---

## Phase 2: Select Property Types

### GATE IN
- [ ] Función e invariantes identificadas (Phase 1)

### MUST DO
1. [ ] **Mapear invariantes a los 5 tipos** (ver REFERENCE): round-trip, idempotency, monotonicity, invariants, oracle
2. [ ] **Elegir las propiedades aplicables** — p.ej. si hay serialize/parse → round-trip; si hay implementación de referencia → oracle
3. [ ] **Definir arbitraries** apropiados por tipo de entrada (rangos, generadores tipados)

### CHECKPOINT
- [ ] ≥1 tipo de propiedad seleccionado y justificado
- [ ] Arbitraries definidos para cada parámetro de entrada

### OUTPUTS
- Variables: `PROPERTY_TYPES[]`, `ARBITRARIES[]`

### IF FAILS
ERROR: Ninguna propiedad aplicable.
Cause: la función no expone invariantes claras.
Recovery:
  [ ] Option A: usar el tipo `invariants` con la postcondición más básica (ej. tipo/rango del resultado)
  [ ] Option B: documentar que property testing aporta poco aquí y recomendar unit tests de ejemplo

---

## Phase 3: Generate Property Tests

### GATE IN
- [ ] Tipos de propiedad y arbitraries definidos (Phase 2)

### MUST DO
1. [ ] **Generar** `tests/properties/{TARGET}.property.test.{EXT}` con una propiedad por invariante
2. [ ] **Fijar semilla reproducible** — configurar la librería con seed fija (ej. fast-check `{ seed }`)
3. [ ] **Limitar runs** — usar `--runs` o default 100 para evitar sobrecargar la suite

### CHECKPOINT
- [ ] `tests/properties/{TARGET}.property.test.{EXT}` existe con ≥1 propiedad
- [ ] Semilla reproducible fijada
- [ ] Límite de runs configurado

### OUTPUTS
- `tests/properties/{TARGET}.property.test.{EXT}`

### IF FAILS
ERROR: No se pudo generar el property test.
Cause: librería no instalada o arbitraries inválidos.
Recovery:
  [ ] Option A: guiar instalación de la librería (ver REFERENCE) y reintentar
  [ ] Option B: simplificar arbitraries a tipos primitivos y reintentar

---

## Phase 4: Run + Interpret Counterexamples

### GATE IN
- [ ] Property test generado (Phase 3)

### MUST DO
1. [ ] **Ejecutar** la suite de property tests
2. [ ] **Si falla** — capturar el contraejemplo tras shrinking (mínimo, no el original grande)
3. [ ] **Sugerir** un unit test de regresión basado en el contraejemplo mínimo
4. [ ] **Distinguir** bug en producción vs invariante mal formulada (no asumir que el código está mal)

### CHECKPOINT
- [ ] Suite ejecutada; resultado capturado (pass o contraejemplo mínimo)
- [ ] Si hay contraejemplo: test de regresión sugerido

### OUTPUTS
- Resultado de ejecución + contraejemplos mínimos

### IF FAILS
ERROR: La ejecución no produjo resultado interpretable.
Cause: test flaky o shrinking no convergió.
Recovery:
  [ ] Option A: reducir el espacio del arbitrary y reintentar
  [ ] Option B: reportar el contraejemplo original con WARN si el shrinking no convergió

---

## Phase 5: CASTLE T Evidence

### GATE IN
- [ ] Resultado de ejecución disponible (Phase 4)

### MUST DO
1. [ ] **Documentar** propiedades ejercitadas, runs, semilla y contraejemplos en el summary
2. [ ] **Evaluar veredicto T**: PASS si 0 contraejemplos sin resolver; CONDITIONAL si hay contraejemplos pendientes
3. [ ] **Registrar** la evidencia para consumo de `/qa` Fase 5

### CHECKPOINT
- [ ] Summary con propiedades + resultado + veredicto T

### OUTPUTS
- `property-summary.md` (o sección en el session doc)

### IF FAILS
ERROR: No se pudo consolidar evidencia.
Cause: resultados incompletos.
Recovery:
  [ ] Option A: emitir summary parcial con lo ejecutado y marcar WARN

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] `tests/properties/{TARGET}.property.test.{EXT}`
  - [ ] Summary de propiedades/contraejemplos
- [ ] Semilla reproducible fijada en el test generado
- [ ] Contraejemplos (si los hay) reportados tras shrinking al mínimo
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(0 contraejemplos=FORTIFIED; pendientes=CONDITIONAL)_ |
| Artifacts | _(property test, summary)_ |
| Next Recommended | `/mutation-test` (validar fuerza) o `/qa` |
| Risks | _(contraejemplos sin resolver, invariantes débiles, o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Propiedades en verde | `/mutation-test` (confirmar que matan mutantes) |
| Contraejemplo encontrado | `/fix` con el test de regresión sugerido |
| Invariante mal formulada | Reajustar `--invariant` y re-ejecutar |
| Función no pura | Refactor para extraer núcleo puro (`/refactor`) antes de property-testear |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Librería de property testing por stack

| Stack | Librería | API clave |
|-------|----------|-----------|
| TypeScript/JS | `fast-check` | `fc.assert(fc.property(arb, pred), { seed, numRuns })` |
| Python | `hypothesis` | `@given(strategy)`, `@settings(max_examples)`, `@seed(...)` |
| Java | `jqwik` | `@Property`, `@ForAll`, `@Seed` |
| Go | `rapid` | `rapid.Check(t, func(t *rapid.T){...})` |
| Haskell | `QuickCheck` | referencia conceptual (el original) |

### Los 5 tipos de propiedades

| Tipo | Forma | Ejemplo |
|------|-------|---------|
| **Round-trip** | `parse(serialize(x)) == x` | JSON encode/decode, formato↔valor |
| **Idempotency** | `f(f(x)) == f(x)` | normalize, sort, dedupe |
| **Monotonicity** | `a ≤ b ⇒ f(a) ≤ f(b)` | precio→impuesto, ranking |
| **Invariants** | postcondición siempre cierta | "resultado nunca NaN", "len(out) ≤ len(in)" |
| **Oracle** | `f(x) == referencia(x)` | impl optimizada vs impl simple de referencia |

Ejemplos ejecutables de los 5 tipos: `examples/property-types.ts` y `examples/property_types.py`.

### Reproducibilidad

Siempre fijar `seed`. Sin semilla, un fallo intermitente es irreproducible y el contraejemplo
se pierde. fast-check: `{ seed: 42 }`; hypothesis: `@seed(42)`; jqwik: `@Seed("42")`; rapid usa
`-rapid.seed`. El contraejemplo mínimo (tras shrinking) es lo que se convierte en unit test.

### Degradación grácil

Stack sin librería en la tabla → informar el equivalente más cercano y guiar instalación,
en lugar de fallar.
