---
name: clean-arch-setup
description: "Scaffoldea Clean Architecture por stack (Go/TS/Python): capas domain/application/infrastructure/delivery, use cases, entities con invariants, repository interfaces, test de arquitectura que falla si domain importa infra, y ADR-001"
argument-hint: "[domain-name] [--stack go|ts|python] [--no-tests]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /clean-arch-setup

Scaffoldea **Clean Architecture** para un bounded context en el stack del proyecto. Genera las 4 capas
con la regla de dependencia, interfaces de use cases, entities con invariants, repository interfaces
(puertos), un **test de arquitectura** que FALLA si `domain/` importa `infrastructure/`, y el **ADR-001**.
ADVIERTE "patrón prematuro" si el proyecto tiene `< 5` entidades.

## Instrucciones

1. Invocar el skill `clean-arch-setup` usando la herramienta Skill
2. Argumentos:
   - `[domain-name]`: nombre del bounded context o dominio (ej. `orders`, `billing`). Obligatorio
   - `--stack <go|ts|python>`: fuerza el stack del scaffolding. Default: auto-detectado desde `.king/knowledge/stack.md`
   - `--no-tests`: omite el test de arquitectura (DESACONSEJADO — el test es la garantía mecánica de la regla de dependencia; el skill advierte el riesgo)
3. Seguir todas las fases del skill en orden:
   - Detect stack → Prematurity check → Scaffold layers → Generate contracts → Architecture test + ADR
4. Agentes coordinados: @architect (principal: granularidad de capas, valida dependencias hacia el dominio, redacta ADR-001), @developer (genera scaffolding y firmas), @qa (valida que el arch-test FALLE ante un import prohibido)
5. IMPORTANTE: nunca generar imports de infra dentro de `domain/`; nunca implementar los repository interfaces en domain/application (solo el puerto); nunca generar el arch-test con la regla invertida o como skip

Si el proyecto tiene `< 5` entidades de negocio reales, el skill NO continúa en silencio: emite WARNING
"patrón prematuro" (Clean en un CRUD o dominio chico es ceremonia vacía) y pide confirmación. Si no se
detecta el stack ni se pasa `--stack`, lo infiere del árbol (`go.mod`→go, `package.json`/`tsconfig.json`→ts,
`pyproject.toml`→python).

## Ejemplos

### Dominio TS con stack auto-detectado

```
/clean-arch-setup orders
```

### Dominio Go forzando el stack

```
/clean-arch-setup billing --stack go
```

### Greenfield sin test de arquitectura (desaconsejado)

```
/clean-arch-setup catalog --stack python --no-tests
```

## Ejemplo de árbol generado — Go

`internal/` con las 4 capas y la regla de dependencia (las flechas apuntan SIEMPRE hacia el dominio):

```
internal/
├── domain/                          # entities, value objects, domain events — CERO imports de infra
│   └── orders/
│       ├── order.go                 # Entity con invariant (NewOrder rechaza 0 items)
│       └── money.go                 # Value Object inmutable (rechaza monto negativo)
├── application/                     # use cases + puertos (interfaces)
│   └── orders/
│       ├── place_order.go           # UseCase: Execute(ctx, input) (output, error)
│       └── order_repository.go      # PORT (interface) — sin implementación
├── infrastructure/                  # adapters: implementan los puertos (infra → application, correcto)
│   └── orders/
│       └── postgres_order_repo.go   # implementa application.OrderRepository (stub TODO)
└── delivery/                        # HTTP handlers, gRPC, CLI
    └── orders/
        └── order_handler.go         # invoca el use case

.go-arch-lint.yml                    # FALLA si domain depende de infrastructure/delivery
docs/adr/ADR-001-clean-architecture.md
```

## Ejemplo de árbol generado — TypeScript

`src/` con `presentation/` como capa de entrada (en TS la capa de delivery se llama `presentation`):

```
src/
├── domain/                          # negocio puro — CERO imports de infra ni ORM
│   └── orders/
│       ├── order.ts                 # Entity: el constructor lanza si items === 0 (invariant)
│       └── money.ts                 # Value Object inmutable (igualdad por valor)
├── application/
│   └── orders/
│       ├── place-order.usecase.ts   # class PlaceOrderUseCase { execute(input): Promise<Output> }
│       └── ports/
│           └── order-repository.port.ts   # interface OrderRepository — sin implementación
├── infrastructure/                  # adapters que implementan los ports
│   └── orders/
│       └── postgres-order.repository.ts   # implements OrderRepository (stub TODO)
└── presentation/                    # controllers, resolvers, CLI handlers
    └── orders/
        └── order.controller.ts      # inyecta el use case por constructor (DI)

.dependency-cruiser.cjs              # regla no-domain-to-infra (error): ^src/domain ↛ ^src/infrastructure|^src/presentation
docs/adr/ADR-001-clean-architecture.md
```

El test de arquitectura (`go-arch-lint` / `dependency-cruiser` / `import-linter`) es la garantía
MECÁNICA de la regla de dependencia: si una entidad de `domain/` importa el ORM o un adapter de
`infrastructure/`, el test FALLA. Sin él, la regla es disciplina opcional que se rompe en silencio.
Detalle de patrones y trade-offs en `knowledge/domain/architecture-patterns.md`.
