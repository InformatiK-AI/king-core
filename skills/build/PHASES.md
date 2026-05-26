# Build Feature — Phases (v2.0)

> Lógica detallada de las fases 1-9. Entry point: [SKILL.md](SKILL.md)

---

## Fase 1: Setup

### GATE IN
- [ ] Fase 0 completada — workflow context cargado desde `.king/workflows/`

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar que estamos en un repositorio git
2. [ ] Crear branch `feature/[nombre]` desde develop (si no existe)
3. [ ] Opcionalmente configurar worktree para aislamiento

### CHECKPOINT
- [ ] Branch git configurado o no requerido

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Git branch creation or checkout failed
Cause: Repository not initialized, uncommitted changes on current branch, or branch name conflict.
Recovery:
  [ ] Option A: Run `git status` and `git diff --stat` — stash or commit pending changes, then retry branch creation
  [ ] Option B: Check if branch already exists (`git branch -a`) and checkout if it does: `git checkout feature/[nombre]`
  [ ] Option C: If no git repo exists, run `git init` then retry; if still blocked, ask user to resolve manually

---

## Fase 2: Discovery

### GATE IN
- [ ] Plan del workflow context disponible en `.king/workflows/`

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Cargar plan del workflow context**:
   - Leer la tabla "Artefactos Producidos" del workflow `context.md` (cargado en Phase 0.4)
   - Buscar artefacto de tipo "Plan" con referencia a un path en `docs/plans/`
   - Si se encuentra: leer el archivo del plan y usarlo como **contexto primario** de la implementación
   - Si NO se encuentra: **DETENER** — informar al usuario que debe ejecutar `/plan` primero (blocking condition)
2. [ ] Detectar tipo de input:
   - **Si es `#N`** (número de issue GitHub): obtener issue con `gh issue view N --json title,body,labels`
     - Parsear body para extraer: escenarios Gherkin, DoD, archivos afectados, notas de implementación
     - Usar escenarios Gherkin como spec de implementación
     - Usar archivos afectados como punto de partida para el análisis
     - **Cruzar con plan**: Verificar que el issue corresponde a una tarea del plan cargado
   - **Si es `STORY-NNN`** (issue local): leer `.king/issues/STORY-NNN.md`
     - Parsear Markdown para extraer las mismas secciones: Gherkin, DoD, ACs, archivos afectados, notas
     - Usar escenarios Gherkin como spec de implementación
     - Usar archivos afectados como punto de partida para el análisis
     - Actualizar Status del STORY a `in-progress` en el archivo y en `INDEX.md`
     - **Cruzar con plan**: Verificar que el STORY corresponde a una tarea del plan cargado
3. [ ] Identificar archivos que serán afectados
4. [ ] Leer los archivos relevantes para entender el contexto actual
5. [ ] Identificar dependencias y posibles conflictos
6. [ ] Revisar knowledge base del framework si aplica
7. [ ] **Detectar contexto SaaS multi-tenant** — Si CUALQUIERA de estas condiciones es verdadera:
   - `.king/knowledge/stack.md` contiene "multi-tenant", "SaaS" o "tenant_id"
   - El issue/plan menciona explícitamente "multi-tenancy", "RLS", "ABAC" o "tenant isolation"
   - Migration files, schema definitions o model files del proyecto contienen columna `tenant_id`

   → Leer `knowledge/_inject/multi-tenancy.md` e inyectar los patrones RLS/ABAC/middleware en el contexto de implementación de Fase 4. Garantiza que el código generado sea fail-safe por defecto (queries sin tenant_id son imposibles).

8. [ ] **Evaluar complejidad del plan para escalar a SDD** (DESPUÉS de cargar el plan, ANTES de continuar a Fase 3):

   Contar señales de complejidad en el plan cargado:
   - **Volume**: el plan tiene ≥ 8 tareas definidas
   - **Cross-cutting**: el plan afecta ≥ 5 archivos en ≥ 3 módulos distintos
   - **No-SDD**: no existe `.king/sdd/` para este cambio Y el plan tiene ≥ 2 de las señales anteriores
   - **Estimación XL**: el plan contiene estimación XL (si fue generado con `/plan`)

   **Si ≥ 2 señales son verdaderas** → mostrar al usuario:

   ```
   ⚠️  Plan de alta complejidad detectado: {señales}

   Este plan puede superar el scope de un build estándar de una sesión.
   SDD (Spec-Driven Development) ofrece trazabilidad, PR budget guards
   y recovery automático post-compactación para cambios de este tamaño.

   ¿Cómo querés continuar?
   A) Continuar con /build estándar
   B) Escalar a /sdd-new <nombre-del-cambio> (recomendado)
   ```

   - Si el usuario elige **B** → terminar /build y sugerir: `Ejecutá /sdd-new <nombre> con el plan en docs/plans/ como contexto.`
   - Si el usuario elige **A** o hay < 2 señales → continuar a Fase 3 normalmente

### CHECKPOINT
- [ ] Discovery completo — archivos afectados identificados y plan cargado
- [ ] Complexity check ejecutado — decisión de continuar /build o escalar a SDD tomada

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Plan artifact not found in workflow context
Cause: No prior `/plan` session was registered in the workflow context, or the plan file path recorded in context.md does not exist on disk.
Recovery:
  [ ] Option A: Open `.king/workflows/context.md` and check the "Artefactos Producidos" table for a "Plan" entry — verify the path exists
  [ ] Option B: If the plan file is missing, run `/plan` first to generate it, then re-run `/build`
  [ ] Option C: If the plan exists at a different path, update context.md with the correct path and retry

---

## Fase 3: Architecture (via @architect)

### GATE IN
- [ ] Discovery completo — archivos afectados identificados

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Evaluar impacto en la arquitectura existente
2. [ ] Verificar que no viola dependency direction
3. [ ] Proponer diseño con trade-offs (protocolo RADAR)
4. [ ] Identificar archivos y módulos que se modificarán
5. [ ] Si el cambio es arquitectónico, crear ADR

### CHECKPOINT
- [ ] Diseño arquitectónico aprobado por @architect

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Architectural design rejected or not approved by @architect
Cause: Proposed design violates dependency direction, introduces unacceptable coupling, or conflicts with existing ADRs.
Recovery:
  [ ] Option A: Review @architect feedback, revise the design addressing each objection, and re-present for approval
  [ ] Option B: If conflict is with an existing ADR, create a new ADR proposing the amendment and get it approved before proceeding
  [ ] Option C: Escalate to user if @architect and implementation requirements are irreconcilable — do not proceed without approval

---

## Fase 4: Implementation (via @developer o @frontend)

### GATE IN
- [ ] Diseño arquitectónico aprobado por @architect

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Implementar siguiendo las convenciones del proyecto:
   - Seguir las convenciones del stack del proyecto (ver CLAUDE.md)
   - En nuevos componentes: seguir las convenciones del stack definidas en CLAUDE.md
   - Seguir naming conventions del proyecto
2. [ ] Mantener i18n consistente si el proyecto lo usa
3. [ ] Hacer commits incrementales con conventional commits:
   ```
   feat(scope): descripción clara del cambio
   ```
4. [ ] Verificar sintaxis después de cada cambio significativo:
   ```bash
   # [comando de verificación del proyecto - ver CLAUDE.md]
   ```
5. [ ] Si viene de issue `#N` (GitHub), agregar comment de progreso:
   ```bash
   gh issue comment N --body "Implementación en progreso en branch feature/[nombre]"
   ```
6. [ ] Si viene de issue `STORY-NNN` (local), ya se actualizó Status a `in-progress` en Fase 2

### CHECKPOINT
- [ ] Implementación completada — commits incrementales realizados con conventional commits

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Implementation not committed — expected code artifacts absent
Cause: Write operation failed silently, implementation was incomplete, or commits were not made with conventional commit format.
Recovery:
  [ ] Option A: Run `git status` to confirm which files are modified but not staged — stage and commit each logical unit
  [ ] Option B: If syntax errors are blocking commits, fix them first (`[verification command from CLAUDE.md]`), then commit
  [ ] Option C: If implementation is genuinely incomplete, identify which acceptance criteria remain unimplemented and continue from the last completed step

---

## Fase 5: Testing (via @qa)

### GATE IN
- [ ] Implementación completada por @developer o @frontend

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar cada acceptance criterion
2. [ ] Ejecutar verificación de sintaxis
3. [ ] Si afecta pipeline: probar con test projects embebidos
4. [ ] Verificar no regresiones en funcionalidad existente
5. [ ] Verificar i18n si el proyecto lo usa
6. [ ] Si viene de issue `#N`, verificar cada escenario Gherkin del issue como test case
7. [ ] Smoke test visual de la feature:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Smoke-Test
   Si se omite, documentar motivo en reporte de sesión.
   ---

8. [ ] **Performance Gate** (si el proyecto tiene frontend):
   - Ejecutar según `rules/performance-gate.md`
   - Si modo `error` y score insuficiente → FAIL (resolver antes de continuar)
   - Si modo `warn` o gate skipped (no frontend) → PASS con nota en sesión

9. [ ] Coverage Gate:
   → Ver `rules/coverage-gate.md` para el proceso completo
   → Scope: `build_scope` del `.king/coverage.yaml` (default: `diff` — solo archivos del branch)
   → Si modo `error` y cobertura insuficiente: FAIL — volver a Fase 4 y agregar tests en los archivos indicados
   → Si modo `warn`, runner no detectado, tool ausente, o `.king/coverage.yaml` ausente: continuar con nota en sesión

10. [ ] Performance Budget Gate:
    → Ver `rules/token-budget-gate.md` para el proceso completo
    → Scope: componentes del proyecto listados en LOAD-INDEX.md
    → **Este gate es SIEMPRE no-bloqueante en /build** — independientemente del modo configurado en `.king/token-budget.yaml`, un exceso emite WARN pero nunca detiene el build
    → Si LOAD-INDEX.md ausente, gate disabled, o `.king/token-budget.yaml` ausente: continuar con nota en sesión

### CHECKPOINT
- [ ] Tests de Fase 5 pasando — todos los acceptance criteria verificados
- [ ] Performance Gate: PASS o skipped (no frontend)
- [ ] Coverage Gate ejecutado — resultado documentado (PASS / WARN / SKIP / FAIL)
- [ ] Performance Budget Gate ejecutado — resultado documentado (PASS / WARN / SKIP / FAIL)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Acceptance criterion failed — expected behavior not achieved
Cause: Implementation does not satisfy one or more Gherkin scenarios or DoD items from the issue spec.
Recovery:
  [ ] Option A: Show which AC failed with actual vs expected output — return to Fase 4 and fix the specific failing behavior
  [ ] Option B: If the AC is ambiguous or contradicts the implementation, ask user to clarify intent before retrying
  [ ] Option C: If failure is environmental (missing dependency, wrong config), fix the environment and re-run — do not mark as implementation bug

ERROR: Coverage Gate failed — cobertura insuficiente
Cause: La cobertura del branch está por debajo del threshold configurado en `.king/coverage.yaml`.
Recovery:
  [ ] Option A: Ver los archivos con menor cobertura listados en el reporte del gate — agregar tests que cubran esas líneas, luego re-ejecutar
  [ ] Option B: Si el gate falló por YAML malformado — verificar `.king/coverage.yaml` sintaxis y reintentar
  [ ] Option C: Si el gate falló por tool no instalada — instalar la tool o cambiar a `mode: warn` temporalmente en `.king/coverage.yaml`

---

## Fase 6: Security (via @security)

### GATE IN
- [ ] Tests de Fase 5 pasando

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar Security Gate básico (5 checks)
2. [ ] Verificar que no se introdujeron secrets
3. [ ] Verificar que no hay patrones vulnerables
4. [ ] Si se agregó endpoint: verificar rate limiting y validación

### CHECKPOINT
- [ ] Security Gate completado — sin secrets ni patrones vulnerables introducidos

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Security Gate failed — secrets or vulnerable patterns detected
Cause: Credentials, API keys, or OWASP-pattern vulnerabilities were introduced in the implementation.
Recovery:
  [ ] Option A: If secrets found — remove them immediately, add to `.gitignore`, rotate the exposed credentials, then re-run Security Gate
  [ ] Option B: If vulnerable pattern found — fix the specific code pattern (e.g., add input validation, parameterize queries), re-run the check
  [ ] Option C: If finding is a false positive — document the justification in the session report and get explicit user approval before proceeding

---

## Fase 7: CASTLE Assessment

### GATE IN
- [ ] Security Gate de Fase 6 completado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar CASTLE con capas C·A·_·T·L·_
2. [ ] Resultado debe ser FORTIFIED o CONDITIONAL
3. [ ] Si BREACHED: resolver issues antes de continuar

### CHECKPOINT
- [ ] CASTLE Assessment = FORTIFIED o CONDITIONAL

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: CASTLE Assessment returned BREACHED — quality gates not met
Cause: One or more CASTLE layers (C·A·T·L) have failing checks that block progression.
Recovery:
  [ ] Option A: Review each BREACHED layer's findings — fix the highest-severity issue first, then re-run only that layer's checks
  [ ] Option B: If a layer is BREACHED due to missing tests (T layer), add the missing tests and verify they pass before re-running CASTLE
  [ ] Option C: If BREACHED cannot be resolved in this session, set Status: PARTIAL in the session report and escalate to user with the full CASTLE breakdown

---

## Fase 8: GitHub Integration

### GATE IN
- [ ] CASTLE Assessment de Fase 7 = FORTIFIED o CONDITIONAL

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Asegurar todos los cambios están comitteados
2. [ ] Push branch al remote: `git push -u origin feature/[nombre]`
3. [ ] Crear PR a develop con template:
   ```
   ## Summary
   [Descripción de la feature]

   ## CASTLE Score
   [Resultado del assessment]

   ## Test Plan
   - [ ] Tests verificados
   - [ ] i18n verificado (si aplica)
   - [ ] No regresiones

   ## Issues
   Closes #[número del issue si viene de #N]
   ```
Si viene de issue `#N`, el campo `Closes #[número]` se llena automáticamente con el `#N` del input.

### CHECKPOINT
- [ ] GitHub Integration completada — branch pusheado y PR creado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Git push or PR creation failed
Cause: Remote not configured, authentication error, branch already exists on remote with diverged history, or `gh` CLI not authenticated.
Recovery:
  [ ] Option A: Run `git push -u origin feature/[nombre]` manually — capture the exact error and fix it (auth: `gh auth login`; diverged: `git pull --rebase origin feature/[nombre]`)
  [ ] Option B: If PR creation fails after successful push, run `gh pr create` manually with the template body — verify `gh auth status` first
  [ ] Option C: If remote is unreachable, commit all changes locally and ask user to push manually — document the PR template in the session report for manual submission

---

## Fase 9: Report

### GATE IN
- [ ] GitHub Integration de Fase 8 completada

### MUST DO
> ⚠️ All actions are MANDATORY

Generar reporte RADAR con:
- Decisiones tomadas y justificación
- Archivos modificados
- Resultado de CASTLE assessment
- Link al PR creado
- Si viene de issue `#N`, confirmar que el PR contiene `Closes #N` en el body (auto-cierra el issue al mergearse)

### Evidencia Visual
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### CHECKPOINT
- [ ] Reporte RADAR generado — decisiones, archivos, CASTLE score y PR link incluidos

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Build report not completed — required sections missing
Cause: One or more required report sections (decisions, modified files, CASTLE score, PR link) could not be assembled because a prior phase was incomplete.
Recovery:
  [ ] Option A: Identify which section is missing, retrieve the data from the session (git log, CASTLE output, `gh pr view`), and complete the report
  [ ] Option B: If PR link is missing because GitHub Integration failed, document Status: PARTIAL and note the missing link with the reason
  [ ] Option C: If report cannot be completed at all, output a minimal summary with Status: PARTIAL and list what was accomplished vs what remains
