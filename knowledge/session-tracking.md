# Sistema de Persistencia de Contexto

Documentación de referencia para el sistema de tracking de sesiones y workflows de King Framework.

## Estructura de `.king/`

Cada proyecto que usa el framework mantiene un directorio `.king/` en la raíz del repositorio:

```
.king/
├── registry.md                          # Índice global de workflows y sesiones
├── sessions/                            # Session documents individuales
│   ├── 2026-03-06_001_build_auth-middleware.md
│   ├── 2026-03-06_002_qa_auth-middleware.md
│   ├── 2026-03-06_003_merge_auth-middleware.md
│   ├── ...
│   └── evidence/                        # Evidencia visual (Playwright screenshots)
│       ├── 2026-03-06_001_build_auth-middleware/
│       │   ├── 01-home-cargado.png
│       │   └── 02-panel-migracion.png
│       └── 2026-03-06_002_fix_login-bug/
│           ├── 01-estado-inicial.png
│           └── 02-bug-visible.png
└── workflows/                           # Contexto por workflow
    ├── add-auth-system/
    │   └── context.md
    ├── fix-pipeline-timeout/
    │   └── context.md
    └── ...
```

### Inicialización

Si `.king/` no existe al ejecutar Phase 0 de cualquier skill:
1. Crear el directorio `.king/`
2. Crear `registry.md` usando template `templates/registry.md`
3. Crear subdirectorios `sessions/`, `sessions/evidence/` y `workflows/`
4. Hacer commit: `chore(tracking): initialize .king tracking directory`

## Nomenclatura

### IDs de Workflow
- Formato: `WF-NNN` (numérico secuencial, 3 dígitos con padding)
- Ejemplo: `WF-001`, `WF-012`, `WF-100`
- Se asigna al crear un nuevo workflow

### IDs de Sesión
- Formato: `WF-XXX-SNNN` (workflow ID + sesión secuencial)
- Ejemplo: `WF-001-S001`, `WF-001-S002`
- Se asigna al completar un skill dentro de un workflow

### Nombres de Session Documents
- Formato: `YYYY-MM-DD_NNN_skill-name_context.md`
- `NNN`: secuencial global del día (no por workflow)
- `context`: slug del workflow activo, nombre de branch, o feature (kebab-case, max 40 chars)
- Ejemplo: `2026-03-06_001_build_auth-middleware.md`, `2026-03-06_002_qa_auth-middleware.md`
- Si no hay workflow/contexto disponible: usar solo skill-name (`2026-03-06_001_audit.md`)

### Nombres de Workflow Directories
- Slug del nombre del workflow (lowercase, hyphens)
- Ejemplo: `add-auth-system`, `fix-pipeline-timeout`

### Directorios de Evidencia Visual
- Formato: `sessions/evidence/YYYY-MM-DD_NNN_[skill-name_context]/`
- `YYYY-MM-DD_NNN_context` sincronizado con el session document de la misma sesión
- Archivos: prefijo numérico 2 dígitos + descripción kebab-case + `.png`
- Ejemplo: `01-home-cargado.png`, `02-panel-migracion.png`, `03-bug-visible.png`

## Ciclo de Vida del Workflow

```
CREAR → ACTIVO → COMPLETADO → ARCHIVADO

CREAR:      Primer skill crea el workflow (WF-NNN + context.md + registry entry)
ACTIVO:     Skills sucesivos actualizan context.md y registry
COMPLETADO: Último skill marca como completado (promote a prod exitoso, o standalone)
ARCHIVADO:  Manual o automático tras 30 días de inactividad
```

### Transiciones de Estado
| De | A | Trigger |
|----|---|---------|
| — | ACTIVO | Primer skill ejecutado (build, fix, refactor, etc.) |
| ACTIVO | ACTIVO | Cualquier skill intermedio actualiza el contexto |
| ACTIVO | COMPLETADO | promote a prod exitoso, o skill standalone finalizado |
| ACTIVO | ARCHIVADO | >30 días sin actividad (sugerido en SessionStart) |
| COMPLETADO | ARCHIVADO | Automático tras mover a "Completados" en registry |

## Cómo Leer el Contexto (Phase 0)

1. Verificar si `.king/registry.md` existe
2. Si no existe: inicializar (ver arriba)
3. Si existe: leer registry.md
4. Detectar el branch actual: `git branch --show-current`
5. Buscar en la tabla "Workflows Activos" un workflow cuyo branch coincida
6. Si se encuentra:
   - Leer `.king/workflows/[nombre]/context.md`
   - Extraer: decisiones clave, archivos modificados, estado CASTLE, tareas pendientes
   - Inyectar este contexto en las fases siguientes del skill
7. Si NO se encuentra y el skill no es standalone:
   - Crear nuevo workflow (WF-NNN)
   - Crear directorio y context.md desde template
   - Registrar en registry.md
8. Si el skill es standalone (castle, gitflow, github-ops, radar): operar sin workflow

## Cómo Escribir la Sesión (Phase N+1)

1. Generar session document usando template `templates/session-document.md`
2. Rellenar todas las secciones con datos de la sesión actual:
   - Metadata (IDs, skill, fecha, branch, agentes usados)
   - Protocolo RADAR completo
   - CASTLE Assessment (si se ejecutó)
   - Archivos modificados (tabla con detalles)
   - Commits realizados
   - Evidencia Visual (checklist: intentada, app corriendo, screenshots, motivo si omitida)
   - Artefactos producidos
3. Guardar en `.king/sessions/YYYY-MM-DD_NNN_skill-name.md`
4. Actualizar `.king/workflows/[nombre]/context.md`:
   - Agregar sesión a la cadena de sesiones
   - Actualizar archivos modificados (acumulativo)
   - Actualizar estado CASTLE
   - Actualizar decisiones clave (solo nuevas)
   - Actualizar artefactos
   - Actualizar tareas pendientes
   - Actualizar "Próxima Acción"
5. Actualizar `.king/registry.md`:
   - Actualizar fila del workflow en "Activos" (fase actual, último skill, próximo skill, CASTLE, fecha)
   - Agregar fila en "Sesiones Recientes"
   - Si workflow completado: mover de "Activos" a "Completados"
6. Commit: `chore(tracking): update session WF-XXX-SNNN [skill-name]`

## Cómo Guiar el Próximo Paso (Phase N+2)

Determinar el próximo skill según la tabla de flujo:

| Skill Actual | Condición | Próximo Skill |
|--------------|-----------|---------------|
| build | Siempre | `/qa --standard` |
| qa | CASTLE >= CONDITIONAL | `/merge` |
| qa | CASTLE BREACHED | `/fix` → repetir `/qa` |
| fix | Fix aplicado | `/qa --standard` |
| merge | Merge exitoso | `/qa --batch` o esperar |
| qa-batch | FORTIFIED | `/promote --to qa` (auto) |
| qa-batch | CONDITIONAL | `/promote --to qa` (review) |
| qa-batch | BREACHED | `/fix` por blocker |
| promote (→qa) | Health OK | `/qa --env` |
| qa-env | FORTIFIED | `/release` |
| qa-env | BREACHED | `/fix` → repetir |
| release | Completo | `/promote --to prod` |
| promote (→prod) | Health OK | Workflow COMPLETADO |
| refactor | Siempre | `/qa --standard` |
| review | APROBADO | `/merge` |
| review | CAMBIOS REQUERIDOS | `/fix` |
| frontend-design | Siempre | `/qa --standard` |

### Skills Standalone (sin workflow)
- `castle` — Evaluación independiente, no genera workflow
- `gitflow` — Gestión de branches, no genera workflow
- `github-ops` — Operaciones GitHub, no genera workflow
- `radar` — Razonamiento estructurado, no genera workflow

### Comunicación al Usuario

Al finalizar un skill, comunicar al usuario:

```
► Próxima acción: /[skill] [argumentos]
  Objetivo: [qué se logrará]
  Pre-requisitos: [qué debe cumplirse]

  Árbol de decisión post-skill:
  ├─ Si [resultado A] → /[skill X]
  ├─ Si [resultado B] → /[skill Y]
  └─ Si [resultado C] → /[skill Z]
```

## Detección Automática de Workflow

Cuando un usuario ejecuta un skill sin `--workflow`:
1. Obtener branch actual: `git branch --show-current`
2. Buscar en registry.md un workflow activo con ese branch
3. Si existe exactamente 1: usar ese workflow automáticamente
4. Si existen múltiples: preguntar al usuario cuál usar
5. Si no existe ninguno: crear nuevo workflow (si el skill no es standalone)

## Casos Borde

### Múltiples workflows en el mismo branch
- Poco común, pero posible si se reutiliza un branch
- Resolver preguntando al usuario

### Workflow sin actividad >30 días
- SessionStart sugiere archivar
- El usuario decide (no se archiva automáticamente)

### Cambio de branch durante un workflow
- El workflow se asocia al branch original
- Si el usuario cambia de branch y ejecuta un skill, se crea nuevo workflow
- El workflow anterior permanece activo hasta que se complete o archive

### Conflicto de sesión (multiple skills simultáneos)
- No soportado: un skill a la vez por workflow
- Si se detecta otra sesión en progreso, advertir al usuario

### Recovery de sesión incompleta
- Si Phase N+1 no se ejecutó (crash, timeout, etc.)
- El hook Stop intenta escribir la sesión antes de cerrar
- Si no se pudo: la próxima Phase 0 detecta la inconsistencia y la reporta

## Integración con Git

Todos los archivos de `.king/` se trackean en git:
- Los session documents y context.md son parte del historial del proyecto
- Los commits de tracking usan prefijo `chore(tracking):`
- El registry.md se actualiza en cada sesión
- `.king/` NO debe estar en `.gitignore`
