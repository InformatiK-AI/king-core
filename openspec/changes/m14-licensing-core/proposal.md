# Proposal — M14 Licensing Core (BSL + license-check + SOC2)

> Fase: sdd-propose · Change: m14-licensing-core · Backend: openspec · Milestone: M14 (mitad king-core)

## Why

El roadmap de King Framework planifica ~278 semanas-persona. Sin un modelo de negocio funcional, ese
trabajo depende de la motivación de 1-2 personas — un riesgo **económico**, no técnico. M14 convierte el
ecosistema en un negocio sustentable: freemium con tiers claros, licensing técnico verificable, y la
documentación legal/compliance que un enterprise necesita para evaluar el framework.

Este cambio cubre la **mitad king-core** de M14: la infraestructura de licencias (declaración legal BSL 1.1,
verificación de licencia en Engram, activación por CLI) y la guía de compliance enterprise. La mitad
king-entrepreneur (Stripe billing + Pro landing) vive en el cambio hermano `m14-billing-entrepreneur` y
**depende de éste** — el webhook de Stripe escribe la observation `king-framework/license` que `license-check`
(definido aquí) lee. Por eso king-core va primero.

M13 (Apex Hub marketplace) es downstream: el revenue share del 30% se implementa allí. M14 **no bloquea ni
es bloqueado por M13** — puede shippear independiente.

## What Changes

Se agrega a `king-core`: **2 knowledge files nuevos** (business-model, license-management), **1 skill nuevo**
(`license-check` + su command), **1 knowledge file nuevo** (soc2-compliance), y **1 extensión aditiva** al
skill `genesis` (step informativo de licencia en su fase final).

Fuente de verdad: `mejora/planes-detallados/M14-business-model-monetization.md` (§2 diseño, §6 tareas Bloques
A·B·C·F, §7 Gherkin M-95/M-95b/M-95c/M-98).

## Capabilities (contrato para sdd-spec)

| # | Capability (dominio spec) | Item(s) | Artefactos |
|---|---------------------------|---------|------------|
| 1 | `business-model` | M-95 | knowledge `business-model.md` (BSL 1.1 + tiers + ICP + roadmap monetización) |
| 2 | `license-check` | M-95b, M-95c | knowledge `license-management.md` + skill `/license-check` + command `license-check.md` |
| 3 | `genesis-license-step` | C1, C2 | extensión aditiva a `genesis` (step license informativo, no bloqueante) |
| 4 | `soc2-compliance` | M-98 | knowledge `soc2-compliance.md` (mapa controles SOC2 ↔ CASTLE/Chronicle/Engram) |

**Total**: 1 skill, 1 command, 3 knowledge files, 1 extensión aditiva.

## Scope

- **In scope**: creación de `knowledge/universal/business-model.md`, `knowledge/universal/license-management.md`,
  `knowledge/universal/soc2-compliance.md`; skill `skills/license-check/SKILL.md` + `commands/license-check.md`;
  extensión aditiva a `skills/genesis/GENERATION.md` (PHASE final); conformidad anatomía v2.0; contrato de la
  observation `king-framework/license` congelado en `license-management.md` como única fuente.
- **Out of scope**:
  - **A4** (activar GitHub Sponsors, crear waitlist en Carrd.co, 5 entrevistas de usuario): NO produce
    archivos — son acciones manuales del maintainer con cuentas externas. Documentadas como follow-up.
  - Implementación real del endpoint de validación de keys (webhook Vercel/Keygen.sh) — es guidance en el
    knowledge file, no un binario desplegado en este cambio.
  - Stripe billing y Pro landing → cambio hermano `m14-billing-entrepreneur` (repo king-entrepreneur).
  - Ejecución del skill `license-check` contra proyectos externos.

## Affected modules

`king-core/knowledge/universal/` (3 nuevos), `king-core/skills/license-check/` (nuevo),
`king-core/commands/license-check.md` (nuevo), `king-core/skills/genesis/GENERATION.md` (extensión aditiva).

## Delivery

- **single-pr** con `size:exception` (4 archivos de contenido + 1 extensión; scope coherente de un mismo módulo).
- Worktree `feature/m14-licensing-core` desde develop → un único `/merge` a develop tras CASTLE.
- GATE cross-repo: tras el merge, develop de king-core contiene `license-check` + el contrato de la observation.
  Recién entonces arranca `m14-billing-entrepreneur`.

## Rollback plan

- Todo el trabajo vive aislado en el worktree/branch `feature/m14-licensing-core`. Si se aborta antes del merge,
  `git worktree remove` + borrar el branch deja develop intacto.
- La única extensión (genesis `GENERATION.md`) es **aditiva** (verificable por git diff) y el step es
  **informativo, no bloqueante** — revertir = quitar la sección añadida. No cambia el comportamiento de genesis
  para usuarios sin licencia (solo informa).
- Los 3 knowledge + el skill son archivos nuevos — revertir = borrarlos.
