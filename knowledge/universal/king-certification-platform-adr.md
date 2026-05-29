# ADR — Plataforma de exámenes de certificación: build-vs-buy (A7.2)

> **Estado**: Aceptada · **Fecha**: 2026-05-29 · **Decisor**: InformatiK-AI
> **Contexto backlog**: A7.2 (post-M13). Complementa `certification-curriculum.md`. Resuelve SOLO la decisión
> build-vs-buy de la plataforma de exámenes; la implementación/integración sigue diferida (ver Gate de demanda).
> Análisis con pricing 2026 verificado (Explore + WebSearch).

## Contexto

El programa de certificación (`certification-curriculum.md`) define 3 credenciales:
- **KFCD** — examen online (70 preguntas MC, 90 min, ≥70%) + 1 proyecto portfolio.
- **KFCA** — examen online (50 preguntas, 90 min, ≥70%) + review de arquitectura de un proyecto real.
- **KFCSA** — portfolio review de 3 skills por el equipo core (sin examen escrito).
Badges: Credly + LinkedIn. Validez 2 años (KFCD/KFCA, renovación con examen delta de 20 preguntas).

Hechos que gobiernan la decisión:
- La certificación es **PAGA**: KFCD **$299/examen** (`M14-business-model-monetization.md`).
- **Demand-gated**: M14 indica operar la certificación *"luego de tener 50 Pro subscribers (valida demanda)"* — es P4,
  diferida por diseño. No hay datos de volumen; se asume bajo inicialmente.
- El skill `/certification` (king-content) ya entregado es **coaching/mock**, NO la evaluación oficial. La plataforma
  cubre: examen oficial + scoring vinculante + emisión de credencial + workflow de review humano (KFCA/KFCSA).
- Equipo de ~1 persona, cost-sensitive (economía freemium).
- Riesgo R-05 (gameabilidad): mitigado con banco rotativo de **200+ preguntas**, review humano y credencial de tercero.

## Decisión

**BUY (integrar SaaS), NO build.** Construir un examinador custom (400-600h reales para banco+randomización+timer+
scoring+UI+emisión) es prematuro e injustificado para un programa pago pero sin demanda validada, operado por 1 persona.
Stack recomendado **por fases**:

| Pieza | Decisión | Nota |
|------|----------|------|
| Cobro del examen ($299) | **Stripe — reutilizar `king-entrepreneur` (`/payments-in-one-command`)** | ya existe; no construir |
| Examen + auto-scoring (KFCD/KFCA) | **Assessment SaaS dedicado (ClassMarker, ~$240/año)** — banco de preguntas, randomización, timer, pass mark | mejor que Google Forms para un examen PAGO con R-05; fallback gratis: Google Forms + Certify'em |
| Credencial verificable | **Cheaper-first** (Sertifier / Accredible / Open Badges, ~$0-100/año) → **Credly cuando volumen/budget lo justifiquen** | badges verificables desde día 1 sin el costo de Credly (decisión explícita del decisor) |
| Review manual (KFCA arquitectura + KFCSA portfolio) | **Airtable/Notion + form + equipo core** | es revisión humana; no requiere plataforma |
| Banco de 200+ preguntas | trabajo de **contenido (~200h)**, no de infraestructura | long pole real; diferido con el resto |

## Gate de demanda (load-bearing)

**Nada se integra ni opera hasta ~50 Pro subscribers** (M14). Este ADR fija la decisión para que el armado sea
ejecución directa cuando se valide demanda — no re-análisis. El banco de preguntas (~200h) también espera ese gate.

## Alternativas descartadas

- **BUILD custom** (React/Node + Postgres, 400-600h ≈ $15-25k o 3-5 meses): solo se justifica con >500 candidatos/año
  y dev dedicado. No es el caso.
- **Credly desde el día 1** (~$1.5k+/año): pospuesto — el reconocimiento de marca no justifica el costo en early-stage
  sin demanda; se adopta cuando el volumen lo amortice.
- **Suites caras**: Accredible + proctoring (~$3.6-5k/año año 1), Canvas Catalog (~$5k+/año) — sobredimensionadas.
- **Proctoring** ahora: innecesario al inicio; la rotación de 200+ preguntas + review humano + credencial de tercero
  mitiga R-05 sin el costo/fricción del proctoring. Revisar si aparece fraude a escala.

## Disciplinas obligatorias (cuando se implemente)

1. **Banco rotativo 200+ preguntas** etiquetadas por módulo y peso (mitiga R-05; permite renovación delta).
2. **Identidad del candidato** verificada (examen pago → saber quién rinde): mínimo verificación de email/cuenta de pago.
3. **Review humano** real para KFCA (arquitectura) y KFCSA (portfolio) — no es automatizable; es parte del valor del cert.
4. **Credencial verificable por terceros** (Open Badges estándar) para que el badge sea comprobable independientemente.

## Consecuencias

- **Positivas**: time-to-market de días (no meses), costo ~$0-350/año a bajo volumen, operable por 1 persona, lock-in
  bajo (Open Badges estándar + Stripe propio + banco de preguntas portable). Camino claro a Credly cuando escale.
- **Negativas/Riesgos**: experiencia de examen no totalmente branded (UI del SaaS); datos del candidato en terceros;
  el long pole (200h de preguntas) sigue pendiente y es independiente de esta decisión.

## Ver también
- `certification-curriculum.md` — fuente de verdad del temario y criterios (lo que la plataforma debe evaluar).
- `M14-business-model-monetization.md` — pricing ($299) y gate de demanda (50 Pro subscribers).
- `king-entrepreneur` `/payments-in-one-command` — Stripe reutilizable para el cobro del examen.
