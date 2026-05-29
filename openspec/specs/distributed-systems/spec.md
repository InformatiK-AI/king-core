# Delta Spec — distributed-systems (M-32)

## ADDED Requirements

### Requirement: Knowledge `distributed-systems.md`
El framework SHALL proveer `knowledge/domain/distributed-systems.md` con CAP theorem, consensus (Raft/Paxos),
service discovery, load balancing, comparativa de brokers (Kafka/RabbitMQ/NATS/SQS), distributed caching,
stream processing y service mesh, con criterios de elección concretos y anti-patrones (Redlock).

### Requirement: Skill `/microservice-extract`
SHALL guiar la extracción de un bounded context con Strangler Fig: análisis de dependencias cruzadas,
plan de fases con go/no-go, contrato API/event, scaffold del servicio, strategy de datos y handoff a
`/contract-test-pact`. MUST verificar tenancy (`.king/tenancy.yaml`) y propagar la estrategia de aislamiento si aplica (M07).

#### Scenario: Genera plan de extracción en fases
- **Given** un monolito con módulo de pagos con 3 dependencias cross-module
- **When** `/microservice-extract src/payments --target-service payment-service`
- **Then** genera plan de 3 fases con go/no-go, verifica tenancy si aplica, y sugiere `/contract-test-pact` al final

### Requirement: Skill `/event-broker-setup`
SHALL configurar Kafka/RabbitMQ/NATS/SQS con producers (serialización), consumers (retry + DLQ + idempotency key),
schema registry, observabilidad de lag y tests con testcontainers. docker-compose MUST ser válido para local.

### Requirement: Skill `/idempotency`
SHALL agregar idempotency keys con 3 strategies (idempotency-key-header default, request-hash, client-id+sequence),
middleware de deduplicación, schema con TTL y tests. El middleware MUST distinguir "ya procesado" (resultado cacheado)
de "en proceso" (202 + Retry-After).

#### Scenario: Hace el endpoint POST retry-safe
- **Given** un `POST /orders` sin idempotency key
- **When** `/idempotency src/handlers/orders.ts --strategy idempotency-key-header`
- **Then** genera middleware que lee `Idempotency-Key`; misma key → resultado cacheado; test confirma un solo registro en DB

> Set Gherkin completo: M04 §7 (Feature: Distributed Systems Guidance).
