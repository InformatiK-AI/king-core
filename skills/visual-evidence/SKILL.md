---
name: visual-evidence
description: "Skill auxiliar interno. Proporciona instrucciones reutilizables para capturar evidencia visual con Playwright MCP. NO invocar directamente — es referenciado por otros skills."
version: 2.0
api_version: 1.0.0
internal: true
user-invocable: false
---

# Visual Evidence — Captura de Evidencia Visual

> IMPORTANTE: Este skill NO se invoca directamente por el usuario.
> Es referenciado por otros skills usando la sintaxis de delegación por blockquote:
> `> Seguir instrucciones de skills/visual-evidence/SKILL.md → Capture [escenario]`

## URLs de referencia

| Ambiente | Frontend | API Health |
|----------|----------|------------|
| dev | http://localhost:5173 | http://localhost:3001/api/health |
| qa | http://localhost:5174 | http://localhost:3002/api/health |
| prod | http://localhost:5175 | http://localhost:3003/api/health |

## Directorio de evidencia

Path: `.king/sessions/evidence/YYYY-MM-DD_NNNN_[skill-name]/`

- `YYYY-MM-DD`: fecha actual
- `NNNN`: el mismo NNNN del session document asociado (sincronizado con Phase N+1 de session-management)
- `[skill-name]`: nombre del skill que capturó la evidencia
- Archivos PNG con prefijo numérico de 2 dígitos: `01-estado-inicial.png`, `02-accion.png`, `03-resultado.png`

## Verificación de disponibilidad (SIEMPRE ejecutar primero)

Antes de cualquier escenario, verificar si la app está corriendo:

```bash
curl -s --max-time 3 http://localhost:3001/api/health > /dev/null 2>&1 && echo "RUNNING" || echo "NOT_RUNNING"
```

- Si `RUNNING`: ejecutar el escenario de captura correspondiente
- Si `NOT_RUNNING`: registrar `evidencia: N/A (app no iniciada)` en el reporte del skill y continuar sin bloquear. **No fallar, no bloquear el skill llamante.**

---

## Capture QA-Execution

**Usado por**: qa (Fase 2), qa-batch (Fases 3 y 4)
**Propósito**: Evidencia visual de resultados de testing contra la app en ejecución

Pasos:
1. Verificar disponibilidad (ver arriba). Si NOT_RUNNING, omitir y documentar N/A.
2. Crear directorio de evidencia:
   ```bash
   mkdir -p .king/sessions/evidence/YYYY-MM-DD_NNNN_[skill-name]
   ```
3. Navegar a la app:
   - `browser_navigate("http://localhost:5173")`
4. Esperar carga completa:
   - `browser_wait_for(text: "King")`
5. Capturar estado inicial:
   - `browser_take_screenshot(type: "png", filename: ".king/sessions/evidence/[dir]/01-app-cargada.png")`
6. Para cada acceptance criterion que tenga representación visual:
   - Navegar a la sección relevante (si aplica)
   - `browser_wait_for(time: 2)` — esperar estabilidad visual
   - `browser_take_screenshot(type: "png", filename: ".king/sessions/evidence/[dir]/0N-[descripcion-ac].png")`
   - Numerar secuencialmente (02-, 03-, etc.)
7. Si aplica probar el pipeline de migración: iniciar una migración con el test project más simple (REST API JS), esperar resultado visible, capturar:
   - `browser_wait_for(time: 3)` — esperar que la migración complete
   - `browser_take_screenshot(type: "png", filename: ".king/sessions/evidence/[dir]/0N-resultado-migracion.png")`
8. Cerrar el browser:
   - `browser_close()`
9. Listar screenshots capturados:
   ```bash
   ls -la .king/sessions/evidence/[dir]/
   ```
10. Registrar en el reporte del skill llamante usando el formato de la sección "Formato de reporte de evidencia" (ver abajo).

---

## Capture Bug-Reproduction

**Usado por**: fix (Fase 1 — Reproduce)
**Propósito**: Documentar el estado del bug visualmente antes del fix

Pasos:
1. Verificar disponibilidad. Si NOT_RUNNING, omitir y documentar N/A.
2. Crear directorio:
   ```bash
   mkdir -p .king/sessions/evidence/YYYY-MM-DD_NNNN_fix
   ```
3. Navegar a la app:
   - `browser_navigate("http://localhost:5173")`
4. Esperar carga completa:
   - `browser_wait_for(text: "King")`
5. Capturar estado inicial de la app:
   - `browser_take_screenshot(type: "png", filename: "[dir]/01-estado-inicial.png")`
6. Usar `browser_snapshot()` para entender la estructura DOM antes de interactuar — esto ayuda a identificar elementos clickeables y el estado actual de la UI.
7. Reproducir los pasos exactos que causan el bug (según la descripción del issue en Fase 1 del skill fix):
   - Para cada paso de reproducción:
     - Ejecutar la acción (click, navigate, input)
     - `browser_wait_for(time: 2)` — esperar estabilidad
     - `browser_take_screenshot(type: "png", filename: "[dir]/0N-paso-[descripcion].png")`
8. Capturar el estado del bug manifestado:
   - `browser_take_screenshot(type: "png", filename: "[dir]/0N-bug-visible.png", fullPage: true)`
9. Capturar console errors si los hay:
   - `browser_console_messages(level: "error")` — documentar los errores en el Fix Report
10. Cerrar browser:
    - `browser_close()`
11. Registrar paths de screenshots en el Fix Report (sección Evidencia de Reproducción).

---

## Capture Fix-Verification

**Usado por**: fix (Fase 4 — Test)
**Propósito**: Confirmar visualmente que el fix resuelve el bug

Pasos:
1. Verificar disponibilidad. Si NOT_RUNNING, omitir y documentar N/A.
2. Reusar el directorio de Bug-Reproduction si existe (`YYYY-MM-DD_NNNN_fix/`), o crear nuevo si es otra sesión.
3. Navegar a la app:
   - `browser_navigate("http://localhost:5173")`
4. Esperar carga completa:
   - `browser_wait_for(text: "King")`
5. Repetir los mismos pasos de reproducción del bug (de Fase 1):
   - `browser_wait_for(time: 2)` entre cada paso
6. Capturar que el bug YA NO ocurre:
   - `browser_take_screenshot(type: "png", filename: "[dir]/0N-bug-resuelto.png")`
7. Si aplica, capturar la funcionalidad correcta post-fix:
   - `browser_take_screenshot(type: "png", filename: "[dir]/0N-funcionamiento-correcto.png")`
8. Cerrar browser:
   - `browser_close()`
9. Registrar en Fix Report: incluir par "antes/después" con paths de las capturas de Bug-Reproduction y Fix-Verification para comparación visual directa.

---

## Capture Smoke-Test

**Usado por**: qa-env (Fase 5), build (Fase 5), frontend-design (Fase 5), refactor (Fase 4), review (Fase 4)
**Propósito**: Verificación visual rápida de que la app carga y funciona

Pasos:
1. Determinar la URL objetivo según el ambiente activo:
   - dev → http://localhost:5173
   - qa → http://localhost:5174
   - prod → http://localhost:5175
   - Si no se conoce el ambiente, usar dev por defecto.
2. Verificar disponibilidad. Si NOT_RUNNING, omitir y marcar smoke test como N/A.
3. Crear directorio:
   ```bash
   mkdir -p .king/sessions/evidence/YYYY-MM-DD_NNNN_[skill-name]
   ```
4. Navegar a la app:
   - `browser_navigate("[URL del ambiente]")`
5. Esperar carga completa:
   - `browser_wait_for(text: "King")`
6. Capturar home cargado:
   - `browser_take_screenshot(type: "png", filename: "[dir]/01-home-cargado.png")`
7. Verificar panel de migración visible:
   - `browser_snapshot()` — verificar que los elementos del panel existen en el DOM
   - `browser_take_screenshot(type: "png", filename: "[dir]/02-panel-migracion.png")`
8. **Solo para qa-env**: verificar selector de idiomas (i18n):
   - `browser_take_screenshot(type: "png", filename: "[dir]/03-ui-idiomas.png")`
9. **Solo para frontend-design**: capturar pantalla completa para revisión visual:
   - `browser_take_screenshot(type: "png", fullPage: true, filename: "[dir]/03-full-page.png")`
10. Cerrar browser:
    - `browser_close()`
11. Registrar en el reporte del skill llamante.

---

## Formato de reporte de evidencia

Incluir en el reporte del skill llamante la siguiente sección:

```markdown
### Evidencia Visual
| # | Screenshot | Descripción | Estado |
|---|-----------|-------------|--------|
| 1 | .king/sessions/evidence/[dir]/01-app-cargada.png | App cargada correctamente | OK |
| 2 | .king/sessions/evidence/[dir]/02-panel-migracion.png | Panel de migración visible | OK |
| N | N/A | App no iniciada al momento de captura | SKIP |

Directorio: `.king/sessions/evidence/YYYY-MM-DD_NNNN_[skill-name]/`
Total screenshots: [N]
```
