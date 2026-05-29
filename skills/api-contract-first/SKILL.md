---
name: api-contract-first
version: 2.0
api_version: 1.0.0
description: "Genera server stubs, client SDKs, mock server (Prism), contract tests (schemathesis/dredd) y docs (Redoc) desde una spec OpenAPI 3.1 — cada output es INDEPENDIENTE (se puede pedir solo stubs). Valida la spec con spectral y detecta breaking changes vs una versión anterior con oasdiff. Usar cuando se necesite: contract-first, spec-first, generar stubs/SDKs/mock desde OpenAPI, levantar un mock server, generar contract tests de una API, o chequear breaking changes de una spec. Alimenta CASTLE C (Contracts)."
---

# /api-contract-first — Contract-First desde OpenAPI 3.1 (stubs, SDKs, mock, contract tests, docs, breaking-change)

Toma una spec **OpenAPI 3.1** (YAML/JSON existente, o generada desde una descripción en lenguaje natural)
y produce, de forma **independiente por output**: **server stubs** type-safe con validación de
request/response, **client SDKs** en los lenguajes target, un **mock server** (Prism) listo para
`docker-compose`, **contract tests** que verifican que el server cumple la spec (schemathesis o dredd),
y **docs** (Redoc HTML + Swagger UI). Si se provee una spec anterior, ejecuta una **fase explícita de
breaking-change check** con `oasdiff` y reporta cada cambio con severidad (`breaking` / `non-breaking`).

> **Contrato antes que código**: la spec OpenAPI es la ÚNICA fuente de verdad del contrato. Los stubs,
> los SDKs y el mock se DERIVAN de ella — nunca al revés. Un handler que diverge de la spec NO es "la spec
> desactualizada": es una violación de contrato que CASTLE C vigila. Por eso el breaking-change check es
> una fase de primera clase, no un extra opcional.

> **Path resolution**: Todos los paths son relativos al proyecto donde se invoca el skill (no a `KING_FRAMEWORK_PATH`).

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `.king/knowledge/stack.md` | Stack del servidor y lenguajes del proyecto — fuente del `server_stack` y los `client_langs` auto-detectados | Yes | project |
| `.king/knowledge/conventions.md` | Convenciones de naming de handlers, paquetes de SDK y rutas de output | No | project |
| `knowledge/_inject/api-design-essentials.md` | Heurísticas de diseño de API (métodos HTTP, status codes, versionado) que informan la validación de la spec y la severidad de breaking changes | No | framework |
| `knowledge/universal/api-design.md` | Base de conocimiento de diseño de APIs (custom: este skill aplica el versionado y los contratos de esta base para clasificar breaking vs non-breaking) | No | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No se provee `[spec-file]` ni una descripción en lenguaje natural para generar la spec
- [ ] El `[spec-file]` provisto no es OpenAPI 3.1 válido y NO pudo repararse/validarse en Phase 1
- [ ] Se pidió `--outputs sdks` pero no hay `--client-langs` ni stack resoluble para inferirlos
- [ ] Se pidió breaking-change check (`--compare-to`) pero el path a la spec anterior no existe

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA generar stubs/SDKs/mock desde una spec que NO pasó la validación de Phase 1 (spectral) — la spec inválida se repara o se aborta, jamás se propaga
- NUNCA sobrescribir la lógica de negocio existente en los handlers: los stubs generados son esqueletos (cuerpo `TODO`); si el handler ya existe, generar al lado o avisar, nunca pisar implementación
- NUNCA omitir la validación de request/response en los stubs — el stub sin validación rompe el propósito contract-first
- NUNCA degradar un cambio `breaking` a `non-breaking` en el reporte: la severidad la dicta `oasdiff`, no la conveniencia
- NUNCA incluir credenciales, tokens ni connection strings literales en el mock, los SDKs o el docker-compose — usar variables de entorno / `{{SLOT}}`
- NUNCA acoplar los outputs entre sí: cada uno (stubs, SDKs, mock, tests, docs, breaking) DEBE poder generarse solo
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión
> Cada output es CONDICIONAL a `--outputs`; solo es obligatorio el que se haya pedido. La validación (Phase 1) SIEMPRE corre.

- [ ] Spec OpenAPI 3.1 validada con spectral (reporte de lint con errores/warnings) — SIEMPRE
- [ ] Server stubs type-safe con validación request/response (si `--outputs` incluye `stubs`)
- [ ] Client SDKs type-safe en los `--client-langs` (si `--outputs` incluye `sdks`)
- [ ] Mock server (Prism) con servicio `docker-compose` listo para levantar (si `--outputs` incluye `mock`)
- [ ] Contract tests (schemathesis o dredd) que verifican el server contra la spec (si `--outputs` incluye `tests`)
- [ ] Docs: Redoc HTML + Swagger UI (si `--outputs` incluye `docs`)
- [ ] Breaking-change report con severidad por cambio (si se pasó `--compare-to`)
- [ ] Session document creado (via session-management Phase N+1)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase N+1 → Phase N+2
(Context)(Validate  (Gen      (Gen      (Gen mock (Gen      (Gen      (Breaking (Session)  (Guide)
          spec —     stubs)    SDKs)     Prism)    contract  docs      change
          spectral)                                tests)    Redoc)    check —
                                                                       oasdiff)
```
> Cada fase de generación (2–7) tiene su propio GATE IN sobre `--outputs`: si el output no fue pedido, la fase se SALTA en silencio. Solo Phase 1 (validate) es incondicional.

### PARÁMETROS
```
/api-contract-first [spec-file] [--outputs stubs,sdks,mock,tests,docs] [--server-stack <stack>] [--client-langs <l1,l2,...>] [--compare-to <prev-spec>]
```
- `[spec-file]`: path a la spec OpenAPI 3.1 (YAML/JSON). Si se omite, se genera la spec desde una descripción en lenguaje natural (NL) provista por el usuario
- `--outputs`: lista separada por comas de outputs a generar (`stubs,sdks,mock,tests,docs`). Default: `stubs,mock,tests`. Cada uno es independiente
- `--server-stack`: fuerza el stack del servidor para los stubs (ej. `ts-express`, `go-chi`, `python-fastapi`). Default: auto-detectado desde `.king/knowledge/stack.md`
- `--client-langs`: lenguajes target de los SDKs separados por comas (ej. `typescript,python,go`). Default: el mismo stack del proyecto
- `--compare-to`: path a la spec anterior. Activa la fase EXPLÍCITA de breaking-change check (Phase 7) con `oasdiff`

---

## CASTLE activo: C-_-_-T-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE C (Contracts) es la capa central: la spec OpenAPI ES el contrato, y este skill lo materializa y lo
> verifica. CASTLE T (Testing) cubre los contract tests generados. Veredicto CONDITIONAL si spectral reporta
> warnings o si el breaking-change check encuentra cambios `breaking` no versionados; BREACHED si se generan
> stubs desde una spec inválida o si un breaking change se publica sin bump de versión.

## Agentes
- **@architect** — Agente principal: valida que la spec respete los contratos de diseño de API (versionado, status codes), clasifica la severidad de los breaking changes y decide la estrategia de versionado
- **@developer** — Genera los stubs, SDKs, mock y la integración del docker-compose en el stack del proyecto
- **@qa** — Valida que los contract tests efectivamente fallen cuando el server diverge de la spec (test del contrato)

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0

---

## Phase 1: Validate Spec (spectral)

### GATE IN
- [ ] Se recibió `[spec-file]` o una descripción NL para generar la spec (BLOCKING CONDITION ya validó input)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver la spec** — si `[spec-file]` existe, cargarla; si no, generar una spec OpenAPI 3.1 a partir de la descripción NL del usuario y guardarla (ej. `openapi.yaml`)
2. [ ] **Confirmar versión OpenAPI 3.1** — verificar el campo `openapi: 3.1.x`. Si es 3.0.x, advertir y ofrecer migrar; si no es OpenAPI, abortar (BLOCKING CONDITION)
3. [ ] **Lint con spectral** — ejecutar `spectral lint <spec>` con el ruleset OpenAPI (o `.spectral.yaml` del proyecto si existe). Capturar errores y warnings
4. [ ] **Resolver `--outputs`** — parsear la lista pedida (default `stubs,mock,tests`) y marcar qué fases de generación (2–7) están activas
5. [ ] **Resolver `server_stack` y `client_langs`** — desde `--server-stack`/`--client-langs` si se pasaron; si no, inferirlos de `.king/knowledge/stack.md`

### CHECKPOINT
- [ ] La spec es OpenAPI 3.1 válida (o se reportaron los errores de spectral que la invalidan)
- [ ] `SPECTRAL_REPORT` capturado (errores + warnings, o "0 issues")
- [ ] `OUTPUTS_REQUESTED` resuelto (set de outputs a generar)
- [ ] `SERVER_STACK` y `CLIENT_LANGS` resueltos (o WARN si ambiguos)
- [ ] Si spectral reporta ERRORES (no solo warnings): NO continuar a generación hasta reparar o confirmar

### OUTPUTS
- Variables: `SPEC_PATH`, `SPECTRAL_REPORT`, `OUTPUTS_REQUESTED[]`, `SERVER_STACK`, `CLIENT_LANGS[]`, `COMPARE_TO`
- Artefacto: reporte de lint de spectral

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: La spec OpenAPI 3.1 no es válida.
Cause: errores de spectral (schema inválido, refs rotas), versión no 3.1, o tooling spectral ausente.
Recovery:
  [ ] Option A: mostrar los errores de spectral con línea/ruta y proponer la corrección concreta (refs, tipos, required); reintentar el lint
  [ ] Option B: si spectral no está instalado, documentar `npm i -g @stoplight/spectral-cli` y, mientras tanto, validar el schema OpenAPI 3.1 vía análisis estático LLM, marcando el resultado como tentativo
  [ ] Option C: si la spec no es reparable, abortar (BLOCKING CONDITION) y pedir al usuario una spec OpenAPI 3.1 válida o una descripción NL para regenerarla

---

## Phase 2: Generate Stubs (openapi-generator)

### GATE IN
- [ ] `stubs` ∈ `OUTPUTS_REQUESTED` (si no, SALTAR esta fase en silencio)
- [ ] Spec validada en Phase 1 sin errores bloqueantes

### MUST DO
1. [ ] **Resolver el generator del `SERVER_STACK`** — mapear a `openapi-generator-cli` (ej. `ts-express`→`typescript-node`/`nodejs-express-server`, `go-chi`→`go-server`, `python-fastapi`→`python-fastapi`)
2. [ ] **Generar los server stubs** — handlers vacíos con cuerpo `TODO`, tipos derivados de los schemas de la spec, y router/wiring por endpoint
3. [ ] **Inyectar validación request/response** — cada stub valida el request y el response contra el schema de la spec (middleware de validación o validación inline según stack)
4. [ ] **Preservar implementación existente** — si un handler ya existe con lógica, NO sobrescribir: generar al lado (`.generated`) o marcar el conflicto para revisión manual
5. [ ] **Aplicar convenciones** de `.king/knowledge/conventions.md` (naming de handlers y rutas de output) si existe

### CHECKPOINT
- [ ] 1 handler stub por operación de la spec, con tipos derivados del schema
- [ ] Cada stub valida request Y response contra el schema
- [ ] Ningún handler con lógica de negocio existente fue sobrescrito
- [ ] Los stubs compilan/parsean en el `SERVER_STACK` (chequeo de tipos básico)

### OUTPUTS
- Archivos: server stubs por endpoint + tipos + router (en el layout del `SERVER_STACK`)

### IF FAILS
ERROR: No se pudieron generar los server stubs.
Cause: `SERVER_STACK` sin generator en openapi-generator, o openapi-generator-cli ausente.
Recovery:
  [ ] Option A: listar los generators disponibles (`openapi-generator-cli list`) y elegir el más cercano al stack; reintentar
  [ ] Option B: si openapi-generator no está instalado, documentar la instalación (`npm i -g @openapitools/openapi-generator-cli`) y generar los stubs con un template propio del stack como fallback
  [ ] Option C: generar solo los tipos derivados de los schemas y dejar los handlers como TODO documentado, marcando la fase PARTIAL

---

## Phase 3: Generate SDKs (openapi-generator)

### GATE IN
- [ ] `sdks` ∈ `OUTPUTS_REQUESTED` (si no, SALTAR esta fase en silencio)
- [ ] `CLIENT_LANGS` resuelto y no vacío (BLOCKING CONDITION validó esto si se pidió `sdks`)

### MUST DO
1. [ ] **Generar un SDK por lenguaje de `CLIENT_LANGS`** — usar el client generator de `openapi-generator-cli` (ej. `typescript-axios`/`typescript-fetch`, `python`, `go`)
2. [ ] **Garantizar type-safety** — tipos/modelos derivados de los schemas, métodos por operación con firmas tipadas
3. [ ] **Sin secretos embebidos** — base URL y auth configurables por variable de entorno / parámetro de cliente, nunca hardcodeados
4. [ ] **Empaquetar cada SDK** en su carpeta con el manifiesto del lenguaje (`package.json` / `pyproject.toml` / `go.mod`) y un README de uso mínimo

### CHECKPOINT
- [ ] 1 SDK por cada lenguaje de `CLIENT_LANGS`, type-safe
- [ ] Cada SDK expone un método por operación de la spec
- [ ] Ningún secreto/base URL hardcodeado (configurable por env/param)
- [ ] Cada SDK empaquetado con su manifiesto y README

### OUTPUTS
- Archivos: un paquete SDK por lenguaje target

### IF FAILS
ERROR: No se pudo generar uno o más SDKs.
Cause: lenguaje sin client generator soportado, o nombre de lenguaje no reconocido.
Recovery:
  [ ] Option A: mapear el lenguaje al generator soportado más cercano (`typescript-fetch` vs `typescript-axios`) y reintentar
  [ ] Option B: generar los SDKs de los lenguajes que sí son soportados y reportar los no soportados como pendientes (PARTIAL)
  [ ] Option C: pedir al usuario el flavor exacto del generator por lenguaje (ej. `--client-langs typescript-axios`)

---

## Phase 4: Generate Mock (Prism)

### GATE IN
- [ ] `mock` ∈ `OUTPUTS_REQUESTED` (si no, SALTAR esta fase en silencio)
- [ ] Spec validada en Phase 1

### MUST DO
1. [ ] **Generar config de Prism** — `@stoplight/prism-cli` apuntando a la spec, con modo `mock` (responses derivados de examples/schemas) y validación de request activada
2. [ ] **Generar el servicio `docker-compose`** — un service `mock` que levanta Prism (`prism mock <spec>`), con puerto configurable vía variable de entorno (`{{MOCK_PORT}}`, no hardcodeado)
3. [ ] **Documentar el comando de arranque** — `docker compose up mock` (o `prism mock <spec>` standalone) y la URL base resultante
4. [ ] **Sin secretos** — ninguna credencial en el compose; usar `env_file`/variables

### CHECKPOINT
- [ ] Config de Prism generada y apuntando a la spec validada
- [ ] Servicio `mock` en `docker-compose` con puerto configurable (no hardcodeado)
- [ ] Comando de arranque y URL base documentados
- [ ] Ningún secreto literal en el compose

### OUTPUTS
- Archivos: config de Prism + servicio `docker-compose` (`mock`)

### IF FAILS
ERROR: No se pudo generar el mock server.
Cause: `@stoplight/prism-cli` ausente, o conflicto de puerto/servicio en el `docker-compose` existente.
Recovery:
  [ ] Option A: documentar `npm i -g @stoplight/prism-cli` y generar el compose igualmente (corre apenas Prism esté instalado)
  [ ] Option B: si ya existe `docker-compose.yml`, AÑADIR el service `mock` sin remover los existentes; resolver el puerto vía `{{MOCK_PORT}}`
  [ ] Option C: ofrecer el comando standalone (`prism mock <spec> --port {{MOCK_PORT}}`) como alternativa sin docker

---

## Phase 5: Generate Contract Tests (schemathesis / dredd)

### GATE IN
- [ ] `tests` ∈ `OUTPUTS_REQUESTED` (si no, SALTAR esta fase en silencio)
- [ ] Spec validada en Phase 1

### MUST DO
1. [ ] **Elegir el runner** — `schemathesis` (Python, property-based contra la spec) o `dredd` (Node, valida responses contra la spec); por defecto según el stack del proyecto
2. [ ] **Generar la suite de contract tests** — verifica que el server implementado CUMPLE la spec: status codes, schemas de response, headers requeridos. Target configurable (el server real o el mock de Phase 4) vía variable de entorno
3. [ ] **Garantizar que el test FALLA ante divergencia** — el test debe romperse si el server devuelve un response que no respeta el schema o un status no declarado. @qa valida la orientación del test
4. [ ] **Documentar el comando** — `schemathesis run <spec> --base-url $API_URL` o `dredd <spec> $API_URL`, e integrarlo al runner del proyecto (script npm `contract:test` / target make) si aplica

### CHECKPOINT
- [ ] Suite de contract tests generada con el runner elegido
- [ ] La suite verifica status codes + schemas de response contra la spec
- [ ] El test FALLA cuando el server diverge de la spec (orientación correcta)
- [ ] Target del test configurable por env (server real o mock), sin secretos literales

### OUTPUTS
- Archivos: suite de contract tests + entrada en el runner del proyecto

### IF FAILS
ERROR: No se pudieron generar los contract tests.
Cause: runner (schemathesis/dredd) ausente, o no hay base URL/target resoluble.
Recovery:
  [ ] Option A: documentar la instalación (`pip install schemathesis` / `npm i -D dredd`) y generar la suite + comando igualmente
  [ ] Option B: apuntar el target del test al mock de Phase 4 (`{{MOCK_PORT}}`) si no hay server real disponible, marcándolo en el README
  [ ] Option C: generar un subset mínimo de contract tests (1 por operación crítica) y marcar la fase PARTIAL

---

## Phase 6: Generate Docs (redocly)

### GATE IN
- [ ] `docs` ∈ `OUTPUTS_REQUESTED` (si no, SALTAR esta fase en silencio)
- [ ] Spec validada en Phase 1

### MUST DO
1. [ ] **Generar Redoc HTML** — `redocly build-docs <spec> -o <out>/index.html` (HTML estático autocontenido)
2. [ ] **Proveer Swagger UI** — referencia o assets de Swagger UI apuntando a la spec, para exploración interactiva
3. [ ] **Documentar el output** — ruta del HTML generado y cómo servirlo (estático o vía un script `docs:serve`)
4. [ ] **Sin secretos** — la doc no debe exponer tokens ni endpoints internos no declarados en la spec

### CHECKPOINT
- [ ] Redoc HTML generado y autocontenido
- [ ] Swagger UI disponible (assets o referencia) apuntando a la spec
- [ ] Ruta del output y forma de servirlo documentadas
- [ ] Ningún secreto en la doc generada

### OUTPUTS
- Archivos: Redoc HTML + Swagger UI

### IF FAILS
ERROR: No se pudo generar la documentación.
Cause: `redocly` (o `@redocly/cli`) ausente, o la spec referencia recursos externos inaccesibles.
Recovery:
  [ ] Option A: documentar `npm i -g @redocly/cli` y reintentar `redocly build-docs`
  [ ] Option B: si hay `$ref` externos inaccesibles, bundlear primero (`redocly bundle <spec> -o bundled.yaml`) y generar la doc desde el bundle
  [ ] Option C: generar Swagger UI standalone (HTML que carga la spec) como fallback si redocly no está disponible

---

## Phase 7: Breaking Change Check (oasdiff)

### GATE IN
- [ ] `COMPARE_TO` resuelto y la spec anterior existe (si no se pasó `--compare-to`, SALTAR esta fase en silencio)
- [ ] Spec nueva validada en Phase 1

### MUST DO
1. [ ] **Ejecutar `oasdiff breaking`** — comparar la spec anterior (`--compare-to`) contra la nueva: `oasdiff breaking <old> <new>`
2. [ ] **Clasificar cada cambio por severidad** — `breaking` (rompe clientes existentes: campo opcional→requerido, eliminación de endpoint/campo, cambio de tipo, status removido) vs `non-breaking` (campo agregado opcional, nuevo endpoint)
3. [ ] **Localizar cada cambio** — endpoint (método + ruta) y ruta del schema afectada (ej. `request.body.email`)
4. [ ] **Componer el breaking-change report** — tabla con severidad, ubicación y descripción `antes → después`. Si hay ≥1 `breaking`, recomendar bump de versión MAJOR y estrategia de versionado (path/header)
5. [ ] **Marcar el veredicto CASTLE C** — `breaking` no versionado = señal de BREACH; `breaking` con bump = CONDITIONAL; solo `non-breaking` = OK

### CHECKPOINT
- [ ] `oasdiff breaking` ejecutado entre old y new
- [ ] Cada cambio clasificado `breaking` / `non-breaking` (sin degradar severidad)
- [ ] Cada cambio localizado por endpoint + ruta de schema
- [ ] Reporte compuesto; si hay `breaking`, recomendación de versionado presente

### OUTPUTS
- Artefacto: breaking-change report (severidad + ubicación + antes→después)
- Variable: `HAS_BREAKING` (bool), `BREAKING_COUNT`

### IF FAILS
ERROR: No se pudo ejecutar el breaking-change check.
Cause: `oasdiff` ausente, spec anterior inválida, o specs no comparables (formatos distintos).
Recovery:
  [ ] Option A: documentar la instalación de `oasdiff` (`go install github.com/tufin/oasdiff@latest` / binario) y reintentar
  [ ] Option B: si la spec anterior es inválida, validarla primero con spectral; si no es OpenAPI 3.x comparable, reportar la incompatibilidad
  [ ] Option C: hacer un diff estructural LLM como fallback (schemas required, endpoints removidos) y marcar el reporte como tentativo (no autoritativo)

---

## FINAL CHECKPOINT

- [ ] Spec OpenAPI 3.1 validada con spectral (SIEMPRE) — reporte de lint capturado
- [ ] TODOS los outputs PEDIDOS en `--outputs` existen:
  - [ ] Server stubs con validación request/response (si `stubs`)
  - [ ] Client SDKs type-safe por lenguaje (si `sdks`)
  - [ ] Mock Prism + servicio docker-compose (si `mock`)
  - [ ] Contract tests con orientación correcta (si `tests`)
  - [ ] Docs Redoc + Swagger UI (si `docs`)
- [ ] Breaking-change report con severidad por cambio (si `--compare-to`)
- [ ] Ningún output se generó desde una spec inválida
- [ ] Ninguna severidad `breaking` fue degradada a `non-breaking`
- [ ] Ningún secreto / connection string literal en mock, SDKs, docker-compose o docs
- [ ] Ninguna versión de tooling / ruta absoluta / nombre de proyecto hardcodeado
- [ ] Session document creado en `.king/sessions/`

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(spec válida + outputs pedidos generados + sin breaking no versionado = FORTIFIED; warnings de spectral o breaking con bump de versión = CONDITIONAL; stubs desde spec inválida o breaking sin bump = BREACHED)_ |
| Artifacts | _(reporte spectral; stubs/SDKs/mock+compose/contract tests/docs según `--outputs`; breaking-change report si `--compare-to`)_ |
| Next Recommended | `/build` (implementar los stubs), `/contract-test` (correr la suite), o `/release` con bump MAJOR si hay breaking |
| Risks | _(warnings de spectral sin resolver; breaking changes detectados; tooling no instalado generado pero no ejecutado; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo Skill |
|-----------|---------------|
| Stubs generados, falta implementar handlers | `/build` — implementar la lógica de los stubs respetando el contrato |
| Contract tests generados | `/contract-test` o correr la suite contra el server/mock |
| Breaking changes detectados (`HAS_BREAKING`) | `/release` con bump MAJOR + estrategia de versionado, o revisar la spec para evitar el breaking |
| Mock levantado, falta consumirlo desde el front | `/frontend-design` (king-content, si king-content está instalado) o desarrollo del cliente contra el mock Prism |
| spectral reportó warnings | corregir la spec y re-`/api-contract-first <spec> --outputs ...` |
| Todo generado y validado | continuar; integrar el arch-test de contrato en `/review` (CASTLE C) |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Outputs independientes (matriz)

Cada output se genera por separado. Phase 1 (validate) SIEMPRE corre; Phase 7 (breaking) solo con `--compare-to`.

| Output | Fase | Flag `--outputs` | Tooling | Independiente |
|--------|------|------------------|---------|---------------|
| Validate spec | 1 | (siempre) | `spectral` | — (prerequisito) |
| Server stubs | 2 | `stubs` | `openapi-generator-cli` | Sí |
| Client SDKs | 3 | `sdks` | `openapi-generator-cli` | Sí |
| Mock server | 4 | `mock` | `@stoplight/prism-cli` | Sí |
| Contract tests | 5 | `tests` | `schemathesis` / `dredd` | Sí |
| Docs | 6 | `docs` | `redocly` (`@redocly/cli`) | Sí |
| Breaking check | 7 | `--compare-to` | `oasdiff` | Sí (fase explícita) |

> Ejemplos de uso independiente: `--outputs stubs` (solo stubs), `--outputs docs` (solo docs),
> `--compare-to old.yaml --outputs ""` (solo breaking-change check sobre la spec validada).

### Tooling por fase

| Herramienta | Rol | Instalación |
|-------------|-----|-------------|
| `spectral` (Stoplight) | Lint/validación de la spec OpenAPI 3.1 | `npm i -g @stoplight/spectral-cli` |
| `openapi-generator-cli` | Stubs de servidor y SDKs de cliente | `npm i -g @openapitools/openapi-generator-cli` |
| `@stoplight/prism-cli` | Mock server desde la spec | `npm i -g @stoplight/prism-cli` |
| `schemathesis` | Contract tests property-based (Python) | `pip install schemathesis` |
| `dredd` | Contract tests response-validation (Node) | `npm i -D dredd` |
| `redocly` (`@redocly/cli`) | Docs Redoc + bundle | `npm i -g @redocly/cli` |
| `oasdiff` | Detección de breaking changes | `go install github.com/tufin/oasdiff@latest` |

### Clasificación de breaking changes (oasdiff)

| Cambio | Severidad | Por qué |
|--------|-----------|---------|
| Campo de request `optional → required` | `breaking` | Clientes que no lo enviaban ahora fallan |
| Eliminación de endpoint o campo de response | `breaking` | Clientes que lo consumían se rompen |
| Cambio de tipo de un campo (`string → int`) | `breaking` | Deserialización del cliente falla |
| Status code declarado removido | `breaking` | Cliente deja de manejar ese caso |
| Restricción más estricta (`maxLength` menor, enum reducido) | `breaking` | Payloads antes válidos ahora se rechazan |
| Campo de response nuevo | `non-breaking` | Cliente lo ignora |
| Endpoint nuevo | `non-breaking` | No afecta a clientes existentes |
| Campo de request opcional nuevo | `non-breaking` | No obligatorio |

> La severidad la dicta `oasdiff`, NUNCA la conveniencia. Un `breaking` sin bump de versión MAJOR es una
> violación de contrato que CASTLE C marca como BREACH.

### Ejemplo de breaking-change report

```
Breaking Change Report — oasdiff (old.yaml → new.yaml)
======================================================
Total: 3 changes  |  BREAKING: 2  |  non-breaking: 1

[BREAKING]  POST /users — request.body.email
  optional → required
  Clientes que no enviaban `email` recibirán 400. Requiere bump MAJOR.

[BREAKING]  GET /orders/{id} — response.200.body.discount
  field removed (was: number)
  Clientes que leían `discount` obtendrán undefined. Requiere bump MAJOR.

[non-breaking]  GET /products — response.200.body.tags
  field added (string[])
  Aditivo; clientes existentes lo ignoran.

Recomendación: hay 2 breaking changes → versionar como MAJOR (v2)
y mantener v1 hasta la deprecación. Estrategia: versionado por path (/v2)
o por header (Accept-Version). Ver knowledge/universal/api-design.md (versionado).
```

### Integración con CASTLE C (Contracts)

`agents/architect.md` y la capa CASTLE C tratan la spec OpenAPI como el contrato autoritativo:
- Si el proyecto tiene una spec OpenAPI y se modifican handlers/controllers, CASTLE C verifica que los
  cambios NO rompan la spec (los contract tests de Phase 5 son el mecanismo).
- Si NO hay spec OpenAPI, CASTLE C emite WARNING "contrato implícito, considera /api-contract-first".
- Un breaking change detectado por `oasdiff` sin bump de versión es una señal de BREACH de CASTLE C.

Existe además un hook PostToolUse `api-change-check` (ADITIVO en `hooks/hooks.json`): si se modifica un
handler/controller y existe una spec OpenAPI, emite un WARNING de validar el contrato (enforcement: warn).

### Generación de spec desde lenguaje natural (sin spec-file)

Si no se pasa `[spec-file]`, el skill genera primero la spec OpenAPI 3.1 a partir de la descripción del
usuario (endpoints, schemas, status codes) y la valida con spectral en Phase 1 antes de cualquier
generación. La spec generada queda como artefacto (`openapi.yaml`) y se vuelve la fuente de verdad del resto.

### Relación con otros skills del arco M04

`/api-contract-first` materializa el contrato de la API (CASTLE C). Se complementa con `/contract-test`
(M05, correr/expandir la suite de contract tests), `/clean-arch-setup` (los stubs viven en la capa de
delivery/presentation), y `/explain-query` (king-infra, si king-infra está instalado — rendimiento de los handlers implementados). El delta spec
está en `openspec/changes/m04-architecture/specs/api-contract-first/spec.md`.
