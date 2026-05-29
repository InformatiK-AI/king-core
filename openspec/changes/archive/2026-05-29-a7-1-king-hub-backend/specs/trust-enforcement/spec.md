# trust-enforcement — Delta Spec

> Verificación GPG, tiers, CRL, Quality Score y validación de manifest. Capability del change a7-1.
> El backend IMPLEMENTA la policy de `trust-model.md`, no la redefine.

## ADDED Requirements

### Requirement: Verificación GPG y asignación de tier en publish

`POST /skills` MUST verificar la firma GPG detached (`.asc`) contra el package; la clave MUST no estar expirada y su
email MUST coincidir con el GitHub del autor. El servicio MUST asignar `trust_tier` como campo **derivado** (calculado
de la verificación), NUNCA confiando en el valor declarado por el autor.

#### Scenario: Publish con firma válida Tier 3
- **GIVEN** un package + `.asc` firmado con la clave personal del autor (RSA 4096, no expirada)
- **WHEN** `POST /skills`
- **THEN** la firma se verifica OK, se asigna trust_tier 3, se calcula Quality Score y se persiste
- **AND** los campos derivados enviados por el autor (downloads/rating/published_at) se ignoran y recalculan

#### Scenario: Publish con firma inválida o ausente
- **GIVEN** un package sin `.asc` o con firma que no valida
- **WHEN** `POST /skills`
- **THEN** se rechaza (4xx) sin persistir nada

#### Scenario: Namespace protegido por GPG
- **GIVEN** el namespace `autorA/*` ya tiene skills publicados por autorA
- **WHEN** autorB intenta publicar `autorA/skill-x`
- **THEN** se rechaza (solo la clave del dueño del namespace puede publicar)

### Requirement: Quality Score determinista

El servicio MUST calcular el Quality Score con la fórmula §5.1 (determinista: mismo input → mismo score, cap 100).
MUST recalcularlo al publicar y semanalmente (cron). Un skill con solo lo mínimo (api_version válido + castle_layers +
≥5 Gherkin) MUST alcanzar ≥ 40 (invariante §5.3).

#### Scenario: Invariante mínimo-40
- **GIVEN** un manifest con api_version semver válido + castle_layers no vacío + 5 escenarios Gherkin (sin rating ni references)
- **WHEN** se calcula el Quality Score
- **THEN** el score es exactamente 50 (≥ 40 → buscable)

#### Scenario: Determinismo
- **GIVEN** el mismo manifest + mismo rating_avg
- **WHEN** se calcula el score dos veces
- **THEN** ambos resultados son idénticos

### Requirement: CRL (Certificate Revocation List)

El servicio MUST servir `GET /crl` como JSON con los hashes SHA-256 de packages revocados (firmado por el equipo core).
MUST rechazar publish/download de hashes revocados y excluirlos de search.

#### Scenario: Descarga de package revocado
- **GIVEN** un package cuyo hash está en la CRL
- **WHEN** se intenta `GET .../download/{version}`
- **THEN** se rechaza con error de revocación explícito (no 302)

### Requirement: Validación de manifest

El servicio MUST validar el manifest (§3): campos requeridos presentes; `version`/`api_version` semver válido;
`castle_layers` array no vacío de letras CASTLE; `name` == `author.github/<skill>`. Validación PURA y unit-testeable.

#### Scenario: Manifest con api_version inválido
- **GIVEN** un manifest con `api_version: "1.2"` (no semver completo)
- **WHEN** se valida
- **THEN** la validación lo marca inválido (y el Quality Score pierde los 15 puntos de api_version)
