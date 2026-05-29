# Design — M04 Architecture & Patterns

> Fase: sdd-design · Fuente de verdad: `mejora/planes-detallados/M04-architecture-and-patterns.md`
> (§2 diseño técnico por item, §6 tareas T01-T43, §7 Gherkin). Este design NO duplica ese detalle: lo referencia.

## Decisión arquitectónica central

M04 agrega capacidades **como documentación accionable** (skills/knowledge en Markdown), no como código
ejecutable. El "producto" son 14 SKILL.md + 14 commands + 5 knowledge conformes a la anatomía canónica v2.0
(`skills/_shared/skill-anatomy.md`), más 3 extensiones aditivas y 2 hooks. La verificación es **conformidad
estructural + coherencia de referencias**, no ejecución runtime.

## Anatomía obligatoria de cada artefacto

- **SKILL.md**: frontmatter (`name`, `version: 2.0`, `api_version: 1.0.0`, `description`) → Knowledge Injection
  (con graceful degradation "if not exists: warn and continue") → QUICK REFERENCE (BLOCKING CONDITIONS,
  ABSOLUTE RESTRICTIONS, REQUIRED OUTPUTS) → fases con GATE IN / MUST DO / CHECKPOINT / IF FAILS →
  FINAL CHECKPOINT → Execution Summary → REFERENCE.
- **command** (`commands/{name}.md`): invocación, argumentos, ≥1 ejemplo de output realista (fuente: §7 Gherkin).
- **knowledge** (`knowledge/domain/{name}.md`): patrones con problema, ejemplo, cuándo NO usar.

## Orden de implementación y dependencias (5 sprints)

Regla de oro: **knowledge ANTES que los skills que la inyectan**; `architecture-patterns.md` ANTES de extender
`@architect`; **extensiones a archivos existentes y hooks → edición manual ADITIVA** (nunca `/create-skill`),
en commits separados al final de su sprint para aislar el blast radius.

| Sprint | Tareas | knowledge (1°) | skills (scaffold /create-skill → rellenar) | edición manual aditiva |
|--------|--------|----------------|---------------------------------------------|------------------------|
| 1 | T01-T11 | orm-patterns, saga-patterns, resilience-patterns | explain-query, saga-design | `agents/performance.md` (+ORM) |
| 2 | T12-T19 | architecture-patterns | resilience-weave, clean-arch-setup, hexagonal-setup | hook resilience-check |
| 3 | T20-T30 | (usa architecture-patterns) | ddd-tactical, cqrs-setup, event-sourcing, api-contract-first | `agents/architect.md`, `sdd-apply` Step 0, hook api-change-check |
| 4 | T31-T41 | distributed-systems | db-optimize, microservice-extract, event-broker-setup, idempotency, contract-test-pact | — |
| 5 | T42-T43 | — | — | verificación integración + /optimize token budget |

**Órdenes no negociables**: T15 (architecture-patterns.md) antes de T16-T25 y de T26 (architect.md); T07 después de T04;
hooks → append a arrays existentes de `hooks.json`, validar JSON; `/db-optimize` reusa `/explain-query`;
`/microservice-extract` integra tenancy de M07; `/contract-test-pact` integra con `/microservice-extract`.

## Patrón de implementación: Workflow fan-out

Los knowledge + skills + commands son **independientes** → se autoría con un Workflow (un agente por artefacto,
cada uno recibe la sección §2 de M04 + el delta spec + la anatomía v2.0). Las **extensiones (3) y hooks (2)**
NO se paralelizan (archivos compartidos, deben ser aditivos) → edición secuencial manual.

## Dónde encajan las skills de calidad (honestidad técnica)

- **/review** → por sprint, sobre lo creado: conformidad anatomía v2.0 (@architect), seguridad del bash de hooks
  (@security), coherencia skill↔command↔knowledge. NO busca bugs de runtime (no hay runtime).
- **/fix** → reactivo y acotado: solo ante defecto estructural detectado por /review o /sdd-verify.
- **/refactor** → un uso: deduplicar los 5 skills M-25 (comparten fases + inyección architecture-patterns + output
  de estructura de directorios) → extraer común a `_shared/`. Al cierre del sprint 3.
- **/optimize** → un uso: auditoría token-budget (CASTLE A5) de los 14 SKILL.md. Una vez, antes del QA final.
  Big O NO aplica.

## Verificación

`/sdd-verify` (verify-report) → `/qa --scope king-core` → `/castle-report`. Objetivo **CASTLE FORTIFIED**.
El check `npm run build` de `/merge` Fase 4 es **N/A** (plugin Markdown). Tests estructurales: `pytest` (self-tests).
git diff confirma que las 3 extensiones son aditivas; `hooks.json` parseable con 2 hooks añadidos.

## Riesgos (resumen; ver exploration.md)

Engram ambiguous_project → openspec. Knowledge/specs no trackeados → copiados. Extensiones a archivos críticos →
aditivo + git diff + commits separados. PR grande → /review por sprint. R1-R7 del doc M04 §3 (complejidad prematura,
sagas sin outbox, retry no idempotente, breaking changes, ES over-engineering, contract tests falsos, tenancy) →
mitigados dentro de cada skill ("cuándo NO usar", outbox no-opcional, Classify antes de retry, oasdiff, 3 preguntas ES).
