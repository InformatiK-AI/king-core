---
name: contract-test-pact
version: 2.0
api_version: 1.0.0
description: "Genera consumer-driven contract tests con Pact entre servicios: consumer test (Pact DSL → pact file), provider verification contra el provider REAL, setup de Pact Broker (docker-compose si no hay externo) e integración CI. Soporta HTTP REST (Pact v3+v4), gRPC (v4 con plugin) y Message (v3 async — Kafka/SNS/RabbitMQ). Usar cuando se necesite: contract testing, Pact, consumer-driven, verificar integración entre servicios, evitar romper consumers al cambiar un provider. Alimenta CASTLE C (Contracts)."
---

# /contract-test-pact — Consumer-Driven Contract Testing con Pact (HTTP / gRPC / Message)

Genera **consumer-driven contract tests** con **Pact** entre dos servicios. El **consumer** define qué
espera del provider en un test que corre contra un **mock** generado por el Pact DSL; ese test produce un
**pact file** (el contrato formal). El **provider** carga ese pact file y verifica cada interacción contra
su **implementación real** (provider verification). Si no hay un Pact Broker externo, genera un
`docker-compose` con Pact Broker + UI para compartir el contrato entre equipos, e integra ambos lados al
pipeline CI. Soporta **HTTP REST** (Pact v3+v4), **gRPC** (Pact v4 + plugin gRPC) y **Message** (Pact v3
async — Kafka, SNS, RabbitMQ). Alimenta la capa **CASTLE C** (Contracts).

> **Regla innegociable del contrato**: el consumer mock se basa en respuestas **REALES** del provider —
> capturadas de su salida o **derivadas de su spec OpenAPI / .proto / schema de mensaje** — NUNCA inventadas.
> Un mock imaginado genera un pact file que el provider real jamás cumple: el contrato se vuelve ficción.
> Por el otro lado, la provider verification corre SIEMPRE contra el provider **real**, nunca contra otro
> mock. Consumer mockea lo real; provider verifica lo real. Ese es el eje del consumer-driven.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack y lenguajes de consumer y provider — fuente del flavor de Pact (pact-js, pact-python, pact-jvm, pact-go) | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de tests, rutas de output y nombres de servicios en el broker | No | project |
| `knowledge/domain/saga-patterns.md` | Patrones de integración entre servicios (Outbox/Inbox, eventos) que informan el contrato Message async | No | framework |
| `knowledge/universal/api-design.md` | Diseño de contratos de API (versionado, status codes) que informa la severidad de un contrato roto | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `--consumer` o `--provider` (no se puede definir un contrato sin ambos lados)
- [ ] No hay una fuente REAL para el mock del consumer: ni respuesta real del provider, ni spec OpenAPI, ni `.proto`, ni schema de mensaje (mockear de la imaginación está PROHIBIDO)
- [ ] La provider verification no tiene acceso al provider REAL (binario, contenedor o endpoint levantable) — no se verifica contra un mock
- [ ] `--protocol grpc` pero no existe el `.proto` del servicio (Pact gRPC lo requiere)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA basar el consumer mock en respuestas inventadas: el mock SE DERIVA de la respuesta real del provider o de su spec OpenAPI / `.proto` / schema de mensaje
- NUNCA ejecutar la provider verification contra un mock o un stub — SIEMPRE contra el provider REAL (con sus provider states)
- NUNCA degradar un contrato roto a PASS: si la verification falla, el reporte indica el campo/interacción exacta que difiere
- NUNCA publicar un pact file al broker desde la verification (el flujo es: consumer publica el pact, provider lo verifica y publica el resultado)
- NUNCA incluir credenciales, tokens del broker ni connection strings literales en tests, pact files, docker-compose o CI — usar variables de entorno / `{{SLOT}}`
- NUNCA hardcodear datos no deterministas (timestamps, IDs, UUIDs) como valores exactos en el matcher — usar matchers por tipo/regex (`like`, `term`, `eachLike`)
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Consumer test con Pact DSL (HTTP/gRPC/Message según `--protocol`) que define la(s) interacción(es) esperada(s)
- [ ] Pact file JSON con el contrato formal (`pact/{consumer}-{provider}.json`)
- [ ] Provider verification que carga el pact file y lo verifica contra el provider REAL (con provider states)
- [ ] Setup de Pact Broker: `docker-compose` (Broker + UI + Postgres) si no hay `--pact-broker` externo
- [ ] CI integration: step de consumer (publish pact) + step de provider (verify + can-i-deploy)
- [ ] Guía de flujo: cómo se comparte el pact file entre equipos consumer → broker → provider
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase N+1 → Phase N+2
(Context)(Define    (Gen      (Gen      (Gen      (Setup    (CI       (Session)  (Guide)
          inter-     consumer  pact      provider  Pact      integ-
          action)    test)     file)     verifi-   Broker)   ration)
                               (artifact)cation)
```
> Phase 5 (Setup Pact Broker) tiene GATE IN: si se pasó `--pact-broker` (broker externo), se SALTA la generación del docker-compose. Las demás fases son incondicionales.

### PARÁMETROS
```
/contract-test-pact --consumer <name> --provider <name> [--protocol http|grpc|message] [--pact-broker <url>] [--interaction <desc>]
```
- `--consumer`: nombre del servicio consumidor (ej. `order-service`)
- `--provider`: nombre del servicio proveedor (ej. `payment-service`)
- `--protocol`: `http` (REST, Pact v3+v4, default), `grpc` (Pact v4 + plugin gRPC) o `message` (Pact v3 async — Kafka/SNS/RabbitMQ)
- `--pact-broker`: URL del Pact Broker externo. Si se omite, Phase 5 genera un `docker-compose` con broker local
- `--interaction`: descripción de la interacción (endpoint/payload/response esperado). Si se omite, se deriva de la spec OpenAPI / `.proto` / schema disponible

---

## CASTLE activo: C-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE C (Contracts) es la capa central: el pact file ES el contrato entre servicios y este skill lo
> materializa y lo verifica. CASTLE A (Architecture) cubre que el contrato respete el límite entre
> servicios; CASTLE T (Testing) cubre la suite generada. Veredicto CONDITIONAL si el consumer mock es
> tentativo (derivado de spec, no de respuesta real) o si falta el provider state; BREACHED si el mock se
> inventó o si la verification corrió contra un mock en vez del provider real.

## Agentes
- **@architect** — Agente principal: define el contrato (qué llama el consumer, qué responde el provider), valida que respete el límite entre servicios y decide la estrategia de versionado del contrato
- **@developer** — Genera el consumer test con Pact DSL, la provider verification con sus provider states y el docker-compose del broker en el stack del proyecto
- **@qa** — Valida que la provider verification efectivamente FALLE cuando el provider rompe el contrato (test del contrato — ver el scenario `transaction_id → transactionId`)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Define Interaction

### GATE IN
- [ ] `--consumer` y `--provider` recibidos (BLOCKING CONDITION ya validó input)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver el `--protocol`** — `http` (default), `grpc` o `message`. Marca el flavor de Pact y los matchers aplicables
2. [ ] **Resolver el flavor de Pact** — desde `.king/knowledge/stack.md`: pact-js (TS/Node), pact-python, pact-jvm (Java/Kotlin/Scala), pact-go, etc. — un flavor por lado (consumer y provider pueden diferir)
3. [ ] **Localizar la fuente REAL del contrato** — en orden de preferencia: (a) respuesta real capturada del provider, (b) spec OpenAPI del provider, (c) `.proto` (gRPC), (d) schema de mensaje (Message). Si NINGUNA existe, abortar (BLOCKING CONDITION — mockear de la imaginación está prohibido)
4. [ ] **Formalizar cada interacción** — `--interaction` o derivada de la fuente: request (método/ruta/headers/body para HTTP; método RPC + payload para gRPC; topic + payload para Message) → response esperado (status + body / response RPC / ack). Identificar el/los **provider state(s)** necesario(s) (ej. "a payment can be created")
5. [ ] **Marcar campos no deterministas** — timestamps, IDs, UUIDs: se matchearán por tipo/regex en Phase 2, nunca por valor exacto

### CHECKPOINT
- [ ] `PROTOCOL` resuelto (`http` | `grpc` | `message`)
- [ ] `PACT_FLAVOR` resuelto por lado (o WARN si ambiguo)
- [ ] `CONTRACT_SOURCE` identificado y es REAL (respuesta real / OpenAPI / `.proto` / schema) — NO inventado
- [ ] Cada interacción formalizada con request → response esperado y su provider state
- [ ] Campos no deterministas marcados para matchers por tipo

### OUTPUTS
- Variables: `CONSUMER`, `PROVIDER`, `PROTOCOL`, `PACT_FLAVOR`, `CONTRACT_SOURCE`, `INTERACTIONS[]`, `PROVIDER_STATES[]`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo definir la interacción a partir de una fuente real.
Cause: no hay respuesta real del provider, ni spec OpenAPI, ni `.proto`, ni schema de mensaje disponible.
Recovery:
  [ ] Option A: pedir al usuario una respuesta REAL del provider (capturada con curl/grpcurl o un log) para derivar el mock
  [ ] Option B: si existe spec OpenAPI / `.proto` / schema pero no es accesible, pedir la ruta y derivar la interacción de ahí
  [ ] Option C: si no hay ninguna fuente real, abortar (BLOCKING CONDITION) — generar el contrato desde la imaginación está PROHIBIDO porque el provider real nunca lo cumpliría

---

## Phase 2: Generate Consumer Test

### GATE IN
- [ ] `INTERACTIONS[]` y `CONTRACT_SOURCE` resueltos (Phase 1)

### MUST DO
1. [ ] **Generar el test del consumer con Pact DSL** del `PACT_FLAVOR` — declara el provider, define cada interacción (`uponReceiving ... willRespondWith` para HTTP; interacción gRPC con plugin; `expectsToReceive` para Message) y corre la lógica del consumer contra el **mock que Pact levanta**
2. [ ] **Derivar el mock SOLO de `CONTRACT_SOURCE`** — la `willRespondWith` reproduce la respuesta REAL del provider (o la derivada de OpenAPI/`.proto`/schema). NUNCA inventar campos ni valores
3. [ ] **Usar matchers por tipo/regex** — `like(value)` por tipo, `term(regex, example)` por patrón, `eachLike(...)` para arrays. Los campos no deterministas (Phase 1) van con matcher, jamás con valor literal
4. [ ] **Declarar los provider states** referenciados (`given("a payment can be created")`) — el provider los implementará en Phase 4
5. [ ] **Asegurar que el test del consumer PASA contra el mock** — verifica que la lógica del consumer parsea correctamente el response esperado

### CHECKPOINT
- [ ] Consumer test generado con el Pact DSL del flavor correcto y el `--protocol` correcto
- [ ] El mock reproduce la respuesta REAL/derivada (sin campos inventados)
- [ ] Campos no deterministas usan matchers por tipo/regex (no valores exactos)
- [ ] Provider states declarados en cada interacción
- [ ] El consumer test pasa contra el mock de Pact

### OUTPUTS
- Archivo: consumer test (en el layout/test runner del consumer)

### IF FAILS
ERROR: No se pudo generar el consumer test con Pact DSL.
Cause: `PACT_FLAVOR` ausente/no soportado, o el `--protocol grpc`/`message` requiere un plugin de Pact no instalado.
Recovery:
  [ ] Option A: documentar la instalación del flavor (`npm i -D @pact-foundation/pact`, `pip install pact-python`, pact-jvm Gradle/Maven, `go get github.com/pact-foundation/pact-go/v2`) y reintentar
  [ ] Option B: para gRPC/Message, documentar la instalación del plugin Pact (`pact-plugin-cli -y install ... protobuf`) y, mientras tanto, generar el test marcándolo como pendiente de plugin
  [ ] Option C: generar el test para HTTP (camino base soportado por todos los flavors) y marcar gRPC/Message como PARTIAL

---

## Phase 3: Generate Pact File

### GATE IN
- [ ] Consumer test generado y pasa contra el mock (Phase 2)

### MUST DO
1. [ ] **Ejecutar el consumer test para PRODUCIR el pact file** — el pact file es el ARTEFACTO resultante del consumer test, no se escribe a mano
2. [ ] **Verificar la estructura del pact file** — `pact/{consumer}-{provider}.json` con `consumer`, `provider`, `interactions[]` (request/response o messages) y `metadata.pactSpecification.version` (`3.0.0` HTTP/Message, `4.0` gRPC/v4)
3. [ ] **Confirmar que los matchers quedaron en `matchingRules`** — los campos no deterministas figuran como reglas de matching, no como valores fijos
4. [ ] **Documentar el pact file como el contrato formal** — este archivo viaja al broker (o directo al provider) y es la única fuente de verdad de la interacción

### CHECKPOINT
- [ ] `pact/{consumer}-{provider}.json` generado por el consumer test (no escrito a mano)
- [ ] Estructura válida: consumer + provider + interactions + versión de spec correcta para `--protocol`
- [ ] `matchingRules` presentes para los campos no deterministas
- [ ] El pact file refleja EXACTAMENTE las interacciones del Phase 1 (sin campos extra inventados)

### OUTPUTS
- Artefacto: `pact/{consumer}-{provider}.json` (contrato formal)
- Variable: `PACT_FILE_PATH`

### IF FAILS
ERROR: No se generó un pact file válido.
Cause: el consumer test no corrió, o no escribió el pact file (config de output ausente), o la versión de spec no matchea el protocolo.
Recovery:
  [ ] Option A: configurar el directorio de salida de Pact (`pactDir`/`PACT_DIR`) y re-correr el consumer test
  [ ] Option B: si la versión de spec no matchea (`grpc` requiere v4), ajustar la config del flavor a Pact v4 y regenerar
  [ ] Option C: inspeccionar el log del consumer test para ver por qué no se emitió el pact (interacción no ejercida = no se escribe) y completar la lógica del consumer

---

## Phase 4: Generate Provider Verification

### GATE IN
- [ ] `PACT_FILE_PATH` existe (Phase 3)
- [ ] El provider REAL es levantable (binario, contenedor o endpoint) — BLOCKING CONDITION lo validó

### MUST DO
1. [ ] **Generar la provider verification** con el Pact verifier del `PACT_FLAVOR` — carga el pact file (del broker o local) y reproduce CADA interacción contra el provider **REAL** levantado en una URL/endpoint
2. [ ] **Implementar los provider states** declarados por el consumer — cada `given(...)` necesita un setup que deje al provider en ese estado (seed de datos, fixtures) ANTES de la interacción. Sin provider state, la verification es inválida
3. [ ] **Apuntar al provider REAL** — la URL/endpoint del provider verificado se resuelve por variable de entorno (`{{PROVIDER_URL}}`), nunca a un mock. Para Message, el verifier invoca el handler real que produce el mensaje
4. [ ] **Garantizar que la verification FALLA ante divergencia** — si el provider devuelve `transactionId` cuando el contrato espera `transaction_id`, la verification DEBE fallar indicando el campo exacto. @qa valida esta orientación
5. [ ] **Publicar el RESULTADO de la verification al broker** (si hay broker) — el provider publica verde/rojo + la versión verificada; NUNCA publica el pact file (eso es del consumer)

### CHECKPOINT
- [ ] Provider verification generada, carga el pact file y corre contra el provider REAL (no un mock)
- [ ] Cada provider state declarado tiene su setup implementado
- [ ] URL/endpoint del provider configurable por env (no hardcodeado, no mock)
- [ ] La verification FALLA cuando el provider rompe el contrato (orientación verificada por @qa)
- [ ] El provider publica el RESULTADO (no el pact file) al broker, si aplica

### OUTPUTS
- Archivo: provider verification + setup de provider states (en el layout del provider)

### IF FAILS
ERROR: La provider verification no se pudo generar o corre contra el target equivocado.
Cause: el provider real no es levantable, faltan provider states, o el verifier apunta a un mock.
Recovery:
  [ ] Option A: documentar cómo levantar el provider real (docker / comando de arranque) y resolver `{{PROVIDER_URL}}` hacia él
  [ ] Option B: implementar los provider states faltantes (seed/fixtures) — sin ellos la interacción no se puede reproducir
  [ ] Option C: si el provider real no está disponible AHORA, generar la verification completa pero marcar la fase PARTIAL (verification escrita, pendiente de correr contra el provider real) — JAMÁS apuntarla a un mock para "que pase"

---

## Phase 5: Setup Pact Broker

### GATE IN
- [ ] NO se pasó `--pact-broker` (si hay broker externo, SALTAR esta fase en silencio y usar esa URL)

### MUST DO
1. [ ] **Generar el `docker-compose` del Pact Broker** — servicio `pact-broker` (imagen `pactfoundation/pact-broker`) + `postgres` de backing + UI, con puertos configurables vía `{{BROKER_PORT}}` (no hardcodeados)
2. [ ] **Sin secretos literales** — credenciales del broker y del Postgres por `env_file`/variables de entorno, nunca inline en el compose
3. [ ] **Documentar el flujo de publicación** — consumer: `pact-broker publish pact/ --consumer-app-version ... --broker-base-url {{BROKER_URL}}`; provider: verifica desde el broker y publica el resultado
4. [ ] **Documentar arranque y URL** — `docker compose up pact-broker` y la URL/UI resultante para que ambos equipos apunten al mismo broker

### CHECKPOINT
- [ ] `docker-compose` con `pact-broker` + `postgres` + UI, puertos configurables (no hardcodeados)
- [ ] Ningún secreto/credencial literal en el compose
- [ ] Comando de publicación del consumer documentado
- [ ] Arranque del broker y URL/UI documentados

### OUTPUTS
- Archivo: `docker-compose` del Pact Broker (servicio `pact-broker` + `postgres`)
- Variable: `BROKER_URL`

### IF FAILS
ERROR: No se pudo generar el setup del Pact Broker.
Cause: conflicto de puerto/servicio en un `docker-compose` existente, o ambigüedad de credenciales.
Recovery:
  [ ] Option A: si ya existe `docker-compose.yml`, AÑADIR los servicios `pact-broker` + `postgres` sin remover los existentes; resolver el puerto vía `{{BROKER_PORT}}`
  [ ] Option B: ofrecer PactFlow (SaaS) como broker hosteado alternativo — pasar `--pact-broker <url>` y saltar el compose
  [ ] Option C: como fallback sin broker, documentar el intercambio directo del pact file (consumer entrega `pact/{consumer}-{provider}.json` al provider) marcando que se pierde versionado/can-i-deploy

---

## Phase 6: CI Integration

### GATE IN
- [ ] Consumer test, pact file y provider verification existen (Phases 2–4)

### MUST DO
1. [ ] **Generar el step de CI del consumer** — corre el consumer test, produce el pact file y lo PUBLICA al broker (`pact-broker publish` con `--consumer-app-version` = SHA del commit y `--branch`)
2. [ ] **Generar el step de CI del provider** — levanta el provider REAL, corre la provider verification contra el broker y publica el resultado
3. [ ] **Agregar `can-i-deploy` como gate de deploy** — antes de desplegar consumer o provider, `pact-broker can-i-deploy --to-environment <env>` BLOQUEA el deploy si el provider no verificó el contrato del consumer
4. [ ] **Parametrizar todo por env** — URL del broker, token y versiones por variables de CI / secrets, nunca literales
5. [ ] **Documentar el flujo end-to-end** — consumer publica pact → provider verifica → `can-i-deploy` decide → deploy. Mencionar la integración con `/microservice-extract` (sugerir contratos tras extraer un servicio)

### CHECKPOINT
- [ ] Step de CI del consumer: corre test + publica pact al broker (versión = SHA)
- [ ] Step de CI del provider: verifica contra el broker + publica resultado
- [ ] `can-i-deploy` presente como gate antes del deploy
- [ ] Ningún token/URL del broker hardcodeado (vía secrets/env)
- [ ] Flujo end-to-end documentado

### OUTPUTS
- Archivos: steps de CI (consumer publish + provider verify + can-i-deploy)

### IF FAILS
ERROR: No se pudo integrar Pact al CI.
Cause: plataforma de CI no resoluble, o falta el broker/token para publicar y verificar.
Recovery:
  [ ] Option A: detectar la plataforma de CI del proyecto (GitHub Actions, GitLab CI, etc.) y generar el step en su sintaxis; si no se detecta, generar un script shell agnóstico
  [ ] Option B: si no hay broker, generar el flujo CI con intercambio del pact file como artefacto del pipeline (sin `can-i-deploy`) y marcarlo PARTIAL
  [ ] Option C: generar los steps con placeholders `{{BROKER_URL}}`/`{{PACT_BROKER_TOKEN}}` y documentar qué secrets configurar antes de habilitar el gate

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Consumer test con Pact DSL (`--protocol` correcto)
  - [ ] Pact file `pact/{consumer}-{provider}.json` producido por el consumer test
  - [ ] Provider verification contra el provider REAL con provider states
  - [ ] Setup del Pact Broker (`docker-compose`) o `--pact-broker` externo en uso
  - [ ] CI integration: consumer publish + provider verify + `can-i-deploy`
  - [ ] Guía de flujo consumer → broker → provider
- [ ] El consumer mock se derivó de una fuente REAL (respuesta real / OpenAPI / `.proto` / schema), NUNCA inventado
- [ ] La provider verification corre contra el provider REAL, NUNCA un mock
- [ ] La verification FALLA ante divergencia de contrato (orientación verificada)
- [ ] Campos no deterministas usan matchers por tipo/regex (no valores literales)
- [ ] Ningún secreto / token del broker / connection string literal en tests, pact file, compose o CI
- [ ] Ninguna versión de tooling / ruta absoluta / nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(consumer test + pact file + provider verification contra provider real + mock derivado de fuente real = FORTIFIED; mock derivado de spec en vez de respuesta real, o provider state pendiente, o verification escrita pero no corrida = CONDITIONAL; mock inventado o verification contra un mock = BREACHED)_ |
| Artifacts | _(consumer test; `pact/{consumer}-{provider}.json`; provider verification + provider states; docker-compose del broker si aplica; steps de CI)_ |
| Next Recommended | `/contract-test` (expandir la suite), `/api-contract-first` (formalizar la spec OpenAPI del provider) o `/build` (implementar el provider state faltante) |
| Risks | _(mock derivado de spec sin respuesta real; provider real no disponible para verificar; broker no configurado = sin can-i-deploy; plugin gRPC/Message pendiente; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Pact file generado, falta verificar el provider | levantar el provider real y correr la provider verification (Phase 4) |
| Provider verification FALLA (contrato roto) | `/fix` — alinear el provider al contrato (ej. `transactionId` → `transaction_id`), luego re-verificar |
| Sin spec OpenAPI del provider, mock derivado tentativo | `/api-contract-first` — formalizar la spec del provider y re-derivar el mock |
| Provider state faltante | `/build` — implementar el setup del provider state (seed/fixtures) |
| Broker levantado y CI integrado | continuar; habilitar `can-i-deploy` como gate de deploy en el pipeline |
| Servicio recién extraído (`/microservice-extract`) | `/contract-test-pact` para cada contrato entre el nuevo servicio y el monolito |
| Todo verde end-to-end | continuar; el contrato queda vigilado por CASTLE C en `/review` |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### El eje consumer-driven: quién mockea qué

| Lado | Qué hace | Contra qué corre | Fuente del dato |
|------|----------|------------------|-----------------|
| Consumer | Define la interacción esperada (Pact DSL) y produce el pact file | El **mock** que Pact levanta | Respuesta REAL del provider o spec OpenAPI / `.proto` / schema — NUNCA inventada |
| Provider | Verifica que cumple el pact file (provider verification) | El provider **REAL** levantado | El pact file publicado por el consumer + provider states reales |

> La asimetría es el corazón del consumer-driven: el consumer mockea lo REAL, el provider verifica lo REAL.
> Si el consumer mockea de la imaginación, el pact file describe un provider que no existe. Si el provider
> "verifica" contra un mock, no verificó nada. Ambos atajos rompen la garantía del contrato.

### Soporte de protocolos

| Protocolo | Pact spec | Tooling | Nota |
|-----------|-----------|---------|------|
| HTTP REST | v3 + v4 | flavor base (pact-js/python/jvm/go) | Camino base; `request`/`response` con matchers |
| gRPC | v4 | flavor v4 + plugin `protobuf`/`grpc` de Pact | Requiere el `.proto`; interacción síncrona por método RPC |
| Message | v3 (async) | flavor con soporte de mensajes | Kafka / SNS / RabbitMQ; el provider verifica el handler que PRODUCE el mensaje, no un endpoint HTTP |

### Matchers (por qué NUNCA valores exactos en campos no deterministas)

| Matcher | Uso | Ejemplo |
|---------|-----|---------|
| `like(value)` | Match por TIPO (no por valor) | `transaction_id: like("txn_123")` → cualquier string |
| `term(regex, example)` | Match por patrón regex | `status: term("approved|declined", "approved")` |
| `eachLike(template)` | Array de N elementos del mismo shape | `items: eachLike({ sku: like("ABC") })` |
| `integer/decimal/timestamp` | Match por tipo numérico/fecha | `amount: decimal(99.90)` |

> Un timestamp o UUID hardcodeado como valor exacto rompe la verification del provider en cada corrida
> (el provider real genera valores nuevos). Por eso los campos no deterministas SIEMPRE van con matcher por tipo.

### Flujo end-to-end (consumer → broker → provider)

```
1. Consumer corre su Pact test (mock derivado de la respuesta REAL del provider)
       → produce pact/order-service-payment-service.json
2. CI del consumer publica el pact al broker
       pact-broker publish pact/ --consumer-app-version $GIT_SHA --branch $BRANCH
3. CI del provider levanta PaymentService REAL y corre la verification contra el broker
       → reproduce cada interacción contra el provider real con provider states
4. Provider publica el RESULTADO al broker (verde/rojo + versión verificada)
5. can-i-deploy decide si OrderService/PaymentService pueden ir a un entorno
       pact-broker can-i-deploy --to-environment production
```

### Ejemplo de verification fallida (contrato roto)

```
Verifying a pact between order-service and payment-service

  Given a payment can be created
    POST /payments returns {status, transaction_id}
      with body
        $.transaction_id
          Expected "transaction_id" but the actual response had "transactionId" (camelCase)

  1 interaction failed (1 expected, 0 actual matching)
```

> La verification señala el campo EXACTO que difiere. Esto es lo que protege al consumer: si PaymentService
> renombra `transaction_id` a `transactionId`, el pipeline lo detecta ANTES del deploy, no en producción.

### Integración con CASTLE C (Contracts)

`agents/architect.md` y la capa CASTLE C tratan el pact file como el contrato autoritativo entre servicios:
- Toda integración entre servicios detectada (vía `/microservice-extract` o análisis de código) que NO
  tenga un pact file asociado genera **WARNING en CASTLE C** sugiriendo `/contract-test-pact`.
- Un consumer mock inventado (no derivado de fuente real) o una provider verification contra un mock es
  señal de **BREACH** de CASTLE C: el contrato es ficción.
- `can-i-deploy` en rojo (provider no verificó el contrato del consumer) bloquea el deploy — es el gate de
  CASTLE C en el pipeline.

### Integración con `/microservice-extract`

Después de extraer un servicio del monolito, `/microservice-extract` sugiere automáticamente ejecutar
`/contract-test-pact` para CADA contrato entre el nuevo servicio y el monolito (y entre el nuevo servicio
y sus consumers existentes), de modo que la extracción no rompa integraciones silenciosamente.

### Relación con otros skills del arco M04

`/contract-test-pact` materializa el contrato ENTRE servicios (CASTLE C, runtime). Se complementa con
`/api-contract-first` (M04, formaliza la spec OpenAPI del provider — fuente ideal para derivar el mock del
consumer), `/contract-test` (M05, contract tests de una API contra su propia spec) y `/microservice-extract`
(que dispara la sugerencia de pact tras extraer un servicio). El delta spec está en
`openspec/changes/m04-architecture/specs/contract-test-pact/spec.md`.
