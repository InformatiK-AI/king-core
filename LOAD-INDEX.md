# Load Index — king-core

<!-- PURPOSE: Archivo de sistema interno del framework King.
     Documenta qué recursos (skills, agents, knowledge, hooks) existen y se cargan en cada contexto de ejecución.
     Sirve como referencia para optimización de token budget.
     Referenciado desde: CLAUDE.md (sección Estructura de carpetas) y /audit.
     Actualizar al agregar nuevos skills, agents, knowledge o hooks. -->

Inventario y documentación de qué recursos se cargan en cada contexto, para optimización de tokens.

---

## Carga base (siempre)

| Recurso | Tokens aprox | Notas |
|---------|--------------|-------|
| `CLAUDE.md` | ~800 | Configuración raíz |
| `rules/*.md` | ~1500 | Reglas de código/commits/git |

---

## Skills (`skills/`)

51 skills + 2 directorios de soporte (`_shared`, `_templates`). Agrupados por dominio.

> Skills de diseño/accesibilidad (`frontend-design`, `a11y-audit`, `a11y-fix`) movidos a **king-content**; optimización de DB (`db-optimize`, `explain-query`) movida a **king-infra**; las 12 skills de arquitectura y sistemas distribuidos movidas a **king-arch** (decouple A6). king-core los referencia de forma opcional (solo si esos plugins están instalados).

### SDLC / Orquestación

| Skill | Recursos cargados | Notas |
|-------|-------------------|-------|
| `/genesis` | validation/, security/, knowledge/, agents/templates/, context7/ | Inicializa King en un proyecto |
| `/brainstorm` | .king/docs/features/, .king/docs/architecture/ | Ideación y diseño |
| `/plan` | docs/plans/, .king/docs/features/ | Planificación con agentes |
| `/create-issues` | docs/features/, issues/ | Epic + Stories con Gherkin |
| `/build` | validation/, agents/developer, docs/plans/ | Construcción de feature |
| `/review` | review/CHECKS.md, knowledge/stacks/ | Code review stack-agnostic |
| `/qa` | security/SECURITY-GATE, validation/ | QA estándar por feature |
| `/qa-batch` | issues/, qa sessions | QA de múltiples issues pre-promote |
| `/qa-env` | validation/, smoke tests | QA con verificación de ambiente |
| `/merge` | (verifica sesión QA existente) | Merge con quality gates |
| `/promote` | promotions.json, qa sessions | Promoción develop→qa→prod |
| `/release` | promotions.json, qa-env sessions, CHANGELOG.md | Release GitFlow completo |
| `/pr` | (PR template) | Gestión de Pull Requests |
| `/commit` | (changes staged) | Conventional commits |
| `/gitflow` | (branches, worktrees) | Gestión GitFlow |
| `/github-ops` | (gh CLI) | Operaciones GitHub |
| `/worktree` | (self-contained) | Git worktrees por feature |
| `/king-onboard` | knowledge/_inject/onboarding-essentials | Walkthrough guiado del SDLC |

### Calidad / CASTLE / Auditoría

| Skill | Recursos cargados | Notas |
|-------|-------------------|-------|
| `/castle` | security/, validation/ | Evaluación CASTLE 6 capas |
| `/castle-report` | castle sessions | Reporte CASTLE |
| `/audit` | skills/, agents/, knowledge/, docs/ | Health Score del framework |
| `/audit-ledger` | knowledge/_inject/audit-ledger-essentials | Audit trail inmutable |
| `/refine` | knowledge/_inject/prompt-engineering-essentials | Optimización de prompts |
| `/radar` | (self-contained) | Protocolo de razonamiento RADAR |

### Testing

| Skill | Recursos cargados | Notas |
|-------|-------------------|-------|
| `/contract-test` | knowledge/_inject/testing-essentials | Contract testing |
| `/mutation-test` | knowledge/_inject/testing-essentials | Mutation testing |
| `/property-test` | knowledge/_inject/testing-essentials | Property-based testing |
| `/perf-test` | knowledge/universal/performance.md | Performance testing |
| `/test-plan` | (HTML template) | Planes de prueba HTML |

### Arquitectura → king-arch (decouple A6)

> Las 12 skills de arquitectura y sistemas distribuidos (`/clean-arch-setup`, `/hexagonal-setup`, `/cqrs-setup`, `/ddd-tactical`, `/event-sourcing`, `/event-broker-setup`, `/saga-design`, `/microservice-extract`, `/api-contract-first`, `/contract-test-pact`, `/idempotency`, `/resilience-weave`) movidas a **king-arch**. king-core las referencia de forma opcional (solo si king-arch está instalado). El knowledge `architecture-patterns.md` y `resilience-patterns.md` QUEDA en king-core (kernel compartido con @architect/sdd-apply/hooks); `saga-patterns.md` y `distributed-systems.md` se movieron con las skills.

| Skill | Recursos cargados | Notas |
|-------|-------------------|-------|
| `/solid-check` | knowledge/domain/architecture-patterns.md | Verificación SOLID (queda en king-core) |

### Rendimiento / Datos

| Skill | Recursos cargados | Notas |
|-------|-------------------|-------|
| `/optimize` | knowledge/universal/performance.md | Optimización Big O |
| `/refactor` | knowledge/_inject/* | Refactoring preservando comportamiento |

> `/db-optimize` y `/explain-query` movidos a **king-infra**. `/frontend-design`, `/a11y-audit` y `/a11y-fix` movidos a **king-content**.

### Bugfix / Meta

| Skill | Recursos cargados | Notas |
|-------|-------------------|-------|
| `/fix` | knowledge/_inject/* | Bugfix sistemático |
| `/create-skill` | _templates/skill-template-v2.md, knowledge/universal/contributor-guide.md, trust-model.md | Meta-skill: scaffolding + checklist Tier 3 |

### SDD (Spec-Driven Development)

| Skill | Notas |
|-------|-------|
| `/sdd-orchestrator` | Orquestador Agent Teams Lite del flujo SDD |
| `/sdd-new` | Inicia un nuevo cambio SDD |
| `/sdd-ff` | Fast-forward: propose → spec → design → tasks |
| `/sdd-continue` | Continúa la siguiente fase del DAG |
| `/sdd-init` | Inicializa contexto SDD (detecta stack/backend) |
| `/sdd-explore` | Exploración previa al cambio |
| `/sdd-propose` | Propuesta de cambio |
| `/sdd-spec` | Especificaciones (delta specs) |
| `/sdd-design` | Diseño técnico |
| `/sdd-tasks` | Checklist de tareas |
| `/sdd-apply` | Implementación de tareas |
| `/sdd-verify` | Validación contra specs/design/tasks |
| `/sdd-archive` | Sincroniza specs y archiva el cambio |
| `/sdd-onboard` | Walkthrough guiado del ciclo SDD |

### Soporte interno (no invocables)

| Recurso | Notas |
|---------|-------|
| `skills/_shared/` | skill-anatomy.md, castle-capas.md, skill-envelope.md, gate-checkpoint-contract.md, knowledge-injection-contract.md, if-fails-templates.md, slot-convention.md, lifecycle-outputs.md, standalone-convention.md |
| `skills/_templates/` | skill-template-v2.md (plantilla canónica v2.0) |
| `session-management` | Phase 0 / N+1 / N+2 reutilizables |
| `visual-evidence` | Captura de evidencia con Playwright MCP |

---

## Agentes (`agents/`)

| Agent | Invocado por | Recursos adicionales |
|-------|--------------|----------------------|
| @developer | /build, /review, /fix | knowledge/_inject/*, patterns del proyecto, context7/library-registry.md |
| @architect | /genesis, decisiones | knowledge/universal/*, ADRs, context7/library-registry.md |
| @qa | /qa, /qa-batch | security/SECURITY-GATE |
| @security | bajo demanda | knowledge/_inject/security-essentials.md, knowledge/domain/compliance/ |
| @frontend | /qa, /a11y-* (king-content) | knowledge/universal/accessibility.md, a11y-wcag22.md |
| @devops | bajo demanda | knowledge/domain/infrastructure.md |
| @api | bajo demanda | knowledge/_inject/api-design-essentials.md |
| @performance | bajo demanda | knowledge/universal/performance.md |
| @conductor | orquestación multi-agente | agents/_common/communication-flowchart.md |
| @tenancy-enforcer | bajo demanda | knowledge/domain/multi-tenancy-patterns.md |

> Plantillas de agente en `agents/templates/`. Contratos inter-agente en `agents/_common/contracts/`.

### Infraestructura compartida de agentes (`agents/_common/`)

| Recurso | Path | Cargado cuando |
|---------|------|----------------|
| Contrato developer-architect | `agents/_common/contracts/developer-architect.md` | @developer ↔ @architect |
| Contrato developer-qa | `agents/_common/contracts/developer-qa.md` | @developer entrega a @qa |
| Contrato developer-security | `agents/_common/contracts/developer-security.md` | @developer ↔ @security |
| Contrato developer-frontend | `agents/_common/contracts/developer-frontend.md` | @developer ↔ @frontend |
| Contrato qa-security | `agents/_common/contracts/qa-security.md` | @qa orquesta @security |
| Communication Flowchart | `agents/_common/communication-flowchart.md` | Cualquier interacción multi-agente |

---

## Knowledge (`knowledge/`)

| Categoría | Path | Contenido |
|-----------|------|-----------|
| Universal | `knowledge/universal/*.md` | api-design, accessibility, a11y-wcag22, performance, performance-budget, observability, coverage-gate, lighthouse-gate, testing, testing-pyramid, skill-versioning, deprecation-policy, git-mastery, framework-performance-targets, project-roadmap-template, **contributor-guide** |
| Universal (M13) | `knowledge/universal/community-templates/` | 10 specs de community templates (M-61) |
| Inyección (slim) | `knowledge/_inject/*.md` | Versiones slim para agentes: testing, security, api-design, devops, frontend, mobile, payments, auth, observability, prompt-engineering, audit-ledger, context7, design, seo, secrets, multi-tenancy, db-migrations, resilience, onboarding, sdd-boundary |
| Dominio | `knowledge/domain/*.md` | architecture-patterns, resilience-patterns, multi-tenancy-patterns, orm-patterns, infrastructure + `compliance/` (`saga-patterns`, `distributed-systems` movidos a **king-arch**; `design/` a **king-content**) |
| Stacks | `knowledge/stacks/{node,python,go,java,rust,react}/` | Convenciones y patrones por stack |
| Context7 | `knowledge/context7/` | library-registry.md (docs live vía MCP) |

### Versiones de knowledge

| Contexto | Versión a usar | Path |
|----------|----------------|------|
| Inyección en agent | Slim | `knowledge/_inject/*.md` |
| Consulta profunda | Completa | `knowledge/universal/*.md` o `stacks/*/*.md` |
| Referencia en docs | Link a completa | - |
| Context7 on-demand | Live via MCP | `resolve-library-id` + `query-docs` |

---

## Hooks (`hooks/`)

| Hook | Evento | Función |
|------|--------|---------|
| `a11y-check.sh` | PostToolUse | Verifica accesibilidad en cambios de UI |
| `api-change-check.sh` | PostToolUse | Avisa de validar contrato OpenAPI tras cambios en handlers (sugiere `/api-contract-first` de king-arch) |
| `coverage-emit.sh` | PostToolUse | Emite señal de cobertura |
| `instrument-emit-check.sh` | PostToolUse | Verifica instrumentación/observabilidad |
| `logging-emit-check.sh` | PostToolUse | Verifica emisión de logs |
| `perf-check.sh` | PostToolUse | Verifica presupuesto de rendimiento |
| `resilience-check.sh` | PostToolUse | Verifica patrones de resiliencia (sugiere `/resilience-weave` de king-arch) |
| `recovery.sh` | (recuperación) | Rutina de recuperación |
| `session-start/` | SessionStart | Carga de contexto de sesión |
| `conductor-invoke/` | (orquestación) | Invocación del conductor |
| `audit-hook.md` | (doc) | Documentación del hook de auditoría |
| `phase-transition.md` | (doc) | Documentación de transición de fase |

> Configuración en `hooks/hooks.json`. Lanzador en `hooks/run-hook.cmd`.

---

## Optimización de carga

### Principios

1. **Lazy loading**: solo cargar cuando se necesita.
2. **Referencias > duplicación**: apuntar a archivos, no copiar contenido.
3. **Versiones slim**: usar `_inject/` para agentes.
4. **Session reuse**: verificar sesiones existentes antes de re-ejecutar.

### Señales de sobrecarga

- Skill/agent con >2000 tokens de contexto propio.
- Mismo contenido en múltiples archivos.
- Knowledge completo inyectado cuando slim bastaría.

---

## Cómo actualizar este índice

1. Al agregar un nuevo skill/agent/knowledge/hook, documentarlo aquí.
   El skill `/create-skill` actualiza esta tabla automáticamente al hacer scaffolding.
2. Al mover o eliminar recursos, actualizar paths.
3. Revisar tokens aproximados periódicamente vía `/audit`.
