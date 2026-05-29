# Exploration — M13 Ecosystem & Community

> Fase: sdd-explore · Backend: openspec · Fecha: 2026-05-28

## Objetivo del cambio

Dotar a `king-core` de la infraestructura de **ecosistema y comunidad**: capacidades para
descubrir, publicar, versionar y validar plugins/skills de terceros, junto con la documentación
y convenciones que habiliten contribuciones externas. Hoy King es un conjunto de plugins
independientes sin ningún tejido conectivo de "marketplace" ni de gobernanza comunitaria.

## Estado actual del codebase

- **Repo**: `king-core` (rama `feature/m13-ecosystem-community` desde `develop`). 68 skills.
- **No existe infraestructura de ecosistema/comunidad/marketplace**:
  - No hay registro/catálogo de plugins ni mecanismo de descubrimiento.
  - No hay flujo de publicación ni de versionado inter-plugin coordinado.
  - No hay guía de contribución comunitaria ni convenciones de autoría de terceros.
- **Cada plugin es su propio repositorio git** (king-core, king-ai, king-infra, king-mobile,
  king-entrepreneur, etc.). No comparten un monorepo ni un índice común.
- **La raíz `D:\King Framework` no es el repo**: cada plugin tiene su `.git` propio
  (`king-core/.git` es un repo real en rama `develop`). El versionado y la distribución son
  por-plugin, lo que refuerza la necesidad de una capa de ecosistema que los relacione.
- **Ningún artefacto de M13 existe aún**. No hay plan fuente en `mejora/planes-detallados/`
  (directorio inexistente en este worktree); solo existe la rama git. No hay colisión.

## Áreas afectadas

- **`knowledge/universal/`** — destino natural de los knowledge files nuevos de ecosistema
  (publishing/versionado de plugins, contribución comunitaria, gobernanza). Ya alberga
  `skill-versioning.md`, `deprecation-policy.md` y `git-mastery.md`, que son piezas de apoyo
  directas y deben referenciarse (no duplicarse).
- **`skills/create-skill/`** — meta-skill de autoría. Es el punto de extensión para incorporar
  pasos de publicación/registro y conformidad con las convenciones del ecosistema al crear
  skills nuevos. Extensión aditiva, sin romper su flujo actual.
- **`LOAD-INDEX`** (`templates/LOAD-INDEX.md.template`) — el índice de carga de recursos por
  contexto. Debe actualizarse para documentar los skills/knowledge nuevos de M13 y su token
  budget, manteniendo la regla "Referencias > Duplicación".

## Anatomía a respetar (patrón existente)

- Cada skill: `skills/{name}/SKILL.md` con frontmatter (name, version, api_version, description),
  Knowledge Injection con graceful degradation, QUICK REFERENCE, fases con
  GATE IN/MUST DO/CHECKPOINT/IF FAILS, FINAL CHECKPOINT, Execution Summary, REFERENCE.
  Plantilla canónica: `skills/_shared/skill-anatomy.md`.
- Cada command: `commands/{name}.md` doc invocable con ≥1 ejemplo de output.
- Knowledge: `knowledge/universal/{name}.md` o `knowledge/domain/{name}.md`.

## Stack y testing

- Plugin Markdown/YAML sin build step. Tooling Python para self-tests: pytest
  (tests/ unit+integration+benchmarks+snapshots), ruff lint, pytest-cov.
  Verificación = conformidad estructural, no runtime.

## Approaches considerados

1. **Cambio informal directo en `develop`** — rápido, pero sin trazabilidad de specs ni gates;
   incompatible con la naturaleza de infraestructura transversal de M13. Descartado.
2. **Monorepo de plugins** — unificar todos los plugins bajo un solo repo para resolver el
   descubrimiento/versionado de raíz. Cambio estructural masivo, fuera del alcance de M13 y de
   alto riesgo. Descartado para este cambio (posible iniciativa futura separada).
3. **SDD formal + worktree + merge a develop, bloque-a-bloque (estilo M03)** — un único cambio
   SDD con fases del mismo `tasks.md`, ejecutado por bloques (A1..A6) vía Workflow, con merge
   único squash a `develop`. Aditivo, trazable, dogfooding del propio framework. **Recomendado.**

## Recomendación

Adoptar el **approach 3**: SDD formal sobre backend `openspec` (filesystem-first, evita el bug
Engram `ambiguous_project` desde `D:\King Framework`), en el worktree
`feature/m13-ecosystem-community`, con autoría organizada en bloques A1..A6 aplicados por Workflow
y un **merge único squash a `develop`** al cierre (`single-pr` + `size:exception`, igual que M03/M04).

## Decisiones de exploración

1. **Backend openspec (filesystem-first)** — evita `ambiguous_project` desde `D:\King Framework`.
2. **Un único cambio SDD** con los bloques A1..A6 como agrupación de tareas del mismo `tasks.md`.
3. **single-pr + size:exception** — se asume superar el budget de 400 líneas a propósito (1 merge final).
4. **Authoring por bloques** (knowledge/skills independientes paralelizables) vs **extensiones
   aditivas** a `skills/create-skill/` y `LOAD-INDEX` (secuenciales, con git diff de control).

## Riesgos detectados

- Engram `ambiguous_project` → mitigado con openspec.
- `.king/knowledge|specs` no trackeados → copiar manualmente al worktree si se requieren.
- Extensión a `skills/create-skill/` y `LOAD-INDEX` (archivos vivos) → editar aditivo + git diff de control.
- PR grande → review por bloque (A1..A6) para trazabilidad incremental.
- Ausencia de plan fuente formal M13 → la fase de propose/specs debe redactar la fuente de verdad.
