# king-arch-extraction — Delta Spec

> Capability 1 del change a6-king-arch-decouple. Precedente: A3 (decouple king-content/king-infra).

## ADDED Requirements

### Requirement: Plugin king-arch con las 12 skills de arquitectura

El nuevo plugin `king-arch` MUST contener exactamente las 12 skills de patrones de arquitectura movidas desde
king-core, cada una con su command pareado, y MUST replicar la anatomía de un plugin hijo (espejo de king-infra):
`.claude-plugin/plugin.json`, `commands/`, `knowledge/domain/`, `skills/` (con `_shared/` duplicado), `CHANGELOG.md`,
`openspec/`. NO MUST incluir `agents/`, `hooks/` ni `LOAD-INDEX.md`.

#### Scenario: Skills movidas presentes en king-arch
- **GIVEN** el decouple A6 aplicado
- **WHEN** se inspecciona `king-arch/skills/`
- **THEN** existen exactamente estas 12 carpetas con su `SKILL.md`: clean-arch-setup, hexagonal-setup, ddd-tactical,
  cqrs-setup, event-sourcing, saga-design, resilience-weave, idempotency, api-contract-first, contract-test-pact,
  microservice-extract, event-broker-setup
- **AND** `king-core/skills/` ya NO contiene ninguna de las 12

#### Scenario: Commands movidos junto a sus skills
- **GIVEN** el decouple aplicado
- **WHEN** se inspecciona `king-arch/commands/`
- **THEN** existen los 12 `*.md` correspondientes a las 12 skills
- **AND** `king-core/commands/` ya NO contiene esos 12 (pero SÍ conserva `contract-test.md`, `solid-check.md`,
  `optimize.md`, `refactor.md`)

#### Scenario: Knowledge exclusivo movido, knowledge compartido retenido
- **GIVEN** el decouple aplicado
- **WHEN** se inspecciona `king-arch/knowledge/domain/`
- **THEN** contiene `saga-patterns.md` y `distributed-systems.md`
- **AND** `king-core/knowledge/domain/` conserva `architecture-patterns.md`, `resilience-patterns.md` y
  `orm-patterns.md` (compartidos con kernel/agentes/hooks)

#### Scenario: _shared duplicado, no cross-read frágil
- **GIVEN** alguna de las 12 skills referencia `skills/_shared/<archivo>` por path relativo
- **WHEN** se construye king-arch
- **THEN** `king-arch/skills/_shared/` contiene una copia de cada `_shared/*` realmente referenciado por las 12
- **AND** las 12 skills resuelven sus referencias `_shared/` intra-plugin

### Requirement: Manifiesto de king-arch

`king-arch/.claude-plugin/plugin.json` MUST declarar `name: "king-arch"`, `version: "1.0.0"`,
`requires: ["king-framework"]`, y una `description` que enumere las 12 skills por dominio. MUST ser JSON válido.

#### Scenario: plugin.json válido y con requires
- **GIVEN** king-arch creado
- **WHEN** se parsea `king-arch/.claude-plugin/plugin.json`
- **THEN** es JSON válido
- **AND** `requires` incluye `"king-framework"`
- **AND** `version` es `"1.0.0"`
