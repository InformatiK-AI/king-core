---
name: resilience-weave
version: 2.0
api_version: 1.0.0
description: "Teje retry, circuit breaker, bulkhead, timeout y fallback alrededor de llamadas a servicios externos (HTTP, gRPC, DB, cache, queue, SDK de terceros). Clasifica idempotencia ANTES de tejer retry: si la operación NO es idempotente NO agrega retry y sugiere /idempotency. Genera apex.resilience.yaml y tests de chaos. Usar cuando se necesite: hacer resiliente código que llama servicios externos, agregar retry/circuit-breaker/timeout, tolerar fallos de dependencias, o cuando el hook resilience-check detecta llamadas sin resiliencia."
---

# /resilience-weave — Retry, Circuit Breaker, Bulkhead, Timeout y Fallback

Teje los 5 patrones de tolerancia a fallos alrededor de cada llamada a un servicio externo.
La resiliencia NO es "agregar retries": para CADA llamada se decide qué falla se tolera y cómo degradar.
La fase **Classify** determina la **idempotencia ANTES** de tejer retry — una operación no idempotente
con retry duplica efectos (doble cobro, doble email), lo que es PEOR que no tener el patrón. Detecta el
stack desde `.king/knowledge/stack.md`, selecciona la librería apropiada, teje los patrones en el orden
correcto de composición, genera `apex.resilience.yaml` con la configuración usada y produce tests de chaos
que inyectan fallos y verifican el comportamiento.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack del proyecto — fuente para seleccionar la librería de resiliencia | Yes | project |
| `knowledge/domain/resilience-patterns.md` | 9 patrones, tabla de librerías por stack, anti-patrones, orden de composición y checklist por llamada | Yes | framework |
| `.king/knowledge/conventions.md` | Convenciones de naming de servicios y de configuración | No | project |
| `apex.resilience.yaml` | Configuración previa de resiliencia (si existe) — base para no sobrescribir valores afinados | No | project |
| `.king/resilience.yaml` | Política de enforcement del hook (`warn` | `block`) | No | project |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[file|path]` ni se detecta ningún archivo objetivo
- [ ] El target no contiene ninguna llamada a servicio externo (HTTP, gRPC, DB, cache, queue, SDK) — nada que tejer
- [ ] No se puede determinar el stack/lenguaje del target (ni desde `.king/knowledge/stack.md` ni desde la extensión/sintaxis del archivo)

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA tejer **retry** sobre una operación **NO idempotente** sin idempotency-key — solo circuit breaker + timeout, y sugerir `/idempotency`
- NUNCA reintentar sobre errores **4xx de cliente** (400, 401, 403, 404, 422) — son permanentes; reintentar nunca tendrá éxito
- NUNCA tejer **retry** sin **jitter** — backoff exponencial sin jitter sincroniza a todos los clientes (thundering herd)
- NUNCA tejer un **circuit breaker** sin hook de **monitoring** (`OnStateChange` / métrica) — un circuito OPEN silencioso oculta un outage
- NUNCA dejar una llamada de red **sin timeout** — una dependencia colgada agota el pool de conexiones/threads
- NUNCA usar un **fallback que inventa datos críticos** (saldo, autorización, pago) — para datos críticos, error explícito (`503`)
- NUNCA invertir el orden de composición — `Fallback(Retry(CB(Bulkhead(Timeout(call)))))`; timeout SIEMPRE lo más adentro
- NUNCA cambiar la lógica de negocio de la llamada — solo envolverla con los patrones de resiliencia
- NUNCA escribir credenciales/connection strings literales en el código tejido ni en `apex.resilience.yaml` (usar variables de entorno / `{{SLOT}}`)
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] Código modificado con los patrones tejidos alrededor de CADA llamada externa (retry solo si idempotente)
- [ ] `apex.resilience.yaml` generado/actualizado con la configuración aplicada por servicio
- [ ] Tests de chaos: inyectan latencia y errores intermitentes por llamada y verifican circuit breaker + fallback
- [ ] Reporte de clasificación: por llamada, idempotencia + patrones tejidos + patrones omitidos (con razón)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0
(Context)
   │
   ▼
Phase 1 ── Detect calls      (HTTP/gRPC/DB/cache/queue/SDK)
   │
   ▼
Phase 2 ── Classify          ⟵ IDEMPOTENCIA: decide si retry es seguro (GATE para Phase 4)
   │
   ▼
Phase 3 ── Select library    (desde stack.md + tabla resilience-patterns.md)
   │
   ▼
Phase 4 ── Weave retry       (SOLO si idempotente; backoff exp + jitter; excluye 4xx)
   │
   ▼
Phase 5 ── Weave CB          (failure_threshold, min_throughput, recovery + monitoring)
   │
   ▼
Phase 6 ── Weave bulkhead    (semáforo de concurrencia por recurso)
   │
   ▼
Phase 7 ── Weave timeout     (deadline explícito + deadline propagation)
   │
   ▼
Phase 8 ── Weave fallback    (degradado para no-crítico / error explícito para crítico)
   │
   ▼
Phase 9 ── Generate config   (apex.resilience.yaml)
   │
   ▼
Phase 10 ─ Generate tests    (chaos: latencia + errores intermitentes)
   │
   ▼
Phase N+1 (Session) → Phase N+2 (Guide)
```

### PARÁMETROS
```
/resilience-weave [file|path] [--patterns retry,circuit-breaker,bulkhead,timeout,fallback] [--config apex.resilience.yaml]
```
- `[file|path]`: archivo o directorio con código de llamadas externas (default: archivos modificados si lo invoca el hook/`/build`)
- `--patterns`: lista separada por comas de los patrones a tejer (default: `retry,circuit-breaker,bulkhead,timeout,fallback` — todos)
- `--config`: ruta a `apex.resilience.yaml` existente para reusar/afinar valores (default: `apex.resilience.yaml` en la raíz si existe, o parámetros inline)

---

## CASTLE activo: _-A-_-T-L-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> **A** (Architecture): los patrones de resiliencia son decisiones de diseño sobre dependencias y modos de fallo.
> **T** (Testing): los tests de chaos validan que los patrones funcionan de verdad.
> **L** (Logging): la observabilidad es NO opcional — circuit breaker sin monitoring es un anti-patrón que eleva el gate a CONDITIONAL/BREACHED.

## Agentes
- **@architect** — Agente principal: clasifica idempotencia, decide qué patrones aplican por llamada y valida el orden de composición
- **@developer** — Teje los patrones con la librería seleccionada y escribe los tests de chaos
- **@performance** — Valida que timeouts/bulkhead no introduzcan cuellos de botella y que el bulkhead no rechace tráfico legítimo

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Detect calls

### GATE IN
- [ ] Se recibió `[file|path]` (BLOCKING CONDITION ya validó que existe target)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Leer el target** (archivo o todos los archivos del directorio) y resolver el lenguaje desde la extensión y `.king/knowledge/stack.md`
2. [ ] **Identificar llamadas a servicios externos** por categoría: HTTP (`fetch`, `axios`, `http.Client`, `requests`), gRPC, DB (driver/ORM), cache (Redis), queue (SQS/Kafka/RabbitMQ), SDK de terceros (Stripe, AWS, etc.)
3. [ ] **Registrar por cada llamada**: archivo + líneas exactas, categoría, método/verbo HTTP (si aplica) y el recurso/servicio destino (para nombrarlo en `apex.resilience.yaml`)
4. [ ] **Filtrar por `--patterns`** — anotar qué patrones se van a evaluar (default: los 5)

### CHECKPOINT
- [ ] ≥1 llamada externa registrada con archivo + líneas + categoría (si 0, era BLOCKING CONDITION)
- [ ] Nombre de servicio resuelto por llamada (o asignado uno tentativo con WARN)
- [ ] `PATTERNS_REQUESTED` definido

### OUTPUTS
- Variables: `CALLS[]` (file, líneas, categoría, verbo, servicio), `LANG`, `PATTERNS_REQUESTED`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo identificar ninguna llamada externa accionable.
Cause: el código usa un cliente HTTP/SDK no reconocido, o las llamadas están detrás de una abstracción opaca.
Recovery:
  [ ] Option A: pedir al usuario que señale la(s) función(es) que hacen las llamadas externas
  [ ] Option B: tratar las funciones marcadas por el usuario como el punto de envoltura y continuar
  [ ] Option C: si realmente no hay llamadas externas, reportar "nada que tejer" y terminar limpio (no es un fallo)

---

## Phase 2: Classify

### GATE IN
- [ ] `CALLS[]` no vacío (Phase 1)

### MUST DO
1. [ ] **Determinar idempotencia por llamada** — GET/PUT/DELETE bien diseñados y consultas de solo lectura son idempotentes; `POST` que crea recursos, transferencias, envío de email son NO idempotentes (salvo idempotency-key presente). Marcar `IDEMPOTENT = true|false|unknown`
2. [ ] **Detectar idempotency-key** — si un `POST` ya envía un `Idempotency-Key`/clave de deduplicación, tratarlo como idempotente para efectos de retry
3. [ ] **Clasificar errores** por llamada: transitorios reintentables (5xx, red/`ECONNRESET`, 429 con `Retry-After`, timeout) vs. permanentes (4xx de cliente) que abortan
4. [ ] **Evaluar fallback** — ¿el dato es crítico (saldo/pago/autorización → error explícito) o tolera degradación (static value / cached → fallback degradado)?
5. [ ] **Marcar gate de retry** — si `IDEMPOTENT = false` (y sin idempotency-key): `RETRY_ALLOWED = false`; preparar sugerencia `/idempotency`. Si `unknown`: pedir confirmación al usuario antes de tejer retry

### CHECKPOINT
- [ ] Cada llamada tiene `IDEMPOTENT` (`true`/`false`/`unknown`) y `RETRY_ALLOWED` resuelto
- [ ] Clasificación de errores transitorios vs. permanentes por llamada
- [ ] Tipo de fallback decidido por llamada (degradado vs. error explícito)
- [ ] Para llamadas no idempotentes: anotada la sugerencia `/idempotency`

### OUTPUTS
- Variables: `CLASSIFICATION[]` (idempotencia, retry_allowed, errores transitorios, tipo_fallback)

### IF FAILS
ERROR: No se pudo determinar la idempotencia de una o más llamadas.
Cause: el verbo HTTP es ambiguo, la operación es un `POST` sin contexto claro, o es una llamada SDK opaca.
Recovery:
  [ ] Option A: preguntar al usuario si la operación es idempotente (decisión de negocio, no inferible con certeza)
  [ ] Option B: asumir NO idempotente por defecto (fail-safe: nunca tejer retry ante la duda) y dejar `RETRY_ALLOWED = false` con WARN
  [ ] Option C: tejer todos los patrones SALVO retry para esa llamada y sugerir `/idempotency` para habilitar retry seguro

---

## Phase 3: Select library

### GATE IN
- [ ] `CLASSIFICATION[]` disponible (Phase 2)

### MUST DO
1. [ ] **Leer el stack** desde `.king/knowledge/stack.md` y cruzarlo con la tabla de librerías de `knowledge/domain/resilience-patterns.md`
2. [ ] **Seleccionar la suite** — si se tejen 3+ patrones, preferir la suite completa que combina policies (Node `cockatiel`, Go `failsafe-go`, Python `tenacity`+`pybreaker`, Java/.NET `Resilience4j`/`Polly`, Rust `tower`); librerías mono-patrón solo si el stack ya las usa
3. [ ] **Verificar dependencias** — comprobar si la librería ya está en `package.json`/`go.mod`/`requirements.txt`/etc. Si falta, anotarla como dependencia a agregar (NO instalarla en este skill)
4. [ ] **Confirmar deadline propagation** — si el stack soporta contexto padre (Go `context`, etc.), planear propagar el deadline en Phase 7

### CHECKPOINT
- [ ] `LIBRARY` seleccionada y justificada contra la tabla del knowledge
- [ ] Dependencias faltantes listadas (si las hay)
- [ ] Soporte de deadline propagation determinado

### OUTPUTS
- Variables: `LIBRARY`, `DEPS_TO_ADD[]`, `SUPPORTS_DEADLINE_PROP`

### IF FAILS
ERROR: No se pudo seleccionar una librería de resiliencia para el stack.
Cause: stack no listado en la tabla, o `.king/knowledge/stack.md` ausente.
Recovery:
  [ ] Option A: pedir al usuario la librería preferida del ecosistema
  [ ] Option B: tejer los patrones con primitivas del lenguaje estándar (timeout nativo, semáforo, contador de fallos) sin librería externa y marcarlo en el reporte
  [ ] Option C: usar el default más común del lenguaje detectado y marcar como tentativo

---

## Phase 4: Weave retry

### GATE IN
- [ ] `retry` está en `PATTERNS_REQUESTED` (Phase 1)
- [ ] Existe ≥1 llamada con `RETRY_ALLOWED = true` (Phase 2) — si TODAS son no idempotentes, SKIP esta fase

### MUST DO
1. [ ] **Tejer retry SOLO en llamadas idempotentes** — para `RETRY_ALLOWED = false`: NO tejer retry, registrar el motivo y la sugerencia `/idempotency` en el reporte
2. [ ] **Configurar backoff exponencial + jitter** — `max_attempts` (default 3), `base_delay_ms` (default 100), `max_delay_ms` (default 2000), jitter `full` (obligatorio)
3. [ ] **Restringir `retry_on`** a errores transitorios: `[500, 502, 503, 504, NetworkError, TimeoutError]` y 429 con `Retry-After`; abortar explícitamente en 4xx (`AbortError` / equivalente)
4. [ ] **Usar la API de la librería** (`p-retry`/`cockatiel`, `retry-go`, `tenacity`, Resilience4j, Polly, `tower`) respetando los valores configurados

### CHECKPOINT
- [ ] Retry tejido en TODAS las llamadas idempotentes seleccionadas
- [ ] NINGUNA llamada no idempotente recibió retry (verificado contra `RETRY_ALLOWED`)
- [ ] Backoff exponencial + jitter presente; 4xx excluidos del `retry_on`
- [ ] Sugerencia `/idempotency` registrada para las no idempotentes

### OUTPUTS
- Variables: `RETRY_CONFIG` por servicio; llamadas con retry tejido / omitido

### IF FAILS
ERROR: No se pudo tejer retry de forma segura.
Cause: una llamada marcada idempotente resultó ambigua, o la librería no soporta exclusión de 4xx.
Recovery:
  [ ] Option A: degradar a NO tejer retry en la llamada dudosa (fail-safe) y dejar solo CB + timeout
  [ ] Option B: implementar la exclusión de 4xx manualmente (predicate `shouldRetry`) si la librería no la trae nativa
  [ ] Option C: pedir confirmación al usuario para las llamadas `unknown` antes de tejer

---

## Phase 5: Weave circuit breaker

### GATE IN
- [ ] `circuit-breaker` está en `PATTERNS_REQUESTED` (Phase 1)

### MUST DO
1. [ ] **Configurar el breaker** por servicio: `failure_threshold` (default 50%), `min_throughput` (default 10 llamadas mínimas para calcular el ratio), `recovery_timeout_s` (default 30), 1 probe en HALF-OPEN
2. [ ] **Tejer el breaker** envolviendo el bulkhead/timeout (afuera del timeout, adentro del retry) según el orden de composición
3. [ ] **Adjuntar monitoring OBLIGATORIO** — `OnStateChange`/listener que emita métrica + alerta en CADA transición (CLOSED→OPEN→HALF-OPEN). Sin esto, el circuito OPEN es silencioso (anti-patrón)
4. [ ] **Conectar con el fallback** — cuando el circuito está OPEN, la llamada falla rápido y cae al fallback de Phase 8

### CHECKPOINT
- [ ] Circuit breaker tejido por servicio con threshold + min_throughput + recovery
- [ ] Hook de monitoring presente en TODA transición de estado (verificable en el código)
- [ ] Orden de composición respetado (breaker envuelve bulkhead/timeout)

### OUTPUTS
- Variables: `CB_CONFIG` por servicio

### IF FAILS
ERROR: No se pudo tejer el circuit breaker con monitoring.
Cause: la librería no expone un hook de cambio de estado, o no hay sistema de métricas en el proyecto.
Recovery:
  [ ] Option A: usar el callback de estado de la librería con un logger estructurado si no hay métricas formales (al menos visibilidad)
  [ ] Option B: si la operación es de baja frecuencia (nunca alcanza `min_throughput`), omitir el breaker y dejar solo timeout + fallback, anotándolo
  [ ] Option C: bloquear el tejido del breaker y reportar que falta observabilidad (CASTLE L), sugiriendo agregarla primero

---

## Phase 6: Weave bulkhead

### GATE IN
- [ ] `bulkhead` está en `PATTERNS_REQUESTED` (Phase 1)

### MUST DO
1. [ ] **Configurar el semáforo** por recurso externo: `max_concurrent` (default 10) y cola opcional de espera
2. [ ] **Tejer el bulkhead** envolviendo el timeout (adentro del breaker, afuera del timeout) según el orden de composición
3. [ ] **Manejar el rechazo** — la llamada que excede el límite (concurrentes + cola) lanza `BulkheadRejectedError`/equivalente, que cae al fallback de Phase 8
4. [ ] **No estrangular tráfico legítimo** — coordinar con @performance: el límite debe medirse, no ponerse arbitrariamente bajo

### CHECKPOINT
- [ ] Bulkhead tejido por recurso con `max_concurrent`
- [ ] Rechazo manejado (no excepción sin capturar)
- [ ] Orden de composición respetado (bulkhead envuelve timeout)

### OUTPUTS
- Variables: `BULKHEAD_CONFIG` por recurso

### IF FAILS
ERROR: No se pudo tejer el bulkhead.
Cause: la librería no ofrece bulkhead, o el modelo de concurrencia no es claro.
Recovery:
  [ ] Option A: implementar el semáforo con la primitiva nativa del lenguaje (semaphore/channel buffered)
  [ ] Option B: si hay una sola dependencia y recursos abundantes, omitir el bulkhead (overhead sin beneficio) y anotarlo
  [ ] Option C: dejar el bulkhead deshabilitado en `apex.resilience.yaml` para activación posterior tras medición

---

## Phase 7: Weave timeout

### GATE IN
- [ ] `timeout` está en `PATTERNS_REQUESTED` (Phase 1)

### MUST DO
1. [ ] **Configurar el timeout** por llamada: `total_ms` (default 5000) — ni tan corto que cancele operaciones legítimas, ni tan largo que no proteja
2. [ ] **Tejer el timeout lo más ADENTRO** — cada intento individual queda acotado (clave para que retry no consuma todo el presupuesto en un intento)
3. [ ] **Aplicar deadline propagation** si `SUPPORTS_DEADLINE_PROP` — la llamada hija recibe el tiempo RESTANTE del request padre (`context.WithTimeout`, deadline absoluto), no un timeout nuevo
4. [ ] **Asegurar timeout en TODA llamada de red** — ninguna llamada externa queda sin timeout

### CHECKPOINT
- [ ] Timeout tejido en TODAS las llamadas externas (sin excepción)
- [ ] Timeout es el wrapper más interno (verificado contra el orden de composición)
- [ ] Deadline propagation aplicada donde hay contexto padre

### OUTPUTS
- Variables: `TIMEOUT_CONFIG` por llamada

### IF FAILS
ERROR: No se pudo tejer el timeout en una o más llamadas.
Cause: el cliente HTTP/SDK no expone configuración de timeout, o no hay contexto para propagación.
Recovery:
  [ ] Option A: envolver la llamada en un timeout externo (`Promise.race`/`context`/`AbortController`) si el cliente no lo soporta nativo
  [ ] Option B: usar client timeout local fijo si no hay contexto padre para propagar (mejor que nada)
  [ ] Option C: bloquear y reportar — una llamada de red SIN timeout es una ABSOLUTE RESTRICTION; no se puede continuar sin él

---

## Phase 8: Weave fallback

### GATE IN
- [ ] `fallback` está en `PATTERNS_REQUESTED` (Phase 1)
- [ ] Tipo de fallback decidido por llamada (Phase 2)

### MUST DO
1. [ ] **Tejer el fallback lo más AFUERA** — captura cualquier fallo final (retry agotado, circuito OPEN, bulkhead lleno, timeout) y degrada
2. [ ] **Para datos NO críticos**: `static_value` (lista vacía/default) o `cached`/stale; emitir métrica `*.degraded` para visibilidad
3. [ ] **Para datos CRÍTICOS** (pago/saldo/autorización): NO inventar; propagar error explícito con mensaje user-friendly (`503` "temporarily unavailable") — un fallback falso es PEOR
4. [ ] **Registrar la activación** del fallback (contador) para combinar con alerting (un fallback que enmascara un outage sin alerta es un anti-patrón)

### CHECKPOINT
- [ ] Fallback tejido por llamada según su criticidad (degradado vs. error explícito)
- [ ] NINGÚN fallback inventa datos críticos
- [ ] Fallback es el wrapper más externo (orden de composición)
- [ ] Activación del fallback instrumentada (métrica/contador)

### OUTPUTS
- Variables: `FALLBACK_CONFIG` por llamada

### IF FAILS
ERROR: No se pudo determinar un fallback aceptable.
Cause: no está claro si el dato es crítico, o no existe un valor degradado razonable.
Recovery:
  [ ] Option A: por defecto, propagar error explícito (fail-safe: nunca inventar) y dejar `type: error` en la config
  [ ] Option B: preguntar al usuario por un valor degradado aceptable solo si el dato es claramente no crítico
  [ ] Option C: omitir el fallback para esa llamada y dejar que el error suba con el mensaje user-friendly del breaker

---

## Phase 9: Generate config

### GATE IN
- [ ] Al menos un patrón fue tejido (Phases 4-8)

### MUST DO
1. [ ] **Componer `apex.resilience.yaml`** con un bloque por servicio: `retry`, `circuit_breaker`, `bulkhead`, `timeout`, `fallback` con los valores efectivamente aplicados
2. [ ] **Fusionar con config previa** — si existía `apex.resilience.yaml` (o `--config`), preservar valores afinados manualmente; no sobrescribir sin marcar el diff
3. [ ] **Omitir bloques de patrones no tejidos** — si una llamada no idempotente no tiene retry, su servicio NO lleva bloque `retry` (o lo lleva como `disabled: not_idempotent`)
4. [ ] **Sin secretos** — el YAML no contiene credenciales/URLs literales; referenciar por variable de entorno

### CHECKPOINT
- [ ] `apex.resilience.yaml` generado/actualizado con un bloque por servicio
- [ ] Refleja EXACTAMENTE lo tejido (sin retry en no idempotentes)
- [ ] Config previa fusionada sin pérdida de valores afinados
- [ ] Ningún secreto literal en el archivo

### OUTPUTS
- Artefacto: `apex.resilience.yaml`

### IF FAILS
ERROR: No se pudo generar/fusionar `apex.resilience.yaml`.
Cause: conflicto entre la config previa afinada y los nuevos valores.
Recovery:
  [ ] Option A: mostrar el diff al usuario y pedir confirmación de qué valores conservar
  [ ] Option B: escribir la nueva config en `apex.resilience.yaml.new` para revisión manual, sin tocar la existente
  [ ] Option C: usar los valores previos para servicios ya configurados y solo agregar bloques para servicios nuevos

---

## Phase 10: Generate tests

### GATE IN
- [ ] Al menos un patrón fue tejido (Phases 4-8)

### MUST DO
1. [ ] **Generar test de chaos por servicio** con el framework de testing del stack — inyectar latencia `> timeout` y verificar que el circuit breaker abre (`state === OPEN`) y la llamada hace fail-fast
2. [ ] **Test de fallback** — inyectar tasa de error 100% y verificar que la respuesta degrada al fallback (lista vacía / valor cacheado), NO un 500 — para datos no críticos
3. [ ] **Test de retry seguro** — verificar que retry NO se dispara en 4xx y que SÍ reintenta transitorios; verificar que las operaciones NO idempotentes NO tienen retry tejido
4. [ ] **Test de bulkhead** (si tejido) — saturar la concurrencia y verificar el rechazo (`BulkheadRejectedError`) sin tumbar el resto
5. [ ] **Anotar el steady state** — cada test referencia la hipótesis verificada (método científico de chaos: steady state → hypothesis → inject → verify)

### CHECKPOINT
- [ ] ≥1 test de chaos por servicio (circuit breaker abre con latencia sostenida)
- [ ] Test de fallback con errores intermitentes (degrada, no 500)
- [ ] Test que confirma que NO hay retry en no idempotentes ni en 4xx
- [ ] Tests referencian la hipótesis/steady state

### OUTPUTS
- Artefacto: archivo(s) de test de chaos

### IF FAILS
ERROR: No se pudieron generar los tests de chaos.
Cause: no hay framework de testing detectado, o las llamadas no son mockeable/inyectables.
Recovery:
  [ ] Option A: generar los tests con el framework default del stack y un mock/stub del cliente externo
  [ ] Option B: si la llamada no es inyectable, sugerir extraer el cliente a una dependencia inyectable (`/refactor`) y generar el test contra esa interfaz
  [ ] Option C: generar el esqueleto del test con TODOs marcando dónde inyectar el fallo, para completar manualmente

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS existen:
  - [ ] Código tejido con los patrones por llamada (retry SOLO en idempotentes)
  - [ ] `apex.resilience.yaml` generado/actualizado
  - [ ] Tests de chaos (circuit breaker abre + fallback degrada + retry seguro)
  - [ ] Reporte de clasificación por llamada (idempotencia + patrones tejidos/omitidos)
- [ ] NINGUNA operación no idempotente recibió retry (sin idempotency-key) — y se sugirió `/idempotency`
- [ ] Ningún retry sobre 4xx; todo retry con backoff exponencial + jitter
- [ ] Todo circuit breaker tiene monitoring en cada transición
- [ ] Toda llamada de red tiene timeout; orden de composición `Fallback(Retry(CB(Bulkhead(Timeout(call)))))`
- [ ] Ningún fallback inventa datos críticos
- [ ] Ningún secreto literal en código ni en `apex.resilience.yaml`
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(todos los patrones tejidos con monitoring y tests=FORTIFIED; faltó monitoring o no idempotente sin /idempotency=CONDITIONAL; llamada de red sin timeout o retry en no idempotente=BREACHED)_ |
| Artifacts | _(código tejido; `apex.resilience.yaml`; tests de chaos; session document)_ |
| Next Recommended | `/idempotency` (si hubo no idempotentes) · `/qa` (correr chaos) · `/review` |
| Risks | _(retry omitido por no idempotencia; bulkhead sin medir; librería tentativa; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Hubo llamadas NO idempotentes (retry omitido) | `/idempotency` — agregar idempotency-key, luego re-`/resilience-weave` para tejer retry seguro |
| Tests de chaos generados | `/qa` — correr los tests y verificar steady state |
| Faltó observabilidad para el circuit breaker | M07 Observability — agregar métricas/alerting, luego re-tejer el breaker |
| Llamada no inyectable para test | `/refactor` — extraer el cliente externo a una dependencia inyectable |
| Todo tejido y verde | `/review` o continuar; sin acción requerida |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Orden de composición (de afuera hacia adentro)

```
Fallback ( Retry ( CircuitBreaker ( Bulkhead ( Timeout ( call ) ) ) ) )
```

- **Timeout** lo más adentro: cada intento individual está acotado.
- **Bulkhead** acota la concurrencia de cada intento.
- **CircuitBreaker** envuelve al bulkhead: cuenta fallos de los intentos ya acotados.
- **Retry** afuera del breaker: si el circuito está OPEN, falla rápido sin gastar reintentos.
- **Fallback** lo más afuera: captura cualquier fallo final y degrada.

`cockatiel` (`wrap(...)`), `Resilience4j` (decorate) y Polly (`ResiliencePipelineBuilder`) respetan este
orden por construcción. Detalle completo en `knowledge/domain/resilience-patterns.md` § Composición.

### Tabla de librerías por stack (resumen)

| Stack | Retry | Circuit Breaker | Suite completa |
|-------|-------|-----------------|----------------|
| Node.js | `p-retry` | `opossum` | `cockatiel` |
| Go | `retry-go` | `gobreaker` | `failsafe-go` |
| Python | `tenacity`/`stamina` | `pybreaker` | `tenacity`+`pybreaker` |
| Java | Resilience4j | Resilience4j | Resilience4j |
| .NET | Polly | Polly | Polly |
| Rust | `tower` | `tower` | `tower` |

Tabla completa con notas (deadline propagation, jitter por defecto) en `knowledge/domain/resilience-patterns.md`.

### Decisión clave: idempotencia ANTES de retry

| Operación | Idempotente | Retry | Patrones tejidos |
|-----------|-------------|-------|------------------|
| `GET /users/:id` | Sí | ✅ | retry + CB + bulkhead + timeout + fallback |
| `PUT /users/:id` | Sí | ✅ | retry + CB + bulkhead + timeout + fallback |
| `DELETE /users/:id` | Sí (idempotente bien diseñado) | ✅ | retry + CB + bulkhead + timeout + fallback |
| `POST /orders` | **No** | ❌ → `/idempotency` | CB + bulkhead + timeout + fallback (SIN retry) |
| `POST /payments` (con `Idempotency-Key`) | Sí (dedupe) | ✅ | retry + CB + bulkhead + timeout + fallback |

> Reintentar un `POST /orders` sin idempotency-key puede crear órdenes duplicadas. La fase Classify
> bloquea el retry y sugiere `/idempotency` para habilitarlo de forma segura.

### Configuración generada — `apex.resilience.yaml`

```yaml
# apex.resilience.yaml
services:
  payment-api:
    retry:
      max_attempts: 3
      backoff: exponential
      base_delay_ms: 100
      max_delay_ms: 2000
      jitter: full
      retry_on: [500, 502, 503, 504, NetworkError, TimeoutError]
    circuit_breaker:
      failure_threshold: 50   # porcentaje
      min_throughput: 10       # mínimas llamadas para calcular el threshold
      recovery_timeout_s: 30
    bulkhead:
      max_concurrent: 10
    timeout:
      total_ms: 5000
    fallback:
      type: static_value       # static_value | cached | error
      value: null
  order-api:
    # POST /orders no idempotente: retry deshabilitado
    retry:
      disabled: not_idempotent  # usar /idempotency para habilitar
    circuit_breaker:
      failure_threshold: 50
      min_throughput: 10
      recovery_timeout_s: 30
    timeout:
      total_ms: 5000
    fallback:
      type: error               # dato crítico: error explícito, no inventar
```

### Hook `PostToolUse resilience-check` (integración)

`hooks/hooks.json` incorpora un hook `resilience-check` (ADITIVO al array existente) que:
- Detecta archivos modificados con llamadas HTTP/`fetch`/`axios`/gRPC/SDK sin wrapper de retry/timeout
- Emite **WARNING** con la línea específica y sugiere `/resilience-weave` (no bloquea por defecto)
- `enforcement: block` opcional vía `.king/resilience.yaml` para equipos que lo quieran obligatorio

### Integración con `/build`

Si `/build` detecta nuevas dependencias de SDKs externos (diff de `package.json`/`go.mod`/etc.),
sugiere ejecutar `/resilience-weave` sobre los archivos modificados antes de cerrar el build.

### Tests de chaos — método científico

Cada test de chaos sigue: **steady state** (métrica de negocio normal) → **hypothesis** (qué debería
pasar bajo fallo) → **inject fault** (latencia/error/kill, blast radius acotado) → **verify** (se mantuvo
el steady state). Chaos sin observabilidad ni steady state es causar un incidente, no un experimento.
Detalle en `knowledge/domain/resilience-patterns.md` § 9 Chaos Engineering.

### Anti-patrones que este skill previene

| Anti-Pattern | Cómo lo previene el skill |
|-------------|---------------------------|
| Retry en op. no idempotente | Phase 2 (Classify) bloquea retry; sugiere `/idempotency` |
| Retry sin jitter | Phase 4 fuerza jitter `full` |
| Retry sobre 4xx | Phase 4 restringe `retry_on` a transitorios; aborta 4xx |
| Circuit breaker sin monitoring | Phase 5 exige `OnStateChange` → métrica/alerta |
| Llamada sin timeout | Phase 7 teje timeout en TODA llamada (ABSOLUTE RESTRICTION) |
| Fallback que inventa datos críticos | Phase 8 → error explícito para datos críticos |
| Orden de composición invertido | Orden fijo `Fallback(Retry(CB(Bulkhead(Timeout))))` |

Tabla completa de anti-patrones en `knowledge/domain/resilience-patterns.md` § Anti-Patterns.

### Delta spec

Ver `openspec/changes/m04-architecture/specs/resilience-weave/spec.md` para los requirements y scenarios
(teje 5 patrones en HTTP; NO teje retry en no idempotente; hook `resilience-check` aditivo).
