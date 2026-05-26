---
name: refactor
description: "Workflow de refactoring guiado. Usar cuando se necesite: refactorizar código, limpiar código, extraer componentes, reorganizar funciones, mejorar estructura del código, o reducir deuda técnica."
version: 2.0
---

# Refactor — Refactoring Guiado

Workflow para refactorizar código de forma segura, preservando comportamiento.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural patterns to preserve during refactor | Yes | project |
| `.king/knowledge/conventions.md` | Code conventions to maintain after refactoring | Yes | project |
| `.king/knowledge/stack.md` | Stack-specific idioms to follow in refactored code | Yes | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No hay tests que verifiquen el comportamiento actual (riesgo de regresión)
- [ ] El scope del refactor no está definido

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA cambiar comportamiento observable durante un refactor (solo estructura interna)
- NUNCA iniciar si los tests no están en verde antes de comenzar
- NUNCA combinar refactor y nueva funcionalidad en el mismo commit

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Código refactorizado con comportamiento preservado
- [ ] Tests actualizados (o nuevos si no existían)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7
Load      Identify   Plan      Execute   Verify    Review    Session   Guide
```

---


## Agentes involucrados
- **@architect** → Valida mejora arquitectónica
- **@developer** → Implementa cambios
- **@qa** → Verifica no regresiones

## CASTLE: _·A·_·T·_·_ — [ver capas en `skills/_shared/castle-capas.md`]

## Principios de refactoring en King

### Constraints del proyecto
- Respetar la arquitectura actual del proyecto durante el refactor
- Respetar el estilo y patrones del proyecto (ver CLAUDE.md)

### Refactorings válidos
- Extraer funciones largas en helpers más pequeños
- Mejorar nombres de variables/funciones
- Reducir duplicación dentro de una sección
- Reorganizar código dentro de su sección correcta
- Simplificar lógica condicional compleja
- Mejorar manejo de errores
- Extraer módulos/componentes a archivos separados (con ADR)
- Crear archivos CSS, componentes modulares y utilidades

### Refactorings NO válidos (sin ADR)
- Cambiar estructuras core del proyecto sin ADR

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### Fase 1: Identify

#### GATE IN
- [ ] Fase 0 completada — contexto de sesión cargado y scope del refactor descrito

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] ¿Qué se va a refactorizar y por qué?
2. [ ] ¿Cuál es el code smell o problema?
3. [ ] ¿Qué beneficio concreto se obtiene?
4. [ ] ¿El refactoring respeta las constraints del proyecto?

#### CHECKPOINT
- [ ] Code smell identificado — target, motivación y beneficio concreto documentados

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Refactor scope not clearly defined — code smell or target not identified
Cause: The requested refactoring is too vague, or the benefit cannot be quantified enough to justify the risk.
Recovery:
  [ ] Option A: Ask user to point to the specific file/function that is the refactoring target — then identify the smell category (long function, duplication, poor naming, etc.)
  [ ] Option B: If the motivation is "it feels messy," apply RADAR analysis: document the concrete problem (e.g., function has 80 lines and 4 responsibilities) before proceeding
  [ ] Option C: If scope cannot be defined after clarification, recommend `/audit` to identify refactoring candidates systematically, then return to `/refactor` with a specific target

### Fase 2: Plan (via @architect)

#### GATE IN
- [ ] Code smell y scope del refactor identificados en Fase 1

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Estrategia de refactoring:
   - **Incremental** (preferido): Cambios pequeños, uno a uno, verificados
   - **Big-bang** (evitar): Solo si incremental es imposible
2. [ ] Definir pasos concretos
3. [ ] Identificar riesgos
4. [ ] Definir criterio de éxito

#### CHECKPOINT
- [ ] Plan de refactoring aprobado por @architect — pasos, riesgos y criterio de éxito definidos

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Refactoring plan rejected by @architect — approach does not improve architecture
Cause: Proposed refactoring introduces new coupling, violates dependency direction, or the risk outweighs the benefit.
Recovery:
  [ ] Option A: Review @architect feedback specifically — revise the plan to address each objection and re-present with the changes highlighted
  [ ] Option B: If the big-bang approach was rejected, propose an incremental alternative with smaller steps and re-submit for approval
  [ ] Option C: If plan cannot be approved after 2 revisions, escalate to user — present both the original approach and @architect's concerns for a final decision

### Fase 3: Execute (via @developer)

#### GATE IN
- [ ] Plan de refactoring aprobado por @architect en Fase 2

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Para CADA paso del refactoring:
   a. Hacer el cambio mínimo
   b. Verificar sintaxis:
      ```bash
      [comando de verificación del proyecto - ver CLAUDE.md]
      ```
   c. Verificar que el comportamiento no cambió
   d. Commit incremental:
      ```
      refactor(scope): descripción del paso
      ```
2. [ ] Nunca cambiar comportamiento durante refactoring
3. [ ] Si se necesita cambiar comportamiento → es una feature o fix, no refactor

#### CHECKPOINT
- [ ] Todos los pasos del plan ejecutados con commits incrementales — comportamiento no modificado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Refactoring execution incomplete — not all plan steps committed
Cause: A refactoring step introduced a syntax error, broke a test, or inadvertently changed behavior, halting incremental progress.
Recovery:
  [ ] Option A: Identify which step failed — `git log --oneline` to see committed steps vs planned steps; fix the failing step in isolation before committing
  [ ] Option B: If behavior was accidentally changed during a step, revert that specific commit (`git revert HEAD`) and redo the step more carefully
  [ ] Option C: If the plan step is genuinely impossible to execute without changing behavior, stop — document the blocker in the session report and ask user whether to skip that step or convert it to a separate `/fix` or feature task

### Fase 4: Verify (via @qa)

#### GATE IN
- [ ] Ejecución completada en Fase 3 — todos los pasos del plan aplicados

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar que todos los tests pasan
2. [ ] Verificar que el build funciona
3. [ ] Si toca pipeline: verificar con test projects
4. [ ] Verificar que i18n sigue funcionando (si el proyecto lo usa)
5. [ ] Smoke test visual para confirmar que la UI no se degradó:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Smoke-Test
   Si se omite, documentar motivo en reporte de sesión.
   ---

#### CHECKPOINT
- [ ] Todos los tests pasan y build funciona — comportamiento preservado verificado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Tests fail or build broken after refactoring — behavior not preserved
Cause: Refactoring step changed an interface, renamed a symbol used elsewhere, or introduced a structural change that broke dependent code.
Recovery:
  [ ] Option A: Run the failing test(s) individually to isolate the failure — identify which refactoring step caused it using `git bisect` or by reverting commits one at a time
  [ ] Option B: Fix the broken dependency (update call sites, fix import paths) without changing logic — this is still within refactoring scope
  [ ] Option C: If tests cannot be made to pass without changing behavior, STOP — this refactoring has become a feature/fix; document the blocker and ask user how to proceed

### Fase 5: Review (via @architect)

#### GATE IN
- [ ] Verificación de Fase 4 completada — tests pasando y comportamiento preservado

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] ¿El refactoring mejoró la arquitectura?
2. [ ] ¿Se respetaron las constraints?
3. [ ] ¿El coupling disminuyó o se mantuvo?
4. [ ] ¿La legibilidad mejoró?

#### CHECKPOINT
- [ ] Review arquitectónico completado — mejora confirmada y constraints respetadas

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Architectural review failed — refactoring did not improve or worsened architecture
Cause: The refactoring introduced new coupling, violated constraints, or the legibility improvement was not achieved.
Recovery:
  [ ] Option A: Review @architect findings specifically — if coupling increased, extract the problematic dependency and separate it with an interface or utility
  [ ] Option B: If constraints were violated (e.g., a module was moved to the wrong layer), move it back and propose an ADR for the desired structural change instead
  [ ] Option C: If the improvement cannot be confirmed after 2 revision rounds, document the architectural findings and proceed to Report with Status: CONDITIONAL — do not revert already-committed improvements

### Report
```
## Refactor Report

### Target: [qué se refactorizó]
### Motivación: [por qué]

### Cambios
| Paso | Descripción | Verificación |
|------|-------------|-------------|
| 1 | ... | OK |
| 2 | ... | OK |

### Métricas
- Líneas antes: [N]
- Líneas después: [N]
- Funciones extraídas: [N]
- Duplicación eliminada: [descripción]

### Comportamiento: [PRESERVADO|MODIFICADO]

### Evidencia Visual
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### CASTLE Score: [A + T]
```

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
| Next Recommended | _(copiar de tabla de flujo)_ |
| Risks | _(listar findings CONDITIONAL o BREACHED, o "None")_ |

### Fase 6: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 7: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para refactor:
| Condición | Próximo Skill |
|-----------|---------------|
| Siempre (refactor completo) | `/review` |

---

## REFERENCE

> 📚 Información adicional. Esta sección NO contiene acciones, solo contexto.

### Integración SDD
Este skill puede ejecutarse como parte del pipeline SDD durante la fase `verify`.
Ver `rules.verify.quality_skills` en `.king/sdd/config.yaml`.
Cuando se invoca desde SDD, el scope se limita a los archivos del cambio activo.

### Boundary con /optimize
- `/refactor` = mejoras estructurales (extract, rename, reorganize, simplify logic)
- `/optimize` = mejoras de complejidad algorítmica y design patterns
- Son complementarios: `/refactor` → `/optimize` → `/review`
