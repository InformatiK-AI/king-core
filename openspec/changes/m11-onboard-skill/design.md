# Design — M-11 Onboarding TUI (skill `onboard`)

> Fase: sdd-design · Fuente de verdad: `mejora/planes-detallados/M12-developer-experience-tooling.md` §2 M-11, §6 T01-T15, §7.

## Decisión arquitectónica

`onboard` es un skill nativo ejecutable (markdown) que renderiza una "TUI Bubbletea-style" como instrucciones
visuales para Claude Code (barra de progreso ASCII, validación `✓`/`✗`). NO es código TUI real; el LLM renderiza
el formato. Distinto y complementario de `king-onboard`.

## T01 — Reuso vs nuevo (king-onboard)

| Aspecto | king-onboard | onboard (nuevo) |
|---------|--------------|-----------------|
| Propósito | SDLC walkthrough profundo | adopción inicial |
| Estructura | 9 fases, un cambio real | 5 niveles discretos validados |
| Output | aprendizaje + cambio real | progreso en `onboard-progress.yaml` |
| Reusa | — | estilo: narración corta, adaptativo, enseñar haciendo |
| Añade | — | niveles validados, doctor/status/hint, persistencia, --level |

`onboard` deriva a `king-onboard` al cerrar el Nivel 5.

## Anatomía (v2.0, ref `clean-arch-setup`)
Frontmatter (`name`/`version: 2.0`/`api_version: 1.0.0`/`description` con frases gatillo) → Knowledge Injection
con graceful degradation → QUICK REFERENCE (BLOCKING / RESTRICTIONS / REQUIRED OUTPUTS) → fases (los 5 niveles) →
sub-comandos → FINAL CHECKPOINT → Acceptance Criteria.

## Dependencia C1
`doctor`/`status` referencian el contrato de `knowledge/universal/cli-architecture.md` (C1, ya en develop) para
paridad con `king-framework doctor`/`status`. Por eso C2 va DESPUÉS del merge de C1.

## Mapeo tareas → sección
T01 (reuso)→encabezado; T02-T07 (5 niveles)→Los 5 Niveles; T08-T10 (doctor/status/hint)→Sub-comandos;
T11 (persona)→Quickstart; T12 (TUI + progress.yaml)→Formato TUI; T13 (retoma)→Retoma. T14/T15 diferidos.

## Decisiones específicas
1. **Validación dura por nivel**: nunca avanzar/marcar completo con `✗` (evita progreso inválido — riesgo R04 del doc).
2. **No ejecutar el comando por el usuario**: se presenta para copy-paste y se valida el resultado (es un tutorial).
3. **Persistencia en `.king/onboard-progress.yaml`**: habilita retoma y que `doctor` detecte niveles incompletos.
