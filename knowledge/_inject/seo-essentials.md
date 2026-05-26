# SEO Essentials (para inyección en /build)

> Inyectar cuando el skill o feature involucra blog, sitemap, RSS, Open Graph, JSON-LD, o SEO técnico.

---

## Open Graph — Propiedades obligatorias

```html
<!-- Mínimo para SEO válido -->
<meta property="og:type" content="article">
<meta property="og:title" content="Título del Post">
<meta property="og:description" content="Descripción breve (120-155 chars)">
<meta property="og:url" content="https://sitio.com/blog/slug">
<meta property="og:image" content="https://sitio.com/og/slug.jpg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="article:published_time" content="2026-05-07T00:00:00Z">
<meta property="article:author" content="Nombre Autor">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Título del Post">
<meta name="twitter:description" content="Descripción breve">
<meta name="twitter:image" content="https://sitio.com/og/slug.jpg">

<!-- Canonical -->
<link rel="canonical" href="https://sitio.com/blog/slug">
```

---

## JSON-LD — Schemas mínimos verificados

### Article (activa Rich Results en Google News / Discover)

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Título del Post",
  "datePublished": "2026-05-07T00:00:00Z",
  "dateModified": "2026-05-07T00:00:00Z",
  "author": { "@type": "Person", "name": "Autor", "url": "https://sitio.com/about" },
  "image": { "@type": "ImageObject", "url": "https://sitio.com/og/slug.jpg", "width": 1200, "height": 630 },
  "publisher": { "@type": "Organization", "name": "Nombre Sitio", "logo": { "@type": "ImageObject", "url": "https://sitio.com/logo.png" } }
}
```

### BreadcrumbList (campos requeridos: position, name, item)

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://sitio.com" },
    { "@type": "ListItem", "position": 2, "name": "Blog", "item": "https://sitio.com/blog" },
    { "@type": "ListItem", "position": 3, "name": "Título del Post", "item": "https://sitio.com/blog/slug" }
  ]
}
```

### WebSite (en layout raíz, no en cada post)

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Nombre Sitio",
  "url": "https://sitio.com"
}
```

### ⚠️ SEGURIDAD CRÍTICA — Escape obligatorio en JSON-LD

Todo string proveniente de un CMS que se inserte en `<script type="application/ld+json">` DEBE pasar por:

```javascript
JSON.stringify(schema).replace(/</g, '\\u003c')
```

Sin este escape, un campo con `</script>` puede cerrar prematuramente el tag y ejecutar HTML arbitrario (XSS).

---

## Sitemap XML — Spec (sitemaps.org)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://sitio.com/blog/slug</loc>
    <lastmod>2026-05-07</lastmod>       <!-- ISO 8601: YYYY-MM-DD -->
    <changefreq>weekly</changefreq>     <!-- optional, Google lo ignora en la práctica -->
    <priority>0.8</priority>            <!-- 0.0-1.0, default 0.5 -->
  </url>
</urlset>
```

**Límites Google**: máx 50.000 URLs o 50MB por archivo. Si se supera → generar sitemap index:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap><loc>https://sitio.com/sitemap/1.xml</loc></sitemap>
  <sitemap><loc>https://sitio.com/sitemap/2.xml</loc></sitemap>
</sitemapindex>
```

**Regla**: URLs en sitemap SIEMPRE deben usar el dominio de producción (`SITE_URL` del env), NUNCA localhost.

---

## RSS 2.0 — Spec mínima (rssboard.org)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Nombre del Blog</title>
    <link>https://sitio.com/blog</link>
    <description>Descripción del blog</description>
    <language>es</language>
    <lastBuildDate>Wed, 07 May 2026 00:00:00 GMT</lastBuildDate>

    <item>
      <title><![CDATA[Título del Post]]></title>
      <description><![CDATA[Descripción o excerpt HTML]]></description>
      <link>https://sitio.com/blog/slug</link>
      <pubDate>Wed, 07 May 2026 00:00:00 GMT</pubDate>  <!-- RFC 822 -->
      <guid isPermaLink="true">https://sitio.com/blog/slug</guid>
    </item>
  </channel>
</rss>
```

**Reglas**: CDATA obligatorio en title y description para caracteres especiales. `<guid>` requerido para deduplicación en agregadores.

---

## Frontmatter mínimo (válido para Next.js, Astro, Nuxt)

```yaml
---
title: "Título del post"           # REQUERIDO — og:title, JSON-LD headline
description: "Descripción breve"   # REQUERIDO — meta description, og:description
date: 2026-05-07                   # REQUERIDO — datePublished, pubDate RSS, lastmod sitemap
slug: "titulo-del-post"            # REQUERIDO en Next.js y Nuxt (Astro lo infiere del filename)
author: "Nombre Autor"             # RECOMENDADO — JSON-LD author, RSS author
og_image: "/og/titulo.jpg"        # RECOMENDADO — og:image, twitter:image
updatedDate: 2026-05-07            # OPCIONAL — dateModified JSON-LD
draft: false                       # OPCIONAL — filtrar en build; nunca en sitemap
---
```

