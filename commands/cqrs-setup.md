---
name: cqrs-setup
description: "Configura CQRS para un dominio: command bus + handlers (retornan void o ID), query bus + handlers (retornan DTO, nunca mutan), read models desnormalizados, command validators y tests. Enforcement por TIPOS: Command no puede leer, Query no puede escribir. Si el stack lo soporta, sugiere DB separada read/write"
argument-hint: "[domain] --commands <c1,c2> --queries <q1,q2> [--lang ts|py|go|java] [--db-split auto|same|separate] [--no-tests]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /cqrs-setup

Configura **CQRS** (Command Query Responsibility Segregation) para un dominio: genera el **command bus**
con handlers que mutan el write model y retornan `void`/ID, el **query bus** con handlers que leen del read
model y retornan un DTO, los **read models desnormalizados**, los **command validators** y los **tests** de
cada handler. La separación se enforced por **TIPOS**: un Command NO puede leer y una Query NO puede
escribir (firmas + marker types — no una convención que se rompe en silencio). Si el stack lo soporta,
SUGIERE DB separada read/write (CQRS completo). ADVIERTE "patrón prematuro" si es un CRUD donde la pantalla
muestra exactamente lo que se guarda.

## Instrucciones

1. Invocar el skill `cqrs-setup` usando la herramienta Skill
2. Argumentos:
   - `[domain]`: nombre del contexto/módulo (ej. `orders`, `billing`). Obligatorio
   - `--commands <c1,c2,...>`: lista de comandos de negocio (ej. `CreateOrder,CancelOrder`). Al menos un command o una query es obligatorio
   - `--queries <q1,q2,...>`: lista de queries principales (ej. `GetOrderById,ListOrdersByCustomer`)
   - `--lang <ts|py|go|java|...>`: fuerza el lenguaje del scaffold. Default: auto-detectado desde `.king/knowledge/stack.md`
   - `--db-split <auto|same|separate>`: `auto` recomienda según el stack (default); `same` = CQRS simple (misma DB); `separate` = CQRS completo (read store separado por eventos)
   - `--no-tests`: omite los tests de handlers (DESACONSEJADO — el test es lo que prueba que la separación se respeta; el skill advierte el riesgo)
3. Seguir todas las fases del skill en orden:
   - Detect stack → Prematurity check → Buses + contracts → Handlers + read models → Validators + tests → DB split advice
4. Agentes coordinados: @architect (principal: read models por vista, write side sobre el aggregate existente, recomendación de DB split), @developer (genera buses, handlers, read models, validators y marker types), @qa (valida que el enforcement por tipos impida Command-que-lee / Query-que-escribe y que los unit tests cubran handler + validación)
5. IMPORTANTE: un Command handler retorna `void`/ID y NUNCA estado de lectura; un Query handler retorna un DTO y NUNCA muta ni emite eventos; la separación SIEMPRE se enforced por tipos (no compila o falla un test/lint), nunca por disciplina; una Query lee del read model desnormalizado, NUNCA del aggregate (write model)

Si el dominio es un CRUD donde la pantalla muestra exactamente lo que se guarda (read y write no divergen),
el skill NO continúa en silencio: emite WARNING "patrón prematuro" (CQRS sin divergencia = duplicación
pura + trampa de consistencia eventual) y pide confirmación. Si no se detecta el lenguaje ni se pasa
`--lang`, lo infiere del árbol (`go.mod`→go, `package.json`/`tsconfig.json`→ts, `pyproject.toml`→python,
`pom.xml`/`build.gradle`→java).

## Ejemplos

### Dominio orders con CreateOrder + GetOrderById (stack auto-detectado)

```
/cqrs-setup orders --commands CreateOrder --queries GetOrderById
```

`CreateOrder` (Command): el handler carga/crea el aggregate `Order`, valida sus invariants, persiste vía
`OrderRepository`, emite `OrderPlaced` y retorna el `OrderId` — NUNCA el `Order`. Su validator verifica
`items.length > 0` y `customerId` presente ANTES del handler.
`GetOrderById` (Query): el handler consulta el `OrderSummaryReadModel` desnormalizado (total ya calculado,
nombre del cliente embebido) y retorna `OrderDTO` — NO toca el aggregate, NO escribe, NO emite eventos.

### Múltiples commands y queries forzando el lenguaje

```
/cqrs-setup billing --commands ChargeInvoice,RefundInvoice --queries GetInvoiceById,ListUnpaidInvoices --lang go
```

### CQRS completo con read store separado por eventos

```
/cqrs-setup orders --commands CreateOrder,CancelOrder --queries GetOrderById --db-split separate
```

### Greenfield Python sin tests (desaconsejado)

```
/cqrs-setup catalog --commands AddProduct --queries SearchProducts --lang py --no-tests
```

## Ejemplo de árbol generado — TypeScript

```
src/
├── application/
│   ├── commands/
│   │   ├── create-order.command.ts        # objeto Command inmutable (customerId, items[])
│   │   └── create-order.handler.ts        # muta el write model, retorna void | OrderId
│   ├── queries/
│   │   ├── get-order-by-id.query.ts       # objeto Query inmutable (orderId)
│   │   └── get-order-by-id.handler.ts     # lee read model, retorna OrderDTO (no muta)
│   ├── validators/
│   │   └── create-order.validator.ts      # middleware del command bus (valida ANTES del handler)
│   └── buses/
│       ├── command-bus.ts                  # register(CommandType→handler) + dispatch(cmd): void|Id
│       └── query-bus.ts                    # register(QueryType→handler) + ask(query): DTO
├── shared/
│   └── cqrs.ts                             # marker types: Command, Query, CommandHandler<C>, QueryHandler<Q,R>
├── write/
│   └── domain/order.aggregate.ts           # write model (reutiliza el aggregate DDD existente)
└── read/
    ├── order-summary.readmodel.ts          # DTO desnormalizado por vista
    └── projectors/order.projector.ts       # sincroniza read model desde el write side

tests/
├── create-order.handler.test.ts           # muta + valida; retorna OrderId
├── get-order-by-id.handler.test.ts        # retorna DTO; NO escribe
└── cqrs-enforcement.test.ts               # un Command que devuelve estado / una Query que muta NO compila
```

El **enforcement por tipos** es la garantía MECÁNICA de la separación: `CommandHandler<C>` retorna
`void | Id` (nunca estado de lectura) y `QueryHandler<Q, R>` retorna `R` (nunca recibe un repositorio de
escritura). En lenguajes estáticos (TS/Go/Java) violarlo NO compila; en dinámicos (Python) un test/lint
dedicado lo vuelve la garantía equivalente. Sin él, la separación es disciplina opcional que se rompe en
silencio. Detalle de patrones, niveles (simple vs completo) y trade-offs en
`knowledge/domain/architecture-patterns.md` §4.
