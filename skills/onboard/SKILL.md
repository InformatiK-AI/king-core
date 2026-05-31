---
name: onboard
version: 2.0
api_version: 1.0.0
description: "Tutorial de adopción gamificado de King Framework en 5 niveles con validación de éxito por nivel, barra de progreso ASCII y persistencia en .king/onboard-progress.yaml. Incluye sub-comandos doctor (diagnóstico de setup), status (estado actual) y hint (próximo paso). Usar cuando se necesite: empezar con King, onboarding inicial, aprender los comandos básicos, primer contacto con el framework, tutorial paso a paso, /onboard, quickstart por persona (developer/entrepreneur/migración). TTFC objetivo < 5 minutos. Para el SDLC completo con un cambio real, ver king-onboard."
model: haiku
---

# /onboard — Tutorial de Adopción en 5 Niveles

Punto de entrada para developers nuevos en King. Guía la adopción con 5 niveles, cada uno con UN comando
copy-pasteable y un criterio de éxito verificable. El objetivo es TTFC (Time To First Command) < 5 minutos.
NO implementa una feature grande ni es el SDLC completo — para eso está `king-onboard` (referenciado en el Nivel 5).
Persiste el progreso en `.king/onboard-progress.yaml` y permite retomar desde cualquier nivel.

**Relación con `king-onboard`** (T01): `onboard` (este skill) = adopción inicial, 5 niveles discretos con
validación de éxito y progreso persistente. `king-onboard` = walkthrough profundo del SDLC (9 fases, un cambio
real). Son complementarios: `onboard` reusa de `king-onboard` el estilo (narración corta, adaptativo por
experiencia, enseñar haciendo) pero añade niveles validados, sub-comandos `doctor/status/hint` y persistencia.
`onboard` es el punto de entrada; deriva a `king-onboard` al completar el Nivel 5.

## Knowledge Injection

Read BEFORE Phase 1. **Graceful degradation**: si un archivo no existe, log a warning and continue.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/universal/cli-architecture.md` | Contrato de `doctor`/`status` (qué checks/datos) — paridad con el CLI king-framework | No | framework |
| `.king/onboard-progress.yaml` | Progreso del onboarding (nivel actual, niveles completados) | No | project |
| `.king/sessions/` | Fase SDD activa y último commit (para `status`/`hint`) | No | project |
| `.king/knowledge/stack.md` | Stack detectado (adapta los ejemplos de cada nivel) | No | project |

---

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Sin condiciones bloqueantes — el onboarding funciona en cualquier proyecto, incluso vacío.
> (Si `--level N` se pide sin que el nivel previo esté completo, NO bloquear: validar y, si falta, redirigir al nivel pendiente.)

### ABSOLUTE RESTRICTIONS
> 🚫 Sin excepciones

- NUNCA avanzar de nivel sin validar el criterio de éxito del nivel actual (`✓`/`✗` explícito).
- NUNCA ejecutar el comando del nivel POR el usuario sin que lo pida — se le presenta para copy-paste y se valida el resultado.
- NUNCA marcar un nivel completo en `onboard-progress.yaml` si el criterio de éxito dio `✗`.
- NUNCA lectear: narración de 1-3 oraciones por nivel (regla heredada de king-onboard).

### REQUIRED OUTPUTS
> 📦 Generados durante el flujo

- [ ] `.king/onboard-progress.yaml` creado/actualizado con el nivel completado.
- [ ] Para cada nivel: barra de progreso ASCII + objetivo (1 línea) + comando único + validación `✓`/`✗`.
- [ ] Al completar Nivel 5: derivación a `king-onboard` para el SDLC profundo.

---

## Formato TUI (T12)

Cada nivel se renderiza así (instrucciones visuales para Claude Code — "Bubbletea-style"):

```
[■■■□□] Nivel 3/5 — Primer Gate
Objetivo: obtener tu primer reporte CASTLE con score numérico.
Comando:  /qa
```
Tras ejecutar, validar y mostrar `✓ Nivel 3 completo` o `✗ <qué faltó>` + hint.

### Formato de `.king/onboard-progress.yaml`
```yaml
persona: developer        # developer | entrepreneur | migrate
current_level: 3
completed_levels: [1, 2]
started: "2026-05-28"
last_command: "/qa"
ttfc_seconds: 142         # tiempo hasta completar Nivel 1
```

## Los 5 Niveles

> Los 5 niveles usan UN ejemplo guía consistente ("health check") de punta a punta, para que el developer siga
> un hilo único. Si el developer prefiere su propia idea, se sustituye el ejemplo manteniendo el criterio de éxito.

### PHASE / Nivel 1 — Hola, King
- **Objetivo**: generar la base King en un repo.
- **Comando**: `/genesis` (en repo vacío)
- **Criterio de éxito**: `.king/` generado con el stack detectado. ✗ si no existe `.king/`.

### PHASE / Nivel 2 — Tu primer feature
- **Objetivo**: explorar opciones de diseño de una mejora.
- **Comando**: `/brainstorm "agregar health check"`
- **Criterio de éxito**: proposal generado con 3+ opciones. ✗ si < 3 opciones.

### PHASE / Nivel 3 — Primer Gate
- **Objetivo**: tu primer reporte de calidad.
- **Comando**: `/qa`
- **Criterio de éxito**: CASTLE report con score numérico. ✗ si no hay score.

### PHASE / Nivel 4 — Pipeline SDD
- **Objetivo**: pasar de idea a SPEC + TASKS.
- **Comando**: `/sdd-new "health check endpoint"` (revisar el proposal) → luego `/sdd-ff` (secuencial).
- **Criterio de éxito**: SPEC + TASKS generados. ✗ si falta alguno.

### PHASE / Nivel 5 — Production Ready
- **Objetivo**: promover con todos los gates verdes.
- **Comando**: `/promote --env staging`
- **Criterio de éxito**: todos los gates verdes. ✗ si algún gate falla.
- **Cierre**: derivar a `king-onboard` para el SDLC completo con un cambio real.

## Retoma (T13)
`/onboard --level N`: valida que el Nivel N-1 esté efectivamente completo en `onboard-progress.yaml`; si lo está,
inicia el Nivel N sin repetir los anteriores; si NO, redirige al nivel pendiente más bajo.

## Sub-comandos (T08-T10)

### `/onboard doctor` (T08) — diagnóstico de setup
Verifica e imprime `[OK]/[WARN]/[ERROR]` por item (contrato alineado con `king-framework doctor`, ver
`cli-architecture.md`):
- `.king/` existe.
- `hooks.json` tiene los matchers críticos (p.ej. `coverage-emit`). Si falta → `[ERROR]` + comando para corregirlo.
- el agente detectado tiene el plugin activo.
- Engram o Chronicle configurados.

### `/onboard status` (T09)
Muestra fase SDD activa (desde `.king/sessions/`), skills disponibles, gates configurados y último commit auditado.

### `/onboard hint` (T10)
Analiza el nivel actual (desde `onboard-progress.yaml` + estado de `.king/`) y sugiere el próximo comando listo
para copiar.

## Quickstart por persona (T11)
```
Developer     → Nivel 1 → Nivel 2 → Nivel 3   (salta contenido de entrepreneur)
Entrepreneur  → /genesis --mode entrepreneur → /mvp-accelerator
Migración     → /genesis --mode migrate --from cursor
```

## FINAL CHECKPOINT
- [ ] Nivel actual validado con criterio de éxito (`✓`).
- [ ] `onboard-progress.yaml` refleja el último nivel completado.
- [ ] Si Nivel 5 completo → derivación a `king-onboard` mostrada.

## Testing (T14, T15) — diferido
- T14: script de integración que ejecuta los 5 niveles en repo vacío y verifica criterios (suite del framework).
- T15: medición de TTFC con tester externo (manual, no automatizable). Objetivo < 5 min.

## Acceptance Criteria
Set Gherkin completo: `mejora/planes-detallados/M12-developer-experience-tooling.md §7` (Feature: Onboarding TUI
5 Niveles). Mapeo escenario → sección:

| Escenario §7 | Sección |
|--------------|---------|
| TTFC menor a 5 minutos | Formato TUI + Nivel 1 |
| Progresión por los 5 niveles | Los 5 Niveles + onboard-progress.yaml |
| Retoma desde nivel específico | Retoma (`--level N`) |
| doctor detecta setup incompleto | `/onboard doctor` |
| Quickstart por persona Developer | Quickstart por persona |
| hint sugiere próximo paso | `/onboard hint` |
