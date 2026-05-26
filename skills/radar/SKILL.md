---
name: radar
description: "Protocolo de razonamiento RADAR para toma de decisiones estructurada. Usar cuando se necesite analizar antes de actuar, razonar sobre alternativas, o tomar decisiones arquitectónicas."
version: "2.0"
---

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/_inject/prompt-engineering-essentials.md` | Structured reasoning techniques for analysis and decision-making | No | framework |

> **Nota**: RADAR es un protocolo de razonamiento, no un skill de implementación. No requiere knowledge injection del proyecto para operar.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se especificó una tarea, decisión o cambio a analizar

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA actuar (Phase A-Act) sin haber completado Read → Analyze → Decide en orden
- NUNCA tomar una decisión sin generar al menos 2 alternativas (Phase A-Analyze)
- NUNCA elegir una alternativa por facilidad sin justificación explícita (Phase D-Decide)
- NUNCA omitir el reporte final (Phase R-Report)

### REQUIRED OUTPUTS
> 📦 Ver `skills/_shared/lifecycle-outputs.md` para la convención de rutas de sesión

- [ ] Análisis de alternativas documentado (Phase A-Analyze)
- [ ] Decisión con justificación explícita (Phase D-Decide)
- [ ] Reporte RADAR completo (Phase R-Report)
- [ ] Session document creado (via session-management Phase N+1) — opcional en uso embebido

### PHASES OVERVIEW

```
Phase 0: Load Context (opcional en uso embebido)
Phase R: Read         → leer contexto y archivos afectados
Phase A: Analyze      → generar y evaluar alternativas
Phase D: Decide       → seleccionar con justificación
Phase A: Act          → ejecutar en pasos incrementales
Phase R: Report       → comunicar resultado completo
FINAL CHECKPOINT
Execution Summary
Phase N+1: Write Session (opcional en uso embebido)
```

---

## CASTLE: _·A·_·_·_·_ — [ver capas en `skills/_shared/castle-capas.md`]

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` Phase 0
> **Opcional en uso embebido**: Cuando RADAR se usa dentro de otro skill, Phase 0 ya fue ejecutado.

---

## Phase R: Read (Leer)

**Objetivo**: Comprender completamente el contexto antes de actuar.

### GATE IN
- [ ] Fase 0 completada (o embebido en otro skill)
- [ ] Tarea o decisión a analizar identificada

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **CLAUDE.md** — Leer convenciones vigentes del proyecto
2. [ ] **Archivos afectados** — Leer todos los archivos que se van a modificar
3. [ ] **Issues/PRs** — Leer issues o PRs relacionados si aplica
4. [ ] **Dependencias** — Identificar dependencias upstream y downstream del código afectado
5. [ ] **Knowledge base** — Revisar knowledge base del framework si aplica (`knowledge/*.md`)

### CHECKPOINT
- [ ] ¿Leí todos los archivos que voy a modificar?
- [ ] ¿Entiendo la arquitectura actual?
- [ ] ¿Conozco las convenciones del proyecto?
- [ ] ¿Identifiqué dependencias upstream y downstream?

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Contexto insuficiente para tomar decisión
Cause: Archivos no encontrados, arquitectura no comprendida, o dependencias no mapeadas
Recovery:
  [ ] Option A: Leer archivos adicionales — usar Glob/Grep para encontrar archivos relacionados
  [ ] Option B: Preguntar al usuario clarificaciones sobre la arquitectura o el contexto
  [ ] Option C: Documentar las dudas y proceder con los supuestos explícitamente declarados

---

## Phase A: Analyze (Analizar)

**Objetivo**: Generar alternativas viables y evaluar trade-offs.

### GATE IN
- [ ] Phase R completada — contexto comprendido

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Alternativas** — Generar mínimo 2-3 alternativas de implementación
2. [ ] **Trade-offs** — Para cada alternativa documentar Pros, Contras, Impacto y Riesgo
3. [ ] **Pipeline** — Considerar impacto en el pipeline del proyecto
4. [ ] **i18n** — Evaluar impacto en i18n si el proyecto lo usa

   ```
   Alternativa 1: [nombre descriptivo]
     Pros: ...
     Contras: ...
     Impacto: [archivos afectados]
     Riesgo: BAJO|MEDIO|ALTO

   Alternativa 2: [nombre descriptivo]
     Pros: ...
     Contras: ...
     Impacto: [archivos afectados]
     Riesgo: BAJO|MEDIO|ALTO
   ```

### CHECKPOINT
- [ ] Al menos 2 alternativas documentadas con Pros/Contras/Impacto/Riesgo
- [ ] Impacto en pipeline evaluado
- [ ] Análisis presentado al usuario si aplica

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Menos de 2 alternativas identificadas
Cause: Problema demasiado específico o falta de contexto para generar opciones
Recovery:
  [ ] Option A: Volver a Phase R para leer más contexto y patrones existentes
  [ ] Option B: Generar una alternativa "hacer nada" como punto de comparación
  [ ] Option C: Preguntar al usuario si conoce alternativas ya consideradas

---

## Phase D: Decide (Decidir)

**Objetivo**: Elegir la mejor alternativa con justificación clara.

### GATE IN
- [ ] Phase A completada — alternativas evaluadas

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Seleccionar** — Elegir la alternativa con mejor balance riesgo/beneficio
2. [ ] **Justificar** — Documentar la justificación explícitamente (no "porque es más fácil")
3. [ ] **Condiciones** — Identificar condiciones que invalidarían la decisión
4. [ ] **ADR** — Si la decisión es arquitectónica, registrarla como ADR

   ```
   DECISIÓN: Alternativa [N] - [nombre]
   JUSTIFICACIÓN: [por qué esta y no las otras]
   CONDICIONES DE INVALIDACIÓN: [cuándo reconsiderar]
   REVERSIBILIDAD: FÁCIL|MODERADA|DIFÍCIL
   ```

### CHECKPOINT
- [ ] Alternativa seleccionada con justificación documentada
- [ ] Condiciones de invalidación identificadas
- [ ] ADR creado si el cambio es arquitectónico

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Decisión sin justificación suficiente
Cause: Análisis insuficiente o alternativas no diferenciadas
Recovery:
  [ ] Option A: Regresar a Phase A para profundizar el análisis de trade-offs
  [ ] Option B: Escalar a @architect para decisiones con impacto arquitectónico significativo
  [ ] Option C: Documentar la incertidumbre explícitamente y proceder con la opción de menor riesgo

---

## Phase A: Act (Actuar)

**Objetivo**: Ejecutar la decisión con verificación incremental.

### GATE IN
- [ ] Phase D completada — decisión tomada y justificada

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Incremental** — Implementar en pasos pequeños y verificables
2. [ ] **Verificar** — Después de cada paso, verificar que no se rompió nada
3. [ ] **Convenciones** — Seguir convenciones del proyecto (ver CLAUDE.md)
4. [ ] **i18n** — Mantener i18n consistente si se agregan strings
5. [ ] **Commits** — Hacer commits incrementales con conventional commits

   Principios:
   - **Incremental**: Cambios pequeños, verificados uno a uno
   - **Reversible**: Cada paso debe poder deshacerse
   - **Observable**: Los cambios deben ser verificables inmediatamente
   - **Consistente**: Seguir patrones existentes del codebase

### CHECKPOINT
- [ ] Implementación completada en pasos verificados
- [ ] Ningún comportamiento existente roto
- [ ] Commits incrementales realizados
- [ ] Convenciones del proyecto respetadas

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Implementación produce regresión o viola convenciones
Cause: Cambio demasiado amplio o supuestos incorrectos de la Phase D
Recovery:
  [ ] Option A: Revertir el último paso (`git revert` o `git reset`) y reimplementar más incrementalmente
  [ ] Option B: Regresar a Phase D con el nuevo contexto y reconsiderar la decisión
  [ ] Option C: Escalar al usuario con los hallazgos antes de continuar

---

## Phase R: Report (Reportar)

**Objetivo**: Comunicar resultado con razonamiento completo.

### GATE IN
- [ ] Phase A (Act) completada

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resumen** — Resumir qué se hizo y por qué
2. [ ] **Cambios** — Listar archivos modificados con descripción del cambio
3. [ ] **Verificaciones** — Reportar resultado de verificaciones
4. [ ] **Deuda técnica** — Documentar cualquier deuda técnica introducida
5. [ ] **Siguientes pasos** — Sugerir siguientes pasos si aplica

   ```markdown
   ## Reporte RADAR

   ### Decisión tomada
   [Resumen de la alternativa elegida y justificación]

   ### Cambios realizados
   - archivo1.jsx: [descripción del cambio]
   - archivo2.js: [descripción del cambio]

   ### Verificaciones
   - [x] Sintaxis válida
   - [x] No regresiones en funcionalidad existente
   - [x] Convenciones del proyecto respetadas

   ### Deuda técnica
   [Si se introdujo alguna, documentar aquí]

   ### Siguientes pasos
   [Acciones recomendadas si aplica]
   ```

### CHECKPOINT
- [ ] Reporte generado con las 5 secciones requeridas
- [ ] Archivos modificados listados con descripción
- [ ] Deuda técnica documentada (o "None")

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Reporte incompleto
Cause: Falta alguna sección requerida del reporte
Recovery:
  [ ] Option A: Completar la sección faltante — el reporte es obligatorio
  [ ] Option B: Si no hay deuda técnica, escribir explícitamente "None"
  [ ] Option C: Reportar estado parcial con nota de lo que falta y porqué

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen (análisis, decisión, reporte)
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Sesión registrada (si corresponde)

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(copiar de CASTLE Assessment si se ejecutó)_ |
| Artifacts | _(archivos modificados, ADRs creados)_ |
| Next Recommended | _(ver Guide Next Step)_ |
| Risks | _(riesgos activos o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` Phase N+1
> **Opcional en uso embebido**: Omitir si el skill padre maneja la sesión.

---

## Phase N+2: Guide Next Step

| Condición | Próximo Skill |
|-----------|---------------|
| Cambio arquitectónico implementado | `/review` — validar decisión |
| Bug fix implementado | `/fix` (si corresponde) o `/qa` |
| Feature implementada | `/build` o `/qa` |
| Decisión arquitectónica sin implementar aún | `/build` con el plan decidido |

---

## REFERENCE

### Cuándo usar RADAR

| Situación | ¿RADAR? |
|-----------|---------|
| Fix de typo | No |
| Cambio de estilo CSS | No |
| Nueva función en pipeline | Sí |
| Refactoring de componente | Sí |
| Nuevo endpoint API | Sí |
| Cambio en lógica de negocio | Sí |
| Decisión arquitectónica | Sí (+ ADR) |
| Deploy/release | No (usar `/release`) |

### Integración con CASTLE

Después de completar RADAR, si el cambio lo amerita, ejecutar CASTLE assessment:
- Cambios en API → capas C + A
- Cambios de seguridad → capa S
- Código nuevo → capas A + T
- Cambios en pipeline → todas las capas
- Deploy/release → C·A·S·T·L·E completo

> **Session tracking**: Skill standalone. Ver convención en `skills/_shared/standalone-convention.md`.
