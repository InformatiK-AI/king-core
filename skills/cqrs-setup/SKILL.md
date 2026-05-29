---
name: cqrs-setup
version: 2.0
api_version: 1.0.0
description: "Configura CQRS para un dominio: command bus + handlers (retornan void o ID), query bus + handlers (retornan DTO, nunca mutan), read models desnormalizados, command validators y tests de cada handler. El ENFORCEMENT es por TIPOS: un Command NO puede leer y una Query NO puede escribir (firmas + marker types que lo hacen imposible de compilar, no una convención). Si el stack lo soporta, SUGIERE DB separada read/write (CQRS completo). Usar cuando se necesite: separar lectura de escritura, montar un command/query bus, generar read models para UI/reportes, o cuando read y write divergen mucho. ADVIERTE 'patrón prematuro' si es un CRUD donde la pantalla muestra exactamente lo que se guarda."
---

# /cqrs-setup — Command/Query separados con enforcement por tipos

Configura **CQRS** (Command Query Responsibility Segregation) para un dominio: genera el **command bus**
con sus handlers (que mutan el write model y retornan `void` o un ID — NUNCA el estado), el **query bus**
con sus handlers (que leen del read model y retornan un DTO — NUNCA mutan), los **read models
desnormalizados** optimizados por vista, los **command validators**, y los **tests** de command handler y
query handler. La separación NO es una convención de carpetas: es un **enforcement por tipos** — las firmas
y los marker types hacen que un Command que intente leer o una Query que intente escribir NO compilen.

> **Regla transversal innegociable**: una operación o CAMBIA estado (Command → `void`/ID) o DEVUELVE datos
> (Query → DTO) — nunca ambas. El Command va contra el write model (típicamente un aggregate DDD); la Query
> lee de un read model desnormalizado y NO toca el aggregate. Si un handler hace las dos cosas, no es CQRS:
> es un service con un nombre nuevo. Ver `knowledge/domain/architecture-patterns.md` §4.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack, lenguaje y motor de DB del proyecto — fuente del scaffolding y del check de DB separada read/write | Yes | project |
| `.king/knowledge/architecture.md` | Arquitectura existente (¿hay Clean/DDD? ¿aggregates ya modelados?) — el write side de CQRS se apoya en el aggregate existente, no lo duplica | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de comandos, queries, handlers, DTOs y tests | No | project |
| `knowledge/domain/architecture-patterns.md` | Clean/Hexagonal/DDD/CQRS/ES con trade-offs (custom: este skill materializa el patrón CQRS del §4 — command/query bus, read models, niveles simple vs completo — y usa el Mapa de Decisión Rápida + Regla de oro #5 para el check de prematuridad) | Yes | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[domain]` (el nombre del contexto es obligatorio)
- [ ] No se provee ni un solo command (`--commands`) ni una sola query (`--queries`) — CQRS sin ninguna operación no tiene nada que separar
- [ ] El stack no es resoluble (ni `--lang` ni `.king/knowledge/stack.md` declaran el lenguaje)
- [ ] Ya existe un setup CQRS para ese `[domain]` y el usuario NO confirmó sobrescribir

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA generar un command handler que LEA y retorne estado de negocio — un Command retorna `void` o un ID, jamás el aggregate ni un DTO de lectura (eso lo vuelve una Query disfrazada)
- NUNCA generar un query handler que MUTE estado — una Query lee del read model y retorna un DTO; cero `save`/`insert`/`update`/`delete` ni emisión de eventos
- NUNCA hacer que la separación dependa solo de la disciplina del dev — el enforcement DEBE ser por tipos (firmas + marker types/interfaces) de modo que la violación NO compile (o, en lenguajes dinámicos, falle un test/lint dedicado)
- NUNCA leer del aggregate (write model) dentro de una Query — la Query consulta el READ MODEL desnormalizado, nunca el modelo de escritura
- NUNCA continuar el scaffolding sin advertir si el dominio es un CRUD donde la pantalla muestra exactamente lo que se guarda (patrón prematuro) — la advertencia es obligatoria, la decisión es del usuario
- NUNCA hardcodear connection strings, versiones de stack, rutas absolutas ni nombres de proyecto — usar `.king/knowledge/stack.md` y `{{SLOT}}`
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] **Command bus** con registro de handlers (`register(CommandType → handler)`) y un `dispatch(command)` tipado
- [ ] **Query bus** con registro de handlers (`register(QueryType → handler)`) y un `ask(query)` tipado
- [ ] ≥1 **Command handler** que muta el write model y retorna `void` o un ID (NUNCA estado de lectura)
- [ ] ≥1 **Query handler** que lee del read model y retorna un DTO (NUNCA muta)
- [ ] ≥1 **Read model** desnormalizado (DTO optimizado para una vista/pantalla concreta)
- [ ] ≥1 **Command validator** (valida el command ANTES de llegar al handler — middleware o decorator del bus)
- [ ] **Enforcement por tipos** verificable: marker types/interfaces (`Command`/`Query`) + firmas que hacen imposible que un Command lea o una Query escriba (o test/lint equivalente en lenguaje dinámico)
- [ ] **Tests**: command handler unit test + query handler unit test (incluye el test que prueba que la separación se respeta)
- [ ] **Recomendación de DB separada read/write** si el stack lo soporta (CQRS completo) o nota de CQRS simple (misma DB, distintos modelos) con su trade-off
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase N+1 → Phase N+2
(Context)(Detect   (Prematurity (Buses +  (Handlers+(Validators(DB split (Session)  (Guide)
          stack)    check)       contracts)read mdls)+ tests)  advice)
```

### PARÁMETROS
```
/cqrs-setup [domain] --commands <c1,c2,...> --queries <q1,q2,...> [--lang ts|py|go|java|...] [--db-split auto|same|separate] [--no-tests]
```
- `[domain]`: nombre del contexto/módulo (ej. `orders`, `billing`). Obligatorio
- `--commands`: lista de comandos de negocio (ej. `CreateOrder,CancelOrder`). Al menos uno entre commands/queries es obligatorio
- `--queries`: lista de queries principales (ej. `GetOrderById,ListOrdersByCustomer`)
- `--lang`: fuerza el lenguaje del scaffold (default: auto-detectado desde `.king/knowledge/stack.md`)
- `--db-split`: `auto` (recomienda según el stack, default), `same` (CQRS simple — misma DB), `separate` (CQRS completo — read store separado, sincronizado por eventos)
- `--no-tests`: omite la generación de tests de handlers (DESACONSEJADO — el test es lo que prueba que la separación se respeta; el skill advierte el riesgo)

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) es la capa central: el skill MATERIALIZA la separación Command/Query y la vuelve
> verificable por tipos. CASTLE T (Testing) cubre los unit tests de handlers y el test de la separación.
> Veredicto CONDITIONAL si el dominio es un CRUD que no diverge read/write (patrón prematuro) o si se usó
> `--no-tests`. BREACHED si un handler viola la separación (Command lee / Query escribe).

## Agentes
- **@architect** — Agente principal: decide los read models por vista, valida que el write side se apoye en el aggregate existente (no lo duplique), evalúa si conviene DB separada read/write y registra los trade-offs
- **@developer** — Genera el command/query bus, los handlers, los read models, los validators y los marker types del enforcement
- **@qa** — Valida que el enforcement por tipos efectivamente impida que un Command lea o una Query escriba (test del enforcement) y que los unit tests de handler cubran el happy path y la validación

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Stack

### GATE IN
- [ ] Se recibió `[domain]` y al menos un `--commands` o `--queries` (BLOCKING CONDITIONS ya validaron que existen)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Leer `.king/knowledge/stack.md`** y extraer el lenguaje principal, el module/package root y el motor de DB
2. [ ] **Resolver lenguaje** desde `--lang` si se pasó; si no, inferirlo del stack declarado
3. [ ] **Resolver soporte de tipos para el enforcement** — clasificar el lenguaje en `static` (TS/Go/Java/Rust/C#: el enforcement es por compilador) o `dynamic` (Python/JS/Ruby: el enforcement se respalda con type hints + un test/lint dedicado)
4. [ ] **Detectar arquitectura existente** — leer `.king/knowledge/architecture.md`: ¿hay Clean/DDD? ¿existe ya un aggregate para `[domain]`? El write side de CQRS se APOYA en ese aggregate, no lo duplica. Marcar `EXISTS = true|false` para el setup CQRS de `[domain]`
5. [ ] **Resolver capacidad de DB separada read/write** — según el motor de DB del stack: replicas de lectura, segunda DB, o vista materializada. Marcar `DB_SPLIT_CAPABLE = true|false`

### CHECKPOINT
- [ ] `LANG` resuelto — si ambiguo, asumido con WARN explícito
- [ ] `TYPE_MODE` definido (`static` | `dynamic`) — determina cómo se materializa el enforcement
- [ ] `EXISTS` definido (si `true`, requiere confirmación de sobrescritura — BLOCKING CONDITION)
- [ ] `DB_SPLIT_CAPABLE` definido (alimenta la recomendación de Phase 6)

### OUTPUTS
- Variables: `LANG`, `TYPE_MODE`, `MODULE_ROOT`, `EXISTS`, `DB_SPLIT_CAPABLE`, `DB_ENGINE`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el stack del proyecto.
Cause: `.king/knowledge/stack.md` ausente o sin lenguaje declarado, y `--lang` no provisto.
Recovery:
  [ ] Option A: pedir al usuario el lenguaje (`--lang`)
  [ ] Option B: inferir el lenguaje del árbol del proyecto (`go.mod`→go, `package.json`/`tsconfig.json`→ts, `pyproject.toml`→python, `pom.xml`/`build.gradle`→java) y continuar con WARN
  [ ] Option C: abortar y ejecutar `/genesis` para generar `.king/knowledge/stack.md` primero

---

## Phase 2: Prematurity Check

### GATE IN
- [ ] `LANG` y `TYPE_MODE` resueltos (Phase 1)

### MUST DO
1. [ ] **Evaluar divergencia read/write** — ¿el modelo de lectura y el de escritura divergen de verdad (vistas desnormalizadas para UI/reportes vs aggregate normalizado), o la pantalla muestra exactamente lo que se guarda? Usar `--commands`/`--queries` y el código existente
2. [ ] **Aplicar el Mapa de Decisión Rápida + Regla de oro #5** de `knowledge/domain/architecture-patterns.md`: "CQRS sin necesidad = duplicación". Si es un CRUD que no diverge, dos modelos y dos buses son duplicación pura
3. [ ] **Si NO hay divergencia real** (CRUD simple, lecturas y escrituras escalan igual, una sola vista del dato sirve): emitir WARNING "patrón prematuro" — explicar que CQRS sobre un CRUD agrega un bus y dos modelos sin retorno, e introduce la trampa de consistencia eventual del read model. Pedir confirmación explícita para continuar
4. [ ] **Registrar el veredicto** (`PREMATURE = true|false`) y la razón para la Execution Summary

### CHECKPOINT
- [ ] Divergencia read/write evaluada (con su evidencia: vistas vs aggregate)
- [ ] Si NO hay divergencia real: WARNING "patrón prematuro" emitido Y confirmación del usuario registrada
- [ ] `PREMATURE` definido

### OUTPUTS
- Variables: `READ_WRITE_DIVERGES` (bool), `PREMATURE`, `PREMATURE_REASON`

### IF FAILS
ERROR: No se pudo determinar si read y write divergen.
Cause: dominio aún no modelado, queries/commands sin contexto de pantalla, o proyecto vacío.
Recovery:
  [ ] Option A: preguntar al usuario si alguna query necesita una vista que NO es el reflejo directo de lo que escribe un command
  [ ] Option B: si el proyecto está vacío (greenfield), asumir `PREMATURE = true` por defecto y advertir que CQRS sin divergencia conocida es prematuro — continuar solo con confirmación
  [ ] Option C: si el usuario insiste sin datos, continuar marcando `READ_WRITE_DIVERGES = unknown` y `PREMATURE = true` en la Execution Summary

---

## Phase 3: Buses + Contracts

### GATE IN
- [ ] Prematurity check resuelto (Phase 2) — si `PREMATURE`, hay confirmación del usuario

### MUST DO
1. [ ] **Generar los marker types del enforcement** — interfaces/tipos base `Command` y `Query` que el resto hereda. El `CommandHandler<C>` retorna `void`/`ID`; el `QueryHandler<Q, R>` retorna `R` (DTO). Las firmas son lo que hace que un Command NO pueda devolver estado y una Query NO pueda mutar (en `dynamic`: type hints + el contrato que verifica el test de Phase 5)
2. [ ] **Generar el Command Bus** — `register(commandType, handler)` + `dispatch(command): void | ID`. El bus enruta por tipo de command y deja un punto de extensión para middleware (validación, transacción, logging)
3. [ ] **Generar el Query Bus** — `register(queryType, handler)` + `ask(query): DTO`. Enruta por tipo de query; NO tiene punto de extensión transaccional (las queries no abren transacción de escritura)
4. [ ] **Crear la estructura de carpetas** según `knowledge/domain/architecture-patterns.md` §4: `application/commands/`, `application/queries/`, `application/buses/`, `read/` (read models + projectors). El write side reutiliza el aggregate existente; NO lo duplica
5. [ ] **Generar el objeto Command y Query por cada entrada** de `--commands`/`--queries` — Command con sus campos de intención (inmutable), Query con sus parámetros de búsqueda (inmutable). Ambos heredan del marker type correspondiente

### CHECKPOINT
- [ ] Marker types `Command` y `Query` generados; `CommandHandler` retorna `void`/`ID`, `QueryHandler` retorna DTO (por firma)
- [ ] Command Bus con `register` + `dispatch` y punto de middleware
- [ ] Query Bus con `register` + `ask`, sin transacción de escritura
- [ ] Estructura `commands/`/`queries/`/`buses/`/`read/` creada sin duplicar el aggregate existente
- [ ] Un objeto Command/Query inmutable por cada entrada de `--commands`/`--queries`

### OUTPUTS
- Archivos: marker types, command bus, query bus, objetos command/query, estructura de carpetas

### IF FAILS
ERROR: No se pudieron generar los buses o los contratos base.
Cause: lenguaje sin convención clara para genéricos/interfaces, o `[domain]` ambiguo.
Recovery:
  [ ] Option A: usar la forma idiomática del lenguaje para los marker types (TS: interfaces + genéricos; Go: interfaces + type switch en el bus; Python: `Protocol` + `@dataclass(frozen=True)`)
  [ ] Option B: si el lenguaje no soporta genéricos ricos (Go), enrutar por tipo concreto en el bus y documentar el contrato del handler en el README del módulo
  [ ] Option C: generar el bus mínimo (un command + una query) y marcar el resto como TODO en la sesión

---

## Phase 4: Handlers + Read Models

### GATE IN
- [ ] Buses y contratos generados (Phase 3)

### MUST DO
1. [ ] **Generar ≥1 Command handler** por cada command — muta el write model (invoca el aggregate, persiste vía repositorio) y retorna `void` o el ID generado. PROHIBIDO retornar el aggregate o un DTO de lectura. Si hay eventos de dominio, los emite aquí (no en la Query)
2. [ ] **Generar ≥1 Query handler** por cada query — lee del READ MODEL desnormalizado y retorna su DTO. PROHIBIDO: leer del aggregate (write model), llamar `save`/`insert`/`update`/`delete`, o emitir eventos
3. [ ] **Generar ≥1 Read Model desnormalizado** — un DTO optimizado para la vista/pantalla que la query alimenta (campos pre-calculados, joins ya resueltos). NO es el aggregate ni un espejo 1:1 de la tabla de escritura
4. [ ] **Generar un projector/sincronizador stub** que actualice el read model desde el write side (síncrono en CQRS simple; por eventos en CQRS completo — consistencia eventual). Documentar la ventana de lag si es por eventos
5. [ ] **Aplicar convenciones de naming** de `.king/knowledge/conventions.md` si existe (ej. `CreateOrderHandler`, `GetOrderByIdHandler`, `OrderSummaryReadModel`)

### CHECKPOINT
- [ ] ≥1 Command handler que retorna `void`/ID y NO lee estado de negocio
- [ ] ≥1 Query handler que retorna DTO y NO muta (cero `save`/`insert`/`update`/`delete`/emisión de eventos)
- [ ] ≥1 Read model desnormalizado (DTO por vista, no espejo del write model)
- [ ] Projector/sincronizador stub presente; si es por eventos, la ventana de consistencia eventual está documentada
- [ ] Ningún Query handler importa o consulta el aggregate (write model)

### OUTPUTS
- Archivos: command handlers, query handlers, read models, projector stub

### IF FAILS
ERROR: No se pudieron generar los handlers o los read models.
Cause: aggregate del write side inexistente, o la query no tiene una vista clara que la justifique.
Recovery:
  [ ] Option A: si no hay aggregate, generar un write model mínimo (entity con su repositorio) y notar que conviene `/ddd-tactical` para enriquecerlo
  [ ] Option B: si una query no tiene vista desnormalizada clara, generar un read model espejo provisional y marcarlo como "optimizar cuando diverja"
  [ ] Option C: generar el subconjunto de handlers que sí tienen contexto y dejar el resto como TODO documentado

---

## Phase 5: Validators + Tests

### GATE IN
- [ ] Handlers y read models generados (Phase 4)

### MUST DO
1. [ ] **Generar ≥1 Command validator** — valida el command ANTES de que llegue al handler (campos requeridos, rangos, reglas de formato). Implementarlo como middleware/decorator del command bus, NO dentro del handler. Las queries no llevan validador de mutación (solo, si acaso, validación de parámetros de búsqueda)
2. [ ] **Si NO `--no-tests`**: generar el **command handler unit test** — verifica que el command muta el write model y retorna `void`/ID; mockea el repositorio; cubre el camino de validación fallida
3. [ ] **Si NO `--no-tests`**: generar el **query handler unit test** — verifica que la query retorna el DTO esperado desde el read model y que NO escribe (mock del read store sin métodos de escritura, o aserción de cero llamadas de mutación)
4. [ ] **Si NO `--no-tests`**: generar el **test del enforcement de separación** — en `static`, un test/archivo de tipos (o lint de arquitectura) que demuestre que un Command que devuelve estado o una Query que muta NO compila; en `dynamic`, un test que falle si un handler de query invoca un método de escritura
5. [ ] **Si `--no-tests`**: omitir los tests PERO advertir explícitamente que sin el test del enforcement la separación es disciplina opcional. Registrar el riesgo en la Execution Summary

### CHECKPOINT
- [ ] ≥1 Command validator como middleware/decorator del bus (fuera del handler)
- [ ] Command handler unit test presente (mutación + validación) — o `--no-tests` registrado con riesgo
- [ ] Query handler unit test presente (retorna DTO + no muta) — o `--no-tests` registrado con riesgo
- [ ] Test del enforcement presente: Command no puede leer / Query no puede escribir (no compila o test falla) — o `--no-tests` registrado con riesgo
- [ ] Los tests no dependen de infraestructura real (mocks/fakes del repositorio y del read store)

### OUTPUTS
- Archivos: command validator(s), command handler test, query handler test, test del enforcement

### IF FAILS
ERROR: No se pudieron generar los validators o los tests.
Cause: framework de test no detectable, o el lenguaje no expresa el enforcement por compilador.
Recovery:
  [ ] Option A: usar el framework de test del stack (Vitest/Jest, pytest, `go test`, JUnit) inferido del proyecto
  [ ] Option B: si el lenguaje es `dynamic`, materializar el enforcement como un lint/test de arquitectura (no como tipo) y documentarlo como la garantía equivalente
  [ ] Option C: si `--no-tests`, registrar el riesgo en la Execution Summary y continuar — el resto del scaffolding NO depende de los tests

---

## Phase 6: DB Split Advice

### GATE IN
- [ ] Validators y tests resueltos (Phase 5)

### MUST DO
1. [ ] **Resolver el nivel de CQRS** desde `--db-split`: `same` (CQRS simple — misma DB, distintos modelos de objeto), `separate` (CQRS completo — read store separado sincronizado por eventos), o `auto` (recomendar según `DB_SPLIT_CAPABLE` y la divergencia detectada en Phase 2)
2. [ ] **Si el stack lo soporta (`DB_SPLIT_CAPABLE`) y `auto`/`separate`**: SUGERIR DB separada read/write — read replicas, segunda DB de lectura, o vista materializada según el motor (`DB_ENGINE`). Explicar el trade-off: escala lecturas independientemente PERO introduce consistencia eventual del read model (ventana de lag)
3. [ ] **Si `same` o stack sin soporte**: documentar CQRS simple (misma DB, read model como vista/tabla sincrónica) y su trade-off: sin lag, pero sin escalado independiente de lectura
4. [ ] **Registrar la recomendación** con su nivel y trade-off, y la guía de UX para la consistencia eventual (optimistic UI / "procesando…") si la recomendación es `separate`

### CHECKPOINT
- [ ] Nivel de CQRS resuelto (`same` | `separate`) con su justificación
- [ ] Recomendación de DB read/write emitida acorde a `DB_SPLIT_CAPABLE` y la divergencia
- [ ] Trade-off documentado (escalado vs consistencia eventual); guía de UX si es `separate`

### OUTPUTS
- Variables: `CQRS_LEVEL` (`simple` | `complete`), recomendación de DB split (documento/nota en la sesión)

### IF FAILS
ERROR: No se pudo determinar la recomendación de DB split.
Cause: motor de DB no declarado en el stack o capacidad de replicas desconocida.
Recovery:
  [ ] Option A: recomendar CQRS simple (misma DB) por defecto y notar que separar read/write se evalúa cuando las lecturas escalen distinto
  [ ] Option B: preguntar al usuario el motor de DB y si tolera consistencia eventual en las lecturas
  [ ] Option C: emitir la recomendación como tentativa marcada "validar capacidad de replicas del motor antes de adoptar `separate`"

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Command bus con `register` + `dispatch`
  - [ ] Query bus con `register` + `ask`
  - [ ] ≥1 Command handler que retorna `void`/ID (no lee estado)
  - [ ] ≥1 Query handler que retorna DTO (no muta)
  - [ ] ≥1 Read model desnormalizado
  - [ ] ≥1 Command validator (middleware/decorator, fuera del handler)
  - [ ] Enforcement por tipos verificable (Command no puede leer / Query no puede escribir)
  - [ ] Tests de command handler + query handler + test del enforcement (o `--no-tests` con riesgo registrado)
  - [ ] Recomendación de DB separada read/write (o nota de CQRS simple) con trade-off
- [ ] Ningún Command handler retorna estado de negocio; ningún Query handler muta
- [ ] Ninguna Query lee del aggregate (write model)
- [ ] Si NO hay divergencia read/write real: WARNING "patrón prematuro" fue emitido y confirmado
- [ ] Ninguna connection string / versión de stack / ruta absoluta / nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(buses + handlers separados + enforcement por tipos + tests = FORTIFIED; read/write no diverge o `--no-tests` = CONDITIONAL; un handler viola la separación = BREACHED)_ |
| Artifacts | _(command/query bus; command/query handlers; read model(s); command validator(s); marker types del enforcement; tests; recomendación de DB split)_ |
| Next Recommended | `/ddd-tactical [domain]` (enriquecer el write model con aggregates/invariants) o `/event-sourcing [aggregate]` (el write side como log inmutable que alimenta las projections) |
| Risks | _(consistencia eventual del read model si `separate`; patrón prematuro si read/write no diverge; sin garantía mecánica si `--no-tests`; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Write model anémico / sin invariantes ricos | `/ddd-tactical [domain]` — aggregates, VOs, domain events que el Command handler usa |
| Audit trail crítico / time-travel + ya hay CQRS | `/event-sourcing [aggregate]` — eventos como store del write side; projections alimentan los read models |
| No hay separación de capas todavía | `/clean-arch-setup [domain]` — ubicar Command/Query en la capa de aplicación con la regla de dependencia |
| Patrón prematuro confirmado (read/write no diverge) | revisar la decisión; un `controller → repo` directo basta hasta que la lectura diverja o escale distinto |
| Setup CQRS listo | implementar los handlers con `/build`; validar la separación y los read models en `/review` |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Command vs Query — el contrato del enforcement

| Aspecto | Command | Query |
|---------|---------|-------|
| Intención | CAMBIA estado (`CreateOrder`) | LEE estado (`GetOrderById`) |
| Retorno | `void` o un ID — NUNCA el estado resultante | un DTO (read model) — NUNCA muta |
| Va contra | write model (aggregate DDD) vía repositorio | read model desnormalizado |
| Bus | Command Bus (`dispatch`) — punto de middleware (validación, transacción, logging) | Query Bus (`ask`) — sin transacción de escritura |
| Side effects | persiste, emite eventos de dominio | ninguno (idempotente, sin escritura) |
| Marker type | `Command` / `CommandHandler<C> → void\|ID` | `Query` / `QueryHandler<Q,R> → R` |

> La separación se enforced por TIPOS: la firma de `CommandHandler` no devuelve estado de lectura y la de
> `QueryHandler` no recibe un repositorio de escritura. En lenguajes estáticos, violarlo NO compila; en
> dinámicos, un test/lint dedicado lo vuelve la garantía equivalente (ver `architecture-patterns.md` §4 y
> Regla de oro #7 "Verificá la arquitectura con tests").

### Enforcement por tipos según el lenguaje

| Lenguaje | Enforcement | Forma idiomática |
|----------|-------------|------------------|
| TypeScript | Compilador (`static`) | `interface Command {}` / `interface CommandHandler<C extends Command> { handle(c: C): Promise<void \| Id> }`; `QueryHandler<Q extends Query, R> { handle(q: Q): Promise<R> }` |
| Go | Compilador (`static`) | interfaces `Command`/`Query` + `Handle(ctx, cmd) error` (sin retorno de estado) vs `Handle(ctx, q) (DTO, error)`; bus con type switch |
| Java | Compilador (`static`) | genéricos `CommandHandler<C extends Command, Void>` / `QueryHandler<Q extends Query, R>` |
| Python | Type hints + test/lint (`dynamic`) | `@dataclass(frozen=True)` para command/query + `Protocol` para los handlers; test que falla si un query handler llama un método de escritura |

### Estructura de directorios (CQRS §4)

```
src/
├── application/
│   ├── commands/
│   │   ├── create-order.command.ts        # objeto Command inmutable
│   │   └── create-order.handler.ts        # muta el write model, retorna void|OrderId
│   ├── queries/
│   │   ├── get-order-by-id.query.ts       # objeto Query inmutable
│   │   └── get-order-by-id.handler.ts     # lee read model, retorna OrderDTO
│   ├── validators/
│   │   └── create-order.validator.ts      # middleware del command bus
│   └── buses/
│       ├── command-bus.ts                  # register + dispatch
│       └── query-bus.ts                    # register + ask
├── write/
│   └── domain/order.aggregate.ts           # write model (reutiliza el aggregate DDD)
└── read/
    ├── order-summary.readmodel.ts          # DTO desnormalizado por vista
    └── projectors/order.projector.ts       # sincroniza read model desde el write side
```

> El read y el write viven separados: el Command handler escribe en `write/`, el Query handler lee de
> `read/`. El projector es el único puente (síncrono en CQRS simple, por eventos en CQRS completo).

### Ejemplo de referencia: CreateOrder (command) + GetOrderById (query)

- **`CreateOrder` (Command)**: campos `customerId`, `items[]`. El handler carga/crea el aggregate `Order`,
  invoca su lógica de negocio (invariants), persiste vía `OrderRepository`, emite `OrderPlaced`, y retorna
  el `OrderId`. NO retorna el `Order` ni un DTO. Su validator verifica `items.length > 0` y `customerId`
  presente ANTES del handler.
- **`GetOrderById` (Query)**: campo `orderId`. El handler consulta el `OrderSummaryReadModel`
  (desnormalizado: total ya calculado, nombre del cliente embebido) y retorna `OrderDTO`. NO toca el
  aggregate, NO escribe, NO emite eventos. Si el read model se sincroniza por eventos, puede reflejar un
  estado con lag respecto del último command (consistencia eventual).

### Niveles: CQRS simple vs completo (DB split)

| Nivel | DB | Sincronización | Trade-off |
|-------|----|-----------------|-----------|
| Simple | Misma DB, distintos modelos de objeto | Read model sincrónico (misma transacción o vista) | Sin lag, pero sin escalado independiente de lectura |
| Completo | Read store separado (replica / 2ª DB / materialized view) | Por eventos (projector) → consistencia eventual | Escala lecturas aparte, PERO ventana de lag → diseñar la UX (optimistic UI, "procesando…") |

> **Trampa de la consistencia eventual** (`architecture-patterns.md` §4): si el read model se sincroniza por
> eventos, hay una ventana donde la escritura ya ocurrió pero la lectura aún no la refleja. Si no se tolera
> el lag, usar CQRS simple (misma DB, read sincrónico).

### Check de prematuridad (read/write no diverge)

CQRS se PAGA cuando el modelo de lectura y el de escritura divergen (vistas desnormalizadas vs aggregate)
o cuando lecturas y escrituras escalan distinto. En un CRUD donde la pantalla muestra exactamente lo que
se guarda, dos modelos y dos buses son duplicación pura, y la consistencia eventual del read model
introduce bugs sutiles (UI con dato viejo) que cuestan más que lo que rinden. Por eso, si no hay
divergencia real, el skill ADVIERTE "patrón prematuro" y ofrece la alternativa `controller → repo` directo.
La advertencia es obligatoria; la decisión final es del usuario. Fuente: `architecture-patterns.md` (Mapa
de Decisión Rápida + Regla de oro #5 "CQRS sin necesidad = duplicación").

### Relación con otros skills del arco M04

`/cqrs-setup` separa CÓMO se lee de CÓMO se escribe. Se apoya en `/clean-arch-setup` (ubica Command/Query
en la capa de aplicación) y en `/ddd-tactical` (el write model es un aggregate rico: encaje natural
CQRS + DDD). Es el paso previo natural a `/event-sourcing` (el write side como log inmutable cuyas
projections alimentan los read models de CQRS — "Event Sourcing casi siempre acompaña a CQRS"). No son
alternativas excluyentes: son capas ortogonales (ver tabla de Combinaciones Comunes en
`knowledge/domain/architecture-patterns.md`). El delta spec del patrón está en
`openspec/changes/m04-architecture/specs/architecture-patterns/spec.md`.

### Integración con @architect y CASTLE A

`agents/architect.md` referencia `knowledge/domain/architecture-patterns.md` y puede invocar `/cqrs-setup`
cuando detecta que read y write divergen mucho en un dominio rico. CASTLE A vigila dos señales que este
skill previene: "CQRS sin justificación" (dos modelos y un bus sobre un CRUD que no diverge → over-
engineering) y un handler que viola la separación (Command que lee / Query que escribe → responsabilidad
mezclada). El test del enforcement generado es la garantía mecánica que alimenta CASTLE A y CASTLE T.
