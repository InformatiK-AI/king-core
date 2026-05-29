---
name: event-broker-setup
version: 2.0
api_version: 1.0.0
description: "Configura un message broker (Kafka/RabbitMQ/NATS/SQS) end-to-end: topics/queues, producers con serialización (Avro/Protobuf/JSON Schema), consumers con retry + dead-letter queue + idempotency key, schema registry, observabilidad de lag y consumer-group health, y tests con testcontainers. Genera un docker-compose válido para local. Usar cuando se necesite: configurar un broker, mensajería async, eventos, pub/sub, Kafka, RabbitMQ, NATS, SQS, productor/consumidor, dead-letter queue, schema registry o desacoplar servicios con mensajes. Alimenta CASTLE A (Architecture) y L (Logging)."
---

# /event-broker-setup — Message Broker End-to-End (producers, consumers, DLQ, schema registry, observabilidad)

Configura un **message broker** (Kafka, RabbitMQ, NATS/JetStream o SQS/SNS) de punta a punta: crea los
**topics/queues**, genera **producers** con serialización tipada (Avro / Protobuf / JSON Schema),
**consumers** con **retry + backoff**, **dead-letter queue** y **idempotency key**, registra los esquemas
en un **schema registry** (cuando aplica), instrumenta **observabilidad de lag** y salud del consumer
group, y produce **tests con testcontainers** (o broker embebido). Todo queda corriendo en un
**`docker-compose` válido para local**, con la guía de IaC equivalente para prod.

> **El delivery es at-least-once, SIEMPRE.** Ningún broker garantiza exactly-once end-to-end por sí solo
> (ver `knowledge/domain/distributed-systems.md` §5 y §7). Por eso este skill NO genera un consumer sin
> **idempotency key** ni un broker sin **DLQ**: un mensaje envenenado sin DLQ bloquea la partición/cola
> para siempre, y un consumer no idempotente duplica efectos en cada redelivery. Estas dos garantías NO
> son opcionales — son la línea base que CASTLE A vigila.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Lenguaje, framework y cliente de broker del proyecto — fuente de los SDKs de producer/consumer y del runner de tests | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de topics/queues, paquetes y rutas de output | No | project |
| `knowledge/domain/distributed-systems.md` | Comparativa de brokers (§5), criterios de elección, exactly-once (§7) y anti-patrones (custom: este skill aplica la matriz de brokers y la regla "at-least-once → idempotencia + DLQ") | Yes | framework |
| `knowledge/domain/saga-patterns.md` | Inbox/Outbox e idempotencia del consumidor (custom: la idempotency key del consumer se apoya en el Inbox pattern) | No | framework |
| `knowledge/_inject/observability-essentials.md` | Métricas y health checks que informan la observabilidad de lag y consumer-group health | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `--broker` ni hay contexto suficiente para auto-recomendar uno (no se puede inferir)
- [ ] No se provee `--topics` (lista de topics/queues a crear) ni se puede derivar de los eventos del dominio
- [ ] El `--broker` pedido es desconocido (no es `kafka` | `rabbitmq` | `nats` | `sqs`)
- [ ] Se pidió serialización `avro`/`protobuf` pero no se provee ni se puede inferir un esquema para los mensajes

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA generar un consumer sin **idempotency key** — el delivery es at-least-once; un consumer no idempotente duplica efectos en cada redelivery
- NUNCA configurar un topic/queue sin su **dead-letter queue** + política de reintentos — un mensaje envenenado sin DLQ bloquea la partición/cola para siempre
- NUNCA promover un `breaking change` de esquema sin pasar por la compatibilidad del schema registry (BACKWARD por defecto) — romper el contrato del evento rompe a TODOS los consumers
- NUNCA degradar la entrega a "exactly-once" en la doc/output sin que TODA la cadena lo soporte (producer idempotente + broker + sink transaccional o idempotente) — un eslabón at-least-once degrada todo
- NUNCA incluir credenciales, connection strings, brokers URLs ni claves de AWS literales en el código, los tests o el `docker-compose` — usar variables de entorno / `{{SLOT}}`
- NUNCA hardcodear puertos del broker, del schema registry ni del consumer en el `docker-compose` — usar `{{SLOT}}` con default documentado
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Topics/queues creados (config declarativa: particiones/replicación en Kafka, exchanges/bindings en RabbitMQ, streams/subjects en NATS, queues+DLQ en SQS)
- [ ] Producer(s) con serialización tipada (Avro / Protobuf / JSON Schema) — sin secretos hardcodeados
- [ ] Consumer(s) con retry + backoff, dead-letter queue e idempotency key (dedup)
- [ ] Schema registry configurado y esquemas registrados (si serialización Avro/Protobuf, o JSON Schema con registry)
- [ ] Observabilidad: métricas de consumer lag + health del consumer group + alerta de lag creciente
- [ ] Tests con testcontainers (o broker embebido): producer→consumer, redelivery→DLQ, idempotencia (mismo mensaje 2× = 1 efecto)
- [ ] `docker-compose.yml` válido para local (broker + schema registry + UI/observabilidad opcional)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase N+1 → Phase N+2
(Context)(Select   (Provision(Schema   (Producer)(Consumer (Observa- (Tests +  (Session)  (Guide)
          broker +  topics/   registry)           retry +   bility    docker-
          serializ) queues)                       DLQ +     lag)      compose)
                                                   idemp)
```
> El broker se resuelve en Phase 1 (explícito vía `--broker` o auto-recomendado con la matriz de `distributed-systems.md`). Phase 3 (schema registry) se SALTA si la serialización es JSON sin registry.

### PARÁMETROS
```
/event-broker-setup --broker <kafka|rabbitmq|nats|sqs> --topics <t1,t2,...> [--serialization avro|protobuf|json-schema|json] [--group <consumer-group>] [--dlq-max-retries <n>] [--idempotency-key <field>]
```
- `--broker`: broker a configurar (`kafka` | `rabbitmq` | `nats` | `sqs`). Si se omite, el skill **auto-recomienda** según el contexto usando la matriz de `distributed-systems.md` (replay→Kafka, routing→RabbitMQ, latencia→NATS, cero-ops AWS→SQS)
- `--topics`: lista separada por comas de topics/queues a crear, con su producer/consumer. En SQS son colas; en RabbitMQ pueden incluir exchange (`orders:topic`); en NATS subjects (`orders.created`)
- `--serialization`: formato de serialización del payload (`avro` | `protobuf` | `json-schema` | `json`). Default: `json-schema` (validable sin registry pesado). `avro`/`protobuf` activan el schema registry (Phase 3)
- `--group`: consumer group/queue group. Default: derivado del nombre del servicio
- `--dlq-max-retries`: reintentos antes de enviar a la DLQ. Default: `3` (con backoff exponencial)
- `--idempotency-key`: campo del mensaje usado como clave de deduplicación. Default: `messageId` (o header `Idempotency-Key`)

---

## CASTLE activo: _-A-_-T-L-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) es la capa central: valida que el componente distribuido tenga las garantías
> mínimas (idempotencia + DLQ + health checks; ver `distributed-systems.md` → "Integración con CASTLE A").
> CASTLE T cubre los tests con testcontainers (incluido el test de idempotencia y el de redelivery→DLQ).
> CASTLE L cubre la observabilidad de lag y consumer-group health. Veredicto BREACHED si se genera un
> consumer sin idempotency key, un topic sin DLQ, o un breaking change de esquema sin compatibilidad.

## Agentes
- **@architect** — Agente principal: recomienda el broker según los criterios de `distributed-systems.md`, valida las garantías mínimas (idempotencia, DLQ, ordering) y la estrategia de compatibilidad del schema registry
- **@developer** — Genera los producers, consumers, la config del broker, el schema registry y el `docker-compose` en el stack del proyecto
- **@qa** — Valida que el test de idempotencia (mismo mensaje 2× = 1 efecto) y el de redelivery→DLQ efectivamente fallen sin las garantías
- **@performance** — (opcional) Revisa el particionado/ordering y la observabilidad de lag para que no haya consumer rezagado silencioso

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Select Broker + Serialization

### GATE IN
- [ ] Se recibió `--broker` o hay contexto para auto-recomendar (BLOCKING CONDITION ya validó esto)
- [ ] Se recibió `--topics` o se pueden derivar los eventos del dominio

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver el broker** — usar `--broker` si se pasó; si no, **auto-recomendar** con la matriz de `distributed-systems.md` §5: ¿replay/throughput? → Kafka; ¿routing complejo? → RabbitMQ; ¿latencia mínima/simplicidad? → NATS; ¿cero-ops en AWS? → SQS/SNS. Justificar la elección con su sección "cuándo preferirlo"
2. [ ] **Resolver la serialización** — `--serialization` o default `json-schema`. Si es `avro`/`protobuf`, marcar `SCHEMA_REGISTRY = true` (Phase 3 activa)
3. [ ] **Parsear `--topics`** — normalizar cada topic/queue a la nomenclatura del broker (Kafka: topic + particiones; RabbitMQ: exchange+queue+routing-key; NATS: subject/stream; SQS: queue + DLQ asociada)
4. [ ] **Resolver el cliente del stack** — desde `.king/knowledge/stack.md`, mapear al SDK de cliente del broker (ej. `kafkajs`/`confluent-kafka`/`sarama`/`spring-kafka`; `amqplib`/`pika`; `nats.js`/`nats.go`; `aws-sdk` SQS)
5. [ ] **Resolver garantías** — `--group`, `--dlq-max-retries` (default 3), `--idempotency-key` (default `messageId`). Determinar la garantía de ordering del broker elegido (Kafka: por partición; RabbitMQ: por queue; NATS: por subject; SQS: FIFO solo en colas FIFO)

### CHECKPOINT
- [ ] `BROKER` resuelto (uno de los 4) con justificación de "cuándo preferirlo"
- [ ] `SERIALIZATION` resuelto; `SCHEMA_REGISTRY` (bool) definido
- [ ] `TOPICS[]` normalizados a la nomenclatura del broker
- [ ] `CLIENT_SDK` resuelto desde el stack (o WARN si ambiguo)
- [ ] `CONSUMER_GROUP`, `DLQ_MAX_RETRIES`, `IDEMPOTENCY_KEY` resueltos

### OUTPUTS
- Variables: `BROKER`, `SERIALIZATION`, `SCHEMA_REGISTRY`, `TOPICS[]`, `CLIENT_SDK`, `CONSUMER_GROUP`, `DLQ_MAX_RETRIES`, `IDEMPOTENCY_KEY`, `ORDERING_GUARANTEE`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el broker o la serialización.
Cause: `--broker` ausente y contexto insuficiente para recomendar, o stack sin cliente de broker resoluble.
Recovery:
  [ ] Option A: presentar la matriz de decisión de `distributed-systems.md` §5 y pedir al usuario que elija (replay→Kafka, routing→RabbitMQ, latencia→NATS, cero-ops AWS→SQS)
  [ ] Option B: si el stack no declara cliente, asumir el SDK más común del lenguaje (ej. `kafkajs` en Node) con WARN y continuar
  [ ] Option C: si no hay topics, derivarlos de los eventos del dominio descritos por el usuario; si no hay forma, abortar (BLOCKING CONDITION)

---

## Phase 2: Provision Topics / Queues

### GATE IN
- [ ] `BROKER` y `TOPICS[]` resueltos (Phase 1)

### MUST DO
1. [ ] **Generar la config declarativa de cada topic/queue** según el broker:
   - **Kafka**: topic con `partitions` (default 3) y `replication.factor` (1 en local, ≥3 en prod), `cleanup.policy` (`delete` o `compact` para event sourcing)
   - **RabbitMQ**: `exchange` (topic/direct/fanout según routing) + `queue` + `binding` (routing key)
   - **NATS**: `stream` (JetStream, con retention/storage) + `subject(s)` con wildcards si aplica
   - **SQS**: `queue` estándar o FIFO + su `redrive policy` apuntando a la DLQ
2. [ ] **Crear la DLQ asociada a CADA topic/queue** — `<topic>.DLQ` (Kafka), DLX+dead-letter-queue (RabbitMQ), stream DLQ (NATS), `<queue>-dlq` con `maxReceiveCount = DLQ_MAX_RETRIES` (SQS)
3. [ ] **Definir el ordering** — clave de partición (Kafka), una queue por consumer afín (RabbitMQ), subject por entidad (NATS), FIFO + `MessageGroupId` (SQS FIFO) — documentar la garantía resultante
4. [ ] **Aplicar convenciones** de naming de `.king/knowledge/conventions.md` si existe

### CHECKPOINT
- [ ] 1 config declarativa por cada topic/queue de `TOPICS[]`
- [ ] CADA topic/queue tiene su DLQ asociada (sin DLQ = BREACH)
- [ ] Ordering documentado por topic (partición/queue/subject/FIFO group)
- [ ] Replicación/persistencia configurada (local vs prod diferenciados)

### OUTPUTS
- Archivos: config declarativa de topics/queues + DLQs (en el formato del broker)
- Variables: `TOPIC_CONFIGS[]`, `DLQ_CONFIGS[]`

### IF FAILS
ERROR: No se pudieron provisionar los topics/queues.
Cause: nomenclatura del broker no resuelta, o falta el routing (RabbitMQ exchange) / partition key (Kafka).
Recovery:
  [ ] Option A: para RabbitMQ, pedir el tipo de exchange y la routing key; para Kafka, pedir la partition key del evento
  [ ] Option B: usar defaults seguros (Kafka 3 particiones / RF 1 local; RabbitMQ topic exchange; SQS estándar) con WARN y continuar
  [ ] Option C: generar la config de los topics que sí se resolvieron y marcar los demás como PARTIAL

---

## Phase 3: Schema Registry

### GATE IN
- [ ] `SCHEMA_REGISTRY = true` (serialización `avro`/`protobuf`, o `json-schema` con registry) — si no, SALTAR esta fase en silencio
- [ ] `TOPICS[]` provisionados (Phase 2)

### MUST DO
1. [ ] **Definir el esquema de cada mensaje** — `.avsc` (Avro), `.proto` (Protobuf) o JSON Schema, derivado del evento del dominio. Incluir el `IDEMPOTENCY_KEY` como campo del esquema
2. [ ] **Configurar el schema registry** — Confluent Schema Registry (Kafka), Apicurio (Kafka/genérico), o el registry del broker. Añadirlo como servicio del `docker-compose` (Phase 7) con puerto `{{SCHEMA_REGISTRY_PORT}}`
3. [ ] **Registrar cada esquema** bajo el subject `<topic>-value` (y `<topic>-key` si la key es estructurada)
4. [ ] **Fijar la política de compatibilidad** — `BACKWARD` por defecto (los consumers nuevos leen mensajes viejos): permite agregar campos opcionales, prohíbe remover campos requeridos. Documentar qué cambios son breaking
5. [ ] **Wirear producer/consumer al registry** — el producer serializa contra el esquema registrado; el consumer deserializa resolviendo el `schema id` embebido en el mensaje

### CHECKPOINT
- [ ] 1 esquema por tipo de mensaje, registrado bajo su subject
- [ ] Política de compatibilidad fijada (BACKWARD por defecto) y documentada
- [ ] Producer y consumer wireados al registry (serializan/deserializan contra el esquema)
- [ ] Cambios breaking de esquema documentados (remover/renombrar campo requerido, cambiar tipo)

### OUTPUTS
- Archivos: esquemas (`.avsc`/`.proto`/`.json`) + config del schema registry
- Variables: `SCHEMA_SUBJECTS[]`, `COMPAT_MODE`

### IF FAILS
ERROR: No se pudo configurar el schema registry.
Cause: registry ausente, esquema inválido, o serialización sin esquema derivable.
Recovery:
  [ ] Option A: documentar el levantado del registry (Confluent/Apicurio en docker-compose) y registrar el esquema apenas esté arriba
  [ ] Option B: si el esquema no es derivable, generar un esquema mínimo desde un mensaje de ejemplo y marcarlo para revisión
  [ ] Option C: degradar a `json-schema` SIN registry (validación en el cliente) y notar la pérdida de gobernanza de esquemas

---

## Phase 4: Producer (serialización)

### GATE IN
- [ ] `BROKER`, `SERIALIZATION` y `TOPICS[]` resueltos
- [ ] Si `SCHEMA_REGISTRY`: esquemas registrados (Phase 3)

### MUST DO
1. [ ] **Generar el producer** por topic con el `CLIENT_SDK` del stack — conexión configurable por variable de entorno (broker URL, credenciales), nunca hardcodeada
2. [ ] **Serializar el payload** con `SERIALIZATION` — Avro/Protobuf contra el schema registry, o JSON Schema validado antes de publicar. Incluir el `IDEMPOTENCY_KEY` en cada mensaje (campo o header)
3. [ ] **Habilitar idempotencia del producer** cuando el broker lo soporte (Kafka: `enable.idempotence=true` + `acks=all`; SQS FIFO: `MessageDeduplicationId`) para deduplicar reenvíos del productor
4. [ ] **Setear la partition/routing key** — derivada de la entidad (ej. `orderId`) para preservar ordering por entidad
5. [ ] **Manejar errores de publicación** — retry con backoff en fallo de conexión; nunca tragar el error en silencio (logear + métrica)

### CHECKPOINT
- [ ] 1 producer por topic, con conexión configurable por env (sin secretos literales)
- [ ] Payload serializado con `SERIALIZATION` (validado contra esquema si aplica)
- [ ] `IDEMPOTENCY_KEY` presente en cada mensaje
- [ ] Idempotencia del producer habilitada donde el broker lo permita
- [ ] Partition/routing key seteada para ordering por entidad

### OUTPUTS
- Archivos: producer(s) por topic con serialización
- Variables: `PRODUCERS[]`

### IF FAILS
ERROR: No se pudo generar el producer.
Cause: SDK del broker no resuelto, o serializador del esquema no disponible.
Recovery:
  [ ] Option A: usar el SDK más común del lenguaje y documentar su instalación
  [ ] Option B: si el serializador Avro/Protobuf falta, degradar a JSON Schema validado en el cliente con WARN
  [ ] Option C: generar el producer de los topics resueltos y marcar los demás como PARTIAL

---

## Phase 5: Consumer (retry + DLQ + idempotency)

### GATE IN
- [ ] Producer(s) generados (Phase 4)
- [ ] DLQs provisionadas (Phase 2)

### MUST DO
1. [ ] **Generar el consumer** por topic en el `CONSUMER_GROUP`, deserializando el payload (resolviendo el `schema id` si hay registry)
2. [ ] **Implementar idempotencia (dedup)** — antes de procesar, chequear el `IDEMPOTENCY_KEY` contra un store de dedup (Inbox pattern, ver `saga-patterns.md`): si ya fue procesado, ACK sin reprocesar; el efecto se aplica UNA sola vez
3. [ ] **Implementar retry con backoff** — ante error transitorio, reintentar hasta `DLQ_MAX_RETRIES` con backoff exponencial (+ jitter). Distinguir error transitorio (reintentar) de error de negocio/envenenado (a DLQ directo)
4. [ ] **Enviar a la DLQ** — tras agotar reintentos, publicar el mensaje en su DLQ con metadata (causa del fallo, intentos, timestamp, stack) para diagnóstico, y ACK del original
5. [ ] **Commit/ACK del offset DESPUÉS de procesar** (no antes) — para no perder mensajes ante caída del consumer (at-least-once correcto)
6. [ ] **Manejar el orden de commit** — manual ACK tras procesamiento + dedup, nunca auto-commit ciego que pierda mensajes

### CHECKPOINT
- [ ] 1 consumer por topic en `CONSUMER_GROUP`, deserializando correctamente
- [ ] Idempotencia (dedup por `IDEMPOTENCY_KEY`) implementada — mismo mensaje 2× = 1 efecto
- [ ] Retry con backoff hasta `DLQ_MAX_RETRIES`; mensaje envenenado va a la DLQ con metadata
- [ ] ACK/commit DESPUÉS de procesar (no antes)
- [ ] Ningún consumer sin idempotency key (sin esto = BREACH)

### OUTPUTS
- Archivos: consumer(s) con retry + DLQ + idempotencia + store de dedup
- Variables: `CONSUMERS[]`, `DEDUP_STORE`

### IF FAILS
ERROR: No se pudo generar el consumer con las garantías mínimas.
Cause: no hay store de dedup disponible, o el SDK no expone control manual de ACK/offset.
Recovery:
  [ ] Option A: usar un store de dedup simple (tabla con unique constraint sobre `IDEMPOTENCY_KEY` + TTL, o Redis SETNX) — ver Inbox en `saga-patterns.md`
  [ ] Option B: si el SDK solo soporta auto-commit, configurar el intervalo mínimo y documentar el riesgo de redelivery (la idempotencia lo cubre)
  [ ] Option C: si no se puede garantizar idempotencia, NO generar el consumer — abortar y pedir un store de dedup (ABSOLUTE RESTRICTION)

---

## Phase 6: Observability (lag)

### GATE IN
- [ ] Consumer(s) generados (Phase 5)

### MUST DO
1. [ ] **Exponer métricas de consumer lag** — diferencia entre el último offset producido y el consumido por partición/queue (Kafka: lag por partición; RabbitMQ: `messages_ready`/`messages_unacknowledged`; NATS: pending/consumer info; SQS: `ApproximateNumberOfMessagesVisible` + `ApproximateAgeOfOldestMessage`)
2. [ ] **Exponer health del consumer group** — miembros activos, rebalances, particiones sin asignar, consumer rezagado
3. [ ] **Métricas de la DLQ** — tamaño de la DLQ y tasa de entrada (una DLQ que crece = bug en el consumer o mensajes envenenados sistemáticos)
4. [ ] **Definir alerta de lag creciente** — umbral y ventana (ej. lag > N y creciendo M min) → alerta; documentar el runbook básico
5. [ ] **Exportar a un sink** — Prometheus/OpenTelemetry (o el stack de observabilidad del proyecto, ver `observability-essentials.md`); en el `docker-compose` local, opcionalmente una UI (Kafka UI / RabbitMQ Management / NATS surveyor)

### CHECKPOINT
- [ ] Métrica de consumer lag expuesta por partición/queue
- [ ] Health del consumer group expuesto (miembros, rebalances)
- [ ] Métrica de tamaño/tasa de la DLQ expuesta
- [ ] Alerta de lag creciente definida con umbral + runbook
- [ ] Métricas exportadas a un sink (o UI local en el compose)

### OUTPUTS
- Archivos: config de métricas/exporters + (opcional) servicio de UI en el compose
- Variables: `LAG_METRICS`, `ALERT_THRESHOLDS`

### IF FAILS
ERROR: No se pudo instrumentar la observabilidad de lag.
Cause: el broker no expone la métrica nativamente, o no hay sink de métricas resoluble.
Recovery:
  [ ] Option A: usar el exporter estándar del broker (kafka-lag-exporter / rabbitmq_prometheus / nats-exporter / CloudWatch SQS)
  [ ] Option B: si no hay sink, exponer las métricas en un endpoint `/metrics` y documentar el scrape pendiente
  [ ] Option C: como mínimo, logear el lag periódicamente y la UI local del compose; marcar la observabilidad como PARTIAL

---

## Phase 7: Tests + docker-compose

### GATE IN
- [ ] Producer(s) y consumer(s) generados (Phases 4–5)
- [ ] Topics/queues + DLQ provisionados (Phase 2)

### MUST DO
1. [ ] **Generar el `docker-compose.yml` local válido** — servicio del broker + (si aplica) schema registry + (opcional) UI/observabilidad. Puertos vía `{{SLOT}}` (`{{BROKER_PORT}}`, `{{SCHEMA_REGISTRY_PORT}}`), credenciales vía `env_file`, NADA hardcodeado. Healthchecks de cada servicio
2. [ ] **Generar tests con testcontainers** (o broker embebido si testcontainers no aplica al stack):
   - **producer→consumer**: publicar un mensaje y verificar que el consumer lo procesa con el payload deserializado correcto
   - **redelivery→DLQ**: forzar un fallo persistente y verificar que tras `DLQ_MAX_RETRIES` el mensaje termina en la DLQ con su metadata
   - **idempotencia**: entregar el MISMO mensaje 2× (mismo `IDEMPOTENCY_KEY`) y verificar UN solo efecto (1 registro en DB / 1 efecto observable)
   - **(si registry)** compatibilidad: un esquema con un cambio BACKWARD-compatible pasa; uno breaking falla
3. [ ] **Garantizar que los tests FALLAN sin las garantías** — el test de idempotencia debe romperse si se quita el dedup; el de DLQ si se quita la DLQ. @qa valida la orientación
4. [ ] **Documentar el arranque** — `docker compose up` para el broker + registry, y el comando del runner de tests del proyecto

### CHECKPOINT
- [ ] `docker-compose.yml` válido (broker + registry si aplica), puertos por `{{SLOT}}`, sin secretos, con healthchecks
- [ ] Tests con testcontainers: producer→consumer, redelivery→DLQ, idempotencia (y compatibilidad si registry)
- [ ] El test de idempotencia FALLA si se remueve el dedup; el de DLQ FALLA sin DLQ (orientación correcta)
- [ ] Comando de arranque del compose y del runner de tests documentados

### OUTPUTS
- Archivos: `docker-compose.yml` + suite de tests con testcontainers
- Variables: `COMPOSE_PATH`, `TEST_SUITE`

### IF FAILS
ERROR: No se pudo generar los tests o el docker-compose.
Cause: testcontainers no disponible para el stack, o conflicto de puertos/servicios en un compose existente.
Recovery:
  [ ] Option A: si ya existe `docker-compose.yml`, AÑADIR los servicios (broker/registry) sin remover los existentes; resolver puertos vía `{{SLOT}}`
  [ ] Option B: si testcontainers no aplica al lenguaje, usar un broker embebido o un mock broker para los tests y documentarlo
  [ ] Option C: generar el subset crítico de tests (idempotencia + DLQ) y marcar el resto como PARTIAL

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Topics/queues creados, CADA uno con su DLQ
  - [ ] Producer(s) con serialización tipada e `IDEMPOTENCY_KEY` en cada mensaje
  - [ ] Consumer(s) con retry + backoff, DLQ e idempotencia (dedup)
  - [ ] Schema registry + esquemas registrados con compatibilidad (si Avro/Protobuf)
  - [ ] Observabilidad: lag + consumer-group health + alerta + métrica de DLQ
  - [ ] Tests con testcontainers: producer→consumer, redelivery→DLQ, idempotencia
  - [ ] `docker-compose.yml` válido para local
- [ ] Ningún consumer sin idempotency key (ABSOLUTE RESTRICTION)
- [ ] Ningún topic/queue sin DLQ (ABSOLUTE RESTRICTION)
- [ ] Ningún breaking change de esquema sin pasar por la compatibilidad del registry
- [ ] No se declaró "exactly-once" sin que toda la cadena lo soporte
- [ ] Ningún secreto / connection string / broker URL / clave AWS literal en código, tests o compose
- [ ] Ningún puerto / ruta absoluta / nombre de proyecto hardcodeado (todo vía `{{SLOT}}`)
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(broker con idempotencia + DLQ + observabilidad + tests = FORTIFIED; observabilidad PARTIAL o sin schema registry donde convendría = CONDITIONAL; consumer sin idempotency key, topic sin DLQ o breaking change de esquema sin compatibilidad = BREACHED)_ |
| Artifacts | _(config de topics/queues+DLQ; producers; consumers; esquemas+registry si aplica; config de observabilidad; tests testcontainers; docker-compose.yml)_ |
| Next Recommended | `/idempotency` (reforzar dedup en endpoints/handlers), `/contract-test-pact` (contrato de eventos entre servicios), o `/build` (integrar producers/consumers en la app) |
| Risks | _(observabilidad PARTIAL; testcontainers no disponible; ordering no garantizado para el caso de uso; DLQ creciendo = bug; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Consumer generado, falta reforzar idempotencia en endpoints HTTP | `/idempotency` — idempotency keys en handlers (request-hash / header) |
| Eventos cruzan límites de servicio (microservicios) | `/contract-test-pact` — contrato de eventos productor/consumidor |
| Producers/consumers listos, falta integrarlos en la app | `/build` — wirear los producers/consumers en los casos de uso |
| Patrón de coordinación de estado entre servicios (saga) | revisar `knowledge/domain/saga-patterns.md` (Outbox/Inbox/saga) |
| DLQ creciendo en observabilidad | `/fix` — investigar el mensaje envenenado o el bug del consumer |
| Broker auto-recomendado, dudas sobre la elección | revisar `knowledge/domain/distributed-systems.md` §5 y re-`/event-broker-setup --broker <otro>` |
| Todo configurado y testeado | continuar; el arch-check de "broker con garantías mínimas" lo vigila CASTLE A en `/review` |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Comparativa de brokers — cuándo preferir cada uno

> Resumen accionable de `knowledge/domain/distributed-systems.md` §5. La elección NO es de gusto:
> depende de throughput, routing, latencia y si querés managed.

| Broker | Modelo | Cuándo preferirlo | Costo / límite |
|--------|--------|-------------------|----------------|
| **Kafka** | Log distribuido particionado | Necesitás **retención y replay** (event sourcing, reprocesar con lógica nueva), **alto throughput** sostenido, o varios consumer groups leyendo el MISMO stream a distinto ritmo | Operación pesada (KRaft), overkill para colas de tareas simples |
| **RabbitMQ** | Broker con exchanges/queues | Necesitás **routing flexible** (por tipo/atributos vía exchanges), colas de trabajo con prioridades, RPC sobre mensajería, o enrutamiento complejo sin lógica en el consumer | Menor throughput, sin replay nativo |
| **NATS (JetStream)** | Pub/sub + streaming opcional | Priorizás **latencia mínima** y simplicidad operativa (request/reply, pub/sub interno); JetStream agrega persistencia cuando hace falta | Ecosistema más chico que Kafka/RabbitMQ |
| **SQS/SNS** | Cola managed (SQS) + fan-out (SNS) | Estás en **AWS** y querés **cero operación** (serverless-friendly, desacople con Lambda); SNS→SQS para fan-out durable; DLQ nativas | Sin replay arbitrario, costo por mensaje, atado a AWS |

> **Regla**: ¿replay? → Kafka (o JetStream). ¿routing complejo? → RabbitMQ. ¿latencia/simplicidad? → NATS.
> ¿cero-ops en AWS? → SQS/SNS. Y SIEMPRE: como el delivery es at-least-once, consumidores idempotentes + DLQ.

### Serialización — Avro vs Protobuf vs JSON Schema

| Formato | Tamaño / velocidad | Schema registry | Cuándo |
|---------|--------------------|-----------------|--------|
| **Avro** | Compacto (binario), schema-on-read | Sí (Confluent/Apicurio) | Kafka + evolución de esquemas frecuente; el estándar de facto en Kafka |
| **Protobuf** | Muy compacto, rápido, tipado fuerte | Sí (o `.proto` versionado) | Contratos estrictos, gRPC en el mismo ecosistema, polyglot |
| **JSON Schema** | Legible, mayor tamaño | Opcional (registry o validación en cliente) | Default pragmático; debug fácil; sin infra de registry pesada |
| **JSON** (sin schema) | Legible, sin validación | No | Solo prototipos; NO recomendado en prod (contrato implícito = frágil) |

> El registry **gobierna la evolución**: con `BACKWARD` (default) podés agregar campos opcionales pero NO
> remover/renombrar campos requeridos ni cambiar tipos sin romper consumers. Un breaking change de esquema
> sin pasar por la compatibilidad rompe a TODOS los consumers — por eso es una ABSOLUTE RESTRICTION.

### Garantías mínimas (lo que CASTLE A vigila)

| Garantía | Por qué es obligatoria | Mecanismo |
|----------|------------------------|-----------|
| **Idempotencia del consumer** | Delivery at-least-once → el mismo mensaje llega ≥1 vez | Dedup por `IDEMPOTENCY_KEY` (Inbox pattern, `saga-patterns.md`) |
| **Dead-letter queue** | Un mensaje envenenado sin DLQ bloquea la partición/cola para siempre | DLQ por topic + `maxReceiveCount`/`DLQ_MAX_RETRIES` |
| **Retry con backoff** | Errores transitorios no deben ir a DLQ al primer fallo | Backoff exponencial + jitter, distinguiendo transitorio de envenenado |
| **ACK después de procesar** | ACK antes = se pierden mensajes si el consumer cae | Commit/ACK manual post-procesamiento |
| **Observabilidad de lag** | Un consumer rezagado silencioso = backlog invisible | Métrica de lag por partición + alerta + health del group |

### Exactly-once — la verdad incómoda

"Exactly-once" NO significa que el mensaje viaje una sola vez (imposible en red): significa que el
**efecto** se aplica una sola vez. Exige que **toda la cadena** lo soporte (producer idempotente + broker +
processor + sink transaccional o idempotente). Un eslabón at-least-once degrada todo a at-least-once →
volvés a necesitar idempotencia en el consumidor. NO declares "exactly-once" si tu sink es un `INSERT` no
idempotente. Detalle en `knowledge/domain/distributed-systems.md` §7.

### Ejemplo de docker-compose local (Kafka + Schema Registry)

> Puertos vía `{{SLOT}}` (resueltos en Phase 0), credenciales vía `env_file`. Ningún valor sensible literal.

```yaml
services:
  kafka:
    image: confluentinc/cp-kafka:7.6.0
    ports: ["${KAFKA_PORT:-9092}:9092"]
    environment:
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    healthcheck:
      test: ["CMD", "kafka-topics", "--bootstrap-server", "localhost:9092", "--list"]
      interval: 10s
      timeout: 5s
      retries: 5
  schema-registry:
    image: confluentinc/cp-schema-registry:7.6.0
    depends_on: [kafka]
    ports: ["${SCHEMA_REGISTRY_PORT:-8081}:8081"]
    environment:
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka:9092
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    depends_on: [kafka, schema-registry]
    ports: ["${KAFKA_UI_PORT:-8080}:8080"]
```

### Relación con otros skills del arco M04

`/event-broker-setup` materializa la mensajería async (CASTLE A). Se complementa con `/idempotency` (M-33,
idempotency keys en endpoints HTTP), `/microservice-extract` (M-31, contrato de eventos al extraer un
bounded context), `/contract-test-pact` (contrato productor/consumidor de eventos) y la guía
`knowledge/domain/saga-patterns.md` (Outbox/Inbox para publicar/consumir eventos de forma transaccional).
El delta spec está en `openspec/changes/m04-architecture/specs/distributed-systems/spec.md`.

### Integración con CASTLE A (Architecture)

`agents/architect.md` y la capa CASTLE A tratan un componente de mensajería **sin garantías mínimas** como
WARNING/BREACH (ver `distributed-systems.md` → "Integración con CASTLE A"). Señales que vigila:
- Consumidor de broker sin idempotencia/dedup o sin DLQ configurada → BREACH.
- Pipeline que promete "exactly-once" con un sink no transaccional ni idempotente → WARNING.
- Producer/consumer con connection string o credenciales literales → BREACH (también CASTLE S si existiera el gate).
- Topic/queue sin DLQ → BREACH. DLQ que crece sin observabilidad → WARNING (consumer con bug oculto).
