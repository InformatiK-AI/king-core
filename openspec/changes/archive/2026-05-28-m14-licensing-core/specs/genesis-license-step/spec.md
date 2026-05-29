# genesis-license-step — Delta Spec (Bloque C)

> Extensión aditiva a `skills/genesis/GENERATION.md`. Fuente: M14 §M-95c "Integración con genesis".

## ADDED Requirements

### Requirement: Step informativo de licencia en genesis

La fase final de `genesis` (post-scaffold) MUST verificar si hay una licencia activa y, de no haberla, mostrar
el mensaje de upgrade **una sola vez**. El step MUST ser **informativo y no bloqueante** — NUNCA MUST
interrumpir ni abortar genesis para usuarios sin licencia.

#### Scenario: Genesis informa sobre upgrade cuando no hay licencia
- **GIVEN** un proyecto donde genesis completó el scaffold
- **AND** no existe observation `king-framework/license` activa
- **WHEN** genesis ejecuta su fase final
- **THEN** muestra el mensaje de upgrade una sola vez
- **AND** genesis termina con éxito normalmente (no bloquea)

#### Scenario: Genesis no muestra mensaje cuando hay licencia activa
- **GIVEN** existe observation `king-framework/license` con tier Pro activo
- **WHEN** genesis ejecuta su fase final
- **THEN** no muestra el mensaje de upgrade
- **AND** genesis termina con éxito normalmente

#### Scenario: La extensión es aditiva
- **GIVEN** el archivo `skills/genesis/GENERATION.md` original
- **WHEN** se aplica la extensión del Bloque C
- **THEN** el `git diff` muestra solo contenido añadido (ninguna línea existente removida)
- **AND** el comportamiento de genesis para usuarios Core es idéntico al previo
