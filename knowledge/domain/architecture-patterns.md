# Architecture Patterns — Guía de Patrones Arquitectónicos

> Versión completa. Para inyección en agents usar `knowledge/_inject/architecture-patterns.md`.
>
> Estos 5 patrones no son alternativas excluyentes: son CAPAS de decisión distintas.
> Clean Architecture y Hexagonal definen *dónde van las dependencias*. DDD Tactical
> define *cómo modelás el dominio*. CQRS define *cómo separás lectura de escritura*.
> Event Sourcing define *cómo persistís el estado*. Por eso se COMBINAN (ver tabla
> final). El error caro es aplicarlos todos "porque sí" en un CRUD que no los pide.

---

## Mapa de Decisión Rápida

```
¿El dominio tiene reglas de negocio reales, o es CRUD sobre tablas?
  └─ CRUD puro → NO metas Clean/Hexagonal/DDD. Un controller→repo basta.
  └─ Reglas reales → ¿Larga vida útil + equipo grande?
        └─ SÍ → Clean Architecture (regla de dependencia) como base.
        └─ ¿Muchos adapters intercambiables (DB, cola, HTTP, 3ros)?
              └─ SÍ → Hexagonal (Ports & Adapters), más explícito en boundaries.
        └─ ¿Lenguaje ubicuo rico, invariantes complejos?
              └─ SÍ → + DDD Tactical (aggregates, VOs, domain events).
        └─ ¿Leer y escribir tienen modelos MUY distintos / cargas asimétricas?
              └─ SÍ → + CQRS (separá Command de Query).
        └─ ¿Audit trail crítico / time-travel / ya tenés CQRS?
              └─ SÍ → + Event Sourcing (el estado ES la secuencia de eventos).
```

**Regla transversal innegociable**: la dirección de las dependencias apunta SIEMPRE
hacia el dominio. El dominio no importa frameworks, ni DB, ni HTTP. Es la única regla
común a Clean y Hexagonal, y la que más se viola en la práctica. Si una entidad
importa el ORM, ya rompiste la arquitectura sin importar cuántas carpetas tengas.

---

## 1. Clean Architecture

Anillos concéntricos. La **Regla de Dependencia**: el código fuente solo puede
apuntar hacia ADENTRO. Nada en un anillo interno sabe nada de un anillo externo.

```
   ┌─────────────────────────────────────────────┐
   │  Frameworks & Drivers  (DB, web, UI, ORM)    │  ← detalles, volátil
   │  ┌───────────────────────────────────────┐   │
   │  │  Interface Adapters                    │   │  ← controllers, gateways,
   │  │  (controllers, presenters, gateways)   │   │     presenters, mappers
   │  │  ┌─────────────────────────────────┐   │   │
   │  │  │  Use Cases (Application)         │   │   │  ← orquestación, sin UI/DB
   │  │  │  ┌───────────────────────────┐   │   │   │
   │  │  │  │  Entities (Enterprise)    │   │   │   │  ← negocio puro, estable
   │  │  │  └───────────────────────────┘   │   │   │
   │  │  └─────────────────────────────────┘   │   │
   │  └───────────────────────────────────────┘   │
   └─────────────────────────────────────────────┘
        DEPENDENCIAS APUNTAN HACIA ADENTRO ──────▶
```

### Regla / estructura

- **Entities**: lógica de negocio empresarial pura. Sin imports de infra, sin
  anotaciones de ORM, sin frameworks. Lo más estable y reutilizable.
- **Use Cases**: orquestan entidades para ejecutar una operación de aplicación.
  No conocen la UI ni la DB concreta — dependen de INTERFACES (puertos).
- **Interface Adapters**: traducen entre el mundo exterior y los use cases.
  Controllers (entran), presenters (salen), gateways/repositories (datos).
- **Frameworks & Drivers**: el detalle volátil. DB, framework web, UI, ORM, broker.
- **Dependency Inversion en el cruce**: un use case necesita datos → define una
  interfaz que él posee; el adapter externo la implementa. El flujo de control va
  hacia afuera, pero la dependencia de código va hacia adentro.

### Cuándo usar

- Sistemas con **lógica de negocio compleja** que vivirán años.
- **Equipos grandes** donde aislar el dominio reduce el costo de coordinación.
- Cuando esperás que los detalles (DB, framework) cambien y querés que no arrastren
  al dominio.

### Cuándo NO usar

- **CRUD simples**: si la "lógica" es leer/escribir tablas, los anillos son ceremonia
  vacía. El controller puede hablar con el repo directamente.
- **Scripts y herramientas one-shot**: no hay dominio que proteger.
- **MVPs de validación**: cuando aún no sabés si el producto existe, no inviertas en
  desacoplar de un framework que quizás tirás en dos semanas.

### Estructura de directorios

```
src/
├── domain/                  # Entities — negocio puro, CERO imports de infra
│   ├── order.ts
│   └── money.ts
├── application/             # Use Cases + puertos (interfaces)
│   ├── place-order.usecase.ts
│   └── ports/
│       ├── order-repository.port.ts   # interfaz, NO implementación
│       └── payment-gateway.port.ts
├── adapters/               # Interface Adapters
│   ├── http/order.controller.ts
│   ├── persistence/postgres-order.repository.ts  # implementa el puerto
│   └── presenters/order.presenter.ts
└── infrastructure/         # Frameworks & Drivers
    ├── server.ts           # Express/Fastify wiring
    └── db/pool.ts          # ORM/pool config
```

> **Test de humo**: `domain/` no debe tener NINGÚN import hacia `adapters/` o
> `infrastructure/`. Si lo tiene, la regla de dependencia está rota. Un test de
> arquitectura (dependency-cruiser, ArchUnit) lo verifica automáticamente.

---

## 2. Hexagonal (Ports & Adapters)

El dominio (Application Core) en el centro. Se comunica con el exterior SOLO a través
de **ports** (interfaces). Los **adapters** implementan esos ports. Misma idea de
dependencia que Clean, pero el énfasis está en los BOUNDARIES explícitos.

```
   DRIVING side (entra)                 DRIVEN side (sale)
   actores que USAN la app             infra que la app USA

   ┌──────────┐                                   ┌──────────┐
   │ HTTP     │──▶┌───────────┐ ports ┌────────┐──▶│ Postgres │
   │ Adapter  │   │           │       │        │   │ Adapter  │
   └──────────┘   │           │       │        │   └──────────┘
   ┌──────────┐   │ APPLICATION CORE  │        │   ┌──────────┐
   │ CLI      │──▶│ (dominio + casos) │◀───────│──▶│ Kafka    │
   │ Adapter  │   │  no conoce a sus  │        │   │ Adapter  │
   └──────────┘   │     adapters      │        │   └──────────┘
   ┌──────────┐   │           │       │        │   ┌──────────┐
   │ Test     │──▶└───────────┘       └────────┘──▶│ Email    │
   │ (fake)   │   driving ports       driven ports │ Adapter  │
   └──────────┘                                    └──────────┘
```

### Regla / estructura

- **Driving ports** (primary/inbound): interfaces que el core EXPONE para que lo
  invoquen (p. ej. `PlaceOrderUseCase`). Los adapters driving (HTTP, CLI, test) los
  llaman.
- **Driven ports** (secondary/outbound): interfaces que el core NECESITA y otros
  implementan (p. ej. `OrderRepository`, `PaymentGateway`). Los adapters driven
  (Postgres, Kafka, Stripe) los implementan.
- **Application Core**: NUNCA importa un adapter directamente. Solo conoce los ports.
- **Boundary tests**: tests que verifican que el core no depende de ningún adapter.
  Es la garantía mecánica del patrón, no una buena intención.
- **Intercambiabilidad**: cambiar Postgres por Mongo = escribir otro adapter que
  cumpla el mismo driven port. El core no se toca.

### Cuándo usar

- Cuando hay (o se anticipan) **múltiples adapters intercambiables** para un mismo
  port: distintas DBs, colas, proveedores de pago, o un fake para tests.
- Cuando querés **testear el dominio en aislamiento total** con adapters fake, sin
  levantar infraestructura.
- Cuando el boundary "core vs. mundo" debe ser explícito y verificable.

### Cuándo NO usar

- **Dominio sin lógica real** (thin CRUD layer): si el "core" solo pasa datos del
  controller al repo, los ports son indirección sin valor.
- Cuando NUNCA vas a tener más de un adapter por port y no testeás el dominio aislado:
  la abstracción no se paga sola.

### Estructura de directorios

```
src/
├── core/                          # Application Core — no importa adapters
│   ├── domain/order.ts
│   ├── application/place-order.service.ts
│   └── ports/
│       ├── in/place-order.port.ts        # driving port
│       └── out/                           # driven ports
│           ├── order-repository.port.ts
│           └── payment-gateway.port.ts
└── adapters/
    ├── in/                                # driving adapters
    │   ├── http/order.controller.ts
    │   └── cli/order.command.ts
    └── out/                               # driven adapters
        ├── persistence/postgres-order.adapter.ts
        ├── messaging/kafka.adapter.ts
        └── payment/stripe.adapter.ts
```

> **Hexagonal vs. Clean**: son conceptualmente equivalentes (dependencia hacia el
> dominio). Hexagonal es MÁS EXPLÍCITO en nombrar los puertos como contratos del
> dominio y en separar driving/driven. Clean ordena en anillos. No los enfrentes:
> Hexagonal es una forma concreta de implementar la regla de dependencia de Clean.

---

## 3. DDD Tactical

Los bloques de construcción para modelar un dominio rico. NO es sobre carpetas: es
sobre capturar el **lenguaje ubicuo** (ubiquitous language) del negocio en el código.

### Regla / estructura

| Bloque | Qué es | Clave |
|--------|--------|-------|
| **Aggregate** | Cluster de objetos tratados como una unidad. Frontera de consistencia. | Siempre consistente EN MEMORIA. Solo se modifica vía su Aggregate Root. |
| **Aggregate Root** | La única entrada al aggregate. | Las invariantes se protegen aquí. Lo de afuera referencia al root, no a sus internos. |
| **Entity** | Objeto con identidad propia y ciclo de vida. | Igualdad por ID, no por atributos. Mutable. |
| **Value Object** | Objeto sin identidad, definido por sus atributos. | INMUTABLE. Igualdad por valor (`Money(100,"USD")`). Reemplazar, no mutar. |
| **Domain Event** | Algo relevante que SUCEDIÓ. | Nombre en pasado (`OrderPlaced`). Inmutable. Disparado por el aggregate. |
| **Repository** | Colección de AGGREGATES (no de entidades sueltas). | Uno por aggregate root. Abstrae la persistencia. |
| **Domain Service** | Lógica que no pertenece naturalmente a ningún aggregate. | Sin estado. Opera sobre varios aggregates/VOs. |
| **Factory** | Construcción de aggregates complejos garantizando invariantes. | Encapsula el ensamblado válido. |

- **Regla de oro del aggregate**: una transacción modifica UN aggregate. Coordinación
  entre aggregates → consistencia eventual vía domain events (no transacción única).
- **Referencia por ID**: los aggregates se referencian entre sí por identidad, no por
  navegación de objetos (evita aggregates gigantes que cargan medio modelo).

### Cuándo usar

- **Dominio rico**: muchas reglas de negocio, invariantes, flujos con estado.
- **Múltiples equipos** que necesitan un lenguaje compartido y preciso (el ubiquitous
  language baja el costo de comunicación negocio↔código).
- Cuando los bugs vienen de modelar mal el negocio, no de la infraestructura.

### Cuándo NO usar

- **Dominio anémico**: si tus "entidades" son solo bolsas de getters/setters y toda
  la lógica vive en services procedurales, DDD Tactical es overhead sin beneficio.
- **Solo CRUD**: gestionar tablas no necesita aggregates.
- **Tiempo/presupuesto limitado**: modelar bien un dominio rico cuesta; si no hay
  riqueza que modelar, no inviertas.

### Estructura de directorios

```
src/domain/
├── order/                              # un módulo por aggregate
│   ├── order.aggregate.ts              # Aggregate Root + invariantes
│   ├── order-line.entity.ts           # Entity interna del aggregate
│   ├── order-id.vo.ts                 # Value Object (identidad tipada)
│   ├── money.vo.ts                    # Value Object inmutable
│   ├── order-placed.event.ts         # Domain Event (pasado, inmutable)
│   ├── order.repository.ts           # interfaz del Repository (colección)
│   └── pricing.service.ts            # Domain Service (lógica cross-aggregate)
└── customer/
    ├── customer.aggregate.ts
    └── customer.repository.ts
```

> **Señal de dominio anémico (anti-patrón)**: si `OrderService` tiene toda la lógica
> y `Order` solo tiene campos públicos, NO estás haciendo DDD: tenés un modelo de
> datos con una capa de procedimientos encima. La lógica vive en el aggregate.

---

## 4. CQRS (Command Query Responsibility Segregation)

Separá el modelo que ESCRIBE del modelo que LEE. Una operación o cambia estado
(Command) o devuelve datos (Query) — nunca ambas. No es un patrón de DB: es de
responsabilidades.

```
        WRITE side                         READ side
   ┌──────────────────┐              ┌──────────────────┐
   │  Command          │              │  Query            │
   │  (cambia estado)  │              │  (lee, no muta)   │
   └────────┬─────────┘              └────────┬─────────┘
            ▼                                  ▼
     ┌─────────────┐                    ┌─────────────┐
     │ Command Bus │                    │  Query Bus  │
     └──────┬──────┘                    └──────┬──────┘
            ▼                                  ▼
   ┌──────────────────┐    eventos/    ┌──────────────────┐
   │ Command Handler  │───sincroniza──▶│  Read Model      │
   │ → Write Model    │   proyección   │  (desnormalizado)│
   │   (aggregate)    │                │   optimizado     │
   └──────────────────┘                └──────────────────┘
```

### Regla / estructura

- **Command**: intención de CAMBIAR estado (`PlaceOrder`). Retorna `void` o un ID, no
  el estado resultante. Va contra el write model (típicamente un aggregate DDD).
- **Query**: LEE estado (`GetOrderSummary`). Retorna un DTO. NUNCA modifica nada.
- **Command Bus + Query Bus**: desacoplan al invocador del handler concreto. Permiten
  middleware transversal (logging, validación, transacciones, métricas).
- **Read Models**: estructuras optimizadas y DESNORMALIZADAS para cada query. Pueden
  vivir en otra tabla, otra DB, o cache. Se actualizan desde el write side
  (síncrono o por eventos → consistencia eventual del read).
- **Niveles**: CQRS "simple" = misma DB, distintos modelos de objeto. CQRS "completo"
  = read store separado, sincronizado por eventos.

### Cuándo usar

- Con **DDD**, cuando el modelo de escritura (aggregate normalizado, con invariantes)
  y el de lectura (vistas desnormalizadas para UI/reportes) divergen mucho.
- Cuando **lecturas y escrituras escalan distinto** (95% lecturas → read replicas /
  read models cacheados sin tocar el write path).
- Cuando una sola "vista" del dato no sirve para todas las pantallas.

### Cuándo NO usar

- **CRUD simple**: si la pantalla muestra exactamente lo que guardás, separar modelos
  es duplicación pura.
- **Performance no es problema** y no hay divergencia read/write: el bus y los dos
  modelos agregan complejidad sin retorno.
- **Equipo pequeño / sistema chico**: la consistencia eventual del read model
  introduce bugs sutiles (UI que muestra dato viejo) que cuestan más que lo que rinden.

### Estructura de directorios

```
src/
├── application/
│   ├── commands/
│   │   ├── place-order.command.ts
│   │   └── place-order.handler.ts      # muta el write model (aggregate)
│   ├── queries/
│   │   ├── get-order-summary.query.ts
│   │   └── get-order-summary.handler.ts # lee del read model, retorna DTO
│   └── buses/{command-bus,query-bus}.ts
├── write/
│   └── domain/order.aggregate.ts        # modelo de escritura (DDD)
└── read/
    ├── order-summary.readmodel.ts        # desnormalizado, optimizado para UI
    └── projectors/order.projector.ts     # actualiza read model desde eventos
```

> **Trampa de la consistencia eventual**: si el read model se sincroniza por eventos,
> hay una ventana donde una escritura ya ocurrió pero la lectura aún no la refleja.
> Diseñá la UX para eso (optimistic UI, "procesando…") o usá CQRS simple (misma DB,
> read sincrónico) cuando no toleres el lag.

---

## 5. Event Sourcing

El estado NO se guarda como "snapshot actual" sino como la **secuencia inmutable de
eventos** que lo produjeron. El estado presente se DERIVA reproduciendo los eventos.

```
  Comando ─▶ Aggregate valida ─▶ emite Event(s) ─▶ append al Event Store
                                                          │
   Event Store (append-only, inmutable):                  │
   ┌──────────────────────────────────────────────────┐  │
   │ #1 OrderCreated   #2 ItemAdded   #3 OrderPaid …   │◀─┘
   └──────────────────────────────────────────────────┘
        │  replay (fold) para reconstruir estado
        ▼
   Estado actual = reduce(eventos)        Snapshot (opt.) = estado en evento #N
        │                                  para no reproducir desde #1
        ▼
   Projections ─▶ read models (CQRS) optimizados por vista
```

### Regla / estructura

- **El log de eventos es la fuente de verdad**, no una tabla de estado. El estado
  actual es un *fold* (reduce) sobre los eventos del aggregate.
- **Event Store**: almacenamiento **append-only e inmutable**. No se hace `UPDATE` ni
  `DELETE` de un evento: para corregir, se emite un evento compensatorio nuevo.
- **Projection**: reconstruye una vista de estado (o un read model CQRS) reproduciendo
  eventos. Si la lógica de proyección cambia, se REconstruye desde cero.
- **Snapshot**: optimización para aggregates con historia larga — se guarda el estado
  cada N eventos para no reproducir desde el principio. Es cache, no fuente de verdad.
- **Versionado de eventos**: los eventos viejos viven para siempre → necesitás
  upcasters/versionado de esquema de eventos. Esto es trabajo permanente.

### Cuándo usar

- **Audit trail crítico** o regulatorio: el historial completo es un requisito, no un
  lujo (finanzas, salud, compliance).
- **Time travel**: necesitás reconstruir el estado "como estaba en cualquier momento".
- Cuando **ya usás CQRS** y el write side se beneficia de tener eventos como store.
- Análisis: nuevos read models a partir de eventos históricos sin re-instrumentar.

### Cuándo NO usar

- **Reportes simples / CRUD**: la complejidad operativa (replay, snapshots,
  versionado, eventual consistency) no se justifica.
- **Datos que se borran / GDPR "right to be forgotten"**: un store inmutable choca de
  frente con "borrá mi dato". Hay mitigaciones (crypto-shredding) pero son costosas.
- **Equipo sin experiencia**: ES es de los patrones más difíciles de operar bien;
  adoptarlo sin madurez lleva a un sistema imposible de debuggear.

### Estructura de directorios

```
src/
├── domain/order/
│   ├── order.aggregate.ts          # apply(event) muta estado; decide() emite eventos
│   └── events/                     # eventos inmutables, versionados
│       ├── order-created.event.ts
│       └── order-paid.event.ts
├── eventstore/
│   ├── event-store.ts              # append-only: append() / loadStream(aggregateId)
│   └── snapshot-store.ts           # snapshots cada N eventos
└── read/
    └── projections/
        ├── order-summary.projection.ts   # fold(eventos) → read model
        └── rebuild.ts                     # reconstruye proyecciones desde #1
```

> **Lo inmutable es para siempre**: un evento mal diseñado vive en el store eternamente
> y todo replay lo verá. Diseñá los eventos con cuidado, en pasado, con todo el dato
> necesario para reproducir el estado SIN consultar el mundo exterior.

---

## Combinaciones Comunes

Los patrones son capas ortogonales; en sistemas reales se apilan. Estas son las
combinaciones que se sostienen en producción:

| Combinación | Por qué encaja | Qué aporta cada uno | Cuándo |
|-------------|----------------|---------------------|--------|
| **Clean Arch + DDD Tactical** | Clean da la separación TÉCNICA (anillos); DDD da la separación SEMÁNTICA (aggregates/VOs). | Clean: dónde van las dependencias. DDD: cómo modelás el dominio que vive en el anillo interno. | Default para dominios ricos de larga vida. |
| **Hexagonal + Clean Arch** | Son conceptualmente equivalentes; Hexagonal es más explícito en ports. | Misma regla de dependencia hacia el dominio; Hexagonal nombra los boundaries como contratos. No los enfrentes: Hexagonal ES una implementación de Clean. | Cuando querés boundaries explícitos y verificables. |
| **CQRS + DDD** | Encaje natural: los Commands van al AGGREGATE (write model con invariantes); las Queries van al READ MODEL desnormalizado. | DDD: integridad del write side. CQRS: lecturas optimizadas sin contaminar el aggregate. | Cuando read y write divergen mucho en un dominio rico. |
| **Event Sourcing + CQRS** | Encaje natural: los eventos SON el store del lado Command; las projections alimentan los read models del lado Query. | ES: write side como log inmutable. CQRS: projections construyen vistas de lectura desde los eventos. | Audit crítico + ya tenés CQRS. Casi nunca ES sin CQRS. |

### Stack típico maduro

```
Hexagonal (boundaries)  ──┐
   = Clean (dependencia)  ├─▶ define DÓNDE va cada cosa
DDD Tactical              ──┘   y CÓMO se modela el dominio
       │
       ├─ CQRS         ──▶ separa Command (aggregate) de Query (read model)
       │
       └─ Event Sourcing ──▶ el write side persiste eventos; CQRS los proyecta
```

### Reglas de oro (innegociables)

1. **Las dependencias apuntan al dominio. Siempre.** Es la regla común a Clean y
   Hexagonal. Una entidad que importa el ORM ya rompió la arquitectura, sin importar
   las carpetas.
2. **No apliques patrones a un CRUD.** Clean/Hexagonal/DDD/CQRS/ES en un CRUD simple
   son ceremonia que ralentiza sin proteger nada. El patrón se gana, no se asume.
3. **Hexagonal y Clean no compiten.** Hexagonal es una forma explícita de implementar
   la regla de dependencia de Clean. Elegí vocabulario, no bando.
4. **DDD modela; Clean ubica.** DDD dice CÓMO es el dominio (aggregates, VOs); Clean
   dice DÓNDE vive (anillo interno). Se complementan, no se solapan.
5. **CQRS sin necesidad = duplicación; ES sin CQRS = rareza.** Separá read/write solo
   si divergen. Event Sourcing casi siempre acompaña a CQRS, no va solo.
6. **Lo inmutable (eventos) es para siempre.** En Event Sourcing, un evento mal
   diseñado te persigue en cada replay. Diseñá eventos con la misma seriedad que un
   contrato público.
7. **Verificá la arquitectura con tests.** La regla de dependencia y los boundaries
   hexagonales se rompen en silencio. Un test de arquitectura (dependency-cruiser,
   ArchUnit) los convierte en garantía mecánica, no en disciplina opcional.

---

## Integración con CASTLE A (Architecture)

Cuando un agente analiza código, CASTLE A vigila la coherencia arquitectónica. Señales
típicas que disparan WARNING:

- **Dominio importando infraestructura**: una entidad/aggregate que importa el ORM, el
  cliente HTTP o el SDK del broker → regla de dependencia rota.
- **Anillos saltados**: un controller que habla directo con la DB sin pasar por un use
  case (en un sistema que sí declara Clean/Hexagonal).
- **Dominio anémico disfrazado de DDD**: aggregates sin lógica + services
  procedurales con toda la regla de negocio.
- **CQRS sin justificación**: dos modelos y un bus sobre un CRUD que no diverge → over-
  engineering; sugerir simplificar.
- **Event Sourcing sin versionado/snapshots**: store de eventos sin estrategia de
  upcasting ni snapshots → bomba de tiempo operativa.
- **Adapter referenciado desde el core** (Hexagonal): el Application Core importando un
  adapter concreto en vez del port → boundary roto; sugerir invertir la dependencia.
