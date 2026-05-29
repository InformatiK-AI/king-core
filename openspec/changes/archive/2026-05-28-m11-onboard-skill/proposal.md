# Proposal — M-11 Onboarding TUI 5 Niveles (skill `onboard`)

> Fase: sdd-propose · Change: m11-onboard-skill · Backend: openspec

## Why

King tiene 40+ skills pero ningún punto de entrada único para un developer nuevo: el onboarding demanda 2-4 horas.
M-11 crea un tutorial de adopción gamificado de 5 niveles con validación de éxito, barra de progreso y
persistencia, con TTFC objetivo < 5 minutos. Es el punto de entrada; `king-onboard` (existente) sigue siendo el
walkthrough profundo del SDLC. Depende de C1 (define `doctor`/`status`/`hint` en `cli-architecture.md`).

## What Changes

Se agrega a `king-core`:
- `skills/onboard/SKILL.md` — skill NUEVO (distinto de `king-onboard`): 5 niveles validados, sub-comandos
  `doctor`/`status`/`hint`, quickstart por persona, retoma `--level N`, formato `.king/onboard-progress.yaml`.

Fuente de verdad: `mejora/planes-detallados/M12-developer-experience-tooling.md` (§2 M-11, §6 T01-T15, §7 Gherkin).

## Capabilities (contrato para sdd-spec)

| # | Capability | Item | Artefacto |
|---|------------|------|-----------|
| 1 | `onboard` | M-11 | `skills/onboard/SKILL.md` |

## Scope

- **In scope**: el skill `onboard` (5 niveles, sub-comandos, persona, retoma, formato progress.yaml). T01-T13.
- **Diferido**: T14 (script de integración de los 5 niveles — suite del framework) y T15 (medición TTFC con
  tester humano — no automatizable).

## Verification

`sdd-verify` valida anatomía v2.0 del skill + cobertura Gherkin §7 (6 escenarios) + que las referencias a
`doctor`/`status`/`hint` (C1) y a comandos existentes (`/genesis`, `/qa`, `/sdd-new`, `/promote`, `king-onboard`)
sean válidas. Gate CASTLE ≥ 85, pytest estructural verde.
