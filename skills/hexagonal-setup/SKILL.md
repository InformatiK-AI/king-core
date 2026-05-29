---
name: hexagonal-setup
version: 2.0
api_version: 1.0.0
description: "Scaffoldea arquitectura Hexagonal (Ports & Adapters) — genera core/ con domain + application, ports/ explícitos (driving en in/, driven en out/), adapters/ separados en driving/ y driven/, y boundary tests que verifican que el Application Core no importa ningún adapter. Naming explícito: UserRepository (port) vs PostgresUserRepository (driven adapter). Usar cuando se necesite: montar arquitectura hexagonal, generar ports & adapters, separar driving/driven, aislar el dominio de la infra con boundaries verificables, o testear el core con adapters in-memory. Variante explícita de Clean Architecture."
---

# /hexagonal-setup — Ports & Adapters con Boundaries Verificables

Genera la estructura de **Arquitectura Hexagonal (Ports & Adapters)** para un módulo o proyecto.
Coloca el **Application Core** (domain + application) en el centro, expone **driving ports** (left/inbound)
y declara **driven ports** (right/outbound), y materializa los **adapters** separados en `adapters/driving/`
y `adapters/driven/`. Genera **boundary tests** que verifican mecánicamente que `core/` NUNCA importa
`adapters/`, además de adapters **in-memory** para testear el core sin infraestructura real. El naming es
explícito y no negociable: `UserRepository` es el **port** (interfaz que el core posee), `PostgresUserRepository`
es el **driven adapter** (implementación de infra). Alimenta la capa **CASTLE A** (Architecture: regla de
dependencia hacia el dominio + boundaries hexagonales).

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

> **Hexagonal vs. Clean**: son conceptualmente equivalentes (la dependencia apunta SIEMPRE hacia el dominio).
> Hexagonal es la forma MÁS EXPLÍCITA: nombra los puertos como contratos del dominio y separa driving/driven.
> No los enfrentes — Hexagonal es una implementación concreta de la regla de dependencia de Clean.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/domain/architecture-patterns.md` | Sección **2. Hexagonal (Ports & Adapters)** — driving/driven ports, regla de dependencia, boundary tests, estructura de directorios canónica. Fuente autoritativa de este skill. | Yes | framework |
| `.king/knowledge/stack.md` | Stack/lenguaje del proyecto — define extensiones (`.ts`/`.py`/`.go`/`.java`), tooling de boundary test (dependency-cruiser/ArchUnit/import-linter) y nombre de adapter de infra real | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de archivos, carpetas e interfaces del proyecto (sufijo `.port`, `.adapter`, etc.) | No | project |
| `knowledge/_inject/architecture-patterns.md` | Versión condensada para recordatorio rápido de la regla de dependencia | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[module-name]` ni se puede inferir el nombre del módulo/aggregate a scaffoldear
- [ ] El dominio es un **CRUD puro sin lógica de negocio** (controller→repo basta) — Hexagonal sería indirección sin valor; sugerir un controller→repo directo y abortar
- [ ] No se puede determinar el lenguaje/stack del proyecto (ni `.king/knowledge/stack.md` ni input del usuario)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA generar un import desde `core/` hacia `adapters/` — la dirección de dependencia apunta SIEMPRE hacia el dominio
- NUNCA poner una anotación de ORM, un cliente HTTP, un SDK de broker o un import de framework dentro de `core/domain/` o `core/application/`
- NUNCA implementar lógica de infraestructura real en este skill (conexión a DB, llamadas de red) — solo el ESQUELETO del adapter con `// TODO: implementación de infra`
- NUNCA colapsar driving y driven en una sola carpeta `adapters/` — DEBEN separarse en `adapters/driving/` y `adapters/driven/`
- NUNCA nombrar el port con prefijo de tecnología (`PostgresUserRepository` como port es ERROR) — el port es `UserRepository`; la tecnología vive SOLO en el adapter
- NUNCA sobreescribir archivos existentes sin confirmación explícita del usuario
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Árbol de directorios hexagonal creado: `core/{domain,application,ports/{in,out}}` + `adapters/{driving,driven}`
- [ ] ≥1 **driving port** (interfaz inbound, ej. `PlaceOrderUseCase`/`<Module>UseCase`) en `core/ports/in/`
- [ ] ≥1 **driven port** (interfaz outbound, ej. `UserRepository`) en `core/ports/out/`
- [ ] ≥1 **driving adapter** en `adapters/driving/` (ej. HTTP controller que invoca el driving port)
- [ ] ≥1 **driven adapter** real-stub en `adapters/driven/` con naming `<Tech><Port>` (ej. `PostgresUserRepository`)
- [ ] ≥1 **driven adapter in-memory** para tests (ej. `InMemoryUserRepository`) en `adapters/driven/` o `test/`
- [ ] **Boundary test** que falla si `core/` importa cualquier cosa de `adapters/` (dependency-cruiser/ArchUnit/import-linter o test programático)
- [ ] Application service en `core/application/` que depende SOLO de ports (nunca de adapters)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Detect    (Scaffold (Generate (Generate (Boundary (Session)  (Guide)
          stack &    skeleton) ports)    adapters  tests)
          fitness)             in/out    driving/
                                         driven)
```

### PARÁMETROS
```
/hexagonal-setup [module-name] [--lang ts|py|go|java|...] [--port <root-path>] [--driven postgres,kafka,...] [--driving http,cli,...]
```
- `[module-name]`: nombre del módulo/aggregate a scaffoldear (ej. `user`, `order`). Deriva el naming de ports/adapters
- `--lang`: lenguaje del scaffold (default: auto-detectado desde `.king/knowledge/stack.md`)
- `--port`: ruta raíz donde colgar `core/` y `adapters/` (default: `src/`)
- `--driven`: tecnologías de driven adapters a stubear (default: `postgres` + `in-memory`)
- `--driving`: tecnologías de driving adapters a stubear (default: `http`)

---

## CASTLE activo: _-A-_-_-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> Alimenta CASTLE A (Architecture) con dos checks: (1) la regla de dependencia (core no importa adapters) y
> (2) los boundaries hexagonales (driving/driven separados, port sin prefijo de tecnología). El boundary test
> generado es la garantía MECÁNICA — sin gate de bloqueo propio salvo que `@architect` lo eleve durante `/review`.

## Agentes
- **@architect** — Agente principal: decide fitness del patrón (Hexagonal vs CRUD vs Clean), define los boundaries y valida la regla de dependencia
- **@developer** — Genera el esqueleto de ports/adapters/services siguiendo el naming explícito
- **@qa** — Diseña los boundary tests y los adapters in-memory para testear el core en aislamiento

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Stack & Fitness

### GATE IN
- [ ] Se recibió `[module-name]` o se puede inferir (BLOCKING CONDITION ya validó input)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Leer `knowledge/domain/architecture-patterns.md` → sección 2 (Hexagonal)** y fijar la estructura canónica como referencia (core/ports/{in,out}, adapters/{driving,driven})
2. [ ] **Leer `.king/knowledge/stack.md`** y resolver: `LANG`, extensión de archivos, y herramienta de boundary test disponible (dependency-cruiser para TS/JS, ArchUnit para Java/Kotlin, import-linter para Python, go list/test para Go)
3. [ ] **Evaluar fitness del patrón** (con @architect) — confirmar que el dominio tiene reglas de negocio reales y/o ≥2 adapters intercambiables por port o necesidad de testear el core aislado. Si es CRUD puro, activar la BLOCKING CONDITION y abortar con recomendación controller→repo
4. [ ] **Resolver paths y tecnologías** — `ROOT` (de `--port`, default `src/`), `DRIVEN[]` (de `--driven`, default `postgres` + `in-memory`), `DRIVING[]` (de `--driving`, default `http`)
5. [ ] **Derivar naming del módulo** — desde `[module-name]`: port driven `<Module>Repository`, adapter driven `Postgres<Module>Repository` + `InMemory<Module>Repository`, driving port `<Module>UseCase`, driving adapter `<Module>Controller`

### CHECKPOINT
- [ ] `LANG` + extensión + herramienta de boundary test resueltos (si ambiguo, asumido con WARN explícito)
- [ ] Fitness confirmado: el patrón aplica (NO es CRUD puro)
- [ ] `ROOT`, `DRIVEN[]`, `DRIVING[]` y naming del módulo definidos

### OUTPUTS
- Variables: `LANG`, `EXT`, `BOUNDARY_TOOL`, `ROOT`, `MODULE`, `DRIVEN[]`, `DRIVING[]`, naming derivado

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el stack o el fitness del patrón.
Cause: `.king/knowledge/stack.md` ausente/sin lenguaje declarado, o el dominio es un CRUD sin lógica.
Recovery:
  [ ] Option A: pedir al usuario el lenguaje (`--lang`) y confirmar que hay lógica de negocio o múltiples adapters
  [ ] Option B: si es CRUD puro, NO scaffoldear Hexagonal — recomendar controller→repo directo y cerrar (no es error, es la decisión correcta)
  [ ] Option C: asumir `ts` + dependency-cruiser (default más común), marcar el scaffold como tentativo y continuar con WARN

---

## Phase 2: Scaffold Skeleton

### GATE IN
- [ ] `LANG`, `ROOT` y naming del módulo resueltos (Phase 1)

### MUST DO
1. [ ] **Crear el árbol de directorios** bajo `ROOT`:
   ```
   {ROOT}/
   ├── core/
   │   ├── domain/                 # entidades del módulo — CERO imports de infra
   │   ├── application/            # services/use cases — dependen SOLO de ports
   │   └── ports/
   │       ├── in/                 # driving ports (left/inbound)
   │       └── out/                # driven ports (right/outbound)
   └── adapters/
       ├── driving/                # driving adapters (HTTP, CLI, test) → invocan ports/in
       └── driven/                 # driven adapters (Postgres, Kafka, in-memory) → implementan ports/out
   ```
2. [ ] **Generar la entidad de dominio** mínima en `core/domain/<module>.<ext>` (negocio puro, sin imports de infra)
3. [ ] **Verificar que no se sobreescribe nada** — si un archivo/carpeta destino existe, listar y pedir confirmación antes de continuar

### CHECKPOINT
- [ ] `core/{domain,application,ports/in,ports/out}` existen
- [ ] `adapters/{driving,driven}` existen (driving y driven SEPARADOS, nunca colapsados)
- [ ] Entidad de dominio creada sin imports de infra
- [ ] Ningún archivo existente sobreescrito sin confirmación

### OUTPUTS
- Estructura de directorios hexagonal en disco
- `core/domain/<module>.<ext>`

### IF FAILS
ERROR: No se pudo crear la estructura de directorios.
Cause: permisos, ruta `ROOT` inválida, o colisión con archivos existentes.
Recovery:
  [ ] Option A: pedir al usuario una `--port` (ruta raíz) alternativa
  [ ] Option B: si hay colisión, generar bajo `{ROOT}/<module>/` para aislar el módulo nuevo
  [ ] Option C: listar archivos en conflicto y pedir confirmación de sobreescritura selectiva

---

## Phase 3: Generate Ports (in / out)

### GATE IN
- [ ] Estructura `core/ports/{in,out}` creada (Phase 2)

### MUST DO
1. [ ] **Generar el driven port (outbound)** en `core/ports/out/<module>-repository.<ext>` — interfaz `<Module>Repository` con métodos de colección (`save`, `findById`, `findAll`). Es un CONTRATO que el core POSEE; NO contiene tecnología en el nombre ni en el cuerpo
2. [ ] **Generar el driving port (inbound)** en `core/ports/in/<module>-usecase.<ext>` — interfaz `<Module>UseCase` que el core EXPONE para que lo invoquen los driving adapters (ej. `placeOrder(...)`/`registerUser(...)`)
3. [ ] **Generar el application service** en `core/application/<module>.service.<ext>` — implementa el driving port `<Module>UseCase` y depende SOLO del driven port `<Module>Repository` (inyectado por constructor). NUNCA importa un adapter
4. [ ] **Verificar imports del core** — todos los imports de `core/application/` apuntan a `core/domain/` o `core/ports/` — JAMÁS a `adapters/`

### CHECKPOINT
- [ ] Driven port `<Module>Repository` en `core/ports/out/` SIN prefijo de tecnología
- [ ] Driving port `<Module>UseCase` en `core/ports/in/`
- [ ] Application service implementa el driving port y depende solo del driven port (inyección por constructor)
- [ ] Ningún import de `core/` apunta a `adapters/`

### OUTPUTS
- `core/ports/out/<module>-repository.<ext>` (driven port)
- `core/ports/in/<module>-usecase.<ext>` (driving port)
- `core/application/<module>.service.<ext>` (service)

### IF FAILS
ERROR: No se pudieron generar los ports o el service viola la regla de dependencia.
Cause: el service necesita un detalle de infra (no debería) o el naming del port incluye tecnología.
Recovery:
  [ ] Option A: si el service "necesita" infra, mover esa responsabilidad detrás de un nuevo driven port (invertir la dependencia)
  [ ] Option B: si el port tiene prefijo de tecnología, renombrarlo al contrato puro (`UserRepository`) y mover la tecnología al adapter
  [ ] Option C: regenerar el service con el repositorio inyectado por constructor (dependency injection) y reintentar el CHECKPOINT

---

## Phase 4: Generate Adapters (driving / driven)

### GATE IN
- [ ] Ports `in/` y `out/` generados (Phase 3)

### MUST DO
1. [ ] **Generar el driven adapter real-stub** en `adapters/driven/persistence/postgres-<module>-repository.<ext>` — clase `Postgres<Module>Repository` que IMPLEMENTA `<Module>Repository` (el driven port). Cuerpo de los métodos = esqueleto con `// TODO: implementación de infra` (este skill NO implementa la conexión real)
2. [ ] **Generar el driven adapter in-memory** en `adapters/driven/persistence/in-memory-<module>-repository.<ext>` — clase `InMemory<Module>Repository` que implementa el MISMO port con un `Map`/dict en memoria. Es la pieza que permite testear el core sin infra real
3. [ ] **Generar el driving adapter** en `adapters/driving/http/<module>.controller.<ext>` — clase `<Module>Controller` que recibe el driving port `<Module>UseCase` (inyectado) y lo invoca. NO contiene lógica de negocio
4. [ ] **Verificar la dirección de dependencias** — cada adapter importa del `core/` (ports/domain); NINGÚN archivo de `core/` importa de `adapters/`. El wiring/composición (qué adapter concreto se inyecta) vive FUERA del core (composition root / infraestructura)

### CHECKPOINT
- [ ] `Postgres<Module>Repository` en `adapters/driven/` implementa el driven port (stub con TODO)
- [ ] `InMemory<Module>Repository` en `adapters/driven/` implementa el MISMO driven port (en memoria)
- [ ] `<Module>Controller` en `adapters/driving/` invoca el driving port (sin lógica de negocio)
- [ ] Adapters importan del core; el core NO importa de adapters

### OUTPUTS
- `adapters/driven/persistence/postgres-<module>-repository.<ext>` (real-stub)
- `adapters/driven/persistence/in-memory-<module>-repository.<ext>` (test double)
- `adapters/driving/http/<module>.controller.<ext>` (driving adapter)

### IF FAILS
ERROR: No se pudieron generar los adapters o se invirtió la dirección de dependencia.
Cause: un adapter no respeta la firma del port, o el core terminó importando un adapter.
Recovery:
  [ ] Option A: alinear la firma del adapter con la interfaz exacta del port (mismo contrato)
  [ ] Option B: si el core importaba un adapter, mover el wiring a un composition root (`main`/`server`/`infrastructure`) fuera del core
  [ ] Option C: generar solo el in-memory adapter primero (mínimo viable para el boundary test) y stubear el resto con TODO

---

## Phase 5: Boundary Tests

### GATE IN
- [ ] Ports y adapters generados (Phase 3, Phase 4)

### MUST DO
1. [ ] **Generar el boundary test arquitectónico** con `BOUNDARY_TOOL` — una regla que FALLA si cualquier archivo bajo `core/` importa cualquier cosa bajo `adapters/`:
   - TS/JS: regla `dependency-cruiser` (`forbidden`: `core` → `adapters`)
   - Java/Kotlin: test `ArchUnit` (`noClasses().that().resideInAPackage("..core..").should().dependOnClassesThat().resideInAPackage("..adapters..")`)
   - Python: `import-linter` contract (layers: `core` no puede importar `adapters`)
   - Go: test que recorre imports de `core/` y falla si referencia `adapters/`
2. [ ] **Generar el test de comportamiento del core con in-memory** — un test que instancia el application service con `InMemory<Module>Repository` (NO Postgres) y verifica un caso de uso, demostrando que el core se testea SIN infra real
3. [ ] **Documentar el wiring** — un snippet (en el REFERENCE o composition root stub) que muestra cómo inyectar `Postgres<Module>Repository` en prod y `InMemory<Module>Repository` en test, todo FUERA del core
4. [ ] **Ejecutar (o describir cómo ejecutar) el boundary test** — confirmar que pasa con la estructura generada (el core limpio debe pasar; un import core→adapter debe romperlo)

### CHECKPOINT
- [ ] Boundary test arquitectónico generado (falla si `core/` importa `adapters/`)
- [ ] Test de core con `InMemory<Module>Repository` generado (core testeado sin infra)
- [ ] Wiring documentado (inyección del adapter concreto FUERA del core)
- [ ] El boundary test PASA con la estructura limpia generada

### OUTPUTS
- Boundary test (config `dependency-cruiser` / test `ArchUnit` / contract `import-linter` / test Go)
- Test de comportamiento del core con in-memory adapter
- Reporte final del scaffold (árbol generado + naming + cómo correr los tests)

### IF FAILS
ERROR: El boundary test no se pudo generar o no pasa con la estructura limpia.
Cause: herramienta de boundary test no disponible en el stack, o un import residual core→adapter.
Recovery:
  [ ] Option A: si la herramienta no está, generar un boundary test PROGRAMÁTICO (lee imports de `core/` y assert que ninguno apunta a `adapters/`)
  [ ] Option B: si falla por un import residual, localizar el import core→adapter y corregirlo (mover el wiring fuera del core)
  [ ] Option C: marcar el boundary test como TODO con la regla escrita pero sin runner, y recomendar instalar la herramienta (dependency-cruiser/ArchUnit/import-linter)

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Árbol `core/{domain,application,ports/{in,out}}` + `adapters/{driving,driven}` creado
  - [ ] Driving port `<Module>UseCase` en `core/ports/in/`
  - [ ] Driven port `<Module>Repository` en `core/ports/out/` (SIN prefijo de tecnología)
  - [ ] Driving adapter `<Module>Controller` en `adapters/driving/`
  - [ ] Driven adapter `Postgres<Module>Repository` (real-stub) en `adapters/driven/`
  - [ ] Driven adapter `InMemory<Module>Repository` (test double) en `adapters/driven/` o `test/`
  - [ ] Boundary test (falla si `core/` importa `adapters/`)
  - [ ] Application service que depende SOLO de ports
- [ ] La regla de dependencia se respeta: NINGÚN import de `core/` apunta a `adapters/`
- [ ] driving y driven están SEPARADOS (nunca colapsados en una sola carpeta `adapters/`)
- [ ] El port NO tiene prefijo de tecnología; la tecnología vive SOLO en el adapter
- [ ] El boundary test PASA con la estructura limpia
- [ ] Ningún archivo existente fue sobreescrito sin confirmación
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(boundaries OK + boundary test pasa=FORTIFIED; boundary test como TODO sin runner / herramienta ausente=CONDITIONAL; import core→adapter sin corregir=BREACHED solo si @architect lo eleva en /review)_ |
| Artifacts | _(árbol hexagonal: core/ports/in+out, adapters/driving+driven, boundary test, in-memory adapter; + session document)_ |
| Next Recommended | `/ddd-tactical <module>` (modelar el dominio rico dentro del core) o `/review` (validar boundaries) |
| Risks | _(adapters generados como stub con TODO de infra; boundary test sin runner si la herramienta no está instalada; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| El dominio dentro del core es rico (invariantes, VOs) | `/ddd-tactical <module>` — modelar aggregates/VOs/domain events DENTRO de `core/domain/` |
| Read y write divergen mucho | `/cqrs-setup` — separar Command (aggregate) de Query (read model) sobre el core hexagonal |
| Adapters stub listos para implementar infra real | `/build` — implementar `Postgres<Module>Repository` (conexión real) |
| Verificar que los boundaries se sostienen | `/review` — @architect valida la regla de dependencia y los ports |
| Boundary test sin runner (herramienta ausente) | instalar dependency-cruiser/ArchUnit/import-linter y re-ejecutar el boundary test |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Estructura hexagonal generada (canónica)

```
src/
├── core/                                   # Application Core — NUNCA importa adapters
│   ├── domain/
│   │   └── user.ts                         # entidad de dominio — cero imports de infra
│   ├── application/
│   │   └── user.service.ts                 # implementa UserUseCase, depende solo de UserRepository
│   └── ports/
│       ├── in/                             # DRIVING ports (left / inbound)
│       │   └── user-usecase.ts             # UserUseCase — lo que el core EXPONE
│       └── out/                            # DRIVEN ports (right / outbound)
│           └── user-repository.ts          # UserRepository — lo que el core NECESITA
└── adapters/
    ├── driving/                            # DRIVING adapters (left) → invocan ports/in
    │   └── http/user.controller.ts         # UserController
    └── driven/                             # DRIVEN adapters (right) → implementan ports/out
        └── persistence/
            ├── postgres-user-repository.ts # PostgresUserRepository (infra real, stub)
            └── in-memory-user-repository.ts# InMemoryUserRepository (test double)
```

### Naming explícito: port vs adapter (regla innegociable)

| Concepto | Nombre | Ubicación | Rol |
|----------|--------|-----------|-----|
| Driven **port** | `UserRepository` | `core/ports/out/` | Contrato que el core POSEE. SIN tecnología en el nombre |
| Driven **adapter** (real) | `PostgresUserRepository` | `adapters/driven/` | Implementa el port con Postgres |
| Driven **adapter** (test) | `InMemoryUserRepository` | `adapters/driven/` o `test/` | Implementa el MISMO port en memoria |
| Driving **port** | `UserUseCase` | `core/ports/in/` | Lo que el core EXPONE a los driving adapters |
| Driving **adapter** | `UserController` | `adapters/driving/` | Traduce HTTP → driving port; sin lógica de negocio |

> El error caro: nombrar `PostgresUserRepository` como port. El port es el CONTRATO (`UserRepository`).
> La tecnología (Postgres, Mongo, in-memory) vive SOLO en el adapter. Cambiar de DB = otro adapter, mismo port, core intacto.

### Driving (left) vs Driven (right)

| Lado | También llamado | Quién manda | Ejemplos de adapter | Port que toca |
|------|-----------------|-------------|---------------------|---------------|
| **Driving** (left, inbound) | primary | el actor USA la app | HTTP controller, CLI, test runner | implementa-invoca `ports/in` (`UserUseCase`) |
| **Driven** (right, outbound) | secondary | la app USA la infra | Postgres, Kafka, Stripe, in-memory | implementa `ports/out` (`UserRepository`) |

### Boundary test por stack

| Stack | Herramienta | Regla |
|-------|-------------|-------|
| TS/JS | dependency-cruiser | `forbidden`: módulos en `core` no pueden depender de `adapters` |
| Java/Kotlin | ArchUnit | `noClasses().that().resideInAPackage("..core..").should().dependOnClassesThat().resideInAPackage("..adapters..")` |
| Python | import-linter | contrato `layers`: `core` por encima de `adapters`, sin imports descendentes invertidos |
| Go | go test | test custom que recorre los imports de `core/` y falla si referencia `adapters/` |
| Cualquiera | test programático | lee los imports de `core/` y `assert` que ninguno apunta a `adapters/` (fallback sin tooling) |

### Wiring (composition root) — FUERA del core

El core no decide qué adapter usar. El composition root (en `infrastructure`/`main`/`server`) inyecta:

```ts
// prod: src/infrastructure/server.ts  (FUERA del core)
const repo = new PostgresUserRepository(pool);   // driven adapter real
const useCase = new UserService(repo);           // core: depende solo del port
const controller = new UserController(useCase);  // driving adapter

// test:
const repo = new InMemoryUserRepository();       // mismo port, otra implementación
const useCase = new UserService(repo);           // el core no cambia → testeable sin infra
```

### Hexagonal vs Clean Architecture

Son conceptualmente equivalentes: la dependencia apunta SIEMPRE hacia el dominio. Diferencias de énfasis:

| | Clean Architecture | Hexagonal (este skill) |
|--|---------------------|------------------------|
| Metáfora | anillos concéntricos | hexágono con puertos |
| Ports | "interfaces" en application | EXPLÍCITOS: `ports/in` (driving) + `ports/out` (driven) |
| Adapters | "interface adapters" en una capa | SEPARADOS: `adapters/driving` + `adapters/driven` |
| Énfasis | dónde van las dependencias (anillos) | boundaries explícitos y verificables |

No los enfrentes: Hexagonal ES una forma concreta de implementar la regla de dependencia de Clean.
Ver `knowledge/domain/architecture-patterns.md` secciones 1 y 2 para el detalle completo.

### Cuándo NO usar (abortar y recomendar alternativa)

- **CRUD puro sin lógica**: si el core solo pasa datos del controller al repo, los ports son indirección sin valor → controller→repo directo
- **Nunca habrá más de un adapter por port y no testeás el core aislado**: la abstracción no se paga sola
- Ver la sección 2 ("Cuándo NO usar") de `knowledge/domain/architecture-patterns.md`

### Integración con @architect y CASTLE A

`agents/architect.md` invoca o consulta los outputs de `/hexagonal-setup` durante `/review`. El check CASTLE A
"adapter referenciado desde el core" se marca como violación cuando el Application Core importa un adapter
concreto en vez del port. El boundary test generado por este skill es la garantía mecánica que evita ese drift.
