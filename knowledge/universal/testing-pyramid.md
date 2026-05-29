# Testing Pyramid — Estrategia de Testing Completa (M05)

> Knowledge unificada de la pirámide de testing del King Framework.
> Responde: **"¿Qué nivel de testing necesito ahora, y por qué?"**
> Skills relacionados: `/contract-test`, `/mutation-test`, `/property-test`, `/perf-test`, `/qa`.
> Base previa: `knowledge/_inject/testing-essentials.md`, `knowledge/universal/coverage-gate.md`.

---

## 1. Pirámide vs Trofeo

Dos modelos válidos. La elección depende de **dónde vive el riesgo** de tu sistema.

### Pirámide clásica (Mike Cohn)

```
        /  E2E  \         ← Pocos · lentos · frágiles · caros
       / Integr.  \       ← Algunos · verifican conexiones
      /    Unit     \      ← Muchos · rápidos · aislados · baratos
```

Optimiza para **velocidad de feedback**. Ideal cuando la lógica de dominio es rica y
las integraciones son estables.

### Trofeo de testing (Kent C. Dodds)

```
        ___________
       /    E2E     \      ← Pocos
      |  Integration |     ← LA MAYORÍA (el "cuerpo" del trofeo)
       \    Unit     /     ← Los justos
        \   Static  /      ← Base: tipos, lint, compilador
```

Optimiza para **confianza por dólar invertido**. Ideal en frontends y servicios donde
la mayoría de los bugs aparecen en los límites entre módulos, no dentro de funciones puras.

### Trade-off central

| Modelo | Maximiza | Cuesta | Úsalo cuando |
|--------|----------|--------|--------------|
| Pirámide | Velocidad de feedback, aislamiento | Más mocks → tests acoplados a implementación | Dominio con lógica compleja (cálculos, reglas de negocio) |
| Trofeo | Confianza real, refactor-safety | Tests más lentos, setup de integración | Apps con mucho I/O, glue code, UI |

> **Regla King**: no es una guerra religiosa. La capa **Static** (TypeScript, mypy, `go vet`,
> el compilador) es testing gratuito — actívala SIEMPRE antes de discutir pirámide vs trofeo.

---

## 2. Cuándo usar cada nivel — Matriz Costo × Valor × Velocidad

| Nivel | Costo de escribir | Velocidad feedback | Valor (bugs que atrapa) | Skill King |
|-------|-------------------|--------------------|-------------------------|------------|
| **Static** (tipos/lint) | Casi cero | Instantáneo | Errores de tipo, null, imports | (compilador + `/qa`) |
| **Unit** | Bajo | ms | Lógica de negocio, edge cases | `sdd-apply` (TDD), `/qa` |
| **Property** | Medio | s | Boundary conditions, invariantes que casos puntuales no cubren | `/property-test` |
| **Integration** | Medio | s–min | Wiring, queries, serialización | `/qa`, `sdd-apply` |
| **Contract** | Medio | s | Drift entre servicios independientes | `/contract-test` |
| **Mutation** | Alto (tiempo CPU) | min | Tests que pasan pero **no detectan bugs** | `/mutation-test` |
| **E2E** | Alto | min | Flujos críticos completos | `/qa`, `/test-plan` |
| **Performance** | Alto | min | Regresiones de latencia/throughput | `/perf-test` |

### Heurística de decisión

```
¿La función es pura y tiene invariantes claras?        → /property-test
¿Dos servicios se comunican por HTTP?                  → /contract-test
¿El coverage es alto pero dudo de la calidad del test? → /mutation-test
¿Hay un SLA de latencia o riesgo de regresión perf?    → /perf-test
¿Es lógica de negocio simple con casos conocidos?      → Unit (TDD en sdd-apply)
```

---

## 3. Secuencia recomendada

Orden de adopción cuando construyes una feature de cero. Cada nivel asume el anterior:

```
Static  →  Unit  →  Integration  →  Contract  →  Property  →  Mutation  →  E2E  →  Performance
  │         │           │             │             │            │          │          │
 tipos    TDD       wiring/DB     servicios     invariantes   calidad    flujos    latencia
                                  externos                    del test
```

1. **Static** — el compilador y el linter son tu primera suite. Gratis.
2. **Unit** — TDD en `sdd-apply`. Cubre la lógica de dominio. Meta: coverage ≥ threshold (M01).
3. **Integration** — verifica los límites: DB, colas, filesystem.
4. **Contract** (`/contract-test`) — sólo si hay ≥2 servicios independientes que se comunican.
5. **Property** (`/property-test`) — refuerza las funciones puras con generación de inputs.
6. **Mutation** (`/mutation-test`) — valida que los tests de los pasos 2-5 **realmente detectan bugs**.
7. **E2E** — pocos, sobre flujos críticos de negocio.
8. **Performance** (`/perf-test`) — antes de promote a staging/prod.

> **No saltes a mutation/E2E/perf si el coverage unitario está por debajo del threshold.**
> Mutation testing sobre una suite débil sólo te dice lo que ya sabes: faltan tests.

---

## 4. Anti-patrones comunes

| Anti-patrón | Síntoma | Consecuencia | Antídoto |
|-------------|---------|--------------|----------|
| **Ice cream cone** | Mayoría E2E, pocos unit | Suite lenta y frágil, feedback en minutos | Invertir la proporción; bajar lógica a unit/property |
| **Happy-path only** | Sólo se testea el camino feliz | Los bugs viven en los errores y edge cases | `/property-test` + escenarios negativos en `/test-plan` |
| **Mock everything** | Cada dependencia mockeada | Tests verdes con sistema roto en producción | Integration real + `/contract-test` en los límites |
| **Coverage theater** | 100% coverage, `assert true` | Falsa confianza — los tests no fallan ante bugs | `/mutation-test` (mutation score ≥ 80%) |
| **Contract por captura** | "Funciona en mi máquina" entre servicios | Breaking change silencioso en release | `/contract-test` consumer-driven + verificación del proveedor |
| **Perf al final** | Se mide latencia recién en prod | Regresión detectada por usuarios | `/perf-test` con gate p95 antes de `/promote` |
| **Test acoplado a implementación** | Refactor inocuo rompe 30 tests | Los tests frenan el cambio en vez de habilitarlo | Testear comportamiento (entradas/salidas), no internals |

---

## 5. Relación con CASTLE T (y C, E)

Los skills de M05 elevan capas del gate CASTLE de **checklist** a **gate cuantitativo**:

| Skill | Capa CASTLE | Señal que aporta | Umbral por defecto |
|-------|-------------|------------------|--------------------|
| `/contract-test` | **C** (Contracts) | Integraciones con contrato verificado vs sin contrato | 100% integraciones con contrato (WARNING si falta) |
| `/mutation-test` | **T** (Testing) | Mutation score del scope | ≥ 80% (BREACH si menor) |
| `/property-test` | **T** (Testing) | Evidencia de invariantes ejercitadas + contraejemplos | sin contraejemplos sin resolver |
| `/perf-test` | **E** (Evidence) | p50/p95/p99 vs budget | p95 ≤ threshold (`block` veta promote) |

Flujo: cada skill escribe su resumen en `.king/` (`.king/mutation/`, `.king/pact/`, `.king/perf/`),
y `/qa` Fase 5 + `/castle-report` los agregan al score CASTLE del cambio.

> El **Coverage Gate (M01)** mide *cuánto* código ejercitan los tests.
> El **Mutation Gate (M05)** mide *si esos tests sirven*. Son complementarios: coverage alto +
> mutation score bajo = tests que ejecutan código sin verificar nada.

---

## 6. Definición de "Done" por nivel

Un nivel está **completo** cuando cumple su criterio cuantitativo, no cuando "hay tests":

| Nivel | Definición de Done |
|-------|--------------------|
| **Unit** | Coverage del módulo ≥ `thresholds.global` de `.king/coverage.yaml`; casos negativos y edge incluidos |
| **Property** | ≥1 propiedad por función pura crítica; 0 contraejemplos sin resolver; semilla reproducible fijada |
| **Contract** | 100% de integraciones HTTP con contrato Pact; verificación del proveedor en verde |
| **Mutation** | `mutation_score ≥ mutation_score_threshold` (default 80) sobre el scope del cambio |
| **Integration** | Caminos de I/O críticos cubiertos con dependencias reales (no mocks) |
| **E2E** | Flujos críticos de negocio en verde; ejecutados contra entorno realista |
| **Performance** | p95 ≤ budget de `.king/performance.yaml` para los endpoints tocados; smoke + load en verde |

**Definición de Done del módulo completo (CASTLE T FORTIFIED)**:
coverage ≥ threshold **Y** mutation score ≥ threshold **Y** contracts 100% verified **Y** p95 dentro de budget.
