# Template: API-only

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Spec oficial del starter **API-only**: un backend HTTP sin frontend, diseñado
contract-first (OpenAPI como fuente de verdad), con versionado de API explícito,
rate-limiting de fábrica y observability instrumentada desde el primer endpoint.
Es la base para microservicios, BFFs y APIs públicas que terceros consumen.

`/genesis` consume esta spec para saber qué generar cuando se elige `--template api-only`.

---

## Stack

| Capa | Tecnología | Versión | Por qué |
|---|---|---|---|
| Runtime | Node.js | 22 LTS | LTS con soporte hasta 2027; `fetch` y test runner nativos. |
| Lenguaje | TypeScript | 5.x (strict) | Tipos derivados del contrato OpenAPI eliminan drift spec↔código. |
| Framework HTTP | Fastify | 5.x | Throughput superior a Express y validación JSON Schema nativa (alineada con OpenAPI). |
| Contrato | OpenAPI | 3.1 | Fuente de verdad; 3.1 es superset de JSON Schema, reusable por el validador de Fastify. |
| Generación de tipos | `openapi-typescript` + `fastify-type-provider` | última | Tipos de request/response generados desde el `.yaml`, no escritos a mano. |
| Validación runtime | Ajv (vía Fastify) | 8.x | Valida payloads contra el schema del contrato en cada request. |
| Rate-limiting | `@fastify/rate-limit` + Redis | 9.x / 7.x | Límites por API key con store distribuido para escalar horizontalmente. |
| Observability | OpenTelemetry SDK + Pino | última / 9.x | Trazas y métricas OTLP; logs JSON estructurados correlacionados por `trace_id`. |
| Documentación | `@fastify/swagger` + Scalar UI | última | Sirve el contrato como UI interactiva en `/docs` sin build de frontend. |
| Persistencia | PostgreSQL + Drizzle ORM | 16 / última | SQL tipado, migraciones versionadas; sin generación de cliente pesado. |
| Deploy target | Contenedor OCI sobre Fly.io | — | Multi-región con bajo overhead; `Dockerfile` portable a cualquier orquestador. |

> No incluye framework de frontend, bundler de UI ni assets estáticos: es deliberadamente
> headless. El único "front" es la doc OpenAPI servida en `/docs`.

---

## Skills King pre-configurados

Activos por defecto en `.king/config.yaml`:

| Skill | Rol en este template |
|---|---|
| `/genesis` | Bootstrap inicial del proyecto desde esta spec. |
| `/build` | Workflow de feature (endpoint nuevo → contrato → handler → test). |
| `/castle` | Evaluación de calidad; aquí con énfasis en **C** (contratos) y **L** (logging). |
| `/promote` | Promoción develop → qa → prod por worktree. |
| `/observe` (M06) | Instrumentación OpenTelemetry y verificación de SLOs. |
| `/slo-define` (M06) | Define SLOs de latencia/error-rate por endpoint. |
| `/contract-test` (M05) | Verifica que la implementación cumple el contrato OpenAPI. |
| `/api-version-check` | Bloquea cambios breaking sin bump de versión (ver Decisiones). |

CASTLE completo activo: **C·A·S·T·L·E**, con peso reforzado en Contracts y Logging.

---

## Estructura de proyecto generada

```text
api-only/
├── openapi/
│   ├── openapi.yaml            # Contrato — FUENTE DE VERDAD. Se edita primero.
│   └── components/             # Schemas, parámetros y responses reutilizables
├── src/
│   ├── server.ts               # Bootstrap Fastify + plugins (swagger, rate-limit, otel)
│   ├── plugins/
│   │   ├── observability.ts    # OpenTelemetry SDK + Pino con trace_id
│   │   ├── rate-limit.ts       # @fastify/rate-limit con store Redis
│   │   └── versioning.ts       # Routing por versión (/v1, /v2)
│   ├── routes/
│   │   └── v1/                 # Handlers de la versión 1; tipos derivados del contrato
│   ├── generated/
│   │   └── api-types.ts        # Generado por openapi-typescript (NO editar a mano)
│   ├── db/
│   │   ├── schema.ts           # Tablas Drizzle
│   │   └── migrations/         # Migraciones versionadas
│   └── lib/                    # Errores tipados, paginación, helpers de respuesta
├── tests/
│   ├── contract/               # Implementación vs openapi.yaml
│   ├── integration/            # Endpoints contra Postgres+Redis efímeros (testcontainers)
│   └── unit/                   # Lógica de dominio aislada
├── .king/
│   ├── config.yaml             # Skills activos + CASTLE
│   ├── coverage.yaml           # Umbrales de cobertura
│   └── slo.yaml                # SLOs por endpoint (latencia p95, error budget)
├── Dockerfile                  # Imagen OCI multi-stage
├── fly.toml                    # Config de deploy Fly.io
├── docker-compose.yml          # Postgres + Redis para desarrollo local
└── .github/workflows/ci.yml    # Pipeline CI/CD
```

---

## CASTLE configuration

| Layer | Estado | Gate específico en este template |
|---|---|---|
| **C** — Contracts | Reforzado | El build falla si `src/generated/api-types.ts` no coincide con `openapi.yaml`. Cada endpoint debe estar declarado en el contrato antes de implementarse. |
| **A** — Architecture | Activo | Separación routes → lib (dominio) → db. Los handlers no acceden a Drizzle directamente. |
| **S** — Security | Activo | Rate-limit obligatorio en todas las rutas; cabeceras de seguridad; sin secretos en código (validación de env al boot). |
| **T** — Testing | Activo | Cobertura mínima **85%**; suite de contract tests obligatoria (no se puede mergear sin ella). |
| **L** — Logging | Reforzado | Logs JSON estructurados con `trace_id` en cada request; spans OTLP exportados. Sin `console.log` (gate lo bloquea). |
| **E** — Environment | Activo | Paridad dev/prod vía contenedor; `docker-compose` replica Postgres+Redis de prod. Validación de variables de entorno al arranque. |

`.king/coverage.yaml`: `thresholds.global: 85`, `enforcement: block`.
`.king/slo.yaml`: latencia p95 < 200 ms, error budget 0.1% por endpoint.

---

## CI/CD incluido

Plataforma: **GitHub Actions** → deploy en **Fly.io**.

Pipeline (`.github/workflows/ci.yml`) por PR:

1. **lint + typecheck** — Biome + `tsc --noEmit`.
2. **contract-check** — regenera tipos desde `openapi.yaml` y falla si hay diff (drift).
3. **test** — unit + integration (Postgres+Redis efímeros vía service containers) + contract tests, con gate de cobertura 85%.
4. **castle-check** — evaluación CASTLE; bloquea si C, T o L fallan.
5. **api-version-check** — diff del contrato contra `main`; si hay cambio breaking sin bump de versión, falla.
6. **build-image** — construye imagen OCI multi-stage y la publica al registry.

En merge a `main`: deploy automático a producción en Fly.io con migraciones aplicadas
en un release-command previo al swap de instancias (zero-downtime).

---

## Cómo usar

```
king-framework genesis --template api-only-starter
```

## Decisiones de diseño

- **Contract-first con OpenAPI 3.1 como fuente de verdad** — el `.yaml` se edita ANTES
  que el código y los tipos se generan desde él. Esto elimina el drift spec↔implementación,
  que es el bug crónico de las APIs documentadas a mano. 3.1 sobre 3.0 porque es superset
  de JSON Schema y Fastify lo valida en runtime sin traducción.

- **Fastify sobre Express** — para una API pura el throughput y la validación JSON Schema
  nativa importan más que el ecosistema de middleware de Express. Fastify duplica
  peticiones/seg en benchmarks y su type-provider conecta directo con los tipos del contrato.

- **Versionado por path (`/v1`, `/v2`) y no por header** — el versionado en la URL es
  explícito, cacheable y trivial de enrutar. El gate `api-version-check` impide publicar
  cambios breaking sin una versión nueva, garantizando el runway de la deprecation-policy
  a los consumidores externos.

- **Rate-limiting con store Redis, no en memoria** — un límite en memoria miente en cuanto
  hay más de una instancia. Redis hace que el límite sea real bajo escalado horizontal, que
  es el escenario por defecto de una API que terceros consumen.

- **Observability desde el primer endpoint, no como retrofit** — OpenTelemetry + Pino con
  `trace_id` correlacionado se instalan en el bootstrap. Una API sin trazas es una caja negra
  en producción; instrumentar después siempre cuesta más y deja huecos. Por eso L es layer
  reforzado en CASTLE.

- **Sin frontend, intencionalmente** — la única UI es la doc OpenAPI servida en `/docs`.
  Mantener el template headless evita arrastrar un bundler, build de assets y dependencias de
  UI que un servicio de API no necesita y que diluirían su responsabilidad única.
