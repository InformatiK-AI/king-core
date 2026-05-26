# Frontend Design — Phases (v3.0)

> Lógica detallada de las fases 1-6. Entry point: [SKILL.md](SKILL.md)

---

## Fase 1: Inspiración

### GATE IN
- [ ] Fase 0 completada — workflow context cargado
- [ ] Componente o pantalla a diseñar identificado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Seleccionar estilo visual** — fast path primero:
   - Buscar en `design-essentials.md` (slim) el estilo que mejor coincida con tipo+audiencia+industria del proyecto
   - Si hay match → **citar**: `Estilo seleccionado: [name] ([id]) — Criterio: [tipo/audiencia/industria]`
   - Si ningún estilo del slim matchea bien → cargar `knowledge/domain/design/styles.md` completo (57 estilos)
   - Si ningún catálogo disponible → consultar referencias (Dribbble, Behance) y definir estilo manualmente
2. [ ] **Identificar patrones** — Detectar patrones visuales relevantes para el estilo elegido: Bento grids, aurora backgrounds, glassmorphism, micro-interacciones, skeleton loading, scroll animations
3. [ ] **Definir mood board** — Documentar el mood board mental del diseño (estilo, tono, energía) — citar el estilo seleccionado si viene del catálogo

### CHECKPOINT
- [ ] Estilo visual seleccionado — si viene del catálogo, citado con ID y criterio de selección
- [ ] Patrones visuales seleccionados documentados
- [ ] Mood board definido y comunicado al usuario

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Inspiración insuficiente para avanzar
Cause: Sin referencias concretas o sin dirección visual clara
Recovery:
  [ ] Option A: Preguntar al usuario por referencias o ejemplos de diseño que le gusten
  [ ] Option B: Revisar el diseño actual del proyecto y proponer evolución incremental
  [ ] Option C: Proponer 3 estilos diferentes y pedir al usuario que elija dirección

---

## Fase 2: Wireframe

### GATE IN
- [ ] Fase 1 completada — mood board y referencias definidos

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Proponer estructura** — Definir layout principal (ASCII mockup si ayuda a visualizar)
2. [ ] **Jerarquía visual** — Definir qué elemento llama la atención primero, flujo visual del usuario y puntos de acción (CTAs)
3. [ ] **Breakpoints** — Definir responsive breakpoints para el componente (mobile-first)

### CHECKPOINT
- [ ] Layout propuesto documentado
- [ ] Jerarquía visual definida (qué ve el usuario primero)
- [ ] Comportamiento responsive especificado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Wireframe incompleto o sin consenso
Cause: Requerimientos ambiguos o layout inconsistente con el diseño existente
Recovery:
  [ ] Option A: Presentar al usuario 2 opciones de layout y solicitar decisión
  [ ] Option B: Revisar layouts existentes del proyecto como referencia estructural
  [ ] Option C: Simplificar el alcance — diseñar primero la versión mobile, luego expandir

---

## Fase 3: Design

### GATE IN
- [ ] Fase 2 completada — wireframe y layout aprobados

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Color palette** — Tres paths por orden de prioridad:
   - **Prioridad 1 — Si `.king/design/tokens.json` existe** (generado por `/brand-identity`):
     - Usar `color.semantic.background`, `color.semantic.text-primary`, `color.semantic.brand-primary` del tokens.json
     - Citar: `Paleta desde brand-identity tokens.json — brand-primary: [hex], background: [hex]`
   - **Prioridad 2 — Slim fast path** (si no hay tokens.json):
     - Buscar en `design-essentials.md` una paleta con `wcag_aa ≥ 4.5:1` adecuada para el estilo de Fase 1
     - Si hay match → **citar**: `Paleta seleccionada: [name] ([id]) — WCAG estimado: [wcag_aa]`
     - Si ninguna paleta del slim es adecuada → cargar `knowledge/domain/design/palettes.md` completo (95 entradas)
   - **Prioridad 3 — Fallback** (sin catálogos ni tokens.json):
     - Definir paleta coherente con branding existente (ver `.king/knowledge/conventions.md`)
2. [ ] **Tipografía** — Tres paths por orden de prioridad:
   - **Prioridad 1**: Si `tokens.json` existe → usar `typography.fontFamily.heading` y `typography.fontFamily.body`
   - **Prioridad 2**: Buscar en `design-essentials.md` (slim) el pairing adecuado para el estilo; si no matchea → cargar `knowledge/domain/design/font-pairings.md` completo
   - **Prioridad 3**: Definir tipografía manualmente coherente con el proyecto
3. [ ] **Espaciado** — Si `tokens.json` existe: usar `spacing.*`. Si no: 8px grid mínimo.
4. [ ] **Componentes** — Especificar estados visuales: hover, focus, active, disabled
5. [ ] **Estados de UI** — Definir loading (skeleton), error, empty y success states
6. [ ] **Animaciones** — Especificar animaciones CSS (fadeSlideUp, transitions, @keyframes)

### CHECKPOINT
- [ ] Paleta definida — si viene del catálogo o tokens.json, citada con fuente y criterio
- [ ] Tipografía definida — si viene del catálogo o tokens.json, citada con fuente
- [ ] Todos los estados de UI especificados (loading, error, empty, success)
- [ ] Animaciones especificadas con timing y easing

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Design system incompleto
Cause: Falta especificación de estados o inconsistencia con branding existente
Recovery:
  [ ] Option A: Si `tokens.json` existe pero tiene referencias rotas → usar palettes.md como fallback
  [ ] Option B: Revisar paleta del proyecto en `.king/knowledge/conventions.md` y alinear
  [ ] Option C: Omitir estados secundarios y documentarlos como "deferred" en el reporte

---

## Fase 4: Implementation

### GATE IN
- [ ] Fase 3 completada — design system especificado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Implementar estilos** — Usar el sistema de estilos del proyecto (ver `.king/knowledge/stack.md` y `.king/knowledge/conventions.md`)
2. [ ] **Animaciones** — Implementar transiciones y @keyframes según especificación de Fase 3
3. [ ] **Estados interactivos** — Implementar hover/focus/active states con event handlers si aplica
4. [ ] **Accesibilidad** — Verificar: contrast ratio ≥ 4.5:1, focus indicators visibles, aria-labels donde necesario, keyboard navigation funcional

### CHECKPOINT
- [ ] Componente renderiza correctamente
- [ ] Animaciones fluidas (60fps — sin jank)
- [ ] Contrast ratio ≥ 4.5:1 para texto normal
- [ ] Focus indicators visibles en todos los elementos interactivos
- [ ] aria-labels presentes donde el texto visual es insuficiente

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Implementación no cumple criterios de calidad
Cause: Contraste insuficiente, animaciones con jank, o accesibilidad rota
Recovery:
  [ ] Option A (contraste): Ajustar color hasta alcanzar ratio 4.5:1 — usar herramienta: `https://contrast-ratio.com`
  [ ] Option B (jank): Mover animaciones a `transform` y `opacity` (GPU-accelerated), añadir `will-change`
  [ ] Option C (accesibilidad): Agregar aria-labels faltantes y verificar con keyboard Tab navigation

---

## Fase 5: Review

### GATE IN
- [ ] Fase 4 completada — implementación lista

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Evidencia visual** — Capturar screenshot o nota de omisión con justificación

   ---
   **EVIDENCIA VISUAL REQUERIDA** — Ejecutar AHORA:
   > Seguir instrucciones de `skills/visual-evidence/SKILL.md` → Capture Smoke-Test
   Para frontend-design, el escenario Smoke-Test captura fullPage.
   Si se omite, documentar motivo en reporte de sesión.
   ---

2. [ ] **Checklist de calidad** — Verificar: ¿impresiona?, ¿animaciones fluidas?, ¿accesible?, ¿responsive?, ¿consistente con la app?
3. [ ] **Generar reporte** — Completar el Frontend Design Report

### CHECKPOINT
- [ ] Evidencia visual capturada o razón de omisión documentada
- [ ] Todos los ítems del checklist de calidad evaluados
- [ ] Reporte generado con secciones: Componente, Inspiración, Diseño, Accesibilidad, Performance, Evidencia

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Review incompleto o diseño no aprueba calidad
Cause: Diseño no impresiona, animaciones con problemas o accesibilidad rota
Recovery:
  [ ] Option A: Iterar sobre los ítems fallidos del checklist (máx 2 iteraciones)
  [ ] Option B: Escalar a @frontend para segunda opinión sobre calidad visual
  [ ] Option C: Documentar los ítems pendientes en Risks del Execution Summary y proceder con CONDITIONAL

---

## Fase 6: Commit

### GATE IN
- [ ] Fase 5 completada — review aprobado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Staging** — Agregar solo los archivos modificados para este componente
2. [ ] **Commit** — Crear commit con conventional commit format: `feat(ui): [descripción del diseño]`
3. [ ] **Push** — Pushear branch al remote

### CHECKPOINT
- [ ] Commit creado con mensaje descriptivo (conventional commit)
- [ ] Solo archivos del componente incluidos (no archivos no relacionados)
- [ ] Branch pusheado al remote

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Commit o push fallido
Cause: Archivos unstaged, branch sin upstream, o conflictos de merge
Recovery:
  [ ] Option A: `git status` para ver archivos pendientes, añadir explícitamente y reintentar
  [ ] Option B: `git push -u origin {branch}` para crear upstream si no existe
  [ ] Option C: Resolver conflictos manualmente y reintentar el push
