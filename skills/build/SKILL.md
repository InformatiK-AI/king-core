---
name: build
description: "Workflow guiado para desarrollar features completas. Usar cuando se necesite: construir una feature nueva, implementar funcionalidad, desarrollar un componente, o agregar una capacidad al sistema."
version: 2.0
---

# Build Feature — Workflow de Desarrollo

Workflow completo para implementar una feature desde cero hasta PR listo para review.

> **Path resolution**: Paths `skills/`, `agents/`, `knowledge/`, `rules/` son relativas a KING_FRAMEWORK_PATH (anunciado al inicio de sesión). Prepend ese valor al usar Read.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural context and decisions for the build | Yes | project |
| `.king/knowledge/conventions.md` | Code style, naming and commit conventions | Yes | project |
| `.king/knowledge/stack.md` | Stack-specific idioms and implementation patterns | Yes | project |
| `.king/knowledge/environments.md` | Environment configuration and deployment constraints | Yes | project |
| `knowledge/_inject/multi-tenancy.md` | RLS, ABAC y tenant context injection. Cargar solo si contexto SaaS multi-tenant detectado (ver Fase 2, paso 7) | No (SaaS only) | framework |
| `knowledge/_inject/resilience-patterns.md` | Retry, circuit breaker, bulkhead and timeout patterns for external service integrations | Conditional | framework |

> **Conditional** (resilience-patterns.md): load at Knowledge Injection time if input mentions `api externa`, `http client`, `external api`, `third-party`, `webhook`, or `microservice`.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se especificó issue, tarea ni descripción de feature
- [ ] No existe sesión de `/genesis` previa en el proyecto
- [ ] No existe plan previo en `docs/plans/` referenciado como artefacto tipo "Plan" en el workflow context (usar `/plan` primero, o `/fix` para correcciones rápidas)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA hacer commit directamente a `main` o `develop` — siempre via feature branch
- NUNCA proceder a fases de implementación si los tests están en rojo

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Código implementado y funcional
- [ ] Tests unitarios/integración actualizados
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8 → Phase 9 → Phase 10 → Phase 11
Load      Setup    Discovery  Arch     Implement  Testing   Security  CASTLE   GitHub   Report   Session   Guide
```

---

## Input
- **Issue de GitHub (recomendado)**: `/build #42` — Lee el issue de GitHub, extrae Gherkin y DoD como spec de implementación. Máxima trazabilidad plan→issue→code.
- **Issue local (recomendado)**: `/build STORY-001` — Lee `.king/issues/STORY-001.md`, extrae Gherkin, DoD, archivos afectados y notas. Funciona sin GitHub.
> **Nota**: Todo `/build` requiere plan previo registrado en el workflow context. Para cambios rápidos o hotfixes sin plan, usar `/fix`.

## Agentes involucrados
- **@architect** → Evalúa impacto arquitectónico y propone diseño
- **@developer** (o **@frontend** si es UI) → Implementa el código
- **@qa** → Verifica acceptance criteria y calidad
- **@security** → Ejecuta security gate básico

## CASTLE: C·A·_·T·L·_ — [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## PHASE ROUTER

> **Excepción v2.0 documentada**: Este skill usa PHASE ROUTER con carga modular por sub-archivos.
> Justificación: entry point ~900 tokens; carga total ~3310 tokens.
> Los sub-archivos se cargan on-demand según la fase activa.

| Fases | Sub-archivo |
|-------|-------------|
| Fase 1: Setup → Fase 9: Report (todas las fases de implementación) | [PHASES.md](PHASES.md) |

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
| Risks | _(listar findings CONDITIONAL o BREACHED, o "None")_ |

### Fase 10: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 11: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para build:
| Condición | Próximo Skill |
|-----------|---------------|
| Siempre (build completo) | `/review` — Code review obligatorio antes de QA |

---

## Archivos del skill

| Archivo | Contenido |
|---------|-----------|
| `SKILL.md` | Entry point — este archivo (~900t) |
| `PHASES.md` | Fases 1-9: Setup, Discovery, Architecture, Implementation, Testing, Security, CASTLE, GitHub, Report |

## Ver también

- `skills/build/PHASES.md` — Lógica detallada de las 9 fases
- `skills/_shared/lifecycle-outputs.md` — Convención de rutas de sesión
- `skills/session-management/SKILL.md` — Phase 0 y Phase N+1
