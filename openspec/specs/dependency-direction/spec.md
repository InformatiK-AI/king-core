# dependency-direction — Delta Spec

> Capability 3 del change a6-king-arch-decouple. Regla arquitectónica invariante del ecosistema King.

## ADDED Requirements

### Requirement: king-core nunca depende de king-arch

king-arch MUST declarar `requires: ["king-framework"]`. king-core MUST NOT declarar ninguna dependencia hacia
king-arch en su `plugin.json` ni asumir su presencia para funcionar. La relación es unidireccional: el hijo
(king-arch) lee del kernel (king-core) cross-plugin, nunca al revés.

#### Scenario: Manifiesto de king-core sin dependencia inversa
- **GIVEN** el decouple aplicado
- **WHEN** se inspecciona `king-core/.claude-plugin/plugin.json`
- **THEN** NO contiene `king-arch` en ningún campo `requires`/`dependencies`
- **AND** su `description` marca las skills de arquitectura como "ahora en king-arch — referencia opcional"

#### Scenario: king-arch lee agentes y knowledge compartido del kernel
- **GIVEN** king-arch instalado junto a king-core
- **WHEN** una de las 12 skills necesita `@architect`, `architecture-patterns.md` o `skills/session-management/`
- **THEN** los resuelve cross-plugin desde king-core (que los retiene como kernel)
- **AND** no existe copia divergente de esos recursos en king-arch (salvo `_shared/` duplicado por fragilidad de path)

### Requirement: Registro instalable en el marketplace

king-arch MUST aparecer en `proyectos referencia/King/king-marketplace/.claude-plugin/marketplace.json` como entrada
del array `plugins[]`, con su `source` apuntando al repo, para ser instalable y resolver `requires:[king-framework]`.

#### Scenario: Entrada de king-arch en el marketplace
- **GIVEN** el decouple aplicado
- **WHEN** se parsea `marketplace.json`
- **THEN** es JSON válido
- **AND** `plugins[]` incluye una entrada `king-arch`
