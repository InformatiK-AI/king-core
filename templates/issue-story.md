# STORY-NNN: [Titulo]

**Status:** open | in-progress | closed
**Epic:** EPIC-NNN
**Priority:** high | medium | low
**Labels:** story, component:xxx
**Created:** YYYY-MM-DD

## Descripcion
[Contexto y objetivo de esta story]

## Escenarios Funcionales (Gherkin)
```gherkin
Feature: [nombre descriptivo]

  Scenario: [happy path - flujo principal]
    Given [precondicion]
    When [accion del usuario]
    Then [resultado esperado]

  Scenario: [edge case - caso limite]
    Given [precondicion alternativa]
    When [accion que puede fallar]
    Then [manejo del caso]
```

## Escenarios Tecnicos
```gherkin
Feature: [nombre tecnico]

  Scenario: [detalle de implementacion]
    Given [estado del sistema]
    When [operacion tecnica]
    Then [resultado tecnico verificable]
```

## Definition of Done
- [ ] Codigo con convenciones del proyecto
- [ ] Escenarios funcionales verificados
- [ ] Escenarios tecnicos verificados
- [ ] Verificacion de sintaxis OK
- [ ] Build exitoso
- [ ] i18n actualizado (ES/EN/PT) si aplica
- [ ] Code review completado
- [ ] CASTLE >= CONDITIONAL
- [ ] Sin vulnerabilidades introducidas
- [ ] Conventional commits

## Acceptance Criteria
- AC-1: [criterio verificable derivado del happy path]
- AC-2: [criterio verificable derivado del edge case]

## Archivos Afectados
- `path/to/file.ext` — [tipo de cambio: crear/modificar/eliminar]

## Notas de Implementacion
[Hints tecnicos, patrones a seguir, secciones relevantes]

## Dependencias
[Stories que deben completarse antes, si las hay]
