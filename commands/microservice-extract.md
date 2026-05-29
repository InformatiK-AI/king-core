---
name: microservice-extract
description: "Extrae un bounded context de un monolito a un microservicio independiente con Strangler Fig: análisis de dependencias cruzadas, plan en FASES con go/no-go, contrato API/event, scaffold del servicio, strategy de datos y handoff a /contract-test-pact. Verifica y propaga la tenancy al nuevo servicio"
argument-hint: "[module-path] [--target-service <name>] [--communication sync-http|async-events|both]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /microservice-extract

Toma un **módulo del monolito** (un bounded context) y lo extrae a un **microservicio independiente**
aplicando **Strangler Fig** — extracción incremental detrás de una fachada, fase por fase, con gate
**go/no-go** y **rollback** en cada paso, NUNCA big-bang. Primero **mapea las dependencias cruzadas** del
módulo (inbound/outbound), genera el **plan de extracción en fases**, define el **contrato API/event** del
límite, hace el **scaffold** del servicio con la arquitectura del proyecto, decide la **strategy de datos**
(DB compartida transitoria → migración total, sin dual-write) y hace **handoff a `/contract-test-pact`**.
Si el monolito es multi-tenant, **verifica el sentinel de tenancy y propaga el aislamiento** al nuevo
servicio. Alimenta **CASTLE A (Architecture)**.

## Instrucciones

1. Invocar el skill `microservice-extract` usando la herramienta Skill
2. Argumentos:
   - `[module-path]`: path del módulo/bounded context a extraer (ej. `src/payments`)
   - `--target-service <name>`: nombre del nuevo servicio (ej. `payment-service`). Default: derivado del `module-path`
   - `--communication <sync-http|async-events|both>`: estilo del límite — `sync-http` (request/response L7), `async-events` (broker + eventos, default por menor acoplamiento) o `both`
3. Seguir todas las fases del skill en orden:
   - Analyze cross-deps → Phase plan (Strangler + go/no-go) → Define contract (API/event) → Scaffold service → Data strategy → Verify tenancy → Handoff a /contract-test-pact
   - Phase 6 (Verify tenancy) tiene GATE IN: si NO existe `.king/tenancy.yaml` ni `.king/knowledge/tenancy.md`, se SALTA con nota "single-tenant". Las demás fases son incondicionales
4. Agentes coordinados: @architect (principal: delimita el bounded context, mapea dependencias, decide comunicación, diseña el plan de fases con go/no-go y la strategy de datos, veta el distributed monolith), @developer (scaffold del servicio + fachada del monolito + docker-compose), @tenancy-enforcer (si el sentinel existe: verifica que contrato y scaffold preserven el aislamiento de tenant)
5. IMPORTANTE — reglas innegociables:
   - NUNCA big-bang: la extracción es incremental con gate go/no-go y rollback por fase
   - NUNCA mover/eliminar el código del módulo del monolito en este skill — el monolito sigue sirviendo detrás de la fachada (este skill PLANIFICA y hace SCAFFOLD)
   - NUNCA acceso cruzado directo a DBs (distributed monolith) ni dual-write como strategy de datos — usar Outbox/saga
   - Si el sentinel de tenancy existe, el nuevo servicio DEBE heredar el aislamiento (resolver middleware + RLS/schema + tenant_id en el contrato); sin eso NO se avanza al handoff
   - Nunca embeber secretos, connection strings ni puertos literales en scaffold, contrato o docker-compose

El estilo de comunicación por defecto es `async-events` porque minimiza el acoplamiento: una llamada
síncrona en cadena entre el monolito y el nuevo servicio reintroduce el acoplamiento temporal que la
extracción busca eliminar. Elegí el broker (si async) con criterio: replay→Kafka, routing→RabbitMQ,
latencia→NATS, cero-ops AWS→SQS/SNS (ver `knowledge/domain/distributed-systems.md`).

## Ejemplos

### Extraer `payments` a un payment-service (caso canónico, async)

El módulo `src/payments` del monolito tiene 3 dependencias cross-module (lee `users`, emite hacia
`orders`, escribe la tabla `transactions`). Se extrae a un servicio independiente comunicándose por eventos:

```
/microservice-extract src/payments --target-service payment-service --communication async-events
```

Genera:
- **Mapa de dependencias cruzadas**: outbound (`payments → users` lectura), inbound (`orders → payments`),
  datos compartidos (`transactions`), con la fuerza de cada acoplamiento y los ciclos detectados
- **Plan en 3 fases (Strangler Fig)**: F1 fachada + payment-service en sombra (lecturas, `shared-db`);
  F2 canary de un % de pagos al servicio; F3 corte de escrituras + migración de `transactions` a DB propia
  (`migrated`). Cada fase con gate go/no-go (paridad, error rate, latencia) y rollback (feature flag → off)
- **Event contract**: evento `PaymentCompleted` (payload + dirección productor→consumidor + at-least-once
  + idempotencia), con el broker elegido por criterio; `payment-service` es **provider**, `orders` consumer
- **Scaffold** de `payment-service` con la arquitectura del proyecto (capas dominio/aplicación/adapters),
  producer/consumer del contrato, healthchecks liveness+readiness, manifiesto y servicio `docker-compose`
- **Strategy de datos**: `shared-db` transitoria (lee `transactions` del monolito) → corte a DB propia con
  Outbox + verificación de integridad (NUNCA dual-write)
- **Tenancy**: si existe `.king/tenancy.yaml`/`.king/knowledge/tenancy.md`, el resolver middleware se
  propaga al scaffold, las migraciones de la nueva DB replican el RLS, y el `tenant_id` viaja en el evento
- **Handoff**: `/contract-test-pact --consumer orders --provider payment-service --protocol message`

### Extracción con comunicación síncrona (REST)

```
/microservice-extract src/inventory --target-service inventory-service --communication sync-http
```

(define un API contract — preferentemente OpenAPI 3.1 — y el handoff usa `--protocol http`)

### Extracción con ambos estilos (API + eventos)

```
/microservice-extract src/catalog --target-service catalog-service --communication both
```

(API para queries síncronas + eventos para hechos de dominio; un handoff de Pact por interacción)

### Nombre de servicio derivado del path

```
/microservice-extract src/notifications
```

(deriva `--target-service notifications` del path y asume `async-events`)

## El plan en fases (Strangler Fig + go/no-go)

Cada fase tiene objetivo, gate medible y rollback. NO hay big-bang: el monolito sirve hasta el último
peldaño verde.

| Fase | Objetivo | Gate go/no-go | Rollback | Estado de datos |
|------|----------|---------------|----------|-----------------|
| F1 | Servicio en sombra (lecturas) | Paridad de respuestas ≥ 99.9% | Flag `read` → off | `shared-db` |
| F2 | Canary de tráfico real | Error rate < 0.1%, latencia p99 en SLA | Re-enrutar al monolito | `shared-db` |
| F3 | Corte de escrituras + datos | Integridad migrada verificada | Revertir migración + flag | corte a `migrated` |

> El gate NO es subjetivo: son métricas. Sin observabilidad para medirlas, la Fase 0 del plan es
> instrumentarlas antes de migrar tráfico.

## Anti-patrones que el skill bloquea

| Anti-patrón | Por qué | Qué hace el skill |
|-------------|---------|-------------------|
| Big-bang (mover todo de golpe) | Concentra el riesgo sin rollback gradual | Exige plan incremental con gate por fase |
| Acceso cruzado directo a DBs | *Distributed monolith*: costo de lo distribuido, cero beneficio | Acceso cruzado SOLO por el contrato API/event |
| Dual-write (dos DBs sin coordinación) | Corrompe datos en silencio ante fallo parcial | Outbox/saga (`saga-patterns.md`) |
| Ciclo de acoplamiento fuerte sin resolver | Extraerlo produce distributed monolith | Reporta blocker → `/refactor` o `/ddd-tactical` primero |
| Servicio extraído single-tenant en monolito multi-tenant | Fuga de datos cross-tenant | Propaga resolver + RLS + tenant en contrato; @tenancy-enforcer veta |

## Handoff a contract testing

El contrato definido (API/event) alimenta directamente `/contract-test-pact`: `sync-http` → `--protocol
http`, `async-events` → `--protocol message`, `both` → un handoff por interacción. Los contract tests
blindan el límite ANTES de redirigir tráfico real — se ejecutan como parte del gate go/no-go de la fase que
corta tráfico. La interacción de Pact se DERIVA del contrato, NUNCA se inventa.

## Knowledge de fondo

Comunicación inter-servicio, brokers y el distributed monolith en `knowledge/domain/distributed-systems.md`.
Strategy de datos transaccional cruzando el límite (Outbox/Inbox, saga, dual-write como anti-patrón) en
`knowledge/domain/saga-patterns.md`. El límite del bounded context y la dirección de las dependencias son
decisiones de **CASTLE A (Architecture)** que este skill materializa.
