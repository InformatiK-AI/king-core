# Archive Report — A6 king-arch decouple

> Fase: sdd-archive · Change: a6-king-arch-decouple · Fecha: 2026-05-29 · Verdict: FORTIFIED

## Resumen

Extracción del plugin **king-arch** desde king-core (decouple A6, medium-risk), replicando el patrón A3. Se movieron
12 skills de patrones de arquitectura + 12 commands + 2 knowledge exclusivos; king-core retuvo kernel (agentes,
knowledge compartido, hooks) y reescribió graceful sus referencias operativas.

## Entregado

- **Nuevo plugin** `king-arch/` (repo git propio): 12 skills, 12 commands, `knowledge/domain/{saga-patterns,distributed-systems}.md`, `skills/_shared/` (18, duplicados), `.claude-plugin/plugin.json` v1.0.0 (`requires:[king-framework]`), `CHANGELOG.md`, `.gitignore`.
- **king-core** (v1.11.1 → **1.12.0**, 63→51 skills): removidas las 12 skills+commands+2 knowledge; 6 sitios graceful; `plugin.json`, `LOAD-INDEX.md`, `CHANGELOG.md`, `README.md` actualizados.
- **Marketplace**: entrada `king-arch` añadida.

## Specs sincronizadas a openspec/specs/

3 capabilities nuevas (delta → live): `king-arch-extraction`, `graceful-degradation`, `dependency-direction`.

Live-specs de las skills movidas (`api-contract-first`, `architecture-patterns`, `contract-test-pact`,
`distributed-systems`, `resilience-weave`, `saga-design`) **NO eliminadas** (precedente A3: `db-optimize/spec.md`
permaneció tras mover la skill a king-infra). Se mantienen como contrato/historia.

## Verificación

pytest 59 passed (cov 97.78%) · audit king-core 82.60 · audit king-arch 75.58 (paridad hijos) · api_version EXIT 0 ·
4/4 JSON válidos · ambos hooks graceful (EXIT 0 + texto king-arch) · sin dependencia inversa.

## Pendiente (outward-facing — requiere confirmación del usuario)

- Commit inicial de king-arch + commit del branch `feature/a6-king-arch-decouple` (king-core) → **hechos localmente en ARCHIVE**.
- **Push de ambos repos, PR, merge a develop, release v1.12.0 y push del marketplace** → DIFERIDO.
- Crear el repo remoto `InformatiK-AI/king-arch` en GitHub antes del push.

## Deuda preexistente (fuera de scope A6, documentada)
- marketplace.json omite king-content/infra/ai/mobile/legal; blurb de king-core dice "47 skills".
