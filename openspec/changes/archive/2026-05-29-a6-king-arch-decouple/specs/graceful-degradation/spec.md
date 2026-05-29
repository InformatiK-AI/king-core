# graceful-degradation — Delta Spec

> Capability 2 del change a6-king-arch-decouple. king-core debe funcionar SIN king-arch instalado.

## ADDED Requirements

### Requirement: Referencias king-core → skill movida son graceful

Toda referencia en king-core (kernel) a una de las 12 skills movidas MUST anotarse con el sufijo
`"(king-arch, si está instalado)"` y MUST degradar sin error cuando king-arch no está presente (log warning +
continuar). king-core NUNCA MUST bloquear ni fallar por ausencia de king-arch.

#### Scenario: @architect recomienda patrón sin king-arch instalado
- **GIVEN** king-arch NO está instalado
- **WHEN** `@architect` (o `sdd-apply`) recorre su árbol de decisión de arquitectura
- **THEN** recomienda el patrón usando `knowledge/domain/architecture-patterns.md` (que queda en king-core)
- **AND** anota el comando de scaffolding como "(king-arch, si está instalado)"
- **AND** NO produce un error; el fallback "follow the existing project pattern" sigue disponible

#### Scenario: Hooks sugieren comando de king-arch sin romperse
- **GIVEN** king-arch NO está instalado
- **WHEN** `hooks/resilience-check.sh` o `hooks/api-change-check.sh` detectan su patrón en código del usuario
- **THEN** emiten su WARNING con `exit 0`
- **AND** el texto sugerido nombra el comando con "(king-arch, si está instalado)"
- **AND** NO bloquean la operación (enforcement = warn)

#### Scenario: Ninguna referencia dura sobrevive
- **GIVEN** el decouple aplicado
- **WHEN** se hace grep en el kernel de king-core de los 12 slash-commands movidos
- **THEN** toda ocurrencia en archivos del kernel está anotada graceful
- **AND** no queda ningún path duro a `skills/<skill-movida>/` desde king-core
