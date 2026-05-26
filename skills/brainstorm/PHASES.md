# Brainstorm — Phases (v3.0)

> Lógica detallada de las 5 fases. Router principal: [SKILL.md](SKILL.md)

---

## PHASE 1: Context

### GATE IN
> Condiciones para entrar

- [ ] Sesión de `/genesis` existe en `.king/sessions/`
- [ ] `CLAUDE.md` existe y es legible

### PHASE 1 ASSERTION

> ⛔ **Esta fase es de ejecución obligatoria. No continuar a PHASE 2 sin completar este MUST DO.**
>
> Plan mode NO exime de esta fase. La restricción de escritura no afecta las tareas de lectura, captura de metadata y detección de modo que se ejecutan aquí.
>
> Phase 1 puede ejecutarse brevemente si el contexto ya fue provisto por el usuario, pero las tareas MUST DO siguen siendo obligatorias.

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Cargar knowledge de genesis** — Leer si existen:
   - `.king/knowledge/stack.md`
   - `.king/knowledge/architecture.md`
   - `.king/knowledge/conventions.md`
   - `.king/knowledge/environments.md`
   - `CLAUDE.md` (stack section, equipo de agentes, configuracion)
   - `.claude/knowledge/context7/library-registry.md` (si existe)

2. [ ] **Capturar metadata del documento** —
   - `project`: título del heading principal de `CLAUDE.md` (ej: `# Mi Proyecto` → `Mi Proyecto`)
   - `author`: `git config user.name` o `gh auth status --json login` (el Host, NO hardcodear "Claude")
   - `date`: fecha ISO de ejecución (YYYY-MM-DD)

3. [ ] **Detectar modo** — Ver lógica en [SKILL.md](SKILL.md) sección "Detección Automática de Modo"

4. [ ] **Si modo PROYECTO:**
   - Informar: "Modo PROYECTO detectado. Se generarán 4 documentos de arquitectura en `.king/docs/architecture/`."
   - Inicializar colectores vacíos para 002 (entidades), 003 (deps), 004 (inconsistencias)

5. [ ] **Si modo FEATURE:**
   - Verificar que existan `001-*-arquitectura.md`, `002-*-modelo-datos.md`, `003-*-dependencias.md`, `004-*-inconsistencias.md` en `.king/docs/architecture/`
   - Si no existen: advertir al usuario y sugerir ejecutar `/brainstorm` en modo PROYECTO primero
   - Si existen: cargarlos en memoria para detección de deltas posterior

6. [ ] **Deep codebase analysis** (si el proyecto tiene código fuente existente):
   Invocar Task tool con `subagent_type="feature-dev:code-explorer"`:
   ```
   Analiza el codebase actual enfocándote en módulos, patrones de arquitectura existentes,
   flujos de datos relevantes y dependencias entre módulos.
   Output: Mapa conciso de arquitectura relevante + patrones a respetar
   ```
   Si el proyecto es nuevo (post-genesis sin código fuente) → saltar este paso.

### CHECKPOINT
> ✅ Verificar antes de continuar

- [ ] Knowledge de genesis cargado (o ausente documentado)
- [ ] Metadata capturado: `project`, `author`, `date`
- [ ] Modo detectado (PROYECTO o FEATURE)
- [ ] Docs base cargados en memoria (modo FEATURE) o colectores inicializados (modo PROYECTO)

### IF FAILS
```
PHASE 1 falló: {razón}
Verificar: CLAUDE.md existe, sesión de genesis existe en .king/sessions/
```

---

## PHASE 2: Explore

### GATE IN

- [ ] PHASE 1 completada

### PHASE 2 ASSERTION

> ⛔ No continuar a PHASE 3 sin completar este MUST DO.
> Esta fase es obligatoria. NUNCA sustituir con supuestos propios.
> Plan mode NO exime de esta fase.

> **PLAN MODE — Reglas de preguntas:**
> 1. **Plan mode: 1 pregunta por turno** — esperar respuesta antes de continuar.
> 2. NUNCA presentar múltiples preguntas en un mismo mensaje.
> 3. NUNCA asumir respuestas en plan mode — preguntar al usuario.

### MUST DO

**Preguntas una a una — esperar respuesta antes de continuar**

**Preguntas base (todos los modos):**

1. [ ] Visión general del sistema (si no fue capturada de genesis)
2. [ ] Módulos principales y sus responsabilidades
3. [ ] Flujo de datos principal
4. [ ] Integraciones externas clave
5. [ ] Consideraciones de seguridad del sistema
6. [ ] Estrategia de testing global

**Preguntas adicionales — Modo PROYECTO únicamente:**

7. [ ] **Entidades de dominio:**
   ```
   ¿Cuáles son las entidades principales de tu dominio?
   (ej: Usuario, Producto, Orden, Factura)
   ```

8. [ ] **Relaciones entre entidades:**
   ```
   ¿Cómo se relacionan estas entidades?
   a) Describir relaciones clave (1:N, N:M, 1:1)
   b) Prefiero que las derives del contexto del sistema
   ```

9. [ ] **Dependencias externas conocidas:**
   ```
   ¿Hay servicios externos o librerías específicas que ya sabes que necesitas?
   (ej: Stripe para pagos, SendGrid para email, Supabase para auth)
   Si no, déjalo en blanco y las derivaré del contexto.
   ```

**Modo FEATURE — exploración de deltas:**
- Identificar nuevas entidades que introduce la feature
- Identificar nuevas dependencias requeridas
- Detectar impacto arquitectónico en los docs base (001-004)

### CHECKPOINT

- [ ] Preguntas base respondidas (1-6)
- [ ] Modo PROYECTO: entidades identificadas, deps catalogadas (preguntas 7-9)
- [ ] Modo FEATURE: deltas detectados (nuevas entidades, deps, componentes)

### IF FAILS
```
PHASE 2 falló: usuario no respondió preguntas de discovery.
Recovery: reformular con opciones concretas, usar valores default si continúa sin respuesta.
```

---

## PHASE 3: Consult

### GATE IN

- [ ] PHASE 2 completada

### PHASE 3 ASSERTION

> ⛔ No continuar a PHASE 4 sin completar este MUST DO.
> Plan mode NO exime de esta fase.

> **PLAN MODE — Agent tool:**
> Agent tool NO está restringido en plan mode — lanzar agentes normalmente.
> Si un subagente intenta Write/Edit/Bash, esas operaciones serán bloqueadas por plan mode.
> Documentar su output como fallback en la conversación (ver MUST DO ítem 4).

### MUST DO

1. [ ] **Detectar señales** en el diseño propuesto — usar matriz del [SKILL.md](SKILL.md) AGENT CONSULTATION MATRIX

2. [ ] **Consultar agentes detectados** (en paralelo cuando sea posible):

   Para cada agente cuya señal se detectó:
   ```
   @{agente}: Dado este diseño de {feature/sistema}, ¿qué consideraciones
   de {dominio} debería incluir desde el inicio?

   Contexto: {resumen del diseño propuesto}

   Preguntas adicionales:
   - ¿Qué entidades o modelos de datos afecta tu dominio?
   - ¿Qué dependencias externas recomiendas y cuáles son sus riesgos?
   - ¿Hay ambigüedades o gaps funcionales que detectas?
   ```

3. [ ] **Recopilar resultados de consultas:**
   - Agregar a colector 002: entidades/schemas recomendados por agentes
   - Agregar a colector 003: dependencias recomendadas con riesgos
   - Agregar a colector 004: gaps, ambigüedades o conflictos detectados

4. [ ] **Si agente no disponible (fallback):**
   ```
   ⚠️ Señal detectada: {señal}
   Agent @{agente} no fue activado en /genesis.
   Usando fallback: {checklist básico}
   ```
   Documentar en colector con status "Fallback".

5. [ ] **Mostrar al usuario los agentes consultados:**
   ```
   🤖 Agentes consultados:
   - @{agente}: {recomendación clave}
   Estas consideraciones están incorporadas en el diseño.
   ```

### CHECKPOINT

- [ ] Agentes relevantes consultados (o fallback documentado)
- [ ] Colector 002: entidades de agentes compiladas
- [ ] Colector 003: dependencias de agentes compiladas
- [ ] Colector 004: inconsistencias de agentes compiladas
- [ ] Conflictos entre agentes documentados como inconsistencias HIGH

### IF FAILS
```
PHASE 3 falló: agente no disponible sin fallback.
Documentar señal en 004 como HIGH, continuar sin esa perspectiva.
```

---

## PHASE 4: Design

### GATE IN

- [ ] PHASE 3 completada

### MUST DO — Modo PROYECTO

> Presentar cada artefacto en secciones de 200-300 palabras. Pedir validación después de cada sección.

1. [ ] **Presentar artefacto 001 — Arquitectura:**
   - Secciones: Context+Vision, ADRs (del stack y tipo de producto), tabla de Componentes, flujo de datos (ASCII), Integraciones Externas, Consideraciones de Seguridad, Estrategia de Testing, Estructura de Carpetas
   - Preguntar: "¿La arquitectura general se ve bien hasta aquí?"

2. [ ] **Presentar artefacto 002 — Modelo de Datos:**
   - Modelo Conceptual: tabla entidades, tabla relaciones, reglas de dominio
   - Modelo Técnico: schemas DB o interfaces TypeScript según el stack de genesis
   - Preguntar: "¿El modelo de datos refleja correctamente tu dominio?"

3. [ ] **Presentar artefacto 003 — Dependencias:**
   - Deps Externas Producción (tabla con riesgo y alternativa)
   - Deps Externas Desarrollo
   - Servicios Externos (tabla con fallback)
   - Módulos Internos (tabla + grafo ASCII)
   - Evaluación de Riesgos
   - Preguntar: "¿Las dependencias y sus riesgos se ven correctos?"

4. [ ] **Presentar artefacto 004 — Inconsistencias:**
   - Lista de gaps con severidad HIGH/MEDIUM/LOW
   - Si el usuario puede resolver alguno ahora: marcarlo como RESUELTO inmediatamente
   - Preguntar: "¿Reconoces estas inconsistencias? ¿Puedes clarificar alguna ahora?"
   - Si no hay inconsistencias: informar "No se detectaron inconsistencias en esta sesión."

### MUST DO — Modo FEATURE

1. [ ] **Presentar diseño de la feature** (flujo existente: secciones de 200-300 palabras)

2. [ ] **Presentar delta summary:**
   ```
   Cambios a documentos base:
   - 001 (arquitectura): {N} nuevos componentes, {N} nuevas integraciones
   - 002 (modelo de datos): {N} nuevas entidades, {N} nuevas relaciones
   - 003 (dependencias): {N} nuevos paquetes, {N} nuevos módulos
   - 004 (inconsistencias): {N} nuevos gaps detectados
   ```
   Preguntar: "¿Los cambios a los documentos base se ven correctos?"

### CHECKPOINT

- [ ] Modo PROYECTO: 4 artefactos presentados y validados por el usuario
- [ ] Modo FEATURE: diseño validado + deltas confirmados
- [ ] Inconsistencias revisadas (algunas pueden quedar ABIERTAS — es válido)

### MODE-AWARE BEHAVIOR
> Este bloque es informativo — NO interrumpe el flujo hacia Phase 5.

Si plan mode activo (Write tool restringido):
- Presentar cada artefacto como bloque Markdown copiable con YAML frontmatter completo
- Indicar la ruta destino de cada bloque
- Informar al usuario: "Phase 5 ejecutará en modo copiable — los documentos se presentarán como bloques Markdown, no se escribirán en disco. Para guardarlos: sal de plan mode y ejecuta 'guarda los documentos de brainstorm'."
- **CONTINUE TO PHASE 5** (presentar bloques, no escribir archivos)

EJEMPLO CONTRASTIVO:
- ❌ MAL: validar el diseño e invitar al usuario a comenzar la implementación del proyecto.
- ✅ BIEN: "Diseño validado. Procedo a Phase 5: Document para ofrecerte los archivos del plan listos para guardar en la carpeta de tu proyecto."

---

## PHASE 5: Document

### GATE IN

- [ ] PHASE 4 completada y validada por el usuario

### PHASE 5 ASSERTION

> ⚠️ Plan mode activo NO es condición bloqueante de esta fase.
> Si Write tool no está disponible → aplicar el mecanismo de bloques copiables de Phase 4 MODE-AWARE BEHAVIOR.
> Esta assertion aplica también a session-management: plan mode no lo bloquea; si Write tool no está disponible → bloque copiable.
> **NUNCA terminar sin haber ejecutado esta fase** (en modo normal o como bloques copiables).

### MUST DO — Modo PROYECTO

1. [ ] **Crear directorio:**
   ```bash
   mkdir -p .king/docs/architecture/
   ```

2. [ ] **Write `001-{proyecto}-arquitectura.md`** — con YAML frontmatter completo

3. [ ] **Write `002-{proyecto}-modelo-datos.md`** — con YAML frontmatter completo

4. [ ] **Write `003-{proyecto}-dependencias.md`** — con YAML frontmatter completo

5. [ ] **Write `004-{proyecto}-inconsistencias.md`** — con YAML frontmatter completo
   (Si no hay inconsistencias: escribir igualmente con sección "No se detectaron inconsistencias en esta sesión.")

6. [ ] **Verificar** que los 4 archivos existen con contenido

### MUST DO — Modo FEATURE

1. [ ] **Write `.king/docs/features/{feature}/design.md`** — con YAML frontmatter completo

2. [ ] **Para cada doc base (001-004) con deltas:**
   - Usar **Edit tool** para APPEND de la sección delta al final del archivo
   - Formato del delta: ver template en [REFERENCE.md](REFERENCE.md) sección "Template: Delta Section"

3. [ ] **Para cada doc base modificado:**
   - Usar Edit tool para actualizar frontmatter: `version` (incrementar minor: 1.0→1.1→1.2), `date` (fecha actual)
   - Para `004-inconsistencias.md`: además actualizar la tabla de Resumen al inicio

4. [ ] **Si un doc base no existe:**
   - WARN al usuario: "Doc base {nombre} no encontrado. Skipping delta."
   - Log la situación en la sesión. No bloquear la ejecución.

### CHECKPOINT

- [ ] Modo PROYECTO: 4 archivos en `.king/docs/architecture/` verificados
- [ ] Modo FEATURE: `design.md` creado + deltas appendeados + versiones incrementadas
- [ ] Todos los archivos tienen YAML frontmatter con project/date/author/version

### OUTPUTS

- **Modo PROYECTO**: `.king/docs/architecture/001-{proyecto}-arquitectura.md`, `002-*.md`, `003-*.md`, `004-*.md`
- **Modo FEATURE**: `.king/docs/features/{feature}/design.md` + deltas en docs base

### IF FAILS
```
PHASE 5 falló al escribir {archivo}.
Archivos creados hasta ahora: {lista}
Para retomar: los archivos existentes son válidos. Re-ejecutar /brainstorm y responder
las preguntas de forma abreviada para llegar a PHASE 5 y completar los archivos faltantes.
```

---

## Finalización

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Confirmar archivos creados** — Mostrar paths de todos los artefactos generados/modificados
2. [ ] **Registrar sesión** via session-management Phase N+1 (ver `skills/_shared/lifecycle-outputs.md`)
3. [ ] **Comunicar próximo paso:**
   - **Modo PROYECTO**: `/brainstorm --feature {nombre}` para diseñar la primera feature
   - **Modo FEATURE con UI**: `/frontend-design --feature {feature}` (recomendado) o `/plan`
   - **Modo FEATURE sin UI**: `/plan`

### CHECKPOINT

- [ ] Artefactos confirmados y paths mostrados al usuario
- [ ] Sesión registrada en `.king/sessions/`
- [ ] Próximo paso comunicado

> Output detallado de finalización y templates de los documentos: [REFERENCE.md](REFERENCE.md)
