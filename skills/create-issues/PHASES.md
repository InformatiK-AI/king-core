# Create Issues — Phases (v2.0)

> Lógica detallada de las fases 1-8. Entry point: [SKILL.md](SKILL.md)

---

## Fase 1: Detección de Modo y Validación de Entrada

### GATE IN
- Prerequisito: Fase 0 (Load Context) completada; ruta al plan de implementación proporcionada por el usuario.

### MUST DO
> ⚠️ All actions are MANDATORY

**1a. Verificar plan:**
1. [ ] Verificar que el archivo de plan existe y es legible:
   ```bash
   test -f "[ruta-al-plan]" && echo "Plan encontrado" || echo "Plan no encontrado"
   ```
2. [ ] Leer y parsear el contenido del plan

**1b. Detección automática de modo:**
```bash
gh auth status 2>/dev/null
```
- **SI** `gh` disponible Y el repo tiene remote → **MODO GITHUB** (flujo de creación en GitHub)
- **SI NO** → **MODO LOCAL** (genera archivos Markdown en `.king/issues/`)

Informar al usuario qué modo se detectó antes de continuar.

**1c. Validación según modo:**
- **MODO GITHUB:**
  1. Detectar repositorio destino (cascade de prioridad):
     - Flag `--repo <owner/repo>` proporcionado por el usuario
     - Repositorio del directorio actual: `gh repo view --json nameWithOwner -q .nameWithOwner`
     - Si no se detecta: preguntar al usuario con AskUserQuestion
  2. Verificar acceso: `gh repo view [owner/repo] --json name -q .name`
- **MODO LOCAL:**
  1. Crear directorio `.king/issues/` si no existe
  2. Leer `INDEX.md` si existe para determinar último ID asignado
  3. Si no existe `INDEX.md`, iniciar IDs desde 001

### CHECKPOINT
- [ ] Modo detectado (GITHUB o LOCAL) e informado al usuario.
- [ ] Plan de implementación leído y parseado correctamente.
- [ ] Repositorio GitHub validado con acceso (MODO GITHUB) o directorio `.king/issues/` listo con ID inicial determinado (MODO LOCAL).

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Plan file not found or mode detection failed
Cause: Plan path is incorrect, `gh` CLI not authenticated, or `.king/issues/` directory cannot be created.
Recovery:
  [ ] Option A: Verify the plan file exists at the provided path — if not, ask user for the correct path or run `/plan` first to generate it
  [ ] Option B: If MODO GITHUB detection fails (gh auth error), run `gh auth login` and retry — or explicitly switch to MODO LOCAL if GitHub is not needed
  [ ] Option C: If `.king/issues/` cannot be created, check permissions and run `mkdir -p .king/issues/` manually, then retry

---

## Fase 2: Análisis del Plan (via @architect)

### GATE IN
- Prerequisito: Fase 1 completada; modo detectado, plan leído, y entorno (GitHub o local) validado.

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Parsear el plan de implementación identificando:
   - Objetivo general (candidato a Epic)
   - Tareas individuales (candidatas a Stories)
   - Dependencias entre tareas
   - Archivos afectados por tarea
2. [ ] Aplicar criterios INVEST a cada Story candidata:
   - **I**ndependent: ¿Se puede implementar sin bloquear otras?
   - **N**egotiable: ¿Tiene flexibilidad en implementación?
   - **V**aluable: ¿Entrega valor verificable?
   - **E**stimable: ¿Se puede estimar el esfuerzo?
   - **S**mall: ¿Es lo suficientemente pequeña? (max 1-2 horas)
   - **T**estable: ¿Tiene criterios de aceptación claros?
3. [ ] Proponer estructura: 1 Epic + N Stories
4. [ ] Presentar estructura al usuario para aprobación antes de continuar

### CHECKPOINT
- [ ] Epic candidato identificado con objetivo general claro.
- [ ] Lista de Stories candidatas generada con criterios INVEST evaluados.
- [ ] Dependencias entre Stories mapeadas.
- [ ] Estructura Epic/Stories aprobada por el usuario.

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Plan analysis failed — Epic or Stories could not be identified
Cause: The plan file lacks a clear objective (Epic candidate), tasks are not granular enough to be Stories, or user rejected the proposed structure.
Recovery:
  [ ] Option A: If the plan has no clear Epic, propose one derived from the plan's overall goal — present it to user for confirmation before continuing
  [ ] Option B: If tasks are too large (XL) to be Stories, split them further into sub-tasks of max 1-2 hours and re-evaluate INVEST criteria
  [ ] Option C: If user rejects the structure, ask them to describe how they want the plan decomposed (e.g., "split task 3 into two stories") and apply that structure

---

## Fase 3: Generación Gherkin (via @qa)

### GATE IN
- Prerequisito: Fase 2 completada; estructura Epic + Stories aprobada por el usuario.

### MUST DO
> ⚠️ All actions are MANDATORY

Para cada Story aprobada, generar:

**Escenarios Funcionales** (perspectiva usuario, mínimo 2):
```gherkin
Feature: [nombre descriptivo]

  Scenario: [happy path - flujo principal]
    Given [precondición]
    When [acción del usuario]
    Then [resultado esperado]

  Scenario: [edge case - caso límite]
    Given [precondición alternativa]
    When [acción que puede fallar]
    Then [manejo del caso]
```

**Escenarios Técnicos** (perspectiva implementación, mínimo 1):
```gherkin
Feature: [nombre técnico]

  Scenario: [detalle de implementación]
    Given [estado del sistema]
    When [operación técnica]
    Then [resultado técnico verificable]
```

Convenciones:
- Keywords Gherkin en inglés (Given/When/Then)
- Descripciones en español
- Cada escenario debe ser independiente y verificable

### CHECKPOINT
- [ ] Cada Story tiene al menos 2 escenarios funcionales (happy path + edge case) en formato Gherkin válido.
- [ ] Cada Story tiene al menos 1 escenario técnico en formato Gherkin válido.
- [ ] Todos los escenarios son independientes y verificables entre sí.

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Gherkin scenarios invalid or insufficient — Stories lack required scenario coverage
Cause: A Story has fewer than 2 functional scenarios, an edge case is missing, or a scenario is not independently verifiable.
Recovery:
  [ ] Option A: For each Story with insufficient scenarios, add the missing type (edge case or technical scenario) following the Gherkin conventions defined in Fase 3
  [ ] Option B: If a scenario is not independent, rewrite it with its own Given precondition that does not rely on other scenarios' state
  [ ] Option C: If a Story genuinely has only one meaningful scenario, document the justification and get user approval to proceed with a single scenario exception

---

## Fase 4: Generación DoD y Acceptance Criteria

### GATE IN
- Prerequisito: Fase 3 completada; escenarios Gherkin (funcionales y técnicos) generados para cada Story.

### MUST DO
> ⚠️ All actions are MANDATORY

Para cada Story, generar:

**Definition of Done** (checklist adaptada al proyecto):
- [ ] Código con convenciones del proyecto (ver CLAUDE.md)
- [ ] Escenarios funcionales verificados
- [ ] Escenarios técnicos verificados
- [ ] Verificación de sintaxis OK (`node -e "require('fs')..."`)
- [ ] Build exitoso (`npm run build`)
- [ ] i18n actualizado (ES/EN/PT) si aplica
- [ ] Code review completado
- [ ] CASTLE >= CONDITIONAL
- [ ] Sin vulnerabilidades introducidas
- [ ] Conventional commits

**Acceptance Criteria** (derivados de escenarios funcionales):
- AC-N: criterio verificable derivado de cada Scenario del happy path
- Cada AC debe ser binario (cumple o no cumple)

### CHECKPOINT
- [ ] Cada Story tiene un checklist Definition of Done adaptado al proyecto.
- [ ] Cada Story tiene Acceptance Criteria binarios derivados de sus escenarios del happy path.

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: DoD or Acceptance Criteria missing for one or more Stories
Cause: A Story's Gherkin happy path scenarios are ambiguous, or the DoD checklist was not customized for the project stack.
Recovery:
  [ ] Option A: For each Story missing ACs, derive them directly from its happy path Given/When/Then — each Then clause becomes one AC ("AC-N: [Then clause]")
  [ ] Option B: If the DoD checklist is generic, load `.king/knowledge/conventions.md` and `.king/knowledge/stack.md` and customize the checklist items for the actual tech stack
  [ ] Option C: If an AC cannot be made binary, rewrite it as two separate ACs covering the positive and negative cases

---

## Fase 5: Composición de Issues (via @architect)

### GATE IN
- Prerequisito: Fase 4 completada; DoD y Acceptance Criteria generados para cada Story.

### MUST DO
> ⚠️ All actions are MANDATORY

**Body del Epic:**
```markdown
## Vision
[Descripción de alto nivel de la feature]

## Objetivos
- [ ] Story #PENDING: [título story 1]
- [ ] Story #PENDING: [título story 2]
- [ ] Story #PENDING: [título story N]

## Alcance
### Incluido
- [funcionalidad incluida]

### Excluido
- [funcionalidad explícitamente fuera de alcance]

## Dependencias
- [dependencias externas o entre componentes]

## Metricas de Exito
- [métrica cuantificable]
```

**Body de cada Story:**
```markdown
## Descripcion
[Qué entrega esta story y por qué es valiosa]
**Epic**: #PENDING

## Escenarios Funcionales (BDD)
[Gherkin generado en Fase 3]

## Escenarios Tecnicos
[Gherkin técnico generado en Fase 3]

## Definition of Done
[Checklist generada en Fase 4]

## Acceptance Criteria
[ACs generados en Fase 4]

## Archivos Afectados
- `path/to/file.ext` — [tipo de cambio: crear/modificar/eliminar]

## Notas de Implementacion
[Hints técnicos, patrones a seguir, módulos relevantes]

## Dependencias
[Stories que deben completarse antes, si las hay]
```

Presentar preview completo de todos los issues al usuario antes de crear en GitHub.

### CHECKPOINT
- [ ] Body del Epic compuesto con Vision, Objetivos, Alcance, Dependencias y Métricas de Éxito.
- [ ] Body de cada Story compuesto con todos los campos requeridos (Descripción, Gherkin, DoD, ACs, Archivos Afectados, Notas).
- [ ] Preview completo presentado al usuario y aprobado antes de proceder a creación.

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Issue bodies incomplete or user did not approve preview
Cause: Required fields are missing in Epic or Story bodies, or user found errors in the preview and requested changes.
Recovery:
  [ ] Option A: For each missing required field, fill it now using data from previous phases — do not leave any field blank or with placeholder text
  [ ] Option B: If user rejected the preview, identify exactly which fields or content they want changed — apply changes and re-present only the modified sections
  [ ] Option C: If user wants to fundamentally restructure the issues (e.g., merge two stories), apply the restructuring to the composed bodies and re-present the full preview before proceeding

---

## Fase 6: Creación de Issues

### GATE IN
- Prerequisito: Fase 5 completada; bodies del Epic y todas las Stories compuestos y aprobados por el usuario.

### MUST DO
> ⚠️ All actions are MANDATORY

> La ejecución de esta fase depende del modo detectado en Fase 1b.

### Fase 6A: Creación en GitHub (via @devops) — MODO GITHUB

**Paso 1 — Labels** (crear si no existen):
```bash
gh label create "epic" --color "0052CC" --description "Epic: agrupación de stories" --force
gh label create "story" --color "0E8A16" --description "Story: unidad de trabajo implementable" --force
gh label create "priority:high" --color "D93F0B" --description "Prioridad alta" --force
gh label create "priority:medium" --color "FBCA04" --description "Prioridad media" --force
gh label create "priority:low" --color "C2E0C6" --description "Prioridad baja" --force
gh label create "component:pipeline" --color "BFD4F2" --description "Pipeline de migración" --force
gh label create "component:ui" --color "D4C5F9" --description "Interfaz de usuario" --force
gh label create "component:api" --color "FEF2C0" --description "API/Backend" --force
gh label create "component:i18n" --color "F9D0C4" --description "Internacionalización" --force
```

**Paso 2 — Crear Epic:**
```bash
EPIC_BODY=$(mktemp --suffix=.md)
cat > "$EPIC_BODY" << 'EPICEOF'
[body del epic]
EPICEOF
gh issue create --title "[Epic] [título]" --body-file "$EPIC_BODY" --label "epic,priority:high"
rm -f "$EPIC_BODY"
```
Capturar el número del issue creado.

**Paso 3 — Crear Stories secuencialmente:**
```bash
STORY_BODY=$(mktemp --suffix=.md)
cat > "$STORY_BODY" << 'STORYEOF'
[body de la story]
STORYEOF
gh issue create --title "[título de la story]" --body-file "$STORY_BODY" --label "story,[component label],[priority label]"
rm -f "$STORY_BODY"
```
Capturar el número de cada issue.

**Paso 4 — Actualizar Epic con números reales:**
```bash
EPIC_BODY_UPDATED=$(mktemp --suffix=.md)
cat > "$EPIC_BODY_UPDATED" << 'EPICEOF'
[body actualizado con #reales]
EPICEOF
gh issue edit [epic-number] --body-file "$EPIC_BODY_UPDATED"
rm -f "$EPIC_BODY_UPDATED"
```

Actualizar también el campo `**Epic**: #PENDING` en cada Story con el número real del Epic.

**Paso 5 — Opcionales** (si se proporcionaron flags):
- `--milestone <nombre>`: `gh issue edit [number] --milestone "[nombre]"`
- `--assignee <usuario>`: `gh issue edit [number] --add-assignee "[usuario]"`

### Fase 6B: Creación Local — MODO LOCAL

**Paso 1 — Crear Epic:** Crear archivo `EPIC-NNN.md` usando template `templates/issue-epic.md`.

**Paso 2 — Crear Stories:** Para cada Story, crear `STORY-NNN.md` usando `templates/issue-story.md`. Status inicial: `open`.

**Paso 3 — Crear/Actualizar INDEX.md:** Agregar fila por cada issue creado. Formato: ID | Título | Status | Epic | Prioridad.

**Paso 4 — Actualizar Epic con IDs reales.**

**Estructura resultante:**
```
.king/issues/
├── EPIC-001.md
├── STORY-001.md
├── STORY-002.md
└── INDEX.md
```

### CHECKPOINT
- [ ] Epic creado en GitHub con número de issue capturado (MODO GITHUB) o archivo EPIC-NNN.md creado en `.king/issues/` (MODO LOCAL).
- [ ] Todas las Stories creadas secuencialmente con números/IDs capturados.
- [ ] Cross-references actualizadas: `#PENDING` reemplazados por números/IDs reales en Epic y Stories.
- [ ] INDEX.md creado o actualizado con todas las entradas (MODO LOCAL).

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Issue creation failed — Epic or Stories not created in GitHub or local
Cause: `gh issue create` command failed (auth, network, rate limit), or file write to `.king/issues/` failed.
Recovery:
  [ ] Option A: For MODO GITHUB — check `gh auth status` and retry the failing `gh issue create` command individually; capture the issue number before proceeding to the next
  [ ] Option B: For MODO LOCAL — verify `.king/issues/` exists and is writable; retry the file write; check disk space with `df -h` if write fails
  [ ] Option C: If partial creation occurred (Epic created, some Stories failed), update the Epic with the stories that were created and document which stories failed

---

## Fase 7: Verificación

### GATE IN
- Prerequisito: Fase 6 completada; todos los issues creados con IDs/números reales asignados y cross-references actualizadas.

### MUST DO
> ⚠️ All actions are MANDATORY

**MODO GITHUB:**
1. [ ] Verificar cada issue creado: `gh issue view [number]`
2. [ ] Validar cross-references: Epic lista todas las Stories con `#` correctos, cada Story referencia el Epic correcto
3. [ ] Verificar labels aplicados correctamente
4. [ ] Si hay errores, corregir con `gh issue edit`

**MODO LOCAL:**
1. [ ] Verificar que todos los archivos STORY-NNN.md y EPIC-NNN.md fueron creados correctamente
2. [ ] Validar cross-references: Epic lista todas las Stories con IDs correctos
3. [ ] Verificar que INDEX.md tiene todas las entradas
4. [ ] Si hay errores, corregir los archivos directamente

### CHECKPOINT
- [ ] Cada issue verificado individualmente (via `gh issue view` o lectura del archivo Markdown).
- [ ] Cross-references correctas: Epic lista todas las Stories, cada Story referencia el Epic correcto.
- [ ] Labels aplicados correctamente a cada issue (MODO GITHUB).
- [ ] INDEX.md completo y sin entradas faltantes (MODO LOCAL).

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Verification failed — cross-references incorrect or issues missing from index
Cause: A `#PENDING` was not replaced, an issue references the wrong Epic number, or INDEX.md is missing entries.
Recovery:
  [ ] Option A: For each broken cross-reference, run `gh issue edit [number] --body-file [corrected-file]` (GITHUB) or directly edit the Markdown file (LOCAL)
  [ ] Option B: If INDEX.md has missing entries, add them now from the list of created issue IDs captured during Fase 6
  [ ] Option C: If a label is missing on a GITHUB issue, apply it with `gh issue edit [number] --add-label "[label]"`

---

## Fase 8: Report

### GATE IN
- Prerequisito: Fase 7 completada; todos los issues verificados y cross-references validadas.

### MUST DO
> ⚠️ All actions are MANDATORY

Generar reporte con:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
► ISSUES CREADOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Tipo | Título | Gherkin | ACs | URL |
|---|------|--------|---------|-----|-----|
| N | Epic | [título] | — | — | [url o path] |
| N | Story | [título] | X scenarios | Y ACs | [url o path] |

Total: 1 Epic + N Stories
Escenarios Gherkin: X funcionales + Y técnicos
Acceptance Criteria: Z total

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### CHECKPOINT
- [ ] Tabla de issues generada con tipo, título, conteo de escenarios Gherkin, ACs, y URL o path.
- [ ] Totales reportados: cantidad de Epic, Stories, escenarios Gherkin y Acceptance Criteria.

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Issues report not generated — table or totals missing
Cause: Issue URLs or paths were not captured during creation, or scenario/AC counts were not tracked.
Recovery:
  [ ] Option A: Reconstruct the table from data captured during Fase 6 — issue numbers/IDs, titles, and Gherkin counts from Fase 3 are sufficient
  [ ] Option B: If URLs are missing for GITHUB mode, run `gh issue list --limit 20 --json number,title,url` to retrieve them
  [ ] Option C: Output a partial report with whatever data is available — Status: PARTIAL with a note on what is missing is acceptable
