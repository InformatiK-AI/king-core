---
name: qa-env
description: "QA con verificación de ambiente. Usar cuando se necesite: QA en un ambiente específico, verificar ambiente QA o producción, validar deploy, o hacer quality assurance con smoke tests de ambiente."
version: 2.0
internal: true
---

# QA Env — QA con Verificación de Ambiente

Todo lo de QA Standard más verificación completa del ambiente desplegado.

## Agentes involucrados
- **@qa** → Verificaciones de calidad
- **@security** → Security Gate
- **@devops** → Verificación de ambiente

## CASTLE: C·A·S·T·L·E — FORTIFIED [ver capas en `skills/_shared/castle-capas.md`]

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

---

## Fases

### Fases 1-4: Igual que QA Standard
Ejecutar las fases de Strategy, Execution, Coverage y Security Gate de qa.

### Fase 5: Environment Verification (via @devops)
1. **Smoke tests**: Verificar que la aplicación funciona en el ambiente target
   ```bash
   # Health check
   curl -s http://localhost:[PORT]/api/health
   # Frontend
   curl -s http://localhost:[VITE_PORT]/ | head -5
   ```
2. **Environment parity**: Verificar variables de entorno
   - PORT correcto para el ambiente
   - DATABASE_URL apunta a la DB correcta
   - CORS_ORIGIN configurado para el ambiente
3. **Post-deploy health**: Verificar todos los endpoints responden
4. **Rollback readiness**: Verificar que se puede volver atrás
5. **Smoke test visual del ambiente**:

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Smoke-Test
   Para qa-env, el escenario Smoke-Test captura adicionalmente el selector de idiomas.
   Si se omite, documentar motivo en reporte de sesión.
   ---

### Fase 6: CASTLE Full
1. Ejecutar CASTLE completo (6 capas incluyendo E-Environment)

### Fase 7: Report
```
## QA Environment Report

### Ambiente: [dev|qa|prod]
### URL: http://localhost:[port]

### Standard QA
[Resultado de qa]

### Environment Checks
- [ ] Health endpoint: [OK|FAIL]
- [ ] Frontend carga: [OK|FAIL]
- [ ] Proxy funciona: [OK|FAIL]
- [ ] Variables correctas: [OK|FAIL]
- [ ] Rollback posible: [YES|NO]

### Evidencia Visual
[Tabla generada según `skills/visual-evidence/SKILL.md` → Formato de reporte de evidencia]

### CASTLE Score: [FORTIFIED|CONDITIONAL|BREACHED]
### Veredicto: [APROBADO|OBSERVACIONES|RECHAZADO]
```

---

### Fase 8: Write Session

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### Fase 9: Guide Next Step

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para qa-env:
| Condición | Próximo Skill |
|-----------|---------------|
| CASTLE FORTIFIED | `/release` |
| CASTLE BREACHED | `/fix` → repetir `/qa --env` |
