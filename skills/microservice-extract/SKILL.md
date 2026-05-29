---
name: microservice-extract
version: 2.0
api_version: 1.0.0
description: "Extrae un bounded context de un monolito a un microservicio independiente con el patrón Strangler Fig: analiza dependencias cruzadas, genera un plan de extracción en FASES con gates go/no-go, define el contrato API/event entre monolito y servicio, hace el scaffold del nuevo servicio con la arquitectura del proyecto, decide la strategy de datos (DB compartida transitoria vs migración total) y hace handoff a /contract-test-pact. Verifica tenancy (.king/tenancy.yaml / .king/knowledge/tenancy.md) y propaga la estrategia de aislamiento al nuevo servicio. Usar cuando se necesite: extraer un servicio, sacar un módulo del monolito, strangler fig, descomponer un monolito, crear un microservicio desde un bounded context, o aislar pagos/inventario/notificaciones en su propio servicio. Alimenta CASTLE A (Architecture)."
---

# /microservice-extract — Extracción de un Bounded Context con Strangler Fig (deps, plan en fases, contrato, scaffold, datos, tenancy)

Toma un **módulo del monolito** (un bounded context) y lo extrae a un **microservicio independiente**
aplicando el patrón **Strangler Fig**: en lugar de un big-bang riesgoso, estrangula el módulo
incrementalmente detrás de una fachada, fase por fase, con un gate **go/no-go** y un plan de **rollback**
en cada paso. Primero **mapea las dependencias cruzadas** del módulo hacia (y desde) el resto del
monolito, luego genera el **plan de extracción en fases**, define el **contrato API/event** del límite,
hace el **scaffold** del servicio con la arquitectura del proyecto, decide la **strategy de datos**
(DB compartida transitoria → migración total), y hace **handoff a `/contract-test-pact`** para blindar el
límite con contract tests. Alimenta la capa **CASTLE A** (Architecture).

> **Strangler Fig, no big-bang**: NUNCA se mueve un módulo de golpe. Se interpone una fachada, se redirige
> tráfico incrementalmente al nuevo servicio, y SOLO cuando una fase verde pasa su go/no-go se avanza a la
> siguiente. Si una fase falla su gate, se ejecuta el rollback de ESA fase — el monolito sigue sirviendo.
> Un acoplamiento cíclico fuerte entre el módulo y el resto NO se "rompe a la fuerza": se reporta como
> blocker arquitectónico. Extraer un módulo cíclicamente acoplado produce un *distributed monolith*, que
> tiene todo el costo de lo distribuido y ninguno de sus beneficios — eso es BREACH de CASTLE A.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack del proyecto — fuente de la arquitectura/lenguaje del scaffold del nuevo servicio | Yes | project |
| `.king/knowledge/architecture.md` | Arquitectura del monolito (capas, layout) — para que el scaffold del servicio respete el mismo patrón (hexagonal/clean) | No | project |
| `.king/tenancy.yaml` (o `.king/knowledge/tenancy.md`) | Sentinel de multi-tenancy: modelo, resolver y estrategia de aislamiento a PROPAGAR al nuevo servicio (M07) | No | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de servicios, paquetes y rutas de output | No | project |
| `knowledge/domain/distributed-systems.md` | Comunicación inter-servicio (sync L7 + discovery vs async broker), brokers, distributed monolith como anti-patrón | No | framework |
| `knowledge/domain/saga-patterns.md` | Strategy de datos transaccional cruzando el nuevo límite (Outbox/Inbox, saga, dual-write como anti-patrón) | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[module-path]` o el path no existe / no contiene código del módulo a extraer
- [ ] El módulo tiene acoplamiento **cíclico fuerte** con el resto del monolito que NO puede resolverse sin una refactorización previa (extraerlo produciría un distributed monolith) — reportar como blocker arquitectónico
- [ ] `--communication` provisto pero con un valor inválido (no es `sync-http` / `async-events` / `both`)
- [ ] El módulo no es un **bounded context** identificable (es código transversal/utilitario sin un límite de dominio claro)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA extraer en big-bang: la extracción es SIEMPRE incremental (Strangler Fig) con fases y gate go/no-go por fase
- NUNCA mover/eliminar el código del módulo del monolito en este skill — el monolito sigue sirviendo detrás de la fachada hasta que la última fase pase su gate (este skill PLANIFICA y hace SCAFFOLD, no apaga el monolito)
- NUNCA proponer **dual-write** (escribir a dos DBs sin coordinación) como strategy de datos — usar Outbox/saga (ver `saga-patterns.md`); el dual-write silenciosamente corrompe datos
- NUNCA dejar que el nuevo servicio escriba en la DB del monolito (ni el monolito en la DB del servicio): eso es un *distributed monolith* — el acceso cruzado va SIEMPRE por el contrato API/event
- NUNCA omitir la verificación de tenancy si el sentinel existe: el nuevo servicio DEBE heredar el modelo de aislamiento (RLS / tenant_id / middleware) — un servicio extraído sin aislamiento es una fuga de datos cross-tenant
- NUNCA incluir credenciales, connection strings ni puertos literales en el scaffold, el contrato o el docker-compose — usar variables de entorno / `{{SLOT}}`
- NUNCA avanzar de fase si su gate go/no-go quedó en NO-GO — ejecutar el rollback de esa fase
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Análisis de dependencias cruzadas del módulo: qué consume del monolito y quién lo consume a él (inbound/outbound), con la dirección y el tipo de cada acoplamiento
- [ ] Plan de extracción en FASES (Strangler Fig) con un gate **go/no-go** y un **rollback** por fase
- [ ] Contrato del límite: API contract (sync) y/o event contract (async) según `--communication`
- [ ] Scaffold del nuevo servicio con la arquitectura del proyecto (capas, manifiesto, healthchecks, docker-compose)
- [ ] Strategy de datos: DB compartida transitoria vs migración total, con el patrón transaccional cruzando el límite (Outbox/saga)
- [ ] Verificación de tenancy: si el sentinel existe, la estrategia de aislamiento PROPAGADA al scaffold del nuevo servicio (o nota explícita "single-tenant, no aplica")
- [ ] Handoff a `/contract-test-pact` con el consumer y el provider resueltos del límite
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase N+1 → Phase N+2
(Context)(Analyze   (Phase     (Define   (Scaffold (Data     (Verify   (Handoff  (Session)  (Guide)
          cross-     plan —     contract  service)  strategy) tenancy)  contract-
          deps)      strangler  API/                                    test-pact)
                     + go/no-go)event)
```
> Phase 6 (Verify tenancy) tiene GATE IN sobre la existencia del sentinel: si no hay `.king/tenancy.yaml` ni `.king/knowledge/tenancy.md`, se SALTA dejando nota "single-tenant". Las demás fases son incondicionales.

### PARÁMETROS
```
/microservice-extract [module-path] [--target-service <name>] [--communication sync-http|async-events|both]
```
- `[module-path]`: path del módulo/bounded context a extraer en el monolito (ej. `src/payments`)
- `--target-service`: nombre del nuevo servicio (ej. `payment-service`). Default: derivado del `module-path`
- `--communication`: estilo de comunicación del límite — `sync-http` (request/response L7), `async-events` (broker + eventos) o `both`. Default: `async-events` (menor acoplamiento)

---

## CASTLE activo: _-A-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE A (Architecture) es la capa central: el límite del bounded context, la dirección de las
> dependencias y la prohibición del distributed monolith son decisiones arquitectónicas que este skill
> materializa. CASTLE T cubre el handoff a contract tests (Phase 7). Veredicto CONDITIONAL si hay
> acoplamiento residual que se resuelve dentro del plan de fases, o si la strategy de datos arranca con DB
> compartida transitoria; BREACHED si el plan permite acceso cruzado directo a DBs (distributed monolith),
> dual-write como strategy de datos, o un servicio extraído sin propagar la tenancy cuando el sentinel existe.

## Agentes
- **@architect** — Agente principal: identifica el límite del bounded context, mapea las dependencias cruzadas, decide la dirección de la comunicación, diseña el plan de fases con go/no-go y la strategy de datos, y veta el distributed monolith
- **@developer** — Genera el scaffold del nuevo servicio en el stack/arquitectura del proyecto, la fachada/router del monolito y el docker-compose
- **@tenancy-enforcer** — (si el sentinel existe) verifica que el contrato y el scaffold del nuevo servicio preserven el aislamiento de tenant (resolver middleware, tenant_id en el contrato, RLS en la nueva DB)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Analyze Cross-Dependencies

### GATE IN
- [ ] Se recibió `[module-path]` y existe (BLOCKING CONDITION ya validó el input)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Delimitar el bounded context** — confirmar que `[module-path]` es un límite de dominio (no código transversal). Registrar el lenguaje ubicuo y las entidades/agregados que lo componen
2. [ ] **Mapear dependencias OUTBOUND** — qué consume el módulo del resto del monolito: imports/llamadas a otros módulos, tablas/entidades de OTROS dominios que lee o escribe, servicios compartidos
3. [ ] **Mapear dependencias INBOUND** — quién consume al módulo: qué módulos lo importan/llaman, qué partes del monolito dependen de sus tablas/eventos
4. [ ] **Clasificar cada acoplamiento** — por dirección (in/out), tipo (llamada de código, acceso a datos compartido, evento) y fuerza (débil/refactorizable vs cíclico-fuerte). Marcar los ciclos `módulo ↔ resto`
5. [ ] **Resolver `--target-service` y `--communication`** — desde los flags si se pasaron; si no, derivar el nombre del `module-path` y asumir `async-events` (menor acoplamiento) con WARN
6. [ ] **Detectar blocker de extracción** — si existe un ciclo fuerte irresoluble sin refactor previo, marcarlo (alimenta BLOCKING CONDITION / blocker arquitectónico)

### CHECKPOINT
- [ ] `BOUNDED_CONTEXT` confirmado (entidades + lenguaje ubicuo) o reportado como NO-bounded-context (BLOCKING CONDITION)
- [ ] `DEPS_OUT[]` y `DEPS_IN[]` listados con dirección, tipo y fuerza por acoplamiento
- [ ] Ciclos `módulo ↔ resto` identificados (o "ninguno")
- [ ] `TARGET_SERVICE` y `COMMUNICATION` resueltos
- [ ] Si hay ciclo fuerte irresoluble: marcado como blocker antes de continuar

### OUTPUTS
- Variables: `BOUNDED_CONTEXT`, `DEPS_OUT[]`, `DEPS_IN[]`, `CYCLES[]`, `TARGET_SERVICE`, `COMMUNICATION`, `SHARED_TABLES[]`
- Artefacto: mapa de dependencias cruzadas (inbound/outbound + fuerza)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo mapear el límite ni las dependencias del módulo.
Cause: el `module-path` no es un bounded context claro, o el acoplamiento es cíclico fuerte e irresoluble.
Recovery:
  [ ] Option A: si el módulo es transversal/utilitario sin límite de dominio, abortar (BLOCKING CONDITION) y sugerir re-delimitar el bounded context con `/ddd-tactical`
  [ ] Option B: si hay un ciclo fuerte, NO extraer: proponer una refactorización previa que rompa el ciclo (extraer interfaz, invertir dependencia, mover el código compartido) y re-ejecutar después
  [ ] Option C: si el mapeo es parcial (parte del código no es analizable estáticamente), continuar con los acoplamientos detectados, marcar la cobertura como PARTIAL y pedir al usuario los consumidores que falten

---

## Phase 2: Phase Plan (Strangler Fig + go/no-go)

### GATE IN
- [ ] `DEPS_OUT[]` / `DEPS_IN[]` disponibles (Phase 1) y sin ciclo fuerte irresoluble

### MUST DO
1. [ ] **Diseñar la fachada (strangler)** — el punto de intercepción que enruta tráfico al monolito o al nuevo servicio (proxy/router/feature-flag). Es la espina dorsal del Strangler Fig
2. [ ] **Descomponer en FASES incrementales** — típicamente: (F1) interponer la fachada + nuevo servicio sirviendo lecturas en sombra; (F2) redirigir un subconjunto de tráfico (canary) al servicio; (F3) mover escrituras + datos y cortar el acceso del monolito al módulo. Adaptar al acoplamiento real
3. [ ] **Definir el gate go/no-go por fase** — criterios concretos y medibles (paridad de respuestas, error rate, latencia, % de tráfico migrado, integridad de datos). Solo con GO se avanza
4. [ ] **Definir el rollback por fase** — cómo se revierte ESA fase (feature flag a `off`, re-enrutar al monolito, revertir migración). El monolito DEBE seguir sirviendo ante un NO-GO
5. [ ] **Secuenciar la resolución de cada acoplamiento** de `DEPS_OUT`/`DEPS_IN` dentro de las fases (qué llamada se reemplaza por el contrato, en qué fase)

### CHECKPOINT
- [ ] Fachada de strangler definida (punto de intercepción + mecanismo de enrutado)
- [ ] Plan con ≥2 fases incrementales, cada una con gate go/no-go medible y rollback explícito
- [ ] Ningún paso es big-bang (no hay una sola fase que mueva todo de golpe)
- [ ] Cada acoplamiento de Phase 1 tiene una fase asignada para su resolución

### OUTPUTS
- Artefacto: plan de extracción en fases (fachada + fases + go/no-go + rollback por fase)
- Variable: `PHASE_PLAN[]`

### IF FAILS
ERROR: No se pudo construir un plan incremental con gates.
Cause: el acoplamiento no permite fasear (todo depende de todo), o no hay criterios de go/no-go medibles.
Recovery:
  [ ] Option A: reducir el alcance — extraer primero un sub-contexto más pequeño y autónomo, y dejar el resto para una extracción posterior
  [ ] Option B: si no hay métricas de go/no-go disponibles (sin observabilidad), incluir como Fase 0 del plan instrumentar las métricas mínimas (error rate, latencia, paridad) antes de migrar tráfico
  [ ] Option C: si una dependencia bloquea el fasear, volver a Phase 1 y resolver ese acoplamiento con una refactorización previa antes del plan

---

## Phase 3: Define Contract (API / Event)

### GATE IN
- [ ] `PHASE_PLAN[]` disponible (Phase 2) y `COMMUNICATION` resuelto (Phase 1)

### MUST DO
1. [ ] **Derivar el contrato de los acoplamientos** — cada llamada cruzada de `DEPS_OUT`/`DEPS_IN` que cruza el nuevo límite se vuelve una operación del contrato (NUNCA acceso directo a datos del otro lado)
2. [ ] **Si `COMMUNICATION` incluye `sync-http`** — definir el **API contract** (endpoints, request/response, status codes). Preferir generarlo como spec OpenAPI 3.1 para alimentar `/api-contract-first` y el handoff a Pact
3. [ ] **Si `COMMUNICATION` incluye `async-events`** — definir el **event contract** (nombre del evento, schema del payload, dirección productor→consumidor, garantías at-least-once + idempotencia). Elegir el broker según `distributed-systems.md` (replay→Kafka, routing→RabbitMQ, latencia→NATS, cero-ops AWS→SQS/SNS)
4. [ ] **Marcar el sentido del límite** — qué lado es **provider** y cuál es **consumer** de cada interacción (insumo directo del handoff a `/contract-test-pact`)
5. [ ] **Incluir el contexto de tenant en el contrato** si el sentinel existe — el `tenant_id` viaja en el contrato (header/claim en sync, campo del payload en async); el dato cruzado NUNCA va sin su tenant

### CHECKPOINT
- [ ] Cada acoplamiento que cruza el límite tiene una operación de contrato (ningún acceso directo a datos del otro lado)
- [ ] API contract definido si `sync-http`/`both` (preferentemente OpenAPI 3.1)
- [ ] Event contract definido si `async-events`/`both` (schema + dirección + at-least-once/idempotencia + broker elegido con criterio)
- [ ] Provider y consumer marcados por interacción (para el handoff a Pact)
- [ ] Si hay sentinel de tenancy: el `tenant_id` está presente en el contrato

### OUTPUTS
- Artefactos: API contract (OpenAPI 3.1) y/o event contract (schema + dirección)
- Variables: `API_CONTRACT`, `EVENT_CONTRACT`, `BOUNDARY_PROVIDER`, `BOUNDARY_CONSUMER`

### IF FAILS
ERROR: No se pudo definir el contrato del límite.
Cause: el acoplamiento depende de acceso directo a datos (no hay una operación clara), o el estilo de comunicación no se ajusta al patrón de acceso.
Recovery:
  [ ] Option A: si el acoplamiento es por datos compartidos, NO exponer la tabla: definir una operación de contrato que encapsule ese acceso (el dueño del dato lo sirve)
  [ ] Option B: si el patrón es claramente request/response pero se pidió `async-events` (o viceversa), recomendar el estilo correcto según `distributed-systems.md` y confirmar con el usuario
  [ ] Option C: delegar la generación formal del API contract a `/api-contract-first` (OpenAPI 3.1) y continuar con el contrato a alto nivel, marcando la formalización como pendiente

---

## Phase 4: Scaffold Service

### GATE IN
- [ ] `API_CONTRACT`/`EVENT_CONTRACT` disponible (Phase 3)

### MUST DO
1. [ ] **Generar el scaffold con la arquitectura del proyecto** — respetar el layout de `.king/knowledge/architecture.md` (hexagonal/clean/screaming): capas de dominio, aplicación y adapters; NO replicar la estructura ad-hoc del monolito si el proyecto define un patrón
2. [ ] **Mover (copiar) la lógica de dominio del bounded context** al nuevo servicio como punto de partida (sin tocar aún el módulo en el monolito — eso es de la última fase del plan)
3. [ ] **Generar los adapters del contrato** — el handler HTTP (si sync) y/o el producer/consumer de eventos (si async) que materializan el contrato de Phase 3
4. [ ] **Generar healthchecks** — liveness + readiness distinguidos (ver `distributed-systems.md`), para que el discovery/LB no enrute a zombies
5. [ ] **Generar el manifiesto y el docker-compose** — manifiesto del lenguaje (`package.json`/`go.mod`/`pyproject.toml`) y un servicio en `docker-compose` con puerto por `{{SLOT}}`/env, sin secretos literales
6. [ ] **Aplicar convenciones** de `.king/knowledge/conventions.md` (naming del servicio, paquetes, rutas) si existe

### CHECKPOINT
- [ ] Scaffold del servicio con el layout arquitectónico del proyecto (capas correctas)
- [ ] Adapters del contrato presentes (handler HTTP y/o producer/consumer de eventos)
- [ ] Healthchecks liveness + readiness diferenciados
- [ ] Manifiesto + servicio `docker-compose` con puerto configurable, sin secretos literales
- [ ] El módulo en el monolito NO fue tocado/eliminado (sigue sirviendo detrás de la fachada)

### OUTPUTS
- Archivos: scaffold del nuevo servicio (capas + adapters + healthchecks + manifiesto + docker-compose)
- Variable: `SERVICE_SCAFFOLD_PATH`

### IF FAILS
ERROR: No se pudo generar el scaffold del servicio.
Cause: arquitectura del proyecto indeterminada, o stack sin plantilla de scaffold conocida.
Recovery:
  [ ] Option A: si `.king/knowledge/architecture.md` no existe, ofrecer correr `/clean-arch-setup` o `/hexagonal-setup` primero para fijar el layout, y luego scaffoldear sobre él
  [ ] Option B: generar un scaffold mínimo (dominio + un adapter del contrato + healthcheck + compose) y marcar la fase PARTIAL, dejando el resto como TODO documentado
  [ ] Option C: si el stack no tiene plantilla, scaffoldear la estructura de carpetas y los contratos, dejando los manifiestos como TODO con el comando de init del lenguaje

---

## Phase 5: Data Strategy

### GATE IN
- [ ] `SERVICE_SCAFFOLD_PATH` disponible (Phase 4) y `SHARED_TABLES[]` conocidas (Phase 1)

### MUST DO
1. [ ] **Decidir el punto de partida de datos** — `shared-db` transitoria (el servicio lee la DB del monolito al inicio, como peldaño del Strangler Fig) → `migrated` (el servicio tiene su propia DB y el monolito ya no toca esos datos). La meta SIEMPRE es `migrated`; `shared-db` es solo un paso intermedio temporal con fecha de corte
2. [ ] **Definir el patrón transaccional cruzando el límite** — cuando una operación toca el módulo extraído y el monolito, usar **Outbox + eventos** o **saga** (ver `saga-patterns.md`). PROHIBIDO el dual-write
3. [ ] **Planificar la migración de datos** — backfill + sincronización (CDC/outbox) durante `shared-db`, con verificación de integridad antes del corte. El corte es el go/no-go de la fase de datos del plan
4. [ ] **Anclar la strategy de datos a las fases** del `PHASE_PLAN` — qué fase corre con `shared-db` y en qué fase se hace el corte a `migrated`

### CHECKPOINT
- [ ] `DATA_STRATEGY` decidida (`shared-db` transitoria → `migrated`) con fecha/criterio de corte
- [ ] Patrón transaccional cruzando el límite definido (Outbox/saga) — sin dual-write
- [ ] Plan de migración (backfill + sync + verificación de integridad) presente
- [ ] La strategy de datos está anclada a las fases del plan (qué fase, qué estado de datos)

### OUTPUTS
- Artefacto: strategy de datos (estado por fase + patrón transaccional + plan de migración)
- Variable: `DATA_STRATEGY`

### IF FAILS
ERROR: No se pudo definir una strategy de datos segura.
Cause: la operación exige atomicidad cruzando servicios, o la migración no tiene forma de verificar integridad.
Recovery:
  [ ] Option A: si se exige atomicidad cruzada, NO usar dual-write: modelar una saga con compensaciones (`/saga-design`) y mantener `shared-db` hasta que la saga esté blindada
  [ ] Option B: si no hay forma de verificar integridad post-migración, extender la fase `shared-db` con sincronización dual-read (comparar resultados) antes del corte
  [ ] Option C: reducir el alcance de datos — migrar primero las tablas exclusivas del bounded context y dejar las compartidas en `shared-db` hasta resolver su pertenencia

---

## Phase 6: Verify Tenancy (M07 integration)

### GATE IN
- [ ] Existe el sentinel de tenancy: `.king/tenancy.yaml` o `.king/knowledge/tenancy.md` (si NINGUNO existe, SALTAR esta fase dejando nota "single-tenant — no aplica")

### MUST DO
1. [ ] **Leer el sentinel** — extraer `model` (shared-rls / schema-per-tenant / db-per-tenant), `resolver` (cómo se resuelve el tenant) y `stack`
2. [ ] **Propagar el resolver de tenant al scaffold** — el nuevo servicio DEBE tener el middleware/interceptor de resolución de tenant en su cadena de entrada (igual que el monolito), antes de cualquier handler del contrato
3. [ ] **Propagar el aislamiento a la nueva DB** — si `DATA_STRATEGY` migra a una DB propia: replicar el modelo de aislamiento (RLS + `CREATE POLICY` para shared-rls; schema/db por tenant según el modelo) en las migraciones del nuevo servicio
4. [ ] **Verificar el tenant en el contrato** — confirmar que el `tenant_id` viaja en el contrato del límite (Phase 3) y que el consumidor lo propaga; el dato cruzado NUNCA va sin tenant
5. [ ] **Delegar el veto a @tenancy-enforcer** — pasar el scaffold y el contrato para que verifique queries sin tenant_id, endpoints sin resolver middleware y migrations sin RLS en el nuevo servicio

### CHECKPOINT
- [ ] Sentinel leído: `model` + `resolver` + `stack` identificados
- [ ] Resolver de tenant presente en la cadena de entrada del nuevo servicio
- [ ] Aislamiento (RLS/schema/db según modelo) replicado en las migraciones del nuevo servicio (si migra a DB propia)
- [ ] `tenant_id` presente en el contrato del límite
- [ ] @tenancy-enforcer no reporta veto en el scaffold/contrato (o los vetos fueron resueltos)

### OUTPUTS
- Artefacto: estrategia de aislamiento propagada (middleware + migraciones RLS/schema + tenant en contrato)
- Variable: `TENANCY_MODEL` (o `none`)

### IF FAILS
ERROR: No se pudo propagar la estrategia de aislamiento al nuevo servicio.
Cause: el sentinel existe pero el modelo no es replicable directamente, o el scaffold no contempla el resolver.
Recovery:
  [ ] Option A: si el modelo del monolito no encaja en el nuevo servicio (ej. db-per-tenant con infra distinta), escalar a @architect para decidir el modelo del servicio extraído (debe mantener el aislamiento equivalente)
  [ ] Option B: si el scaffold no tiene el resolver, agregar el middleware de resolución de tenant como primer adapter de entrada antes de continuar
  [ ] Option C: si la propagación no puede completarse ahora, marcar la fase como BLOCKED (NO avanzar al handoff): un servicio sin aislamiento es una fuga cross-tenant — corregir antes de cualquier contract test

---

## Phase 7: Handoff to /contract-test-pact

### GATE IN
- [ ] Contrato del límite definido (Phase 3) con `BOUNDARY_PROVIDER` y `BOUNDARY_CONSUMER` resueltos

### MUST DO
1. [ ] **Resolver consumer y provider del límite** — del `BOUNDARY_PROVIDER`/`BOUNDARY_CONSUMER`: típicamente el monolito (o un servicio existente) es consumer y el nuevo servicio es provider, o viceversa según la dirección de cada interacción
2. [ ] **Mapear el protocolo de Pact** — `sync-http` → `--protocol http`; `async-events` → `--protocol message`; `both` → un handoff por cada interacción
3. [ ] **Componer el comando de handoff** — `/contract-test-pact --consumer <name> --provider <name> --protocol <http|message>`, con la interacción derivada del contrato de Phase 3 (NUNCA inventada)
4. [ ] **Documentar el orden** — los contract tests blindan el límite ANTES de redirigir tráfico real en las fases del plan: el handoff se ejecuta como parte del gate go/no-go de la fase que corta tráfico

### CHECKPOINT
- [ ] Consumer y provider del límite resueltos
- [ ] Protocolo de Pact mapeado desde `COMMUNICATION`
- [ ] Comando `/contract-test-pact` compuesto con la interacción derivada del contrato (no inventada)
- [ ] El handoff está anclado al gate go/no-go de la fase correspondiente del plan

### OUTPUTS
- Artefacto: comando(s) de handoff a `/contract-test-pact` con consumer/provider/protocolo/interacción
- Variable: `PACT_HANDOFF[]`

### IF FAILS
ERROR: No se pudo componer el handoff a /contract-test-pact.
Cause: el contrato no define una interacción concreta, o no se resuelve quién es consumer/provider.
Recovery:
  [ ] Option A: volver a Phase 3 y concretar al menos una interacción del límite (la más crítica) para arrancar el contract test
  [ ] Option B: si el límite es bidireccional, generar dos handoffs (uno por dirección), cada uno con su consumer/provider
  [ ] Option C: si la interacción no está formalizada, encadenar primero `/api-contract-first` (OpenAPI 3.1) y derivar la interacción de Pact de esa spec

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Análisis de dependencias cruzadas (inbound/outbound + fuerza)
  - [ ] Plan de extracción en fases con go/no-go + rollback por fase
  - [ ] Contrato del límite (API y/o event según `--communication`)
  - [ ] Scaffold del servicio con la arquitectura del proyecto + healthchecks + docker-compose
  - [ ] Strategy de datos (shared-db transitoria → migrated, sin dual-write)
  - [ ] Tenancy: aislamiento propagado (o nota "single-tenant — no aplica")
  - [ ] Handoff a `/contract-test-pact` con consumer/provider/protocolo
- [ ] Ningún paso del plan es big-bang (extracción incremental verificada)
- [ ] El módulo del monolito NO fue movido/eliminado (sigue detrás de la fachada)
- [ ] Ningún acceso cruzado directo a DBs en el plan (sin distributed monolith); sin dual-write
- [ ] Si hay sentinel de tenancy: el nuevo servicio hereda el aislamiento (middleware + RLS/schema + tenant en contrato)
- [ ] Ningún secreto / connection string / puerto literal en scaffold, contrato o docker-compose
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(límite limpio + plan incremental + sin acceso cruzado a DBs + tenancy propagada = FORTIFIED; acoplamiento residual resuelto en el plan o shared-db transitoria = CONDITIONAL; acceso cruzado directo a DBs, dual-write, o servicio sin aislamiento con sentinel presente = BREACHED)_ |
| Artifacts | _(mapa de dependencias; plan de fases; contrato API/event; scaffold del servicio + docker-compose; strategy de datos; comando(s) de handoff a /contract-test-pact)_ |
| Next Recommended | `/contract-test-pact` (blindar el límite), `/event-broker-setup` (si async), `/api-contract-first` (formalizar el API contract) o `/saga-design` (si la strategy de datos exige saga) |
| Risks | _(ciclo de acoplamiento resuelto en el plan; shared-db transitoria con corte pendiente; tenancy escalada a @architect; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Contrato del límite definido | `/contract-test-pact` — blindar el límite consumer/provider antes de redirigir tráfico |
| `--communication async-events`/`both` | `/event-broker-setup` — configurar el broker (producers/consumers + DLQ + idempotencia) del event contract |
| API contract a alto nivel, falta formalizar | `/api-contract-first` — generar la spec OpenAPI 3.1 + stubs/mock del nuevo servicio |
| Strategy de datos exige atomicidad cruzada | `/saga-design` — modelar la saga con compensaciones (sin dual-write) |
| Ciclo de acoplamiento fuerte detectado | `/refactor` o `/ddd-tactical` — romper el ciclo (invertir dependencia) antes de extraer |
| Arquitectura del proyecto indefinida | `/clean-arch-setup` o `/hexagonal-setup` — fijar el layout antes del scaffold |
| Sentinel de tenancy con modelo no replicable | escalar a @architect para el modelo de aislamiento del servicio extraído |
| Plan, contrato y scaffold listos | ejecutar el plan fase a fase respetando cada gate go/no-go |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Por qué Strangler Fig (y no big-bang)

El Strangler Fig (Martin Fowler) extrae un módulo **incrementalmente** detrás de una fachada que enruta
tráfico: el nuevo servicio "estrangula" al módulo del monolito fase por fase hasta que el módulo queda sin
tráfico y se retira. La alternativa big-bang (reescribir y cortar de golpe) concentra TODO el riesgo en un
único evento sin rollback gradual. El Strangler Fig convierte un salto al vacío en una escalera con
barandas: cada peldaño (fase) tiene su gate go/no-go y su rollback, y el monolito sigue sirviendo hasta el
último peldaño verde.

### Anatomía de una fase del plan (go/no-go + rollback)

| Elemento | Qué define | Ejemplo |
|----------|------------|---------|
| Objetivo | Qué tráfico/dato migra esta fase | "Servir lecturas de `payment` desde el nuevo servicio en sombra" |
| Gate go/no-go | Criterio medible para avanzar | Paridad de respuestas ≥ 99.9%, error rate < 0.1%, latencia p99 dentro de SLA |
| Rollback | Cómo se revierte ESTA fase | Feature flag `payment-service.read` → `off`, re-enrutar al monolito |
| Estado de datos | shared-db o migrated en esta fase | F1–F2: `shared-db`; F3: corte a `migrated` |

> El gate NO es subjetivo: son métricas. Sin observabilidad para medirlas, la Fase 0 del plan es
> instrumentarlas (ver Phase 2 IF FAILS Option B).

### Comunicación del límite (sync vs async)

| `--communication` | Mecanismo | Cuándo (ver `distributed-systems.md`) |
|-------------------|-----------|----------------------------------------|
| `sync-http` | Request/response L7 + service discovery + health checks | El consumer necesita la respuesta inmediata; acoplamiento temporal aceptable |
| `async-events` (default) | Broker + eventos (at-least-once + idempotencia + DLQ) | Desacople máximo; el consumer reacciona a hechos; tolera latencia |
| `both` | API para queries síncronas + eventos para hechos de dominio | Lecturas síncronas + propagación de cambios async |

> Default `async-events` porque minimiza el acoplamiento: una llamada síncrona en cadena entre el monolito
> y el nuevo servicio reintroduce el acoplamiento temporal que la extracción busca eliminar.

### Strategy de datos — el peldaño shared-db

| Estado | Quién es dueño del dato | Riesgo | Cuándo |
|--------|-------------------------|--------|--------|
| `shared-db` (transitoria) | El monolito; el servicio LEE su DB | Acoplamiento por datos — es un peldaño, NO el destino | Arranque del Strangler Fig, con fecha de corte |
| `migrated` (destino) | El nuevo servicio; el monolito ya NO toca esos datos | Migración debe verificar integridad antes del corte | Fase final del plan |

> El **dual-write** (escribir a las dos DBs sin coordinación) está PROHIBIDO: ante un fallo parcial deja
> las DBs divergentes y corrompe datos en silencio. Para escribir cruzando el límite: **Outbox + eventos**
> o **saga** (`saga-patterns.md`). El acceso cruzado directo a la DB del otro servicio (lectura o
> escritura permanente) es un *distributed monolith* — BREACH de CASTLE A.

### Propagación de tenancy al servicio extraído (M07)

Si el monolito es multi-tenant (existe `.king/tenancy.yaml` o `.king/knowledge/tenancy.md`), el servicio
extraído NO puede nacer single-tenant: heredaría una fuga de datos cross-tenant. La propagación cubre
tres planos:

| Plano | Qué se propaga |
|-------|----------------|
| Entrada | El **resolver middleware** de tenant en la cadena del nuevo servicio, antes de cualquier handler del contrato |
| Datos | El modelo de aislamiento en las migraciones de la nueva DB: RLS + `CREATE POLICY` (shared-rls), schema/db por tenant según el modelo |
| Contrato | El `tenant_id` viaja en el contrato del límite (header/claim en sync, campo del payload en async) |

> @tenancy-enforcer (activo solo si el sentinel existe) veta el scaffold/contrato si encuentra queries sin
> tenant_id, endpoints sin resolver o migrations sin RLS. Un servicio extraído que no pasa este veto NO
> avanza al handoff de contract tests.

### El distributed monolith — el anti-patrón que este skill previene

Extraer un servicio mal acoplado produce un *distributed monolith*: servicios que deben desplegarse
juntos, se llaman en cadena síncrona y/o comparten DB. Tiene TODO el costo de lo distribuido (latencia de
red, fallos parciales, complejidad operativa) y CERO de sus beneficios (despliegue y escalado
independientes). Señales que este skill bloquea o marca CONDITIONAL:

- El nuevo servicio lee/escribe la DB del monolito de forma permanente (no como `shared-db` transitoria con corte).
- Ciclo síncrono `monolito → servicio → monolito` en el camino caliente.
- Dual-write como strategy de datos.
- Acoplamiento cíclico fuerte que no se resolvió antes de extraer.

### Relación con otros skills del arco M04 y siguientes

`/microservice-extract` produce el límite; `/contract-test-pact` (M04) lo blinda con contract tests;
`/event-broker-setup` configura el broker del event contract; `/api-contract-first` formaliza el API
contract en OpenAPI 3.1; `/saga-design` modela la coordinación de datos cruzando el límite; `/idempotency`
hace idempotentes los consumidores del nuevo servicio. Para romper un ciclo previo a la extracción:
`/ddd-tactical` (re-delimitar el bounded context) o `/refactor` (invertir la dependencia). El conocimiento
de fondo está en `knowledge/domain/distributed-systems.md` y `knowledge/domain/saga-patterns.md`. El delta
spec está en `openspec/changes/m04-architecture/specs/distributed-systems/spec.md`.
