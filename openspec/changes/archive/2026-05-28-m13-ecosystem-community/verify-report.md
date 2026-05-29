# Verify Report — M13 Change A (king-core)

> Ceremonia: sdd-verify · Cambio: `m13-ecosystem-community` (Change A — king-core)
> Fecha: 2026-05-28 · Veredicto: **PASS**

## 1. Resumen

M13 Change A (king-core) entrega **8 items** del bloque Ecosystem, Community & Distribution:

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

Total estructural: 7 knowledge docs nuevos + 10 community templates + 1 skill extendido aditivamente + plugin.json actualizado.

## 2. Evidencia estructural

- **Self-tests del framework:** `pytest` = **59 passed**. Sin regresión respecto al baseline de M04 (59 passed). Los cambios de M13 Change A son documentación (knowledge/templates) y una extensión aditiva de skill; no tocan rutas de código cubiertas por los self-tests.
- **Codificación:** todos los archivos entregados y de ceremonia (knowledge docs, community templates, `create-skill/SKILL.md`, specs, `tasks.md`, `state.yaml`, `plugin.json`) verificados **UTF-8 sin BOM**.
- **`create-skill/SKILL.md` extendido aditivamente:** frontmatter intacto, secciones originales preservadas; se añaden las secciones de scaffolding automatizado, Checklist de Publicación Tier 3, Recognition Program y referencia bidireccional "Ver también" → `contributor-guide.md`.
- **`plugin.json` válido:** JSON parseable, **versión 1.10.0**, descripción actualizada para reflejar el knowledge de ecosistema y comunidad.

## 3. Spec compliance (8 capabilities)

Las 8 capabilities en `specs/*/spec.md` están cubiertas y cada deliverable cumple su DoD:

1. **`plugin-trust-model` (M-57)** — 4 tiers con criterios/badges/garantías, firma GPG y verificación atómica en cliente, pipeline de scanning, invariante absoluta de no-gate-override, CRL pública, integración con M-56. **Cumple.**
2. **`contributor-experience` (M-62)** — scaffolding automatizado en `/create-skill` (detección de colisiones + generación de LOAD-INDEX), Checklist Tier 3, Recognition Program, Contributor Guide canónico con style/testing/publishing guide. **Cumple.**
3. **`community-templates` (M-61)** — catálogo de 10 templates oficiales, cada uno con las 6 secciones obligatorias y decisiones justificadas; invocables vía genesis; metadato de frescura. **Cumple.**
4. **`skill-certification` (M-60 curriculum)** — KFCD (8 módulos = 100%), KFCA (4 módulos al 25%, A3 → CASTLE Spec v1.0), KFCSA (6 criterios, mínimo 4/6, obligatorios 3+4+5), Credly + LinkedIn badge. **Cumple.**
5. **`apex-hub-spec` (M-56)** — arquitectura del plugin king-hub (4 skills), schema de manifest (>=12 campos), 7 CLI commands, Quality Score determinista, backend Go + PostgreSQL + S3 con endpoints y governance. **Cumple.**
6. **`castle-spec` (M-21)** — 6 capas con >=4 métricas y gate de veto por capa, contratos bilaterales con ejemplos, mappings SOC2/ISO 27001:2022/NIST 800-53, certificaciones y governance formal. **Cumple.**
7. **`i18n-framework` (M-96)** — policy de idiomas (5 + canónico español), estructura localizada, proceso de traducción con review native speaker, runtime `KING_LANG`, targets por versión, tooling `extract`/`verify`, gestión de divergencias. **Cumple.**
8. **`platform-adapters` (M-97)** — roadmap con criterios de priorización objetivos, interface `AgentAdapter` de 7 métodos, Feature Parity Matrix de 11 plataformas, soporte `KING_LANG`, proceso de contribución de adapters. **Cumple.**

### Fixes del review aplicados

- **CASTLE alineado a la semántica canónica de King:** C = Contracts, E = Environment (corregido respecto a la nomenclatura inicial divergente).
- **Quality Score capado a 100:** la fórmula nunca excede el techo de 100 puntos.
- **Nombre unificado a "King Hub":** marketplace, plugin y knowledge (`king-hub-spec.md`) usan un único nombre canónico.
- **10 templates normalizados:** cada uno con sección "Cómo usar" + comando `genesis` invocable + metadato `last_reviewed`.
- **Umbral Gherkin elevado 3 -> 5:** los escenarios mínimos por feature en el testing guide pasan de 3 a 5.

## 4. Veredicto

**PASS.** Gates estructurales en verde: `pytest` 59 passed sin regresión, UTF-8 sin BOM en todos los entregables, `plugin.json` válido en 1.10.0, 8 capabilities con DoD cumplido y fixes del review aplicados.

CASTLE: **CONDITIONAL -> FORTIFIED-ready**. La condición residual es de documentación (no de gates estructurales, que están verdes); el cambio queda listo para promover a FORTIFIED en el archive posterior al merge.

## 5. Pendiente fuera de scope (Change B / king-content)

- **M-59** — interactive-tutorials (king-content).
- **M-60** — parte de skill + command de certification (T-25/T-26, king-content).

Estos items no forman parte de Change A y se entregan en Change B sobre king-content.
