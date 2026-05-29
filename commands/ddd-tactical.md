---
name: ddd-tactical
description: "Scaffoldea DDD táctico por stack (Go/TS/Python): Aggregate con invariants y método de fábrica, Entities con identidad TIPADA (ID como Value Object), Value Objects inmutables, Domain Events inmutables (pasado + payload + timestamp), Repository interface (save/findById/findAll con Specification) y tests de invariants"
argument-hint: "[aggregate-name] [--entities a,b] [--vos a,b] [--events a,b] [--stack go|ts|python]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /ddd-tactical

Scaffoldea los bloques de **DDD Táctico** para un aggregate en el stack del proyecto. Genera el
**Aggregate Root** con invariants protegidos y **método de fábrica** (única construcción válida),
**Entities** con identidad **TIPADA** (el ID es un Value Object, NO un `string`/`uuid` crudo), **Value
Objects** inmutables que validan en el constructor, **Domain Events** inmutables (nombre en pasado,
payload, `timestamp`), la **Repository interface** de colección (`save` / `findById` / `findAll` con
**Specification**), y los **tests unitarios de las invariants**. ADVIERTE "dominio anémico" si las
entidades son solo getters/setters sin reglas.

## Instrucciones

1. Invocar el skill `ddd-tactical` usando la herramienta Skill
2. Argumentos:
   - `[aggregate-name]`: nombre del aggregate root (ej. `Order`, `Subscription`). Obligatorio
   - `--entities a,b`: entidades internas del aggregate (ej. `OrderItem`). Opcional
   - `--vos a,b`: Value Objects además de los IDs (ej. `Money,Address`). Opcional
   - `--events a,b`: Domain Events que emite el aggregate (ej. `OrderPlaced,OrderCancelled`). Opcional
   - `--stack <go|ts|python>`: fuerza el stack. Default: auto-detectado desde `.king/knowledge/stack.md`
3. Seguir todas las fases del skill en orden:
   - Detect stack → Anemia check → Value Objects + Entities → Aggregate + Domain Events → Repository + invariant tests
4. Agentes coordinados: @architect (principal: frontera del aggregate, invariants en el root, referencias por ID), @developer (genera VOs inmutables, IDs tipados, fábrica, eventos, interfaz del repositorio), @qa (valida que el test de invariant FALLE al violar la regla)
5. IMPORTANTE: nunca usar `string`/`uuid` crudo como identidad (el ID es un VO tipado); nunca generar VOs o domain events mutables; nunca dejar construir el aggregate en estado inválido (única entrada = fábrica); nunca poner las invariants en un service externo (modelo anémico); nunca implementar el repository en `domain/` (solo la interfaz)

Si el aggregate no tiene reglas reales que proteger (solo getters/setters / CRUD puro), el skill NO
continúa en silencio: emite WARNING "dominio anémico" (DDD táctico sin invariants es ceremonia) y pide
confirmación. Si no se detecta el stack ni se pasa `--stack`, lo infiere del árbol (`go.mod`→go,
`package.json`/`tsconfig.json`→ts, `pyproject.toml`→python).

## Ejemplos

### Aggregate con stack auto-detectado

```
/ddd-tactical Order
```

### Aggregate Order completo (entity + VO + evento)

```
/ddd-tactical Order --entities OrderItem --vos Money --events OrderPlaced
```

### Aggregate Go forzando el stack

```
/ddd-tactical Subscription --vos Money,BillingCycle --events SubscriptionRenewed --stack go
```

## Ejemplo completo — aggregate `Order` (invariant "máximo 10 items")

`/ddd-tactical Order --entities OrderItem --vos Money --events OrderPlaced` genera (naming TS; Go/Python
análogo) el módulo `domain/order/` con identidad tipada en cada nivel y el invariant protegido en el root:

```
src/domain/order/
├── order-id.vo.ts            # Value Object: identidad TIPADA del aggregate (NO string crudo)
├── order-item-id.vo.ts       # Value Object: identidad TIPADA de la entity OrderItem
├── money.vo.ts               # Value Object inmutable: el constructor rechaza monto negativo
├── order-item.entity.ts      # Entity interna: igualdad por OrderItemId, no por atributos
├── order.aggregate.ts        # Aggregate Root: create() (fábrica) + addItem() lanza si > 10 items
├── order-placed.event.ts     # Domain Event: nombre en pasado + payload(OrderId, total) + occurredOn
├── order.repository.ts       # interfaz: save(Order) / findById(OrderId) / findAll(Specification)
├── specification.ts          # interfaz Specification.isSatisfiedBy(order): boolean
└── order.spec.ts             # tests: addItem #10 pasa, #11 lanza DomainException; OrderId igual por valor
```

Claves del modelo generado:

- **Identidad tipada**: `OrderId` y `OrderItemId` son Value Objects, no `string`. Pasar un `OrderId`
  donde va un `OrderItemId` es un error de tipo en compilación, no un bug en runtime.
- **Método de fábrica**: `Order.create(id, items)` es la ÚNICA construcción válida — el constructor es
  privado. No se puede crear un `Order` en estado inválido.
- **Invariant en el aggregate**: `Order.addItem(item)` lanza `DomainException("max 10 items")` al
  intentar agregar el item 11. La regla vive en el aggregate root, NUNCA en un `OrderService` externo.
- **Value Object inmutable**: `Money` valida en el constructor (rechaza negativos), no tiene setters,
  iguala por valor. Para cambiarlo se reemplaza, no se muta.
- **Domain Event inmutable**: `OrderPlaced` lleva nombre en PASADO, payload (`OrderId`, total) y
  `occurredOn` (timestamp). Se emite al confirmar la orden y no se muta después.
- **Repository de colección**: la interfaz expone `save` / `findById(OrderId)` / `findAll(Specification)`
  — uno por aggregate root, sin implementación (la impl. vive en infra). `findAll` filtra por
  `Specification`, no por queries crudas.
- **Tests de invariant**: el test agrega 10 items (pasa) y el item 11 (espera `DomainException`). Si se
  relaja el límite, el test del item 11 DEBE fallar — es la garantía mecánica del invariant.

El ID tipado, la inmutabilidad de los VOs/eventos y el invariant dentro del root no son adornos: son lo
que vuelve el lenguaje ubicuo verificable por el compilador y por los tests. Detalle de patrones y
trade-offs en `knowledge/domain/architecture-patterns.md` §3 (DDD Tactical).
