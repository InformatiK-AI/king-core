# Design — A6 king-arch decouple

> Fase: sdd-design · Change: a6-king-arch-decouple · Fuente de verdad: post_m13_hardening (A6) + plan aprobado.

## Decisiones de arquitectura (con rationale)

### D1 — Solo se mueven las 12 skills de patrones; el kernel de razonamiento queda
king-core retiene `brainstorm`, `plan`, `radar`, `castle`, `audit`, `solid-check`, `refactor`, `optimize`, `review`,
`contract-test`. **Rationale**: son meta-razonamiento/workflow usados por todo el ecosistema; moverlos rompería el
kernel. Precedente A3: `@frontend`/`@performance` quedaron como kernel aunque sus skills se movieron.

### D2 — Knowledge: mover solo lo exclusivo de las 12
Mueven `saga-patterns.md` y `distributed-systems.md` (grep: 0 consumidores fuera de las 12). Quedan
`architecture-patterns.md` (usado por `@architect` líneas 110/237 y `sdd-apply` 41), `resilience-patterns.md`
(usado por `hooks/resilience-check.sh`) y `orm-patterns.md` (usado por `@performance`). **Rationale**: dirección de
dependencias — lo que el kernel consume no puede emigrar; king-arch lo lee cross-plugin (precedente A3 con `orm-patterns`).

### D3 — Hooks quedan en king-core (solo cambia el texto del warning)
`resilience-check.sh` y `api-change-check.sh` no se mueven; `hooks.json` NO se toca. **Rationale**: king-infra/king-content
no tienen `hooks/`; estos hooks solo *sugieren* (enforcement=warn) y ya degradan a `exit 0`. Mantenerlos en king-core
preserva el aviso aunque king-arch no esté instalado; solo el comando sugerido se anota "(king-arch, si está instalado)".

### D4 — `_shared/` se duplica completo en king-arch
Las 12 referencian directamente `{lifecycle-outputs, castle-capas, skill-envelope, if-fails-templates}`, pero esos
archivos tienen refs transitivas (p.ej. `lifecycle-outputs`→`chronicle-convention`). **Rationale**: king-infra duplicó
los 18 `_shared/*` wholesale; replicamos ese precedente para evitar breakage transitivo y cross-read frágil de paths
relativos. `session-management` y los agentes NO se duplican (se leen cross-plugin del kernel).

### D5 — Versionado
king-core `1.11.1 → 1.12.0` (minor: cambio de superficie tipo A3, que fue 1.11.0). king-arch nace en `1.0.0`.

### D6 — Cross-plugin knowledge resolution (riesgo R3)
Las 12 referencian `knowledge/domain/architecture-patterns.md` y `resilience-patterns.md` con path relativo; tras el
move quedan en king-core. En APPLY se confirma el mecanismo que A3 usó para que un hijo lea knowledge del kernel
(misma técnica que `db-optimize` en king-infra leyendo de king-core). `saga-patterns`/`distributed-systems` resuelven
intra-king-arch. Si el harness no resuelve cross-plugin por path, fallback = anotar la ref como "(king-core)".

### D7 — Live-specs no se migran
Los `king-core/openspec/specs/{api-contract-first,architecture-patterns,contract-test-pact,distributed-systems,
resilience-weave,saga-design}/spec.md` se mantienen (precedente A3 dejó `db-optimize/spec.md`). Documentales/contrato.

## Mapeo origen → destino

| Origen (king-core) | Destino | Operación |
|--------------------|---------|-----------|
| `skills/{12}/` (carpeta completa, incl. sub-archivos si los hubiera) | `king-arch/skills/{12}/` | MOVER |
| `commands/{12}.md` | `king-arch/commands/{12}.md` | MOVER |
| `knowledge/domain/saga-patterns.md` | `king-arch/knowledge/domain/saga-patterns.md` | MOVER |
| `knowledge/domain/distributed-systems.md` | `king-arch/knowledge/domain/distributed-systems.md` | MOVER |
| `skills/_shared/*` (18 archivos) | `king-arch/skills/_shared/*` | COPIAR (no mover) |
| — | `king-arch/.claude-plugin/plugin.json` | CREAR |
| — | `king-arch/CHANGELOG.md`, `.gitignore`, `openspec/` | CREAR |
| `agents/architect.md` | (in situ) | EDITAR graceful |
| `skills/sdd-apply/SKILL.md` | (in situ) | EDITAR graceful |
| `knowledge/domain/resilience-patterns.md` | (in situ) | EDITAR graceful (texto) |
| `hooks/resilience-check.sh`, `hooks/api-change-check.sh` | (in situ) | EDITAR texto del warning |
| `.claude-plugin/plugin.json` | (in situ) | EDITAR description + version |
| `LOAD-INDEX.md`, `CHANGELOG.md`, `README.md` | (in situ) | EDITAR |
| `proyectos referencia/King/king-marketplace/.claude-plugin/marketplace.json` | (in situ) | EDITAR (entrada king-arch) |

Los 12 (lista canónica): `clean-arch-setup`, `hexagonal-setup`, `ddd-tactical`, `cqrs-setup`, `event-sourcing`,
`saga-design`, `resilience-weave`, `idempotency`, `api-contract-first`, `contract-test-pact`, `microservice-extract`,
`event-broker-setup`.

## Patrón textual graceful (heredado de A3)

Sufijo literal: `(king-arch, si está instalado)` junto al slash-command. En knowledge/agents que describen árboles de
decisión: el conocimiento permanece válido (queda en king-core); solo el comando de scaffolding se anota condicional.
En hooks `.sh`: el `echo`/`MSG` del WARNING nombra el comando con el sufijo; el `exit 0` no cambia.

## Estrategia git

- king-core: branch `feature/a6-king-arch-decouple` desde develop → un solo `/merge` tras CASTLE FORTIFIED.
- king-arch: `git init` + commit inicial. Push/PR (ambos repos) y entrada de marketplace pusheada → **diferido a
  confirmación del usuario** (acción outward-facing).
