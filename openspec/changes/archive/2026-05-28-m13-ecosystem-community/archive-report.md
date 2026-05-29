# Archive Report — M13 Ecosystem, Community & Distribution (Change A · king-core)

> Ceremonia: sdd-archive · Cambio: `m13-ecosystem-community` (Change A — king-core)
> Fecha de archivado: 2026-05-28 · Veredicto verify: **PASS**

## 1. Resumen del cambio

M13 Change A (king-core) entrega **8 items** del bloque Ecosystem, Community & Distribution. Todo el cambio ya está mergeado a `develop`.

| Item | Capability | Deliverable principal |
| ---- | ---------- | --------------------- |
| M-57 | plugin-trust-model | `knowledge/universal/trust-model.md` (4 tiers + GPG + scanning + CRL + invariante no-gate-override) |
| M-62 | contributor-experience | `skills/create-skill/SKILL.md` extendido + `knowledge/universal/contributor-guide.md` |
| M-61 | community-templates | `knowledge/universal/community-templates/01..10-*.md` (10 templates oficiales) |
| M-60 (curriculum) | skill-certification | `knowledge/universal/certification-curriculum.md` (KFCD/KFCA/KFCSA + Credly) |
| M-56 | apex-hub-spec | `knowledge/universal/king-hub-spec.md` (arquitectura, manifest, CLI, Quality Score, backend) |
| M-21 | castle-spec | `knowledge/universal/castle-spec-v1.md` (6 capas + contratos bilaterales + mappings + governance) |
| M-96 | i18n-framework | `knowledge/universal/i18n-framework.md` (policy, tooling, targets, divergencias) |
| M-97 | platform-adapters | `knowledge/universal/platform-adapters-roadmap.md` (criterios + AgentAdapter + parity matrix) |

Total estructural: 7 knowledge docs nuevos + 10 community templates + 1 skill extendido aditivamente + `plugin.json` actualizado (v1.10.0).

## 2. Veredicto verify

**PASS** (ver `verify-report.md`). Gates estructurales en verde: `pytest` 59 passed sin regresión, UTF-8 sin BOM en todos los entregables, `plugin.json` válido en 1.10.0, 8 capabilities con DoD cumplido y fixes del review aplicados.

## 3. Specs canónicas sincronizadas

Las 8 capabilities son **nuevas**, por lo que el delta spec se copió directamente a `openspec/specs/{cap}/spec.md` (sin merge sobre main spec previa):

1. `openspec/specs/plugin-trust-model/spec.md`
2. `openspec/specs/contributor-experience/spec.md`
3. `openspec/specs/community-templates/spec.md`
4. `openspec/specs/skill-certification/spec.md`
5. `openspec/specs/apex-hub-spec/spec.md`
6. `openspec/specs/castle-spec/spec.md`
7. `openspec/specs/i18n-framework/spec.md`
8. `openspec/specs/platform-adapters/spec.md`

## 4. Pendiente fuera de scope (Change B / king-content)

- **M-59** — interactive-tutorials (king-content).
- **M-60** — parte de skill + command de certification (T-25/T-26, king-content).

Change B (king-content: M-59 + M-60 skill/command) **queda pendiente** y se entregará en un ciclo SDD separado sobre el repo king-content.
