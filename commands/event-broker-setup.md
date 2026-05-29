---
name: event-broker-setup
description: "Configura un message broker (Kafka/RabbitMQ/NATS/SQS) end-to-end: topics/queues, producers con serialización (Avro/Protobuf/JSON Schema), consumers con retry + dead-letter queue + idempotency key, schema registry, observabilidad de lag y tests con testcontainers. docker-compose válido para local"
argument-hint: "--broker <kafka|rabbitmq|nats|sqs> --topics <t1,t2,...> [--serialization avro|protobuf|json-schema|json] [--group <consumer-group>] [--dlq-max-retries <n>] [--idempotency-key <field>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /event-broker-setup

Configura un **message broker** (Kafka, RabbitMQ, NATS/JetStream o SQS/SNS) de punta a punta: crea los
**topics/queues** (cada uno con su **DLQ**), genera **producers** con serialización tipada
(Avro/Protobuf/JSON Schema), **consumers** con **retry + backoff**, **dead-letter queue** e **idempotency
key**, registra los esquemas en un **schema registry** (cuando aplica), instrumenta **observabilidad de
lag** y salud del consumer group, y produce **tests con testcontainers**. Todo corriendo en un
**`docker-compose` válido para local**. Alimenta **CASTLE A (Architecture)** y **L (Logging)**.

## Instrucciones

1. Invocar el skill `event-broker-setup` usando la herramienta Skill
2. Argumentos:
   - `--broker <kafka|rabbitmq|nats|sqs>`: broker a configurar. Si se omite, el skill **auto-recomienda** según el contexto usando la matriz de `knowledge/domain/distributed-systems.md` (replay/throughput → Kafka; routing complejo → RabbitMQ; latencia mínima → NATS; cero-ops en AWS → SQS/SNS)
   - `--topics <t1,t2,...>`: topics/queues a crear, separados por comas, con su producer/consumer. En SQS son colas; en RabbitMQ pueden incluir exchange (`orders:topic`); en NATS subjects (`orders.created`)
   - `--serialization <avro|protobuf|json-schema|json>`: formato del payload. Default: `json-schema`. `avro`/`protobuf` activan el schema registry
   - `--group <consumer-group>`: consumer/queue group. Default: derivado del nombre del servicio
   - `--dlq-max-retries <n>`: reintentos antes de la DLQ. Default: `3` (backoff exponencial + jitter)
   - `--idempotency-key <field>`: campo usado como clave de deduplicación. Default: `messageId`
3. Seguir todas las fases del skill en orden:
   - Select broker + serialization → Provision topics/queues (+ DLQ) → Schema registry → Producer (serialización) → Consumer (retry + DLQ + idempotency) → Observability (lag) → Tests + docker-compose
   - Phase 3 (schema registry) se SALTA si la serialización es JSON sin registry
4. Agentes coordinados: @architect (principal: recomienda broker, valida garantías mínimas y compatibilidad de esquemas), @developer (genera producers/consumers/config/compose), @qa (valida que el test de idempotencia y el de redelivery→DLQ fallen sin las garantías), @performance (opcional: particionado/ordering + observabilidad de lag)
5. IMPORTANTE: nunca generar un consumer sin idempotency key; nunca un topic/queue sin DLQ; nunca promover un breaking change de esquema sin compatibilidad del registry; nunca declarar "exactly-once" sin que toda la cadena lo soporte; nunca embeber secretos/connection strings/puertos en código, tests o compose (usar variables de entorno / `{{SLOT}}`)

El delivery es **at-least-once SIEMPRE**: ningún broker garantiza exactly-once end-to-end por sí solo. Por
eso el consumer SIEMPRE lleva idempotency key (dedup) y el topic SIEMPRE lleva DLQ — son la línea base que
CASTLE A vigila, no extras opcionales.

## Ejemplos

### Kafka con un topic + producer + consumer + DLQ (Avro + schema registry)

```
/event-broker-setup --broker kafka --topics orders.created --serialization avro --group order-processor --dlq-max-retries 3 --idempotency-key orderId
```

Esto genera:

- **Topic** `orders.created` con 3 particiones (partition key = `orderId` → ordering por orden) + **DLQ** `orders.created.DLQ`.
- **Schema registry** (Confluent) en el `docker-compose`, con el esquema `orders.created-value` (`.avsc`) registrado bajo compatibilidad `BACKWARD`.
- **Producer** que serializa el evento con Avro contra el registry, con `enable.idempotence=true` + `acks=all`, e incluye `orderId` como `IDEMPOTENCY_KEY`.
- **Consumer** en el group `order-processor` que:
  - deserializa resolviendo el `schema id` embebido;
  - **deduplica** por `orderId` contra un store (Inbox): si ya fue procesado, ACK sin reprocesar (1 efecto);
  - **reintenta** errores transitorios con backoff hasta 3 veces;
  - tras agotar reintentos, envía el mensaje a `orders.created.DLQ` con metadata (causa, intentos, timestamp) y ACK del original;
  - hace **commit del offset DESPUÉS de procesar** (at-least-once correcto).
- **Observabilidad**: lag por partición, health del consumer group, tamaño de la DLQ y alerta de lag creciente.
- **Tests con testcontainers**: producer→consumer, redelivery→DLQ, idempotencia (mismo `orderId` 2× = 1 efecto), y compatibilidad de esquema.
- **`docker-compose.yml`** válido para local: Kafka (KRaft) + Schema Registry + Kafka UI, puertos vía `{{SLOT}}`, sin secretos.

Esquema de flujo del topic:

```
producer ──(Avro, key=orderId)──▶ topic orders.created (3 particiones)
                                          │
                                  consumer group order-processor
                                          │
                          dedup(orderId)? ─sí─▶ ACK (sin reprocesar)  ── 1 efecto
                                          │no
                                  process() ─ok─▶ ACK
                                          │error transitorio
                                  retry × ≤3 (backoff) ─agotado─▶ orders.created.DLQ (+ metadata)
```

### RabbitMQ con routing por tipo (JSON Schema, sin registry pesado)

```
/event-broker-setup --broker rabbitmq --topics payments:topic --serialization json-schema --group payment-worker
```

(exchange topic + queue + binding + dead-letter exchange; consumer con dedup + retry + DLX)

### NATS JetStream para baja latencia inter-servicio

```
/event-broker-setup --broker nats --topics user.events --serialization protobuf
```

### SQS managed en AWS (cero-ops, DLQ nativa)

```
/event-broker-setup --broker sqs --topics order-events --idempotency-key messageId --dlq-max-retries 5
```

(queue + redrive policy a `order-events-dlq` con `maxReceiveCount=5`; FIFO + `MessageGroupId` si se necesita ordering)

### Auto-recomendar el broker (sin --broker)

```
/event-broker-setup --topics order.events --serialization avro
```

(el skill aplica la matriz de `distributed-systems.md` y justifica la elección con su "cuándo preferirlo")

## Comparativa de brokers — cuándo preferir cada uno

| Broker | Cuándo preferirlo | Costo / límite |
|--------|-------------------|----------------|
| **Kafka** | Retención y **replay** (event sourcing), alto throughput sostenido, varios consumer groups sobre el mismo stream | Operación pesada; overkill para colas de tareas simples |
| **RabbitMQ** | **Routing flexible** (exchanges direct/topic/fanout/headers), prioridades, RPC sobre mensajería | Menor throughput, sin replay nativo |
| **NATS (JetStream)** | **Latencia mínima** y simplicidad operativa; persistencia opcional con JetStream | Ecosistema más chico |
| **SQS/SNS** | **Cero-ops** en AWS, serverless-friendly, DLQ nativa, SNS→SQS fan-out | Sin replay arbitrario, costo por mensaje, atado a AWS |

> ¿replay? → Kafka · ¿routing complejo? → RabbitMQ · ¿latencia/simplicidad? → NATS · ¿cero-ops AWS? → SQS/SNS.
> Y SIEMPRE: el delivery es at-least-once → consumidores **idempotentes** + **DLQ** en todos.

## Serialización

`avro` (Kafka, evolución frecuente, registry) · `protobuf` (contratos estrictos, gRPC, polyglot) ·
`json-schema` (default pragmático, debug fácil) · `json` (solo prototipos, NO prod).

El **schema registry** gobierna la evolución: con `BACKWARD` (default) podés agregar campos opcionales pero
NO remover/renombrar campos requeridos ni cambiar tipos. Un breaking change de esquema sin pasar por la
compatibilidad rompe a TODOS los consumers.

## Garantías mínimas (CASTLE A)

idempotencia del consumer (dedup por idempotency key) · DLQ por topic · retry con backoff · ACK después de
procesar · observabilidad de lag. Detalle de brokers, exactly-once y anti-patrones en
`knowledge/domain/distributed-systems.md`; Inbox/Outbox e idempotencia del consumidor en
`knowledge/domain/saga-patterns.md`.
