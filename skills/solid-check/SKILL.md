---
name: solid-check
version: 1.0
description: "Analiza el código del proyecto buscando violaciones de los 5 principios SOLID. Produce solid-report.json que alimenta el CASTLE A2 sub-score."
---

# SOLID Check — CASTLE A2 Sub-Score

Detecta violaciones de los 5 principios SOLID en el código fuente del proyecto activo. Produce `.king/castle/solid-report.json` consumido por `/castle-report` y el agente `@architect`.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a KING_FRAMEWORK_PATH).

---

## QUICK REFERENCE

### BLOCKING CONDITIONS
> Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe código fuente detectable en el proyecto (tooling plugin, solo markdown/yaml) → log warning y exit 0 (graceful — no es un error)

### ABSOLUTE RESTRICTIONS
> Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA modificar archivos del proyecto analizado
- NUNCA fallar con exit error si el proyecto no tiene código fuente — log + exit 0
- NUNCA cambiar el schema de `solid-report.json` (contrato consumido por castle-report)
- NUNCA bloquear ejecución si `enforcement: warn` (default)
- NUNCA omitir la escritura de `solid-report.json` incluso cuando `violations: []`

### REQUIRED OUTPUTS

- [ ] `.king/castle/solid-report.json` escrito
- [ ] Tabla de violaciones en terminal (o mensaje "No SOLID violations detected")

### PHASES OVERVIEW

```
Phase 0: Detect Stack       → leer .king/knowledge/stack.md si existe
Phase 1: Discover Sources   → identificar archivos de código fuente
Phase 2: Scan Violations    → detectar anti-patterns por principio SOLID
Phase 3: Evaluate Status    → aplicar enforcement rules
Phase 4: Display Table      → mostrar tabla en terminal
Phase 5: Write Output       → escribir solid-report.json
FINAL CHECKPOINT
Execution Summary
```

---

## Phase 0: Detect Stack

Intentar leer `.king/knowledge/stack.md`. Extraer el lenguaje/stack primario del proyecto.

| Stack detectado | Extensiones a escanear |
|---|---|
| Go | `.go` |
| TypeScript / JavaScript | `.ts`, `.tsx`, `.js`, `.jsx` |
| Python | `.py` |
| Java / Kotlin | `.java`, `.kt` |
| C# | `.cs` |
| Ruby | `.rb` |
| PHP | `.php` |
| Sin stack detectado | `.go`, `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.java`, `.kt`, `.cs` |

Si `.king/knowledge/stack.md` no existe, continuar con extensiones por defecto.

---

## Phase 1: Discover Source Files

Buscar archivos con las extensiones del stack detectado en el directorio del proyecto. Excluir:
- `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`, `__pycache__/`
- Archivos de configuración (`.config.js`, `.config.ts`, `*.yaml`, `*.json`, `*.md`)
- Archivos de test (`*_test.go`, `*.test.ts`, `*.spec.ts`, `*.test.js`, `*.spec.js`)

**BLOCKING CONDITION**: Si no se encuentran archivos de código fuente → escribir `solid-report.json` con `violations: []`, `status: "pass"`, log "No source files found — solid-check skipping (tooling plugin?)" y exit 0.

---

## Phase 2: Scan SOLID Violations

Para cada archivo fuente, analizar los siguientes anti-patterns. Registrar `file` (path relativo al project root), `lines` (rango inicio-fin), `principle`, `severity` y `description`.

### S — Single Responsibility Principle

**Señales de violación**:
- Archivo/clase/función con **> 200 líneas** que mezcla múltiples concerns (ej. lógica de negocio + logging + acceso a datos)
- Función que realiza >1 tarea conceptualmente distinta (ej. valida input, transforma datos Y persiste en DB)
- Clase/struct con métodos de dominios no relacionados (ej. `UserService` con métodos de envío de email + gestión de permisos + reportes)

**Severity**:
- `critical` si archivo > 400 líneas con ≥3 concerns mezclados
- `major` si función/método > 50 líneas con ≥2 concerns
- `minor` si clase tiene >8 métodos públicos de dominios distintos

### O — Open/Closed Principle

**Señales de violación**:
- `switch`/`if-else if` sobre tipos o `type` assertions sin polimorfismo (para agregar un tipo nuevo se debe modificar la clase)
- Métodos que requieren modificación para cada nueva variante de comportamiento (en lugar de extensión por composición/herencia)

**Severity**:
- `critical` si el switch cubre ≥5 casos y no hay patrón de extensión
- `major` si hay ≥3 casos y está dentro de una clase de dominio central
- `minor` si hay ≥2 casos en helpers o utilidades

### L — Liskov Substitution Principle

**Señales de violación**:
- Subclase lanza excepciones que la clase padre no declara
- Override de método que estrecha el contrato (acepta menos parámetros o devuelve tipos más restrictivos)
- Subclase que ignora o invalida comportamiento de la clase padre (método sobrescrito que no cumple el contrato original)
- Type assertions/casts forzados de interfaz a implementación concreta

**Severity**:
- `critical` si el override altera el contrato público visible externamente
- `major` si hay excepciones no declaradas en el contrato padre
- `minor` si hay narrowing de tipos en override interno

### I — Interface Segregation Principle

**Señales de violación**:
- Interface/protocolo/contrato con **> 10 métodos** requeridos
- Implementadores que dejan métodos vacíos (`return nil`, `pass`, `throw NotImplementedException`) — señal de que la interface es demasiado grande
- Interface que mezcla operaciones de read y write + admin en una sola

**Severity**:
- `critical` si interface tiene > 15 métodos
- `major` si interface tiene > 10 métodos o hay ≥3 implementaciones vacías
- `minor` si interface tiene 8–10 métodos con concerns mezclados

### D — Dependency Inversion Principle

**Señales de violación**:
- Instanciación directa de implementaciones concretas en constructores de módulos de alto nivel (`new PostgresDB()`, `NewMySQLRepo()` dentro de un service)
- Import directo de implementación concreta donde debería haber una interface (ej. `import { PostgresUserRepo } from './infra/postgres'` dentro de un use case)
- Hard-coded connection strings o configuración de infraestructura en lógica de negocio

**Severity**:
- `critical` si un use case/service instancia directamente infraestructura (DB, HTTP client, filesystem)
- `major` si hay import de implementación concreta en capa de dominio
- `minor` si hay configuración de infraestructura en lógica de negocio sin abstracción

---

## Phase 3: Evaluate Status and Enforcement

### Leer configuración de enforcement

Intentar leer `.king/solid.yaml`. Si no existe, usar defaults:

```yaml
enforcement: warn   # warn | block
mode: run           # run | skip
```

Si `mode: skip` → log "solid-check: mode=skip (bypassed) — auditing to .king/audit/" + escribir report con `violations: []` + exit 0.

### Determinar status

```
status = "fail"  si summary.critical > 0
status = "pass"  si summary.critical == 0
```

### Determinar exit code

```
enforcement: warn  → exit 0 siempre (pass o fail)
enforcement: block → exit 0 si status == "pass"
                     exit 2 si status == "fail" (hay violations critical)
```

---

## Phase 4: Display Table

Mostrar en terminal:

```
SOLID Check — A2 Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SRP [FAIL]  src/auth/service.go:45-82   — Multiple responsibilities (auth + logging)
DIP [WARN]  src/db/repo.go:12           — Depends on concrete PostgresDB, not interface
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Violations: 2 (1 critical, 1 major) | Status: FAIL
Enforcement: warn -> SOLID report generated, not blocking
```

Si `violations: []`:
```
SOLID Check — A2 Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No SOLID violations detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: PASS | Enforcement: warn
```

Leyenda de iconos por severity:
- `critical` → `[FAIL]`
- `major` → `[WARN]`
- `minor` → `[INFO]`

---

## Phase 5: Write Output

Crear directorio `.king/castle/` si no existe.

Escribir `.king/castle/solid-report.json` con el siguiente schema (INMUTABLE — contrato consumido por castle-report/SKILL.md):

```json
{
  "violations": [
    {
      "file": "relative/path.ext",
      "lines": [45, 82],
      "principle": "SRP|OCP|LSP|ISP|DIP",
      "severity": "critical|major|minor",
      "description": "Descripción concisa de la violación"
    }
  ],
  "summary": {
    "total": 0,
    "critical": 0,
    "major": 0,
    "minor": 0
  },
  "enforcement": "warn",
  "status": "pass|fail",
  "checked_at": "ISO8601"
}
```

**Reglas**:
- `status: "fail"` si `summary.critical > 0`; `"pass"` si no hay critical (solo major/minor con enforcement=warn son tolerados)
- `enforcement` refleja el valor de `.king/solid.yaml` (o `"warn"` si no existe el archivo)
- `checked_at` es timestamp ISO8601 de la ejecución actual
- Si no hay violaciones: `violations: []`, `summary` con todos ceros

---

## FINAL CHECKPOINT

- [ ] `.king/castle/solid-report.json` escrito
- [ ] Schema válido (violations array, summary object, enforcement, status, checked_at)
- [ ] `status` es `"fail"` solo cuando `summary.critical > 0`
- [ ] Exit code correcto según enforcement y status
- [ ] Si proyecto sin código fuente: exit 0 (no error)

---

## Execution Summary

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| Violations | _(N total: C critical, M major, P minor)_ |
| Artifacts | `.king/castle/solid-report.json` |
| Next Recommended | Si status=fail AND enforcement=block: fix violations antes de continuar; si status=pass o enforcement=warn: continuar flujo normal |
| Risks | Si proyecto no tiene código fuente: report generado con violations vacías (expected) |
