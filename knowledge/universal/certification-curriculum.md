# Certification Curriculum — King Framework

Este documento es la fuente de verdad del programa de certificación de King Framework.
Define las tres credenciales (KFCD, KFCA, KFCSA), el temario completo con pesos
auditables, y los criterios objetivos de evaluación. El skill `/certification`
(entregado en king-content, Change B) consume este curriculum como insumo: NO duplica
el temario, lo referencia. Cuando un skill del framework evoluciona, este documento se
actualiza y el programa de certificación queda automáticamente al día.

> Idioma canónico: español. Las traducciones del badge y materiales siguen
> `knowledge/universal/i18n-framework.md`.

---

## 1. Las tres certificaciones

| Credencial | Nivel | Requisito previo | Evaluación | Badge | Validez |
|---|---|---|---|---|---|
| **KFCD** — King Framework Certified Developer | Intermedio | 6 meses de experiencia con el framework | Examen online (70 preguntas, 90 min) + 1 proyecto portfolio | LinkedIn + Credly | 2 años, renovable |
| **KFCA** — King Framework Certified Architect | Avanzado | KFCD + 12 meses adicionales de uso | Examen online (50 preguntas, 90 min) + review de arquitectura de un proyecto real | LinkedIn + Credly | 2 años, renovable |
| **KFCSA** — King Framework Certified Skill Author | Especialización | KFCD + ≥1 skill publicado en el hub (Tier 3 mínimo) | Portfolio review (3 skills) + code review por el equipo core | LinkedIn + Credly | Indefinido mientras los skills sigan activos |

### Renovación

- **KFCD / KFCA**: a los 2 años, renovación mediante un examen delta corto (20 preguntas)
  que cubre solo los cambios introducidos desde la última certificación (nuevos skills,
  cambios en CASTLE Spec, deprecaciones). No requiere reexaminar el temario completo.
- **KFCSA**: la credencial permanece activa mientras al menos 3 skills del portfolio
  conserven `trust_tier ≤ 3` y publiquen al menos una versión por año. Si un skill cae a
  Local o es revocado (ver `knowledge/universal/trust-model.md`), el titular dispone de
  90 días para reemplazarlo en su portfolio antes de que la credencial se marque inactiva.

---

## 2. KFCD — 8 módulos (suman 100%)

El temario del KFCD cubre **todo** el framework. La regla de cobertura es invariante:
**cada skill core debe aparecer referenciado en al menos un módulo**. La tabla de
trazabilidad de la §2.9 garantiza esa cobertura de forma auditable.

| # | Módulo | Peso |
|---|--------|------|
| 1 | Fundamentos del Framework | 10% |
| 2 | Configuración y Setup | 10% |
| 3 | Developer Workflow | 15% |
| 4 | CASTLE en Profundidad | 15% |
| 5 | Multi-tenancy y Seguridad | 15% |
| 6 | Entrepreneur Path | 10% |
| 7 | Observability y Performance | 15% |
| 8 | Ecosistema y Contribución | 10% |
| | **Total** | **100%** |

### Módulo 1 — Fundamentos del Framework (10%)

Objetivo: entender qué ES King antes de operarlo.

- Arquitectura de King: las cinco piezas (plugins, skills, agents, hooks, knowledge) y cómo se componen.
- El ciclo de vida SDD: `sdd-explore` → `sdd-propose` → `sdd-spec` → `sdd-design` → `sdd-tasks` → `sdd-apply` → `sdd-verify` → `sdd-archive`. Cuándo usar `/sdd-new`, `/sdd-ff` y `/sdd-continue`.
- CASTLE: las 6 capas (C·A·S·T·L·E) y por qué cada una es un veto, no un consejo.
- Conceptos transversales: RADAR (razonamiento estructurado), Chronicle/Engram (memoria persistente), NEXUS (portabilidad entre agentes).

**Resultado esperado**: el candidato explica, sin código, por qué King es una plataforma y no una colección de scripts.

### Módulo 2 — Configuración y Setup (10%)

Objetivo: dejar un proyecto operativo con King.

- Instalación vía Apex Core (Homebrew, Scoop, `go install`).
- `/genesis`: discovery estructurado, detección de stack, generación de `.king/`, LOAD-INDEX y agentes adaptados. Persona developer vs entrepreneur.
- Hooks: qué eventos existen (PreToolUse, PostToolUse, Stop, etc.) y cuándo usarlos vs. cuándo NO.
- Settings y profiles por proyecto: configuración de gates, thresholds y agentes.

**Skills core cubiertos**: `/genesis`.

### Módulo 3 — Developer Workflow (15%)

Objetivo: dominar el ciclo diario de desarrollo.

- Ciclo completo: `/plan` → `/build` → `/qa` → `/review` → `/promote`.
- Ideación previa: `/brainstorm` y `/radar` antes de planificar; `/refine` para optimizar prompts.
- Quality gates en el flujo: cobertura, linting, type-checking.
- Trabajo aislado: `/worktree` y `/gitflow` (estado de branches, sincronización de ambientes).
- `/commit` con conventional commits y `/github-ops` (PRs, push, issues).
- `/create-issues` para descomponer un plan en Epic + Stories con Gherkin.
- `/release` y semver; `/fix`, `/refactor` y `/optimize` para mantenimiento.

**Skills core cubiertos**: `/plan`, `/build`, `/qa`, `/review`, `/promote`, `/brainstorm`, `/radar`, `/refine`, `/worktree`, `/gitflow`, `/commit`, `/github-ops`, `/pr`, `/create-issues`, `/release`, `/fix`, `/refactor`, `/optimize`, `/merge`.

### Módulo 4 — CASTLE en Profundidad (15%)

Objetivo: leer, interpretar y configurar la evaluación de calidad.

- **C — Contracts**: contratos de API, schemas y eventos; cobertura, linting, deuda técnica.
- **A — Architecture**: SOLID, hexagonal, separación de capas.
- **S — Security**: OWASP, secrets, auth.
- **T — Testing**: pirámide de tests, TDD, contract tests.
- **L — Logging & Observability**: logs estructurados, OpenTelemetry.
- **E — Environment**: configuración por ambiente; performance, accesibilidad (a11y), internacionalización (i18n).
- Cómo correr `/castle` y leer el `/castle-report` (Health Score y dimensiones).
- Cómo añadir gates custom a un proyecto y ajustar thresholds.

**Skills core cubiertos**: `/castle`, `/castle-report`, `/audit`, `/solid-check`, `/contract-test`, `/mutation-test`, `/property-test`, `/perf-test`, `/a11y-audit`, `/a11y-fix`, `/test-plan`.

### Módulo 5 — Multi-tenancy y Seguridad (15%)

Objetivo: construir sistemas multi-tenant seguros.

- Tenancy Enforcer: row-level security, propagación de contexto de tenant.
- Auth Scaffold: OAuth2, PKCE, gestión de sesiones.
- Secrets Management: integración con vault, rotación de secretos.
- Deep dive de la capa **S** de CASTLE: OWASP Top 10, manejo de secretos, modelos de amenazas.
- Patrones de resiliencia (`/resilience-weave`) e idempotencia (`/idempotency`) como defensa en profundidad.

**Skills core cubiertos**: `/resilience-weave`, `/idempotency`. (Tenancy Enforcer, Auth Scaffold y Secrets Management se entregan vía king-entrepreneur / verticales; el módulo enseña su uso e integración con la capa S.)

### Módulo 6 — Entrepreneur Path (10%)

Objetivo: lanzar un MVP a velocidad de fundador sin sacrificar calidad.

- `/genesis` con persona entrepreneur.
- `/auth-in-one-command`, `/payments-in-one-command`, `/deploy-in-one-command`.
- `/landing-page-generate` y `/mvp-accelerator` (orquestador del arco entrepreneur).
- `/validate-idea` y `/lean-canvas` para validación previa.
- Community Templates: cuándo usar cada uno (ver §referencia a `community-templates/`).
- King para MVPs: equilibrio entre velocidad de lanzamiento y los gates mínimos de CASTLE.

**Skills core cubiertos**: `/genesis` (persona entrepreneur). King-entrepreneur referenciado: `/auth-in-one-command`, `/payments-in-one-command`, `/deploy-in-one-command`, `/landing-page-generate`, `/mvp-accelerator`, `/validate-idea`, `/lean-canvas`.

### Módulo 7 — Observability y Performance (15%)

Objetivo: operar y medir lo que se construyó.

- Observer / OpenTelemetry automático.
- Enforce de structured logging (capa L de CASTLE).
- `/health-check`, SLO/SLI y su definición.
- Performance Budget Gate y `/optimize` (análisis Big O).
- AI Cost Attribution (`/cost-report`) para proyectos AI-native.
- Diseño de UI de alto impacto con `/frontend-design` cuando la performance percibida importa.

**Skills core cubiertos**: `/optimize`, `/perf-test`, `/frontend-design`. King-infra / king-ai referenciados: observability, SLO, `/cost-report`.

### Módulo 8 — Ecosistema y Contribución (10%)

Objetivo: consumir y contribuir al ecosistema con seguridad.

- Cómo instalar skills del hub (King Hub).
- Trust Model: los 4 tiers (Official / Trusted / Community / Local) y cómo verificar firmas GPG (ver `knowledge/universal/trust-model.md`).
- Contribuir con `/create-skill`: scaffolding y checklist de publicación Tier 3.
- Community Templates: cuándo crear uno nuevo vs. extender uno existente.
- Onboarding del framework con `/king-onboard`.

**Skills core cubiertos**: `/create-skill`, `/king-onboard`.

### §2.9 — Tabla de trazabilidad skill core → módulo

Esta tabla es el contrato auditable de la regla de cobertura. **Todo skill core de king-core
aparece en al menos un módulo.** Skills auxiliares internos (`_shared`, `_templates`,
`session-management`, `visual-evidence`, `sdd-orchestrator`) quedan fuera por no ser
invocables directamente por el usuario.

| Skill core (king-core) | Módulo(s) |
|---|---|
| `/genesis` | 2, 6 |
| `/plan` | 3 |
| `/build` | 3 |
| `/brainstorm` | 3 |
| `/radar` | 1, 3 |
| `/refine` | 3 |
| `/qa`, `/qa-batch`, `/qa-env` | 3 |
| `/review` | 3 |
| `/promote` | 3 |
| `/worktree` | 3 |
| `/gitflow` | 3 |
| `/commit` | 3 |
| `/github-ops` | 3 |
| `/pr` | 3 |
| `/create-issues` | 3 |
| `/release` | 3 |
| `/fix` | 3 |
| `/refactor` | 3 |
| `/optimize` | 3, 7 |
| `/merge` | 3 |
| `/castle`, `/castle-report` | 4 |
| `/audit` | 4 |
| `/solid-check` | 4 |
| `/contract-test`, `/contract-test-pact` | 4 |
| `/mutation-test` | 4 |
| `/property-test` | 4 |
| `/perf-test` | 4, 7 |
| `/a11y-audit`, `/a11y-fix` | 4 |
| `/test-plan` | 4 |
| `/api-contract-first` | 4 |
| `/clean-arch-setup`, `/hexagonal-setup`, `/ddd-tactical`, `/cqrs-setup`, `/event-sourcing` | 4 (A en KFCA) |
| `/microservice-extract`, `/saga-design`, `/event-broker-setup`, `/db-optimize`, `/explain-query` | 4 (A en KFCA) |
| `/resilience-weave`, `/idempotency` | 5 |
| `/frontend-design` | 7 |
| `/create-skill` | 8 |
| `/king-onboard` | 8 |
| `/sdd-new`, `/sdd-ff`, `/sdd-continue` y fases `sdd-*` | 1 |

> Regla de mantenimiento: al añadir un skill core nuevo, el autor DEBE asignarlo a un módulo
> y actualizar esta tabla en el mismo PR. El gate de auditoría del curriculum (futuro)
> validará que ningún skill core quede huérfano.

---

## 3. KFCA — 4 módulos adicionales (25% cada uno, suman 100%)

El KFCA se construye **sobre** el KFCD (es prerequisito). Estos cuatro módulos NO repiten
el temario base: profundizan en arquitectura, autoría avanzada de skills, enterprise y
gobernanza.

| # | Módulo | Peso |
|---|--------|------|
| A1 | Diseño de Arquitectura con King | 25% |
| A2 | Diseño de Skills Avanzados | 25% |
| A3 | Enterprise y Compliance | 25% |
| A4 | Framework Governance | 25% |
| | **Total** | **100%** |

### Módulo A1 — Diseño de Arquitectura con King (25%)

- Hexagonal Architecture integrada al workflow King (`/hexagonal-setup`).
- SOLID en la práctica con `/build` y `/review` (`/solid-check` como gate).
- Patrones DDD con los agentes King (`/ddd-tactical`, `/cqrs-setup`, `/event-sourcing`).
- Arquitectura distribuida: `/microservice-extract`, `/saga-design`, `/event-broker-setup`.
- Decisiones de arquitectura documentadas con RADAR y ADRs.

### Módulo A2 — Diseño de Skills Avanzados (25%)

- Skills multi-agente con contratos bilaterales (provider/consumer).
- PhaseTransition hooks y enforcement de gates desde un skill.
- Skills de verticales complejas (mobile, AI-native, data).
- Performance de skills: token budgets, modularidad, progressive disclosure.

### Módulo A3 — Enterprise y Compliance (25%)

- CASTLE como lenguaje de compliance.
- Mappings SOC2 / ISO 27001 / NIST 800-53 con CASTLE Spec v1.0 (ver `knowledge/universal/castle-spec-v1.md`).
- Multi-agent portability y adapters de Apex Core.
- Engram cross-project memory graph para auditoría y continuidad.

### Módulo A4 — Framework Governance (25%)

- Contribución al core (proceso Tier 1).
- Deprecation policy y semver de skills (ver `knowledge/universal/deprecation-policy.md` y `skill-versioning.md`).
- Self-quality del framework: test suite, benchmarks, CI.
- Roadmap y proceso de propuesta de nuevos módulos.

---

## 4. KFCSA — Evaluación de portfolio

El KFCSA NO tiene examen escrito: se evalúa un **portfolio de skills publicados** mediante
review del equipo core. El candidato presenta **3 skills** publicados en el hub (Tier 3 mínimo).

### 4.1 Criterios de review (por cada skill)

Cada skill del portfolio se puntúa contra 6 criterios. Cada criterio aprueba (1) o no
aprueba (0): el score por skill es un entero de 0 a 6.

| # | Criterio | Qué se verifica | ¿Obligatorio? |
|---|----------|------------------|---------------|
| 1 | **Funcionalidad** | El skill cumple su propósito declarado sin ambigüedad. | No |
| 2 | **CASTLE alignment** | Declara correctamente qué capas CASTLE toca (`castle_layers`). | No |
| 3 | **Testing** | Al menos 5 scenarios Gherkin verificables. | **Sí** |
| 4 | **Documentation** | `SKILL.md` completo con todas las secciones de la spec v2.0. | **Sí** |
| 5 | **Trust Model compliance** | Firmado con GPG, sin gate-overrides, `api_version` semver válido. | **Sí** |
| 6 | **Mantenimiento** | Al menos 2 versiones publicadas con CHANGELOG. | No |

### 4.2 Umbral de aprobación

- **Por skill**: score mínimo **4/6**, con los criterios **3 (Testing) + 4 (Documentation) + 5 (Trust Model compliance) OBLIGATORIOS**. Un skill que falle cualquiera de los criterios 3, 4 o 5 NO aprueba aunque alcance 4 puntos por otra combinación.
- **Por portfolio**: los **3 skills** deben aprobar individualmente. Un solo skill reprobado invalida el portfolio completo (no se promedia).

Tabla de decisión por skill:

| Criterios 3·4·5 | Score total | Resultado del skill |
|---|---|---|
| Los 3 presentes | ≥ 4/6 | APRUEBA |
| Los 3 presentes | < 4/6 | NO APRUEBA (faltan criterios opcionales) |
| Falta alguno de 3·4·5 | cualquiera | NO APRUEBA (criterio obligatorio ausente) |

### 4.3 Proceso de portfolio review por el equipo core

1. **Submission**: el candidato envía los 3 skills (URLs del hub) mediante el flujo de KFCSA. Cada skill debe ser Tier 3 mínimo y estar publicado.
2. **Verificación automatizada**: el pipeline del hub corre el gate-override-checker y la verificación de firma GPG (criterio 5) y cuenta los scenarios Gherkin (criterio 3). Resultados objetivos pre-cargados para el reviewer.
3. **Code review humano**: dos miembros del equipo core revisan funcionalidad (1), CASTLE alignment (2), documentación (4) y mantenimiento (6). Cada reviewer puntúa de forma independiente.
4. **Resolución**: si ambos reviewers coinciden, el resultado es firme. Si discrepan en algún criterio, un tercer reviewer del core desempata.
5. **Resultado**: APROBADO emite el badge KFCSA (Credly + LinkedIn). RECHAZADO entrega feedback específico por criterio y skill, con guía de remediación; el candidato puede reenviar tras corregir.
6. **Mantenimiento del badge**: ver §1 (Renovación) — el badge sigue activo mientras el portfolio conserve 3 skills Tier 3 con publicación anual.

---

## 5. Integración con `/certification` (king-content, Change B)

El skill `/certification` (entregado en el Change B / king-content) usa este curriculum como
única fuente de temario. Su flujo de fases:

1. **Diagnóstico** — evalúa el nivel actual del candidato contra los módulos del nivel target.
2. **Study Plan** — genera un plan personalizado con los módulos ordenados por prioridad según el diagnóstico, una estimación de tiempo de estudio por módulo, y un porcentaje de preparación estimado.
3. **Mock Exam** — examen simulado con el formato del nivel target (70/90 preguntas según KFCD/KFCA).
4. **Review** — analiza resultados del mock e identifica los módulos a reforzar.
5. **Portfolio Prep** (solo KFCSA) — checklist de readiness contra los 6 criterios de la §4.

Este documento NO implementa el skill: solo define el contrato de contenido que el skill
consume. Por eso el curriculum es actualizable de forma independiente — cuando un skill del
framework evoluciona, se actualiza la §2.9 y el programa queda al día sin tocar `/certification`.

---

## 6. Referencias

- `knowledge/universal/trust-model.md` — 4 tiers, firmas GPG, gate-override checker, CRL (criterio 5 de KFCSA).
- `knowledge/universal/castle-spec-v1.md` — CASTLE Spec v1.0 y mappings de compliance (Módulo A3).
- `knowledge/universal/skill-versioning.md` — `api_version` semver y CHANGELOG (criterios 5 y 6 de KFCSA).
- `knowledge/universal/deprecation-policy.md` — deprecación y LTS (Módulo A4).
- `knowledge/universal/community-templates/` — los 10 templates oficiales (Módulos 6 y 8).
- `king-content/skills/certification/SKILL.md` — el skill de preparación (Change B).
