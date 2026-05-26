---
name: test-plan
version: 2.0
description: "Generador de planes de pruebas HTML interactivos. Usar cuando se necesite: crear plan de pruebas, generar test plan HTML, documentar casos de prueba, generar reporte de QA, crear suite de testing estructurada, exportar plan pruebas con tema King."
---

# /test-plan — Generador de Planes de Pruebas HTML

Genera HTMLs auto-contenidos (~2800 lineas) con planes de pruebas interactivos, tema King "Dark Royalty", persistencia localStorage, evidencia fotografica, export JSON y print A4.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/conventions.md` | Code style and naming conventions for test generation | Yes | project |
| `knowledge/_inject/testing-essentials.md` | Testing strategies, patterns and coverage requirements | No | framework |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Condiciones que DETIENEN la ejecucion inmediatamente

- [ ] Sin fuente de datos: no se proporcionó `--gherkin`, ni `--feature` apuntando a codebase analizable, ni descripcion de modulos manual
- [ ] No existe sesion previa de `/genesis` en el proyecto

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA continuar si el CASTLE Assessment retorna BREACHED
- NUNCA generar escenarios de test sin criterios de aceptación verificables
- NUNCA omitir escenarios de edge cases o error paths del test plan

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convencion de rutas de sesion

- [ ] `.king/docs/test-plans/{slug}-test-plan.html` — HTML SPA auto-contenido del plan de pruebas
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7
(Context) (Discover)(Analyze)(Compose)(Generate)(Verify)(Session)(Guide)
```

### PARAMETROS
```
/test-plan --mode single|consolidated --feature <name> --role <name> --gherkin <path>
```
- `--mode single`: Un rol, un plan
- `--mode consolidated`: Multiples roles/modulos en un solo HTML
- `--feature <name>`: Nombre del feature/sistema a testear
- `--role <name>`: Rol del ejecutor (admin, user, supervisor, etc.)
- `--gherkin <path>`: Ruta a archivo .feature con escenarios Gherkin a parsear

---

## CASTLE activo: C-A-S-T-_-_

## Agentes
- **@qa** — Agente principal: define modulos, casos, criterios
- **@developer** — Analisis de codebase para inferir casos de prueba
- **@frontend** — Verificacion visual del HTML generado

---

## Fase 0: Load Context

> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase 0

Resumen: Display header → Verificar `.king/` → Detectar/crear workflow → Cargar `context.md` → Inyectar contexto.

---

## Fase 1: Discover

### GATE IN
- [ ] Argumentos proporcionados o defaults asumibles
- [ ] Al menos una fuente de datos presente

### MUST DO
1. [ ] **Parsear argumentos**: extraer `--mode`, `--feature`, `--role`, `--gherkin` del input
2. [ ] **Detectar modo**: si `--mode` no especificado, preguntar al usuario (single vs consolidated)
3. [ ] **Validar feature name**: si no hay `--feature`, preguntar. Generar `slug` (kebab-case lowercase)
4. [ ] **Validar fuente de datos**: verificar que existe `--gherkin` path O que el codebase es analizable
5. [ ] **Definir output path**: `.king/docs/test-plans/{slug}-test-plan.html`

### CHECKPOINT
- [ ] `mode` definido (single | consolidated)
- [ ] `feature` y `slug` definidos
- [ ] `slug` coincide con `/^[a-z0-9-]+$/`
- [ ] Al menos una fuente de datos confirmada

### OUTPUTS
- Variables: `MODE`, `FEATURE`, `SLUG`, `ROLE`, `GHERKIN_PATH`, `OUTPUT_PATH`

### IF FAILS
```
ERROR: Sin fuente de datos.
Proporcionar al menos uno de:
  --gherkin <path>   Archivo .feature con escenarios
  --feature <name>   Para analisis de codebase
O describir manualmente los modulos a testear.
```

---

## Fase 2: Analyze (@developer + @qa)

### GATE IN
- [ ] Variables de Fase 1 definidas
- [ ] Fuente de datos validada

### MUST DO
1. [ ] **Si `--gherkin`**: Parsear archivo .feature usando reglas de Fragment 5 (REFERENCE.md):
   - Feature → nombre del Modulo
   - Scenario → TestCase desc
   - Given → prereqs
   - When + And → steps[]
   - Then + And → expected
   - Tags → clasificacion (@critical→severity HIGH, @security→category Security, etc.)
2. [ ] **Si codebase**: @developer explora rutas/componentes del feature para inferir casos de prueba
3. [ ] **AI-generar casos adicionales**: @qa infiere casos de borde, negativos, seguridad no cubiertos por Gherkin
4. [ ] **Asignar metadata** a cada caso: severity (HIGH/MED/LOW), priority (P1-P3), category, coverageType
5. [ ] **Construir borrador MODULES[]**: agrupar casos por modulo/feature

### CHECKPOINT
- [ ] Al menos 1 modulo con al menos 1 caso de prueba
- [ ] Cada caso tiene: desc, steps[], expected, severity, priority

### OUTPUTS
- Borrador `MODULES[]` en memoria

### IF FAILS
```
ERROR: No se pudieron inferir casos de prueba.
Opciones:
  - Verificar que el path --gherkin existe y es legible
  - Si es codebase: verificar que --feature apunta a rutas existentes
  - Describir modulos manualmente al agente @qa
```

---

## Fase 3: Compose (@qa)

### GATE IN
- [ ] Borrador MODULES[] construido

### MUST DO
1. [ ] **Aplicar schema completo** de Fragment 4 (REFERENCE.md) a cada modulo y caso
2. [ ] **Asignar colorClass** a cada modulo: `m01`-`m12` ciclicamente (`'m' + ((index % 12) + 1).toString().padStart(2,'0')`)
3. [ ] **Presentar resumen al usuario**:
   ```
   Modulos: N | Casos totales: M | Alta prioridad: X
   [tabla: modulo, casos, severidades]
   ```
4. [ ] **Esperar aprobacion** del usuario antes de generar HTML
5. [ ] **Incorporar ajustes** del usuario si los hay

### CHECKPOINT
- [ ] Usuario aprobó la composicion
- [ ] MODULES[] final validado contra schema de Fragment 4

### OUTPUTS
- `MODULES[]` final aprobado

### IF FAILS
```
WARN: Usuario no aprobó la composicion.
Opciones:
  - Ajustar modulos/casos segun feedback del usuario
  - Volver a Fase 2 si se requiere re-analisis del codebase
  - Si el usuario cancela: terminar sesion sin generar HTML
```

---

## Fase 4: Generate (@developer)

> SEGURIDAD OBLIGATORIA: HTML entity encoding en toda interpolacion de datos de usuario

### GATE IN
- [ ] MODULES[] aprobado por usuario

### MUST DO
1. [ ] **Leer Fragment 1** (CSS) de REFERENCE.md — usar verbatim en `<style>`
2. [ ] **Leer Fragment 2** (HTML Structure) de REFERENCE.md — usar como skeleton
3. [ ] **Leer Fragment 3** (JavaScript Engine) de REFERENCE.md — adaptar con MODULES[] real
4. [ ] **Reemplazar `{{PLACEHOLDER}}`** en el HTML con datos del feature/rol/fecha
5. [ ] **HTML ENTITY ENCODING OBLIGATORIO**: toda interpolacion de datos en HTML DEBE usar `escapeHtml()`. Ver Fragment 3 para implementacion. No usar funciones de ejecucion dinamica de codigo. Usar `JSON.parse()` para parsing de datos, nunca ejecucion de strings como codigo.
6. [ ] **Embeber MODULES[]** en el HTML como `window.__SEED__ = { modules: [...] }`
7. [ ] **Verificar**: 0 dependencias externas excepto Google Fonts en `<link>`
8. [ ] **Escribir output** con Write tool a `.king/docs/test-plans/{slug}-test-plan.html`

### CHECKPOINT
- [ ] Archivo HTML escrito en output path
- [ ] `escapeHtml()` presente y usada en toda interpolacion dinamica
- [ ] No se usan funciones de ejecucion dinamica de codigo en el JS generado
- [ ] `JSON.parse()` usado para parsing de datos
- [ ] Cada `localStorage.setItem` esta dentro de `try { } catch (e) { }`

### OUTPUTS
- `.king/docs/test-plans/{slug}-test-plan.html`

### IF FAILS
```
ERROR: Falla al generar HTML.
Verificar: MODULES[] valido, paths correctos, write permissions en .king/docs/test-plans/
```

---

## Fase 5: Verify (@frontend via Playwright)

### GATE IN
- [ ] HTML generado en output path

### MUST DO
1. [ ] **Abrir en Playwright**: navegar al archivo HTML local
2. [ ] **Screenshot del plan**: capturar estado inicial
3. [ ] **Verificar consola**: 0 errores JavaScript
4. [ ] **Verificar render**: portada visible, modulos cargados, stats en 0
5. [ ] **Verificar localStorage**: cambiar un status radio, verificar que persiste

### CHECKPOINT
- [ ] Screenshot capturado en `.king/sessions/evidence/`
- [ ] 0 errores de consola
- [ ] HTML renderiza correctamente

### OUTPUTS
- Screenshot en `.king/sessions/evidence/YYYY-MM-DD_NNN_test-plan_{context}/`

### IF FAILS
```
WARN: Verificacion visual no completada.
Documentar motivo en session document:
  - Archivo local sin server HTTP
  - Playwright no disponible
  - Error de consola: [detallar]
```

---

## Fase 6: Write Session

### GATE IN
- [ ] HTML generado y verificado (o verificacion documentada con WARN)

### MUST DO
> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+1

### CHECKPOINT
- [ ] Session document creado en `.king/sessions/`
- [ ] Session registrada en registry.md

---

## Fase 7: Guide Next Step

### GATE IN
- [ ] Session document escrito (Fase 6 completada)

### MUST DO
> Seguir instrucciones de `skills/session-management/SKILL.md` → Phase N+2

Tabla de flujo para test-plan:

| Condicion | Proximo Skill |
|-----------|---------------|
| HTML generado y verificado | Skill completado — entregar al usuario |
| Errores en HTML | Regenerar (volver a Fase 4) |
| Playwright fallo | Documentar y completar con WARN |

### CHECKPOINT
- [ ] Proximo paso comunicado al usuario

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] `.king/docs/test-plans/{slug}-test-plan.html` existe y tiene contenido
  - [ ] Session document creado en `.king/sessions/`
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] `escapeHtml()` presente en el HTML generado
- [ ] `try/catch` en localStorage en el HTML generado
- [ ] Session registrada en registry.md

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

## REFERENCE

> Informacion adicional para entender el skill. Esta seccion NO contiene acciones.

### Correspondencia de Placeholders

Los `{{PLACEHOLDER}}` de Fragment 2 (HTML) y Fragment 3 (JS) usan nombres distintos para el mismo dato:

| Fragment 2 (HTML) | Fragment 3 (JS storage key) | Dato |
|-------------------|-----------------------------|------|
| `{{ROLE_NAME}}`   | `{{ROLE}}`                  | Nombre del rol ejecutor (ej: "admin") |
| `{{FEATURE_NAME}}`| `{{SLUG}}`                  | Identificador del feature (ej: "auth-module") |
| `{{DATE_ISO}}`    | —                           | Fecha ISO (`YYYY-MM-DD`) para `<input type="date">` |
| `{{DATE_DISPLAY}}`| —                           | Fecha legible para el footer (ej: "27 de marzo de 2026") |

Al reemplazar placeholders en Fase 4, aplicar ambas variantes al mismo valor.

---

### Casos Edge

**Sin Gherkin, sin codebase**: El usuario puede describir manualmente los modulos. @qa los estructura en MODULES[].

**Modulos > 12**: El color ciclico garantiza que modulo 13 = m01, 14 = m02, etc. Formula: `'m' + ((index % 12) + 1).toString().padStart(2,'0')`

**Modo consolidated**: Multiples roles en un solo HTML. Cada rol tiene su propio set de MODULES[] filtrable.

### Dependencias del HTML Generado
- Google Fonts (DM Sans + JetBrains Mono): unica dependencia externa
- 0 frameworks JS (vanilla JS puro)
- 0 CSS frameworks (CSS custom properties)
- localStorage para persistencia (funciona offline)

### Integraciones
- Invocado desde `/qa` cuando se necesita plan de pruebas formal
- Output referenciado en `/review` para evidencia visual
- Session tracking via `session-management`
