# Exploration — M-17 Apex Core + M-63 CLI (spec)

> Fase: sdd-explore · Change: m17-m63-apex-core-cli-spec · Backend: openspec

## Pregunta

¿Cómo lleva King a 11 plataformas (Cursor, Gemini, OpenCode, …) y se invoca de forma unificada,
sin reescribir los skills ni acoplar el framework a una sola plataforma?

## Hallazgos en el codebase

- `knowledge/universal/` ya contiene 15 docs (api-design, performance, testing, accessibility, skill-versioning…).
  Los nuevos (`multi-platform-adapters.md`, `cli-architecture.md`) son ADITIVOS — no solapan con los existentes.
  `skill-versioning.md` ya define versionado de skills → el adapter-versioning (T28) lo referencia, no lo duplica.
- El source of truth de un skill es `SKILL.md` + `hooks.json` + `agents/` + `knowledge/`. El binario Go solo LEE
  ese formato y proyecta a cada plataforma → es un translator layer, no un runtime alternativo.
- Las precondiciones del módulo están satisfechas: M01 (CASTLE numérico, coverage hook) y M11 (versioning) en develop.

## Decisión de enfoque (comparación)

| Enfoque | Veredicto |
|---------|-----------|
| Reescribir King en Go multiplataforma | ❌ Rompe el principio "Claude Code es source of truth"; duplica lógica |
| Adapters como proyección de salida (translator) | ✅ Adoptado. Si un adapter rompe, el skill nativo sigue intacto |
| Un binario por plataforma | ❌ Mantenimiento × N; se elige un binario con `AgentAdapter` interface |

## Alcance confirmado

- **SPEC-ONLY in-repo**: este cambio produce DOS knowledge docs markdown. El binario Go (`apex-core`),
  su CI, firma GPG y distribución viven en el repo externo `king-framework/apex-core`. Aquí se define el CONTRATO.
- **Fusión M-17 + M-63**: ambos describen el mismo binario y comparten `cli-architecture.md` → un solo cambio,
  un solo dueño del archivo = cero conflicto de merge.
