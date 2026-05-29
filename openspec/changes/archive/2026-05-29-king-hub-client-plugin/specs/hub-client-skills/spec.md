# hub-client-skills — Delta Spec

> Los 4 skills cliente del King Hub. Capability del change king-hub-client-plugin.

## ADDED Requirements

### Requirement: 4 skills v2.0 con diseño híbrido

El plugin `king-hub` MUST proveer 4 skills (`hub-search`, `hub-install`, `hub-publish`, `hub-stats`) en anatomía v2.0.
Cada skill MUST orquestar el CLI `king-framework skill *` como ruta primaria y MUST degradar graceful al flujo HTTP+GPG
directo contra el backend (`KING_HUB_URL`) cuando el CLI no esté disponible.

#### Scenario: Skills presentes y verificables
- **GIVEN** el plugin king-hub
- **WHEN** se inspecciona `skills/`
- **THEN** existen hub-search, hub-install, hub-publish, hub-stats con SKILL.md v2.0 + REFERENCE.md
- **AND** audit_self da health ≥ 75 (paridad con plugins hijos) y check_api_version pasa

#### Scenario: Fallback graceful sin CLI
- **GIVEN** el CLI `king-framework` NO está instalado
- **WHEN** se invoca cualquier hub-* skill
- **THEN** el skill ejecuta el flujo directo (curl al backend + gpg) sin fallar por ausencia del CLI

### Requirement: hub-install con fallo atómico

`hub-install` MUST verificar (firma GPG detached + no-expiración + tier↔clave + CRL) ANTES de escribir, y MUST abortar
sin escribir nada si cualquier paso falla (fallo atómico, trust-model §2.3). `--force` MUST NOT saltar la verificación
criptográfica (solo la incompatibilidad de versión).

#### Scenario: Verificación fallida no escribe
- **GIVEN** un package con firma inválida o hash revocado
- **WHEN** se ejecuta hub-install
- **THEN** aborta con el motivo exacto y NO escribe en `skills/`

### Requirement: hub-publish no publica skills inválidos

`hub-publish` MUST validar el manifest (schema §3) y verificar ausencia de gate-overrides localmente antes de firmar y
enviar. NUNCA MUST publicar con manifest inválido o gate-override.

#### Scenario: Manifest inválido se rechaza pre-envío
- **GIVEN** un manifest sin `castle_layers` o con `api_version` no semver
- **WHEN** se ejecuta hub-publish
- **THEN** reporta los campos a corregir y NO sube nada
