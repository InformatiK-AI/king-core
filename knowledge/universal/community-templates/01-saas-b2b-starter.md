# Template: SaaS B2B

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial de la comunidad para arrancar un SaaS B2B multi-tenant de producción.
Define la especificación que `/genesis` consume al generar el proyecto: stack exacto,
skills King activos, estructura de carpetas, configuración CASTLE, pipeline CI/CD y las
decisiones de diseño con su rationale.

El SaaS B2B tiene una característica que lo distingue del B2C: **la unidad de cuenta no es
el usuario, es la organización (tenant)**. Todo el diseño de este template gira alrededor de
ese eje — aislamiento multi-tenant, autorización por roles dentro del tenant, y facturación
por suscripción a nivel de organización.

---

## Stack

| Capa | Tecnología | Versión | Rol |
|------|-----------|---------|-----|
| Framework | Next.js (App Router) | 15.x | Frontend + API routes + Server Actions |
| Lenguaje | TypeScript | 5.x (strict) | Type safety end-to-end |
| Base de datos | PostgreSQL (vía Supabase) | 16.x | Persistencia con Row Level Security |
| Backend-as-a-Service | Supabase | Auth + Postgres + Storage | Infra gestionada para MVP |
| Autenticación | Supabase Auth | — | Sesiones, OAuth, multi-tenant claims |
| Facturación | Stripe (Subscriptions + Billing) | API 2024-x | Suscripciones, planes, webhooks |
| Email transaccional | Resend | — | Invitaciones, recibos, password reset |
| ORM / Query | Drizzle ORM | 0.3x.x | Migraciones tipadas sobre Postgres |
| Validación | Zod | 3.x | Schemas de entrada y contratos de API |
| Deploy | Vercel | — | Preview por PR + producción en `main` |
| Tests unit/integración | Vitest | 2.x | Velocidad y compatibilidad con Vite |
| Tests E2E | Playwright | 1.4x.x | Flujos críticos multi-tenant |

> Las versiones mayores están fijadas; las menores siguen el último estable al momento de
> ejecutar `/genesis`. El template **no** mezcla App Router con Pages Router.

---

## Skills King pre-configurados

Activos por defecto en `.king/config.yaml` (sección `skills.enabled`):

| Skill | Origen | Para qué en un SaaS B2B |
|-------|--------|--------------------------|
| `/genesis` | king-core | Bootstrap inicial del proyecto desde este template |
| `/build` | king-core | Desarrollo guiado de features con quality gates |
| `/castle` | king-core | Evaluación de calidad C·A·S·T·L·E completa |
| `/promote` | king-infra | Promoción develop → qa → prod con worktrees |
| `/qa-env` | king-core | QA con smoke tests y environment parity |
| auth-scaffold | M6 (king-entrepreneur) | Scaffolding de login, registro, sesiones, OAuth |
| multi-tenancy enforcer | M7 | Garantiza aislamiento de datos por `tenant_id` |
| `/health-check` | king-infra | Endpoint de salud + verificación de readiness |
| `/deploy` | king-entrepreneur | Deploy a Vercel con credenciales vía CLI |

**CASTLE completo activo**: las seis capas C·A·S·T·L·E se evalúan en cada merge y promote.
No es opcional en este template — un SaaS B2B maneja datos de múltiples clientes y la
seguridad del aislamiento es un requisito de negocio, no una mejora.

**RBAC/ABAC pre-configurado**: el template incluye un modelo de roles (`owner`, `admin`,
`member`, `billing`) y políticas de atributo (`tenant_id` + `feature_flags` del plan) que
`auth-scaffold` y el `multi-tenancy enforcer` consumen para emitir guards en las API routes.

---

## Estructura de proyecto generada

```
saas-b2b-app/
├── .king/
│   ├── config.yaml              # skills habilitados + thresholds
│   ├── coverage.yaml            # gate de cobertura (global: 80)
│   └── castle/                  # reportes CASTLE generados
├── app/
│   ├── (auth)/                  # login, signup, reset (públicas)
│   ├── (app)/
│   │   ├── [tenant]/            # rutas scoped por organización
│   │   │   ├── dashboard/
│   │   │   ├── settings/
│   │   │   ├── members/         # invitaciones + gestión RBAC
│   │   │   └── billing/         # planes Stripe + portal
│   ├── api/
│   │   ├── webhooks/stripe/     # handler con verificación de firma
│   │   └── health/              # readiness probe
│   └── layout.tsx
├── lib/
│   ├── auth/                    # auth-scaffold: sesión + claims
│   ├── tenancy/                 # multi-tenancy enforcer: tenant guard
│   ├── authz/                   # RBAC/ABAC: roles + policies
│   ├── billing/                 # cliente Stripe + sync de suscripciones
│   └── email/                   # plantillas Resend
├── db/
│   ├── schema.ts                # Drizzle: tenants, users, memberships, subscriptions
│   ├── migrations/
│   └── rls/                     # políticas Row Level Security por tenant
├── tests/
│   ├── unit/
│   ├── integration/             # incluye test de aislamiento cross-tenant
│   └── e2e/                     # Playwright: signup → invite → billing
├── .github/workflows/
│   └── ci.yml                   # test + CASTLE + preview/prod deploy
├── drizzle.config.ts
├── vitest.config.ts
├── playwright.config.ts
└── package.json
```

La carpeta `lib/tenancy/` y la `db/rls/` son el corazón del template: **doble barrera de
aislamiento** — guard en la capa de aplicación y Row Level Security en Postgres. Si uno falla,
el otro contiene la fuga.

---

## CASTLE configuration

Todas las capas activas (`enforcement: block` salvo donde se indica):

| Capa | Activa | Gate específico para SaaS B2B |
|------|--------|-------------------------------|
| **C** — Contracts | Sí | Webhooks de Stripe validados con Zod; contratos de API tipados; firma de webhook verificada antes de procesar |
| **A** — Architecture | Sí | Frontera de tenancy verificada — ninguna query a `db/` sin pasar por `lib/tenancy/`; separación auth / authz / billing |
| **S** — Security | Sí | RLS obligatorio en toda tabla con `tenant_id`; secretos sólo vía env; test de aislamiento cross-tenant obligatorio en CI |
| **T** — Testing | Sí | Cobertura global mínima 80%; `lib/tenancy/` y `lib/authz/` con override a 95% en `.king/coverage.yaml` |
| **L** — Logging | Sí | Logs estructurados con `tenant_id` en cada evento; nunca PII de cliente en logs; audit trail de cambios de rol y billing |
| **E** — Environment | Sí | Paridad dev/qa/prod verificada por `/qa-env`; variables Stripe/Supabase/Resend documentadas en `.env.example` |

El gate de Testing eleva `lib/tenancy/` y `lib/authz/` a **95%** vía
`thresholds.per_package` — son los módulos donde un bug se traduce en un cliente viendo datos
de otro cliente. El resto del proyecto se mantiene en el 80% global para no penalizar glue code.

---

## CI/CD incluido

**Plataforma**: GitHub Actions + Vercel.

`.github/workflows/ci.yml` generado por defecto:

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test:unit       # Vitest unit + integration (incl. cross-tenant)
      - run: pnpm test:e2e         # Playwright flujos críticos
      - run: pnpm castle:check     # gate C·A·S·T·L·E completo

  preview-deploy:
    if: github.event_name == 'pull_request'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: vercel deploy --prebuilt           # preview por PR

  production-deploy:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: vercel deploy --prebuilt --prod     # producción en merge a main
```

**Flujo**: cada PR ejecuta test + E2E + CASTLE y publica un **preview deploy** aislado en
Vercel. El merge a `main` dispara el **deploy a producción**. El gate CASTLE bloquea el merge
si cualquiera de las seis capas falla.

**Tests incluidos**: Vitest (unit + integración, con un test obligatorio de aislamiento
cross-tenant) y Playwright (E2E del flujo signup → invitación de miembro → checkout de billing).
Cobertura mínima global del **80%**, con `lib/tenancy/` y `lib/authz/` al **95%**.

---

## Cómo usar

```
king-framework genesis --template saas-b2b-starter
```

## Decisiones de diseño

Cada elección está justificada por el contexto SaaS B2B, no por preferencia genérica:

- **Supabase sobre Prisma + RDS gestionado manualmente** — un SaaS B2B en fase MVP no debe
  gastar runway operando infra. Supabase entrega Postgres, Auth y Storage gestionados, y su
  **Row Level Security nativo es la pieza que materializa el aislamiento multi-tenant en la
  base de datos** sin escribir un proxy de autorización propio. El día que el escalado lo exija,
  Supabase es Postgres estándar y migra sin reescribir el modelo de datos.

- **App Router de Next.js 15 sobre Pages Router** — el App Router permite que las rutas
  `[tenant]/...` resuelvan el tenant en un layout server-side y propaguen los claims a Server
  Actions sin re-validar en cada componente. Es el estándar de Next.js 15 y la dirección donde
  va el ecosistema; arrancar en Pages Router sería nacer con deuda.

- **Stripe Subscriptions sobre cobros one-shot** — el modelo de negocio dominante en SaaS B2B
  es la suscripción recurrente con planes por asiento o por tier. Stripe Billing maneja
  prorrateo, trials, dunning y el customer portal de forma nativa; reimplementar ese ciclo de
  vida sería reinventar un sistema de cobros completo. El **webhook con verificación de firma
  obligatoria** evita que un actor falsifique eventos de pago.

- **Doble barrera de aislamiento (guard de aplicación + RLS en Postgres)** — en B2B una fuga
  cross-tenant no es un bug, es una brecha de confianza que puede terminar el contrato. Por eso
  el aislamiento no se confía a una sola capa: el `multi-tenancy enforcer` impone el guard en
  `lib/tenancy/` y las políticas RLS lo imponen en la base de datos. Defensa en profundidad.

- **RBAC + ABAC en lugar de roles planos** — un cliente B2B espera delegar administración:
  un `owner` invita `admin`s, los `admin`s gestionan `member`s, y un rol `billing` accede sólo
  a facturación. Eso es RBAC. Pero el acceso a features depende también del **plan contratado**
  (un atributo del tenant), y eso exige ABAC. El template combina ambos porque ningún SaaS B2B
  serio sobrevive con un único rol de "usuario".

- **Resend sobre SendGrid** — el email transaccional (invitaciones, recibos, reset) es crítico
  en el onboarding B2B. Resend ofrece mejor DX, SDK tipado en TypeScript y plantillas en React,
  alineándose con el resto del stack sin introducir un paradigma ajeno.

- **Drizzle ORM sobre el cliente raw de Supabase** — las migraciones tipadas y el schema en
  TypeScript dan trazabilidad del modelo multi-tenant (tablas con `tenant_id`, memberships,
  subscriptions) y permiten que el gate de Architecture verifique que ninguna query salta la
  frontera de tenancy. El cliente raw no da esas garantías de compilación.
