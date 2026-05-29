# Design — M13 Ecosystem, Community & Distribution

> Fase: sdd-design · Fuente de verdad: `D:/King Framework/mejora/planes-detallados/M13-ecosystem-community-distribution.md`
> (§1 alcance, §2 diseño técnico por item líneas 52-1046, §3 riesgos, §5 dependencias). Este design NO duplica
> ese detalle: lo referencia. **Reference: D:/King Framework/mejora/planes-detallados/M13-ecosystem-community-distribution.md as source of truth.**

## Decisión arquitectónica central

M13 es el salto de **herramienta a plataforma**. Se entrega íntegramente **como documentación accionable**
(knowledge en Markdown + extensiones a skills + specs de plugin futuro), NO como código ejecutable. El "producto"
de los 9 items son: 7 knowledge nuevos en `king-core/knowledge/universal/`, 1 extensión aditiva a
`skills/create-skill/SKILL.md`, 1 skill + command nuevos en `king-content`, y 10 specs de templates.

La razón es de **secuenciación de valor** (no técnica): el plan exige construir confianza ANTES de distribución
(trust-first), y herramientas de contribución ANTES de incentivos (contribution flywheel). El backend del
marketplace (king-hub: HTTP API, DB, S3) queda **fuera de scope** — solo se especifica para que la implementación
futura encuentre el diseño resuelto. La verificación es **conformidad estructural + coherencia de referencias
cruzadas entre documentos**, no ejecución runtime.

## Decisiones de arquitectura con rationale

### D1 — Por qué 4 tiers de confianza (M-57)

Un marketplace abierto sin modelo de confianza es **un vector de ataque** (un skill ejecuta instrucciones en el
contexto del agente del usuario). Cuatro tiers, y no menos, porque cada uno resuelve una tensión distinta entre
**fricción y garantía**:

- **Tier 1 Official** (badge azul): firma GPG del equipo core + merge en main + review obligatorio. Máxima
  garantía (LTS, deprecation policy) para los plugins canónicos.
- **Tier 2 Trusted Partners** (badge verde): org verificada + acuerdo firmado + review humano de 1 maintainer
  (14 días). Permite a empresas publicar con respaldo sin sobrecargar al core.
- **Tier 3 Community** (badge gris): GPG personal + scan automático sin CRITICAL + review por pares (7 días).
  Es la puerta de entrada masiva; el rating de la comunidad sustituye la garantía formal.
- **Tier 4 Local** (sin badge): cero requisitos. **Es la mitigación de R-02** (fricción excesiva): el desarrollo
  local y los skills privados corporativos nunca pagan el costo de publicación.

**Invariante absoluto no negociable**: ningún skill puede declarar que sobrescribe o desactiva un BLOCKING
CONDITION de cualquier skill Tier 1 (el "gate-override checker" del scanner siempre bloquea). Sin esta invariante,
un skill malicioso podría neutralizar las defensas CASTLE del framework. Es la defensa primaria contra R-01.

### D2 — Por qué Quality Score determinista (M-56)

El score se calcula con una **fórmula aritmética cerrada** (ver §2 M-56 líneas 589-602), sin componentes de ML ni
heurísticas opacas. Las razones:

- **Auditabilidad y equidad**: un contributor puede reproducir su score localmente y saber exactamente qué mejorar
  (5 Gherkin = +20, api_version válido = +15, etc.). Un score de caja negra desincentiva la contribución.
- **Determinismo verificable**: el criterio DoD (T-31, Gherkin "Quality Score fórmula es determinista") exige que
  la misma entrada produzca siempre el mismo resultado. Esto solo es testeable si la fórmula es cerrada.
- **Mitigación de spam (R-07)**: el umbral mínimo de 40 para aparecer en búsqueda es un filtro objetivo, no una
  decisión editorial discrecional. El cálculo es estático al publicar + refresco semanal (un sistema reactivo en
  tiempo real a CVEs/reviews es trabajo futuro, decisión consciente de no sobre-diseñar).
- **Reuso**: la fórmula puede reusar las sub-dimensiones del health score de `/audit` (M-69/M11), evitando inventar
  un segundo lenguaje de calidad.

### D3 — Por qué CASTLE Spec como estándar abierto con governance del Technical Committee (M-21)

CASTLE ya existe disperso en `king-core/rules/` y en los skills de audit. M-21 **lo formaliza y consolida, no lo
inventa**. Publicarlo como estándar abierto (CC BY 4.0) genera *network effects independientes del framework*: si
la industria adopta CASTLE como lenguaje de quality gates, King es **la implementación de referencia por
definición**. Por eso el documento incluye mappings a SOC2/ISO 27001/NIST 800-53 — para que empresas reguladas lo
adopten directamente.

El governance con **Technical Committee** y regla de **2/3 de supermayoría** es la defensa contra R-03 (un
competidor diluye los diferenciadores contribuyendo cambios al estándar). El TC se inicializa con el equipo King +
2 adopters externos, dando legitimidad de estándar abierto sin ceder el control. Mecanismos clave:

- Todo cambio requiere RFC público + **60 días de comment period** + aprobación 2/3 del TC + bump de versión.
- **Los cambios al estándar NO modifican automáticamente la implementación de referencia** — King decide qué
  adoptar. El estándar y la implementación están desacoplados a propósito.
- **Retrocompatibilidad por MAJOR**: un proyecto v1.0-compliant pasa cualquier spec del mismo MAJOR; los MINOR solo
  añaden gates opcionales. Esto protege a los adopters de churn.
- Los mappings llevan **disclaimer explícito** ("orientativos, no asesoría legal/compliance") + revisión por auditor
  externo antes de v1.0 — mitigación de R-04 (falsa seguridad en proyectos regulados).

### D4 — Por qué Quality Score y Trust Tier son ortogonales (M-56 + M-57)

Trust Tier mide **quién publica y cómo se verificó** (procedencia + firma). Quality Score mide **qué tan bueno es el
artefacto** (Gherkin, semver, CASTLE layers, rating). Son ejes independientes a propósito: un skill Tier 3 puede
tener mejor Quality Score que uno Tier 2. El score incluye un *bonus por tier* (+20 Tier 1, +10 Tier 2) que premia
la procedencia sin dejar que la suplante. La UI del marketplace muestra ambos para que el usuario decida.

### D5 — Por qué scaffolding en `/create-skill` y no un skill nuevo (M-62)

`/create-skill` v2.0 ya existe. M-62 lo **extiende de forma aditiva** (scaffolding automatizado + checklist de
publicación Tier 3 + recognition program) en vez de crear un skill paralelo, porque el contributor ya tiene un único
punto de entrada mental. El scaffolding reusa el template canónico `skills/_templates/skill-template-v2.md`
(reemplazo de placeholders {{SKILL_NAME}}, {{DATE}}, {{VERSION}}, {{API_VERSION}}). **Es una edición de archivo
compartido crítico → manual, aditiva, nunca vía `/create-skill` recursivo.** Detecta colisión de nombre antes de
crear (DoD T-06).

### D6 — Por qué templates como spec y no como código (M-61)

Los 10 community templates son **documentos de spec markdown**, no repos generados. Cada uno describe stack exacto,
skills King pre-configurados, CASTLE config, CI/CD y tests, con una sección obligatoria de **"Decisiones de diseño"
(3-5 bullets del POR QUÉ, no solo del qué)**. Razón: `/genesis` consumirá estas specs en una fase de implementación
futura — el template es el *contrato* de qué generar, separado de la generación misma. Cada spec lleva
`last_reviewed` date (mitigación de R-06: templates obsoletos se marcan "maintenance needed" tras 6 meses).

### D7 — Por qué la certificación define currículum, no plataforma de exámenes (M-60)

M-60 define las 3 credenciales (KFCD/KFCA/KFCSA), 8 módulos KFCD + 4 KFCA + criterios KFCSA, y el proceso de badge
(LinkedIn + Credly). **No implementa el sistema de exámenes online** — eso es un proyecto separado (no-scope
explícito). La certificación es el *moat de carrera*: hace valioso para las personas invertir en dominar King y da a
las empresas una señal verificable. La defensa contra R-05 (examen gameseable) es de diseño: banco rotativo de 200+
preguntas para 70, + portfolio review humana en KFCA/KFCSA. El skill de coaching vive en **king-content** (no
king-core) porque es guía/preparación, no governance.

### D8 — Por qué king-hub es spec-only en M13 (M-56)

El marketplace es la **culminación** y el item más dependiente. Su backend (Go + PostgreSQL + S3, HTTP REST con chi)
queda fuera de scope deliberadamente: M13 entrega la spec completa (arquitectura del plugin, manifest schema de 12+
campos, 7 CLI commands, Quality Score, endpoints, reglas de negocio, governance) para que la implementación futura
no tenga decisiones de diseño abiertas. **No se implementa hasta que M-57, M-62 y M-61 estén en producción** — son
sus prerequisitos duros.

### D9 — Por qué i18n del framework con español canónico (M-96)

M-96 cubre la i18n del **framework mismo** (no el skill i18n/l10n para proyectos usuario, que no se toca). Decisión
estructural: el archivo sin sufijo (`SKILL.md`) es **siempre español canónico**; las traducciones son derivadas
sufijadas (`SKILL.en.md`, `SKILL.pt.md`...). Runtime selecciona vía `KING_LANG` (default `es`) con fallback al
canónico si falta la traducción. **Las traducciones NO pueden cambiar la semántica de BLOCKING CONDITIONS ni
REQUIRED OUTPUTS** — regla explícita, mitigación de R-09 (divergencia semántica). El runtime KING_LANG depende de
soporte en Apex Core (M12 o posterior); el documento es solo policy.

### D10 — Por qué M-97 documenta un contrato, no implementa adapters

M-97 extiende el roadmap de plataformas más allá de las 11 actuales. Documenta criterios de priorización (≥3 de 6)
y la interface `AgentAdapter` (Detect/Install/ConfigureSkills/ConfigureHooks/ConfigureMCP/Verify) **ya definida en
M12** como contrato público para contributors externos. La implementación de adapters nuevos es trabajo de Apex
Core (Go), fuera de M13. La Feature Parity Matrix obliga a cada adapter a declarar qué soporta y a emitir warning
claro cuando una feature queda fuera.

## DAG de dependencias internas

Orden derivado de §5 del plan (líneas 1131-1143). La regla de oro: **trust ANTES que distribución; herramientas de
contribución ANTES que el catálogo que las usa.**

```
M-57 (trust-model) ──> M-62 (contributor-guide referencia tiers + firma GPG)
M-57 (trust-model) ──> M-56 (marketplace implementa la policy del trust model)
M-62 (contributor) ──> M-61 (templates se crean usando /create-skill mejorado)
M-61 (templates)   ──> M-60 (módulo 6 KFCD cubre community templates)
M-60 (certification)──> M-56 (hub muestra badge de certificación del publicador)
M-57 + M-62 + M-61 ──> M-56 (marketplace requiere estos tres items estables)
M-56 (hub spec)    ──> M-59 (tutoriales referencian cómo publicar en el hub)
M-21 (CASTLE spec) ──> M-59 (tutorial 3 cubre CASTLE en profundidad)
M-96 (i18n)        ──> M-97 (adapters deben soportar KING_LANG si la plataforma lo permite)
```

**Cadena crítica lineal** (la columna vertebral del módulo):

```
M-57 → M-62 → M-61 → M-60 → M-56
```

M-57 es la raíz: sin trust model, ni el contributor guide (M-62) ni el marketplace (M-56) tienen política que
referenciar. La cadena converge en M-56, que es además **fan-in** de M-57+M-62+M-61 simultáneamente.

**Subgrafos independientes** (no en la cadena crítica, paralelizables tras sus raíces):

```
M-21 → M-59      (estándar CASTLE alimenta el tutorial de profundidad)
M-96 → M-97      (i18n alimenta el roadmap de adapters)
```

**Dependencias con otros módulos** (entrantes, todas ya satisfechas en develop): M12 → M-56 (CLI `king-framework
skill *`); M11 → M-57, M-56 (`api_version` en frontmatter); M7 → M-61 (tenancy + auth en templates); M4 → M-60
(módulos A1-A4 KFCA); M9 → M-61 (templates browser-extension/desktop); M10 → M-61 (template mobile).

## Estrategia de 6 bloques de apply

Los knowledge nuevos son **independientes** dentro de su bloque → se autorían con un **Workflow fan-out** (un agente
por documento, cada uno recibe su sección §2 del plan + el delta spec + la anatomía v2.0). Las **extensiones a
archivos compartidos** (`create-skill/SKILL.md`, LOAD-INDEX) NO se paralelizan → edición secuencial manual aditiva.
Los bloques respetan el DAG: nunca se aplica un consumidor antes que su dependencia.

| Bloque | Foco | Items | Tareas (§6) | Paraleliza | Razón del corte |
|--------|------|-------|-------------|-----------|-----------------|
| **A1** | trust | M-57 | T-01..T-05 | sí (1 doc) | Raíz del DAG. Debe existir antes que M-62 y M-56. |
| **A2** | castle / i18n / adapters | M-21, M-96, M-97 | T-39..T-43, i18n+adapters | sí (3 docs) | Subgrafos independientes de la cadena crítica → se autoran en paralelo temprano. M-21 desbloquea M-59. |
| **A3** | contributor | M-62 | T-06..T-11 | parcial | Extensión aditiva a `create-skill/SKILL.md` (manual, secuencial) + `contributor-guide.md` nuevo. Requiere A1 (referencia tiers/GPG). |
| **A4** | templates | M-61 | T-12..T-21 | sí (10 docs) | Mayor fan-out (10 specs, 1 agente c/u). Requiere A3 (`/create-skill` mejorado). |
| **A5** | curriculum | M-60 | T-22..T-27 | parcial | Currículum (king-core) + skill/command de certificación (king-content). Requiere A4 (módulo 6 KFCD) y A2 (A3 KFCA mapea CASTLE Spec). |
| **A6** | hub | M-56, M-59 | T-28..T-38 | sí (docs) | Convergencia final. M-56 es fan-in de A1+A3+A4 (+A5 para badge). M-59 requiere M-56 y M-21 (A2). |

**Órdenes no negociables**:

- A1 (M-57) **siempre primero** — es la raíz; M-62, M-56 referencian `trust-model.md`.
- A2 puede correr en paralelo a A1 (independiente), pero M-21 debe estar listo antes de A6 (M-59 tutorial 3).
- A3 después de A1; la extensión de `create-skill/SKILL.md` es **append manual** + validación, en commit separado
  para aislar blast radius (archivo compartido crítico).
- A4 después de A3 (`/create-skill` mejorado genera los templates) y reusa skills de M7/M9/M10.
- A5 después de A4 (módulo 6 KFCD = community templates) y A2 (A3 KFCA mapea CASTLE Spec v1.0).
- A6 al final: M-56 requiere M-57+M-62+M-61 estables (fan-in) y M-60 para el badge; M-59 requiere M-56 y M-21.

## Patrón de implementación: Workflow fan-out

Knowledge + specs independientes → un agente por artefacto en su bloque, con contexto acotado (sección §2 + delta
spec + anatomía). Las extensiones a archivos compartidos (M-62 sobre `create-skill/SKILL.md`, LOAD-INDEX) → edición
manual secuencial, commits separados al cierre del bloque. Coherencia de referencias cruzadas (trust-model ↔
contributor-guide ↔ king-hub-spec ↔ castle-spec) verificada tras cada bloque, no al final.

## Verificación

`/sdd-verify` (verify-report) → `/qa --scope king-core` → `/castle-report`. Objetivo **CASTLE FORTIFIED**. El check
`npm run build` de `/merge` Fase 4 es **N/A** (plugin Markdown). Tests estructurales: `pytest` (self-tests).
git diff confirma que la única extensión (`create-skill/SKILL.md`) es aditiva. Verificación específica de M13:
fórmula Quality Score determinista (Gherkin T-31), invariante de no-gate-override del scanner (T-03), governance TC
con regla 2/3 + 60 días comment period (T-42), y todas las referencias cruzadas entre los 7 knowledge resuelven.

## Riesgos (resumen; ver §3 del plan, líneas 1049-1063)

R-01 skill malicioso no detectado → invariante no-gate-override en CI + CRL <48h + GPG en cliente. R-02 fricción de
contributors → Tier 4 sin fricción + scaffolding asistido + recognition. R-03 dilución del estándar → governance TC
2/3 + estándar desacoplado de la implementación. R-04 mappings erróneos → disclaimer + auditor externo. R-05 examen
gameseable → banco rotativo 200+ + portfolio humana. R-06 templates obsoletos → `last_reviewed` + flag a 6 meses.
R-07 spam en hub → Quality Score mínimo 40 + ratings + trust tier visible. R-08 tutoriales rotos → declarar
`required_skills` + aviso de incompatibilidad. R-09 divergencia i18n → aprobación native speaker + canónico español
como fuente de verdad ante duda semántica. Engram ambiguous_project → filesystem-first openspec.
