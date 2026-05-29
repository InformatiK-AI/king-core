# Tasks — M14 Licensing Core

> Detalle largo (criterios, paths, contenido) en `mejora/planes-detallados/M14-business-model-monetization.md §6`
> (Bloques A, B, C, F). Aquí: tareas de 1 línea. Marcar `[x]` al completar (sdd-apply).
> **A4 excluido del scope** (acciones manuales del maintainer — Sponsors/waitlist/entrevistas).

## Bloque A — BSL & Knowledge (sin dependencias)
- [x] A1 knowledge `business-model.md`: texto BSL 1.1 adaptado + tabla de 6 tiers + ICP por segmento
- [x] A2 sección roadmap de monetización en `business-model.md` (fases v1.9 → v3.0 con metas MRR) + FAQ legal
- [x] A3 knowledge `license-management.md`: esquema JSON observation Engram + flujo activación + modo degradado

## Bloque B — license-check skill (depende de A1, A3)
- [x] B1 `skills/license-check/SKILL.md` Phase 0 + Phase 1 (read-engram) con fallback si Engram no responde
- [x] B2 `skills/license-check/SKILL.md` Phase 2 (validate-tier) + Phase 3 (return-result/activate) + FINAL CHECKPOINT + Execution Summary
- [x] B3 `commands/license-check.md`: descripción + parámetros (`activate <key>`, `status`, `deactivate`) + ejemplos
- [x] B4 Mensajes estándar (upgrade / expiración / modo degradado) en `license-management.md`

## Bloque C — license step en genesis (depende de B2)
- [x] C1 Leer `skills/genesis/GENERATION.md` fase final e identificar punto de inserción
- [x] C2 Añadir step license-check (informativo, no bloqueante) en la fase final de genesis (aditivo)

## Bloque F — SOC2 guide (independiente)
- [x] F1 `knowledge/universal/soc2-compliance.md` §1: mapa controles SOC2 Type II ↔ CASTLE/Chronicle/Engram
- [x] F2 `soc2-compliance.md` §2: gaps honestos + plan de remediación + template cuestionario procurement

## Validación
- [x] V1 `pytest` estructural (frontmatter, api_version, anatomía v2.0) PASS — 59 passed
- [x] V2 Contrato de observation idéntico en `license-management.md` ↔ `license-check/SKILL.md` (capa C)
- [x] V3 `rg` sin keys reales en ejemplos; `/license status` muestra solo últimos 4 chars (capa S)
