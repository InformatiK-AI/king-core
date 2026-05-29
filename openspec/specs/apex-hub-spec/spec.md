# Delta Spec — apex-hub-spec (M-56)

## ADDED Requirements

### Requirement: Spec del Marketplace `king-hub`
El knowledge `knowledge/universal/king-hub-spec.md` SHALL documentar la spec completa del
marketplace oficial de skills del King Framework: arquitectura del plugin `king-hub`, schema
del manifest, CLI de 7 comandos, fórmula de Quality Score determinista, backend (HTTP REST +
PostgreSQL + S3) y governance. El documento MUST ser **spec-only**: la implementación del
backend NO es parte de M13. El documento SHALL referenciar `trust-model.md` (M-57),
`contributor-guide.md` (M-62) y `community-templates/` (M-61) como prerequisitos cuya policy
el hub **implementa** (no redefine).

#### Scenario: Documento spec-only autocontenido
- **Given** el archivo `knowledge/universal/king-hub-spec.md`
- **When** reviso su scope declarado
- **Then** establece explícitamente que M13 entrega solo la spec y que el backend (Go, PostgreSQL, S3) no se implementa
- **And** referencia M-57 (trust-model), M-62 (contributor-guide) y M-61 (community-templates) como prerequisitos

### Requirement: Schema del Manifest con campos tipados
La sección de Manifest Schema SHALL definir todos los campos requeridos con su tipo de dato:
`name`, `version`, `api_version`, `king_framework_version`, `author` (objeto con `github` y
`gpg_key_id`), `trust_tier`, `description`, `tags` y `castle_layers`. Cada campo MUST tener
tipo especificado. La spec SHALL incluir al menos un ejemplo de `manifest.json` válido y
completo. Los campos derivados (`downloads`, `rating`, `published_at`) MUST marcarse como
escritos por el hub, no por el autor.

#### Scenario: Manifest schema tiene todos los campos requeridos
- **Given** el archivo `knowledge/universal/king-hub-spec.md`
- **When** reviso la sección de Manifest Schema
- **Then** el schema incluye `name`, `version`, `api_version`, `king_framework_version`, `author` (con `github` y `gpg_key_id`), `trust_tier`, `description`, `tags` y `castle_layers`
- **And** cada campo tiene tipo de dato especificado
- **And** hay un ejemplo de manifest válido completo

### Requirement: CLI de 7 comandos para el ciclo de gestión
La sección de CLI Commands SHALL documentar exactamente 7 comandos: `search`, `install`,
`update`, `publish`, `info`, `verify` y `uninstall`. Cada comando MUST tener sintaxis, flags
disponibles y un ejemplo de output esperado. `search` SHALL devolver únicamente skills con
Quality Score ≥ 40. `install` SHALL verificar firma GPG y compatibilidad antes de escribir.
`verify` SHALL operar localmente sin requerir conexión al hub.

#### Scenario: CLI commands cubren el ciclo completo de gestión
- **Given** la sección de CLI Commands en `king-hub-spec.md`
- **When** cuento los comandos documentados
- **Then** hay exactamente 7 comandos: `search`, `install`, `update`, `publish`, `info`, `verify`, `uninstall`
- **And** cada comando tiene sintaxis, flags disponibles y ejemplo de output esperado

### Requirement: Quality Score determinista
La sección de Quality Score SHALL definir una fórmula aritmética cerrada (sin ML ni juicio
humano) donde el mismo input produce siempre el mismo score. El score máximo posible MUST ser
100 y el umbral mínimo para aparecer en búsqueda MUST ser 40. La spec SHALL demostrar que un
skill con solo las características mínimas (Tier 3, `api_version` semver válido, `castle_layers`
declaradas, ≥ 5 escenarios Gherkin) obtiene al menos 40. Quality Score y Trust Tier SHALL
documentarse como dimensiones ortogonales.

#### Scenario: Quality Score fórmula es determinista y documentada
- **Given** un skill de ejemplo con características conocidas
- **When** aplico la fórmula de Quality Score de la spec
- **Then** el score calculado es determinista (mismo input = mismo score)
- **And** el score máximo posible es 100
- **And** un skill con solo las características mínimas (Tier 3, `api_version` válido, CASTLE layers declarados, 5 Gherkin) obtiene al menos 40

### Requirement: Backend, Compatibility Matrix y Governance
La spec SHALL documentar el backend de implementación futura con al menos 6 endpoints (`GET
/skills`, `GET /skills/{autor}/{name}`, `POST /skills`, `GET .../download/{version}`, `POST
.../rate`, `GET /crl`) y las reglas de negocio (namespace por autor, downgrade libre vs upgrade
con re-review, rate limiting, CRL firmada). La Compatibility Matrix SHALL especificar que una
incompatibilidad de `king_framework_version` produce WARNING (no bloqueo) y que el usuario
puede forzar con `--force`. La sección de Governance SHALL referenciar el uso de `github-ops`
para crear el repo `king-framework/king-hub` y configurar su CI.

#### Scenario: Backend define endpoints y reglas de negocio
- **Given** la sección de Backend Architecture en `king-hub-spec.md`
- **When** cuento los endpoints documentados
- **Then** hay al menos 6 endpoints incluyendo `/skills`, detalle, publish, download, rate y `/crl`
- **And** las reglas de negocio cubren namespace por autor, política de tiers, rate limiting y CRL

#### Scenario: Incompatibilidad de versión avisa pero no bloquea
- **Given** un skill cuyo `king_framework_version` no es compatible con la versión del usuario
- **When** el usuario ejecuta `king-framework skill install autor/skill-legacy`
- **Then** el CLI muestra un WARNING explícito de incompatibilidad
- **And** no bloquea la instalación: el usuario puede proceder con `--force`

> Set Gherkin completo: M13 §7 (Feature: Spec completa del marketplace king-hub).
