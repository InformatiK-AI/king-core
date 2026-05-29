# Tasks — M13 Ecosystem, Community & Distribution (Change A — king-core)

> Detalle largo (criterios, paths, horas) en `mejora/planes-detallados/M13-ecosystem-community-distribution.md §6`.
> Aquí: 28 tareas de king-core en 6 bloques. Marcar `[x]` al completar (sdd-apply).
> Scope: SOLO los 8 items de king-core. Excluido: M-59 (king-content) y la parte skill de M-60 (T-25/T-26, king-content) → Change B.

## Bloque A1 — M-57 Plugin Signatures + Trust Model (T-01..T-05)
- [x] A1.1 T-01 `knowledge/universal/trust-model.md` con los 4 tiers (criterios, badges, garantías) + invariante de gate-override
- [x] A1.2 T-02 Proceso de generación y gestión de claves GPG (full-generate-key, firma de package, verificación en cliente)
- [x] A1.3 T-03 Pipeline de scanning automático (tabla 5 herramientas: Semgrep + Trivy + Snyk + gate-override checker + GPG validator, condición de bloqueo por herramienta)
- [x] A1.4 T-04 Proceso de revocación por tier + formato de la CRL (URL + verificación del cliente al instalar)
- [x] A1.5 T-05 Sección de integración con M-56 (campo `trust_tier` en manifest, vínculo bidireccional con king-hub-spec.md)

## Bloque A2 — M-21 CASTLE Spec + M-96 i18n + M-97 Plataformas (T-39..T-48)
### M-21 CASTLE Spec v1.0
- [x] A2.1 T-39 `knowledge/universal/castle-spec-v1.md` con las 6 capas (C,A,S,T,L,E): ≥4 métricas con threshold por capa + gate de veto con condición explícita
- [x] A2.2 T-40 Concepto de Contratos Bilaterales CASTLE con formato y ≥2 ejemplos concretos
- [x] A2.3 T-41 Tablas de mappings SOC2 → CASTLE, ISO 27001:2022 → CASTLE, NIST 800-53 → CASTLE (≥5 controles por estándar + disclaimer legal)
- [x] A2.4 T-42 Certificaciones CASTLE (Reviewer + Compliant Project) + governance (Technical Committee, 60 días comment period, retrocompatibilidad por MAJOR)
### M-96 i18n del Framework
- [x] A2.5 T-43 `knowledge/universal/i18n-framework.md` con policy de idiomas, estructura de archivos localizados y proceso de traducción (5 idiomas + canónico español + review native speaker)
- [x] A2.6 T-44 Comandos de tooling asistido (`king-framework i18n extract` y `i18n verify`) con sintaxis y ejemplo de output
- [x] A2.7 T-45 Targets de cobertura por versión (v2.5 → v4.0) + proceso de notificación cuando el canónico cambia (GitHub Issue automático)
### M-97 Plataformas Adicionales
- [x] A2.8 T-46 `knowledge/universal/platform-adapters-roadmap.md` con criterios de priorización (6 criterios, ≥3 para prioritario) + tabla 7 candidatos con complejidad
- [x] A2.9 T-47 Interface AgentAdapter (7 métodos con firma y contrato) + Feature Parity Matrix para las 11 plataformas actuales (≥5 features)
- [x] A2.10 T-48 Proceso de contribución de adapter nuevo (5 pasos: Issue → Aprobación → Fork → PR → Merge) + tests requeridos

## Bloque A3 — M-62 Contributor Experience Mejorado (T-06..T-11)
- [x] A3.1 T-06 Extender `skills/create-skill/SKILL.md` con scaffolding automatizado (directorio + SKILL.md con placeholders + LOAD-INDEX update); detecta colisiones antes de crear
- [x] A3.2 T-06b Generar `LOAD-INDEX.md` desde `templates/LOAD-INDEX.md.template` como parte del scaffolding (placeholders reemplazados, entrada del nuevo skill añadida)
- [x] A3.3 T-07 Sección "Checklist de Publicación Tier 3" en create-skill/SKILL.md (calidad mínima + identidad GPG + proceso de PR en king-hub)
- [x] A3.4 T-08 Sección "Recognition Program" en create-skill/SKILL.md (contributors page, skill of the month, annual awards, speaker opportunities, tier promotion)
- [x] A3.5 T-09 `knowledge/universal/contributor-guide.md` con style guide (7 secciones) + testing guide con Gherkin + publishing guide con link a trust-model.md
- [x] A3.6 T-10 Verificar/añadir placeholders en `skills/_templates/skill-template-v2.md` ({{SKILL_NAME}}, {{DATE}}, {{VERSION}}, {{API_VERSION}})
- [x] A3.7 T-11 Referencia bidireccional entre create-skill/SKILL.md (sección "Ver también") y contributor-guide.md

## Bloque A4 — M-61 Community Templates Oficiales (T-12..T-21)
- [x] A4.1 T-12 `knowledge/universal/community-templates/01-saas-b2b-starter.md` (Next.js 15 + Supabase + Stripe + Resend + Vercel); 6 secciones + ≥3 decisiones justificadas
- [x] A4.2 T-13 `community-templates/02-saas-b2c-starter.md` (Next.js + Clerk + Stripe + Mixpanel); diferenciación vs B2B justificada
- [x] A4.3 T-14 `community-templates/03-marketplace-starter.md` (Next.js + Postgres + Stripe Connect + Algolia); Stripe Connect vs Payments justificado
- [x] A4.4 T-15 `community-templates/04-mobile-app-starter.md` (React Native + Expo + Supabase + RevenueCat); referencia skills M10 + RevenueCat justificado
- [x] A4.5 T-16 `community-templates/05-api-only-starter.md` (Go + chi + Postgres + Fly.io); Go+chi vs Node/Fastify + estructura hexagonal
- [x] A4.6 T-17 `community-templates/06-data-pipeline-starter.md` (Python + Airflow + dbt + Snowflake); CASTLE L con lineage + Airflow vs Prefect
- [x] A4.7 T-18 `community-templates/07-ai-agent-starter.md` (Python/TS + Anthropic/OpenAI + vector DB); skills AI-native + tabla pgvector vs Pinecone vs Qdrant
- [x] A4.8 T-19 `community-templates/08-cli-tool-starter.md` (Go + Cobra + Bubbletea); estructura Cobra, testing Bubbletea, distribución Homebrew tap
- [x] A4.9 T-20 `community-templates/09-browser-extension-starter.md` (Plasmo + WXT); tradeoffs Plasmo vs WXT + implicaciones manifest v3
- [x] A4.10 T-21 `community-templates/10-desktop-app-starter.md` (Electron / Tauri); tabla comparativa + CI/CD multiplataforma

## Bloque A5 — M-60 Certification Curriculum (knowledge) (T-22..T-24, T-27)
- [x] A5.1 T-22 `knowledge/universal/certification-curriculum.md` con los 8 módulos KFCD (nombre, peso %, temas verificables; todos los skills referenciados en ≥1 módulo)
- [x] A5.2 T-23 Módulos KFCA (A1-A4) en certification-curriculum.md (4 módulos al 25%; A3 con mapping a CASTLE Spec v1.0 de M-21)
- [x] A5.3 T-24 Criterios de evaluación KFCSA (6 criterios, mínimo 4/6, obligatorios 3+4+5) en certification-curriculum.md
- [x] A5.4 T-27 Sección Credly + LinkedIn badge process (claim del badge, validez 2 años, proceso de renovación) en certification-curriculum.md

## Bloque A6 — M-56 King Hub Marketplace Spec (T-28..T-33)
- [x] A6.1 T-28 `knowledge/universal/king-hub-spec.md` con arquitectura del plugin king-hub (estructura de directorios + 4 skills: hub-publish/install/search/stats)
- [x] A6.2 T-29 Schema de `manifest.json` (≥12 campos con tipos y validaciones + ejemplo de manifest válido)
- [x] A6.3 T-30 7 CLI commands de Apex Core (search, install, update, publish, info, verify, uninstall) con sintaxis, flags y ejemplo de output
- [x] A6.4 T-31 Fórmula del Quality Score (pesos completos, umbral 40 para búsqueda, ejemplo de skill con score calculado)
- [x] A6.5 T-32 Prerrequisitos + arquitectura del backend (Go + PostgreSQL + S3); ≥6 endpoints (method + path + descripción) + reglas de negocio
- [x] A6.6 T-33 Uso de github-ops durante la implementación del hub (crear repo, configurar CI, proteger branches); referencia a skills/github-ops/SKILL.md

---

## Review Workload Forecast
- Estimated lines: >> 400 (10 knowledge nuevos + 1 skill extendido + 1 template ext + 10 template specs + LOAD-INDEX gen)
- 400-line budget risk: **High**
- Chained PRs recommended: Sí (Change A king-core / Change B king-content separados)
- Quality gate: `/review` por bloque (trazabilidad incremental), CASTLE FORTIFIED antes del merge
- Excluido de este Change: M-59 (interactive-tutorials, king-content) + M-60 skill/command (T-25, T-26, king-content) → Change B
