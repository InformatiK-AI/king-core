# Template: Marketplace

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial para construir un **marketplace two-sided** (plataforma que conecta oferta y demanda). El núcleo del dominio no es el CRUD de productos: es la **confianza entre dos partes que no se conocen** y el **movimiento de dinero entre ellas con una comisión para la plataforma**. Todo el stack se elige para resolver eso primero.

Dominios cubiertos por defecto: oferta/demanda (perfiles duales), pagos con split, ratings bidireccionales, búsqueda con faceting, y trust & safety.

## Stack

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Framework web | Next.js (App Router) | 15.x |
| Lenguaje | TypeScript (strict) | 5.x |
| Base de datos | PostgreSQL (Supabase) | 16 |
| Auth | Supabase Auth (roles `buyer` / `seller` / `admin`) | — |
| Pagos + split | Stripe Connect (Express accounts) | API 2024-06 |
| Búsqueda | Meilisearch (faceted + typo-tolerant) | 1.x |
| Cache / rate limit | Upstash Redis | — |
| Email transaccional | Resend | — |
| Almacenamiento | Supabase Storage (imágenes de listings) | — |
| Tests | Vitest (unit/integration) + Playwright (E2E) | — |
| Deploy | Vercel (web) + Supabase (datos) | — |

## Skills King pre-configurados

Activos por defecto en `.king/config`:

| Skill | Rol en el marketplace |
|-------|----------------------|
| `/genesis` | Genera la estructura inicial desde esta spec |
| `/build` | Desarrollo guiado de features (listings, checkout, ratings) |
| `payments-in-one-command` | Configura Stripe Connect con split y webhook firmado |
| `auth-in-one-command` | Auth con roles duales `buyer` / `seller` |
| `/deploy` | Deploy a Vercel + Supabase |
| `/promote` | Promoción develop → qa → prod |
| `/castle` | Evaluación de calidad con foco en S (trust & safety) |
| `/qa-env` | Smoke tests del flujo de pago en cada ambiente |

CASTLE completo activo (`C·A·S·T·L·E`), con énfasis reforzado en **S (Security)** y **C (Contracts)** por el manejo de dinero de terceros.

## Estructura de proyecto generada

```
marketplace/
├── .king/
│   ├── config.yaml
│   ├── coverage.yaml          # global 80, payments 95
│   └── castle/
├── app/
│   ├── (marketplace)/
│   │   ├── search/            # búsqueda con facets
│   │   ├── listings/[id]/     # detalle de oferta + ratings
│   │   └── checkout/          # flujo de pago con split
│   ├── (seller)/
│   │   ├── onboarding/        # Stripe Connect Express
│   │   ├── listings/          # CRUD de oferta
│   │   └── payouts/           # estado de transferencias
│   ├── (account)/
│   │   ├── orders/            # lado demanda
│   │   └── reviews/           # ratings bidireccionales
│   └── api/
│       └── webhooks/stripe/   # firma obligatoria
├── lib/
│   ├── payments/              # split, fees, refunds
│   ├── search/                # cliente Meilisearch + indexer
│   ├── trust/                 # moderación, reputación, fraude
│   └── ratings/
├── supabase/
│   ├── migrations/            # RLS por rol buyer/seller
│   └── seed.sql
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── .github/workflows/ci.yml
```

## CASTLE configuration

| Layer | Estado | Gate específico para marketplace |
|-------|--------|----------------------------------|
| **C** — Contracts | Activo (reforzado) | Schema validado del webhook de Stripe; contrato de eventos `order.*` y `payout.*` versionado |
| **A** — Architecture | Activo | Separación dura `lib/payments` ↔ UI; dinero nunca se calcula en el cliente |
| **S** — Security | Activo (reforzado) | RLS de Postgres por rol; webhook con verificación de firma obligatoria; secretos solo vía CLI/env, nunca en chat ni repo |
| **T** — Testing | Activo | Coverage global 80%, `lib/payments` 95% (override en `coverage.yaml`); E2E obligatorio del split |
| **L** — Logging | Activo | Audit trail inmutable de toda transacción (monto, fee, payout, refund) |
| **E** — Environment | Activo | Stripe en modo `test` en dev/qa; claves `live` solo en prod; parity check en `/qa-env` |

## CI/CD incluido

`.github/workflows/ci.yml` (GitHub Actions):

```yaml
name: CI
on: [pull_request, push]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint && pnpm typecheck
      - run: pnpm test --coverage        # falla si payments < 95%
      - run: pnpm test:e2e               # incluye split de pago en modo test
      - run: king-framework castle check # bloquea merge si S o T fallan
  preview:
    needs: quality
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - run: vercel deploy --prebuilt     # preview por PR
```

Deploy target: **Vercel** (web, preview por PR + prod en merge a `main`) + **Supabase** (migraciones aplicadas en el pipeline de promote). Webhooks de Stripe apuntan al dominio de cada ambiente.

## Cómo usar

```
king-framework genesis --template marketplace-starter
```

## Decisiones de diseño

- **Stripe Connect (Express) sobre Stripe estándar o pasarela propia** — un marketplace mueve dinero ENTRE terceros, no hacia la plataforma. Connect resuelve el split (comisión automática vía `application_fee_amount`), el onboarding KYC del seller, y los payouts, sin que la plataforma toque el dinero ni asuma carga regulatoria. Construir esto a mano implicaría licencias de dinero y cumplimiento PCI propio: inviable para un MVP.

- **Meilisearch sobre `LIKE`/`ILIKE` en Postgres o Elasticsearch** — la búsqueda es la puerta de entrada de la DEMANDA; sin faceting (precio, categoría, ubicación, rating) y tolerancia a typos, el lado comprador no encuentra oferta y el marketplace muere. `ILIKE` no escala ni hace ranking relevante. Elasticsearch resuelve lo mismo pero con un costo operativo desproporcionado para un starter; Meilisearch da relevancia y facets con configuración mínima.

- **Ratings bidireccionales como dominio de primera clase, no un campo más** — en un two-sided, la confianza fluye en ambas direcciones: el comprador califica al vendedor Y viceversa. Modelarlo en `lib/ratings` con su propia lógica (no un `stars int` colgado del listing) permite reputación agregada, ponderación por recencia y detección de reseñas falsas, que alimentan directamente trust & safety.

- **RLS de Postgres con roles duales sobre autorización solo en la capa de aplicación** — un seller jamás debe leer las órdenes de otro seller ni los datos de pago de un buyer. Empujar la autorización a la base de datos (Row Level Security por rol) hace que un bug en la capa de app no exponga datos de terceros: defensa en profundidad sobre el activo más sensible.

- **`lib/trust` separado desde el día uno** — trust & safety (moderación de listings, reputación, señales de fraude) no es una feature opcional que se agrega después: es lo que distingue un marketplace de un tablón de anuncios. Aislarlo como módulo propio evita que la lógica de fraude se disperse por el checkout y la búsqueda, y permite endurecerla sin tocar el flujo de venta.

- **Cálculo de montos y fees exclusivamente en el servidor (`lib/payments`)** — el precio, la comisión y el total NUNCA se calculan ni se confían desde el cliente. Cualquier importe que llega del navegador se trata como sugerencia y se recomputa en el backend antes de crear el PaymentIntent: previene manipulación de precios, el vector de ataque más obvio en un flujo de pago.
