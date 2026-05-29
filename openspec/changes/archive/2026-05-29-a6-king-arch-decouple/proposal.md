# Proposal — A6 Extraer king-arch (decouple de 12 skills de arquitectura)

> Fase: sdd-propose · Change: a6-king-arch-decouple · Backend: openspec · Backlog item: A6 (post-M13 hardening, medium-risk / no urgente)

## Why

Tras M04, king-core acumuló 14 skills de patrones de arquitectura. A3 ya movió 2 de ellas a king-infra
(`db-optimize`, `explain-query`). Las 12 restantes forman un dominio cohesivo y separable (Clean/Hexagonal/DDD/CQRS,
event-sourcing, sagas, resiliencia, idempotencia, contratos de API, microservicios, brokers de eventos) que no
pertenece al kernel de razonamiento/workflow de king-core.

Extraerlas a un plugin propio `king-arch` reduce el peso del kernel y completa el patrón de modularización por dominio
ya aplicado en A3 (frontend/a11y → king-content; db → king-infra). El item está registrado como **A6** en el backlog
post-M13 (`post_m13_hardening`), clasificado **medium-risk / no urgente** porque toca referencias cross-plugin y
knowledge compartido — pero no es destructivo (las skills viven en el nuevo repo + historia git).

## What Changes

Se crea el plugin **`king-arch`** (repo nuevo, `requires: ["king-framework"]`) y se mueven desde `king-core`:
**12 skills + 12 commands + 2 knowledge files** (`saga-patterns.md`, `distributed-systems.md`, exclusivos de las 12).
king-core reescribe **graceful** las referencias hacia las skills movidas y actualiza manifiesto/LOAD-INDEX/CHANGELOG.

Fuente de verdad: backlog `post_m13_hardening` (item A6) + plan aprobado
`C:\Users\jsalg\.claude\plans\enriquece-este-mensaje-paso-snoopy-squirrel.md`. Precedente directo: A3 (decouple
king-content/king-infra, ver `CHANGELOG.md`).

## Capabilities (contrato para sdd-spec)

| # | Capability (dominio spec) | Artefactos |
|---|---------------------------|------------|
| 1 | `king-arch-extraction` | Mover 12 skills + 12 commands + 2 knowledge a king-arch; crear `.claude-plugin/plugin.json` (v1.0.0, requires king-framework); duplicar `_shared/` necesarios |
| 2 | `graceful-degradation` | king-core funciona SIN king-arch: refs reescritas con sufijo "(king-arch, si está instalado)" + log warning; @architect/sdd-apply degradan a guidance vía knowledge local |
| 3 | `dependency-direction` | king-arch declara `requires:[king-framework]`; PROHIBIDA toda dependencia king-core→king-arch; agentes/knowledge compartido/hooks QUEDAN en king-core (cross-read) |

## Scope

- **In scope**:
  - Crear repo `king-arch/` con anatomía espejo de king-infra (`.claude-plugin/`, `commands/`, `knowledge/domain/`,
    `skills/` con `_shared/` duplicado, `CHANGELOG.md`, `openspec/`). Sin `agents/`, sin `hooks/`, sin LOAD-INDEX.
  - Mover las 12 skills: `clean-arch-setup`, `hexagonal-setup`, `ddd-tactical`, `cqrs-setup`, `event-sourcing`,
    `saga-design`, `resilience-weave`, `idempotency`, `api-contract-first`, `contract-test-pact`,
    `microservice-extract`, `event-broker-setup` (+ sus 12 commands).
  - Mover `knowledge/domain/saga-patterns.md` y `knowledge/domain/distributed-systems.md` (exclusivos de las 12).
  - Reescribir graceful 6 sitios en king-core (agents/architect.md, skills/sdd-apply, 2 knowledge, 2 hooks `.sh` texto).
  - Actualizar `king-core/.claude-plugin/plugin.json` (description + version 1.11.1→1.12.0), `LOAD-INDEX.md`,
    `CHANGELOG.md`, `README.md` (conteo).
  - Registrar king-arch en `proyectos referencia/King/king-marketplace/.claude-plugin/marketplace.json`.
- **Out of scope**:
  - **Mover hooks** (`resilience-check.sh`, `api-change-check.sh`): QUEDAN en king-core (precedente A3: hijos no tienen
    `hooks/`). Solo se reescribe el texto del warning.
  - **Mover knowledge compartido** (`architecture-patterns.md`, `resilience-patterns.md`, `orm-patterns.md`): QUEDAN
    (consumidos por @architect/sdd-apply/hooks/@performance).
  - Mover el kernel de razonamiento (`brainstorm`, `plan`, `radar`, `castle`, `audit`, `solid-check`, `refactor`,
    `optimize`, `review`, `contract-test`).
  - Migrar los live-specs de las skills movidas fuera de `king-core/openspec/specs/` (precedente A3: se mantienen).
  - `push` / PR a remoto y release de king-arch — se confirman con el usuario antes de ejecutar.

## Affected modules

- `king-core/skills/` (−12), `king-core/commands/` (−12), `king-core/knowledge/domain/` (−2),
  `king-core/agents/architect.md` (graceful), `king-core/skills/sdd-apply/SKILL.md` (graceful),
  `king-core/hooks/{resilience-check,api-change-check}.sh` (texto), `king-core/.claude-plugin/plugin.json`,
  `king-core/LOAD-INDEX.md`, `king-core/CHANGELOG.md`, `king-core/README.md`.
- **Nuevo**: `king-arch/` (repo independiente).
- `proyectos referencia/King/king-marketplace/.claude-plugin/marketplace.json`.

## Delivery

- **single-pr** con `size:exception` (decouple cohesivo de un dominio; ~26 archivos movidos + reescrituras graceful).
- Branch `feature/a6-king-arch-decouple` desde develop en king-core → `/merge` a develop tras CASTLE.
- king-arch = repo nuevo con su commit inicial. Push/PR diferidos a confirmación del usuario.

## Rollback plan

- **king-core**: todo el trabajo vive en `feature/a6-king-arch-decouple`. Abortar antes del merge = borrar el branch
  deja develop intacto. Las skills/commands/knowledge "removidos" siguen en la historia git y en king-arch.
- **king-arch**: repo nuevo aislado — revertir = borrar el directorio. No afecta a ningún otro plugin.
- **marketplace**: el cambio es una entrada additiva en un array JSON — revertir = quitar la entrada.
- Riesgo destructivo controlado: la única "remoción" grande (12 skills de king-core) es reversible por git y
  redundante (copia íntegra en king-arch). Verificación de degradación graceful antes de cerrar (ver tasks VERIFY).
