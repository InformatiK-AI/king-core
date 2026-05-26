---
name: brainstorm
version: 2.0
description: "Skill de ideación y diseño. Explora la intención del usuario, requisitos y diseño ANTES de planificar implementación. Consulta agentes especializados para enriquecer el diseño. En modo PROYECTO genera blueprint técnico completo (4 artefactos). Solo genera documentación, nunca ejecuta código."
---

# Brainstorming Ideas Into Designs

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural context for design proposals | Yes | project |
| `.king/knowledge/stack.md` | Stack constraints for feasibility assessment | Yes | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión de `/genesis` previa
- [ ] No se puede acceder al proyecto: `CLAUDE.md` no existe o `.claude/` no es legible
- [ ] Se completaron 3 iteraciones de diseño sin aprobación → preguntar al usuario si continuar o abortar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA responder "entendido" o "comenzaré a implementar" sin completar Phase 5
- NUNCA saltarse la generación de documentos — si Write() no está disponible, presentar bloques copiables
- /brainstorm produce documentos de diseño, NUNCA código ni decisiones de implementación
- NUNCA saltarse una fase — las 5 fases son obligatorias e irremplazables
- NUNCA interpretar las fases como "lo que haré" — son acciones a ejecutar ahora

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

**Modo PROYECTO (4 artefactos + sesión):**
- [ ] `.king/docs/architecture/001-{proyecto}-arquitectura.md`
- [ ] `.king/docs/architecture/002-{proyecto}-modelo-datos.md`
- [ ] `.king/docs/architecture/003-{proyecto}-dependencias.md`
- [ ] `.king/docs/architecture/004-{proyecto}-inconsistencias.md`
- [ ] Session document creado (via session-management Phase N+1)

**Modo FEATURE (design + deltas):**
- [ ] `.king/docs/features/{feature}/design.md`
- [ ] Deltas appendeados a 001-004 si aplica
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
PHASE 1 → PHASE 2 → PHASE 3 → PHASE 4 → PHASE 5
CONTEXT   EXPLORE   CONSULT   DESIGN    DOCUMENT
   ↓         ↓         ↓         ↓          ↓
 Leer      Q 1x1    Agentes   Presentar  Write() ×4
genesis   +entid.   +collect  secciones  o append
knowledge  +deps     002/003   1 por      delta
```
⛔ TODAS las fases son obligatorias — ejecutar cada una completa antes de avanzar.
⛔ Plan mode NO exime de ninguna fase. Solo Phase 5 adapta Write() a bloques copiables.
⛔ NUNCA saltar fases. NUNCA describir fases en lugar de ejecutarlas.

### METADATA FORMAT + AGENT CONSULTATION MATRIX
> Ver: [REFERENCE.md](REFERENCE.md)

---

## PARAMETERS
- `--mode {proyecto|feature}` - Override de modo (opcional, default: detección automática)
- `--feature {nombre}` - Nombre de la feature a diseñar (modo feature)

---

## Detección Automática de Modo

> Ver lógica completa: [REFERENCE.md](REFERENCE.md) → sección "Detección Automática de Modo"

Si `--mode {proyecto|feature}` explícito → usar directamente. Sin flag → lógica de detección en REFERENCE.md.

---

## PHASE ROUTER

> Cargar [PHASES.md](PHASES.md) para la lógica completa de las 5 fases.

| Fase | Contenido |
|------|-----------|
| PHASE 1: Context | Cargar knowledge, capturar metadata, detectar modo |
| PHASE 2: Explore | Preguntas 1x1, entidades de dominio, deps conocidas |
| PHASE 3: Consult | Agentes RADAR + colectar para 002/003/004 |
| PHASE 4: Design | Presentar secciones por artefacto, validar con usuario |
| PHASE 5: Document | Write() ×4 (PROYECTO) o append delta (FEATURE) |

---

## Key Principles

- **One question at a time** - No abrumar con múltiples preguntas
- **Multiple choice preferred** - Más fácil de responder cuando sea posible
- **YAGNI ruthlessly** - "You Aren't Gonna Need It". Eliminar features innecesarias de todos los diseños
- **Explore alternatives** - Siempre proponer 2-3 enfoques antes de decidir
- **Shift-left expertise** - Consultar agentes especializados ANTES de finalizar el diseño
- **Selective consultation** - Solo consultar agentes cuyas señales se detectan (no todos)
- **Incremental validation** - Presentar diseño en secciones, validar cada una
- **Be flexible** - Volver atrás y clarificar cuando algo no tenga sentido

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] Modo detectado: PROYECTO (sin diseño previo + sesión genesis existente) o FEATURE
- [ ] Agentes relevantes consultados (o fallback documentado)
- [ ] **Modo PROYECTO**: 4 artefactos en `.king/docs/architecture/` creados y verificados
- [ ] **Modo FEATURE**: `design.md` creado + deltas appendeados a docs base
- [ ] Todos los artefactos tienen YAML frontmatter con project/date/author/version
- [ ] Sesión registrada en `.king/sessions/`
- [ ] Próximo paso comunicado

### PROOF OF COMPLETION

Antes de declarar el skill completado, reportar el estado de cada artefacto esperado:

| Artefacto | Estado |
|-----------|--------|
| [nombre del artefacto] | `WRITTEN` / `PRESENTED` / `FAILED` |

**Estados posibles:**
- `WRITTEN` — artefacto escrito en disco con Write tool
- `PRESENTED` — artefacto presentado como bloque copiable en la conversación (plan mode)
- `FAILED` — artefacto no generado ni presentado (error o skip no justificado)

Si algún artefacto tiene estado `FAILED`, explicar la causa. No usar la palabra "completado" hasta que todos los estados estén reportados.

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

## IF FAILS

> Ver escenarios A/B/C completos: [REFERENCE.md](REFERENCE.md) → sección "IF FAILS"

---

## Ver también

- **Lógica detallada de fases**: `skills/brainstorm/PHASES.md`
- **Templates de artefactos**: `skills/brainstorm/REFERENCE.md`
- **Skill siguiente**: `skills/plan/SKILL.md`
- **Validación**: `validation/VALIDATION.md`
- **Session template**: `skills/session-management/SKILL.md` → "/brainstorm"
