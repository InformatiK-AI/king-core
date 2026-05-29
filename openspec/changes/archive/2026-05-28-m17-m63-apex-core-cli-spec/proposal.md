# Proposal — M-17 Apex Core + M-63 CLI Cross-Platform (spec)

> Fase: sdd-propose · Change: m17-m63-apex-core-cli-spec · Backend: openspec

## Why

King es poderoso pero su superficie de adopción es estrecha: vive solo en Claude Code y se invoca skill por skill.
Falta (a) **portabilidad** — el mismo skill debería proyectarse a Cursor, Gemini, OpenCode y 8 plataformas más —
y (b) un **punto de entrada unificado** (`king-framework install|status|doctor|update|…`). M-17 define el motor
(translator layer en Go, interface `AgentAdapter`); M-63 define el volante (los comandos de ese binario). Son el
mismo binario. M01 y M11 (precondiciones) ya están en develop.

## What Changes

Se agregan a `king-core` **dos knowledge specs** en `knowledge/universal/`:

- `multi-platform-adapters.md` — interface `AgentAdapter`, structs `KingConfig`/`VerifyReport`, tabla de 11
  plataformas con tiers, mapeo de formatos, merge strategy no-destructiva, fixtures golden, adapter-versioning.
- `cli-architecture.md` — spec del binario Go: comandos (`install`/`status`/`doctor`/`update`/`backup`/`restore`/
  `skill *`/`agent *`), flags, exit codes, output (`--json`/`--quiet`/`--no-color`), distribución, firma GPG,
  shell completions, testing strategy.

Fuente de verdad: `mejora/planes-detallados/M12-developer-experience-tooling.md` (§2 M-17/M-63, §6 T16-T40, §7 Gherkin).

## Capabilities (contrato para sdd-spec)

| # | Capability (dominio spec) | Item | Artefacto |
|---|---------------------------|------|-----------|
| 1 | `multi-platform-adapters` | M-17 | `knowledge/universal/multi-platform-adapters.md` |
| 2 | `cli-architecture` | M-63 | `knowledge/universal/cli-architecture.md` |

## Scope

- **In scope**: los 2 knowledge specs markdown (contrato del binario y de los adapters), conformes a la convención
  de `knowledge/universal/`. Tareas T16-T40.
- **Out of scope (repo externo `king-framework/apex-core`)**: implementación Go, CI matrix, publicación de binarios,
  Homebrew/Scoop/Docker, generación real de la firma GPG. Aquí se ESPECIFICAN, no se ejecutan.

## Verification

`sdd-verify` valida conformidad estructural + cobertura del Gherkin §7 (M-17: 5 escenarios; M-63: 6 escenarios)
EN EL DOCUMENTO (cada escenario debe tener su contrato descrito), no ejecución de un binario. Gate: CASTLE ≥ 85.

## Naturaleza (CP1)

SPEC-ONLY. El `apply` produce MARKDOWN. CASTLE evalúa el DOCUMENTO (completitud, coherencia, ausencia de
contradicciones con `skill-versioning.md`), no un runtime. Confirmado con el usuario en el plan aprobado.
