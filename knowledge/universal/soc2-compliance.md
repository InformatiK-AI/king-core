# SOC2 / ISO 27001 Compliance Guide — King Framework

> Knowledge universal · Milestone M14 (M-98) · Fuente: `mejora/planes-detallados/M14-business-model-monetization.md`
> Documento de referencia para que un **enterprise customer** evalúe King Framework en contextos regulados.
> **NO es una certificación real** — eso es P3 (~16 semanas, cuando haya 20+ enterprise customers). Es la guía
> de evaluación: honestidad > marketing.

---

## 1. Mapa de controles SOC2 Type II ↔ features de King

SOC2 Type II audita los Trust Services Criteria (TSC) a lo largo del tiempo. Esta tabla mapea los controles
relevantes contra las features que King ya provee — y marca explícitamente lo que NO cubre (ver §2).

### Common Criteria (CC) — Security

| Control | Descripción | Feature de King que lo soporta | Cobertura |
|---------|-------------|-------------------------------|-----------|
| **CC6.1** | Control de acceso lógico | CASTLE capa **A** (Architecture — dependency direction, boundaries) + capa **C** (Contracts — contratos bilaterales entre agentes) | Parcial |
| **CC6.6** | Protección contra amenazas externas | CASTLE capa **S** (Security — OWASP, veto bloqueante CVSS≥9.0) | Sólida |
| **CC6.7** | Retención y disposición de datos | **Engram** como documentación de retention policy (working memory con `revision_count`, upsert por topic_key) | Parcial — ver gap G2 |
| **CC7.2** | Monitoreo de operaciones | **Chronicle** como audit log inmutable (filesystem nativo, zero-dependency) + Audit Ledger | Sólida |
| **CC7.3** | Evaluación de eventos de seguridad | CASTLE Security Gate + `/audit-ledger` (audit trail consultable y exportable a JSON/CSV) | Sólida |
| **CC8.1** | Gestión de cambios | **SDD** (Spec-Driven Development): proposal → spec → design → tasks → apply → verify → archive, con state.yaml y trazabilidad | Sólida |

### Otros TSC

| Control | Descripción | Feature de King | Cobertura |
|---------|-------------|-----------------|-----------|
| **A1.2** (Availability) | Recuperación y resiliencia | `/resilience-weave` (retry/circuit-breaker/bulkhead) — guidance, no enforcement runtime | Parcial — guidance |
| **PI1.x** (Processing Integrity) | Integridad del procesamiento | `/idempotency` (exactly-once efectivo) + contract testing (`/contract-test-pact`) | Parcial — guidance |
| **C1.x** (Confidentiality) | Protección de datos confidenciales | CASTLE S (no secrets en código) + `domain/compliance/` (GDPR, HIPAA, PCI-DSS) | Parcial |

### Las 6 capas CASTLE como controles

```
C — Contracts     → contratos bilaterales entre agentes (CC6.1: separación de responsabilidades)
A — Architecture  → dependency direction, boundaries (CC6.1: control de acceso lógico)
S — Security      → OWASP, veto CVSS≥9.0 (CC6.6: protección de amenazas)
T — Testing       → coverage gate, contract tests (CC8.1: cambios verificados)
L — Logging       → logging estructurado, observabilidad (CC7.2: monitoreo)
E — Environment   → environment parity, secrets management (CC6.7 / C1.x)
```

---

## 2. Gaps actuales (honestos) y plan de remediación

> La honestidad sobre los gaps es lo que hace este documento útil para procurement. No vendemos una
> certificación que no tenemos.

| ID | Gap | Severidad | Plan de remediación | Timeline |
|----|-----|-----------|---------------------|----------|
| **G1** | No hay certificación SOC2 Type II formal (no se contrató auditor externo) | Alta | Contratar auditor cuando haya 20+ enterprise customers que lo justifiquen económicamente | P3 / v2.5 |
| **G2** | Engram es working memory, no audit trail inmutable (upsert pierde contenido previo) | Media | Para retention auditable, usar `openspec`/`hybrid` mode o Chronicle (que sí es inmutable); documentar cuál usar para datos regulados | v2.0 |
| **G3** | Resilience y Processing Integrity son **guidance** (skills que generan código), no enforcement runtime | Media | Los gates CASTLE validan estructura, no comportamiento en producción; el enforcement runtime queda del lado del proyecto generado | Documentado |
| **G4** | No hay multi-user access control nativo en Engram (single-user por defecto) | Media | Engram multi-user es feature de King Enterprise (M14 tier Enterprise) | v2.0 |
| **G5** | Secrets management depende de la disciplina del proyecto (CASTLE S detecta, no previene 100%) | Media | `/genesis` genera `.gitignore`; CASTLE S escanea secrets; pero la prevención total requiere vault externo (guidance) | Documentado |

> **Principio**: King Framework provee los **controles y la disciplina** (CASTLE, Chronicle, SDD, Engram), pero
> la certificación SOC2 es del **producto del cliente**, no del framework. King facilita el cumplimiento; no lo
> garantiza por sí solo.

---

## 3. Template de cuestionario de seguridad (procurement)

Plantilla para responder cuestionarios enterprise de forma consistente en < 30 minutos.

| Pregunta típica de procurement | Respuesta basada en features de King |
|--------------------------------|--------------------------------------|
| ¿Cómo se controla el acceso al código generado? | El acceso se controla a nivel del repositorio del cliente. King aplica CASTLE C/A (contratos + boundaries) sobre la arquitectura generada. |
| ¿Hay un audit log de las operaciones de los agentes? | Sí — Chronicle (filesystem inmutable, zero-dependency) + `/audit-ledger` (exportable a JSON/CSV, filtrable por fecha/agente/skill). |
| ¿Cómo se gestionan los cambios? | Vía SDD: cada cambio tiene proposal/spec/design/tasks/verify-report archivados con trazabilidad completa (state.yaml). |
| ¿Se escanean vulnerabilidades? | Sí — CASTLE Security Gate con veto bloqueante en CVSS≥9.0 (único en el mercado) + OWASP en `/review`. |
| ¿Cómo se manejan los secrets? | CASTLE S detecta secrets en código; `/genesis` genera `.gitignore`; recomendamos vault externo para producción (guidance en `domain/compliance/`). |
| ¿Tienen certificación SOC2/ISO27001? | No formalmente aún (ver gap G1). Proveemos esta guía de mapeo de controles para evaluación. La certificación del producto final es responsabilidad del cliente; King facilita el cumplimiento. |
| ¿Dónde se almacenan los datos de licencia? | Localmente, como observation en el Engram del entorno del cliente (`king-framework/license`). Sin telemetría obligatoria. Ver [[license-management]]. |
| ¿Cumplen GDPR/HIPAA/PCI-DSS? | Hay knowledge base en `domain/compliance/` con guidance para cada uno. El cumplimiento efectivo depende de la implementación del proyecto del cliente. |

---

## Relacionado

- [[business-model]] — tiers (Enterprise incluye compliance reports), términos BSL 1.1.
- [[license-management]] — Engram como store de licencia (CC6.7 — retention).
