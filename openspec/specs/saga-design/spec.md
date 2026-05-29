# Delta Spec — saga-design (M-05)

## ADDED Requirements

### Requirement: Knowledge `saga-patterns.md`
El framework SHALL proveer `knowledge/domain/saga-patterns.md` con 9 patrones (ACID local, 2PC,
Saga Choreography, Saga Orchestration, Compensating Transactions, Outbox, Inbox, TCC, Saga Coordinator)
con trade-offs explícitos, cuándo NO usar cada uno y una tabla comparativa.

### Requirement: Skill `/saga-design`
El skill `/saga-design` SHALL diseñar un saga distribuido con pasos, compensaciones idempotentes,
eventos outbox y handlers. El Outbox Pattern MUST ser no-opcional (no feature flag). SHALL soportar
4 tecnologías (temporal, step-functions, camunda, custom; default orchestration/custom).

#### Scenario: Genera saga completo con compensaciones
- **Given** "crear orden: reservar inventario + cobrar pago + enviar confirmación" con 3 servicios
- **When** el developer ejecuta `/saga-design`
- **Then** genera diagrama Mermaid con happy path y rollback path
- **And** tabla de 3 pasos con acción forward y compensación de cada uno
- **And** el outbox pattern está en la misma transacción del paso

#### Scenario: Compensaciones idempotentes
- **Given** un handler de compensación generado
- **When** el test lo llama dos veces con el mismo `saga_id`
- **Then** el estado final es igual que tras la primera compensación (no doble revert)

### Requirement: Integración CASTLE C
Cuando se detecte modificación de estado en múltiples servicios sin saga documentada,
CASTLE C SHALL emitir WARNING sugiriendo `/saga-design`.

> Set Gherkin completo: M04 §7 (Feature: Saga Design).
