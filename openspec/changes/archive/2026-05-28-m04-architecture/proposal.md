# Proposal — M04 Architecture & Patterns

> Fase: sdd-propose · Change: m04-architecture · Backend: openspec

## Why

King Framework genera código funcional pero **no opina sobre la arquitectura que lo contiene**.
Las decisiones de patrón (Clean vs Hexagonal, CQRS vs CRUD, Saga vs 2PC, retry seguro vs duplicados)
se dejan al criterio del developer sin scaffolding, guidance ni gates. El `@architect` valida decisiones
ya tomadas pero carece del conocimiento de dominio empaquetado como skills accionables. Resultado:
N+1 queries en producción, transacciones distribuidas inconsistentes, llamadas externas sin resiliencia,
microservicios sin contract testing.

M01 (Quality Gates) y M07 (Multi-tenancy/Security) ya están implementados — las dependencias están satisfechas.

## What Changes

Se agrega a `king-core` un **skill-set de arquitectura accionable**: 14 skills + 14 commands +
5 knowledge files + 2 hooks, más 3 extensiones aditivas a archivos existentes.

Fuente de verdad: `mejora/planes-detallados/M04-architecture-and-patterns.md` (§2 diseño, §6 tareas, §7 Gherkin).

## Capabilities (contrato para sdd-spec)

| # | Capability (dominio spec) | Item(s) | Artefactos |
|---|---------------------------|---------|------------|
| 1 | `orm-patterns` | M-04 | knowledge orm-patterns.md + skill `/explain-query` + ext. @performance |
| 2 | `saga-design` | M-05 | knowledge saga-patterns.md + skill `/saga-design` |
| 3 | `resilience-weave` | M-10 | knowledge resilience-patterns.md + skill `/resilience-weave` + hook resilience-check |
| 4 | `architecture-patterns` | M-25a-e | knowledge architecture-patterns.md + skills `/clean-arch-setup` `/hexagonal-setup` `/ddd-tactical` `/cqrs-setup` `/event-sourcing` + ext. @architect + ext. sdd-apply Step 0 |
| 5 | `api-contract-first` | M-30 | skill `/api-contract-first` + hook api-change-check |
| 6 | `db-optimize` | M-31 | skill `/db-optimize` (reusa /explain-query) |
| 7 | `distributed-systems` | M-32 | knowledge distributed-systems.md + skills `/microservice-extract` `/event-broker-setup` `/idempotency` |
| 8 | `contract-test-pact` | M-36 | skill `/contract-test-pact` |

**Total**: 14 skills, 14 commands, 5 knowledge, 2 hooks, 3 extensiones aditivas.

## Scope

- **In scope**: creación de los 14 skills/commands, 5 knowledge, 2 hooks; extensiones aditivas a
  `agents/performance.md`, `agents/architect.md`, `skills/sdd-apply/SKILL.md`; conformidad anatomía v2.0.
- **Out of scope**: ejecución real de los skills sobre proyectos externos; implementación de las
  herramientas externas que los skills documentan (openapi-generator, Pact, etc. — son guidance, no binarios).

## Affected modules

`king-core/skills/` (14 nuevos), `king-core/commands/` (14 nuevos), `king-core/knowledge/domain/` (5 nuevos),
`king-core/hooks/hooks.json` (2 entries), `king-core/agents/{performance,architect}.md`, `king-core/skills/sdd-apply/SKILL.md`.

## Delivery

- **single-pr** con `size:exception` (scope ~138h supera el budget de 400 líneas a propósito).
- Worktree `feature/m04-architecture` desde develop → un único `/merge` a develop tras CASTLE FORTIFIED.
- Mitigación de tamaño: `/review` por sprint para trazabilidad incremental.

## Rollback plan

- Todo el trabajo vive aislado en el worktree/branch `feature/m04-architecture`. Si se aborta antes del merge,
  basta `/worktree delete m04-architecture` + borrar el branch — develop queda intacto.
- Las 3 extensiones son **aditivas** (verificadas por git diff); revertir = quitar las secciones añadidas.
- Los 2 hooks se añaden con `enforcement: warn` (no bloquean); revertir = quitar las entries del array.
