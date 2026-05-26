---
name: optimize
version: 2.0
description: "Workflow de optimización de rendimiento. Usar cuando se necesite: optimizar algoritmos, mejorar complejidad Big O, aplicar design patterns, auditar buenas prácticas de rendimiento, reducir uso de recursos, o mejorar eficiencia sin cambiar comportamiento."
---

# Optimize — Optimización de Rendimiento

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural decisions that guide what optimizations are coherent | Yes | project |
| `.king/knowledge/conventions.md` | Code conventions to maintain in optimized code | Yes | project |
| `knowledge/_inject/performance-essentials.md` | Performance patterns, benchmarking and optimization strategies | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No hay tests que verifiquen el comportamiento actual
- [ ] El scope de optimización no está definido
- [ ] No se ha identificado al menos un hotspot o área de mejora concreta

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA cambiar contratos externos o firmas de funciones públicas
- NUNCA optimizar sin evidencia de necesidad (no prematura)
- NUNCA proceder si los tests no están en verde antes de comenzar

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Código optimizado con comportamiento preservado (en el proyecto)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
Load      Profile   Diagnose  Plan      Execute   Benchmark  Report    Session   Next
```

## Agentes
- **@performance** → Líder: profiling, benchmarks, estrategia
- **@architect** → Diagnóstico: design patterns, anti-patterns
- **@developer** → Implementación incremental
- **@qa** → Verificación de no regresión y benchmarks

## CASTLE: _·A·_·T·L·_ — [ver capas en `skills/_shared/castle-capas.md`]
- **A**: design patterns cambian decisiones arquitectónicas
- **T**: comportamiento externo debe preservarse (todos los tests deben pasar)
- **L**: benchmarks y métricas antes/después como evidencia de logging

---

## Fase 0: Load Context
> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## PHASE 1: Profile (via @performance)

### GATE IN
- [ ] Scope definido y tests en verde

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Complejidad temporal** — Identificar Big O actual de operaciones clave
2. [ ] **Complejidad espacial** — Identificar uso de memoria y allocations
3. [ ] **Hotspots** — Localizar operaciones costosas, iteraciones anidadas, allocations innecesarias
4. [ ] **Baseline** — Ejecutar benchmarks existentes; si no hay, documentar métricas observables
5. [ ] **Tabla de complejidades** — Producir tabla con complejidades actuales por área

### CHECKPOINT
- [ ] Al menos un hotspot identificado y documentado
- [ ] Tabla de complejidades producida

### IF FAILS
> ❌ What to do when Phase 1 CHECKPOINT fails

ERROR: No hotspots identified or baseline metrics unavailable
Cause: No benchmark tools configured, no measurable operations in scope, or all code paths are already optimal.
Recovery:
  [ ] Option A: If no benchmarks exist — document observable metrics manually (response time, memory in task manager, iteration counts) and use them as baseline
  [ ] Option B: If scope is unclear — ask user to narrow scope to a specific slow operation before profiling
  [ ] Option C: If all areas look optimal — document "No significant hotspot found" and skip to Phase 6 Report with current baseline

---

## PHASE 2: Diagnose (via @architect)

### GATE IN
- [ ] Tabla de complejidades de Phase 1 disponible

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Design patterns aplicables** — Mapear candidatos (Strategy, Flyweight, Factory, Observer, Decorator, etc.)
2. [ ] **Anti-patterns presentes** — Identificar (God Object, N+1 queries, inner loop allocations, etc.)
3. [ ] **Violaciones de buenas prácticas** — Estructuras subóptimas, computaciones repetidas, etc.
4. [ ] **Priorización** — Ordenar por impacto potencial vs. riesgo de cambio

### CHECKPOINT
- [ ] Lista priorizada de oportunidades con impacto estimado producida

### IF FAILS
> ❌ What to do when Phase 2 CHECKPOINT fails

ERROR: No optimization opportunities identified or prioritization impossible
Cause: Code is already well-structured, or complexity analysis insufficient to rank opportunities.
Recovery:
  [ ] Option A: If the code is already optimal — document "No actionable opportunities found" and escalate to user with current complexity analysis
  [ ] Option B: If anti-patterns found but hard to rank — use CVSS-style scoring: impact × likelihood; document uncertainty in the prioritization
  [ ] Option C: Skip Phase 3-4 and go to Phase 6 Report if no opportunities justify the optimization effort

---

## PHASE 3: Plan (via @architect + @performance)

### GATE IN
- [ ] Lista priorizada de Phase 2 disponible

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Estrategia** — Seleccionar optimizaciones a implementar
2. [ ] **Especificación** — Para cada optimización: cambio concreto, mejora esperada (ej: O(n²) → O(n log n)), riesgos
3. [ ] **Aprobación** — Presentar plan al usuario y esperar confirmación explícita

### CHECKPOINT
- [ ] Plan aprobado por usuario y/o @architect

### IF FAILS
> ❌ What to do when Phase 3 CHECKPOINT fails

ERROR: Optimization plan not approved — user or @architect rejects the proposed approach
Cause: Risk-to-benefit ratio unacceptable, proposed changes too invasive, or timeline constraint.
Recovery:
  [ ] Option A: If approach is too risky — propose a conservative subset (only the lowest-risk optimizations) and re-present for approval
  [ ] Option B: If user defers — document the plan in `.king/docs/` as "Deferred Optimization Plan" for future use and close with current baseline
  [ ] Option C: If @architect rejects — incorporate architectural feedback, revise the plan, and re-present

---

## PHASE 4: Execute (via @developer)

### GATE IN
- [ ] Plan aprobado; tests en verde

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS — aplicar por cada optimización del plan

1. [ ] **Cambio mínimo** — Solo lo especificado en el plan
2. [ ] **Verificar sintaxis** — Compilación o lint sin errores
3. [ ] **Ejecutar tests** — DEBEN seguir en verde; si alguno falla: REVERTIR inmediatamente
4. [ ] **Commit incremental** — Un commit por optimización: `perf(scope): descripción`

### CHECKPOINT
- [ ] Tests pasan después de cada optimización
- [ ] Ningún contrato externo ni firma pública modificado

### IF FAILS
> ❌ What to do when Phase 4 CHECKPOINT fails

ERROR: Tests fail after optimization — correctness regression detected
Cause: Optimization changed observable behavior, broke a contract, or introduced a logic error.
Recovery:
  [ ] Option A: REVERT immediately — `git revert HEAD` for the failing optimization; do not accumulate broken changes
  [ ] Option B: After reverting, analyze why the test failed — was it the optimization itself or a brittle test? Fix the root cause before retrying
  [ ] Option C: If multiple optimizations were applied, revert one at a time (most recent first) until tests go green, then retry individually

---

## PHASE 5: Benchmark (via @qa + @performance)

### GATE IN
- [ ] Todas las optimizaciones de Phase 4 ejecutadas con tests en verde

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Benchmarks** — Si existen: ejecutar y comparar con baseline. Si no: comparar complejidades teóricas
2. [ ] **Smoke tests** — Verificar comportamiento externo idéntico
3. [ ] **Delta documentado** — Rendimiento obtenido vs. estimado en el plan

### CHECKPOINT
- [ ] Mejora medible documentada
- [ ] Comportamiento externo preservado verificado

### IF FAILS
> ❌ What to do when Phase 5 CHECKPOINT fails

ERROR: No measurable improvement or regression in benchmarks after optimization
Cause: Optimization did not affect the measured hotspot, benchmark noise too high, or optimization was in a cold path.
Recovery:
  [ ] Option A: If improvement exists but benchmark noise is high — run ≥5 iterations and report average; document variance
  [ ] Option B: If no improvement — document "Optimization applied but no measurable speedup in benchmark; theoretical complexity improved" — this is still valid
  [ ] Option C: If benchmarks show regression — revert the optimization (same as Phase 4 Option A) and document why it degraded performance (e.g., cache miss, increased memory pressure)

---

## PHASE 6: Report

### GATE IN
- [ ] Benchmarks y delta de Phase 5 documentados

### MUST DO
1. [ ] **Generar reporte**:

```
## Optimization Report
### Target: [qué se optimizó]
### Motivación: [hotspot identificado]

### Complejidades
| Área | Big O Antes | Big O Después | Mejora |
|------|-------------|---------------|--------|

### Design Patterns Aplicados
| Pattern | Contexto | Justificación |
|---------|----------|---------------|

### Benchmarks
| Métrica | Antes | Después | Delta |
|---------|-------|---------|-------|

### Comportamiento: [PRESERVADO|MODIFICADO]
### CASTLE Score: [A + T + L]
```

### CHECKPOINT
- [ ] Reporte generado con todas las secciones completas

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Sesión registrada

---

## Execution Summary

> Completar usando el template en `skills/_shared/skill-envelope.md`.

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | `FORTIFIED` \| `CONDITIONAL` \| `BREACHED` |
| Artifacts | _lista de archivos optimizados, o "None"_ |
| Next Recommended | `/review` \| `/qa` \| `/merge` |
| Risks | _riesgos identificados, o "None"_ |

## Fase 7: Write Session
> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

## Fase 8: Guide Next Step
> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Siempre (optimización completa) | `/review` |

---
## REFERENCE

> 📚 Información adicional. Esta sección NO contiene acciones, solo contexto.

### Optimizaciones válidas
- Reducción de complejidad temporal (ej: O(n²) → O(n log n))
- Reducción de complejidad espacial
- Aplicación de design patterns
- Caching/memoización donde el valor se calcula múltiples veces
- Lazy evaluation para recursos costosos
- Resource pooling
- Eliminación de operaciones redundantes en hot paths

### Optimizaciones NO válidas (sin Feature/ADR)
- Cambiar contratos externos o firmas públicas
- Optimizar sin evidencia de hotspot
- Micro-optimizaciones sin impacto medible en el contexto del proyecto

### Boundary con /refactor
- `/refactor` = mejoras estructurales (extract, rename, reorganize, simplify logic)
- `/optimize` = mejoras de complejidad algorítmica y design patterns
- Son complementarios: `/refactor` → `/optimize` → `/review`

### Integración SDD
Este skill puede ejecutarse como parte del pipeline SDD durante la fase `verify`.
Ver `rules.verify.quality_skills` en `.king/sdd/config.yaml`.
Cuando se invoca desde SDD, el scope se limita a los archivos del cambio activo.
