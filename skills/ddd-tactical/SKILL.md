---
name: ddd-tactical
version: 2.0
api_version: 1.0.0
description: "Scaffoldea DDD táctico por stack (Go/TS/Python): Aggregate con invariants y método de fábrica, Entities con identidad TIPADA (ID como Value Object, no raw string/UUID), Value Objects inmutables con validación en constructor, Domain Events inmutables (nombre en pasado, payload, timestamp), Repository interface de colección (save/findById/findAll con Specification), y tests unitarios de las invariants. Usar cuando se necesite: modelar un dominio rico, scaffoldear aggregate/value object/domain event, capturar el lenguaje ubicuo en código, o dar identidad tipada a las entidades. ADVIERTE 'dominio anémico' si las entidades son solo getters/setters sin reglas."
---

# /ddd-tactical — Scaffolding de DDD Táctico con identidad tipada e invariants protegidos

Scaffoldea los bloques de construcción de **DDD Táctico** para un aggregate en el stack del proyecto
(Go, TypeScript o Python). Genera el **Aggregate Root** con sus invariants protegidos y un **método de
fábrica** (la única forma válida de construirlo), las **Entities** internas con **identidad tipada** (el
ID es un Value Object, NUNCA un `string`/`uuid` crudo), los **Value Objects** inmutables que validan en
el constructor, los **Domain Events** inmutables (nombre en pasado, payload, `timestamp`), la
**Repository interface** de colección (`save` / `findById` / `findAll` con **Specification**), y los
**tests unitarios de las invariants** del aggregate.

> **Regla transversal innegociable**: el aggregate es la FRONTERA DE CONSISTENCIA. Sus invariants se
> protegen DENTRO del aggregate root, no en un service externo. Si `OrderService` tiene toda la lógica y
> `Order` es solo una bolsa de getters/setters, NO es DDD: es un modelo anémico con procedimientos
> encima. La identidad tipada (`OrderId` VO, no `string`) y la inmutabilidad de los VOs/eventos no son
> adornos: son lo que vuelve el lenguaje ubicuo verificable por el compilador. Ver
> `knowledge/domain/architecture-patterns.md` §3.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack y lenguaje del proyecto — fuente del scaffolding (Go/TS/Python) auto-detectado | Yes | project |
| `.king/knowledge/architecture.md` | Arquitectura existente — ubica `domain/` para colocar el aggregate sin duplicar capas | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de archivos, VOs, eventos y tests | No | project |
| `knowledge/domain/architecture-patterns.md` | Clean/Hexagonal/DDD/CQRS/ES con trade-offs y estructura por patrón (custom: este skill scaffoldea los bloques tácticos del §3 y usa el Mapa de Decisión Rápida para el check de anemia) | Yes | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[aggregate-name]` (el nombre del aggregate root es obligatorio)
- [ ] El stack no es resoluble (ni `--stack` ni `.king/knowledge/stack.md` declaran Go/TS/Python)
- [ ] Ya existe el aggregate `[aggregate-name]` en `domain/` y el usuario NO confirmó sobrescribir

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA usar un `string`/`uuid` crudo como identidad de una entity o aggregate — el ID DEBE ser un Value Object tipado (`OrderId`, `OrderItemId`), no un primitivo
- NUNCA generar Value Objects mutables ni con setters — un VO es inmutable y valida en el constructor; para cambiarlo se reemplaza, no se muta
- NUNCA generar Domain Events mutables ni con nombre en presente — el evento es inmutable, nombre en PASADO (`OrderPlaced`, no `PlaceOrder`) y lleva payload + `timestamp`
- NUNCA exponer un constructor público que permita crear el aggregate en estado inválido — la única entrada válida es el método de fábrica que aplica los invariants
- NUNCA poner las invariants del aggregate en un service externo (modelo anémico) — viven DENTRO del aggregate root
- NUNCA implementar el Repository (acceso a DB) dentro de `domain/` — solo declarar la interfaz de colección; la implementación es responsabilidad de la capa de infra
- NUNCA hardcodear versiones de stack, rutas absolutas, ni nombres de proyecto — usar `.king/knowledge/stack.md` y `{{SLOT}}`
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Aggregate Root con ≥1 invariant protegido y un **método de fábrica** (única construcción válida) en `domain/[aggregate]/`
- [ ] ≥1 ID como Value Object tipado por cada aggregate/entity (`[Aggregate]Id`), nunca un primitivo crudo
- [ ] Entities internas (si se pidieron via `--entities`) con identidad tipada y referenciadas por el aggregate
- [ ] Value Objects inmutables con validación en el constructor (igualdad por valor)
- [ ] Domain Events inmutables con nombre en pasado, payload y `timestamp` (los que se piden via `--events`)
- [ ] Repository interface de colección (`save` / `findById([Aggregate]Id)` / `findAll(Specification)`), SIN implementación
- [ ] Tests unitarios que verifican las invariants del aggregate (incluido el caso que las VIOLA)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Detect   (Anemia    (Value    (Aggregate (Repo +   (Session)  (Guide)
          stack)    check)     Objects+  + Events)  invariant
                               Entities)            tests)
```

### PARÁMETROS
```
/ddd-tactical [aggregate-name] [--entities a,b] [--vos a,b] [--events a,b] [--stack go|ts|python]
```
- `[aggregate-name]`: nombre del aggregate root (ej. `Order`, `Subscription`). Obligatorio
- `--entities`: lista separada por comas de entidades internas del aggregate (ej. `OrderItem`). Opcional
- `--vos`: lista de Value Objects además de los IDs (ej. `Money,Address`). Opcional
- `--events`: lista de Domain Events que emite el aggregate (ej. `OrderPlaced,OrderCancelled`). Opcional
- `--stack`: fuerza el stack del scaffolding (default: auto-detectado desde `.king/knowledge/stack.md`)

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) cubre la integridad del modelo: invariants en el aggregate, identidad tipada,
> inmutabilidad de VOs/eventos y el Repository como puerto. CASTLE T (Testing) cubre los tests de
> invariants generados. Veredicto CONDITIONAL si se detecta riesgo de dominio anémico o si no hay ninguna
> invariant real que proteger (el aggregate sería solo una estructura de datos).

## Agentes
- **@architect** — Agente principal: decide la frontera del aggregate (qué entidades viven adentro), valida que las invariants estén en el root y que las referencias entre aggregates sean por ID
- **@developer** — Genera el scaffolding: VOs inmutables, IDs tipados, método de fábrica, eventos inmutables y la interfaz del repositorio
- **@qa** — Valida que los tests de invariants efectivamente FALLEN al violar la regla (ej. agregar el item 11 cuando el máximo es 10)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect Stack

### GATE IN
- [ ] Se recibió `[aggregate-name]` (BLOCKING CONDITION ya validó que existe)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Leer `.king/knowledge/stack.md`** y extraer el lenguaje principal (Go, TypeScript, Python) y el module/package root
2. [ ] **Resolver stack** desde `--stack` si se pasó; si no, inferirlo del stack declarado. Soportar `go`, `ts`, `python`
3. [ ] **Localizar `domain/`** — leer `.king/knowledge/architecture.md` y el árbol del proyecto para ubicar la capa de dominio (`internal/domain` en Go, `src/domain` en TS/Python). Marcar `EXISTS = true|false` para el aggregate `[aggregate-name]`
4. [ ] **Parsear listas** de `--entities`, `--vos`, `--events` (separadas por coma). Normalizar nombres: aggregate y entities en PascalCase; eventos en PASADO (`OrderPlaced`)
5. [ ] **Resolver el módulo del aggregate** — un sub-directorio por aggregate root (`domain/order/`), no un archivo suelto

### CHECKPOINT
- [ ] `STACK` resuelto (uno de `go|ts|python`) — si ambiguo, asumido con WARN explícito
- [ ] `DOMAIN_ROOT` (ruta de la capa de dominio) resuelto
- [ ] `EXISTS` definido (si `true`, requiere confirmación de sobrescritura — BLOCKING CONDITION)
- [ ] Listas `ENTITIES[]`, `VOS[]`, `EVENTS[]` parseadas (pueden estar vacías)

### OUTPUTS
- Variables: `STACK`, `DOMAIN_ROOT`, `MODULE_ROOT`, `EXISTS`, `ENTITIES[]`, `VOS[]`, `EVENTS[]`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el stack o la capa de dominio del proyecto.
Cause: `.king/knowledge/stack.md` ausente o sin lenguaje declarado, y `--stack` no provisto; o `domain/` no existe.
Recovery:
  [ ] Option A: pedir al usuario el stack (`--stack`) entre los 3 soportados (`go|ts|python`)
  [ ] Option B: inferir el stack del árbol (`go.mod` → go, `package.json`/`tsconfig.json` → ts, `pyproject.toml` → python) y, si no hay `domain/`, crear `domain/` con WARN (sugerir `/clean-arch-setup` primero para las capas)
  [ ] Option C: abortar y ejecutar `/genesis` para generar `.king/knowledge/stack.md`, o `/clean-arch-setup` para crear la capa de dominio

---

## Phase 2: Anemia Check

### GATE IN
- [ ] `STACK` y `DOMAIN_ROOT` resueltos (Phase 1)

### MUST DO
1. [ ] **Identificar las invariants reales** del aggregate — reglas de negocio que el modelo DEBE proteger (ej. "una orden no puede tener más de 10 items", "el total no puede ser negativo"). Usar el código existente, la descripción del usuario o preguntar
2. [ ] **Aplicar el check de anemia** de `knowledge/domain/architecture-patterns.md` §3: si el aggregate sería solo getters/setters sin reglas, o si toda la lógica vive en un `Service` procedural, es un modelo ANÉMICO — DDD táctico sería overhead
3. [ ] **Si NO hay invariants reales** (CRUD puro / dominio anémico): emitir WARNING "dominio anémico" — explicar que DDD táctico sin reglas que proteger es ceremonia, y ofrecer alternativa (un modelo de datos simple + repository directo). Pedir confirmación explícita para continuar
4. [ ] **Registrar el veredicto** (`ANEMIC = true|false`) y la lista de invariants a materializar para el ADR/Execution Summary

### CHECKPOINT
- [ ] ≥1 invariant real identificada (con su fuente: código / usuario) — o WARNING "dominio anémico" emitido y confirmado
- [ ] `ANEMIC` definido
- [ ] Lista de invariants a proteger registrada

### OUTPUTS
- Variables: `INVARIANTS[]`, `ANEMIC`

### IF FAILS
ERROR: No se pudo determinar si el dominio tiene reglas reales que proteger.
Cause: el aggregate no está descrito, o el proyecto aún no modeló las reglas de negocio.
Recovery:
  [ ] Option A: preguntar al usuario por al menos UNA regla de negocio concreta del aggregate (ej. límite de items, estado válido)
  [ ] Option B: si no hay regla alguna, marcar `ANEMIC = true`, advertir y continuar solo con confirmación, generando un invariant placeholder documentado
  [ ] Option C: si el usuario solo quiere un modelo de datos, sugerir NO usar DDD táctico y derivar a un scaffolding CRUD simple

---

## Phase 3: Value Objects + Entities

### GATE IN
- [ ] Anemia check resuelto (Phase 2) — si `ANEMIC`, hay confirmación del usuario

### MUST DO
1. [ ] **Generar el ID tipado del aggregate** como Value Object (`[Aggregate]Id`) — envuelve el identificador (UUID/string) pero NO se expone como primitivo. Valida formato en el constructor; igualdad por valor
2. [ ] **Generar un ID tipado por cada entity** de `--entities` (`[Entity]Id`) — misma regla: identidad tipada, nunca `string` crudo
3. [ ] **Generar los Value Objects** de `--vos` (y cualquier VO implícito como `Money`) — INMUTABLES, validación en el constructor (ej. `Money` rechaza monto negativo / moneda inválida), igualdad por valor, SIN setters
4. [ ] **Generar las Entities internas** de `--entities` — identidad por su ID tipado (igualdad por ID, no por atributos), mutables solo a través de comportamiento con significado de negocio (no setters anémicos). Las entities NO se construyen ni modifican desde fuera del aggregate
5. [ ] **Sin imports de infra** — ningún VO/entity importa ORM, framework, DB o HTTP. Aplicar naming de `.king/knowledge/conventions.md` si existe

### CHECKPOINT
- [ ] `[Aggregate]Id` generado como Value Object tipado (no primitivo)
- [ ] Cada entity tiene su `[Entity]Id` tipado
- [ ] Todos los VOs son inmutables, validan en el constructor y tienen igualdad por valor (sin setters)
- [ ] Entities con igualdad por ID; sin setters anémicos
- [ ] Ningún VO/entity importa infraestructura/ORM

### OUTPUTS
- Archivos: `[aggregate]-id.vo`, `[entity]-id.vo`, VOs (`money.vo`, etc.), entities

### IF FAILS
ERROR: No se pudieron generar los Value Objects / Entities.
Cause: stack sin convención clara para inmutabilidad, o reglas de validación de VO no provistas.
Recovery:
  [ ] Option A: usar el patrón de inmutabilidad canónico del stack (Go: struct con campos privados + constructor `NewX`; TS: `readonly` + `Object.freeze`/`private constructor` + factory; Python: `@dataclass(frozen=True)`)
  [ ] Option B: pedir al usuario la regla de validación concreta de cada VO (ej. rango de `Money`)
  [ ] Option C: generar los IDs tipados + un VO mínimo y marcar el resto como TODO documentado

---

## Phase 4: Aggregate + Domain Events

### GATE IN
- [ ] Value Objects e IDs tipados generados (Phase 3)

### MUST DO
1. [ ] **Generar el Aggregate Root** en `domain/[aggregate]/` — usa su `[Aggregate]Id` tipado, contiene las entities/VOs, y un **método de fábrica** (`[Aggregate].create(...)` / `New[Aggregate](...)`) que es la ÚNICA forma válida de construirlo (constructor cerrado/privado)
2. [ ] **Materializar las invariants** dentro del aggregate root — la fábrica y los métodos de comportamiento (`addItem`, etc.) lanzan `DomainException`/error de dominio al violar una regla (ej. superar el máximo de items). NUNCA dejar construir el aggregate en estado inválido
3. [ ] **Generar los Domain Events** de `--events` — INMUTABLES, nombre en PASADO (`OrderPlaced`), con payload mínimo (IDs/VOs relevantes) y `timestamp` (`occurredOn`). El evento se construye al ocurrir el hecho, no se muta después
4. [ ] **Emitir eventos desde el aggregate** — el aggregate registra los eventos que ocurren (`pullDomainEvents()` / lista interna), respetando que un cambio de estado relevante emite su evento en pasado
5. [ ] **Referencias entre aggregates por ID** — si el aggregate referencia otro aggregate, lo hace por su ID tipado, NO por navegación de objetos (evita aggregates gigantes)

### CHECKPOINT
- [ ] Aggregate Root con constructor cerrado + método de fábrica como única construcción válida
- [ ] ≥1 invariant protegida en la fábrica/comportamiento (lanza al violarse) — NO en un service externo
- [ ] Cada Domain Event es inmutable, con nombre en pasado, payload y `timestamp`
- [ ] El aggregate emite/registra sus domain events
- [ ] Referencias a otros aggregates por ID tipado (si aplica)

### OUTPUTS
- Archivos: `[aggregate].aggregate`, `[event].event` (uno por `--events`)

### IF FAILS
ERROR: No se pudo generar el aggregate o sus eventos.
Cause: invariants no expresables sin más contexto del negocio, o `--events` con nombres en presente.
Recovery:
  [ ] Option A: normalizar nombres de eventos a pasado automáticamente (`PlaceOrder` → `OrderPlaced`) con WARN
  [ ] Option B: pedir al usuario la regla concreta del invariant y el payload mínimo de cada evento
  [ ] Option C: generar el aggregate con un invariant placeholder + un evento `[Aggregate]Created` por defecto, documentando el TODO

---

## Phase 5: Repository + Invariant Tests

### GATE IN
- [ ] Aggregate y eventos generados (Phase 4)

### MUST DO
1. [ ] **Generar la Repository interface** de colección en `domain/[aggregate]/` — `save([Aggregate])`, `findById([Aggregate]Id)`, `findAll(Specification)`. UN repositorio por aggregate root, SOLO la interfaz (sin implementación de DB). Recibe/devuelve el aggregate, no DTOs
2. [ ] **Generar el contrato de Specification** — una interfaz `Specification` (`isSatisfiedBy(aggregate) → bool`) que `findAll` consume para filtrar por reglas de dominio, en vez de exponer queries crudas en la interfaz
3. [ ] **Generar los tests unitarios de invariants** — por cada invariant: un test del CASO VÁLIDO (la fábrica construye OK) y un test del CASO QUE VIOLA la regla (espera `DomainException`). Ej. para "max 10 items": agregar 10 pasa, agregar el item 11 lanza
4. [ ] **Test de identidad tipada** — verificar que el ID es un VO (igualdad por valor entre dos `[Aggregate]Id` con el mismo valor) y NO un primitivo
5. [ ] **@qa valida el test del test** — confirmar que el test de violación efectivamente FALLA si se relaja el invariant (no es un test que pase trivialmente)

### CHECKPOINT
- [ ] Repository interface con `save` / `findById([Aggregate]Id)` / `findAll(Specification)`, SIN implementación
- [ ] Contrato `Specification` generado y consumido por `findAll`
- [ ] Test por invariant: caso válido + caso que VIOLA (espera `DomainException`)
- [ ] Test de identidad tipada (igualdad por valor del ID VO)
- [ ] Los tests de violación fallan si se relaja el invariant (verificado por @qa)

### OUTPUTS
- Archivos: `[aggregate].repository` (interfaz), `specification`, `[aggregate].test`/`*_test`

### IF FAILS
ERROR: No se pudieron generar el repositorio o los tests de invariants.
Cause: stack sin framework de test detectable, o invariants sin caso de violación expresable.
Recovery:
  [ ] Option A: usar el runner de test del stack (Go: `testing` + `go test`; TS: Vitest/Jest; Python: pytest) según `.king/knowledge/stack.md`
  [ ] Option B: generar al menos el test del invariant principal (caso válido + violación) y marcar el resto como TODO
  [ ] Option C: si no hay framework de test, generar los tests de todas formas y documentar el comando de instalación/ejecución

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Aggregate Root con ≥1 invariant protegido y método de fábrica (única construcción válida)
  - [ ] `[Aggregate]Id` (y `[Entity]Id` por entity) como Value Object tipado, nunca primitivo
  - [ ] Entities internas con identidad tipada (si se pidieron via `--entities`)
  - [ ] Value Objects inmutables con validación en el constructor (igualdad por valor)
  - [ ] Domain Events inmutables con nombre en pasado, payload y `timestamp`
  - [ ] Repository interface (`save` / `findById` / `findAll` con Specification), SIN implementación
  - [ ] Tests de invariants: caso válido + caso que VIOLA la regla
- [ ] Ningún `string`/`uuid` crudo usado como identidad
- [ ] Ningún VO o evento mutable; ningún invariant en un service externo (no anémico)
- [ ] `domain/` sin imports de infraestructura/ORM
- [ ] Si dominio anémico: WARNING fue emitido y confirmado
- [ ] Ninguna versión de stack / ruta absoluta / nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(aggregate con invariants + identidad tipada + VOs/eventos inmutables + tests que fallan al violar = FORTIFIED; dominio anémico o sin invariant real = CONDITIONAL; ID primitivo, VO/evento mutable o invariant en service externo = BREACHED)_ |
| Artifacts | _(IDs tipados; VOs; entities; aggregate root + fábrica; domain events; repository interface + specification; tests de invariants)_ |
| Next Recommended | `/cqrs-setup` (separar command/query sobre el aggregate) o `/event-sourcing [aggregate]` (si los domain events son la fuente de verdad) |
| Risks | _(dominio anémico si las entidades no tienen reglas; invariants placeholder si el negocio no se describió; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Read y write del aggregate divergen mucho | `/cqrs-setup` — separar Command de Query sobre el aggregate |
| Los domain events son la fuente de verdad (audit/time-travel) | `/event-sourcing [aggregate-name]` — event store + projections |
| Falta la separación de capas donde vive el aggregate | `/clean-arch-setup [domain]` o `/hexagonal-setup` — montar domain/application/infra |
| Dominio anémico confirmado | revisar la decisión; quizás un modelo de datos + repository directo basta |
| Aggregate listo | implementar use cases que lo orquestan con `/build`, validar invariants en `/review` |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Bloques tácticos generados (qué y por qué)

| Bloque | Regla clave | Cómo lo materializa el skill |
|--------|-------------|------------------------------|
| Aggregate Root | Frontera de consistencia; única entrada; invariants adentro | Constructor cerrado + método de fábrica; lanza `DomainException` al violar regla |
| Entity | Identidad propia; igualdad por ID (no por atributos) | ID tipado (`[Entity]Id` VO); mutación solo por comportamiento con significado |
| Value Object | Inmutable; igualdad por valor; valida al construir | Sin setters; validación en constructor; reemplazar en vez de mutar |
| Domain Event | Algo que SUCEDIÓ; nombre en pasado; inmutable | `OrderPlaced` con payload + `timestamp` (`occurredOn`); emitido por el aggregate |
| Repository | Colección de AGGREGATES (1 por root) | Interfaz `save`/`findById`/`findAll(Specification)`; impl. en infra, no en domain |
| Identidad tipada | El ID es un VO, no un primitivo | `OrderId` envuelve el UUID; el compilador impide pasar un `OrderId` donde va un `CustomerId` |

### Patrón de inmutabilidad de Value Object por stack

| Stack | Patrón |
|-------|--------|
| Go | `struct` con campos privados + constructor `NewMoney(amount, currency) (Money, error)`; sin métodos que muten; comparación por valor |
| TS | `class Money { private constructor(...) ; static create(...): Money }` con campos `readonly` (o `Object.freeze`); método `equals(other)` por valor |
| Python | `@dataclass(frozen=True)` con `__post_init__` para validar; igualdad por valor automática |

El ID tipado sigue el MISMO patrón: un VO que envuelve el identificador. Pasar un `string` crudo donde
va un `OrderId` debe ser un error de compilación/tipo, no un bug en runtime.

### Por qué identidad TIPADA (no `string`/`uuid`)

Con IDs primitivos, `repo.findById(customerId)` cuando esperaba un `orderId` compila y explota en
producción. Con identidad tipada, `OrderId` y `CustomerId` son tipos distintos: el error se atrapa en
compilación. Además, el VO de ID puede validar el formato una sola vez (en su constructor) en lugar de
re-validar el string en cada frontera. Es el lenguaje ubicuo hecho verificable. Ver
`knowledge/domain/architecture-patterns.md` §3 ("identidad tipada").

### Ejemplo de referencia — aggregate `Order` (invariant "máximo 10 items")

Módulo `domain/order/` (naming TS de ejemplo; Go/Python análogo):

```
domain/order/
├── order-id.vo.ts            # Value Object: identidad tipada del aggregate (no string crudo)
├── order-item-id.vo.ts       # Value Object: identidad tipada de la entity OrderItem
├── money.vo.ts               # Value Object inmutable (rechaza monto negativo)
├── order-item.entity.ts      # Entity interna: igualdad por OrderItemId
├── order.aggregate.ts        # Aggregate Root: create() (fábrica) + addItem() lanza si > 10 items
├── order-placed.event.ts     # Domain Event: pasado + payload(OrderId, total) + occurredOn
├── order.repository.ts       # interfaz: save / findById(OrderId) / findAll(Specification)
├── specification.ts          # interfaz Specification.isSatisfiedBy(order)
└── order.spec.ts             # tests: addItem #10 pasa, #11 lanza DomainException
```

- `Order.create(id, items)` es la única construcción válida — el constructor es privado.
- `Order.addItem(item)` lanza `DomainException("max 10 items")` al intentar el item 11 (el invariant
  vive en el aggregate, NO en un `OrderService`).
- `OrderId` y `OrderItemId` son VOs: pasar uno donde va el otro es error de tipo.
- `OrderPlaced` se emite al confirmar la orden, con `occurredOn` y payload inmutable.
- El test `addItem` #11 DEBE fallar si se relaja el límite — es la garantía de la invariant.

### Check de dominio anémico (cuándo NO usar DDD táctico)

DDD táctico se PAGA con dominios ricos. Si tus "entidades" son bolsas de getters/setters y toda la
lógica vive en `XService` procedural, NO estás haciendo DDD: tenés un modelo de datos con procedimientos
encima (anti-patrón anémico). En ese caso el skill ADVIERTE y ofrece la alternativa simple (modelo de
datos + repository directo). La advertencia es obligatoria; la decisión final es del usuario. Fuente:
`knowledge/domain/architecture-patterns.md` §3 ("Señal de dominio anémico" + "Cuándo NO usar").

### Relación con otros skills del arco M04

`/ddd-tactical` define CÓMO se modela el dominio rico (aggregates, VOs, eventos). Vive DENTRO del anillo
`domain/` que monta `/clean-arch-setup` o `/hexagonal-setup` (la separación técnica). Se complementa con
`/cqrs-setup` (separar command/query sobre el aggregate) y `/event-sourcing` (cuando los domain events
son la fuente de verdad, no solo notificaciones). No son alternativas excluyentes: son capas ortogonales
(ver tabla de Combinaciones Comunes en `knowledge/domain/architecture-patterns.md`). El delta spec del
patrón está en `openspec/changes/m04-architecture/specs/architecture-patterns/spec.md`.

### Integración con @architect y CASTLE A

`agents/architect.md` referencia `knowledge/domain/architecture-patterns.md` y puede invocar
`/ddd-tactical` cuando detecta un dominio rico modelado de forma anémica. Un ID primitivo como identidad,
un VO mutable, o un invariant que vive en un service externo son violaciones que CASTLE A (Architecture)
vigila: rompen la integridad semántica del modelo que el aggregate debería garantizar.
