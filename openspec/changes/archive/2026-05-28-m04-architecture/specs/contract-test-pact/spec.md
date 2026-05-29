# Delta Spec — contract-test-pact (M-36)

## ADDED Requirements

### Requirement: Skill `/contract-test-pact`
El skill `/contract-test-pact` SHALL generar consumer-driven contract tests con Pact entre servicios:
consumer test (Pact DSL → pact file), provider verification, setup de Pact Broker (docker-compose si no hay externo)
e integración CI. SHALL soportar HTTP REST (Pact v3+v4), gRPC (v4) y Message (v3 async).
Los consumer mocks MUST basarse en respuestas reales del provider (o derivarse de la spec OpenAPI, no de la imaginación).
La provider verification MUST ejecutar contra el provider real.

#### Scenario: Genera consumer test y pact file
- **Given** OrderService como consumer de PaymentService con interacción `POST /payments → {status, transaction_id}`
- **When** `/contract-test-pact --consumer order-service --provider payment-service`
- **Then** genera consumer test con Pact DSL y `pact/order-service-payment-service.json` con request/response formalizados

#### Scenario: Provider verification falla al romper el contrato
- **Given** un pact file que espera `transaction_id`
- **And** el provider cambia a `transactionId` (camelCase)
- **When** se ejecuta la provider verification
- **Then** falla indicando exactamente qué campo difiere

### Requirement: Integración CASTLE C
Toda integración entre servicios sin pact file SHALL generar WARNING en CASTLE C sugiriendo `/contract-test-pact`.

> Set Gherkin completo: M04 §7 (Feature: Contract Testing con Pact).
