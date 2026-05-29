# license-check — Delta Spec (M-95b, M-95c)

> Reusa Gherkin de `mejora/planes-detallados/M14-business-model-monetization.md §7 M-95b / M-95c`.

## ADDED Requirements

### Requirement: Verificación de licencia para skills premium

El skill `/license-check` MUST verificar, contra la observation `king-framework/license` en Engram, si hay una
licencia activa con tier suficiente, y retornar `{ tier, features_available[], upgrade_required }`. NUNCA MUST
exponer la key completa en su output.

#### Scenario: Skill premium invocado sin licencia
- **GIVEN** no existe observation `king-framework/license` en Engram
- **WHEN** se invoca un skill marcado como premium (tier: pro)
- **THEN** license-check retorna `upgrade_required: true`
- **AND** se muestra el mensaje de upgrade estándar exacto
- **AND** el skill no ejecuta ninguna fase posterior

#### Scenario: Skill premium invocado con licencia Pro activa
- **GIVEN** existe observation con tier "pro" y `expires_at` en el futuro
- **WHEN** se invoca un skill Pro (e.g. `/brand-identity`)
- **THEN** license-check retorna `upgrade_required: false`
- **AND** `features_available` incluye todos los skills Pro
- **AND** el skill continúa con Fase 1

#### Scenario: Skill Team invocado con licencia Pro (tier insuficiente)
- **GIVEN** existe observation con tier "pro"
- **WHEN** se invoca un skill exclusivo de Team (e.g. `/ai-audit-ledger`)
- **THEN** license-check retorna `upgrade_required: true`
- **AND** el mensaje especifica el tier requerido ("King Team")

#### Scenario: Licencia expirada
- **GIVEN** existe observation con tier "pro" y `expires_at` hace 3 días
- **WHEN** se invoca cualquier skill premium
- **THEN** license-check trata la licencia como expirada
- **AND** muestra mensaje de renovación (distinto al de upgrade)

#### Scenario: Engram no responde (modo degradado)
- **GIVEN** Engram tarda más de 3 segundos en responder
- **WHEN** license-check intenta leer la observation
- **THEN** continúa con tier "core" (modo degradado)
- **AND** no bloquea al usuario por error de infraestructura

### Requirement: Activación de licencia vía CLI

El comando `/license-check activate <key>` (documentado en `commands/license-check.md` y
`license-management.md`) MUST persistir la observation `king-framework/license` en Engram cuando la key es
válida, y NO MUST modificar Engram cuando es inválida.

#### Scenario: Activación exitosa de licencia Pro
- **GIVEN** el usuario ejecuta `/license activate KF-PRO-XXXX-XXXX`
- **AND** la key es válida según el endpoint de validación
- **WHEN** license-check procesa el parámetro activate
- **THEN** persiste observation `king-framework/license` en Engram con tier, key, expires_at, seats, email
- **AND** confirma al usuario con la fecha de vencimiento

#### Scenario: Activación con key inválida
- **GIVEN** el usuario ejecuta `/license activate KF-PRO-INVALID`
- **WHEN** license-check intenta validar
- **THEN** no modifica Engram
- **AND** muestra mensaje de error con instrucciones para obtener key válida

#### Scenario: Consulta de estado de licencia
- **GIVEN** el usuario ejecuta `/license status`
- **WHEN** license-check lee la observation actual
- **THEN** muestra tier activo, fecha de vencimiento y número de seats
- **AND** NO expone el valor completo de la key (solo los últimos 4 caracteres)
