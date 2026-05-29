# Archive Report — M14 Licensing Core

> Fase: sdd-archive · Change: m14-licensing-core · Fecha: 2026-05-28 · Veredicto: FORTIFIED

## Resumen

Mitad king-core del milestone M14 (Business Model & Monetization). Entrega la infraestructura de licencias y la
guía de compliance enterprise. Habilita el cambio hermano `m14-billing-entrepreneur` (repo king-entrepreneur).

## Lineage

| Artefacto | Estado |
|-----------|--------|
| proposal · exploration · design · specs (4) · tasks · verify-report | completed |
| Bloques implementados | A (BSL+knowledge), B (license-check), C (genesis), F (SOC2) |
| A4 (Sponsors/waitlist/entrevistas) | Out-of-scope (acción manual del maintainer) |

## Entregables (en develop @ 931282b)

- `knowledge/universal/business-model.md` — BSL 1.1, 6 tiers, ICP, roadmap MRR, FAQ
- `knowledge/universal/license-management.md` — contrato observation `king-framework/license` (single source of truth), flujo activación, modo degradado, mensajes estándar
- `skills/license-check/SKILL.md` + `commands/license-check.md` — verificación de tier, 4 modos, anatomía v2.0, CASTLE S
- `knowledge/universal/soc2-compliance.md` — mapa controles SOC2 ↔ CASTLE/Chronicle/Engram, gaps, template procurement
- `skills/genesis/GENERATION.md` — step license informativo no bloqueante (extensión aditiva, +14 líneas)

## Verificación

- pytest: 59 passed · genesis diff: 14 added / 0 removed · secrets scan: clean · specs: 4/4 COMPLIANT
- CASTLE: C·A·S·T en verde (S es la capa central — key nunca expuesta)

## GATE cross-repo

develop de king-core ahora expone `license-check` + el contrato de la observation. **Desbloquea**
`m14-billing-entrepreneur`: el webhook `checkout.session.completed` de Stripe escribirá la misma observation que
`license-check` lee.

## Commits

- Feature: `46f9d55` (16 archivos, 1269 inserciones)
- Merge a develop: `931282b` (pusheado a origin/develop)
