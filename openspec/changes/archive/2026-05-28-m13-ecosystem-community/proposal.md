# Proposal — M13 Ecosystem, Community & Distribution (Change A: king-core)

> Fase: sdd-propose · Change: m13-ecosystem-community · Backend: openspec

## Intent

King es hoy una herramienta de desarrollo excepcionalmente capaz, pero herramienta al fin:
su valor crece **linealmente** con el trabajo del equipo core. M13 introduce el salto de
herramienta a **plataforma** — el momento en que terceros publican skills, existe un estándar
de auditoría abierto que el mercado adopta, y hay certificaciones verificables. Cuando eso ocurre,
el valor de King crece **exponencialmente** sin requerir trabajo proporcional del equipo.

Ese salto exige tres condiciones simultáneas: (1) un **modelo de confianza** robusto que proteja
la integridad del ecosistema, (2) **herramientas** que hagan trivial contribuir con calidad, y
(3) **credenciales** que hagan valioso invertir en dominar el framework. Este Change A construye
esa fundación dentro de `king-core` — la pieza de gobernanza, firmas, certificación y estándares.
La parte de contenido (tutoriales y skill de certificación en `king-content`) se entrega en el
**Change B**, que depende de los artefactos de gobernanza producidos aquí.

Fuente de verdad: `mejora/planes-detallados/M13-ecosystem-community-distribution.md` (§1 visión/alcance,
§3 riesgos R-01..R-10, §6 tareas, §7 acceptance Gherkin).

## Scope

### In scope (8 items — solo king-core)

| # | Item | Entrega | Tipo |
|---|------|---------|------|
| 1 | **M-57** Plugin Signatures + Trust Model | `knowledge/universal/trust-model.md` — 4 tiers (Official/Trusted/Community/Local), firmas GPG, pipeline de scanning, CRL, invariante de no-gate-override | Nuevo knowledge |
| 2 | **M-62** Contributor Experience mejorado | Extensión de `skills/create-skill/SKILL.md` (scaffolding + checklist Tier 3 + recognition) + `knowledge/universal/contributor-guide.md` | Extensión skill + knowledge |
| 3 | **M-61** Community Templates oficiales | 10 specs en `knowledge/universal/community-templates/01..10-*.md` (stack + skills + CASTLE + CI/CD + decisiones) | Nuevo (specs markdown) |
| 4 | **M-60 (parte curriculum)** Skill Certification Program | `knowledge/universal/certification-curriculum.md` — 8 módulos KFCD, 4 módulos KFCA, criterios KFCSA, Credly/LinkedIn | Nuevo knowledge |
| 5 | **M-56** King Hub Marketplace Spec | `knowledge/universal/king-hub-spec.md` — arquitectura del plugin, manifest schema, 7 CLI commands, Quality Score, backend spec | Nuevo (spec king-hub) |
| 6 | **M-21** CASTLE Spec v1.0 (estándar abierto) | `knowledge/universal/castle-spec-v1.md` — 6 capas con thresholds/gates, contratos bilaterales, mappings SOC2/ISO/NIST, governance | Nuevo knowledge |
| 7 | **M-96** i18n del framework | `knowledge/universal/i18n-framework.md` — policy es/en/pt/fr/ja, archivos localizados, tooling, targets por versión | Nuevo (knowledge + convención) |
| 8 | **M-97** Plataformas adicionales | `knowledge/universal/platform-adapters-roadmap.md` — criterios de priorización, interface AgentAdapter (7 métodos), Feature Parity Matrix | Extensión knowledge |

Estos 8 items son útiles **sin** depender de que king-hub esté implementado: funcionan también en
contexto local y de revisión manual.

### Out of scope (explícito)

- **Backend del king-hub** (HTTP API, PostgreSQL, S3, hosting de la CRL). M-56 define la spec del
  plugin y la arquitectura; **no** implementa el servidor.
- **Sistema de exámenes online** de M-60. Aquí se define el currículum, los módulos y los criterios
  de certificación; la plataforma de exámenes (Typeform/Credly/ExamBuilder) es un proyecto separado.
- **king-content (Change B)**: el skill de certificación (M-60 parte skill, `king-content/skills/certification/`)
  y los **tutoriales interactivos M-59** (skill + command + 4 tutoriales + repo templates) viven en el
  Change B, no en este Change A.
- **Videos de YouTube / producción audiovisual** — fuera por completo.
- **Modificación del comportamiento observable** de skills existentes en proyectos usuarios.

## Approach

Entrega aditiva de **documentación de gobernanza y estándares** dentro de `king-core`, sin alterar
comportamiento de skills existentes. La única modificación a un artefacto vivo es la **extensión
aditiva** de `skills/create-skill/SKILL.md` (M-62), verificable por `git diff` y reversible quitando
las secciones añadidas.

Secuencia interna (refleja el DAG de dependencias del plan §5):

1. **M-57** (trust model) — fundación; no depende de nada en M13.
2. **M-62** (contributor experience) — extiende create-skill; referencia los tiers y la firma GPG de M-57.
3. **M-61** (10 community templates) — relativamente independientes; se hacen tras M-62 (`/create-skill` es la herramienta de creación). Las 10 specs son tareas paralelizables.
4. **M-60** (curriculum) — el módulo 6 del KFCD cubre community templates, por lo que sigue a M-61.
5. **M-56** (hub spec) — requiere M-57 + M-62 + M-61 estables; la spec del marketplace implementa la policy del trust model.
6. **M-21** (CASTLE spec) y **M-96** (i18n) y **M-97** (plataformas) — independientes entre sí; pueden ejecutarse en paralelo en cualquier sprint libre.

Cada item se valida contra los escenarios Gherkin del plan §7 (criterios de acceptance documentales
y, donde aplica, funcionales — p.ej. scaffolding de M-62 y scanner de M-57).

## Affected modules

Todo el trabajo es **único a `king-core`**:

- `king-core/knowledge/universal/` — nuevos: `trust-model.md`, `contributor-guide.md`,
  `community-templates/01..10-*.md`, `certification-curriculum.md`, `king-hub-spec.md`,
  `castle-spec-v1.md`, `i18n-framework.md`, `platform-adapters-roadmap.md`.
- `king-core/skills/create-skill/SKILL.md` — extensión aditiva (scaffolding, checklist Tier 3,
  recognition program, "Ver también" → contributor-guide.md).
- `king-core/skills/_templates/skill-template-v2.md` — verificación/ajuste de placeholders
  (`{{SKILL_NAME}}`, `{{DATE}}`, `{{VERSION}}`, `{{API_VERSION}}`) que el scaffolding reemplaza.
- `king-core/LOAD-INDEX.md` — registro de los nuevos knowledge (efecto del scaffolding y de los docs).

Sin cambios en `agents/`, `hooks/`, ni en plugins externos. **king-content y king-hub no se tocan**
en este Change.

## Capabilities (contrato para sdd-spec)

### Nuevas specs (8)

| # | Capability (dominio spec) | Item(s) | Artefactos |
|---|---------------------------|---------|------------|
| 1 | `plugin-trust-model` | M-57 | knowledge `trust-model.md` (4 tiers, GPG, scanning pipeline 5 herramientas, CRL, invariante no-gate-override, campo `trust_tier` para manifest) |
| 2 | `contributor-experience` | M-62 | knowledge `contributor-guide.md` (style guide 7 secciones + testing guide + publishing guide) |
| 3 | `community-templates` | M-61 | 10 specs `community-templates/01..10-*.md` (6 secciones: Stack, Skills King, Estructura, CASTLE, CI/CD, Decisiones) |
| 4 | `skill-certification` | M-60 (curriculum) | knowledge `certification-curriculum.md` (8 módulos KFCD, A1-A4 KFCA, criterios KFCSA, Credly/LinkedIn) |
| 5 | `apex-hub-spec` | M-56 | knowledge `king-hub-spec.md` (estructura plugin, 4 skills, manifest schema ≥12 campos, 7 CLI commands, Quality Score, backend spec) |
| 6 | `castle-spec` | M-21 | knowledge `castle-spec-v1.md` (6 capas con thresholds/gates de veto, contratos bilaterales, mappings SOC2/ISO/NIST, governance) |
| 7 | `i18n-framework` | M-96 | knowledge `i18n-framework.md` (policy 5 idiomas, archivos localizados, tooling extract/verify, targets v2.5→v4.0) |
| 8 | `platform-adapters` | M-97 | knowledge `platform-adapters-roadmap.md` (criterios priorización, interface AgentAdapter 7 métodos, Feature Parity Matrix 11 plataformas) |

### Specs modificadas (1)

| # | Capability | Item(s) | Artefacto |
|---|-----------|---------|-----------|
| 9 | `create-skill` (modificado, aditivo) | M-62 | extensión `skills/create-skill/SKILL.md`: scaffolding automatizado, checklist de publicación Tier 3, recognition program, link a contributor-guide.md |

**Total**: 8 specs nuevas + 1 spec modificada (aditiva). ~22 archivos knowledge nuevos + 1 extensión + verificación de template.

## Risks (con mitigación)

| ID | Riesgo | Prob. | Impacto | Mitigación |
|----|--------|-------|---------|-----------|
| R-01 | Un skill Tier 3 publicado contiene código malicioso no detectado por Semgrep/Trivy | BAJA | CRÍTICO | Invariante absoluta de no-gate-override (verificada en CI). CRL para revocación en < 48h. Verificación GPG en el cliente bloquea installs sin firma válida. |
| R-02 | El Trust Model crea fricción excesiva para contributors legítimos y frena la adopción | MEDIA | ALTO | Tier 4 (local) sin fricción. Tier 3 con proceso asistido vía `/create-skill`. Recognition Program compensa el esfuerzo con visibilidad real. |
| R-03 | CASTLE Spec v1.0 es adoptada por competidores que contribuyen cambios que diluyen los diferenciadores de King | BAJA | MEDIO | Governance con Technical Committee controlado por King team (supermayoría 2/3). Los cambios al estándar no modifican la implementación de referencia automáticamente. |
| R-04 | Los mappings SOC2/ISO/NIST tienen errores que generan falsa seguridad en proyectos regulados | MEDIA | ALTO | Disclaimer explícito: "los mappings son orientativos, no son asesoría legal ni de compliance". Revisión de los mappings por auditor externo antes de publicar v1.0. |
| R-05 | Las certificaciones KFCD/KFCA/KFCSA pierden credibilidad si el examen es fácilmente gameseable | MEDIA | ALTO | Banco de preguntas rotativo (200+ para 70 en examen). Portfolio review humana para KFCA y KFCSA. Credly permite verificación por terceros. |
| R-06 | Los Community Templates quedan desactualizados a medida que los stacks evolucionan | ALTA | MEDIO | Cada template spec con `last_reviewed`; > 6 meses sin review → "maintenance needed" en el hub. Templates Tier 1 con maintainer designado del equipo core. |
| R-07 | El marketplace (king-hub) se convierte en spam de skills de baja calidad que diluyen la marca | MEDIA | ALTO | Quality Score mínimo 40 para aparecer en búsqueda. Rating + reviews. "Skill of the month" eleva los de calidad. Trust tier visible en cada resultado. |
| R-08 | Los tutoriales interactivos (M-59, Change B) fallan silenciosamente si los skills que orquestan cambian | MEDIA | MEDIO | Los tutoriales declaran versiones (`king_framework_version` + `required_skills`). Si hay incompatibilidad, avisan antes de arrancar. (Mitigación heredada por las specs de gobernanza que este Change produce.) |
| R-09 | i18n introduce divergencias semánticas en traducciones de BLOCKING CONDITIONS que causan comportamiento inesperado | MEDIA | ALTO | Traducciones requieren aprobación de native speaker + comparación contra el canónico español. Regla explícita: ante duda semántica, se mantiene la frase del canónico. |
| R-10 | Los adapters de plataformas adicionales (M-97) crean surface de ataque al inyectar content en agentes de terceros | BAJA | ALTO | Cada adapter es code review por el equipo core. Los adapters no ejecutan código arbitrario — solo escriben archivos de configuración en el formato de la plataforma. |

## Rollback plan

- Todo el trabajo vive aislado en el worktree/branch `feature/m13-ecosystem-community`. Si se aborta
  antes del merge, basta `/worktree delete m13-ecosystem-community` + borrar el branch — develop queda intacto.
- Los **22 knowledge nuevos** son archivos creados; revertir = eliminarlos. No alteran comportamiento
  de ningún skill existente, por lo que su retirada es no destructiva.
- La **extensión de `create-skill/SKILL.md`** (M-62) es **aditiva** (verificada por `git diff`):
  revertir = quitar las secciones añadidas, dejando el skill en su forma original.
- La verificación/ajuste de placeholders en `skill-template-v2.md` es idempotente; si introduce un
  placeholder nuevo, revertir = quitarlo.
- Las entradas añadidas a `LOAD-INDEX.md` se revierten quitando las líneas correspondientes.
- Como no hay backend ni infra desplegada (todo es spec/knowledge), **no hay rollback operacional**
  fuera del repositorio.

## Success Criteria (checklist)

- [ ] **M-57**: `trust-model.md` con tabla de 4 tiers (criterios objetivos), proceso GPG (generación,
      firma, verificación en cliente), pipeline de scanning con 5 herramientas y condición de bloqueo
      por herramienta, proceso de revocación por tier + formato CRL, e invariante de no-gate-override
      verificable. Campo `trust_tier` vinculado con `king-hub-spec.md`.
- [ ] **M-62**: `create-skill/SKILL.md` extendido con scaffolding (estructura correcta + detección de
      colisiones antes de crear), checklist de publicación Tier 3 (calidad + identidad GPG + PR en hub),
      recognition program y link a `contributor-guide.md`. `contributor-guide.md` con style guide
      (7 secciones) + testing guide (ejemplo Gherkin) + publishing guide (→ trust-model.md).
      Placeholders del template v2.0 presentes.
- [ ] **M-61**: 10 specs en `community-templates/`, cada una con las 6 secciones y ≥ 3 decisiones de
      diseño justificadas. `01-saas-b2b-starter` referencia auth-scaffold + multi-tenancy enforcer,
      CASTLE C·A·S·T·L·E completo y CI/CD con check-action. Cada spec incluye `genesis --template {nombre}`.
- [ ] **M-60 (curriculum)**: `certification-curriculum.md` con 8 módulos KFCD (pesos suman 100%,
      todos los skills core referenciados ≥ 1 módulo), 4 módulos KFCA (25% c/u, A3 con mapping a
      CASTLE Spec v1.0), criterios KFCSA (mínimo 4/6 con 3 obligatorios), y proceso Credly + LinkedIn
      (validez 2 años + renovación).
- [ ] **M-56**: `king-hub-spec.md` con estructura del plugin (4 skills), manifest schema (≥ 12 campos
      tipados + ejemplo válido), 7 CLI commands (search/install/update/publish/info/verify/uninstall
      con sintaxis/flags/output), fórmula de Quality Score determinista (mínimo 40 para búsqueda),
      backend spec (≥ 6 endpoints) y uso de github-ops para setup del repo.
- [ ] **M-21**: `castle-spec-v1.md` con las 6 capas (≥ 4 métricas con threshold y gate de veto binario
      por capa), contratos bilaterales (formato + ≥ 2 ejemplos), mappings SOC2/ISO/NIST (≥ 5 controles
      c/u con control ID + capa + gate, disclaimer legal), y governance (comment period 60 días,
      supermayoría 2/3, retrocompatibilidad por MAJOR).
- [ ] **M-96**: `i18n-framework.md` con policy de 5 idiomas (prioridad), estructura de archivos
      localizados (`SKILL.md` canónico + `.en/.pt/.fr`), regla del canónico español, tooling
      `extract`/`verify` (sintaxis + output), y targets v2.5→v4.0 (v4.0 = 100% en todos los idiomas).
- [ ] **M-97**: `platform-adapters-roadmap.md` con criterios de priorización (≥ 3 para prioritario,
      tabla de 7 candidatos + complejidad), interface AgentAdapter (7 métodos con firma y condición de
      error), y Feature Parity Matrix (≥ 11 plataformas × ≥ 5 features, Claude Code "✓ full").
- [ ] **Conformidad**: todos los knowledge en español canónico (King es canónico en español); ningún
      artefacto modifica comportamiento observable de skills existentes; la extensión de create-skill es
      aditiva y verificable por `git diff`.
- [ ] **Acceptance Gherkin** del plan §7 satisfechos para cada item (documental y, donde aplica, funcional).
