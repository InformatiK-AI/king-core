---
name: plan
description: "Planificación de features con agentes especializados. Usar cuando se necesite: planificar una feature, diseñar una solución, analizar impacto de un cambio, o generar un plan de implementación robusto."
version: 2.0
api_version: 1.0.0
---

# Plan Feature — Planificación Multi-Agente

Planificación estructurada de features usando agentes especializados que aportan perspectivas de arquitectura, seguridad, QA y desarrollo para generar un design doc y plan de implementación robusto.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural patterns to consider in the implementation plan | Yes | project |
| `.king/knowledge/conventions.md` | Code and project conventions for planning accuracy | Yes | project |
| `.king/knowledge/stack.md` | Stack-specific constraints that affect planning | Yes | project |

## QUICK REFERENCE

### PHASES OVERVIEW
Phase 0 (Load Context) → Fase 1 (Captura de Idea) → Fase 2 (Exploración del Codebase) → Fase 2.5 (Complexity Triage) → Fase 3 (Análisis Multi-Agente) → Fase 4 (Consolidación RADAR) → Fase 5 (Aprobación del Diseño) → Fase 6 (Generación del Plan) → Fase 7 (Report) → Fase 8 (Write Session) → Fase 9 (Guide Next Step)

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión de `/brainstorm` previa (feature no fue ideada)
- [ ] Los requerimientos son demasiado ambiguos para planificar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA producir el plan final sin la aprobación explícita del usuario (Fase 5)
- NUNCA saltarse la consulta a @architect para cambios con impacto arquitectónico

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] `docs/plans/YYYY-MM-DD-<feature>.md` — Design doc con plan de implementación
- [ ] Lista de issues a crear (input para `/create-issues`)
- [ ] Session document creado (via session-management Phase N+1)

---


## Agentes involucrados
- **@architect** → Evalúa impacto arquitectónico, módulos y dependencias afectadas
- **@developer** → Factibilidad, estimación de esfuerzo, dependencias técnicas
- **@security** → Implicaciones de seguridad, vectores de ataque potenciales
- **@qa** → Estrategia de testing, edge cases, criterios de aceptación
- **@frontend** → (opcional) Si la feature tiene componente UI
- **@api** → (opcional) Si la feature involucra endpoints o APIs
- **@devops** → (opcional) Si la feature requiere cambios de infraestructura o CI/CD

## CASTLE activo: C·A·S·_·_·_

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### Fase 1: Captura de Idea

#### GATE IN
- Prerequisito: Knowledge Injection completada (archivos `.king/knowledge/` leídos o warnings logueados)

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Recibir la idea/descripción de la feature del usuario
2. [ ] Hacer 2-3 preguntas de clarificación usando AskUserQuestion:
   - **Alcance**: ¿Qué está incluido y qué queda fuera?
   - **Restricciones**: ¿Hay limitaciones técnicas, de tiempo o de compatibilidad?
   - **Criterios de éxito**: ¿Cómo se mide que la feature está completa?
3. [ ] Documentar la idea enriquecida con las respuestas

#### CHECKPOINT
- [ ] Descripción de la feature recibida y documentada
- [ ] Alcance, restricciones y criterios de éxito capturados y respondidos por el usuario

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Feature idea not captured — required clarification questions unanswered
Cause: User did not respond to one or more of the three clarification questions (scope, constraints, success criteria).
Recovery:
  [ ] Option A: Re-ask only the unanswered questions — do not repeat answered ones; wait for response before continuing
  [ ] Option B: If user wants to proceed without answering a question, document "Not specified" for that field and proceed with caveats noted
  [ ] Option C: If requirements are fundamentally too ambiguous to plan (e.g., "make it better"), ask user to run `/brainstorm` first to develop the idea before returning to `/plan`

### Fase 2: Exploración del Codebase

#### GATE IN
- Prerequisito: Idea enriquecida de Fase 1 completada (alcance, restricciones y criterios de éxito documentados)

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Lanzar agente Explore (Agent tool, subagent_type=Explore, thoroughness=very thorough) para:
   - Mapear archivos que serán afectados por la feature
   - Identificar patrones existentes relevantes en el codebase
   - Encontrar funcionalidad relacionada que pueda ser reutilizada o impactada
   - Detectar posibles conflictos con código existente
2. [ ] Consolidar hallazgos en un resumen de contexto técnico

#### CHECKPOINT
- [ ] Archivos afectados por la feature mapeados
- [ ] Patrones existentes relevantes identificados
- [ ] Resumen de contexto técnico consolidado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Codebase exploration failed — affected files not mapped
Cause: Explore agent could not access the codebase, the project has no existing code to explore, or the feature touches files in an area not yet created.
Recovery:
  [ ] Option A: If Explore agent failed, read the most likely affected files manually using the feature description as a guide — document findings in the technical context summary
  [ ] Option B: If the project is new (no existing code), document "New project — no existing patterns to map" and proceed with an empty baseline
  [ ] Option C: If specific files cannot be accessed, list them as "unverified" in the context summary and note the access error — do not block planning on file access issues

### Fase 2.5: Complexity Triage

#### GATE IN
- Prerequisito: Fase 2 completada (archivos afectados mapeados y resumen técnico consolidado)

#### MUST DO

1. [ ] Evaluar señales de complejidad usando el contexto de Fase 2:
   - **Cross-cutting**: ¿3+ archivos afectados con dependencias cruzadas (imports mutuos)?
   - **Multi-sesión probable**: ¿estimación preliminar > 4 horas (por cantidad de archivos × complejidad promedio)?
   - **Trazabilidad requerida**: ¿el cambio toca auth, pagos, datos sensibles, compliance, o el usuario mencionó auditoría?
   - **Coordinación multi-agente intensa**: ¿requiere @architect + @security + otro agente especializado en paralelo?

2. [ ] Contar señales detectadas:
   - **0-1 señales** → continuar a Fase 3 normalmente
   - **≥ 2 señales** → mostrar al usuario:

     ```
     ⚠️  Complejidad detectada: {lista de señales}

     Este cambio podría beneficiarse de SDD (Spec-Driven Development),
     que ofrece trazabilidad completa, recovery post-compactación y
     entrega iterativa con PR budget guards.

     ¿Cómo querés continuar?
     A) Continuar con /plan estándar (adecuado para cambios de una sesión)
     B) Escalar a /sdd-new (recomendado para cambios complejos multi-sesión)
     ```

3. [ ] Si el usuario elige **B (SDD)**:
   - Exportar el contexto recopilado (idea enriquecida de Fase 1 + archivos afectados de Fase 2) como brief de contexto
   - Terminar /plan aquí
   - Indicar al usuario: `Ejecutá /sdd-new <nombre-del-cambio>. El contexto recopilado está disponible en esta sesión.`

4. [ ] Si el usuario elige **A (continuar)** o hay 0-1 señales → proceder a Fase 3

#### CHECKPOINT
- [ ] Señales de complejidad evaluadas y documentadas
- [ ] Decisión tomada: continuar /plan o escalar a SDD

### IF FAILS
ERROR: Complexity triage inconclusive
Recovery: Asumir 0 señales y continuar a Fase 3.

### Fase 3: Análisis Multi-Agente

#### GATE IN
- Prerequisito: Resumen de contexto técnico de Fase 2 disponible (archivos afectados y patrones identificados)

#### MUST DO
> ⚠️ All actions are MANDATORY

Lanzar 3-5 agentes EN PARALELO (Agent tool), cada uno con su perspectiva especializada:

1. [ ] **@architect** — Análisis arquitectónico:
   - Impacto en la arquitectura existente (Browser → Vite → Express → Anthropic)
   - Paradigm maps afectados y nuevos necesarios
   - Módulos y archivos específicos que se modificarán
   - Propuesta de diseño con trade-offs

2. [ ] **@developer** — Análisis de factibilidad:
   - Estimación de esfuerzo (S/M/L/XL)
   - Dependencias técnicas (npm packages, APIs externas)
   - Riesgos de implementación
   - Propuesta de descomposición en tareas bite-sized

3. [ ] **@security** — Análisis de seguridad:
   - Vectores de ataque introducidos
   - Implicaciones para API key management
   - Validación de input necesaria
   - Compliance considerations

4. [ ] **@qa** — Análisis de calidad:
   - Estrategia de testing recomendada
   - Edge cases identificados
   - Criterios de aceptación propuestos
   - Impacto en test projects embebidos

5. [ ] **(Opcionales)** según tipo de feature:
   - **@frontend**: Si hay componente UI → análisis de UX, inline styles, responsive
   - **@api**: Si hay endpoints → diseño de API, rate limiting, validación
   - **@devops**: Si hay infra → cambios en build, deploy, variables de entorno

#### CHECKPOINT
- [ ] Outputs de @architect y @developer recibidos (obligatorios)
- [ ] Output de @security recibido (obligatorio)
- [ ] Output de @qa recibido (obligatorio)
- [ ] Agentes opcionales ejecutados si aplica según tipo de feature

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Required agent outputs not received — multi-agent analysis incomplete
Cause: One or more mandatory agents (@architect, @developer, @security, @qa) did not return a usable output.
Recovery:
  [ ] Option A: Re-run the specific agent that failed — provide it the technical context summary from Fase 2 as input and retry
  [ ] Option B: If an agent consistently fails to produce output, simulate its perspective manually using the agent's documented responsibilities and knowledge files
  [ ] Option C: If two or more mandatory agents fail, pause and ask user whether to proceed with partial analysis or wait — document which perspectives are missing in the design doc

### Fase 4: Consolidación RADAR

#### GATE IN
- Prerequisito: Outputs de todos los agentes obligatorios de Fase 3 recibidos (@architect, @developer, @security, @qa)

#### MUST DO
> ⚠️ All actions are MANDATORY

Usar protocolo RADAR para consolidar las perspectivas de los agentes:

1. [ ] **Read** — Recopilar outputs de todos los agentes ejecutados en Fase 3
2. [ ] **Analyze** — Identificar:
   - Conflictos entre perspectivas (ej: @architect quiere separar vs @developer prefiere inline)
   - Sinergias (ej: @security y @qa identificaron el mismo edge case)
   - Gaps no cubiertos por ningún agente
3. [ ] **Decide** — Determinar enfoque recomendado:
   - Resolver conflictos con justificación
   - Documentar trade-offs explícitamente
   - Proponer alternativas descartadas con razón
4. [ ] **Act** — Componer design doc con secciones:
   - Visión y objetivos
   - Diseño técnico (arquitectura, componentes, flujo de datos)
   - Seguridad y riesgos
   - Estrategia de testing
   - Estimación y dependencias
5. [ ] **Report** — Presentar design doc al usuario de forma estructurada

#### CHECKPOINT
- [ ] Conflictos entre perspectivas de agentes identificados y resueltos con justificación
- [ ] Design doc borrador compuesto con todas las secciones requeridas
- [ ] Trade-offs y alternativas descartadas documentados

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Design doc consolidation failed — unresolved conflicts or missing sections
Cause: Agent perspectives have irreconcilable conflicts, or one or more required design doc sections (vision, technical design, security, testing, estimation) could not be drafted.
Recovery:
  [ ] Option A: For each unresolved conflict, apply RADAR Decide step — choose the option that best satisfies Security > Correctness > Simplicity and document the reasoning explicitly
  [ ] Option B: If a required section is missing due to insufficient agent output, draft that section using available information and mark it as "Needs review" for user confirmation
  [ ] Option C: If consolidation cannot produce a coherent design, present the conflict summary to the user and ask for their decision on the blocking trade-off

### Fase 5: Aprobación del Diseño

#### GATE IN
- Prerequisito: Design doc borrador de Fase 4 compuesto con todas las secciones (visión, diseño técnico, seguridad, testing, estimación)

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Presentar design doc sección por sección al usuario
2. [ ] Para cada sección, permitir:
   - Aprobación
   - Solicitud de cambios
   - Preguntas de clarificación
3. [ ] **Gate**: El usuario DEBE aprobar el design doc completo antes de continuar
4. [ ] Si hay cambios solicitados, iterar las secciones afectadas

#### CHECKPOINT
- [ ] Design doc presentado al usuario sección por sección
- [ ] Usuario ha aprobado explícitamente el design doc completo
- [ ] Todos los cambios solicitados por el usuario incorporados y re-aprobados

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Design doc not approved — user requested changes after review
Cause: User found issues in one or more sections of the design doc that require revision before the plan can be generated.
Recovery:
  [ ] Option A: Identify exactly which sections were rejected and what changes were requested — revise only those sections and re-present them for approval without re-presenting already-approved sections
  [ ] Option B: If the same section is rejected 3 times, ask the user to write their preferred version of that section directly — incorporate it verbatim
  [ ] Option C: If user wants to fundamentally change the approach (different tech, different architecture), return to Fase 3 with the new direction and re-run the affected agents

### Fase 6: Generación del Plan

#### GATE IN
- Prerequisito: Design doc aprobado explícitamente por el usuario en Fase 5

#### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Con el design doc aprobado, generar plan de implementación:
   - Descomponer en tareas bite-sized (max 1-2 horas de trabajo cada una)
   - Establecer orden de dependencias entre tareas
   - Asignar archivos afectados por tarea
   - Incluir criterios de aceptación por tarea
2. [ ] Asegurar que el directorio existe:
   ```bash
   mkdir -p docs/plans/
   ```
3. [ ] Escribir plan en: `docs/plans/YYYY-MM-DD-<topic-slug>.md`
4. [ ] El plan debe incluir secciones parseables por `/create-issues`: objetivo general, tareas con títulos, dependencias entre tareas, y archivos afectados por tarea
5. [ ] **Registrar artefacto**: En Phase N+1 (Write Session), el path del plan (`docs/plans/YYYY-MM-DD-<topic-slug>.md`) DEBE registrarse como artefacto tipo "Plan" en la tabla "Artefactos Producidos" del workflow `context.md`

#### CHECKPOINT
- [ ] Plan de implementación escrito en `docs/plans/YYYY-MM-DD-<topic-slug>.md`
- [ ] Tareas descompuestas en unidades bite-sized con dependencias y archivos afectados
- [ ] Plan contiene secciones parseables por `/create-issues`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Plan file not written to docs/plans/
Cause: Directory does not exist, write permission denied, or the plan content is malformed.
Recovery:
  [ ] Option A: Run `mkdir -p docs/plans/` and retry writing the file — verify disk space with `df -h` if the write fails again
  [ ] Option B: If the plan file was written but lacks parseable sections (no task titles, no dependencies), add those sections now by restructuring the content from the design doc
  [ ] Option C: If the directory cannot be created (permissions), ask user to create `docs/plans/` manually and confirm before retrying

### Fase 7: Report

#### GATE IN
- Prerequisito: Archivo de plan `docs/plans/YYYY-MM-DD-<topic-slug>.md` creado y escrito en Fase 6

#### MUST DO
> ⚠️ All actions are MANDATORY

Generar reporte RADAR con:
- Resumen de la feature planificada
- Decisiones clave tomadas y justificación
- Agentes consultados y sus perspectivas
- Design doc aprobado (referencia al archivo)
- Plan de implementación generado (referencia al archivo)
- Métricas: número de tareas, archivos afectados, estimación total

#### CHECKPOINT
- [ ] Reporte RADAR presentado al usuario con resumen completo de la feature
- [ ] Referencias a design doc y archivo de plan incluidas en el reporte
- [ ] Métricas (número de tareas, archivos afectados, estimación total) calculadas y reportadas

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Plan report not completed — required fields missing
Cause: Plan file path, design doc reference, or task metrics could not be assembled for the report.
Recovery:
  [ ] Option A: Retrieve the plan file path from the write operation in Fase 6 — if it was written successfully, the path is known; include it in the report now
  [ ] Option B: If metrics (task count, file count, estimation) cannot be calculated, count them manually from the plan file and include them
  [ ] Option C: Output a partial report with Status: PARTIAL noting which fields are missing — the plan file itself is the critical artifact; the report is secondary

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
| Next Recommended | _(ver Guide Next Step)_ |
| Risks | _(riesgos activos o "None")_ |

### Fase 8: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 9: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para plan:
| Condición | Próximo Skill |
|-----------|---------------|
| Plan generado exitosamente | `/create-issues docs/plans/YYYY-MM-DD-<topic>.md` |
| Usuario quiere iterar diseño | Repetir `/plan` con ajustes |

## Templates

- **Feature Specification**: `templates/feature-spec.md` — Formato estándar para documentar la especificación de la feature resultante del plan
