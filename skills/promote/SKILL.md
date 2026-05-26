---
name: promote
description: "Promoción entre ambientes con worktree. Usar cuando se necesite: promover a QA, promover a producción, deploy entre ambientes, sincronizar worktrees, o mover código de develop a qa o de qa a prod."
version: 2.0
---

# Promote — Promoción entre Ambientes

Workflow para promover código entre ambientes (develop → qa → prod) usando worktrees.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/environments.md` | Environment configuration, URLs and deployment targets | Yes | project |
| `knowledge/_inject/observability-essentials.md` | Health check patterns and smoke test strategies | No | framework |
| `rules/accessibility-gate.md` | Accessibility Gate rules, blocking levels and reporting format | No (frontend only) | framework |
| `rules/dr-gate.md` | Disaster Recovery Gate — activation logic, skip conditions, evaluation process and report format | No | framework |
| `rules/health-check-gate.md` | Health Check Gate — activation logic, skip conditions, evaluation process and report format | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] QA batch no ejecutado para el conjunto de features
- [ ] CASTLE BREACHED en cualquier capa evaluada

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA promover a `prod` sin CASTLE FORTIFIED previo
- NUNCA proceder si los smoke tests del ambiente destino fallan
- NUNCA revertir sin documentar el rollback en el reporte de la sesión

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Código promovido al ambiente destino (QA o prod)
- [ ] Smoke tests pasando en el ambiente destino
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
PHASE 1: Readiness → PHASE 1b: DR Gate → PHASE 1c: Health-Check → PHASE 2: Security → PHASE 2b: A11y → PHASE 3: DB Migration → PHASE 4: Env Config → PHASE 5: Deploy
      |                    |                        |                    |                    |                   |                       |                   |
  QA/CASTLE           DR config OK        Health endpoints OK      Security Gate       axe-core/WCAG        DB scripts            .env verified        git sync
      ↓
PHASE 6: Setup → PHASE 7: Smoke Tests → PHASE 8: Health → PHASE 9: GitHub → PHASE 10: Report
```

---

## Agentes involucrados
- **@devops** → Gestión de worktrees y deploy
- **@security** → Security Gate pre-deploy
- **@qa** → Smoke tests post-deploy

## CASTLE activo: _·_·S·_·_·E

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Ambientes

> Valores específicos del proyecto (ports, DB names, URLs) definidos en `.king/knowledge/environments.md`

| Ambiente | Branch | Port | DB | Worktree |
|----------|--------|------|----|----------|
| dev | develop | `{{DEV_PORT}}` | `{{DEV_DB_NAME}}` | .worktrees/environments/dev/ |
| qa | origin/develop | `{{QA_PORT}}` | `{{QA_DB_NAME}}` | .worktrees/environments/qa/ |
| prod | origin/main | `{{PROD_PORT}}` | `{{PROD_DB_NAME}}` | .worktrees/environments/prod/ |

## GATE IN — Pre-conditions para ejecutar /promote
> Si alguna condición no se cumple, DETENER y reportar al usuario.

- [ ] QA batch pasado para el ambiente origen (CASTLE CONDITIONAL mínimo)
- [ ] No hay CASTLE BREACHED activo en el ambiente origen
- [ ] El worktree destino existe y es accesible
- [ ] No hay promotion en curso para el mismo ambiente destino

---

## PHASE ROUTER

> **Excepción v2.0 documentada**: Este skill usa PHASE ROUTER con carga modular por sub-archivos.
> Justificación: entry point ~1200 tokens; carga total ~4170 tokens.
> Los sub-archivos se cargan on-demand según la fase activa.

| Fases | Sub-archivo |
|-------|-------------|
| Fases 1, 1b, 1c, 2, 2b, 3 — Gates de calidad pre-deploy | [PRE-DEPLOY.md](PRE-DEPLOY.md) |
| Fases 4-10 — Ejecución del deploy y verificación | [DEPLOY.md](DEPLOY.md) |

---

## FINAL CHECKPOINT

> Verificar TODOS los items antes de reportar la promotion como exitosa.

- [ ] Worktree destino sincronizado con los cambios del origen
- [ ] Health check del ambiente destino OK
- [ ] Smoke tests pasando en el ambiente destino (si aplica)
- [ ] Reporte de promotion generado
- [ ] Rollback plan documentado (en caso de issues post-promotion)

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

### Fase 11: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 12: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para promote:
| Condición | Próximo Skill |
|-----------|---------------|
| Promote a QA + Health OK | `/qa --env` |
| Promote a Prod + Health OK | `/release` |

---

## Archivos del skill

| Archivo | Contenido |
|---------|-----------|
| `SKILL.md` | Entry point — este archivo (~1200t) |
| `PRE-DEPLOY.md` | Fases 1, 1b, 1c, 2, 2b, 3: todos los gates de calidad antes del deploy |
| `DEPLOY.md` | Fases 4-10: env config, deploy, post-deploy, smoke tests, health, GitHub, report |

## Ver también

- `skills/promote/PRE-DEPLOY.md` — Gates de calidad: Coverage, DR, Health-Check, Security, A11y, DB Migration
- `skills/promote/DEPLOY.md` — Ejecución del deploy y verificación post-deploy
- `skills/_shared/lifecycle-outputs.md` — Convención de rutas de sesión
- `skills/session-management/SKILL.md` — Phase 0 y Phase N+1
