---
name: create-issues
description: "Crear issues estructurados desde un plan de implementación. Usar cuando se necesite: crear issues desde un plan, generar epic y stories, crear issues con Gherkin, descomponer un plan en issues, o preparar backlog. Soporta GitHub Issues o tracking local en .king/issues/."
version: 2.0
api_version: 1.0.0
pipeline_position: "optional — between /plan and /build"
model: sonnet
---

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural context for identifying affected components | Yes | project |
| `.king/knowledge/conventions.md` | Naming and documentation conventions for issue creation | Yes | project |

---

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se proporcionó ruta al plan de implementación
- [ ] El archivo de plan no existe o no es legible
- [ ] El plan no contiene tareas identificables (sin objetivo general ni tareas)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA crear issues con criterios de aceptación ambiguos o sin escenarios Gherkin
- NUNCA crear issues que no correspondan a tareas del plan aprobado

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Epic creado (GitHub o local) con número/ID asignado
- [ ] Stories creadas con Gherkin, DoD y Acceptance Criteria
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
Phase 0 (Load Context) → Fase 1 (Detección Modo y Validación) → Fase 2 (Análisis del Plan) → Fase 3 (Generación Gherkin) → Fase 4 (DoD y Acceptance Criteria) → Fase 5 (Composición de Issues) → Fase 6 (Creación de Issues) → Fase 7 (Verificación) → Fase 8 (Report) → Fase 9 (Write Session) → Fase 10 (Guide Next Step)

---

# Create Issues — Plan a Issues (GitHub o Local)

Convierte un plan de implementación en un Epic + Stories con escenarios Gherkin, Definition of Done, y Acceptance Criteria estructurados.

**Dual-mode:** Detecta automáticamente si GitHub CLI está disponible. Si lo está, crea issues en GitHub (flujo original). Si no, genera tracking local en `.king/issues/` con archivos Markdown.

## Agentes involucrados
- **@architect** → Descomposición INVEST de tareas, estructura Epic/Stories
- **@qa** → Generación de escenarios Gherkin (funcionales y técnicos)
- **@devops** → Operaciones GitHub (labels, issues, milestones)

## CASTLE activo: C·A·_·_·_·_

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## PHASE ROUTER

> **Excepción v2.0 documentada**: Este skill usa PHASE ROUTER con carga modular por sub-archivos.
> Justificación: entry point ~700 tokens; carga total ~2220 tokens.
> Los sub-archivos se cargan on-demand según la fase activa.

| Fases | Sub-archivo |
|-------|-------------|
| Fases 1-8: Detección → Análisis → Gherkin → DoD → Composición → Creación → Verificación → Report | [PHASES.md](PHASES.md) |

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Sesión registrada

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(copiar de CASTLE Assessment)_ |
| Artifacts | _(listar archivos modificados, branch, PR)_ |
| Next Recommended | _(ver Guide Next Step)_ |
| Risks | _(riesgos activos o "None")_ |

### Fase 9: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 10: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

**Instrucciones explícitas de navegación post-creación:**

1. Listar todas las Stories creadas ordenadas por prioridad y dependencias
2. Identificar la primera Story a implementar (menor dependencias, mayor prioridad)
3. Mostrar el comando exacto según el modo:
   - **MODO GITHUB:** `/build #[número-primera-story]`
   - **MODO LOCAL:** `/build STORY-[NNN]`
4. Mostrar resumen de todas las stories para referencia:
   ```
   Stories creadas (orden recomendado de implementación):
   1. STORY-001 / #42 — [título] (priority: high)
   2. STORY-002 / #43 — [título] (priority: high)
   3. STORY-003 / #44 — [título] (priority: medium)
   ```

Tabla de flujo para create-issues:
| Condición | Próximo Skill |
|-----------|---------------|
| Issues creados (GitHub) | `/build #[primera-story]` |
| Issues creados (Local) | `/build STORY-[NNN]` |
| Error en creación | Resolver error → repetir `/create-issues` |

---

## Archivos del skill

| Archivo | Contenido |
|---------|-----------|
| `SKILL.md` | Entry point — este archivo (~700t) |
| `PHASES.md` | Fases 1-8: detección, análisis, Gherkin, DoD, composición, creación, verificación, report |

## Ver también

- `skills/create-issues/PHASES.md` — Lógica detallada de las 8 fases
- `skills/_shared/lifecycle-outputs.md` — Convención de rutas de sesión
- `skills/session-management/SKILL.md` — Phase 0 y Phase N+1
