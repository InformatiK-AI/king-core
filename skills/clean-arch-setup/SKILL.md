---
name: clean-arch-setup
version: 2.0
api_version: 1.0.0
description: "Scaffoldea Clean Architecture por stack (Go/TS/Python) con estructura de directorios por capa, interfaces de use cases, entities con invariants, repository interfaces, tests de arquitectura (dependency-cruiser/go-arch-lint) que FALLAN si domain importa infra, y ADR-001. Usar cuando se necesite: montar Clean Architecture, scaffoldear capas domain/application/infrastructure, generar la regla de dependencia con tests automáticos, o iniciar un bounded context. ADVIERTE 'patrón prematuro' si el proyecto tiene < 5 entidades."
---

# /clean-arch-setup — Scaffolding de Clean Architecture con la Regla de Dependencia verificable

Scaffoldea la estructura de **Clean Architecture** para un dominio (bounded context) en el stack del
proyecto (Go, TypeScript o Python). Genera las 4 capas con packages correctos, interfaces de **use
cases** vacías con firma canónica, **entities** base con invariants protegidos, **repository
interfaces** (puertos — sin implementación, esa vive en infra), un **test de arquitectura**
(`dependency-cruiser` para TS, `go-arch-lint` para Go, `import-linter` para Python) que FALLA si
`domain/` importa `infrastructure/`, y el **ADR-001** documentando la decisión con trade-offs.

> **Regla transversal innegociable**: la dirección de las dependencias apunta SIEMPRE hacia el dominio.
> El dominio NO importa frameworks, ni DB, ni HTTP. Una entidad que importa el ORM ya rompió la
> arquitectura, sin importar cuántas carpetas tengas. Por eso el test de arquitectura NO es opcional:
> es la garantía mecánica de la regla, no una buena intención. Ver `knowledge/domain/architecture-patterns.md` §1.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack y lenguaje del proyecto — fuente del scaffolding (Go/TS/Python) auto-detectado | Yes | project |
| `.king/knowledge/architecture.md` | Arquitectura existente y decisiones previas — evita duplicar capas ya montadas | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de packages, archivos y tests | No | project |
| `knowledge/domain/architecture-patterns.md` | Clean/Hexagonal/DDD/CQRS/ES con trade-offs, estructura por patrón y la regla de dependencia (custom: este skill scaffoldea el patrón Clean del §1 y usa el Mapa de Decisión Rápida para el check de prematuridad) | Yes | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[domain-name]` (el nombre del bounded context es obligatorio)
- [ ] El stack no es resoluble (ni `--stack` ni `.king/knowledge/stack.md` declaran Go/TS/Python)
- [ ] Ya existe una estructura Clean para ese `[domain-name]` y el usuario NO confirmó sobrescribir

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA generar imports de infraestructura (ORM, cliente HTTP, SDK de broker) dentro de `domain/` — eso viola la regla de dependencia que el propio skill protege
- NUNCA implementar los repository interfaces dentro de `domain/` o `application/` — solo declarar el puerto; la implementación es responsabilidad de la capa de infra
- NUNCA generar el test de arquitectura como `skip`/`todo` ni con la regla de dependencia invertida — el test DEBE fallar si `domain` importa `infra`
- NUNCA continuar el scaffolding sin advertir si el proyecto tiene < 5 entidades (patrón prematuro) — la advertencia es obligatoria, la decisión es del usuario
- NUNCA hardcodear versiones de stack, rutas absolutas, ni nombres de proyecto — usar `.king/knowledge/stack.md` y `{{SLOT}}`
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Estructura de directorios por capa creada según el stack (Go: `internal/{domain,application,infrastructure,delivery}`; TS: `src/{domain,application,infrastructure,presentation}`; Python análogo)
- [ ] ≥1 interfaz de Use Case con firma canónica (`Execute(input) → output`) en `application/`
- [ ] ≥1 Entity base con al menos un invariant protegido en el constructor/factory en `domain/`
- [ ] ≥1 Repository interface (puerto) declarada en `application/ports` (o equivalente), SIN implementación
- [ ] Test de arquitectura (`dependency-cruiser` / `go-arch-lint` / `import-linter`) que FALLA si `domain` importa `infrastructure`
- [ ] `ADR-001` creado documentando la decisión con trade-offs (cuándo usar / cuándo NO)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Detect   (Prematurity (Scaffold (Generate (Arch     (Session)  (Guide)
          stack)    check)       layers)   contracts) test+ADR)
```

### PARÁMETROS
```
/clean-arch-setup [domain-name] [--stack go|ts|python] [--no-tests]
```
- `[domain-name]`: nombre del bounded context o dominio (ej. `orders`, `billing`). Obligatorio
- `--stack`: fuerza el stack del scaffolding (default: auto-detectado desde `.king/knowledge/stack.md`)
- `--no-tests`: omite la generación del test de arquitectura (DESACONSEJADO — el test es la garantía mecánica de la regla de dependencia; el skill advierte el riesgo)

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) es la capa central: el skill MATERIALIZA la regla de dependencia y la vuelve
> verificable. CASTLE T (Testing) cubre el test de arquitectura generado. Veredicto CONDITIONAL si el
> proyecto tiene < 5 entidades (patrón prematuro) o si se usó `--no-tests`.

## Agentes
- **@architect** — Agente principal: decide la granularidad de las capas, valida que las dependencias apunten al dominio y redacta el ADR-001 con trade-offs
- **@developer** — Genera el scaffolding de archivos por capa y las firmas canónicas de use cases/repositories
- **@qa** — Valida que el test de arquitectura efectivamente FALLE ante un import prohibido (test del test)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Stack

### GATE IN
- [ ] Se recibió `[domain-name]` (BLOCKING CONDITION ya validó que existe)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Leer `.king/knowledge/stack.md`** y extraer el lenguaje principal (Go, TypeScript, Python) y el package/module root
2. [ ] **Resolver stack** desde `--stack` si se pasó; si no, inferirlo del stack declarado. Soportar `go`, `ts`, `python`
3. [ ] **Resolver layout** del stack: Go → `internal/{domain,application,infrastructure,delivery}`; TS → `src/{domain,application,infrastructure,presentation}`; Python → `src/{domain,application,infrastructure,delivery}`
4. [ ] **Detectar arquitectura existente** — leer `.king/knowledge/architecture.md` y el árbol del proyecto para no duplicar capas ya montadas. Marcar `EXISTS = true|false` para `[domain-name]`
5. [ ] **Resolver el tooling de arch-test** por stack: TS → `dependency-cruiser`; Go → `go-arch-lint`; Python → `import-linter`

### CHECKPOINT
- [ ] `STACK` resuelto (uno de `go|ts|python`) — si ambiguo, asumido con WARN explícito
- [ ] `LAYOUT` (mapa capa→directorio) definido para el stack
- [ ] `ARCH_TOOL` resuelto según stack
- [ ] `EXISTS` definido (si `true`, requiere confirmación de sobrescritura — BLOCKING CONDITION)

### OUTPUTS
- Variables: `STACK`, `LAYOUT`, `ARCH_TOOL`, `MODULE_ROOT`, `EXISTS`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el stack del proyecto.
Cause: `.king/knowledge/stack.md` ausente o sin lenguaje declarado, y `--stack` no provisto.
Recovery:
  [ ] Option A: pedir al usuario el stack (`--stack`) entre los 3 soportados (`go|ts|python`)
  [ ] Option B: inferir el stack del árbol del proyecto (`go.mod` → go, `package.json`/`tsconfig.json` → ts, `pyproject.toml`/`setup.py` → python) y continuar con WARN
  [ ] Option C: abortar y ejecutar `/genesis` para generar `.king/knowledge/stack.md` primero

---

## Phase 2: Prematurity Check

### GATE IN
- [ ] `STACK` y `LAYOUT` resueltos (Phase 1)

### MUST DO
1. [ ] **Contar entidades del dominio** — estimar el número de entidades/aggregates reales del proyecto (modelos de negocio con reglas, NO tablas CRUD). Usar el código existente, los modelos declarados, o preguntar al usuario si no es inferible
2. [ ] **Aplicar el Mapa de Decisión Rápida** de `knowledge/domain/architecture-patterns.md`: ¿el dominio tiene reglas de negocio reales o es CRUD sobre tablas? Si es CRUD puro, Clean es ceremonia vacía
3. [ ] **Si `entidades < 5`**: emitir WARNING "patrón prematuro" — explicar que Clean Architecture en un dominio chico o CRUD es overhead sin retorno (anillos vacíos), y ofrecer alternativa (`controller → repo` directo). Pedir confirmación explícita para continuar
4. [ ] **Registrar el veredicto de prematuridad** (`PREMATURE = true|false`) para el ADR y la Execution Summary

### CHECKPOINT
- [ ] Número de entidades estimado (con su fuente: código / declaración / usuario)
- [ ] Si `< 5` entidades: WARNING "patrón prematuro" emitido Y confirmación del usuario registrada
- [ ] `PREMATURE` definido

### OUTPUTS
- Variables: `ENTITY_COUNT`, `PREMATURE`, `DOMAIN_HAS_REAL_RULES` (bool)

### IF FAILS
ERROR: No se pudo determinar el número de entidades del dominio.
Cause: proyecto vacío, modelos no declarados, o dominio aún no modelado.
Recovery:
  [ ] Option A: preguntar al usuario cuántas entidades/aggregates de negocio prevé el dominio
  [ ] Option B: si el proyecto está vacío (greenfield), asumir `PREMATURE = true` por defecto y advertir que Clean en un proyecto sin dominio aún es prematuro — continuar solo con confirmación
  [ ] Option C: si el usuario insiste sin datos, continuar marcando `ENTITY_COUNT = unknown` y `PREMATURE = true` en el ADR

---

## Phase 3: Scaffold Layers

### GATE IN
- [ ] Prematurity check resuelto (Phase 2) — si `PREMATURE`, hay confirmación del usuario

### MUST DO
1. [ ] **Crear los directorios por capa** según `LAYOUT`:
   - Go: `internal/{domain,application,infrastructure,delivery}` (con sub-packages por `[domain-name]`)
   - TS: `src/{domain,application,infrastructure,presentation}`
   - Python: `src/{domain,application,infrastructure,delivery}` (con `__init__.py` por package)
2. [ ] **Agregar un README breve por capa** con su responsabilidad y la regla de dependencia (qué puede importar y qué NO)
3. [ ] **Respetar la regla de dependencia en el layout**: `domain` no importa nada; `application` importa `domain`; `infrastructure` y `delivery` importan `application`/`domain` pero NUNCA al revés
4. [ ] **Idempotencia** — si una capa ya existe (`EXISTS`), preservar su contenido y solo agregar lo faltante para `[domain-name]`

### CHECKPOINT
- [ ] Las 4 capas existen como directorios con el naming del stack
- [ ] Cada capa tiene README con su responsabilidad y restricción de imports
- [ ] Ningún directorio de `domain` contiene referencias a `infrastructure`/`delivery`

### OUTPUTS
- Estructura de directorios por capa (filesystem)

### IF FAILS
ERROR: No se pudieron crear los directorios de las capas.
Cause: permisos insuficientes, ruta inexistente, o `MODULE_ROOT` mal resuelto.
Recovery:
  [ ] Option A: verificar permisos del root del proyecto (`ls -ld`) y reintentar la creación
  [ ] Option B: si un package ya existe con contenido, NO sobrescribir — agregar solo los archivos faltantes
  [ ] Option C: mostrar al usuario el árbol propuesto y pedir confirmación de la ruta base

---

## Phase 4: Generate Contracts

### GATE IN
- [ ] Estructura de capas creada (Phase 3)

### MUST DO
1. [ ] **Generar ≥1 Entity base** en `domain/` con al menos un invariant protegido en el constructor/factory (ej. `Money` no puede ser negativo, `Order` no puede tener 0 items). La entity NO tiene imports de infra ni anotaciones de ORM
2. [ ] **Generar ≥1 Repository interface** (puerto) — para Go en `application` (interfaz consumida); para TS/Python en `application/ports`. SOLO la firma (`Save`, `FindById`, `FindByX`), SIN implementación. Naming del puerto sin prefijo de tecnología (`OrderRepository`, no `PostgresOrderRepository`)
3. [ ] **Generar ≥1 interfaz de Use Case** en `application/` con la firma canónica `Execute(input) → output` (Go: método de un struct/interface; TS: clase/interface con `execute`; Python: `__call__`/`execute`). El use case depende del puerto del repositorio, NO de su implementación
4. [ ] **Generar un adapter stub** en `infrastructure/` que implemente el repository interface (cuerpo vacío / `TODO`), para demostrar la dirección correcta de la dependencia (infra → application)
5. [ ] **Aplicar convenciones de naming** de `.king/knowledge/conventions.md` si existe

### CHECKPOINT
- [ ] ≥1 Entity con invariant protegido (lanza error/excepción al violarse)
- [ ] ≥1 Repository interface declarada en la capa de aplicación, SIN implementación en domain/application
- [ ] ≥1 Use Case con firma canónica `Execute(input) → output` dependiente del puerto
- [ ] El adapter stub en `infrastructure/` implementa el puerto (dependencia infra → application, correcta)
- [ ] `domain/` sin un solo import de `infrastructure`/`delivery`/ORM

### OUTPUTS
- Archivos: entity, repository port, use case, adapter stub (por capa)

### IF FAILS
ERROR: No se pudieron generar los contratos de las capas.
Cause: stack sin convención clara para interfaces, o `[domain-name]` ambiguo.
Recovery:
  [ ] Option A: usar la firma canónica genérica del stack (`execute`/`Execute`/`__call__`) y un invariant placeholder documentado
  [ ] Option B: pedir al usuario una regla de negocio concreta para materializar el invariant de la entity
  [ ] Option C: generar los contratos mínimos (1 entity + 1 puerto + 1 use case) y marcar el resto como TODO en el ADR

---

## Phase 5: Architecture Test + ADR

### GATE IN
- [ ] Contratos generados (Phase 4)

### MUST DO
1. [ ] **Si NO `--no-tests`**: generar el test de arquitectura con `ARCH_TOOL`:
   - TS → `.dependency-cruiser.cjs` con una regla `no-domain-to-infra` (severity `error`) que prohíbe que `^src/domain` importe `^src/infrastructure|^src/presentation`
   - Go → `.go-arch-lint.yml` con componentes por capa y `deps` que prohíben `domain → infrastructure|delivery`
   - Python → `.importlinter` (`importlinter` / `import-linter`) con un contrato `layers` (`domain` < `application` < `infrastructure`/`delivery`) o `forbidden` (`domain` no puede importar `infrastructure`)
2. [ ] **Verificar que el test FALLA ante una violación** — el test debe estar orientado de modo que un import `domain → infra` lo rompa (no al revés). @qa valida insertando temporalmente un import prohibido si es factible, o razonando la regla
3. [ ] **Si `--no-tests`**: omitir el test PERO advertir explícitamente que sin él la regla de dependencia es disciplina opcional, no garantía mecánica. Registrar el riesgo en el ADR y la Execution Summary
4. [ ] **Generar `ADR-001`** en `docs/adr/ADR-001-clean-architecture.md` (o `docs/architecture/`): contexto, decisión (adoptar Clean para `[domain-name]`), las 4 capas y la regla de dependencia, trade-offs (cuándo usar / cuándo NO usar — referenciando `knowledge/domain/architecture-patterns.md` §1), y el veredicto de prematuridad si `PREMATURE`
5. [ ] **Agregar el comando del arch-test** al runner del proyecto (script npm `arch:check`, `make arch-lint`, o target equivalente) si el proyecto lo soporta

### CHECKPOINT
- [ ] Test de arquitectura generado con la regla `domain ↛ infrastructure` (o `--no-tests` registrado con su riesgo)
- [ ] La orientación del test es correcta: FALLA si `domain` importa `infra`
- [ ] `ADR-001` creado con contexto, decisión, las 4 capas, trade-offs y veredicto de prematuridad
- [ ] El arch-test es invocable vía un script/target del proyecto (si aplica)

### OUTPUTS
- Archivos: config del arch-test (`ARCH_TOOL`), `ADR-001`, entrada en el runner

### IF FAILS
ERROR: No se pudo generar el test de arquitectura.
Cause: `ARCH_TOOL` no instalado en el proyecto o sin convención de configuración detectable.
Recovery:
  [ ] Option A: generar el archivo de configuración del arch-tool igualmente y documentar el comando de instalación (`npm i -D dependency-cruiser` / `go install ...go-arch-lint` / `pip install import-linter`)
  [ ] Option B: si la herramienta no se puede instalar, generar un test de import-check casero (script que falla si encuentra `import .../infrastructure` dentro de `domain/`) como fallback
  [ ] Option C: si `--no-tests`, registrar el riesgo en el ADR y continuar — el resto del scaffolding NO depende del test

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Estructura de directorios por capa según el stack
  - [ ] ≥1 Use Case con firma canónica en `application/`
  - [ ] ≥1 Entity con invariant protegido en `domain/`
  - [ ] ≥1 Repository interface (puerto) sin implementación
  - [ ] Test de arquitectura que FALLA si `domain` importa `infra` (o `--no-tests` con riesgo registrado)
  - [ ] `ADR-001` con trade-offs y veredicto de prematuridad
- [ ] `domain/` sin ningún import de `infrastructure`/`delivery`/ORM
- [ ] Si `entidades < 5`: WARNING "patrón prematuro" fue emitido y confirmado
- [ ] Ninguna versión de stack / ruta absoluta / nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(scaffolding + arch-test orientado correctamente = FORTIFIED; `< 5` entidades o `--no-tests` = CONDITIONAL; arch-test invertido/ausente sin justificar o domain importa infra = BREACHED)_ |
| Artifacts | _(estructura de capas; entity/puerto/use case/adapter stub; config arch-test; ADR-001)_ |
| Next Recommended | `/ddd-tactical [domain-name]` (modelar el dominio rico) o `/hexagonal-setup` (boundaries explícitos) |
| Risks | _(patrón prematuro si `< 5` entidades; sin garantía mecánica si `--no-tests`; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Dominio rico (invariantes complejos, lenguaje ubicuo) | `/ddd-tactical [domain-name]` — aggregates, VOs, domain events |
| Se anticipan múltiples adapters intercambiables (DB/cola/3ros) | `/hexagonal-setup` — ports driving/driven explícitos |
| Read y write divergen mucho | `/cqrs-setup` — separar Command de Query |
| Patrón prematuro confirmado (`< 5` entidades) | revisar la decisión; quizás `controller → repo` directo basta hasta que el dominio crezca |
| Scaffolding listo | implementar use cases con `/build`, validar con el arch-test en `/review` |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Layout por stack (las 4 capas)

| Capa | Go (`internal/`) | TS (`src/`) | Python (`src/`) | Responsabilidad |
|------|------------------|-------------|------------------|-----------------|
| Domain | `domain/` | `domain/` | `domain/` | Entities, value objects, domain events. CERO imports de infra |
| Application | `application/` | `application/` | `application/` | Use cases + puertos (interfaces). Depende solo de `domain` |
| Infrastructure | `infrastructure/` | `infrastructure/` | `infrastructure/` | Adapters (DB, HTTP, queue) que implementan los puertos |
| Delivery / Presentation | `delivery/` | `presentation/` | `delivery/` | HTTP handlers, gRPC, CLI, controllers, resolvers |

> **Nota de naming**: Go y Python usan `delivery/` (handlers/CLI); TS usa `presentation/` (controllers, resolvers, CLI handlers). Es la misma capa de entrada, distinto vocabulario por ecosistema. La fuente es M04 §M-25a.

### Tooling de test de arquitectura por stack

| Stack | Herramienta | Config | Regla generada |
|-------|-------------|--------|----------------|
| TypeScript | `dependency-cruiser` | `.dependency-cruiser.cjs` | `no-domain-to-infra`: `^src/domain` no puede importar `^src/infrastructure` ni `^src/presentation` (severity `error`) |
| Go | `go-arch-lint` | `.go-arch-lint.yml` | componentes por capa + `deps`: `domain` no puede depender de `infrastructure`/`delivery` |
| Python | `import-linter` | `.importlinter` | contrato `layers` (`domain` < `application` < `infrastructure`) o `forbidden` (`domain` ↛ `infrastructure`) |

> El test es la GARANTÍA MECÁNICA de la regla de dependencia. Sin él, la regla es disciplina opcional
> que se rompe en silencio (ver `knowledge/domain/architecture-patterns.md`, Regla de oro #7). Por eso
> `--no-tests` está DESACONSEJADO y siempre se registra como riesgo.

### Firma canónica de Use Case

| Stack | Patrón |
|-------|--------|
| Go | `type PlaceOrder interface { Execute(ctx, input) (output, error) }` + struct con dependencia del puerto |
| TS | `class PlaceOrderUseCase { execute(input): Promise<Output> }` — recibe el puerto por constructor (DI) |
| Python | `class PlaceOrder: def execute(self, input) -> Output` o `__call__` — recibe el puerto por `__init__` |

El use case SIEMPRE depende del **puerto** (interfaz del repositorio), nunca de su implementación
concreta. La implementación se inyecta desde la capa de composición (`infrastructure`/`delivery`).

### Entity con invariant (concepto)

Una entity protege sus invariantes en el constructor/factory: si los datos violan una regla de negocio,
NO se construye (lanza error/excepción). Ejemplos: `Money` rechaza montos negativos; `Order` no puede
crearse con 0 items; `Email` valida formato. La entity NO importa ORM ni framework — es negocio puro.
Detalle de DDD Tactical (aggregates, VOs, domain events) en `/ddd-tactical` y
`knowledge/domain/architecture-patterns.md` §3.

### Check de prematuridad (`< 5` entidades)

Clean Architecture se PAGA con dominios ricos y de larga vida. En un CRUD o un dominio chico, los
anillos son ceremonia vacía: indirección sin nada que proteger. Por eso, si el proyecto tiene `< 5`
entidades de negocio reales, el skill ADVIERTE "patrón prematuro" y ofrece la alternativa
`controller → repo` directo. La advertencia es obligatoria; la decisión final es del usuario. Fuente:
`knowledge/domain/architecture-patterns.md` (Mapa de Decisión Rápida + Regla de oro #2 "No apliques
patrones a un CRUD").

### Relación con otros skills del arco M04

`/clean-arch-setup` define DÓNDE va cada cosa (la regla de dependencia). Se complementa con
`/hexagonal-setup` (boundaries explícitos — Hexagonal ES una implementación de Clean), `/ddd-tactical`
(CÓMO se modela el dominio rico), `/cqrs-setup` y `/event-sourcing`. No son alternativas excluyentes:
son capas ortogonales (ver tabla de Combinaciones Comunes en `knowledge/domain/architecture-patterns.md`).
El delta spec del patrón está en
`openspec/changes/m04-architecture/specs/architecture-patterns/spec.md`.

### Integración con @architect y CASTLE A

`agents/architect.md` referencia `knowledge/domain/architecture-patterns.md` y puede invocar
`/clean-arch-setup` cuando detecta un dominio rico sin separación de capas. El test de arquitectura
generado alimenta CASTLE A (Architecture): un import `domain → infra` que rompe el arch-test es una
violación de la regla de dependencia, señal típica que CASTLE A vigila (ver §"Integración con CASTLE A"
del knowledge).
