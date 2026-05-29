# Delta Spec — contributor-experience (M-62)

## ADDED Requirements

### Requirement: Scaffolding automatizado en `/create-skill`
El skill `/create-skill` SHALL generar la estructura completa de un skill nuevo desde el template
canónico v2.0 (`skills/_templates/skill-template-v2.md`). La generación MUST producir el directorio
`skills/{nombre}/`, un `SKILL.md` con todos los placeholders reemplazados, `references/.gitkeep`,
`scripts/.gitkeep`, y MUST actualizar `LOAD-INDEX.md` con la nueva entrada. La detección de colisión
de nombre MUST ejecutarse ANTES de crear cualquier archivo: si el nombre colisiona con un skill
existente, el skill NO SHALL crear ningún archivo ni directorio.

#### Scenario: Scaffolding genera estructura completa
- **Given** que ejecuto `/create-skill analytics-tracker`
- **When** el skill procesa el nombre y no hay colisión
- **Then** crea el directorio `skills/analytics-tracker/`
- **And** genera `skills/analytics-tracker/SKILL.md` con los placeholders reemplazados (name=analytics-tracker, date actual, api_version=1.0.0)
- **And** crea `skills/analytics-tracker/references/.gitkeep`
- **And** crea `skills/analytics-tracker/scripts/.gitkeep`
- **And** actualiza `LOAD-INDEX.md` con la nueva entrada

#### Scenario: Colisión de nombre detectada antes de crear
- **Given** que ya existe `skills/build/` en el repo
- **When** ejecuto `/create-skill build`
- **Then** el skill detecta la colisión antes de crear cualquier archivo
- **And** presenta el skill existente al usuario
- **And** pregunta si es una extensión del skill existente o un nuevo skill distinto
- **And** no crea ningún directorio ni archivo hasta recibir respuesta

### Requirement: Checklist de Publicación Tier 3 en `/create-skill`
El `SKILL.md` de `/create-skill` SHALL incluir una checklist de publicación para Tier 3 (Hub) con
tres secciones: calidad mínima, identidad del publicador (GPG) y proceso de publicación (PR). La
checklist MUST referenciar `knowledge/universal/trust-model.md` para el proceso de firma y por tier,
MUST referenciar `knowledge/universal/contributor-guide.md` para el style guide, y MUST incluir el
formato del `manifest.json` requerido con los campos `name`, `version`, `api_version`, `author`,
`description`, `trust_tier`, `tags`, `castle_layers`. La extensión del SKILL.md MUST ser aditiva:
no SHALL eliminar contenido existente del skill v2.0.

#### Scenario: Checklist de publicación cubre los requisitos de Tier 3
- **Given** que un contributor quiere publicar un skill en el hub
- **When** consulta el `SKILL.md` de `/create-skill` buscando requisitos de publicación
- **Then** encuentra la checklist completa con secciones de calidad mínima, identidad GPG y proceso de PR
- **And** la checklist referencia `trust-model.md` para el proceso de firma
- **And** la checklist incluye el formato del `manifest.json` requerido

### Requirement: Contributor Guide canónico
El framework SHALL proveer `knowledge/universal/contributor-guide.md` (sin frontmatter, en español)
con: Style Guide para skills (naming kebab-case, idioma español, estructura de fases, descripción
para auto-triggering, capas CASTLE, reporte final), Testing Guide (mínimo 3 scenarios Gherkin
cubriendo happy path, error e idempotencia), Publishing Guide que referencia `trust-model.md`,
Recognition Program y sección "Cómo conseguir ayuda".

#### Scenario: La guía cubre el style guide completo y referencia el trust model
- **Given** el archivo `knowledge/universal/contributor-guide.md`
- **When** un contributor lo revisa antes de escribir un skill
- **Then** encuentra reglas de naming kebab-case, idioma español y estructura de fases (GATE IN / MUST DO / CHECKPOINT)
- **And** encuentra la regla de mínimo 3 scenarios Gherkin para publicación Tier 3
- **And** la Publishing Guide referencia `knowledge/universal/trust-model.md`

> Set Gherkin completo: M13 §7 (Feature: /create-skill con scaffolding automatizado).
