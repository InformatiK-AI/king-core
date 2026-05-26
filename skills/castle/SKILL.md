---
name: castle
description: "Evaluación de calidad CASTLE (Contracts, Architecture, Security, Testing, Logging, Environment). Usar para auditorías de calidad, pre-merge, pre-release, o cuando se necesite evaluar el estado del proyecto."
version: "2.0"
---

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/conventions.md` | Project conventions for Architecture and Contracts evaluation | Yes | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se especificó contexto ni capa a evaluar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA emitir veredicto FORTIFIED si alguna capa activa está en FAIL
- NUNCA omitir capas activas según el contexto del skill invocador
- NUNCA proceder con una operación si el veredicto es BREACHED
- NUNCA evaluar capas que no están activas para el contexto actual

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] CASTLE Assessment Report con veredicto (FORTIFIED | CONDITIONAL | BREACHED)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW

```
Phase 0: Load Context
Phase 1: Determine Scope   → activar capas según contexto
Phase 2: Execute Checks    → evaluar cada capa activa
Phase 3: Calculate Verdict → FORTIFIED | CONDITIONAL | BREACHED
Phase 4: Generate Report   → formatear y presentar reporte
FINAL CHECKPOINT
Execution Summary
Phase N+1: Write Session
Phase N+2: Guide Next Step
```

---

## CASTLE Layers

```
C - Contracts      → Contratos de API, schemas, interfaces
A - Architecture   → Estructura, patrones, dependency direction
S - Security       → Vulnerabilidades, secrets, OWASP Top 10
T - Testing        → Cobertura, calidad de tests, ACs
L - Logging        → Logs estructurados, error handling, health
E - Environment    → Ambientes, deploy, smoke tests, rollback
```

## Capas Activas por Skill (fuente autoritativa: `skills/_shared/castle-capas.md`)

| Skill | C | A | S | T | L | E | Gate mínimo |
|-------|---|---|---|---|---|---|-------------|
| `build` | ✓ | ✓ | - | ✓ | ✓ | - | CONDITIONAL |
| `qa` | ✓ | ✓ | ✓ | ✓ | ✓ | - | CONDITIONAL |
| `review` | ✓ | ✓ | ✓ | ✓ | - | - | CONDITIONAL |
| `release` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | FORTIFIED |
| `refactor` | - | ✓ | - | ✓ | - | - | CONDITIONAL |
| `optimize` | - | ✓ | - | ✓ | ✓ | - | CONDITIONAL |
| `merge` | - | ✓ | - | ✓ | - | - | CONDITIONAL |
| `fix` | - | ✓ | ✓ | ✓ | - | - | CONDITIONAL |
| `plan` | ✓ | ✓ | ✓ | - | - | - | CONDITIONAL |
| `create-issues` | ✓ | ✓ | - | - | - | - | CONDITIONAL |
| `frontend-design` | - | ✓ | - | ✓ | - | - | CONDITIONAL |
| `test-plan` | ✓ | ✓ | ✓ | ✓ | - | - | CONDITIONAL |
| `promote` | - | - | ✓ | - | - | ✓ | CONDITIONAL |
| `/castle` (standalone) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | FORTIFIED |

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` Phase 0

---

## Phase 1: Determine Scope

### GATE IN
- [ ] Fase 0 completada
- [ ] Contexto identificado (skill invocador o `--context` explícito)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Identificar contexto** — Determinar qué skill invoca CASTLE (o `--context` explícito como `release`, `layer S`, etc.)
2. [ ] **Activar capas** — Consultar tabla de capas activas y marcar las correspondientes al contexto
3. [ ] **Cargar checks** — Para cada capa activa, identificar el archivo de checks en `references/[capa]-checks.md`

### CHECKPOINT
- [ ] Capas activas identificadas y documentadas
- [ ] Archivos de checks localizados para cada capa activa

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Contexto no mapeado en la tabla de capas
Cause: Skill invocador no está en la tabla o `--context` es inválido
Recovery:
  [ ] Option A: Usar la fila por defecto (`/castle` standalone) — 6 capas completas
  [ ] Option B: Preguntar al usuario qué capas activar explícitamente
  [ ] Option C: Consultar `skills/_shared/castle-capas.md` para la definición actualizada

---

## Phase 2: Execute Checks

### GATE IN
- [ ] Phase 1 completada — capas activas identificadas

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Por cada capa activa**, leer `references/[capa]-checks.md` y ejecutar sus checks
2. [ ] **Registrar resultado** de cada check: PASS | WARNING | FAIL
3. [ ] **Calcular estado de capa**:
   - PASS: Todos los checks son PASS
   - WARNING: Al menos un WARNING, ningún FAIL
   - FAIL: Al menos un FAIL

   > **Resolución de paths**: Los paths `references/` son **plugin-relative** — se resuelven desde `skills/castle/`.

### CHECKPOINT
- [ ] Todos los checks de todas las capas activas ejecutados
- [ ] Estado por capa calculado (PASS | WARNING | FAIL)
- [ ] Evidencia de cada check documentada

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Check no ejecutable (archivo faltante o herramienta no disponible)
Cause: Archivo `references/[capa]-checks.md` no encontrado o tool no disponible
Recovery:
  [ ] Option A: Marcar esa capa como WARNING con nota de "check no ejecutado"
  [ ] Option B: Ejecutar checks manualmente basándose en el conocimiento del protocolo
  [ ] Option C: Escalar al usuario si la capa es crítica (S o E para prod)

---

## Phase 3: Calculate Verdict

### GATE IN
- [ ] Phase 2 completada — todos los checks ejecutados

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Agregar resultados** — Combinar estados de todas las capas activas
2. [ ] **Determinar veredicto global**:

   | Veredicto | Condición | Acción |
   |-----------|-----------|--------|
   | FORTIFIED | Todas las capas activas en PASS | Proceder sin restricciones |
   | CONDITIONAL | Solo WARNING, ningún FAIL | Proceder con observaciones documentadas |
   | BREACHED | Al menos un FAIL en alguna capa | BLOQUEAR — no proceder hasta resolver |

3. [ ] **Verificar gate mínimo** — Comparar veredicto con gate mínimo requerido por el skill invocador

### CHECKPOINT
- [ ] Veredicto global calculado (FORTIFIED | CONDITIONAL | BREACHED)
- [ ] Gate mínimo verificado
- [ ] Si BREACHED: finding documentado con capa y check específico

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Veredicto BREACHED — gate no supera el mínimo requerido
Cause: Al menos un FAIL en una capa activa
Recovery:
  [ ] Option A: Presentar el finding al usuario y bloquear la operación hasta resolución
  [ ] Option B: Si es CONDITIONAL pero el contexto requiere FORTIFIED — pedir resolución de WARNINGs
  [ ] Option C: Escalar a @security (capa S) o @architect (capa A) según la capa con FAIL

---

## Phase 4: Generate Report

### GATE IN
- [ ] Phase 3 completada — veredicto calculado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Generar reporte** — Formatear CASTLE Assessment Report con el template estándar
2. [ ] **Presentar al usuario** — Mostrar reporte completo con veredicto y findings

   ```
   ╔══════════════════════════════════════════╗
   ║           CASTLE Assessment              ║
   ╠══════════════════════════════════════════╣
   ║                                          ║
   ║  C  Contracts     [PASS|WARN|FAIL|----]  ║
   ║  A  Architecture  [PASS|WARN|FAIL|----]  ║
   ║  S  Security      [PASS|WARN|FAIL|----]  ║
   ║  T  Testing       [PASS|WARN|FAIL|----]  ║
   ║  L  Logging       [PASS|WARN|FAIL|----]  ║
   ║  E  Environment   [PASS|WARN|FAIL|----]  ║
   ║                                          ║
   ║  Veredicto: [FORTIFIED|CONDITIONAL|BREACHED]
   ║                                          ║
   ╚══════════════════════════════════════════╝
   ```
   > `----` indica capa no evaluada (no activa para este contexto).

### CHECKPOINT
- [ ] Reporte generado con todas las capas activas
- [ ] Veredicto visible y prominente
- [ ] Findings de FAIL/WARNING documentados con acción recomendada

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Reporte incompleto
Cause: Falta estado de alguna capa activa
Recovery:
  [ ] Option A: Completar el reporte con el estado de la capa faltante (ejecutar Phase 2 solo para esa capa)
  [ ] Option B: Marcar la capa como WARNING con nota de "evaluación pendiente"

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen (reporte con veredicto generado)
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Sesión registrada

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(el veredicto del assessment ejecutado)_ |
| Artifacts | _(CASTLE Assessment Report, capas evaluadas)_ |
| Next Recommended | _(ver Guide Next Step según veredicto)_ |
| Risks | _(findings FAIL/WARNING pendientes de resolución)_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` Phase N+1

---

## Phase N+2: Guide Next Step

| Condición | Próximo Skill |
|-----------|---------------|
| Veredicto FORTIFIED | Proceder con la operación que invocó CASTLE |
| Veredicto CONDITIONAL | Proceder con observaciones documentadas en Execution Summary |
| Veredicto BREACHED (capa S) | Resolver con @security antes de continuar |
| Veredicto BREACHED (capa A) | Resolver con @architect antes de continuar |
| Veredicto BREACHED (otras capas) | Resolver findings específicos y re-ejecutar `/castle` |

---

## REFERENCE

### Integración en el Pipeline

1. **Pre-merge**: Antes de merge a develop (capas según skill)
2. **Pre-promote**: Antes de promover a QA/prod (S + E mínimo)
3. **Pre-release**: Antes de release (6 capas completas, FORTIFIED requerido)
4. **Post-review**: Después de code review (capas del reviewer)
5. **On-demand**: Cuando el usuario ejecuta `/castle`

### Checks por Capa (plugin-relative)

| Capa | Archivo |
|------|---------|
| C — Contracts | `references/contracts-checks.md` |
| A — Architecture | `references/architecture-checks.md` |
| S — Security | `references/security-checks.md` |
| T — Testing | `references/testing-checks.md` |
| L — Logging | `references/logging-checks.md` |
| E — Environment | `references/environment-checks.md` |

> **Session tracking**: Skill standalone. Ver convención en `skills/_shared/standalone-convention.md`.
