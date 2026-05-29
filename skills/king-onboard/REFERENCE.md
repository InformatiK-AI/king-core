# King Framework — Mapa de Skills

Referencia completa de todos los skills del ecosistema King, organizados por categoría, con el trigger de cuándo usar cada uno.

---

## Core SDLC (10 skills)

El pipeline estándar de desarrollo. El orden es la cadena de valor.

| Skill | Cuándo usarlo |
|-------|--------------|
| `/genesis` | Al iniciar un proyecto nuevo con King Framework. Crea `.king/` con stack, arquitectura y convenciones. |
| `/brainstorm` | Cuando tenés una idea pero no está clara. Valida el problema, define el scope, y produce el brief para /plan. |
| `/plan` | Cuando el brainstorm está aprobado y necesitás un plan de implementación. Coordina agentes en paralelo. |
| `/build` | Cuando tenés un plan aprobado. Crea branch, implementa, escribe tests, verifica ACs. |
| `/review` | Después de /build. Code review con CASTLE assessment. Requiere que no haya PR abierta. |
| `/qa` | Después de /review. Verifica ACs, coverage gate, y security gate. |
| `/fix` | Cuando QA o review encuentran un bug. Diagnostica root cause, crea fix branch, verifica que no hay regresiones. |
| `/merge` | Después de /qa PASS. Integra la feature a develop con la estrategia de merge correcta. |
| `/promote` | Cuando develop está listo para subir a QA o staging. Promueve entre ambientes. |
| `/release` | Cuando QA/staging está aprobado para producción. Genera release branch, changelog, y tag semántico. |

---

## SDD Pipeline (9 skills + 4 meta-commands)

Para cambios complejos que requieren más de una sesión, trazabilidad explícita, o coordinación de múltiples agentes con dependencias. Trigger automático cuando /plan detecta ≥ 2 señales de complejidad.

### Skills individuales

| Skill | Cuándo usarlo |
|-------|--------------|
| `/sdd-init` | Inicializar el contexto SDD para el proyecto. Detecta testing capabilities. Corre automáticamente si no fue ejecutado. |
| `/sdd-explore` | Investigar un área del codebase antes de comprometerse con un cambio. Sin artefactos creados. |
| `/sdd-propose` | Formalizar la propuesta: QUÉ y POR QUÉ. Produce `proposal.md`. |
| `/sdd-spec` | Escribir specs en formato Given/When/Then a partir de la propuesta. Produce delta specs. |
| `/sdd-design` | Definir el CÓMO: arquitectura, decisiones de diseño, rationale. Produce `design.md`. |
| `/sdd-tasks` | Descomponer design+spec en tareas concretas y checkeables. Produce `tasks.md`. Forecasta PR budget. |
| `/sdd-apply` | Implementar las tareas en batches. Narra progreso. Soporta entrega iterativa con PR budget guards. |
| `/sdd-verify` | Validar que la implementación cumple las specs. Produce compliance matrix: COMPLIANT/FAILING/UNTESTED. |
| `/sdd-archive` | Cerrar el cambio: mergear delta specs, archivar artefactos, registrar audit trail. |

### Meta-commands (orquestador)

| Meta-command | Cuándo usarlo |
|-------------|--------------|
| `/sdd-new <nombre>` | Arrancar un cambio SDD nuevo: init → explore → propose en un solo comando. |
| `/sdd-ff <nombre>` | Fast-forward planning: propose → spec ∥ design → tasks. Cuando ya tenés el explore hecho. |
| `/sdd-continue [nombre]` | Continuar un cambio SDD en progreso. Lee `state.yaml` y ejecuta la próxima fase disponible. |
| `/sdd-onboard` | Walkthrough guiado del ciclo SDD completo usando tu codebase real. Para aprender SDD haciendo. |

---

## Prompt & Quality (4 skills)

Utilidades para mejorar la calidad del trabajo en cualquier punto del ciclo.

| Skill | Cuándo usarlo |
|-------|--------------|
| `/refine` | Antes de ejecutar cualquier skill con un prompt complejo. Optimiza el prompt con PE techniques. Tiene modo Quick y Deep. |
| `/test-plan` | Antes de /build para features críticas. Genera una estrategia de testing exhaustiva con casos edge y priorización. |
| `/audit` | Cuando querés un diagnóstico amplio del estado del proyecto. Evalúa salud del codebase, deuda técnica, gaps. |
| `/refactor` | Después de review o audit cuando hay code smells identificados. Limpieza quirúrgica sin cambios de funcionalidad. |

---

## Git & Ops (2 skills)

Operaciones de repositorio y flujo de trabajo.

| Skill | Cuándo usarlo |
|-------|--------------|
| `/worktree` | Cuando trabajás en múltiples features en paralelo. Crea git worktrees aislados. También gestiona los ambientes dev/qa/prod. |
| `/github-ops` | Para cualquier operación de GitHub: crear issues, revisar PRs, gestionar labels, analizar CI/CD status. |

---

## Meta-skills del Framework (3 skills)

Para extender y operar King Framework mismo.

| Skill | Cuándo usarlo |
|-------|--------------|
| `/create-skill` | Cuando necesitás crear un skill nuevo que siga las convenciones king v2.0. Checklist y template. |
| `/king-onboard` | Walkthrough guiado del SDLC completo para usuarios nuevos. Este skill. |
| `/frontend-design` (king-content, si king-content está instalado) | Para la documentación web en `docs/`. Diseña y genera páginas con accesibilidad WCAG. |

---

## Utilidades Específicas (varios)

Skills para casos puntuales.

| Skill | Cuándo usarlo |
|-------|--------------|
| `/castle` | Ejecutar un CASTLE quality gate manualmente. Útil para evaluar código legado. |
| `/radar` | Aplicar el protocolo RADAR (Read→Analyze→Decide→Act→Report) a cualquier tarea ambigua. |
| `/commit` | Generar commits convencionales con formato estándar. |
| `/pr` | Crear o revisar Pull Requests con template estructurado. |
| `/gitflow` | Gestionar el flujo git (branch strategy, naming conventions). |
| `/optimize` | Optimizar performance de código identificado como bottleneck. |
| `/qa-batch` | QA sobre múltiples features o issues en paralelo. |
| `/qa-env` | QA de un ambiente completo (staging, QA). |
| `/visual-evidence` | Capturar screenshots y comparaciones visuales como evidencia de QA. |

---

## Agents (9 agentes especializados)

Invocados automáticamente por los skills. También disponibles directamente con `@nombre`.

| Agente | Especialidad | CASTLE Layer |
|--------|-------------|-------------|
| `@architect` | Decisiones de arquitectura, ADRs, dependency direction | A |
| `@developer` | Implementación, refactoring, code quality | T |
| `@qa` | Quality assurance, testing, CASTLE T+L layers | T · L |
| `@security` | Security gate, OWASP, veto de seguridad | S |
| `@frontend` | UI/UX, accesibilidad WCAG, docs web | — |
| `@devops` | CI/CD, pipelines, deployments, environments | E |
| `@api` | Diseño de APIs, contratos, schemas | C |
| `@performance` | Latencia, throughput, optimización | — |
| `@mobile` | Mobile constraints, offline, battery | — |

---

## Plugins del Ecosistema

Skills adicionales disponibles instalando los plugins correspondientes.

| Plugin | Skills | Persona |
|--------|--------|---------|
| `king-ai` | /llm-integration, /ai-feature-scaffold, @ml-engineer | Developer que añade IA a un proyecto |
| `king-infra` | /db-migrate, /db-seed, /publish-package, /auth-scaffold, /health-check-setup, /dr-setup | DevOps / Platform engineer |
| `king-mobile` | /mobile-scaffold, /mobile-deploy, @mobile | Mobile developer |
| `king-content` | /blog-setup, /headless-cms-setup, /brand-identity | Equipo de contenido / SEO |
| `king-entrepreneur` | /welcome, /idea-validate, /mvp-launch, ... | Fundador / Emprendedor |
| `king-legal` | /legal-docs-generate | Compliance / Legal |

---

## Cuándo usar SDD vs SDLC estándar

```
¿El cambio toca 3+ archivos con dependencias cruzadas?   → SDD
¿Se estima en más de una sesión de trabajo?              → SDD
¿Requiere trazabilidad explícita (compliance, auditoría)?→ SDD
¿Cambia arquitectura, API pública, o datos?              → SDD
¿Es un bug fix, tweak, o feature de 1-2 archivos?        → SDLC estándar
¿Es rápido y discreto (< 1 sesión)?                      → SDLC estándar
```

`/plan` y `/build` detectan estas señales automáticamente y ofrecen escalar a SDD.
