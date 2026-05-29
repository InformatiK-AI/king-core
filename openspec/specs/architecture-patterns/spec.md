# Delta Spec — architecture-patterns (M-25a-e)

## ADDED Requirements

### Requirement: Knowledge `architecture-patterns.md`
El framework SHALL proveer `knowledge/domain/architecture-patterns.md` cubriendo Clean Architecture,
Hexagonal, DDD Tactical, CQRS y Event Sourcing con trade-offs, "cuándo usar", "cuándo NO usar" y tabla
de combinaciones comunes. Cada patrón MUST incluir un ejemplo de estructura de directorios.

### Requirement: Skill `/clean-arch-setup`
SHALL scaffoldear Clean Architecture por stack (Go/TS/Python) con interfaces de use cases, entities con
invariants, repository interfaces, tests de arquitectura (dependency-cruiser/go-arch-lint) y ADR-001.
SHALL advertir si el proyecto tiene < 5 entidades (patrón prematuro).

#### Scenario: Genera estructura con tests de arquitectura válidos
- **Given** un proyecto TS sin arquitectura definida
- **When** el developer ejecuta `/clean-arch-setup orders`
- **Then** crea domain/application/infrastructure/presentation, ADR-001, y tests que fallan si domain importa infra

### Requirement: Skill `/hexagonal-setup`
SHALL generar ports explícitos (driving/driven), adapters organizados y boundary tests que verifican que
application/ no importa adapters/. Naming: `UserRepository` (port) vs `PostgresUserRepository` (adapter).

### Requirement: Skill `/ddd-tactical`
SHALL scaffoldear aggregate con invariants, entities con identidad tipada (ID como VO), value objects
inmutables, domain events inmutables con timestamp, y repository interface. Tests de invariants.

#### Scenario: Genera aggregate con invariant
- **Given** regla "una orden no puede tener más de 10 items"
- **When** `/ddd-tactical Order --entities OrderItem --events OrderPlaced`
- **Then** `Order.addItem` lanza DomainException al superar el límite; OrderId es VO; test verifica el item 11

### Requirement: Skill `/cqrs-setup`
SHALL configurar command bus, query bus, read models y validators. Command MUST no poder leer; Query MUST no poder escribir (enforced por tipos).

### Requirement: Skill `/event-sourcing`
SHALL configurar event store, rehydration, snapshots y projections. MUST hacer 3 preguntas de validación
(audit trail? time-travel? CQRS activo?) y rechazar si < 2 "sí", sugiriendo audit log simple.

### Requirement: Extensiones ADITIVAS
`agents/architect.md` SHALL incorporar sección "Architecture Patterns Knowledge" + árbol de decisión
(referencia a architecture-patterns.md). `skills/sdd-apply/SKILL.md` SHALL incorporar "Step 0 — Architecture Pattern"
salteable si el patrón ya está documentado. Ambas MUST ser aditivas (sin remover contenido).

> Set Gherkin completo: M04 §7 (Features: Architecture Setup, DDD/CQRS/Event Sourcing).
