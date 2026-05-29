# Tasks — A6 king-arch decouple

> Fase: sdd-tasks · Change: a6-king-arch-decouple · Agrupadas por fase. `[ ]` pendiente · `[x]` hecho.

## Bloque B0 — Setup (king-core)
- [ ] B0.1 Crear branch `feature/a6-king-arch-decouple` desde develop en king-core.

## Bloque B1 — Crear estructura king-arch
- [ ] B1.1 Crear `king-arch/` con `git init`; agregar `.gitignore` (espejo de king-infra).
- [ ] B1.2 Crear `king-arch/.claude-plugin/plugin.json` (name king-arch, v1.0.0, requires:[king-framework], description con las 12 por dominio, keywords).
- [ ] B1.3 Crear `king-arch/CHANGELOG.md` (entrada inicial v1.0.0 — extracción A6 desde king-core).
- [ ] B1.4 Crear `king-arch/openspec/` (config.yaml mínimo espejo de king-core).
- [ ] B1.5 Copiar `king-core/skills/_shared/*` (18 archivos) a `king-arch/skills/_shared/`.

## Bloque B2 — Mover las 12 skills + commands + 2 knowledge
- [ ] B2.1 Mover las 12 carpetas `king-core/skills/{12}/` → `king-arch/skills/{12}/` (carpeta completa, `git mv`/`git rm` + add en destino).
- [ ] B2.2 Mover los 12 `king-core/commands/{12}.md` → `king-arch/commands/`.
- [ ] B2.3 Mover `king-core/knowledge/domain/saga-patterns.md` y `distributed-systems.md` → `king-arch/knowledge/domain/`.
- [ ] B2.4 Ajustar en su nuevo hogar las menciones internas de saga-patterns.md (líneas 304, 502) — quedan intra-king-arch, sin sufijo graceful.

## Bloque B3 — Reescritura graceful en king-core (kernel → skill movida)
- [ ] B3.1 `agents/architect.md` — anotar `/clean-arch-setup`, `/hexagonal-setup`, `/ddd-tactical`, `/cqrs-setup`, `/event-sourcing` (árbol de decisión ~40, 110-135) con "(king-arch, si está instalado)" + nota de degradación (knowledge queda → guidance sigue válida).
- [ ] B3.2 `skills/sdd-apply/SKILL.md` (38-42) — mismas opciones de arquitectura graceful; preservar fallback "follow existing pattern".
- [ ] B3.3 `knowledge/domain/resilience-patterns.md` (4, 397) — `/resilience-weave (king-arch, si está instalado)`.
- [ ] B3.4 `hooks/resilience-check.sh` (46) — texto del WARNING → `/resilience-weave (king-arch, si está instalado)`. (`hooks.json` NO se toca.)
- [ ] B3.5 `hooks/api-change-check.sh` (41) — texto del WARNING → `/api-contract-first (king-arch, si está instalado)`.

## Bloque B4 — Manifiestos e índices king-core
- [ ] B4.1 `.claude-plugin/plugin.json` — quitar "arquitectura (clean/hexagonal/CQRS/DDD/sagas)" del scope; extender nota A3 con "…arquitectura ahora en king-arch — referencia opcional"; version `1.11.1 → 1.12.0`.
- [ ] B4.2 `LOAD-INDEX.md` — quitar las 11 entradas de "Arquitectura (M04)" + `contract-test-pact`; mantener `/solid-check` (reubicar); degradar saga-patterns/distributed-systems; actualizar notas de hooks; recalcular conteo de skills.
- [ ] B4.3 `CHANGELOG.md` — entrada estilo A3: `### Changed (A6 — desacople king-arch) — king-core NN→MM skills…`.
- [ ] B4.4 `README.md` — recalcular y alinear conteo de skills (deuda preexistente README/CHANGELOG/LOAD-INDEX).

## Bloque B5 — Registro / instalabilidad
- [ ] B5.1 Añadir entrada `king-arch` al array `plugins[]` de `proyectos referencia/King/king-marketplace/.claude-plugin/marketplace.json` (source = repo king-arch). JSON válido.
- [ ] B5.2 (Opcional, recomendado) Regularizar el marketplace agregando king-content/infra/ai/mobile/legal faltantes.
- [ ] B5.3 (Opcional) Añadir las 12 filas a la tabla de skills del CLAUDE.md del ecosistema con sufijo "— requires king-arch".

## Bloque B6 — VERIFY
- [ ] B6.1 `python -m pytest tests/ --cov=src --cov-fail-under=80 -v` → 59+ passed, cov ≥80%.
- [ ] B6.2 `python scripts/audit_self.py --ci-threshold 80` (king-core) → health ≥80, EXIT 0.
- [ ] B6.3 `python scripts/check_api_version.py skills/**/SKILL.md` → sin "missing api_version".
- [ ] B6.4 `pre-commit run --all-files` → pass; plugin.json/hooks.json JSON válido.
- [ ] B6.5 audit_self.py sobre `king-arch/skills` → health ≥80.
- [ ] B6.6 Degradación graceful: simular los 2 hooks con stdin → `exit 0` + texto "(king-arch, si está instalado)".
- [ ] B6.7 Grep de no-regresión: ninguna ref kernel→las 12 sin sufijo graceful; ninguna `requires` king-core→king-arch.
- [ ] B6.8 Generar `verify-report.md` con verdict CASTLE.

## Bloque B7 — ARCHIVE
- [ ] B7.1 Sincronizar delta specs a `king-core/openspec/specs/` SIN borrar los live-specs de las skills movidas.
- [ ] B7.2 Archivar el change a `openspec/changes/archive/<fecha>-a6-king-arch-decouple/`.
- [ ] B7.3 Actualizar `state.yaml` (phases completas + castle_verdict + verification).
- [ ] B7.4 Commit en king-core (feature branch) + commit inicial en king-arch. **Push/PR/merge → confirmar con el usuario.**
