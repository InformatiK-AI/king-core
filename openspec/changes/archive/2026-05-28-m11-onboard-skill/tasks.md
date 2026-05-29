# Tasks — M-11 Onboarding TUI (skill `onboard`)

> Detalle en `mejora/planes-detallados/M12-developer-experience-tooling.md §6 (T01-T15)`.

## Apply
- [x] T01 Leer king-onboard SKILL.md/PHASES.md; mapear reuso vs nuevo (documentado en encabezado + design)
- [x] T02 `skills/onboard/SKILL.md` — estructura base, blocking, required outputs, overview
- [x] T03 Nivel 1 (`/genesis`) — instrucción, criterio, validación `.king/`
- [x] T04 Nivel 2 (`/brainstorm`) — instrucción, criterio, validación proposal
- [x] T05 Nivel 3 (`/qa`) — instrucción, criterio, validación CASTLE score
- [x] T06 Nivel 4 (`/sdd-new` + `/sdd-ff`) — instrucción, criterio, validación SPEC+TASKS
- [x] T07 Nivel 5 (`/promote --env staging`) — instrucción, criterio, gates verdes + derivación a king-onboard
- [x] T08 Sub-comando `doctor` — checks `[OK]/[WARN]/[ERROR]`
- [x] T09 Sub-comando `status` — sesiones, skills, gates, último commit
- [x] T10 Sub-comando `hint` — detección de nivel + sugerencia
- [x] T11 Quickstart por persona (Developer/Entrepreneur/Migración)
- [x] T12 Barra de progreso ASCII + formato `.king/onboard-progress.yaml`
- [x] T13 Retoma `/onboard --level N`
- [~] T14 Script de integración de los 5 niveles — diferido (suite del framework)
- [~] T15 Medición TTFC con tester externo — diferido (manual)

## Verify
- [x] Cobertura Gherkin §7: 6 escenarios reflejados
- [x] Anatomía v2.0 + frontmatter + api_version
- [x] Referencias válidas (doctor/status/hint de C1; /genesis, /qa, /sdd-new, /promote, king-onboard)
- [x] CASTLE ≥ 85, pytest estructural verde
