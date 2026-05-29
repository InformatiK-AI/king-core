# CASTLE Spec v1.0 — Estándar Abierto de Quality Gates

## Introducción

CASTLE es un framework de quality gates para proyectos de software que define **6 capas de
verificación** con criterios objetivos, **contratos de veto bloqueante** y **mappings a estándares
de compliance internacionales** (SOC2 Type II, ISO 27001:2022, NIST 800-53).

CASTLE es independiente de framework, lenguaje o plataforma. Cualquier proyecto —en cualquier stack—
puede declararse CASTLE-Compliant si su pipeline verifica automáticamente las gates de las 6 capas.
Este documento es la **especificación formal v1.0**.

- **Acrónimo**: **C**ontracts · **A**rchitecture · **S**ecurity · **T**esting · **L**ogging &
  Observability · **E**nvironment.
- **Implementación de referencia**: King Framework (`https://github.com/king-framework/king-core`),
  versión v2.0 o superior.
- **Licencia del estándar**: CC BY 4.0 (el texto de la spec es libre de citar, traducir y adaptar
  con atribución).
- **Repositorio del estándar**: `https://github.com/castle-spec/castle-spec`.

### Principios de diseño

1. **Thresholds numéricos, no opiniones.** Cada métrica tiene un umbral medible por herramienta
   automática. No hay "código suficientemente bueno": hay un número y un comparador.
2. **Vetos binarios.** Cada capa define un *gate de veto*: una condición que se activa o no se
   activa, sin zona gris. Si se activa, la entrega se bloquea. No hay vetos "parciales".
3. **Verificable en CI.** Toda gate debe poder ejecutarse de forma desatendida en un pipeline.
   Si una gate requiere juicio humano para evaluarse, no es una gate CASTLE: es una guideline.
4. **Compliance trazable.** Cada gate puede mapearse a controles de estándares reconocidos, de
   modo que pasar CASTLE produce evidencia reutilizable para auditorías SOC2 / ISO / NIST.

### Cómo leer esta spec (RFC 2119)

Las palabras clave **MUST / SHALL**, **MUST NOT / SHALL NOT**, **SHOULD**, **SHOULD NOT** y **MAY**
se interpretan según RFC 2119:

- **MUST / SHALL**: requisito absoluto para declararse CASTLE-Compliant.
- **SHOULD**: recomendación fuerte; desviarse exige justificación documentada.
- **MAY**: opcional; no afecta la conformidad.

---

## Las 6 Capas

Cada capa define: (a) un conjunto de **métricas con threshold numérico** (mínimo 4 por capa), y
(b) un **gate de veto** con la condición binaria exacta que lo activa.

Convención de severidad de métrica:

- **HARD**: su violación dispara el gate de veto de la capa (bloqueo de entrega).
- **SOFT**: su violación genera advertencia, no bloquea por sí sola.

### C — Contracts

Criterios para verificar la corrección de los **contratos que el codebase expone** (APIs, schemas,
interfaces, eventos) y su evolución sin rupturas no versionadas.

| Métrica | Threshold | Severidad | Herramienta de ejemplo |
|---|---|---|---|
| API pública con schema/contrato declarado | 100 % de APIs con OpenAPI/AsyncAPI/protobuf | HARD | `spectral`, validación de schema |
| Contract tests para APIs con consumidores externos | ≥ 1 por consumidor | HARD | Pact, schemathesis |
| Breaking changes sin bump de versión MAJOR | 0 | HARD | `oasdiff`, `buf breaking` |
| api_version semver declarada en interfaces públicas | presente en cada API pública | HARD | inspección de manifest/spec |
| Validación de schema en requests/responses | 100 % de endpoints | SOFT | middleware de validación, `spectral` |
| Deprecaciones con período de aviso | conforme a `deprecation-policy` | SOFT | revisión de changelog/headers |

**Gate de veto (C)**: se activa si existe **≥ 1** breaking change sin bump de versión MAJOR **O**
**≥ 1** API pública sin contrato/schema declarado. Cualquiera de estas condiciones HARD bloquea la entrega.

### A — Architecture

Criterios para verificar que el diseño arquitectural es sostenible en el tiempo.

| Métrica | Threshold | Severidad | Herramienta de ejemplo |
|---|---|---|---|
| Dependency violations (ciclos) | 0 dependencias circulares | HARD | `dependency-cruiser`, `go-arch-lint`, `import-linter` |
| Layer violations | 0 llamadas cross-layer directas | HARD | tests de arquitectura |
| Interface segregation | ≤ 7 métodos por interface | SOFT | análisis estático |
| Package cohesion | responsabilidad única verificable por paquete | SOFT | revisión + métricas LCOM |
| API surface documentada | 100 % de API pública con OpenAPI/equivalente | SOFT | `spectral`, validación de schema |

**Gate de veto (A)**: se activa si existe **≥ 1** dependencia circular **O** **≥ 1** layer violation
(p. ej. `domain` importando `infrastructure` en arquitectura hexagonal). Veto inmediato.

### S — Security

Criterios de seguridad verificables automáticamente.

| Métrica | Threshold | Severidad | Herramienta de ejemplo |
|---|---|---|---|
| CVEs críticas en dependencias | 0 | HARD | `trivy`, `osv-scanner`, `npm audit` |
| Secrets hardcodeados | 0 | HARD | `gitleaks`, `trufflehog` |
| OWASP Top 10 issues | 0 | HARD | `semgrep`, SAST estático |
| Endpoints de auth sin TLS | 0 | HARD | validación de config / smoke test |
| SQL injection patterns | 0 | HARD | `semgrep`, análisis estático |

**Gate de veto (S)**: se activa si existe **≥ 1** secreto expuesto **O** **≥ 1** CVE de severidad
CRITICAL. Veto inmediato (la severidad MEDIUM/LOW de CVE es SOFT y no bloquea por sí sola).

### T — Testing

Criterios de estrategia de testing (pirámide de tests).

| Métrica | Threshold | Severidad | Herramienta de ejemplo |
|---|---|---|---|
| Unit test count | ≥ 1 por función pública no trivial | HARD | framework de unit testing del stack |
| Integration tests | ≥ 1 por integración externa (DB, API, queue) | HARD | testcontainers, mocks de integración |
| E2E tests | ≥ 1 por user journey crítico | SOFT | Playwright, Cypress, k6 |
| Test independence | 0 tests dependientes del orden de ejecución | HARD | ejecución con shuffle/random seed |
| Test determinism | 0 tests flaky en 10 ejecuciones consecutivas | HARD | runner con repetición |
| Contract tests | requeridos para APIs públicas con consumidores externos | HARD | Pact, schemathesis |

**Gate de veto (T)**: se activa si se detecta **flakiness** (≥ 1 test flaky en 10 corridas) **O**
**test order dependency** (un test cambia de resultado al reordenar la suite). Veto hasta corregir.

### L — Logging & Observability

Criterios de visibilidad operacional.

| Métrica | Threshold | Severidad | Herramienta de ejemplo |
|---|---|---|---|
| Structured logging | 100 % de logs en formato JSON estructurado | HARD | structlog, zap, pino |
| Trace propagation | 100 % de requests HTTP con trace ID | HARD | OpenTelemetry |
| Error logging con contexto | 100 % de errores con stack + request ID + user ID | HARD | middleware de errores |
| SLO definidos | ≥ latency p99 y error rate por servicio | SOFT | catálogo de SLO |
| Alerts configurados | ≥ 1 alert por SLO crítico | SOFT | Alertmanager, PagerDuty |
| Health endpoint | `/health` o equivalente en cada servicio | HARD | probe de liveness/readiness |

**Gate de veto (L)**: se activa si **NO** existe structured logging en producción (logs en texto
plano no parseable) **O** si falta el health endpoint en algún servicio desplegable. Veto inmediato.

### E — Environment

Criterios de correctitud de la configuración por ambiente, del despliegue y de la capacidad de
revertirlo (deploy, smoke tests, rollback).

| Métrica | Threshold | Severidad | Herramienta de ejemplo |
|---|---|---|---|
| Configuración externalizada (12-factor) | 0 valores de ambiente hardcodeados | HARD | revisión de config, `dotenv-linter` |
| Secrets fuera del código/repo | 0 secrets en config/repo | HARD | Vault, env vars, `gitleaks` |
| Smoke tests post-deploy | ≥ 1 por path crítico, 100 % PASS antes de promover | HARD | smoke suite en pipeline |
| Plan de rollback documentado y probado | presente y verificable por deployable | HARD | runbook + ensayo de rollback |
| Paridad de ambientes dev/staging/prod | verificada | SOFT | diff de config, IaC plan |
| Build/deploy reproducible (IaC) | infraestructura declarada como código | SOFT | Terraform, Pulumi, Helm |

**Gate de veto (E)**: se activa si existe **≥ 1** secret en config/repo de un ambiente **O** si un
smoke test post-deploy crítico falla **O** si un deployable no tiene plan de rollback verificable.
Veto inmediato.

> **Nota.** Las métricas de **performance** y **accessibility** son **gates complementarios** fuera
> de las 6 capas núcleo de CASTLE; no forman parte de la capa E.

### Resumen de gates de veto (referencia rápida)

| Capa | Condición binaria que activa el veto |
|---|---|
| **C** | ≥ 1 breaking change sin bump MAJOR · O · ≥ 1 API pública sin contrato/schema |
| **A** | ≥ 1 dependencia circular · O · ≥ 1 layer violation |
| **S** | ≥ 1 secreto expuesto · O · ≥ 1 CVE CRITICAL |
| **T** | ≥ 1 test flaky en 10 corridas · O · test order dependency |
| **L** | sin structured logging en prod · O · falta health endpoint |
| **E** | ≥ 1 secret en config/repo · O · smoke test post-deploy crítico falla · O · deployable sin rollback |

Cada condición es **binaria**: se activa o no se activa. No existen vetos "parciales" ni umbrales
de tolerancia. Un proyecto pasa CASTLE si **ninguno** de los 6 vetos está activo.

---

## Contratos Bilaterales

Un **contrato bilateral CASTLE** es un acuerdo entre dos componentes del sistema que especifica qué
CASTLE layers cada componente **garantiza** hacia el otro y qué layers **requiere** del otro. Permite
expresar, de forma verificable, las expectativas de calidad en una frontera de integración.

### Formato

```
Contrato: ComponenteA → ComponenteB
  Garantiza: <layers que A cumple y expone a B>
  Requiere:  <layers que A exige que B cumpla>
  Violación: <consecuencia binaria si el contrato no se satisface>
```

- **Garantiza**: lo que el componente origen promete al destino (su propio nivel CASTLE).
- **Requiere**: lo que el componente origen exige del destino para integrarse.
- **Violación**: la regla de veto del contrato. MUST ser binaria (bloquea integración / no bloquea).

Notación de gate dentro de un contrato: `Layer[gate específico]` — p. ej. `C[schema declarado]`,
`S[0 CVE]`, `T[contract-tests]`, `A[no circular]`, `L[structured-logs]`, `E[rollback-ready]`.

### Ejemplo 1 — servicio frontend que consume un API

```
Contrato: WebFrontend → OrdersAPI
  Garantiza: E[smoke-tests post-deploy], E[rollback-ready], C[contract-tests]
  Requiere:  S[0 CVE critical], S[TLS en auth], T[contract-tests], L[trace-id propagation]
  Violación: bloquea integración (el frontend no despliega contra una OrdersAPI sin contract-tests)
```

### Ejemplo 2 — microservicio que publica eventos a una cola

```
Contrato: PaymentsService → EventBus
  Garantiza: A[no circular], T[integration-tests por cola], L[structured-logs JSON]
  Requiere:  S[0 secrets], L[trace-id propagation], C[schema declarado]
  Violación: bloquea integración (no se conecta a un EventBus sin propagación de trace-id)
```

**Regla de composición**: un contrato `A → B` se satisface si y solo si las layers que A **Requiere**
están entre las layers que B **Garantiza**, y ninguna de las gates involucradas tiene su veto activo.
Si la condición no se cumple, la integración MUST bloquearse.

---

## Mappings de Compliance

> **Disclaimer (lea antes de usar estos mappings).** Estos mappings son **orientativos** y existen
> para facilitar la preparación de evidencia técnica. **NO constituyen una certificación regulada,
> ni asesoría legal, ni asesoría de compliance.** Pasar las gates CASTLE **no** equivale a obtener
> una certificación SOC2 Type II, ISO 27001 ni una autorización NIST. La conformidad formal con esos
> estándares requiere auditoría por una entidad acreditada y abarca controles organizativos y de
> proceso que CASTLE **no** evalúa (RR. HH., gestión de riesgos, continuidad de negocio, etc.).
> Antes de publicar la v1.0, los mappings SHOULD ser revisados por un auditor externo acreditado.

Cada fila de mapping incluye: **control ID** del estándar, **CASTLE Layer** que lo cubre y el
**gate específico** que produce la evidencia.

### SOC2 Type II → CASTLE

| Control SOC2 | CASTLE Layer | Gate específico |
|---|---|---|
| CC6.1 — Logical access controls | S | Endpoints de auth sin TLS: 0 |
| CC6.7 — Transmission encryption | S | TLS en todos los endpoints |
| CC7.1 — Detection of security events | L | Structured logging + alerts configurados |
| CC7.2 — Monitoring of system components | L | SLO definidos + health endpoints |
| CC8.1 — Change management | T + C | Coverage ≥ 80 % (T) + contract tests del cambio (C) |
| A1.1 — Capacity / availability management | L + E | SLO definidos (L) + smoke tests/health post-deploy (E) |

### ISO 27001:2022 → CASTLE

| Control ISO | CASTLE Layer | Gate específico |
|---|---|---|
| A.8.8 — Management of technical vulnerabilities | S | CVE scan en CI (0 CRITICAL) |
| A.8.25 — Secure development lifecycle | T + C | Coverage ≥ 80 % (T) + contract tests del cambio (C) |
| A.8.28 — Secure coding | S | SAST en CI (0 issues OWASP Top 10) |
| A.8.16 — Monitoring activities | L | Structured logs + trace propagation |
| A.5.37 — Documented operating procedures | A + E | API surface documentada (A) + runbooks de deploy/rollback (E) |
| A.12.1.2 (legado 2013) — Change management | T + C | Coverage ≥ 80 % (T) + contract tests del cambio (C) |

### NIST 800-53 → CASTLE

| Control NIST | CASTLE Layer | Gate específico |
|---|---|---|
| SI-2 — Flaw Remediation | S | CVEs críticas: 0 |
| SI-10 — Information Input Validation | S | SQL injection patterns: 0 + input validation |
| AU-2 — Event Logging | L | Structured logging (100 % JSON) |
| AU-9 — Protection of Audit Information | L | Error logging con contexto (request/user ID) |
| SA-11 — Developer Security Testing | T | Pirámide de tests + coverage ≥ 80 % |
| SC-28 — Protection of Information at Rest | S | Secrets management (0 secrets hardcodeados) |

Cada estándar mapea **≥ 5 controles** (SOC2: 6, ISO 27001:2022: 6, NIST 800-53: 6), todos con su
capa CASTLE y el gate que produce la evidencia automatizada.

---

## Certificaciones CASTLE

CASTLE distingue entre certificar **personas** (capaces de auditar con el estándar) y certificar
**proyectos** (que cumplen el estándar de forma automática y continua).

### CASTLE Certified Reviewer (personas)

- **Para**: auditores de calidad de software, arquitectos, tech leads.
- **Requisito**: examinar **3 o más** proyectos usando CASTLE y producir reports verificables
  (con el detalle de las 6 capas y el estado de cada gate de veto).
- **Badge**: "Certified to review projects against CASTLE Spec v1.0".

### CASTLE-Compliant Project (proyectos)

- **Para**: proyectos de software (no personas).
- **Requisito**: pipeline de CI que verifica **automáticamente** todas las gates de las 6 capas.
- **Badge**: "CASTLE-Compliant" — verificable vía `king-framework audit --castle-spec v1.0`.
- **Validez**: activa mientras el CI pase. Se **revoca automáticamente** si una gate de veto falla
  en producción. La certificación de un proyecto NO es un sello estático: es un estado vivo
  derivado del último pipeline verde.

---

## Implementaciones de Referencia

| Framework | Status | Repo |
|---|---|---|
| King Framework | Referencia (v2.0+) | `github.com/king-framework/king-core` |
| (Open) | Contribuciones bienvenidas | `github.com/castle-spec/implementations` |

Una implementación de referencia MUST ejecutar las 6 capas con thresholds numéricos y gates de veto
binarios, y SHOULD exponer un comando que produzca un report verificable por terceros.

---

## Governance del Estándar

El estándar CASTLE Spec es un proyecto open source bajo licencia **CC BY 4.0**, gobernado por un
**Technical Committee**.

### Composición del Technical Committee

Inicialmente: equipo King + **2 adopters externos**. Las decisiones sobre la spec se toman por
**supermayoría de 2/3** del comité.

### Proceso de cambios a la spec

Todo cambio a la especificación MUST seguir este proceso:

1. **RFC (Request for Comments)** abierta en `github.com/castle-spec/castle-spec`.
2. **Comment period de 60 días** — período mínimo durante el cual la comunidad revisa y comenta la
   RFC. Una RFC NO puede aprobarse antes de que transcurran los 60 días.
3. **Aprobación de 2/3 del Technical Committee** (supermayoría). Una mayoría simple NO es suficiente.
4. **Bump de versión** de la spec según el tipo de cambio (`CASTLE Spec v1.1`, `v2.0`, etc.).

### Retrocompatibilidad por MAJOR version

La retrocompatibilidad se garantiza **explícitamente** por versión MAJOR:

- Un proyecto **CASTLE v1.0-compliant** pasa la auditoría de **cualquier** spec con el **mismo MAJOR
  version** (v1.0, v1.1, v1.2, …). Es decir, los cambios dentro de un MAJOR nunca rompen un proyecto
  ya conforme.
- Los cambios **MINOR** (v1.0 → v1.1) **solo añaden gates opcionales** (severidad SOFT o gates que
  requieren opt-in). MUST NOT endurecer un threshold existente ni convertir una métrica SOFT en HARD.
- Solo un cambio **MAJOR** (v1.0 → v2.0) puede endurecer thresholds, promover métricas SOFT a HARD,
  o añadir gates de veto nuevos. Un MAJOR PUEDE romper la conformidad de proyectos previos, por lo
  que MUST documentar la ruta de migración.

### Versionado de la spec (SemVer aplicado al estándar)

| Bump | Qué cambia | ¿Rompe conformidad previa? |
|---|---|---|
| PATCH (v1.0.0 → v1.0.1) | Correcciones de redacción, aclaraciones, ejemplos | No |
| MINOR (v1.0 → v1.1) | Gates opcionales nuevos (SOFT / opt-in) | No |
| MAJOR (v1.0 → v2.0) | Thresholds más estrictos, SOFT→HARD, vetos nuevos | Posible (con guía de migración) |

---

## Apéndice — Glosario

- **Gate**: verificación automática de una métrica contra su threshold.
- **Gate de veto**: condición binaria por capa que, si se activa, bloquea la entrega.
- **HARD / SOFT**: severidad de una métrica; HARD dispara veto, SOFT solo advierte.
- **Contrato bilateral**: acuerdo verificable de garantías/requisitos CASTLE entre dos componentes.
- **CASTLE-Compliant Project**: proyecto cuyo CI verifica las 6 capas y mantiene los 6 vetos inactivos.
- **Technical Committee**: órgano de governance que aprueba cambios a la spec por 2/3.

## Ver también

- `knowledge/universal/coverage-gate.md` — implementación de la capa **T** (coverage) en King.
- `knowledge/universal/performance-budget.md` — gate complementario de performance (fuera de las 6 capas CASTLE núcleo).
- `knowledge/universal/observability.md` — base de la capa **L** (logging & observability).
- `knowledge/universal/king-hub-spec.md` — campo `castle_layers` del manifest y verificación en el hub.
- `skills/castle/` — implementación de referencia de la evaluación de las 6 capas en King Framework.
