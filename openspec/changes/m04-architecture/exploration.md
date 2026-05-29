# Exploration — M04 Architecture & Patterns

> Fase: sdd-explore · Backend: openspec · Fecha: 2026-05-28

## Objetivo del cambio

Convertir `king-core` en un guía arquitectónico accionable: 14 skills nuevos, 5 knowledge files,
2 hooks y 3 extensiones aditivas a archivos existentes. Fuente de verdad ya redactada:
`mejora/planes-detallados/M04-architecture-and-patterns.md` (1.465 líneas, §2 diseño técnico,
§6 las 43 tareas T01-T43, §7 Gherkin/acceptance, §8 plan de sprints).

## Estado actual del codebase

- **Repo**: `king-core` (rama feature/m04-architecture desde develop @ 3d2a6e5). 54 skills.
- **Dependencias satisfechas**:
  - M01 Quality Gates ✅ — `skills/solid-check/`, `skills/castle-report/`, gates coverage/a11y/perf, CASTLE v2.
  - M07 Multi-tenancy/Security ✅ — `agents/tenancy-enforcer.md`, `knowledge/domain/multi-tenancy-patterns.md`,
    secrets management, hooks rls-validator. → `/microservice-extract` podrá propagar tenancy.
- **Ningún artefacto de M04 existe aún** (0/14 skills, 0/5 knowledge). No hay colisión.

## Capacidades de arquitectura existentes (reuso)

- `agents/architect.md` — dueño de la capa A de CASTLE (dependency direction A2 BLOQUEANTE, coupling A4,
  pattern consistency A3). Se EXTIENDE (aditivo) con "Architecture Patterns Knowledge" + árbol de decisión.
- `agents/performance.md` — se EXTIENDE (aditivo) con "ORM Checks" (queries en loops → /explain-query).
- `skills/sdd-apply/SKILL.md` — se EXTIENDE con "Step 0 — Architecture Pattern".
- `hooks/hooks.json` — se AÑADEN (append a arrays existentes) 2 hooks: resilience-check, api-change-check.
- `skills/solid-check/`, `skills/castle/`, `knowledge/domain/multi-tenancy-patterns.md` — referencias de patrón.

## Anatomía a respetar (patrón existente)

- Cada skill: `skills/{name}/SKILL.md` con frontmatter (name, version, api_version, description),
  Knowledge Injection con graceful degradation, QUICK REFERENCE, fases con GATE IN/MUST DO/CHECKPOINT/IF FAILS,
  FINAL CHECKPOINT, Execution Summary, REFERENCE. Plantilla canónica: `skills/_shared/skill-anatomy.md`.
- Cada command: `commands/{name}.md` doc invocable con ≥1 ejemplo de output.
- Knowledge: `knowledge/domain/{name}.md`.

## Stack y testing

- Plugin Markdown/YAML sin build step. Tooling Python para self-tests: pytest (tests/ unit+integration+
  benchmarks+snapshots), ruff lint, pytest-cov. Verificación = conformidad estructural, no runtime.

## Decisiones de exploración

1. **Backend openspec (filesystem-first)** — evita el bug Engram `ambiguous_project` desde `D:\King Framework`.
2. **Un único cambio SDD** con 5 sprints como fases del mismo `tasks.md`.
3. **single-pr + size:exception** — supera el budget de 400 líneas a propósito (decisión del usuario: 1 merge final).
4. **Authoring paralelizable** (knowledge/skills/commands independientes) vs **extensiones secuenciales/aditivas**
   (architect.md, performance.md, sdd-apply, hooks.json).

## Riesgos detectados

- Engram ambiguous_project → mitigado con openspec.
- `.king/knowledge|specs` no trackeados → ya copiados al worktree.
- Extensiones a archivos críticos → editar aditivo + git diff de control.
- PR grande → review por sprint para trazabilidad incremental.
