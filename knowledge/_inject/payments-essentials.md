---
inject: payments-essentials
version: 1.0
scope: universal
---

# Payments Essentials — Reglas de Seguridad

## Reglas Absolutas

**Secrets**: NUNCA pedir STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET ni equivalentes Lemonsqueezy en el chat. Solo generar `.env.example` con placeholders `KEY=REPLACE_WITH_YOUR_VALUE`. El usuario los configura manualmente en `.env`.

**Webhook validation**: Todo handler de webhook DEBE verificar firma antes de procesar. Sin verificación = vector de fraude inmediato.
- Stripe: `stripe.webhooks.constructEvent(payload, sig, process.env.STRIPE_WEBHOOK_SECRET)`
- Lemonsqueezy: HMAC-SHA256 con `process.env.LEMONSQUEEZY_WEBHOOK_SECRET`

**Idempotency**: Stripe soporta `Idempotency-Key` header. Usar para operaciones críticas (checkout, refund). Lemonsqueezy: idempotencia via `event_id` del webhook.

**Checkout flow**: Nunca procesar pago server-side sin verificar estado en Stripe/LS API primero. El frontend es mentiroso.

## Stripe — Patrones Clave

```
Init: new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2023-10-16' })
Checkout: stripe.checkout.sessions.create({ ... })
Customer portal: stripe.billingPortal.sessions.create({ ... })
Webhook: stripe.webhooks.constructEvent(body, sig, secret) → en endpoint POST /webhooks/stripe
```

**Env vars requeridas**:
```
STRIPE_SECRET_KEY=sk_live_REPLACE_WITH_YOUR_VALUE
STRIPE_PUBLISHABLE_KEY=pk_live_REPLACE_WITH_YOUR_VALUE
STRIPE_WEBHOOK_SECRET=whsec_REPLACE_WITH_YOUR_VALUE
```

## Lemonsqueezy — Patrones Clave

```
Init: lemonSqueezySetup({ apiKey: process.env.LEMONSQUEEZY_API_KEY })
Checkout: createCheckout(storeId, variantId, { ... })
Webhook: verificar HMAC-SHA256(body, secret) === X-Signature header
```

**Env vars requeridas**:
```
LEMONSQUEEZY_API_KEY=REPLACE_WITH_YOUR_VALUE
LEMONSQUEEZY_WEBHOOK_SECRET=REPLACE_WITH_YOUR_VALUE
LEMONSQUEEZY_STORE_ID=REPLACE_WITH_YOUR_VALUE
```

## Checks S-PAY (CASTLE capa S)

- S-PAY-1: Sin secrets hardcodeados — BLOQUEANTE
- S-PAY-2: Webhook handler tiene verificación de firma — BLOQUEANTE
- S-PAY-3: `.env.example` solo tiene placeholders, sin valores reales — BLOQUEANTE
- S-PAY-4: Idempotency key usado en operaciones mutantes (checkout, refund) — WARNING
- S-PAY-5: Estado verificado en API antes de dar acceso — WARNING HIGH
