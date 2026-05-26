---
name: qa-batch
description: "QA extensivo para batch de issues antes de promover a QA. Usar cuando se necesite: validar un conjunto de issues, QA para promote, verificar batch pre-promote, o evaluar múltiples cambios juntos antes de avanzar a QA."
version: 2.0
internal: true
---

# QA Batch — Validación de Batch de Issues

Evaluación extensiva de un conjunto de issues/PRs antes de promover de develop a QA.

## Agentes involucrados
- **@qa** → Verificación de calidad por issue
- **@security** → Security Gate sobre diff acumulado
- **@devops** → Verificación de ambiente QA
- **@architect** → Verificación de drift arquitectónico

## CASTLE: C·A·S·T·L·E — FORTIFIED [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### Fase 1: Issue Collection
1. Listar todos los issues/PRs incluidos en el batch
2. Para cada issue, obtener:
   - Título y descripción
   - Acceptance criteria
   - Archivos modificados
   - Tests asociados
3. Crear checklist del batch

### Fase 2: Dependency Check
1. Verificar que no hay dependencias circulares entre issues
2. Verificar que cambios de un issue no rompen otro
3. Verificar que no hay conflictos de merge entre PRs

### Fase 3: Per-Issue QA
Para cada issue en el batch:
1. Verificar ACs cumplidos
2. Verificar tests escritos y pasando
3. Verificar convenciones del proyecto
4. Verificar i18n si aplica
5. Verificar no regresiones con tests existentes
6. Si el issue tiene representación UI, captura visual:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture QA-Execution
   Si se omite, documentar motivo en reporte de sesión.
   ---

### Fase 4: Integration Testing
1. Tests de integración cross-issue:
   - ¿Las features interactúan correctamente?
   - ¿Los cambios en pipeline son coherentes entre sí?
   - ¿El servidor inicia con todos los cambios aplicados?
2. Build completo:
   ```bash
   cd [project-root] && npm run build 2>&1
   ```
3. Smoke test visual de integración:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Smoke-Test
   Si se omite, documentar motivo en reporte de sesión.
   ---

### Fase 5: Security Gate
1. Ejecutar Security Gate sobre el diff acumulado (develop vs último promote)
2. Verificar que ningún issue introduce vulnerabilidades

### Fase 6: Architecture Review (via @architect)
1. Verificar que el batch no introduce drift arquitectónico
2. Verificar que dependency direction se mantiene
3. Verificar que patrones son consistentes

### Fase 7: CASTLE Full
1. Ejecutar CASTLE completo (6 capas)
2. Resultado determina la decisión de promote

### Fase 8: Promote Decision
| CASTLE | Decisión |
|--------|----------|
| FORTIFIED | Auto-promote a QA |
| CONDITIONAL | Revisión manual requerida |
| BREACHED | BLOQUEADO — resolver issues primero |

### Fase 9: GitHub Integration
1. Crear PR de develop → qa branch (si procede)
2. Comentar reporte CASTLE en el PR
3. Listar issues incluidos en el body del PR

### Fase 10: Report
```
## QA Batch Report

### Batch: [fecha o sprint]
### Issues incluidos: [N]

| Issue | Título | QA | Tests | i18n |
|-------|--------|----|-------|------|
| #1 | ... | PASS/FAIL | PASS/FAIL | PASS/N/A |
| #2 | ... | PASS/FAIL | PASS/FAIL | PASS/N/A |

### Integration: [PASS|FAIL]
### Security Gate: [SECURE|REVIEW|VULNERABLE]
### CASTLE Score: [FORTIFIED|CONDITIONAL|BREACHED]

### Evidencia Visual
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### Decisión: [AUTO-PROMOTE|MANUAL-REVIEW|BLOCKED]
```

---

### Fase 11: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 12: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para qa-batch:
| Condición | Próximo Skill |
|-----------|---------------|
| CASTLE FORTIFIED | `/promote --to qa` (automático) |
| CASTLE CONDITIONAL | `/promote --to qa` (con review) |
| CASTLE BREACHED | `/fix` por blocker → repetir `/qa --batch` |
