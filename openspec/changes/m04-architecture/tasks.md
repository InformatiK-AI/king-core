# Tasks — M04 Architecture & Patterns

> Detalle largo (criterios, paths, horas) en `mejora/planes-detallados/M04-architecture-and-patterns.md §6`.
> Aquí: 43 tareas de 1 línea en 5 fases. Marcar `[x]` al completar (sdd-apply).

## Sprint 1 — ORM + Saga + Resilience knowledge (T01-T11)
- [ ] T01 Verificar que los 14 paths de skills y 5 de knowledge no existen
- [ ] T02 Leer `agents/performance.md` (extension points para ORM)
- [ ] T03 Leer `skills/sdd-apply/SKILL.md` (punto de integración Step 0)
- [ ] T04 knowledge `orm-patterns.md` (4 patrones, 4 anti-patrones, 6 ORMs)
- [ ] T05 skill `explain-query` (5 fases, 6 dialectos, degrada sin DB)
- [ ] T06 command `explain-query.md` (ejemplo N+1 + CREATE INDEX)
- [ ] T07 Extender `agents/performance.md` con "ORM Checks" (aditivo)
- [ ] T08 knowledge `saga-patterns.md` (9 patrones + tabla comparativa)
- [ ] T09 skill `saga-design` (6 fases, 4 techs, outbox no-opcional)
- [ ] T10 command `saga-design.md` (ejemplo orden e-commerce)
- [ ] T11 knowledge `resilience-patterns.md` (9 patrones + libs por stack)

## Sprint 2 — Resilience Weaver + Clean/Hexagonal (T12-T19)
- [ ] T12 skill `resilience-weave` (10 fases, Classify antes de retry)
- [ ] T13 command `resilience-weave.md` (antes/después Node.js)
- [ ] T14 hook `resilience-check` en `hooks.json` (PostToolUse, warn, aditivo)
- [ ] T15 knowledge `architecture-patterns.md` (5 patrones + combinaciones)
- [ ] T16 skill `clean-arch-setup` (scaffold por stack + arch tests + ADR-001)
- [ ] T17 command `clean-arch-setup.md` (árbol Go + TS)
- [ ] T18 skill `hexagonal-setup` (ports driving/driven + boundary tests)
- [ ] T19 command `hexagonal-setup.md` (UserRepository port vs adapter)

## Sprint 3 — DDD/CQRS/ES + API Contract (T20-T30)
- [ ] T20 skill `ddd-tactical` (aggregate, VO, domain events, invariants)
- [ ] T21 command `ddd-tactical.md` (ejemplo Order aggregate)
- [ ] T22 skill `cqrs-setup` (command/query bus, read models, enforced)
- [ ] T23 command `cqrs-setup.md` (CreateOrder + GetOrderById)
- [ ] T24 skill `event-sourcing` (event store, snapshots, 3 preguntas)
- [ ] T25 command `event-sourcing.md` (schema + apply method)
- [ ] T26 Extender `agents/architect.md` con Patterns Knowledge + árbol decisión (aditivo)
- [ ] T27 Integrar `sdd-apply` Step 0 — Architecture Pattern (salteable, aditivo)
- [ ] T28 skill `api-contract-first` (7 fases, oasdiff breaking change)
- [ ] T29 command `api-contract-first.md` (breaking change report)
- [ ] T30 hook `api-change-check` en `hooks.json` (PostToolUse, warn, aditivo)

## Sprint 4 — DB Excellence + Distributed + Pact (T31-T41)
- [ ] T31 skill `db-optimize` (8 fases, reusa explain-query, handoff db-migrate)
- [ ] T32 command `db-optimize.md` (FK sin índice + caching)
- [ ] T33 knowledge `distributed-systems.md` (CAP, brokers, anti-patrones)
- [ ] T34 skill `microservice-extract` (Strangler Fig, fases go/no-go, tenancy M07)
- [ ] T35 command `microservice-extract.md` (extracción de pagos)
- [ ] T36 skill `event-broker-setup` (4 brokers, DLQ, testcontainers)
- [ ] T37 command `event-broker-setup.md` (topic + producer + consumer)
- [ ] T38 skill `idempotency` (3 strategies, middleware dedup, TTL)
- [ ] T39 command `idempotency.md` (middleware Express + Redis)
- [ ] T40 skill `contract-test-pact` (6 fases, HTTP/gRPC/message)
- [ ] T41 command `contract-test-pact.md` (Order↔Payment HTTP)

## Sprint 5 — Validación (T42-T43)
- [ ] T42 `/qa` completo sobre los artefactos (CASTLE FORTIFIED, anatomía v2.0)
- [ ] T43 Verificar integración `@architect` extendido (árbol de decisión correcto)

---

## Review Workload Forecast
- Estimated lines: >> 400 (14 skills + 14 commands + 5 knowledge + 3 ext + 2 hooks)
- 400-line budget risk: **High**
- Chained PRs recommended: No (decisión del usuario)
- Decision needed before apply: **Resuelta** → `delivery_strategy: single-pr`, `size:exception` aceptada
- Quality gate: `/review` por sprint (trazabilidad incremental), CASTLE FORTIFIED antes del merge único
