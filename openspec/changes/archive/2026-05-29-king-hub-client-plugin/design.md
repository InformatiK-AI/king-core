# Design — King Hub plugin cliente

> Fase: sdd-design · Fuente: king-hub-spec §2/§4, trust-model, skill-anatomy v2.0.

## D1 — Diseño Híbrido (RADAR)
Cada skill: ruta primaria = `king-framework skill <cmd>` (Apex Core, spec §4); fallback graceful = flujo HTTP+GPG
directo contra el backend (`KING_HUB_URL`). Justificación: el CLI es spec-only/no construido, el backend sí → híbrido
los hace útiles HOY, fieles a la capa CLI de la spec, y se auto-mejoran cuando el CLI llegue. Reversibilidad FÁCIL.

## D2 — Anatomía v2.0
Cada SKILL.md: frontmatter (name/version 2.0/api_version/description) · Knowledge Injection · QUICK REFERENCE
(BLOCKING/REQUIRED OUTPUTS/PHASES OVERVIEW) · línea CASTLE · Phase 0 (→session-management) · Phases (GATE IN/MUST DO/
CHECKPOINT/OUTPUTS/IF FAILS) · FINAL CHECKPOINT · Execution Summary · Phase N+1/N+2 · REFERENCE + REFERENCE.md por skill
(sube C03 del audit). Resultado: health 75.70 (paridad hijos).

## D3 — CASTLE por skill
- hub-search: read-only (sin gate).
- hub-install: **S** (Security — instalación confiable, fallo atómico).
- hub-publish: **C·S·T** (Contracts/Security/Testing — manifest + firma + Gherkin).
- hub-stats: read-only.

## D4 — Endpoint configurable
`KING_HUB_URL` (default `https://hub.kingframework.dev`; dev `http://localhost:8090`). Documentado en hub-publishing-guide.

## D5 — _shared duplicado
Se copió `skills/_shared/` de king-core (paridad king-arch/king-infra) para que las refs `_shared/*` resuelvan intra-plugin.
`session-management` y agentes se leen cross-plugin de king-core.

## Estructura
`king-hub/` → `.claude-plugin/plugin.json` · `skills/{_shared, hub-search, hub-install, hub-publish, hub-stats}/` ·
`commands/*.md` · `knowledge/hub-publishing-guide.md` · `CHANGELOG.md` · `.gitignore`.

## Verificación
Estructural (skills markdown ejecutados por el agente, sin runtime): audit_self ≥75, check_api_version, JSON válido.
