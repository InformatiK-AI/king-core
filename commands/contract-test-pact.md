---
name: contract-test-pact
description: "Consumer-driven contract testing con Pact entre servicios: consumer test (Pact DSL → pact file), provider verification contra el provider REAL, setup de Pact Broker (docker-compose si no hay externo) e integración CI. Soporta HTTP REST (v3+v4), gRPC (v4) y Message (v3 async)"
argument-hint: "--consumer <name> --provider <name> [--protocol http|grpc|message] [--pact-broker <url>] [--interaction <desc>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /contract-test-pact

Genera **consumer-driven contract tests** con **Pact** entre dos servicios. El **consumer** define qué
espera del provider en un test que corre contra un **mock** generado por el Pact DSL; ese test produce un
**pact file** (el contrato formal). El **provider** carga el pact file y lo verifica contra su
**implementación real**. Si no hay Pact Broker externo, genera un `docker-compose` con Broker + UI para
compartir el contrato entre equipos, e integra ambos lados al CI. Soporta **HTTP REST** (Pact v3+v4),
**gRPC** (Pact v4 + plugin) y **Message** (Pact v3 async — Kafka/SNS/RabbitMQ). Alimenta **CASTLE C (Contracts)**.

## Instrucciones

1. Invocar el skill `contract-test-pact` usando la herramienta Skill
2. Argumentos:
   - `--consumer <name>`: nombre del servicio consumidor (ej. `order-service`)
   - `--provider <name>`: nombre del servicio proveedor (ej. `payment-service`)
   - `--protocol <http|grpc|message>`: `http` (REST, Pact v3+v4, default), `grpc` (Pact v4 + plugin gRPC) o `message` (Pact v3 async — Kafka/SNS/RabbitMQ)
   - `--pact-broker <url>`: URL del Pact Broker externo. Si se omite, el skill genera un `docker-compose` con broker local (Broker + UI + Postgres)
   - `--interaction <desc>`: descripción de la interacción (endpoint/payload/response). Si se omite, se deriva de la spec OpenAPI / `.proto` / schema disponible
3. Seguir todas las fases del skill en orden:
   - Define interaction → Generate consumer test → Generate pact file → Generate provider verification → Setup Pact Broker → CI integration
   - Phase 5 (Setup Pact Broker) tiene GATE IN: si se pasó `--pact-broker`, se SALTA la generación del docker-compose. Las demás fases son incondicionales
4. Agentes coordinados: @architect (principal: define el contrato y valida el límite entre servicios), @developer (genera consumer test, provider verification con provider states y docker-compose), @qa (valida que la verification FALLE cuando el provider rompe el contrato)
5. IMPORTANTE — regla innegociable del consumer-driven:
   - El consumer mock se DERIVA de una respuesta REAL del provider (o de su spec OpenAPI / `.proto` / schema de mensaje). NUNCA se inventa
   - La provider verification corre SIEMPRE contra el provider REAL (con sus provider states), NUNCA contra un mock
   - Los campos no deterministas (timestamps, IDs, UUIDs) van con matchers por tipo/regex (`like`, `term`, `eachLike`), nunca con valores exactos
   - Nunca embeber tokens del broker ni connection strings en tests, pact files, compose o CI

## Ejemplos

### OrderService ↔ PaymentService (HTTP REST) — el caso canónico

OrderService es **consumer** de PaymentService: llama `POST /payments` y espera `{status, transaction_id}`.

```
/contract-test-pact --consumer order-service --provider payment-service
```

Genera:
- **Consumer test** (Pact DSL) en OrderService: define `POST /payments → {status, transaction_id}` con el
  mock derivado de la respuesta REAL de PaymentService; `transaction_id` matcheado por tipo (`like`), no por valor
- **Pact file** `pact/order-service-payment-service.json` con request/response formalizados
- **Provider verification** en PaymentService: levanta el servicio REAL, implementa el provider state
  `a payment can be created` y reproduce la interacción contra él
- **docker-compose** con Pact Broker + UI (no se pasó `--pact-broker`)
- **CI**: OrderService publica el pact, PaymentService verifica + `can-i-deploy`

### Con Pact Broker externo (PactFlow / broker hosteado)

```
/contract-test-pact --consumer order-service --provider payment-service --pact-broker https://my-org.pactflow.io
```

(salta la generación del docker-compose y publica/verifica contra el broker externo)

### gRPC (Pact v4 + plugin)

```
/contract-test-pact --consumer order-service --provider inventory-service --protocol grpc
```

(requiere el `.proto` del servicio; usa Pact v4 con el plugin gRPC)

### Message async (Kafka / SNS / RabbitMQ)

```
/contract-test-pact --consumer notification-service --provider order-service --protocol message
```

(el provider verifica el handler que PRODUCE el mensaje, no un endpoint HTTP; Pact v3 async)

## El eje consumer-driven (quién mockea qué)

| Lado | Corre contra | Fuente del dato |
|------|--------------|-----------------|
| Consumer (define + produce pact) | El **mock** que Pact levanta | Respuesta REAL del provider o spec OpenAPI / `.proto` / schema — NUNCA inventada |
| Provider (verifica el pact) | El provider **REAL** levantado | El pact file + provider states reales |

El consumer mockea lo REAL; el provider verifica lo REAL. Si el consumer inventa el mock, el pact describe
un provider que no existe; si el provider "verifica" contra un mock, no verificó nada. Ambos atajos rompen
el contrato — y son BREACH de CASTLE C.

## Ejemplo de verification fallida (contrato roto)

PaymentService renombra `transaction_id` a `transactionId` (camelCase). La provider verification lo detecta:

```
Verifying a pact between order-service and payment-service

  Given a payment can be created
    POST /payments returns {status, transaction_id}
      with body
        $.transaction_id
          Expected "transaction_id" but the actual response had "transactionId"

  1 interaction failed
```

El pipeline lo detecta ANTES del deploy (`can-i-deploy` en rojo), no en producción.

## Tooling

Pact por flavor: `@pact-foundation/pact` (pact-js) · `pact-python` · pact-jvm · `pact-go`.
Plugins para gRPC/Message (`pact-plugin-cli`). Broker: `pactfoundation/pact-broker` (docker) o PactFlow (SaaS).
CLI de flujo: `pact-broker publish`, `pact-broker can-i-deploy`.

El pact file es la ÚNICA fuente de verdad del contrato ENTRE servicios: el consumer lo deriva de lo REAL y
el provider lo verifica contra lo REAL. Detalle de matchers, protocolos y flujo end-to-end en el SKILL.md;
diseño de contratos de API y versionado en `knowledge/universal/api-design.md`.
