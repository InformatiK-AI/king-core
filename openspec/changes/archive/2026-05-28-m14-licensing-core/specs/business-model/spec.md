# business-model — Delta Spec (M-95)

> Reusa Gherkin de `mejora/planes-detallados/M14-business-model-monetization.md §7 M-95`.

## ADDED Requirements

### Requirement: Documentación del modelo de negocio y licencia BSL 1.1

El knowledge file `knowledge/universal/business-model.md` MUST declarar legalmente qué es gratis y qué
requiere licencia, con la tabla completa de tiers, el ICP por segmento, el roadmap de monetización y un FAQ
legal. El texto de licencia MUST estar adaptado de Business Source License 1.1.

#### Scenario: Developer consulta qué puede usar gratis
- **GIVEN** existe `knowledge/universal/business-model.md`
- **WHEN** un developer lee la sección de tiers
- **THEN** encuentra qué skills están en King Core (gratis) y cuáles requieren King Pro
- **AND** entiende que el uso no-comercial es libre bajo BSL 1.1

#### Scenario: Enterprise evalúa compliance legal
- **GIVEN** existe `business-model.md` con texto BSL 1.1 adaptado
- **WHEN** un procurement officer lo revisa
- **THEN** encuentra la definición de "uso comercial"
- **AND** encuentra la conversión automática a Apache 2.0 a los 4 años
- **AND** puede determinar si su caso de uso requiere licencia

#### Scenario: El documento describe todos los tiers
- **GIVEN** el archivo `business-model.md`
- **WHEN** se revisa la tabla de tiers
- **THEN** lista King Core ($0), King Pro ($29/mes), King Team ($99/mes), King Enterprise ($499/mes),
  King Enterprise+ ($1.499/mes) y Certificación KFCD ($299/examen)
- **AND** cada tier enumera qué incluye

#### Scenario: Roadmap de monetización presente
- **GIVEN** la sección roadmap de `business-model.md`
- **WHEN** se la consulta
- **THEN** describe las fases v1.9 → v2.0 → v2.5 → v3.0 con metas de MRR
