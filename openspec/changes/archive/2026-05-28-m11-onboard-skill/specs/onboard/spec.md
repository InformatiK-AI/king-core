# Delta Spec — onboard (M-11)

## ADDED Requirements

### Requirement: Skill `onboard`
`king-core` SHALL proveer `skills/onboard/SKILL.md`, un tutorial de adopción de 5 niveles distinto de
`king-onboard`. Cada nivel MUST tener UN comando copy-pasteable y un criterio de éxito verificable (`✓`/`✗`).
MUST persistir el progreso en `.king/onboard-progress.yaml` y NUNCA marcar un nivel completo si el criterio dio `✗`.

#### Scenario: TTFC menor a 5 minutos
- **Given** un repositorio vacío
- **When** el developer ejecuta `/onboard`
- **Then** muestra `[□□□□□] Nivel 1/5 — Hola, King`, el objetivo en una línea y el comando único; completar el Nivel 1 toma < 5 min

#### Scenario: Progresión por los 5 niveles
- **Given** el Nivel N completo
- **When** el developer ejecuta el comando del Nivel N+1
- **Then** valida el criterio del Nivel N+1, actualiza `onboard-progress.yaml` y muestra `[■■■□□] Nivel N+1/5 — <nombre>`

### Requirement: Retoma `--level N`
SHALL permitir `/onboard --level N`: valida que el Nivel N-1 esté completo en `onboard-progress.yaml` e inicia
el Nivel N sin repetir los anteriores; si no, redirige al nivel pendiente.

#### Scenario: Retoma desde nivel específico
- **Given** `onboard-progress.yaml` indica Nivel 2 completo
- **When** `/onboard --level 3`
- **Then** valida que el Nivel 2 está completo e inicia el Nivel 3 directamente

### Requirement: Sub-comandos `doctor`/`status`/`hint`
SHALL exponer `/onboard doctor` (diagnóstico `[OK]/[WARN]/[ERROR]` de `.king/`, hooks, plugin, memory backend —
contrato alineado con `cli-architecture.md`), `/onboard status` (fase SDD, skills, gates, último commit) y
`/onboard hint` (próximo comando según el nivel actual).

#### Scenario: doctor detecta setup incompleto
- **Given** `.king/` existe pero `hooks.json` sin matcher `coverage-emit`
- **When** `/onboard doctor`
- **Then** muestra `[ERROR] hooks.json: matcher coverage-emit ausente` y el comando para corregirlo

#### Scenario: hint sugiere próximo paso
- **Given** `onboard-progress.yaml` indica Nivel 2 completado
- **When** `/onboard hint`
- **Then** muestra el comando del Nivel 3 listo para copiar

### Requirement: Quickstart por persona
SHALL ofrecer rutas por persona: Developer (Nivel 1→2→3), Entrepreneur (`/genesis --mode entrepreneur` →
`/mvp-accelerator`), Migración (`/genesis --mode migrate --from cursor`).

#### Scenario: Quickstart por persona Developer
- **Given** el developer indica persona "developer"
- **Then** propone Nivel 1 → Nivel 2 → Nivel 3 y salta contenido de entrepreneur

> Set Gherkin completo: M12 §7 (Feature: Onboarding TUI 5 Niveles — 6 escenarios).
> Complementariedad: `onboard` (adopción) deriva a `king-onboard` (SDLC profundo) al completar el Nivel 5.
