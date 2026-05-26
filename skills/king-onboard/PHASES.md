# /king-onboard — Fases Detalladas

> Sub-archivo cargado desde SKILL.md. Contiene el contenido completo de cada fase del walkthrough.

---

## Phase 1: Welcome + Project Scan

Saludar al usuario y explicar qué está por pasar:

```
"¡Bienvenido a King Framework! Te voy a guiar por el ciclo completo de desarrollo —
desde la inicialización hasta el merge — usando tu codebase real.

King Framework tiene 42 skills que cubren todo: generar proyectos, planificar features,
implementar, revisar, hacer QA, mergear, y mucho más. En este onboarding vamos a
ejecutar el ciclo de una forma guiada, paso a paso, con un cambio pequeño y real.

Primero déjame escanear tu proyecto..."
```

Escanear el estado actual del proyecto:

```
Detectar:
├── ¿Tiene directorio .king/? → proyecto ya inicializado con King
├── ¿Tiene git init? → repositorio git disponible
├── ¿Tiene docs/plans/? → planes existentes
├── ¿Tiene tests? (pytest, jest, go test, etc.) → capacidades de testing
└── ¿Qué stack usa? (leer package.json, go.mod, requirements.txt, etc.)
```

Buscar 2-3 oportunidades de mejora pequeñas:

```
Criterios para una buena mejora de onboarding:
├── Alcance pequeño — completable en 45-60 min
├── Bajo riesgo — sin breaking changes, sin migraciones de datos
├── Valor real — algo genuinamente útil, no ficticio
├── Planificable — tiene al menos 1 requerimiento claro y 2 escenarios
└── Ejemplos:
    ├── Validación de input faltante en un formulario o endpoint
    ├── Mensajes de error inconsistentes en un flujo auth
    ├── Una función utilitaria que podría extraerse y reutilizarse
    ├── Estado de loading/error faltante en un componente async
    └── Un TODO o FIXME con intención clara en el código
```

Presentar las opciones al usuario y dejar que elija, o que proponga la suya.

---

## Phase 2: Genesis (narrado)

Si el proyecto ya tiene `.king/`:

```
"Veo que tu proyecto ya fue inicializado con /genesis — tiene .king/ configurado.
Perfecto, eso significa que los agentes y skills van a tener contexto de tu stack
y arquitectura desde el inicio. Saltamos esta fase."
```

Si el proyecto NO tiene `.king/`:

```
"Step 0: Genesis — Antes de arrancar el ciclo de desarrollo, King Framework necesita
conocer tu proyecto. /genesis crea .king/ con el contexto base:
stack, convenciones, arquitectura y ambientes."
```

Ejecutar genesis simplificado:
1. Crear `.king/knowledge/stack.md` con el stack detectado en Phase 1
2. Crear `.king/knowledge/conventions.md` con convenciones básicas detectadas
3. Crear `.king/knowledge/architecture.md` con la estructura de carpetas del proyecto

Teaching moment:
```
"Notás que creamos .king/knowledge/? Esos archivos son el contexto que todos los
skills van a usar. /build los lee para no repetirte preguntas. /plan los usa para
generar código consistente con tu proyecto. Es el cerebro compartido del equipo."
```

---

## Phase 3: Brainstorm (narrado) ← PAUSA

```
"Step 1: Brainstorm — Toda feature empieza con una idea. /brainstorm toma el concepto
en crudo y lo enriquece: identifica el problema real, valida que sea la solución correcta,
y define el scope antes de comprometerse a planificar."
```

Simular brainstorm con la mejora elegida:
1. Formular el problema real: ¿qué duele hoy? ¿a quién?
2. Validar la solución: ¿hay una forma más simple de resolverlo?
3. Definir el scope: ¿qué está dentro, qué está fuera?
4. Enunciar el criterio de éxito: ¿cómo sabremos que está listo?

```
Tip 💡: Antes de escribir el brief para /brainstorm, usá /refine para optimizar
el prompt. Un prompt bien estructurado produce un análisis más preciso.
```

Presentar el resumen del brainstorm al usuario.

**PAUSA**: Preguntar al usuario si quiere ajustar algo antes de planificar. Aceptar: SÍ/continuar, NO/detener, o feedback para ajustar.

---

## Phase 4: Plan (narrado) ← PAUSA

```
"Step 2: Plan — Ahora convertimos la idea en un plan de implementación concreto.
/plan coordina múltiples agentes especializados en paralelo para analizar el impacto
desde distintas perspectivas."
```

Simular el análisis multi-agente narrado:

```
"Lanzando análisis en paralelo...

  @architect — ¿Cómo impacta esto en la arquitectura? ¿Dónde vive este código?
  @developer  — ¿Cuánto esfuerzo? ¿Qué archivos se tocan? ¿Hay patrones reutilizables?
  @qa         — ¿Cómo lo testeamos? ¿Qué casos edge hay?
  @security   — ¿Hay superficie de ataque? ¿Qué validar?

Consolidando..."
```

Producir el design doc simplificado:
- Problema y solución propuesta
- Archivos afectados
- Decisiones de diseño clave
- Criterios de aceptación (formato Gherkin si aplica)
- Tareas ordenadas (estimación S/M/L)

Teaching moment sobre complexity triage:
```
"Notás que antes de ejecutar, /plan evalúa la complejidad. Si el cambio toca
3+ archivos con dependencias cruzadas, o se estima en más de una sesión, /plan
sugiere escalar a SDD — que agrega trazabilidad completa, recovery post-compactación
y PR budget guards. Para esta mejora, es lo suficientemente pequeña para SDLC estándar."
```

**PAUSA**: Mostrar el plan y preguntar "¿Continuamos con la implementación?". Aceptar ajustes antes de avanzar.

---

## Phase 5: Build (narrado)

```
"Step 3: Build — Acción. /build toma el plan aprobado y lo implementa:
crea el branch, analiza el impacto arquitectónico, escribe el código,
y verifica contra los criterios de aceptación."
```

Simular el build en pasos narrados:

**5a. Branch:**
```
"Creando feature branch desde develop...
 git checkout -b feature/[nombre-de-la-mejora]

 Tip 💡: Para cambios que van a tardar varios días o que corren en paralelo
 con otras features, usá /worktree — crea un git worktree aislado para trabajar
 en múltiples branches simultáneamente sin cambiar de directorio."
```

**5b. Architecture check:**
```
"@architect evaluando impacto...
 ¿Este código va en la capa correcta? ¿Violamos algún principio de diseño existente?
 ¿Estamos respetando la dirección de dependencias?"
```

**5c. Implementation:**
Implementar el cambio planificado. Narrar cada decisión relevante:
```
"Implementando [tarea]: [descripción breve]
 ✓ Hecho — [nota de qué se creó/cambió]"
```

**5d. Tests:**
```
"Escribiendo tests...

 Tip 💡: Para proyectos que necesitan un plan de testing más completo antes de
 implementar — especialmente en QA o features críticas — /test-plan genera una
 estrategia de testing exhaustiva con cobertura de casos edge.

 Tip 💡: Si necesitás interactuar con GitHub — crear issues, PRs, revisar
 CI/CD status — /github-ops cubre todas las operaciones de repositorio."
```

---

## Phase 6: Review (narrado)

```
"Step 4: Review — Todo código nuevo pasa por revisión antes de mergear.
/review hace un análisis técnico profundo usando el protocolo CASTLE."
```

Ejecutar code review narrado:

```
"Ejecutando CASTLE assessment sobre el diff...

  C — Correctness:  ¿El código hace lo que dice que hace?
  A — Architecture: ¿Respeta los patrones establecidos? ¿Dependency direction OK?
  S — Security:     ¿Hay superficie de ataque? ¿Input validado? ¿Secrets hardcodeados?
  T — Testing:      ¿Los tests cubren los criterios de aceptación?
  L — Legibility:   ¿El código es claro? ¿Los nombres expresan intención?
  E — Extensibility: ¿Es fácil de mantener y extender?
```

Generar el reporte de review con el veredicto CASTLE: FORTIFIED / CONDITIONAL / BREACHED.

Teaching moment:
```
"Tip 💡: Si el review encuentra problemas estructurales — código duplicado, acoplamiento
alto, nombres inconsistentes — /refactor hace la limpieza quirúrgica sin cambiar
funcionalidad. /audit es para auditorías más amplias del proyecto completo."
```

Si hay observaciones: incorporarlas antes de continuar.

---

## Phase 7: QA (narrado)

```
"Step 5: QA — Verificación de calidad antes del merge. /qa confirma que todo
cumple los criterios de aceptación, la cobertura de tests, y pasa el security gate."
```

Ejecutar QA narrado:

```
"Verificando criterios de aceptación...
  ✓ [AC 1]: [descripción] — PASS
  ✓ [AC 2]: [descripción] — PASS

Ejecutando coverage gate...
  Coverage: X% — [dentro/fuera del threshold]

Ejecutando security gate (5 checks)...
  ✓ Sin secrets hardcodeados
  ✓ Input validado en boundaries
  ✓ Sin vulnerabilidades OWASP evidentes
  ✓ Sin tokens expuestos en logs
  ✓ Permisos correctos
```

Teaching moment:
```
"Tip 💡: Si QA encuentra bugs, /fix es el skill para resolverlos — tiene un flujo
específico para diagnosticar el root cause, crear la fix branch, y verificar que
la corrección no introduce regresiones."
```

Si QA pasa → continuar. Si falla → corregir con /fix narrado antes de avanzar.

---

## Phase 8: Merge (narrado)

```
"Step 6: Merge — El código aprobado se integra a develop. /merge gestiona
la estrategia de merge, la resolución de conflictos y las PR conventions."
```

Ejecutar merge narrado:

```
"Verificando que develop está actualizado...
Ejecutando merge de feature/[nombre] → develop...
  Strategy: squash merge (mantiene historial limpio en develop)
  PR title: [titulo convencional]
  PR description: [resumen del cambio]
```

Teaching moment sobre el ciclo completo:
```
"El código está en develop. Desde acá, el ciclo puede continuar con:

  /promote → promueve develop a QA o staging
  /release → genera release branch, changelog, y tag de versión

Esos pasos dependen de tu flow de releases y no los ejecutamos en el onboarding
para no afectar tus ambientes reales."
```

---

## Phase 9: Summary

Cerrar la sesión con el recap completo:

```markdown
## ¡Onboarding Completo! 🎉

Recorriste el SDLC completo de King Framework con un cambio real:

**Cambio implementado**: {descripción de la mejora}

**El ciclo en una línea**:
genesis → brainstorm → plan → build → review → qa → merge

**Skills que usamos**:
- /genesis    → contexto del proyecto
- /brainstorm → idea → scope validado
- /plan       → análisis multi-agente → design doc
- /build      → branch + implementación + tests
- /review     → CASTLE assessment
- /qa         → ACs + coverage + security gate
- /merge      → integración a develop

**Skills que mencionamos como utilitarios**:
- /refine     → optimizar prompts antes de ejecutar skills
- /worktree   → branches paralelos sin cambiar de directorio
- /github-ops → operaciones de repositorio (issues, PRs, CI)
- /test-plan  → estrategia de testing para features críticas
- /audit      → auditoría amplia del proyecto
- /refactor   → limpieza quirúrgica de código
- /fix        → resolución de bugs con diagnóstico estructurado

**Para cambios más complejos (3+ archivos interdependientes, multi-sesión)**:
→ Usá /sdd-onboard para aprender el pipeline SDD, o /sdd-new para arrancar directamente.

**Mapa completo de todos los skills**:
Ver `skills/king-onboard/REFERENCE.md`

**Próximos pasos**:
- Elegí tu próxima feature y arrancá con /brainstorm
- Para cambios complejos: /sdd-new <nombre>
- ¿Dudas? El orquestador siempre está disponible
```

Persistir el resultado del onboarding en Engram si está disponible:
```
mem_save(
  title: "king-onboard/{project}",
  topic_key: "king-onboard/{project}",
  type: "session_summary",
  project: "{project}",
  content: "Onboarding completado. Cambio: {descripción}. Stack: {stack detectado}."
)
```
