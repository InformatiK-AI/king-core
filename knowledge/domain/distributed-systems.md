# Distributed Systems — Guía de Fundamentos y Componentes

> Versión completa. Para inyección en agents usar `knowledge/_inject/distributed-systems.md`.
>
> Un sistema distribuido es un conjunto de procesos que se coordinan a través de una
> red NO confiable: los mensajes se pierden, se duplican, se reordenan y llegan tarde.
> No hay reloj global ni memoria compartida. Esta guía cubre los fundamentos
> (CAP/PACELC, consenso) y los componentes operativos (discovery, balanceo, brokers,
> caching, streaming, service mesh) con criterios concretos de elección.

**Falacia raíz de los sistemas distribuidos**: asumir que "la red es confiable". NO lo
es. Toda decisión de diseño aquí parte de aceptar que la partición de red es inevitable,
no excepcional. Si tu diseño se rompe cuando un nodo no responde, no es un sistema
distribuido — es un monolito desplegado en varias máquinas.

---

## Mapa de Decisión Rápida

```
¿Necesitás coordinar estado entre procesos a través de red?
  └─ NO  → No es un problema distribuido. ACID local. Salí de acá.
  └─ SÍ  → ¿Tolerás ver datos viejos por unos ms durante una partición?
            ├─ NO (banco, inventario, locks) → CP. Consensus (Raft/Paxos).
            └─ SÍ (timeline, catálogo, métricas) → AP. Replicación eventual.

¿Cómo se comunican los servicios?
  ├─ Request/response síncrono → load balancer (L4/L7) + service discovery + health checks
  └─ Async / desacoplado       → message broker (elegí por throughput vs routing vs latencia)

¿Demasiada plomería de red en cada servicio (mTLS, retries, tracing)?
  └─ SÍ y tenés Kubernetes → service mesh (Linkerd primero, Istio si necesitás más)
  └─ NO → librería de resiliencia a nivel app. NO metas un mesh por moda.
```

---

## 1. CAP Theorem

Ante una **partición de red** (P), un sistema distribuido debe elegir entre
**Consistencia** (C: toda lectura ve la última escritura) y **Disponibilidad** (A:
toda petición recibe respuesta sin error). NO podés tener las tres. La P no es opcional:
en una red real, las particiones OCURREN. Por tanto la elección real es **CP vs AP**.

| Tipo | Sacrifica | Comportamiento en partición | Ejemplos | Cuándo |
|------|-----------|-----------------------------|----------|--------|
| **CP** | Disponibilidad | Rechaza/bloquea peticiones hasta restaurar consistencia | HBase, ZooKeeper, etcd, Consul, MongoDB (majority) | Locks, config, líderes, saldos, inventario |
| **AP** | Consistencia inmediata | Responde con datos posiblemente viejos; converge después | Cassandra, CouchDB, DynamoDB, Riak | Timelines, carritos, catálogos, telemetría |
| **CA** | — (no tolera P) | Solo válido SIN partición posible = un solo nodo | PostgreSQL single-node, RDBMS clásico | Sistema NO distribuido |

> **Error conceptual común**: "elijo CA". CA NO es una opción real en un sistema
> distribuido. Si hay red entre nodos, hay partición posible → tenés que elegir C o A.
> "CA" solo describe una base de datos de un único nodo (que no es distribuida).

### PACELC — la extensión que SÍ usás a diario

CAP solo habla del caso de partición, que es raro. PACELC completa el cuadro:

> **if Partition → (Availability vs Consistency); Else → (Latency vs Consistency)**

El "Else" es el que vivís el 99.9% del tiempo: incluso SIN partición, replicar de forma
síncrona (consistencia fuerte) cuesta **latencia**. Por eso PACELC es más útil que CAP
para decisiones reales:

| Sistema | PACELC | Lectura |
|---------|--------|---------|
| DynamoDB / Cassandra | **PA/EL** | En partición prioriza disponibilidad; normalmente prioriza latencia |
| MongoDB | **PA/EC** | Disponible en partición; consistente fuera de ella |
| PostgreSQL (sync replica) | **PC/EC** | Prioriza consistencia siempre, paga latencia |
| HBase / etcd | **PC/EC** | Consistencia siempre, sacrifica disponibilidad y latencia |

**Regla práctica**: no preguntes "¿CP o AP?" (solo cubre particiones). Preguntá
"¿estoy dispuesto a pagar latencia por consistencia en operación normal?" — esa es la
decisión de TODOS los días.

---

## 2. Consensus — acordar un valor con nodos que fallan

Consenso = lograr que N nodos acuerden UN valor (quién es líder, cuál es el próximo
log entry) aun si algunos caen. Es la base de todo sistema CP. Requiere **mayoría
(quorum)**: con 2f+1 nodos toleras f fallos. Por eso los clusters CP son impares (3, 5).

### Raft vs Paxos

| | **Raft** | **Paxos (Multi-Paxos)** |
|--|----------|--------------------------|
| Diseño | Entendibilidad explícita | Generalidad teórica |
| Modelo | Líder fuerte + followers; todo pasa por el líder | Roles proposer/acceptor/learner |
| Mecánica | Leader election (term + voto) → log replication → commit por mayoría | Rondas prepare/accept; sin líder obligatorio |
| Curva | Moderada — diseñado para ser implementable | Alta — notoriamente difícil de implementar bien |
| Implementaciones | **etcd**, **Consul**, CockroachDB, TiKV, RethinkDB | **ZooKeeper (ZAB**, variante de Paxos), Google Chubby, Spanner |

**Default King**: si necesitás consenso, NO lo implementes. Usá etcd/Consul (Raft) o
ZooKeeper (ZAB). Escribir un Raft correcto desde cero es un proyecto de meses con bugs
sutiles en edge cases (split-brain, log truncation, membership changes).

### Distributed Locks — el campo minado

Un lock distribuido coordina acceso exclusivo a un recurso entre procesos. Opciones por
solidez:

- **etcd lease**: lock con TTL renovable atado a una sesión. Si el dueño muere, el lease
  expira → lock liberado. Respaldado por Raft. **Recomendado**.
- **ZooKeeper ephemeral + sequential nodes**: el nodo efímero desaparece al caer la
  sesión → liberación automática, sin TTL que adivinar. Patrón clásico y sólido.
- **Consul session lock**: similar, con health checks integrados.
- **Redis SETNX / Redlock**: el más popular y el más **controversial** (ver anti-patrones).

> **Regla**: un lock distribuido SIEMPRE necesita TTL/lease + liberación automática ante
> caída del dueño. Un lock sin expiración es un deadlock esperando a que un proceso muera
> en el peor momento. Y NUNCA confíes en un lock distribuido para *correctness* sin un
> *fencing token* (ver anti-patrones).

---

## 3. Service Discovery

En un sistema dinámico (autoscaling, contenedores efímeros) las direcciones cambian.
Service discovery resuelve "¿dónde está el servicio X ahora?".

| Modelo | Cómo funciona | Tecnologías | Trade-off |
|--------|---------------|-------------|-----------|
| **Client-side** | El cliente consulta el registry y elige instancia | Eureka + Ribbon (Spring Cloud) | Cliente más complejo; menos saltos; balanceo del lado cliente |
| **Server-side** | Un proxy/LB consulta el registry y rutea | Consul + Nginx/HAProxy, AWS ELB | Cliente simple; salto extra; el LB es punto a escalar |
| **DNS-based** | Resolución vía DNS interno | Kubernetes Services (`svc.cluster.local`), Consul DNS | Universal, sin SDK; cache de DNS y TTL son trampas (clientes cachean IPs muertas) |

### Health Checks — OBLIGATORIOS, no opcionales

Sin health checks, el discovery registra **zombies**: instancias muertas a las que sigue
enrutando tráfico → errores en cascada. Tipos:

- **Liveness**: ¿el proceso está vivo? Si falla → reiniciar.
- **Readiness**: ¿está listo para recibir tráfico? (DB conectada, cache caliente, migraciones
  aplicadas). Si falla → sacar del balanceo SIN matar el proceso.
- **Startup**: gracia inicial para apps lentas en arrancar antes de aplicar liveness.

> **Regla**: distinguí liveness de readiness. Confundirlas mata instancias sanas que solo
> están calentando (readiness fallando tratada como liveness → reinicio infinito) o enruta
> tráfico a instancias no listas (liveness OK pero readiness ignorada).

---

## 4. Load Balancing

Distribuye tráfico entre instancias. La decisión clave es **L4 vs L7**.

| | **L4 (Transport / TCP-UDP)** | **L7 (Application / HTTP)** |
|--|-------------------------------|------------------------------|
| Decide por | IP + puerto | Path, header, cookie, método, host |
| Capacidad | Muy alto throughput, baja latencia | Routing inteligente (canary, A/B, path-based), TLS termination |
| Visibilidad | Ciego al contenido | Ve la request completa |
| Ejemplos | AWS NLB, IPVS, HAProxy (TCP mode) | AWS ALB, Nginx, Envoy, Traefik |
| Cuándo | Protocolos no-HTTP, máximo rendimiento, gRPC bruto | Microservicios HTTP, routing por path/header, canary |

### Algoritmos

- **Round-robin**: rota secuencialmente. Default simple; ignora carga real de cada nodo.
- **Weighted round-robin**: pesos por capacidad de instancia (canary: 95/5).
- **Least connections**: al nodo con menos conexiones activas. Mejor con requests de
  duración dispar.
- **Least response time**: combina conexiones activas + latencia observada.
- **Consistent hashing**: misma key → mismo nodo. **Crítico para servicios stateful**
  (sticky sessions, sharding de cache): minimiza el remapeo al agregar/quitar nodos
  (solo K/N keys se mueven, no todas). Es la base de cómo shardea Redis Cluster y cómo
  Cassandra ubica datos en el ring.

> **Regla**: para servicios **stateless** round-robin/least-connections basta. Para
> **stateful** (cache, sesiones afines) usá consistent hashing — un round-robin sobre
> cache distribuida destruye el hit ratio en cada rescale.

---

## 5. Message Brokers

Desacoplan productores de consumidores con comunicación asíncrona. La elección NO es de
gusto: depende de throughput, modelo de routing, latencia y si querés managed.

| | **Kafka** | **RabbitMQ** | **NATS (JetStream)** | **SQS/SNS** |
|--|-----------|--------------|----------------------|-------------|
| Modelo | Log distribuido particionado | Broker con exchanges/queues | Pub/sub + streaming opcional | Cola managed (SQS) + fan-out (SNS) |
| Throughput | Altísimo (M msg/s) | Medio (decenas-cientos K/s) | Muy alto, ultra-baja latencia | Alto, elástico, managed |
| Retención / Replay | **Sí** (retención por tiempo/tamaño; consumers releen offsets) | No nativo (msg se borra al ack) | Sí con JetStream; core NATS es fire-and-forget | Hasta 14 días; sin replay arbitrario |
| Ordering | Por **partición** (key → partición) | Por queue (se rompe con consumers concurrentes) | Por subject/stream | FIFO solo en colas FIFO (menor throughput) |
| Routing | Simple (topic/partición); lógica en el consumer | **Rico**: direct/topic/fanout/headers exchanges | Subjects con wildcards (`a.*.c`) | Básico (SNS fanout a colas/HTTP/Lambda) |
| Entrega | At-least-once (exactly-once con transactions) | At-least-once / at-most-once | At-least-once (JetStream) | At-least-once (exactly-once-ish en FIFO) |
| Operación | Pesada (antes ZooKeeper, ahora KRaft); curva alta | Media | **Mínima** (un binario, sin deps) | **Cero** (managed AWS) |

### Criterios de elección — concretos

- **Elegí Kafka** cuando: necesitás **retención y replay** (event sourcing, reprocesar con
  nueva lógica), **alto throughput** sostenido (ingesta de eventos, logs, métricas), o
  varios consumer groups leyendo el MISMO stream a distinto ritmo. Costo: operación
  compleja, overkill para colas de tareas simples.
- **Elegí RabbitMQ** cuando: necesitás **routing flexible** (enrutar por tipo/atributos vía
  exchanges), colas de trabajo con prioridades, RPC sobre mensajería, o patrones de
  enrutamiento complejos sin escribir lógica en el consumer. Costo: menor throughput, no
  hay replay.
- **Elegí NATS** cuando: priorizás **latencia mínima** y simplicidad operativa para
  comunicación inter-servicio (request/reply, pub/sub interno). JetStream agrega
  persistencia cuando la necesitás. Costo: ecosistema más chico que Kafka/RabbitMQ.
- **Elegí SQS/SNS** cuando: estás en AWS y querés **cero operación** (serverless-friendly,
  desacople con Lambda). SNS→SQS para fan-out durable. DLQ nativas. Costo: sin replay
  arbitrario, throughput por mensaje con costo, atado a AWS.

> **Regla**: ¿necesitás *replay*? → Kafka (o JetStream). ¿*routing* complejo? → RabbitMQ.
> ¿*latencia* y simplicidad? → NATS. ¿*cero ops* en AWS? → SQS/SNS. Y SIEMPRE: como el
> delivery es at-least-once, los consumidores DEBEN ser idempotentes (ver Inbox en
> `saga-patterns.md`). Configurá **DLQ** en todos: un mensaje envenenado sin DLQ bloquea
> la cola para siempre.

---

## 6. Distributed Caching

Cache compartida entre instancias para reducir latencia y carga sobre la base de datos.

### Redis Cluster vs Memcached

| | **Redis (Cluster)** | **Memcached** |
|--|---------------------|----------------|
| Estructuras | Strings, hashes, sets, sorted sets, streams, bitmaps, HyperLogLog | Solo strings (blobs) |
| Concurrencia | Single-thread por shard (atómico; Redis 6+ I/O multihilo) | **Multi-thread** real |
| Sharding | Nativo (16384 hash slots, consistent-hashing-like) | Del lado cliente (hashing en la librería) |
| Replicación / HA | Replicas + failover (Sentinel/Cluster) | No nativo |
| Persistencia | RDB snapshots + AOF (opcional) | **Ninguna** (puramente volátil) |
| Operaciones atómicas | Sí (`SETNX`, `INCR`, Lua scripts, transactions) | Limitadas (`add`, `incr`, CAS) |
| Cuándo | Caso general: necesitás estructuras, atomicidad, HA, persistencia opcional | Cache pura de strings, máxima simplicidad y throughput multi-core por nodo |

> **Default**: Redis cubre el 95% de los casos. Memcached solo si querés una cache de
> strings ultra-simple multi-thread y no necesitás NADA más (ni estructuras, ni
> persistencia, ni HA nativo).

### Estrategias de caching

| Estrategia | Lectura | Escritura | Trade-off |
|------------|---------|-----------|-----------|
| **Cache-aside** (lazy) | App: mira cache; si miss → DB → puebla cache | App escribe a DB e **invalida** la cache | El más común; cache solo guarda lo pedido; riesgo de stale si la invalidación falla |
| **Read-through** | La cache (con loader) trae de la DB en miss | (combina con write-through) | Lógica de carga encapsulada en la cache; menos código en app |
| **Write-through** | — | App escribe a la cache → la cache escribe a la DB **síncrono** | Cache siempre consistente con DB; latencia de escritura mayor |
| **Write-behind** (write-back) | — | App escribe a la cache → la cache persiste a la DB **async** | Escrituras rapidísimas; **riesgo de pérdida** si la cache cae antes de flush |

> **Regla**: empezá con **cache-aside** (simple, robusto). El problema duro NO es leer:
> es la **invalidación**. Definí TTLs + invalidación explícita en escritura. Write-behind
> SOLO si tolerás perder escrituras recientes (cache volátil = datos en riesgo). Y cuidado
> con el **cache stampede**: cuando una key popular expira, mil requests pegan a la DB a la
> vez → mitigá con locks de regeneración, jitter en TTLs o refresh anticipado.

---

## 7. Stream Processing

Procesamiento continuo de flujos de eventos (no batch). Elección según naturaleza del
problema.

| | **Kafka Streams** | **Apache Flink** | **Spark Structured Streaming** |
|--|-------------------|------------------|--------------------------------|
| Naturaleza | **Librería** embebida en tu app JVM | **Framework** de cluster dedicado | Motor batch+streaming sobre Spark |
| Modelo | Event-at-a-time | True streaming, event-at-a-time | Micro-batch (continuous mode experimental) |
| Latencia | Baja | **Más baja** (real-time real) | Mayor (segundos, por micro-batch) |
| Estado / windowing | Sí (state stores, RocksDB) | Avanzado (event-time, watermarks, savepoints) | Bueno; reusa ecosistema Spark |
| Despliegue | Sin cluster aparte (corre con tu app) | Cluster Flink propio | Cluster Spark |
| Cuándo | Ya usás Kafka y querés transformar streams sin infra extra | Necesitás latencia mínima, ventanas event-time complejas, estado grande | Ya tenés Spark/batch y querés unificar con streaming |

### Exactly-once semantics

"Exactly-once" no significa que el mensaje viaje una sola vez (imposible en red): significa
que el **efecto** se aplica una sola vez. Se logra combinando:

- **Idempotent producers**: el broker deduplica reenvíos del productor (Kafka:
  `enable.idempotence=true`, secuencia + producer ID).
- **Transactional writes**: leer-procesar-escribir como una transacción atómica del broker
  (Kafka transactions: consume + produce + commit de offsets en una sola tx).
- **Idempotencia del consumidor / sink transaccional**: si el sink no es transaccional,
  necesitás dedupe (Inbox pattern) o un sink idempotente (upsert por key).

> **Regla**: exactly-once end-to-end exige que **toda la cadena** lo soporte (producer +
> broker + processor + sink). Un eslabón at-least-once degrada todo a at-least-once →
> volvés a necesitar idempotencia en el consumidor. No vendas "exactly-once" si tu sink es
> un `INSERT` no idempotente.

---

## 8. Service Mesh

Mueve la lógica de red entre servicios (mTLS, retries, timeouts, tracing, traffic
splitting) a una capa de infraestructura — **sidecars** o un proxy por nodo — SIN tocar el
código de la aplicación.

| | **Istio** | **Linkerd** |
|--|-----------|-------------|
| Data plane | Envoy (potente, pesado) | Proxy propio en Rust (micro-proxy, liviano) |
| Capacidades | Máximas: traffic management avanzado, políticas, multi-cluster, WASM | Las esenciales: mTLS, retries, métricas doradas, simplicidad |
| Complejidad | **Alta** (CRDs, tuning, curva pronunciada) | **Baja** (opinado, arranca rápido) |
| Overhead | Mayor (Envoy) | Menor (proxy Rust) |
| Cuándo | Necesitás control fino, multi-cluster, políticas complejas | Querés mTLS + observabilidad con mínima fricción |

### ¿Cuándo vale la complejidad?

Un service mesh resuelve a nivel infra lo que de otro modo repetís en cada servicio:

- mTLS automático entre servicios (zero-trust interno).
- Retries, timeouts, circuit breaking declarativos (sin librería por lenguaje).
- Tracing y métricas uniformes sin instrumentar cada app.
- Traffic shifting (canary, blue-green, mirroring) sin tocar código.

> **Regla de adopción**: un mesh tiene sentido cuando (1) tenés **muchos** servicios en
> **políglota** (mantener librerías de resiliencia por lenguaje no escala), (2) ya corrés
> en **Kubernetes**, y (3) necesitás mTLS/observabilidad uniformes. Para pocos servicios
> en un solo lenguaje, una **librería de resiliencia a nivel app** (ver
> `resilience-patterns.md`) es más simple y suficiente. Empezá por **Linkerd** (menos
> complejidad); subí a **Istio** solo si chocás con un límite real. NO metas un mesh por
> currículum: agrega latencia por sidecar, consumo de recursos y una curva operativa seria.

---

## 9. Anti-patrones

### Redlock — la controversia que DEBÉS conocer

Redlock es el algoritmo de Redis para locks distribuidos sobre N instancias
independientes: adquirís el lock en la mayoría (N/2+1) dentro de un tiempo acotado.

**La crítica de Martin Kleppmann** (y la defensa de antirez, autor de Redis) es el debate
central sobre locks distribuidos:

- Redlock asume **timing**: relojes razonablemente sincronizados y pausas acotadas. Pero un
  **GC pause**, un page fault o una pausa de VM pueden hacer que un proceso CREA que tiene
  el lock cuando su lease YA expiró → **dos procesos con el "mismo" lock** simultáneamente.
- Sin un **fencing token** (un número monótonamente creciente que el recurso protegido
  valida y rechaza si es viejo), ningún lock distribuido garantiza exclusión real ante
  pausas de proceso. Redlock no provee fencing tokens.

**Conclusión accionable** (consenso pragmático del debate):

- Para **eficiencia** (evitar trabajo duplicado, no crítico si ocasionalmente se solapa):
  un lock Redis simple (`SET key val NX PX ttl`) basta. Redlock es overkill.
- Para **correctness** (donde dos dueños = corrupción de datos): NO confíes en Redlock.
  Usá un sistema de consenso (**etcd/ZooKeeper**) Y un **fencing token** validado por el
  recurso. El lock por sí solo nunca es suficiente para correctness.

> **Regla King**: si la corrección depende del lock, NO es trabajo de Redis. Es etcd/ZK +
> fencing token. Redlock para eficiencia, consenso para correctness.

### Otros anti-patrones frecuentes

- **Asumir red confiable**: ignorar timeouts/retries/idempotencia. La red SIEMPRE falla.
- **Distributed monolith**: microservicios tan acoplados que deben desplegarse juntos
  (llamadas síncronas en cadena, una DB compartida). Todo el costo de lo distribuido, cero
  beneficio.
- **Chatty services**: N llamadas de red donde una bastaría (N+1 sobre la red). Cada salto
  suma latencia y modos de fallo. Agregá/batch.
- **Lock sin TTL/lease ni fencing**: deadlock garantizado si el dueño muere.
- **Cache sin estrategia de invalidación**: stale data silencioso; el bug más caro de
  debuggear.
- **Mesh prematuro**: introducir Istio para 3 servicios. Complejidad operativa sin retorno.
- **Exactly-once "creído"**: declararlo end-to-end con un sink no idempotente. Un eslabón
  at-least-once degrada toda la cadena.
- **Quorum par**: clusters de consenso con número par de nodos. 4 nodos toleran los mismos
  fallos (1) que 3 y aumentan el riesgo de empate en elecciones. Siempre impar.

---

## Tabla Comparativa — Selección de Componentes

| Necesidad | Opción default | Alternativa | Criterio de cambio |
|-----------|----------------|-------------|--------------------|
| Consenso / líder / config | **etcd** o Consul (Raft) | ZooKeeper (ZAB) | Ecosistema JVM/Hadoop → ZK |
| Lock distribuido (correctness) | **etcd lease + fencing token** | ZooKeeper ephemeral | Nunca Redlock para correctness |
| Service discovery | **Kubernetes DNS** | Consul, Eureka | Fuera de K8s → Consul |
| Load balancing HTTP | **L7 (Envoy/ALB/Nginx)** | L4 (NLB/IPVS) | Máximo throughput, no-HTTP → L4 |
| Broker — replay/throughput | **Kafka** | NATS JetStream | Latencia mínima → NATS |
| Broker — routing complejo | **RabbitMQ** | — | — |
| Broker — cero ops en AWS | **SQS/SNS** | — | — |
| Cache | **Redis** | Memcached | Solo strings ultra-simple → Memcached |
| Estrategia de cache | **Cache-aside** | Write-through | Consistencia estricta → write-through |
| Stream processing | **Kafka Streams** (si ya usás Kafka) | Flink | Latencia mínima / event-time → Flink |
| Plomería de red inter-servicio | **Librería de resiliencia** | Service mesh | Muchos servicios políglotas en K8s → mesh (Linkerd) |

### Reglas de oro (innegociables)

1. **La red NO es confiable.** Diseñá para timeouts, reintentos e idempotencia desde el
   día uno. Toda llamada de red puede fallar, duplicarse o reordenarse.
2. **CA no existe en distribuido.** Elegís CP o AP. Y con PACELC, también latencia vs
   consistencia en operación normal — esa es la decisión diaria.
3. **No implementes consenso a mano.** etcd/Consul (Raft) o ZooKeeper (ZAB). Un Raft
   casero es un campo minado de bugs sutiles.
4. **Lock distribuido = TTL/lease + liberación automática + (para correctness) fencing
   token.** Redlock para eficiencia; consenso para correctness. Nunca al revés.
5. **Health checks obligatorios**, y distinguí liveness de readiness. Sin ellos, el
   discovery enruta a zombies.
6. **Elegí el broker por criterio, no por moda**: replay→Kafka, routing→RabbitMQ,
   latencia→NATS, cero-ops→SQS/SNS. Todos at-least-once → consumidores idempotentes + DLQ.
7. **Cache: empezá con cache-aside.** El problema duro es la invalidación, no la lectura.
   Cuidado con el stampede.
8. **Exactly-once exige toda la cadena.** Un eslabón at-least-once → idempotencia
   obligatoria en el sink.
9. **Service mesh solo si el dolor lo justifica**: muchos servicios políglotas en K8s.
   Empezá por Linkerd. No por currículum.

---

## Integración con CASTLE A (Architecture)

Cuando un agente detecta un componente distribuido **sin las garantías mínimas**, CASTLE A
emite un **WARNING**. Señales típicas a vigilar:

- Llamadas de red sin timeout, retry con backoff o idempotencia → asume red confiable.
- Lock distribuido sin TTL/lease, o Redlock usado para *correctness* sin fencing token.
- Servicios registrados sin health checks (readiness/liveness) → riesgo de zombies.
- Cache distribuida sin estrategia de invalidación documentada → stale data silencioso.
- Consumidor de broker sin idempotencia/dedupe o sin DLQ configurada.
- Cluster de consenso con número PAR de nodos → quorum frágil.
- Pipeline que promete "exactly-once" con un sink no transaccional ni idempotente.
- Service mesh introducido para pocos servicios mono-lenguaje → complejidad sin retorno.

> **Referencias cruzadas**: para resiliencia de llamadas (retry, circuit breaker,
> bulkhead, timeout) ver `resilience-patterns.md`. Para coordinación de estado entre
> servicios (sagas, outbox/inbox, idempotencia) ver `saga-patterns.md`.
