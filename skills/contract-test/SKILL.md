---
name: contract-test
version: 2.0
api_version: 1.0.0
description: "Genera consumer-driven contracts con Pact entre servicios. Usar cuando se necesite: contract testing, verificar integración entre servicios, generar contratos Pact, detectar breaking changes entre consumer y provider, mocks de proveedor para tests del consumidor, o alimentar CASTLE C con evidencia de contratos."
---

# /contract-test — Consumer-Driven Contracts (Pact)

Detecta integraciones HTTP en el codebase, genera contratos Pact desde el consumidor,
los mocks del proveedor, y el test de verificación del proveedor. Alimenta la capa
**CASTLE C** con evidencia de contratos verificados.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/universal/testing-pyramid.md` | Posición del contract testing en la estrategia y su relación con CASTLE C | No | framework |
| `knowledge/_inject/testing-essentials.md` | Patrones de testing base y naming | No | framework |
| `.king/knowledge/architecture.md` | Límites de servicio para identificar consumer/provider | No | project |
| `.king/knowledge/stack.md` | Stack del proyecto para elegir la librería Pact correcta | No | project |

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No existe sesión previa de `/genesis` en el proyecto (`.king/` ausente)
- [ ] No se detectan integraciones HTTP ni se declara `--consumer`/`--provider` manualmente

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems
- NUNCA generar un contrato sin al menos una interaction (request + response) definida
- NUNCA incluir secrets, tokens o URLs de producción en los archivos de contrato generados
- NUNCA marcar CASTLE C como BREACH en v1 por falta de contrato — el veredicto es CONDITIONAL (WARNING)

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] `tests/contracts/{consumer}-{provider}.pact.json` — contrato Pact
- [ ] `tests/contracts/{consumer}.consumer.test.{ext}` — test del consumidor con mock
- [ ] `tests/contracts/{provider}.provider.test.{ext}` — verificación del proveedor
- [ ] `.king/pact/contract-summary.md` — resumen para CASTLE C
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N+1 → Phase N+2
(Context)(Discover)(Consumer)(Provider)(Broker?)(CASTLE C)(Session)  (Guide)
```

### PARÁMETROS
```
/contract-test [--consumer <name>] [--provider <name>] [--verify] [--broker <url>] [--stack <ts|python|java|go>]
```
- `--consumer <name>`: nombre lógico del servicio consumidor
- `--provider <name>`: nombre lógico del servicio proveedor
- `--verify`: sólo generar/ejecutar la verificación del proveedor sobre contratos existentes
- `--broker <url>`: URL del Pact Broker (opcional; sin él usa archivos locales)
- `--stack`: forzar stack si la autodetección falla

---

## CASTLE activo: C-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.

## Agentes
- **@api** — Agente principal: define interactions, request/response, versionado del contrato
- **@architect** — Identifica límites de servicio (consumer vs provider) desde la arquitectura
- **@qa** — Verifica que el contrato cubre los escenarios críticos de la integración

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

Resumen: Display header → Verificar `.king/` → Detectar/crear workflow → Cargar `context.md` → Inyectar Knowledge.

---

## Phase 1: Discover Integrations

### GATE IN
- [ ] `.king/` existe (genesis ejecutado)
- [ ] Codebase analizable o `--consumer`/`--provider` declarados

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Detectar stack** — leer `.king/knowledge/stack.md`; si ausente, inferir por archivos de manifiesto (`package.json`, `pyproject.toml`/`requirements.txt`, `pom.xml`/`build.gradle`, `go.mod`)
2. [ ] **Buscar llamadas HTTP salientes** (rol consumidor): `fetch`, `axios`, `got` (TS/JS); `httpx`, `requests` (Python); `RestTemplate`, `WebClient`, `HttpClient` (Java); `http.Client`, `http.Get/Post` (Go)
3. [ ] **Buscar handlers HTTP** (rol proveedor): rutas de Express/Fastify, FastAPI/Flask, Spring `@RestController`, `http.HandleFunc`/router de Go
4. [ ] **Mapear integraciones** — para cada llamada saliente, identificar (consumer, provider, método, path, request shape, response shape esperada)
5. [ ] **Resolver nombres lógicos** — usar `--consumer`/`--provider` si se dieron; si no, derivar del nombre del módulo/servicio y confirmar con el usuario

### CHECKPOINT
> ✅ Verify before continuing

- [ ] Al menos 1 integración mapeada con (consumer, provider, interactions)
- [ ] Stack detectado y librería Pact correspondiente seleccionada
- [ ] Cada interaction tiene método, path y shape de request/response

### OUTPUTS
- Variables: `STACK`, `CONSUMER`, `PROVIDER`, `INTERACTIONS[]`, `EXT`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se detectaron integraciones.
Cause: monolito sin llamadas HTTP internas, o autodetección fallida.
Recovery:
  [ ] Option A: pedir al usuario `--consumer` y `--provider` explícitos + describir la interaction
  [ ] Option B: si es monolito sin servicios externos → log WARN "contract testing no aplica" y terminar con Status PARTIAL
  [ ] Option C: forzar `--stack` si la detección de stack fue el problema

---

## Phase 2: Generate Consumer Contract

### GATE IN
- [ ] `INTERACTIONS[]` no vacío (Phase 1)

### MUST DO
1. [ ] **Generar contrato Pact** `tests/contracts/{CONSUMER}-{PROVIDER}.pact.json` con las interactions (request: method/path/headers/body; response: status/headers/body)
2. [ ] **Generar test del consumidor** `tests/contracts/{CONSUMER}.consumer.test.{EXT}` usando la librería Pact del stack (ver tabla en REFERENCE), levantando el mock provider desde el contrato
3. [ ] **Aislar del proveedor real** — el test del consumidor DEBE pasar sin el proveedor corriendo (usa el mock de Pact)
4. [ ] **Versionar el contrato** — incluir `consumer.version` y `pact-specification: { version: "3.0.0" }`

### CHECKPOINT
- [ ] `{CONSUMER}-{PROVIDER}.pact.json` existe con ≥1 interaction completa
- [ ] `{CONSUMER}.consumer.test.{EXT}` existe y referencia el mock de Pact
- [ ] El test no requiere el proveedor real (mock-based)

### OUTPUTS
- `tests/contracts/{CONSUMER}-{PROVIDER}.pact.json`
- `tests/contracts/{CONSUMER}.consumer.test.{EXT}`

### IF FAILS
ERROR: No se pudo generar el contrato del consumidor.
Cause: shape de request/response incompleta o librería Pact no instalada.
Recovery:
  [ ] Option A: completar shapes faltantes preguntando al usuario por el ejemplo de payload
  [ ] Option B: guiar instalación de la librería Pact del stack (ver REFERENCE) y reintentar
  [ ] Option C: ver `skills/_shared/if-fails-templates.md` → Tooling-Not-Installed

---

## Phase 3: Generate Provider Verification

### GATE IN
- [ ] Existe un contrato Pact en `tests/contracts/` (generado en Phase 2 o preexistente con `--verify`)

### MUST DO
1. [ ] **Generar verificación del proveedor** `tests/contracts/{PROVIDER}.provider.test.{EXT}` que reproduce cada interaction del contrato contra el handler real
2. [ ] **Definir provider states** — para interactions que dependen de datos ("given user 42 exists"), generar los hooks de estado
3. [ ] **Asegurar fallo ante incumplimiento** — el test DEBE fallar si el proveedor no satisface una interaction del contrato

### CHECKPOINT
- [ ] `{PROVIDER}.provider.test.{EXT}` existe
- [ ] Cada interaction del contrato tiene su verificación
- [ ] Los provider states necesarios están declarados

### OUTPUTS
- `tests/contracts/{PROVIDER}.provider.test.{EXT}`

### IF FAILS
ERROR: La verificación del proveedor no cubre el contrato.
Cause: provider states faltantes o handler no localizado.
Recovery:
  [ ] Option A: pedir al usuario la ubicación del handler del proveedor
  [ ] Option B: generar stubs de provider state y marcarlos como TODO con WARN
  [ ] Option C: si el proveedor es externo (no en este repo) → documentar verificación manual y seguir

---

## Phase 4: Pact Broker Setup (opcional)

### GATE IN
- [ ] `--broker <url>` proporcionado

### MUST DO
1. [ ] **Generar** `.king/pact/broker.yaml` con la URL del broker y placeholders `{{PACT_BROKER_TOKEN}}` (nunca el token literal)
2. [ ] **Documentar** el comando de publicación (`pact-broker publish`) y de `can-i-deploy`
3. [ ] **No publicar** automáticamente — dejar el comando listo para que el usuario lo ejecute

### CHECKPOINT
- [ ] `.king/pact/broker.yaml` existe con la URL y SIN secrets literales

### OUTPUTS
- `.king/pact/broker.yaml`

### IF FAILS
ERROR: No se pudo configurar el broker.
Cause: URL inválida.
Recovery:
  [ ] Option A: validar formato de URL y reintentar
  [ ] Option B: omitir broker → operar con contratos locales (no bloqueante)

---

## Phase 5: CASTLE C Report

### GATE IN
- [ ] Contrato(s) y verificación generados (o documentados)

### MUST DO
1. [ ] **Contabilizar integraciones** detectadas en Phase 1 vs integraciones con contrato
2. [ ] **Evaluar capa C**: si hay llamadas HTTP sin contrato correspondiente → WARNING por cada una
3. [ ] **Escribir** `.king/pact/contract-summary.md` con: integraciones, contratos, cobertura %, veredicto
4. [ ] **Asignar veredicto CASTLE C**: `PASS` si 100% con contrato; `CONDITIONAL` si falta alguno (nunca BREACH en v1)

### CHECKPOINT
- [ ] `.king/pact/contract-summary.md` existe
- [ ] Veredicto C asignado (PASS | CONDITIONAL)

### OUTPUTS
- `.king/pact/contract-summary.md`

### IF FAILS
ERROR: No se pudo evaluar CASTLE C.
Cause: conteo de integraciones inconsistente.
Recovery:
  [ ] Option A: recontar desde `INTERACTIONS[]` de Phase 1
  [ ] Option B: emitir summary con veredicto CONDITIONAL y nota de incertidumbre

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] `tests/contracts/{CONSUMER}-{PROVIDER}.pact.json`
  - [ ] `tests/contracts/{CONSUMER}.consumer.test.{EXT}`
  - [ ] `tests/contracts/{PROVIDER}.provider.test.{EXT}`
  - [ ] `.king/pact/contract-summary.md`
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Ningún secret/token literal en los archivos generados
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(copiar de Phase 5: PASS=FORTIFIED, WARNING=CONDITIONAL)_ |
| Artifacts | _(contratos, tests, summary)_ |
| Next Recommended | `/mutation-test` o `/qa` |
| Risks | _(integraciones sin contrato, provider states TODO, o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Contratos generados y verificados en verde | `/mutation-test` (validar calidad de los tests) |
| Integraciones sin contrato detectadas | Re-ejecutar `/contract-test` para las faltantes |
| Contrato roto en verificación del proveedor | `/fix` sobre el proveedor para cumplir el contrato |
| Pact Broker configurado | Publicar contratos y correr `can-i-deploy` antes de `/promote` |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Librería Pact por stack

| Stack | Librería | Instalación |
|-------|----------|-------------|
| TypeScript/JS | `@pact-foundation/pact` | `npm i -D @pact-foundation/pact` |
| Python | `pact-python` | `pip install pact-python` |
| Java | `au.com.dius.pact` (JUnit 5) | dependencia Maven/Gradle `au.com.dius.pact.consumer:junit5` |
| Go | `pact-go` | `go install github.com/pact-foundation/pact-go/v2` |

### Estructura del contrato Pact (v3)

```json
{
  "consumer": { "name": "order-service" },
  "provider": { "name": "user-service" },
  "interactions": [
    {
      "description": "a request for user 42",
      "providerState": "user 42 exists",
      "request":  { "method": "GET", "path": "/users/42" },
      "response": { "status": 200, "headers": { "Content-Type": "application/json" },
                    "body": { "id": 42, "name": "Ada" } }
    }
  ],
  "metadata": { "pactSpecification": { "version": "3.0.0" } }
}
```

### Ejemplos por stack

**TypeScript** — `tests/contracts/order-service.consumer.test.ts`:
```typescript
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
const { like } = MatchersV3;

const provider = new PactV3({ consumer: 'order-service', provider: 'user-service' });

provider
  .given('user 42 exists')
  .uponReceiving('a request for user 42')
  .withRequest({ method: 'GET', path: '/users/42' })
  .willRespondWith({ status: 200, body: like({ id: 42, name: 'Ada' }) });

test('GET /users/42 cumple el contrato', () =>
  provider.executeTest(async (mock) => {
    const res = await fetch(`${mock.url}/users/42`);
    expect(res.status).toBe(200);
  }));
```

**Python** — `tests/contracts/order_service.consumer.test.py`:
```python
from pact import Consumer, Provider, Like

pact = Consumer('order-service').has_pact_with(Provider('user-service'))

def test_get_user_contract():
    (pact
        .given('user 42 exists')
        .upon_receiving('a request for user 42')
        .with_request('GET', '/users/42')
        .will_respond_with(200, body=Like({'id': 42, 'name': 'Ada'})))
    with pact:
        # llamada real del cliente contra el mock de pact
        ...
```

**Java (JUnit 5)** — `tests/contracts/OrderServiceConsumerTest.java`:
```java
@ExtendWith(PactConsumerTestExt.class)
@PactTestFor(providerName = "user-service")
class OrderServiceConsumerTest {
  @Pact(consumer = "order-service")
  RequestResponsePact getUser(PactDslWithProvider b) {
    return b.given("user 42 exists")
            .uponReceiving("a request for user 42")
            .path("/users/42").method("GET")
            .willRespondWith().status(200).body("{\"id\":42,\"name\":\"Ada\"}")
            .toPact();
  }
}
```

**Go** — `tests/contracts/order_service_consumer_test.go`:
```go
func TestUserContract(t *testing.T) {
    mockProvider, _ := consumer.NewV2Pact(consumer.MockHTTPProviderConfig{
        Consumer: "order-service", Provider: "user-service"})
    mockProvider.
        AddInteraction().
        Given("user 42 exists").
        UponReceiving("a request for user 42").
        WithRequest("GET", "/users/42").
        WillRespondWith(200, func(b *consumer.V2ResponseBuilder) {
            b.JSONBody(matchers.Like(map[string]interface{}{"id": 42, "name": "Ada"}))
        })
    // ExecuteTest...
}
```

### Integración con CASTLE C

Ver `docs/castle-c-integration.md` (generado por este skill en T-08) y `skills/castle/SKILL.md`
capa C. Regla: toda llamada HTTP saliente a otro servicio debe tener un contrato Pact
correspondiente; la ausencia produce WARNING (veredicto CONDITIONAL), no BREACH, en v1.

### Degradación grácil

Si el stack no está en la tabla (ej. Ruby), el skill informa la librería Pact equivalente
(`pact-ruby`) y guía la instalación antes de continuar, en lugar de fallar.
