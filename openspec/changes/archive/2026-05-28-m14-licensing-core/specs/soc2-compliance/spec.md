# soc2-compliance — Delta Spec (M-98)

> Reusa Gherkin de `mejora/planes-detallados/M14-business-model-monetization.md §7 M-98`.

## ADDED Requirements

### Requirement: Guía de compliance SOC2/ISO27001

El knowledge file `knowledge/universal/soc2-compliance.md` MUST mapear los controles SOC2 Type II contra las
features de King (CASTLE, Chronicle, Engram), documentar honestamente los gaps actuales con su plan de
remediación, e incluir un template de cuestionario de seguridad para procurement enterprise. NO MUST presentarse
como una certificación real (es guía de evaluación).

#### Scenario: Enterprise evalúa King Framework para uso regulado
- **GIVEN** existe `knowledge/universal/soc2-compliance.md`
- **WHEN** un security officer revisa el documento
- **THEN** encuentra el mapeo de controles SOC2 Type II vs features de King
- **AND** encuentra los gaps actuales documentados honestamente
- **AND** encuentra el plan de remediación con timeline

#### Scenario: Procurement responde cuestionario de seguridad
- **GIVEN** existe el template de cuestionario en `soc2-compliance.md`
- **WHEN** el equipo de King responde un cuestionario enterprise
- **THEN** puede completarlo usando el template en menos de 30 minutos
- **AND** las respuestas son consistentes con la documentación del framework

#### Scenario: Mapeo de controles a capas del framework
- **GIVEN** la sección de mapeo de controles
- **WHEN** se la consulta
- **THEN** CASTLE aparece como control de acceso y auditoría (capas A·C)
- **AND** Chronicle aparece como audit log inmutable (CC7.2 — monitoring)
- **AND** Engram aparece como retention policy documentation (CC6.7 — data retention)
