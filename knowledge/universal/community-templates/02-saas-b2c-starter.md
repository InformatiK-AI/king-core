# Template: SaaS B2C

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Spec oficial del template **SaaS B2C** (community-templates 02). Describe el stack exacto, los skills King pre-configurados, la estructura que `/genesis` produce y la configuración de calidad. No es código: es la especificación que `/genesis` consume para generar un proyecto SaaS orientado a consumidor final.

El SaaS B2C se distingue del B2B (template 01) en cinco ejes: **autenticación social** (no SSO corporativo), **onboarding de bajo fricción** (activación en segundos), **suscripciones self-service** (no contratos de ventas), **analytics de producto** (no dashboards de cuenta) y **escalabilidad horizontal** desde el día uno (picos de tráfico virales, no crecimiento lineal de cuentas).

---

## Stack

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Framework | Next.js (App Router) | 15.x |
| Runtime | Node.js | 22 LTS |
| Lenguaje | TypeScript (strict) | 5.x |
| Auth | Clerk (social-first: Google, Apple, GitHub) | última estable |
| Base de datos | PostgreSQL gestionado (Neon, serverless) | 16 |
| ORM | Drizzle ORM | última estable |
| Suscripciones | Stripe (Checkout + Customer Portal + Billing) | API 2024+ |
| Email transaccional | Resend | última estable |
| Product analytics | PostHog (cloud o self-host) | última estable |
| Cache / rate-limit | Upstash Redis (serverless) | última estable |
| UI | Tailwind CSS + shadcn/ui | 4.x / última |
| Deploy | Vercel (edge + serverless functions) | — |
| Tests | Vitest (unit/integration) + Playwright (E2E) | última estable |

---

## Skills King pre-configurados

Activos por defecto en `.king/config` al generar el proyecto:

| Skill | Rol en este template |
|-------|----------------------|
| `/genesis` | Generación inicial del scaffold |
| `/build` | Desarrollo de features con workflow guiado |
| `/deploy` | Deploy a Vercel con credenciales vía CLI |
| `/promote` | Promoción develop → qa → prod entre worktrees |
| `auth-in-one-command` | Auth social pre-configurada (Clerk) |
| `payments-in-one-command` | Suscripciones Stripe self-service |
| `landing-page-generate` | Landing con conversion optimization (B2C es adquisición masiva) |
| `/frontend-design` | UI de alto impacto para captar y retener consumidores |
| `/observe` (M06) | Product analytics + observabilidad de runtime |
| `/audit` | Health Score del framework instalado |
| CASTLE completo | C·A·S·T·L·E activo (ver sección CASTLE) |

---

## Estructura de proyecto generada

```
mi-saas-b2c/
├── .king/
│   ├── config.yaml              # skills activos + stack detectado
│   ├── coverage.yaml            # umbral 80% global
│   └── castle/                  # reportes de gates
├── app/
│   ├── (marketing)/             # landing pública, SEO, pricing
│   │   ├── page.tsx
│   │   └── pricing/page.tsx
│   ├── (auth)/                  # sign-in / sign-up social
│   │   ├── sign-in/[[...rest]]/page.tsx
│   │   └── sign-up/[[...rest]]/page.tsx
│   ├── (app)/                   # área autenticada
│   │   ├── onboarding/page.tsx  # flujo de activación multi-paso
│   │   ├── dashboard/page.tsx
│   │   └── settings/billing/page.tsx  # Stripe Customer Portal
│   ├── api/
│   │   ├── webhooks/stripe/route.ts   # webhook firmado (obligatorio)
│   │   └── webhooks/clerk/route.ts    # sync de usuarios
│   └── layout.tsx               # PostHog provider + analytics
├── lib/
│   ├── db/
│   │   ├── schema.ts            # Drizzle: users, subscriptions, events
│   │   └── client.ts
│   ├── stripe/                  # cliente + helpers de billing
│   ├── analytics/               # eventos de producto tipados
│   └── rate-limit.ts            # Upstash Redis
├── components/
│   ├── ui/                      # shadcn/ui
│   └── onboarding/              # pasos de activación reutilizables
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/                     # signup → onboarding → checkout
├── .github/workflows/ci.yml
├── drizzle.config.ts
└── package.json
```

---

## CASTLE configuration

Las 6 dimensiones activas, con énfasis específico para B2C:

| Layer | Estado | Gate específico |
|-------|--------|-----------------|
| **C** — Contracts | Activo | Webhook de Stripe con verificación de firma OBLIGATORIA; schema de eventos de analytics tipado |
| **A** — Architecture | Activo | Separación marketing / auth / app por route groups; lógica de billing aislada en `lib/stripe` |
| **S** — Security | Activo (reforzado) | Rate-limiting en endpoints públicos (anti-abuso B2C); secrets solo vía env; CSP headers en landing |
| **T** — Testing | Activo | Coverage global ≥ 80%; E2E obligatorio del funnel signup → onboarding → checkout |
| **L** — Logging | Activo | Eventos de producto en PostHog + logs estructurados; trazas del webhook de pagos |
| **E** — Environment | Activo | Paridad dev/qa/prod; deploy preview por PR; variables Stripe en modo test fuera de prod |

Refuerzo B2C: **S** sube de prioridad respecto a B2B porque la superficie pública (signup abierto, sin invitación) expone el sistema a abuso, bots y fraude de tarjetas. El rate-limiting con Upstash y la verificación de firma de webhooks no son opcionales.

---

## CI/CD incluido

Plataforma target: **Vercel**. Workflow `.github/workflows/ci.yml` generado por defecto:

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck          # tsc --noEmit
      - run: pnpm lint
      - run: pnpm test --coverage     # Vitest, gate 80%
      - run: pnpm test:e2e            # Playwright funnel completo
      - run: pnpm castle:check        # CASTLE aggregate ≥ umbral

  preview:
    needs: quality
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - run: vercel deploy --token=${{ secrets.VERCEL_TOKEN }}   # preview por PR

  production:
    needs: quality
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: vercel deploy --prod --token=${{ secrets.VERCEL_TOKEN }}
```

Flujo: cada PR ejecuta calidad + deploy preview; el merge a `main` despliega a producción. CASTLE bloquea el merge si algún gate falla.

---

## Cómo usar

```
king-framework genesis --template saas-b2c-starter
```

## Decisiones de diseño

Cada elección responde a una característica estructural del modelo B2C, no a preferencia genérica:

- **Clerk sobre Supabase Auth o NextAuth** — el B2C vive de la **adquisición masiva con baja fricción**. Clerk entrega login social (Google/Apple/GitHub) con UI lista, manejo de sesiones y MFA sin construir flujos a mano. Apple Sign-In es obligatorio en iOS para apps que ofrecen otros logins sociales, y Clerk lo cubre out-of-the-box; NextAuth exigiría cablear cada proveedor manualmente.

- **Neon (Postgres serverless) sobre RDS o un Postgres fijo** — el tráfico B2C es **espinoso e impredecible** (efecto viral, campañas, picos nocturnos). Neon escala a cero en reposo y separa cómputo de almacenamiento, evitando pagar una instancia provisionada 24/7 para un MVP cuyo tráfico aún no es predecible. RDS tiene sentido cuando la carga es estable y conocida; aquí no lo es.

- **Stripe Checkout + Customer Portal sobre integración manual de Billing** — el B2C es **100% self-service**: no hay equipo de ventas que negocie contratos. El cliente se suscribe, cambia de plan, actualiza tarjeta y cancela solo. El Customer Portal de Stripe entrega toda esa gestión de suscripción sin construir pantallas de billing propias, reduciendo superficie de bugs en el flujo más sensible (el que cobra).

- **PostHog sobre Google Analytics o un wrapper propio** — en B2C el producto se optimiza por **comportamiento de uso**, no por cuentas. PostHog combina product analytics, funnels, session replay y feature flags en una sola herramienta, permitiendo medir activación (onboarding) y retención sin integrar tres servicios distintos. GA está orientado a marketing web, no a analítica de producto in-app.

- **Upstash Redis para rate-limiting desde el día uno** — el signup abierto de un B2C es un **vector de abuso**: bots, fraude de tarjetas, scraping. El rate-limiting serverless protege endpoints públicos sin operar un Redis propio, y encaja con el modelo edge de Vercel (conexión HTTP, no TCP persistente). Postergarlo a "cuando crezcamos" es deuda de seguridad que se paga con incidentes.

- **App Router + route groups sobre Pages Router** — la separación física de **marketing público** (SEO, indexable), **auth** y **app autenticada** mediante route groups deja explícita la frontera de seguridad y permite estrategias de rendering distintas (estático en landing, dinámico en dashboard). Es el estándar de Next.js 15 y habilita Server Components para reducir JS enviado al cliente, clave para la conversión en landing.
