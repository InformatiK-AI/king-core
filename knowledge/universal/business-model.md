# Business Model & Licensing — King Framework

> Knowledge universal · Milestone M14 (M-95) · Fuente: `mejora/planes-detallados/M14-business-model-monetization.md`
> Declara legalmente qué es gratis y qué requiere licencia. Lo consultan `/license-check`, `/genesis` y la
> landing King Pro. Single source of truth de tiers y términos legales.

---

## 1. Modelo: freemium bajo Business Source License 1.1

King Framework se distribuye bajo **Business Source License 1.1 (BSL 1.1)** — el mismo modelo que HashiCorp usó
para Terraform y que MariaDB creó. No es ni "totalmente open-source" ni "propietario cerrado": es un punto medio
diseñado para que el proyecto sea **sustentable** sin dejar de ser abierto para la mayoría de los usuarios.

### Términos clave (resumen no-legal)

| Término | Qué significa en King |
|---------|-----------------------|
| **Uso permitido (gratis)** | Uso personal, educativo, evaluación, y uso comercial dentro de **King Core** (tier $0). Podés leer, modificar y redistribuir el código bajo los términos BSL. |
| **Additional Use Grant** | Uso no-productivo de cualquier skill (incluidos los premium) está permitido para desarrollo, testing y evaluación. |
| **Uso restringido (requiere licencia)** | Uso **comercial en producción** de skills marcados como King Pro / Team / Enterprise. "Comercial en producción" = usás el skill premium para generar valor en un producto o servicio que monetizás. |
| **Change Date** | A los **4 años** de publicada cada versión, esa versión se reconvierte automáticamente a **Apache 2.0** (open-source pleno). Lo que hoy es Pro, en 4 años es libre. |
| **Change License** | Apache License 2.0. |

> El texto legal completo de la licencia vive en el archivo `LICENSE` del repositorio. Este documento es la
> referencia operativa para entender los tiers, no el texto legal vinculante.

### Filosofía: confianza, no DRM

El gate de licencia (`/license-check`) es de **confianza**, no de protección técnica. Un usuario avanzado
puede técnicamente bypassearlo. **Eso está bien y es esperado** — igual que con Terraform, la mayoría paga
porque quiere soporte, features y estar en regla, no porque no pueda evitarlo. El moat de King no es un candado:
es la comunidad, las features, las certificaciones y el SLA enterprise. No prometemos "anti-piratería".

---

## 2. Tiers de producto

| Tier | Precio | Qué incluye |
|------|--------|-------------|
| **King Core** | **$0/mes** | 5 skills core (`/welcome`, `/build`, `/castle`, `/qa`, `/promote`) + 3 agentes (@developer, @architect, @qa) + CASTLE S+T + Chronicle. Open-source bajo BSL 1.1. |
| **King Pro** | **$29/mes** | King Core + todos los skills oficiales (40+) + Jarvis Mode + `/brand-identity` + soporte prioritario. |
| **King Team** | **$99/mes** (hasta 5 devs) | King Pro × equipo + CASTLE 6 capas completas + Engram first-class + AI Audit Ledger. |
| **King Enterprise** | **$499/mes** (hasta 20 devs) | King Team + Engram multi-user + SLA 48h + onboarding call + custom skills. |
| **King Enterprise+** | **$1.499/mes** | King Enterprise + SLA 24h + Slack dedicado + compliance reports. |
| **Certificación KFCD** | **$299/examen** | King Framework Certified Developer — 8 módulos + certificado PDF + badge de LinkedIn. |

> **King Core es el producto vendible mínimo**: lo que se lanza, se cobra y se marketa en v2.0. El catálogo de
> 80+ skills es lo que **retiene** a los usuarios en el largo plazo, no lo que los convierte.

### Qué skills son premium (referencia para license-check)

- **Core (gratis)**: los 5 skills core listados arriba.
- **Pro**: el resto de skills oficiales del catálogo (incluidos `/brand-identity`, Jarvis Mode, los stacks
  king-infra/king-ai/king-mobile/king-content/king-entrepreneur).
- **Team**: skills marcados como colaborativos/auditoría (e.g. AI Audit Ledger, CASTLE 6 capas, Engram first-class).
- **Enterprise**: multi-user, custom skills, compliance reports.

---

## 3. ICP (Ideal Customer Profile) por segmento

| Segmento | Quién es | Dolor que resuelve King | Tier objetivo |
|----------|----------|-------------------------|---------------|
| **Developer-founder** | Indie hacker / solo-dev que construye un SaaS | Ahorra 2-4 semanas de setup (auth, pagos, deploy, CASTLE); evita ir a producción con vulnerabilidades o sin tests | Pro ($29) |
| **Startup team** | Equipo de 2-5 devs en seed/pre-seed | Consistencia de calidad entre devs; CASTLE 6 capas; Engram compartido como memoria del equipo | Team ($99) |
| **Enterprise** | Empresa con compliance/regulación (fintech, salud) | Auditoría, SLA, compliance SOC2/ISO27001, custom skills, soporte dedicado | Enterprise ($499+) |
| **Skill creators** | Developers que publican skills en Apex Hub (M13) | Distribución + revenue share del 30% (se implementa en M13) | — (proveedores) |

---

## 4. Roadmap de monetización

> El modelo de negocio NO cambia las prioridades técnicas P0 — las **financia**. Corre en paralelo al roadmap
> técnico, no lo bloquea ni es bloqueado por él.

| Fase | Cuándo | Qué se vende | Meta de MRR |
|------|--------|--------------|-------------|
| **Fase 0 — Hoy** | Inmediato (sin código) | Consulting $150–300/h + GitHub Sponsors + waitlist King Pro | $1.5k–4.5k one-shot (consulting) |
| **Fase 1 — v1.9** | 6-9 meses | King Pro ($29) + King Team ($99) con license-check + Stripe billing | $2.9k (100 Pro) |
| **Fase 2 — v2.0** | 12-18 meses | King Enterprise ($499) + Enterprise+ ($1.499) + Certificación KFCD ($299) | $22k (500 Pro + 150 Team + 15 Enterprise) |
| **Fase 3 — v2.5** | 24-30 meses | Apex Hub marketplace (M13) + revenue share 30% | + comisión marketplace |

### Métricas de éxito del módulo M14

| Métrica | Target v1.9 | Target v2.0 |
|---------|------------|------------|
| MRR | $2.9k | $22k |
| Waitlist convertida | 20% | 30% |
| Tiempo de activación post-pago | < 2 min (automatizado) | < 1 min |
| Churn mensual | < 10% | < 7% |

---

## 5. FAQ legal

**¿Puedo usar King en mi startup gratis?**
Sí, si usás King Core (los 5 skills core). Para uso comercial en producción de skills Pro/Team/Enterprise,
necesitás la licencia correspondiente. Desarrollo, testing y evaluación de cualquier skill es libre.

**¿Cuándo necesito King Pro?**
Cuando usás skills premium (más allá de los 5 core) para generar valor en un producto/servicio que monetizás
en producción.

**¿Qué pasa con mis contribuciones al framework?**
Quedan bajo BSL 1.1. Si contribuís, aceptás el CLA (Contributor License Agreement) cuando aplique.

**¿Y si King desaparece? ¿Pierdo lo que pagué?**
No técnicamente: a los 4 años cada versión se reconvierte a Apache 2.0 automáticamente (Change Date). Lo que
hoy es Pro será open-source pleno en 4 años.

**¿El license-check me espía o llama a casa?**
No. La licencia vive como una observation local en tu Engram (`king-framework/license`). license-check la lee
localmente. No hay telemetría obligatoria. Ver [[license-management]].

---

## Relacionado

- [[license-management]] — esquema técnico de la observation, flujo de activación, modo degradado, mensajes estándar.
- [[soc2-compliance]] — mapa de controles SOC2/ISO27001 para evaluación enterprise.
