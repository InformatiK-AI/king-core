---
name: genesis
version: 2.0
api_version: 1.0.0
description: "Skill de genesis. Discovery estructurado que genera la infraestructura completa de Claude Code para un proyecto."
model: sonnet
---

## CASTLE activo: C·A·_·_·_·_

# Genesis - Fabrica de Software

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Existing architecture (only present on re-runs of genesis) | No | project |
| `.king/knowledge/conventions.md` | Existing conventions (only present on re-runs of genesis) | No | project |

> **Nota**: En la primera ejecución de genesis, los archivos `.king/knowledge/` aún no existen (genesis los crea). Todos los archivos son `Required: No` — si no existen, continuar sin ellos.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Condiciones que DETIENEN la ejecucion

- [ ] Usuario no responde a pregunta de discovery -> Esperar respuesta
- [ ] Se realizaron 3 propuestas de equipo de agentes sin aprobación → preguntar si continuar sin agentes especializados o abortar
- [ ] Se realizaron 3 revisiones de un artefacto generado sin aprobación → preguntar si continuar con el artefacto actual o abortar
- [ ] No existe `agents/templates/` -> Error: templates no encontrados
- [ ] Decisión de modo de confirmación (batch/individual) no recibida en Phase 3 Step 0 → asumir modo individual y continuar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA sobrescribir archivos `.king/knowledge/` existentes sin confirmación del usuario
- NUNCA generar código de implementación del proyecto — genesis configura el framework
- NUNCA omitir la fase de onboarding (Fases 4-5)

### REQUIRED OUTPUTS
> Archivos que DEBEN crearse al finalizar

- [ ] `CLAUDE.md` (raiz del proyecto) - Documentacion principal personalizada
- [ ] `.king/knowledge/stack.md`
- [ ] `.king/knowledge/architecture.md`
- [ ] `.king/knowledge/conventions.md`
- [ ] `.king/knowledge/environments.md`
- [ ] `.claude/agents/developer.md` - Agent core
- [ ] `.claude/agents/architect.md` - Agent core
- [ ] `.claude/agents/qa.md` - Agent core
- [ ] `.claude/agents/frontend.md` - Agent core
- [ ] `.claude/agents/{especializados}.md` - Segun deteccion (0-6)
- [ ] `.king/sdd/config.yaml` — SDD pipeline inicializado
- [ ] `.king/registry.md` — Registry del proyecto inicializado
- [ ] Session document creado — ver `skills/_shared/lifecycle-outputs.md`

### PHASES OVERVIEW
```
PHASE 1: Discovery -> PHASE 2: Agents -> PHASE 3: Generation -> PHASE 4: Setup -> PHASE 5: Onboarding
      |                   |                  |                   |                |
  5 preguntas      Detectar+Confirmar   Crear artefactos    Worktrees+Hooks   Explicar flujo
```

### PARAMETERS

Ninguno. Se ejecuta con `/genesis`.

### IF FAILS
> Si genesis falla a mitad de ejecucion -> Ver seccion **RECOVERY PROCEDURE** en `GENERATION.md`

---

## PHASE ROUTER

> **Excepción v2.0 documentada**: Este skill usa PHASE ROUTER con carga modular
> (DISCOVERY.md, GENERATION.md) en vez de fases inline con GATE IN. Justificación:
> cada sub-archivo contiene múltiples fases con sus propios checkpoints, y la carga
> modular optimiza tokens (~830 entry vs ~2700 total). Los GATE IN se implementan
> dentro de cada sub-archivo cargado.

> Detecta la fase actual y carga el archivo correspondiente.

### PHASE 1-2: DISCOVERY + AGENT SELECTION

> Cargar: [DISCOVERY.md](DISCOVERY.md)

| Fase | Contenido |
|------|-----------|
| PHASE 1: Discovery | 5 preguntas UNA A UNA, auto-deteccion de stack |
| PHASE 2: Agent Selection | Analizar senales, proponer equipo, confirmar |

### PHASE 3-5: GENERATION + SETUP + ONBOARDING

> Cargar: [GENERATION.md](GENERATION.md)

| Fase | Contenido |
|------|-----------|
| PHASE 3: Generation | Knowledge base, CLAUDE.md, agents core + especializados, Context7 |
| PHASE 4: Setup | Worktrees, hooks |
| PHASE 5: Onboarding | Resumen, sesion de registro |

Incluye tambien: **RECOVERY PROCEDURE** y **REFERENCE** (catalogos, templates, stacks sugeridos).

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] CLAUDE.md existe y esta completo
- [ ] `.gitignore` creado (si no existía) o preservado con warning (si ya existía)
- [ ] `.env.example` generado con secciones de variables del stack detectado
- [ ] `.king/knowledge/stack.md` creado y confirmado
- [ ] `.king/knowledge/architecture.md` creado y confirmado
- [ ] `.king/knowledge/conventions.md` creado y confirmado
- [ ] `.king/knowledge/environments.md` creado y confirmado
- [ ] Todos los agents core existen
- [ ] Agents especializados detectados fueron creados
- [ ] `.king/sdd/config.yaml` creado o ya existía (SDD inicializado)
- [ ] `.king/registry.md` creado o ya existía (registry inicializado)
- [ ] Sesion de genesis registrada
- [ ] Usuario conoce el proximo paso (/brainstorm)

### CASTLE Assessment

Evaluar antes de reportar el Execution Summary:

| Gate | Layer | Verdict | Finding |
|------|-------|---------|---------|
| C | Correctness | ✅ PASS / ❌ BREACH | Todos los REQUIRED OUTPUTS existen y son válidos / {lista de artefactos faltantes} |
| A | Architectural | ✅ PASS / ⚠️ WARNING | Bootstrap coherente con arquitectura del framework / {incoherencia detectada} |

- `FORTIFIED` → ambos gates PASS
- `CONDITIONAL` → algún gate WARNING
- `BREACHED` → algún gate BREACH → reportar y NO marcar Status como `COMPLETE`

### IF FAILS
> ❌ What to do when FINAL CHECKPOINT fails

ERROR: Genesis incomplete — one or more required artifacts missing
Cause: A phase failed silently, a file write was not confirmed, or the session was not registered.
Recovery:
  [ ] Option A: Identify missing artifacts using the RECOVERY PROCEDURE in `GENERATION.md` — run the validation script to see which files are missing vs present
  [ ] Option B: Re-run `/genesis` with merge mode (option b) to generate only the missing artifacts without overwriting what was already created
  [ ] Option C: If session registration is the only missing item, communicate the genesis result to the user directly — the infrastructure is usable without the session file

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(propagar desde tabla CASTLE Assessment del FINAL CHECKPOINT)_ |
| Artifacts | _(listar archivos modificados, branch, PR)_ |
| Next Recommended | _(ver Guide Next Step)_ |
| Risks | _(riesgos activos o "None")_ |

## Archivos del skill

| Archivo | Contenido | Aprox |
|---------|-----------|-------|
| `SKILL.md` | Router, QUICK REFERENCE, FINAL CHECKPOINT | ~100 lineas |
| `DISCOVERY.md` | Fases 1-2: Discovery + Agent Selection | ~170 lineas |
| `GENERATION.md` | Fases 3-5: Generation + Setup + Onboarding + Recovery + Reference | ~700 lineas |

---

## Ver también

- **Skill siguiente**: `skills/brainstorm/SKILL.md`
- **Validacion**: `validation/VALIDATION.md` → "Checklist: /genesis"
- **Session template**: `skills/session-management/SKILL.md`
- **Agent templates**: `agents/templates/agent-radar-template.md`
- **Knowledge base**: `knowledge/`
