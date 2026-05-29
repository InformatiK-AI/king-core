# Delta Spec — plugin-trust-model (M-57)

## ADDED Requirements

### Requirement: Modelo de 4 Tiers de Confianza
El knowledge `knowledge/universal/trust-model.md` SHALL definir cuatro tiers de confianza
(1 Official, 2 Trusted Partners, 3 Community, 4 Local) con criterios objetivos de asignación,
proceso de verificación por tier y badge visible. Cada tier MUST especificar quién publica,
qué requiere, qué scanning aplica y qué garantías ofrece. Tier 4 (Local) MUST quedar sin
fricción de publicación (cero requisitos formales) como mitigación de la fricción de adopción.
El campo `trust_tier` del manifest MUST referenciar el tier definido aquí, y el tier declarado
MUST ser verificado por el pipeline (no auto-declarado libremente).

#### Scenario: Verificación de firma GPG al instalar skill Tier 3
- **Given** un skill publicado en el hub con `trust_tier` 3
- **And** el skill tiene una firma GPG válida (`.asc`) del autor
- **When** se ejecuta `king-framework skill install autor/skill-name`
- **Then** el CLI verifica la firma GPG contra el keyserver público (`keyserver.ubuntu.com` / `keys.openpgp.org`)
- **And** muestra el badge del tier del skill (gris para Tier 3)
- **And** completa la instalación exitosamente

### Requirement: Firma GPG y Verificación Atómica en el Cliente
El proceso de firma GPG SHALL usar RSA 4096 bits con expiración de 2 años y un email que MUST
coincidir con el email de GitHub verificado del autor. Cada package publicado MUST ir acompañado
de una firma desprendida ASCII-armored (`.asc`). Al instalar, el cliente SHALL ejecutar la cadena
de verificación (resolución de clave en keyservers, verificación criptográfica, no-expiración,
correspondencia tier↔clave y, con `--check-revocation`, consulta a la CRL) ANTES de escribir
cualquier archivo. Si cualquier paso falla, la instalación MUST abortar de forma atómica sin
escribir ningún archivo en el sistema, y el mensaje de error MUST indicar la causa exacta.

#### Scenario: Bloqueo de skill con firma GPG inválida
- **Given** un skill en el hub con firma GPG corrupta o expirada
- **When** se ejecuta `king-framework skill install autor/skill-corrupto`
- **Then** el CLI rechaza la instalación con un error explícito
- **And** el mensaje indica que la firma GPG no es válida
- **And** no se escribe ningún archivo en el sistema

### Requirement: Pipeline de Scanning Automático
El CI del repo `king-hub` SHALL ejecutar, para cada PR de publicación, un pipeline de scanning con
cinco verificaciones: Semgrep (severidad `ERROR` bloquea), Trivy (`CRITICAL`/`HIGH` sin fix
bloquea), Snyk OSS (`CRITICAL` bloquea, solo Tier 3), el CASTLE gate-override checker (siempre
bloquea) y el GPG signature validator (firma inválida o ausente bloquea). El documento MUST
especificar para cada herramienta qué detecta, su condición de bloqueo y a qué tiers aplica. El
pipeline SHOULD reutilizar las herramientas del workflow `framework-quality.yml` (M11/M-75).

### Requirement: Invariante Absoluta de No-Gate-Override
Ningún skill MUST declarar que sobrescribe, deshabilita o anula un gate CASTLE Tier 1 del
framework; esta invariante NO admite excepciones. Un gate CASTLE Tier 1 MUST NOT ser marcado nunca
como `continue-on-error`. El `CASTLE gate-override checker` SHALL verificar que el `SKILL.md`
propuesto no contiene instrucciones que anulen un `BLOCKING CONDITION` de cualquier skill Tier 1
de `king-core`. Cuando detecte una violación, el check SHALL fallar con el error
`Gate override detected in SKILL.md`, el PR de publicación MUST NOT poder mergearse, y el autor
SHALL recibir feedback señalando la línea exacta que viola la invariante.

#### Scenario: Scanner bloquea skill que intenta sobrescribir gate CASTLE
- **Given** un skill con `SKILL.md` que contiene instrucciones que anulan un `BLOCKING CONDITION` de king-core
- **When** el CI del hub corre el gate-override-checker sobre ese skill
- **Then** el check falla con el error `Gate override detected in SKILL.md`
- **And** el PR de publicación no puede ser mergeado
- **And** el autor recibe feedback específico sobre qué línea viola el invariante

### Requirement: Revocación con CRL Pública
El proceso de revocación SHALL permitir retirar un skill comprometido del ecosistema en
**< 48 horas** para Tier 3. Tier 1 y 2 MAY ser revocados inmediatamente por el equipo core vía
`king-framework skill revoke <autor>/<skill>`; Tier 3 SHALL requerir un issue en el repo `king-hub`
más votación de 3 maintainers. Al revocar, el hash del package MUST añadirse a la CRL pública
alojada en `hub.kingframework.dev/crl`, el skill MUST desaparecer de los resultados de búsqueda, y
los clientes que intenten instalarlo MUST recibir un error de revocación. Los clientes SHALL
consultar la CRL al instalar cuando se ejecuta `king-framework skill update --check-revocation`.

#### Scenario: Revocación de skill comprometido en Tier 3
- **Given** un skill Tier 3 publicado que es comprometido post-publicación
- **When** el equipo core ejecuta `king-framework skill revoke autor/skill-name`
- **Then** el hash del package es añadido a la CRL pública
- **And** los clientes que intenten instalar ese skill reciben error de revocación
- **And** el skill desaparece de los resultados de búsqueda en el hub

### Requirement: Integración con el Marketplace (M-56)
El `trust-model.md` SHALL ser la política que el backend del `king-hub` (M-56) implementa. El campo
`trust_tier` del manifest MUST referenciar el tier verificado, y la UI del marketplace MUST mostrar
el badge correspondiente (azul/verde/gris/sin badge). El documento SHALL referenciar
`king-hub-spec.md`, `contributor-guide.md` y `castle-spec-v1.md` para mantener la coherencia de
referencias cruzadas del ecosistema.

> Set Gherkin completo: M13 §7 (Feature: Trust Model con 4 tiers), líneas 1243-1274.
