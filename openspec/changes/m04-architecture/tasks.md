# Tasks — M04 Architecture & Patterns

> Detalle largo (criterios, paths, horas) en `mejora/planes-detallados/M04-architecture-and-patterns.md §6`.
> Aquí: 43 tareas de 1 línea en 5 fases. Marcar `[x]` al completar (sdd-apply).

## Sprint 1 — ORM + Saga + Resilience knowledge (T01-T11)
- [x] T01 Verificar que los 14 paths de skills y 5 de knowledge no existen
- [x] T02 Leer `agents/performance.md` (extension points para ORM)
- [x] T03 Leer `skills/sdd-apply/SKILL.md` (punto de integración Step 0) — hecho en Sprint 3 (T27)
- [x] T04 knowledge `orm-patterns.md` (4 patrones, 4 anti-patrones, 6 ORMs)
- [x] T05 skill `explain-query` (5 fases, 6 dialectos, degrada sin DB)
- [x] T06 command `explain-query.md` (ejemplo N+1 + CREATE INDEX)
- [x] T07 Extender `agents/performance.md` con "ORM Checks" (aditivo)
- [x] T08 knowledge `saga-patterns.md` (9 patrones + tabla comparativa)
- [x] T09 skill `saga-design` (6 fases, 4 techs, outbox no-opcional)
- [x] T10 command `saga-design.md` (ejemplo orden e-commerce)
- [x] T11 knowledge `resilience-patterns.md` (9 patrones + libs por stack)

## Sprint 2 — Resilience Weaver + Clean/Hexagonal (T12-T19)
- [x] T12 skill `resilience-weave` (10 fases, Classify antes de retry)
- [x] T13 command `resilience-weave.md` (antes/después Node.js)
- [x] T14 hook `resilience-check` en `hooks.json` (PostToolUse, warn, aditivo)
- [x] T15 knowledge `architecture-patterns.md` (5 patrones + combinaciones)
- [x] T16 skill `clean-arch-setup` (scaffold por stack + arch tests + ADR-001)
- [x] T17 command `clean-arch-setup.md` (árbol Go + TS)
- [x] T18 skill `hexagonal-setup` (ports driving/driven + boundary tests)
- [x] T19 command `hexagonal-setup.md` (UserRepository port vs adapter)

## Sprint 3 — DDD/CQRS/ES + API Contract (T20-T30)
- [x] T20 skill `ddd-tactical` (aggregate, VO, domain events, invariants)
- [x] T21 command `ddd-tactical.md` (ejemplo Order aggregate)
- [x] T22 skill `cqrs-setup` (command/query bus, read models, enforced)
- [x] T23 command `cqrs-setup.md` (CreateOrder + GetOrderById)
- [x] T24 skill `event-sourcing` (event store, snapshots, 3 preguntas)
- [x] T25 command `event-sourcing.md` (schema + apply method)
- [x] T26 Extender `agents/architect.md` con Patterns Knowledge + árbol decisión (aditivo)
- [x] T27 Integrar `sdd-apply` Step 0 — Architecture Pattern (salteable, aditivo)
- [x] T28 skill `api-contract-first` (7 fases, oasdiff breaking change)
- [x] T29 command `api-contract-first.md` (breaking change report)
- [x] T30 hook `api-change-check` en `hooks.json` (PostToolUse, warn, aditivo)

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
