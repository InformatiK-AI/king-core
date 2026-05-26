# Headless CMS Essentials (para inyección en /build)

> Inyectar cuando el skill involucra integración con Contentful, Sanity, Strapi u otros CMS headless.

---

## Regla fundamental: NUNCA llamar al CMS desde el cliente con tokens

Todo acceso a APIs de CMS con tokens de autenticación DEBE ir a través de:
- Server Components (Next.js App Router)
- API Routes / Route Handlers del servidor
- Endpoints SSR (Astro, Nuxt)

**NUNCA** usar prefijo `NEXT_PUBLIC_` para tokens de CMS — expone las credenciales en el bundle público.

---

## Variables de entorno por CMS

```bash
# === Contentful ===
CONTENTFUL_SPACE_ID=your-space-id-here
CONTENTFUL_ACCESS_TOKEN=your-delivery-api-token  # Lectura de contenido publicado
CONTENTFUL_PREVIEW_TOKEN=your-preview-api-token  # Solo para rutas de preview protegidas

# === Sanity ===
SANITY_PROJECT_ID=your-project-id
SANITY_DATASET=production
SANITY_TOKEN=your-api-token  # Solo si se necesitan mutaciones server-side

# === Strapi ===
STRAPI_URL=http://localhost:1337   # URL del servidor Strapi (en prod: URL real)
STRAPI_API_TOKEN=your-api-token-here

# === Compartido ===
WEBHOOK_SECRET=generate-with-openssl-rand-hex-32
ALLOWED_FRONTEND_URL=https://mi-sitio.com
```

---

## Webhook Security (patrón obligatorio)

Todo endpoint que reciba webhooks de CMS DEBE validar firma HMAC con comparación de tiempo constante:

```typescript
import { createHmac, timingSafeEqual } from 'crypto';

function validateWebhookSignature(body: string, signature: string, secret: string): boolean {
  const expected = createHmac('sha256', secret).update(body).digest('hex');
  try {
    return timingSafeEqual(Buffer.from(signature, 'hex'), Buffer.from(expected, 'hex'));
  } catch {
    return false; // longitudes diferentes → siempre false
  }
}
```

---

## Schema mínimo de blog post (compatible con los 3 CMS)

```typescript
interface Post {
  title: string;         // REQUERIDO
  slug: string;          // REQUERIDO, unique
  description: string;   // REQUERIDO para SEO
  content: string | any; // rich text (formato varía por CMS)
  publishedAt: string;   // ISO 8601
  author?: string;
  coverImage?: string;   // URL de la imagen
  draft?: boolean;
}
```

---

## Contentful

**SDK**: `contentful` (npm) — `npm install contentful`
**Auth**: Content Delivery API (published) vs Content Preview API (drafts)
**CORS**: Settings > API > CORS — solo dominios explícitos, no wildcard
**Content Type mínimo**: title (Short text), slug (Short text, unique), description (Short text), content (Rich text), publishedAt (Date & time), author (Short text), coverImage (Media, opcional)

> Implementación completa del cliente en `skills/headless-cms-setup/CONTENTFUL.md` Fase 4

---

## Sanity

**SDK**: `@sanity/client` (npm)
**Query**: GROQ — filtrar drafts con `!(_id in path("drafts.**"))` en queries públicas
**Auth**: projectId + dataset + token (token opcional para datasets públicos)
**CORS**: sanity.io > API > CORS Origins — solo dominios explícitos

> Implementación completa del cliente y schema en `skills/headless-cms-setup/SANITY.md` Fases 4-5

---

## Strapi v5

**API**: REST — estructura de respuesta diferente a v4 (⚠️ v4 es incompatible)
**Auth**: API Token — Settings > API Tokens > Create new token (tipo: Read-only)
**CORS**: `config/middlewares.js` con `ALLOWED_FRONTEND_URL` env var — NUNCA `origin: '*'`

> Implementación completa del cliente en `skills/headless-cms-setup/STRAPI.md` Fases 4-5

---

## CORS por CMS — Checklist

| CMS | Dónde configurar | Qué agregar |
|-----|-----------------|-------------|
| Contentful | Settings > API > CORS | Dominio de producción + `localhost:3000` |
| Sanity | sanity.io > API > CORS Origins | Dominio de producción + `localhost:3000` |
| Strapi | `config/middlewares.js` | `ALLOWED_FRONTEND_URL` env var |

---

## Preview Mode

| CMS | Mecanismo | Precaución |
|-----|-----------|-----------|
| Contentful | Preview API con `CONTENTFUL_PREVIEW_TOKEN` | Solo usar en rutas de preview protegidas por auth — NUNCA en sitemap/RSS |
| Sanity | Documentos con `_id` en path `drafts.**` | Filtrar con `!(_id in path("drafts.**"))` en queries públicas |
| Strapi | Draft & Publish nativo | `?publicationState=live` para contenido publicado únicamente |

---

## Resilience para fetch de CMS

```typescript
// Timeout obligatorio en todo fetch a CMS
const response = await fetch(url, {
  headers: { Authorization: `Bearer ${token}` },
  signal: AbortSignal.timeout(10_000), // 10 segundos
  next: { revalidate: 60 },            // ISR: revalidar cada 60s
});

if (!response.ok) {
  throw new Error(`CMS fetch failed: ${response.status} ${response.statusText}`);
}
```
