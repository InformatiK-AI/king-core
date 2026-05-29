# Exploration — M14 Licensing Core

> Fase: sdd-explore · Change: m14-licensing-core

## Objetivo

Confirmar los puntos de inserción y contratos que el plan maestro M14 asume pero no verificó contra el código
real de king-core, antes de implementar.

## Hallazgos

### H1 — Punto de inserción en genesis (Bloque C)

El skill `genesis` es un router: las fases de generación viven en `skills/genesis/GENERATION.md`. La fase final
de onboarding (post-scaffold) es donde el plan pide el step informativo de licencia. **C1 = leer
`GENERATION.md` e identificar la PHASE de cierre; C2 = añadir el step ahí (aditivo).** No se toca
`genesis/SKILL.md` (el router).

### H2 — Contrato de la observation `king-framework/license`

El esquema JSON está definido en el plan maestro §M-95b. Debe ser la **única fuente de verdad** y vivir en
`license-management.md`, porque tres consumidores lo comparten:
- `license-check` (king-core) lo **lee** vía `mem_get_observation`.
- El CLI de activación lo **escribe** vía `mem_save`.
- El webhook `checkout.session.completed` (king-entrepreneur, cambio hermano) lo **escribe** post-pago.

Campos: `tier`, `key`, `activated_at`, `expires_at`, `seats`, `email`. `topic_key: king-framework/license`,
`type: policy`, `scope: project`.

### H3 — Resolución de proyecto en Engram

Engram resuelve el project name desde el **git remote** al startup del MCP (no desde cwd). El worktree de
king-core comparte el remote `InformatiK-AI/king-core` → project `king-core`. No hay riesgo de
`ambiguous_project` por trabajar en el subdirectorio del worktree. (Confirmado en
`skills/_shared/engram-convention.md` §"Project Name Resolution".)

### H4 — Anatomía del skill

`license-check` sigue anatomía v2.0 (`skills/_shared/skill-anatomy.md`): frontmatter (name/version/api_version),
Knowledge Injection con graceful degradation, QUICK REFERENCE (BLOCKING/ABSOLUTE/REQUIRED OUTPUTS/PHASES),
línea CASTLE, Phase 0 delegada a session-management, fases con GATE IN→MUST DO→CHECKPOINT→OUTPUTS→IF FAILS,
FINAL CHECKPOINT, Execution Summary, Phase N+1/N+2.

### H5 — Modo degradado (riesgo S-LIC-2)

`license-check` NO debe bloquear por error de infraestructura: si Engram no responde, asume tier `core` (modo
degradado), nunca bloquea. Solo bloquea por **ausencia explícita** de licencia para un skill premium.

## Decisiones que entran a design/spec

- El contrato de la observation se congela en `license-management.md`.
- El step de genesis es informativo, no bloqueante (no rompe genesis para usuarios Core).
- license-check tiene 4 fases: Load → read-engram (con fallback) → validate-tier → return-result.
- A4 queda fuera de scope (acciones manuales).
