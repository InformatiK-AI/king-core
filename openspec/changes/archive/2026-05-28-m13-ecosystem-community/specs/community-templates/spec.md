# Delta Spec — community-templates (M-61)

> Capability: `community-templates` · Change: m13-ecosystem-community · Backend: openspec
> Fuente de verdad: `mejora/planes-detallados/M13-ecosystem-community-distribution.md` (§6 M-61, §7 acceptance).

## ADDED Requirements

### Requirement: Catálogo de 10 Community Templates oficiales

King SHALL publicar exactamente **10** specs de template oficial en
`knowledge/universal/community-templates/`, una por archivo, con la nomenclatura numerada
`NN-{nombre}-starter.md`. Cada spec es un **documento markdown** (no código): describe qué genera
`/genesis` cuando se elige ese template. Los 10 archivos MUST ser:

| Archivo | Template (`{nombre}`) |
|---------|------------------------|
| `01-saas-b2b-starter.md` | `saas-b2b-starter` |
| `02-saas-b2c-starter.md` | `saas-b2c-starter` |
| `03-marketplace-starter.md` | `marketplace-starter` |
| `04-mobile-app-starter.md` | `mobile-app-starter` |
| `05-api-only-starter.md` | `api-only-starter` |
| `06-data-pipeline-starter.md` | `data-pipeline-starter` |
| `07-ai-agent-starter.md` | `ai-agent-starter` |
| `08-cli-tool-starter.md` | `cli-tool-starter` |
| `09-browser-extension-starter.md` | `browser-extension-starter` |
| `10-desktop-app-starter.md` | `desktop-app-starter` |

El nombre del template (`{nombre}`) MUST coincidir con el nombre del archivo sin el prefijo numérico
`NN-` y sin la extensión `.md`. Los specs SHALL escribirse en **español canónico** (King es canónico
en español) y en **UTF-8 sin BOM**.

#### Scenario: El catálogo contiene los 10 templates con nomenclatura correcta
- **Given** el directorio `knowledge/universal/community-templates/`
- **When** listo sus archivos `.md`
- **Then** existen exactamente 10 archivos numerados `01-` a `10-`
- **And** cada nombre de archivo termina en `-starter.md`
- **And** no falta ninguno de los 10 nombres canónicos de la tabla

#### Scenario: El nombre del template deriva del nombre del archivo
- **Given** cualquiera de los 10 archivos, p.ej. `03-marketplace-starter.md`
- **When** extraigo el `{nombre}` quitando el prefijo `NN-` y la extensión `.md`
- **Then** obtengo `marketplace-starter`
- **And** ese mismo `{nombre}` es el que aparece en el comando de la sección «Cómo usar» del archivo

---

### Requirement: Cada template DEBE tener las 6 secciones obligatorias

Cada uno de los 10 template specs SHALL contener, en este orden, las **6 secciones obligatorias** con
encabezado markdown `## `:

1. `## Stack` — listado de tecnologías exactas **con versiones** (p.ej. `Next.js 15`).
2. `## Skills King pre-configurados` — lista de skills activos por defecto en `.king/config`.
3. `## Estructura de proyecto generada` — árbol de directorios que `/genesis` produce.
4. `## CASTLE configuration` — qué capas C·A·S·T·L·E están activas y qué gates específicos aplican.
5. `## CI/CD incluido` — workflow YAML por defecto y plataforma de deploy target.
6. `## Decisiones de diseño` — justificación del POR QUÉ del stack.

Adicionalmente, cada spec MUST incluir las secciones de soporte `## Tests incluidos` (framework de
test + cobertura mínima) y `## Cómo usar` (comando de invocación). La sección `## Decisiones de diseño`
MUST contener **al menos 3 bullets**, cada uno justificando una elección de stack (el QUÉ **y** el POR
QUÉ, no solo el QUÉ). La ausencia de cualquiera de las 6 secciones obligatorias, o menos de 3 bullets
de decisión, MUST tratarse como spec inválida.

#### Scenario: Las 6 secciones obligatorias están presentes en cada template
- **Given** cualquiera de los 10 template specs
- **When** reviso sus encabezados `## `
- **Then** contiene las secciones: `Stack`, `Skills King pre-configurados`, `Estructura de proyecto generada`, `CASTLE configuration`, `CI/CD incluido` y `Decisiones de diseño`
- **And** las 6 aparecen en ese orden relativo

#### Scenario: Decisiones de diseño tienen justificación suficiente
- **Given** la sección `## Decisiones de diseño` de cualquier template spec
- **When** cuento sus bullets
- **Then** hay al menos 3 bullets
- **And** cada bullet explica POR QUÉ se eligió la tecnología (no solo la nombra)

#### Scenario: Stack declara versiones explícitas
- **Given** la sección `## Stack` de cualquier template spec
- **When** reviso las tecnologías listadas
- **Then** las tecnologías versionables incluyen versión (p.ej. `Next.js 15`, `Vitest 2`)
- **And** la sección no se limita a nombres sin contexto de versión

---

### Requirement: `saas-b2b-starter` incluye auth-scaffold, multi-tenancy enforcer y CASTLE completo

El template `01-saas-b2b-starter.md` SHALL ser el template de referencia de seguridad multi-tenant.
Su sección `## Skills King pre-configurados` MUST incluir explícitamente **auth-scaffold** (M6) y
**multi-tenancy enforcer** (M7) como skills activos por defecto, además de `/genesis`, `/build`,
`/deploy`, `/promote` y `/health-check`. Su sección `## CASTLE configuration` MUST declarar las
**6 capas C·A·S·T·L·E completas y activas** (Contracts, Architecture, Security, Testing, Logging,
Environment). Su sección `## CI/CD incluido` MUST incluir el **CASTLE check** vía
`king-framework/check-action` en el workflow de GitHub Actions.

El stack de referencia SHALL ser: Next.js 15 (App Router) + Supabase (Postgres + Auth + Storage) +
Stripe (subscriptions) + Resend (email transaccional) + Vercel (deploy), con Vitest + Playwright y
cobertura mínima de 80%.

#### Scenario: saas-b2b referencia los skills de auth y tenancy
- **Given** el archivo `community-templates/01-saas-b2b-starter.md`
- **When** reviso la sección `## Skills King pre-configurados`
- **Then** incluye `auth-scaffold` y `multi-tenancy enforcer` como skills activos
- **And** incluye además `/genesis`, `/build`, `/deploy`, `/promote` y `/health-check`

#### Scenario: saas-b2b activa CASTLE completo (C·A·S·T·L·E)
- **Given** la sección `## CASTLE configuration` de `01-saas-b2b-starter.md`
- **When** reviso las capas declaradas
- **Then** las 6 capas C·A·S·T·L·E están activas (Contracts, Architecture, Security, Testing, Logging, Environment)
- **And** ninguna capa figura como desactivada o relajada

#### Scenario: saas-b2b corre el CASTLE check en CI
- **Given** la sección `## CI/CD incluido` de `01-saas-b2b-starter.md`
- **When** reviso el workflow de GitHub Actions descrito
- **Then** incluye el CASTLE check vía `king-framework/check-action`
- **And** el workflow contempla preview deploy por PR y producción en merge a `main`

---

### Requirement: Templates invocables vía `king-framework genesis --template {nombre}`

Cada uno de los 10 template specs SHALL incluir una sección `## Cómo usar` con el comando de invocación
**exacto**:

```
king-framework genesis --template {nombre}
```

donde `{nombre}` MUST ser el nombre canónico del template (nombre de archivo sin prefijo `NN-` ni
extensión `.md`). El comando es el contrato que `/genesis` consumirá en una fase futura de
implementación para saber qué generar; los specs **no** implementan `/genesis`, solo definen el
contrato de invocación. El `{nombre}` del comando MUST coincidir exactamente con el `{nombre}` derivado
del archivo (sin alias ni variantes).

#### Scenario: Cada template documenta el comando genesis exacto
- **Given** cualquiera de los 10 template specs
- **When** reviso la sección `## Cómo usar`
- **Then** incluye el comando `king-framework genesis --template {nombre}`
- **And** `{nombre}` es el nombre del template (nombre de archivo sin prefijo numérico ni `.md`)

#### Scenario: El nombre del comando coincide con el del archivo
- **Given** el archivo `07-ai-agent-starter.md`
- **When** leo la sección `## Cómo usar`
- **Then** el comando es exactamente `king-framework genesis --template ai-agent-starter`
- **And** el `{nombre}` no introduce alias, mayúsculas ni separadores distintos a los del nombre de archivo

---

### Requirement: Metadato de frescura para mantenimiento del catálogo

Cada template spec SHALL declarar un metadato `last_reviewed` (fecha ISO `AAAA-MM-DD`) que permita al
hub (M-56) detectar templates obsoletos. Un template con `last_reviewed` mayor a **6 meses** respecto a
la fecha actual MUST poder marcarse como «maintenance needed». Esta mitigación corresponde al riesgo
R-06 (templates desactualizados a medida que los stacks evolucionan) del plan §3.

#### Scenario: El template declara fecha de última revisión
- **Given** cualquiera de los 10 template specs
- **When** reviso su metadato de cabecera
- **Then** existe un campo `last_reviewed` con fecha en formato `AAAA-MM-DD`
- **And** la fecha es interpretable para calcular antigüedad contra la fecha actual

> Set Gherkin completo de referencia: M13 §7 (Feature: 10 Community Templates con spec completa).
> Estructura de las 6 secciones: M13 §6 M-61 (líneas 318-346).
