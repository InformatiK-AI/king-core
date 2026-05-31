# Changelog

## [Unreleased]

_(no changes yet)_

---

## [1.14.1] - 2026-05-31

### Added
- **Regla de tiering de modelo para skills nuevos**: `create-skill` documenta el árbol de decisión (`model:` opcional — workers-inline=sonnet, triviales=haiku, orquestadores/razonamiento=sin campo, nunca opus). El template `skill-template-v2.md` y `skill-anatomy.md` incorporan el campo `model` opcional. Evita que skills futuros nazcan sin tier (no fugas).

---

## [1.14.0] - 2026-05-31

### Changed
- **Tiering de modelo por skill**: los skills que generan codigo/contenido inline declaran `model: sonnet`; los triviales (reportes/lookup) `model: haiku`. Orquestadores y skills de razonamiento heredan la sesion (sin campo) para evitar model-thrashing. Alias version-agnostico; criterio documentado para skills futuros.

---

## [1.13.0] — 2026-05-31

### Changed
- **Tiering de modelo por agente**: los 10 agentes declaran `model:` por tier cognitivo con alias version-agnóstico (sigue la última versión de cada familia). `opus`: architect, security, performance, developer. `sonnet`: api, qa, devops, frontend, tenancy-enforcer. `haiku`: conductor. Antes todos en `model: inherit` (todo el pipeline corría en el modelo de sesión).
- **genesis**: el generador propaga el tier al crear agentes de proyecto — `agents/templates/agent-radar-template.md` declara `model: {AGENT_MODEL}` y `skills/genesis/GENERATION.md` mapea cada agente a su tier. Proyectos nuevos ya no nacen en `inherit`.

---

## [1.12.0] — 2026-05-29

### Changed (A6 — desacople king-arch)
- king-core **63→51 skills**: las 12 skills de arquitectura y sistemas distribuidos (`clean-arch-setup`, `hexagonal-setup`, `ddd-tactical`, `cqrs-setup`, `event-sourcing`, `saga-design`, `resilience-weave`, `idempotency`, `api-contract-first`, `contract-test-pact`, `microservice-extract`, `event-broker-setup`) + sus 12 commands + el knowledge exclusivo (`saga-patterns.md`, `distributed-systems.md`) movidos al nuevo plugin **king-arch** v1.0.0 (`requires: ["king-framework"]`).
- Permanecen en king-core (kernel compartido, leídos cross-plugin): knowledge `architecture-patterns.md`/`resilience-patterns.md`/`orm-patterns.md`, los hooks `resilience-check.sh`/`api-change-check.sh` (solo cambia el texto del warning) y el roster de agentes. Refs reescritas **graceful** ("(king-arch, si está instalado)") en `agents/architect.md`, `skills/sdd-apply/SKILL.md`, `knowledge/domain/resilience-patterns.md` y los 2 hooks. `plugin.json`, `LOAD-INDEX.md` y `README.md` actualizados.

---

## [1.11.1] — 2026-05-29

### Fixed (A5a — a11y gate)
- **`hooks/a11y-check.sh`**: de stub a gate WCAG 2.2 AA funcional. Checks estáticos (1.1.1 img alt, 3.1.1 html lang, 4.1.2 div onClick/inputs sin label, 2.4.3 tabindex+). Lee `file_path` del stdin de forma robusta y se movió de matcher `Bash` a `Write|Edit` (causa raíz de W-A2). Respeta `.king/accessibility.yaml`. Fail-safe.

---

## [1.11.0] — 2026-05-29

### Added (A2 — Jarvis default-on)
- Jarvis proactivo **activado por defecto**: `/genesis` instala `.king/hooks/phase-transition.yaml` (enabled) + `write-phase-context.sh`. Kill-switch global `KING_JARVIS=off` (en `session-management` N+1.5) y por proyecto (`enabled: false`).

### Added (A4 — Jarvis M-81/82/83)
- **M-81 Contextual Observer**: `knowledge/universal/jarvis-patterns.md` (13 patrones CASTLE) + `hooks/contextual-observer/` (observer.sh PostToolUse + emit-observations.sh deferred en UserPromptSubmit).
- **M-82 Progress Tracking**: `project-roadmap-template.md` visible + semántica auto-update + `.gitignore`.
- **M-83 Error Recovery**: `knowledge/universal/error-recovery-patterns.md` (5 templates) + `hooks/error-recovery/error-recovery.sh` (evento Stop, async:false).

### Changed (A3 — desacople)
- king-core **68→63 skills**: `frontend-design`, `a11y-audit`, `a11y-fix` movidos a **king-content**; `db-optimize`, `explain-query` a **king-infra**. Catálogo de diseño M09 → king-content. Refs reescritas graceful. LOAD-INDEX actualizado.

---

## [1.10.0] — 2026-05-28

### Added (M13 — Ecosystem & Community, parte king-core)
- **Trust Model** (`knowledge/universal/trust-model.md`): 4 tiers (Official/Trusted/Community/Local), firma GPG, scanning (Semgrep+Trivy+Snyk), revocación <48h con CRL, e invariante de no-override de gates CASTLE.
- **CASTLE Spec v1.0** (`knowledge/universal/castle-spec-v1.md`): estándar abierto de las 6 capas (C·A·S·T·L·E) con métricas/thresholds numéricos, contratos bilaterales, mappings SOC2/ISO 27001/NIST 800-53 y governance (Technical Committee, comment period 60 días, 2/3 supermayoría).
- **Community Templates** (`knowledge/universal/community-templates/01..10-*-starter.md`): 10 template specs oficiales (SaaS B2B/B2C, Marketplace, Mobile, API-only, Data Pipeline, AI Agent, CLI, Browser Ext, Desktop).
- **Certification Curriculum** (`knowledge/universal/certification-curriculum.md`): KFCD (8 módulos), KFCA (4), KFCSA (portfolio).
- **King Hub Spec** (`knowledge/universal/king-hub-spec.md`): spec del marketplace (manifest, 7 CLI commands, Quality Score, governance) — solo especificación, sin backend.
- **i18n Framework** (`knowledge/universal/i18n-framework.md`) y **Platform Adapters Roadmap** (`knowledge/universal/platform-adapters-roadmap.md`).
- **Contributor Guide** (`knowledge/universal/contributor-guide.md`) y **LOAD-INDEX.md** generado.

### Changed
- **create-skill** (`skills/create-skill/SKILL.md`): extendido aditivamente con "Scaffolding Automatizado" y "Checklist de Publicación (Tier 3 Hub)".

---

## [1.9.4] — 2026-05-26

### Fixes
- **frontmatter BOM**: eliminado UTF-8 BOM (`EF BB BF`) de 116 archivos `.md` en todo el ecosistema King (king-framework, king-entrepreneur, king-infra, king-content, king-ai, king-mobile, king-legal). El BOM impedía el parsing correcto del frontmatter YAML.
- **schema SDD**: normalizados 12 SKILL.md SDD del formato Gentleman-Skills (`license`, `metadata.author`, `metadata.version`) al formato King v2.0 (`version` top-level). Skills afectados: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard, sdd-orchestrator, `_shared`.

---

## [1.9.3] — 2026-05-25

### Fixes
- **plugin.json**: corregido nombre del plugin de `king-framework` a `king-core`. Actualizados `homepage`, `repository` y `description` para apuntar al repo correcto.

---

## [1.9.2] — 2026-05-25

### Fixes
- **commit**: eliminada atribución de co-authoring (`Co-Authored-By: Claude`) del skill `/commit`. El skill respeta la convención del usuario definida en `CLAUDE.md`.

---

## [1.9.1] — 2026-05-25

- Initial release de king-core: 47 skills, 10 agentes, pipeline SDLC completo (genesis → brainstorm → plan → build → review → qa → merge → release).
