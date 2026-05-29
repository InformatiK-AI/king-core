# ADR — Hosting del King Hub backend (A7.1)

> **Estado**: Aceptada · **Fecha**: 2026-05-29 · **Decisor**: InformatiK-AI
> **Contexto backlog**: A7.1 (post-M13). Complementa `king-hub-spec.md §6`. La implementación del backend
> (40-60h) sigue diferida a su propio ciclo SDD; esta ADR resuelve solo la decisión de hosting para que ese
> ciclo arranque con el diseño de infra cerrado. Análisis con pricing 2026 verificado (7 agentes, WebSearch).

## Contexto

El backend del King Hub (`king-hub-spec.md §6`) requiere: API Go (chi) con 6 endpoints, PostgreSQL (catálogo),
object storage S3-compatible para artefactos firmados, cron semanal (Quality Score), rate limiting y dominio
`hub.kingframework.dev`. Es un **package registry** → las descargas son **egress-heavy**. Restricciones del
proyecto: open-source, equipo de ~1 persona, early-stage (tráfico bajo), economía freemium sensible al costo.
Prioridades: bajo costo a tráfico bajo · bajo ops · egress barato · buen camino de escalado.

## Decisión

**Hosting primario: Railway.** Arquitectura concreta:

- **Compute**: Go web service *always-on* (Docker multi-stage, distroless), sin scale-to-zero (un registry debe
  responder `install` sin cold-start).
- **Postgres**: Railway Postgres gestionado (barato desde el día 1, backups automáticos, `DATABASE_URL` inyectado).
- **Object storage**: Railway Buckets (S3-compatible sobre Tigris, **egress $0**). Artefactos servidos vía
  **presigned URL (302 redirect)**, nunca proxeados por el compute.
- **Cron**: mismo binario en modo cron (subcomando) con schedule semanal.
- **Dominio/TLS**: `hub.kingframework.dev` con TLS automático.

**Razón del primer puesto**: único proveedor que consolida compute + Postgres gestionado barato + object storage
con egress $0 en una sola factura/dashboard/credenciales. Para 1 persona, esa reducción de superficie operativa
es decisiva. El costo a tráfico bajo queda dominado por compute+Postgres (predecible), no por egress.

## Alternativas consideradas

| Plataforma | Costo tráfico bajo | Ops | Storage + egress | Fit | Veredicto |
|---|---|---|---|---|---|
| **Railway** | ~$10-20/mes | bajo | Buckets, egress $0 | **8.5** | **Elegida** |
| Fly.io + Tigris | ~$8-15/mes | bajo | Tigris, egress $0 | 8 | Runner-up (piso más barato, pero Postgres barato es self-managed → tensión costo/ops) |
| Render + Cloudflare R2 | ~$32-40/mes | bajo | R2, egress $0 + CDN edge | 8 | 3ª opción (patrón canónico de registry; +1 proveedor, más caro) |
| VPS Hetzner | ~$14-15/mes | **alto** | egress barato | 5.5 | Descartada — ops de Postgres en 1 persona |
| GCP Cloud Run + GCS | ~$25-80/mes | medio | GCS egress **$0.12/GB** | 5 | Descartada — egress dealbreaker + LB obligatorio |

## Disciplinas obligatorias (independientes de la plataforma)

1. **Descargas vía presigned URL 302** — el endpoint `/download` DEBE redirigir al object storage, nunca streamear
   el binario por el compute (pagaría egress de compute y rompería la economía). *Guardarraíl*: test de contrato
   que exija 302 a host de storage, nunca 200 con body binario.
2. **Rate limiting en Go** (chi middleware): 100 installs/min/IP, 10 publishes/día/cuenta. Token bucket en memoria
   para single-instance; Redis solo al escalar a réplicas. Ninguna PaaS lo da en planes bajos.
3. **Cloudflare gratis al frente** (recomendado desde día 1): CDN de descargas + anti-DDoS (un registry público es
   blanco de abuso) + habilita migración futura a R2 sin fricción.

## Consecuencias

- **Positivas**: ops mínimo, egress $0, costo predecible, lock-in bajo (S3-compat + Postgres estándar + Docker →
  migrar Railway→Fly→R2 es factible sin reescribir el SDK S3).
- **Negativas/Riesgos**: costo no es $0 (~$10-20/mes always-on); Railway Buckets es GA reciente (sin
  versioning/object-lock — no bloqueante para artefactos inmutables firmados con GPG); Postgres de PaaS menos
  avanzado que RDS/Cloud SQL (suficiente early-stage, revisar en escala).

## Decisión abierta (para el ciclo SDD del backend)

¿Anteponer Cloudflare gratis desde el día 1? Recomendado (cache de descargas + DDoS + futura migración a R2). Es
el único trade-off arquitectónico con margen abierto; el resto de la infra queda fijada por esta ADR.

## Ver también
- `king-hub-spec.md` (§6 Backend Architecture) — la spec que esta ADR complementa.
- `trust-model.md` — scanning GPG/CRL que el backend implementa.
