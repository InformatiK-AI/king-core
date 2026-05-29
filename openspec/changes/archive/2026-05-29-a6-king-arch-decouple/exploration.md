# Exploration — A6 king-arch decouple

> Fase: sdd-explore · Change: a6-king-arch-decouple

## Pregunta central

¿Qué se mueve a king-arch y qué queda en king-core como kernel compartido, sin violar la dirección de dependencias
(king-core NUNCA depende de un hijo)?

## Las 12 skills (confirmadas)

Las 14 skills de patrones entregadas en M04, menos las 2 que A3 movió a king-infra (`db-optimize`, `explain-query`):

`clean-arch-setup`, `hexagonal-setup`, `ddd-tactical`, `cqrs-setup`, `event-sourcing`, `saga-design`,
`resilience-weave`, `idempotency`, `api-contract-first`, `contract-test-pact`, `microservice-extract`,
`event-broker-setup`. Todas son `SKILL.md` monolíticos (sin sub-archivos), cada una con su `commands/<n>.md`.

## Evidencia de grep — move/stay del knowledge/domain

| Archivo | Consumidores reales (grep, excl. openspec) | Decisión |
|---------|--------------------------------------------|----------|
| `saga-patterns.md` | SOLO saga-design, microservice-extract, idempotency, event-broker-setup, contract-test-pact (5 de las 12) + LOAD-INDEX + sus commands | **MUEVE** |
| `distributed-systems.md` | SOLO microservice-extract, idempotency, event-broker-setup (3 de las 12) + LOAD-INDEX + sus commands | **MUEVE** |
| `architecture-patterns.md` | 5 de las 12 **+ `agents/architect.md` (110, 237) + `skills/sdd-apply` (41)** | **QUEDA** (cross-read) |
| `resilience-patterns.md` | `resilience-weave` **+ `hooks/resilience-check.sh`** | **QUEDA** (cross-read) |
| `orm-patterns.md` | Ninguna de las 12; solo `agents/performance.md` | **QUEDA** (kernel) |

Regla de decisión: lo **exclusivo de las 12** se mueve; lo **compartido con kernel/agentes/hooks** queda y se lee
cross-plugin (precedente A3, que dejó `orm-patterns.md` en king-core para king-infra).

## Precedentes verificados (anatomía de hijos)

- **king-infra NO tiene `hooks/`** → los 2 hooks M04 (`resilience-check.sh`, `api-change-check.sh`) QUEDAN en king-core.
  Ya degradan graceful (`exit 0` si no aplica); solo cambia el texto del warning sugerido.
- **king-infra DUPLICÓ `skills/_shared/`** (18 archivos) → king-arch duplica los `_shared/` que las 12 referencian,
  en vez de cross-read frágil.
- **A3 mantuvo los live-specs** de skills movidas en `king-core/openspec/specs/` → A6 hace lo mismo.

## Sitios king-core → skill movida (reescritura graceful)

`agents/architect.md` (árbol de decisión ~40, 110-135), `skills/sdd-apply/SKILL.md` (38-42),
`knowledge/domain/saga-patterns.md` (304, 502 — se ajustan en su nuevo hogar),
`knowledge/domain/resilience-patterns.md` (4, 397), `hooks/resilience-check.sh` (46, texto),
`hooks/api-change-check.sh` (41, texto). Verificado por grep: `build/review/plan/refactor/qa/castle/optimize/radar/fix/genesis`
y los `*.template` NO referencian las 12.

## Registro / instalabilidad

`marketplace.json` vive en `proyectos referencia/King/king-marketplace/.claude-plugin/` y está desactualizado (omite
king-content/infra/ai/mobile/legal). Para king-arch instalable: entrada en `plugins[]` + `requires:[king-framework]`.
Recomendado regularizar los plugins faltantes en el mismo cambio.
