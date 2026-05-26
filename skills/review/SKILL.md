---
name: review
description: "Workflow de revisión de código. Usar cuando se necesite: revisar código, hacer code review, revisar un PR, evaluar calidad de cambios, o dar feedback sobre implementación."
version: 2.0
---

# Code Review — Workflow de Revisión

Workflow estructurado para revisar código con múltiples perspectivas.

> **Path resolution**: Paths `skills/`, `agents/`, `knowledge/`, `rules/` son relativas a KING_FRAMEWORK_PATH (anunciado al inicio de sesión). Prepend ese valor al usar Read.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural context for coherence review | Yes | project |
| `.king/knowledge/conventions.md` | Code and design conventions to verify | Yes | project |
| `knowledge/_inject/security-essentials.md` | Security patterns for the Security Review phase | No | framework |
| `rules/accessibility-gate.md` | Accessibility Gate rules, blocking levels and reporting format | No (frontend only) | framework |
| `rules/token-budget-gate.md` | Token budget check — verifica que skills/agents dentro de umbrales | No (if LOAD-INDEX.md exists) | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No hay código para revisar (no existe diff ni PR)
- [ ] No existe sesión de `/build` previa para el workflow

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA emitir veredicto APPROVED sin haber leído el diff completo
- NUNCA aprobar código con vulnerabilidades de seguridad detectadas, sin importar el deadline

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Review report con veredicto CASTLE C·A·S·T
- [ ] Lista de issues (si los hay) con severidad
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
Load      Context   ArchReview SecReview  QAReview  CASTLE   Report   Session   Guide
```

---

## Agentes involucrados
- **@architect** → Revisa alineación arquitectónica
- **@security** → Busca vulnerabilidades
- **@qa** → Verifica tests y cobertura

## CASTLE: C·A·S·T·_·_ — [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## PHASE ROUTER

> **Excepción v2.0 documentada**: Este skill usa PHASE ROUTER con carga modular por sub-archivos.
> Justificación: entry point ~900 tokens; carga total ~3220 tokens.
> Los sub-archivos se cargan on-demand según la fase activa.

| Fases | Sub-archivo |
|-------|-------------|
| Fases 1-6: Context → Architecture → Security → Quality → CASTLE → Report | [PHASES.md](PHASES.md) |
| Fases 7-8: Write Session + Guide Next Step | inline en este SKILL.md (referencias a session-management) |

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
| Artifacts | _(review report generado, o qa report generado)_ |
| Next Recommended | _(copiar de tabla de flujo)_ |
| Risks | _(listar findings CONDITIONAL o BREACHED, o "None")_ |

---

### Fase 7: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 8: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para review:
| Condición | Próximo Skill |
|-----------|---------------|
| Review APROBADO | `/qa --standard` |
| Review CAMBIOS REQUERIDOS | `/fix` |

---

## REFERENCE

> 📚 Información adicional. Esta sección NO contiene acciones, solo contexto.

### Integración SDD
Este skill puede ejecutarse como parte del pipeline SDD durante la fase `verify`.
Ver `rules.verify.quality_skills` en `.king/sdd/config.yaml`.
Cuando se invoca desde SDD, el scope se limita a los archivos del cambio activo.

---

## Archivos del skill

| Archivo | Contenido |
|---------|-----------|
| `SKILL.md` | Entry point — este archivo (~900t) |
| `PHASES.md` | Fases 1-6: Context, Architecture, Security, Quality, CASTLE, Report |

## Ver también

- `skills/review/PHASES.md` — Lógica detallada de las 6 fases
- `skills/_shared/lifecycle-outputs.md` — Convención de rutas de sesión
- `skills/session-management/SKILL.md` — Phase 0 y Phase N+1
