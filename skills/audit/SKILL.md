---
name: audit
version: 2.0
description: "Auditoria comprehensiva del framework. Detecta inconsistencias, verifica comunicacion agent-skill, y genera backlog de mejoras."
---

# Audit - Framework Quality Audit

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/architecture.md` | Architectural patterns and component inventory for audit assessment | Yes | project |
| `.king/knowledge/conventions.md` | Code style and structural conventions to validate during audit | Yes | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Si alguna es TRUE, la auditoria no puede completarse

- [ ] `.king/` no existe (ejecutar `/genesis` primero para inicializar el framework)
- [ ] Menos de 50% de componentes core encontrados (core = agents/, skills/, rules/, knowledge/, validation/, security/: 6 directorios)
- [ ] Error de acceso a filesystem durante auditoria

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA reportar un Health Score sin calcular todas las métricas especificadas
- NUNCA omitir issues de severidad CRITICAL o HIGH del reporte final
- NUNCA ejecutar en modo `--dry-run` sin notificarlo explícitamente al usuario

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] `.king/docs/audits/YYYY-MM-DD-audit-report.md`
- [ ] `.king/docs/audits/YYYY-MM-DD-improvement-backlog.md`
- [ ] Health Score calculado y comunicado (registrado en reporte y sesión)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
PHASE 1 -> PHASE 2 -> PHASE 3 -> PHASE 4 -> PHASE 5 -> PHASE 6 -> PHASE 7
INVENTORY   FORMAT    CROSS-REF   QUALITY    COMMS     EFFICIENCY  REPORT
    |          |          |          |          |           |          |
Existencia Compliance Referencias Claridad  Handoffs   Duplicados  Backlog
de archivos v2.0/RADAR cruzadas   ACs       Escalation Token       priorizado
                                                       (Budget
                                                        Gate)
```

### PARAMETERS
| Parametro | Descripcion | Default |
|-----------|-------------|---------|
| `--scope {full\|quick}` | Profundidad de auditoria | `full` |
| `--focus {agents\|skills\|security\|quality\|all}` | Area especifica | `all` |
| `--dry-run` | Preview sin escribir reportes | `false` |
| `--fix-suggestions` | Incluir snippets de codigo para fixes | `true` |

### HEALTH SCORE FORMULA
```
health_score = (
  inventory_complete * 20 +
  format_compliant * 20 +
  cross_refs_valid * 20 +
  instructions_quality * 15 +
  communication_complete * 15 +
  efficiency_score * 10  # incluye Performance Budget Gate (token budget via LOAD-INDEX.md)
                         # ver rules/token-budget-gate.md y skills/audit/PHASES.md Phase 6.2
) / 100

Penalties: CRITICAL -10%, HIGH -3%, MEDIUM -1%
```

### RESULTADO FINAL
| Score | Resultado | Criterio |
|-------|-----------|----------|
| 95-100% | PASSED | No CRITICAL, <=2 HIGH |
| 80-94% | PARTIAL | No CRITICAL, <=5 HIGH |
| 60-79% | NEEDS WORK | <=1 CRITICAL |
| <60% | FAILED | >1 CRITICAL o issues estructurales |

---

## PARAMETER VALIDATION

> Ver: [PHASES.md](PHASES.md) → sección "PARAMETER VALIDATION"

---

## PHASES 1-7: ANALYSIS + REPORT

> Cargar: [PHASES.md](PHASES.md)

Contiene las fases de analisis con sus GATE IN, MUST DO, CHECKPOINT, IF FAILS:
- PHASE 1: INVENTORY - Verificar existencia de componentes
- PHASE 2: FORMAT COMPLIANCE - Validar templates v2.0 y RADAR
- PHASE 3: CROSS-REFERENCE VALIDATION - Verificar referencias cruzadas
- PHASE 4: INSTRUCTION QUALITY - Evaluar claridad de instrucciones
- PHASE 5: COMMUNICATION VALIDATION - Verificar protocolos agent-skill
- PHASE 6: EFFICIENCY ANALYSIS - Detectar duplicaciones, optimizar tokens

---

## PHASE 7: REPORT GENERATION

> Cargar: [PHASES.md](PHASES.md) → sección "PHASE 7: REPORT GENERATION"

Genera Health Score final, reporte `.king/docs/audits/YYYY-MM-DD-audit-report.md`,
backlog `.king/docs/audits/YYYY-MM-DD-improvement-backlog.md` y sesión de auditoría.

---

## REFERENCE

> Cargar: [REFERENCE.md](REFERENCE.md)

Contiene: Tabla de severidades, issues conocidos (baseline), patrones de deteccion, comandos utiles post-auditoria.

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] Todas las fases ejecutadas segun `--scope`
- [ ] Health score calculado correctamente
- [ ] Reporte principal generado (si no `--dry-run`)
- [ ] Backlog priorizado generado (si no `--dry-run`)
- [ ] Sesion registrada
- [ ] Resultado comunicado: `PASSED` | `PARTIAL` | `NEEDS WORK` | `FAILED`

**Output final:**
```
Auditoria Completada

Health Score: {score}%
Resultado: {resultado}

Resumen:
   - CRITICAL: {N}
   - HIGH: {N}
   - MEDIUM: {N}
   - LOW: {N}

Archivos generados:
   - .king/docs/audits/{fecha}-audit-report.md
   - .king/docs/audits/{fecha}-improvement-backlog.md
   - .king/sessions/{fecha}-audit.md

Proximos pasos:
   {si CRITICAL} -> Resolver issues criticos antes de continuar desarrollo
   {si HIGH} -> Revisar backlog y priorizar fixes
   {si PASSED} -> Framework en buen estado, continuar con flujo normal
```

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

### Phase N+1: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Phase N+2: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para audit:
| Condición | Próximo Skill |
|-----------|---------------|
| Health Score ≥ 80% (PASSED) | `/brainstorm` — continuar con ciclo normal |
| Health Score 60-79% (PARTIAL) | `/fix` o `/refactor` — priorizar según backlog |
| Health Score < 60% (NEEDS WORK) | Revisar backlog en `.king/docs/audits/` — resolver CRITICAL/HIGH primero |

## Archivos del skill

| Archivo | Contenido | Descripcion |
|---------|-----------|-------------|
| `SKILL.md` | Router, QUICK REFERENCE, pointers a sub-archivos | Este archivo (~230 lineas) |
| `PHASES.md` | Fases 1-6 con GATE IN, MUST DO, CHECKPOINT, IF FAILS | Fases de analisis (~350 lineas) |
| `REFERENCE.md` | Severidades, issues baseline, patrones, comandos | Material de referencia (~150 lineas) |

---

## Ver también

- **CLAUDE.md**: Documentacion principal del framework
- **Validacion**: `validation/VALIDATION.md`
- **Security Gate**: `security/SECURITY-GATE.md`
- **RADAR Protocol**: `agents/_common/protocols/radar.md`
- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Session Template**: `skills/session-management/SKILL.md`
