# Delta Spec — db-optimize (M-31)

## ADDED Requirements

### Requirement: Skill `/db-optimize`
El skill `/db-optimize` SHALL analizar schema y queries del proyecto, detectar slow queries y FK sin índice,
sugerir índices (CREATE INDEX con nombre canónico `idx_{table}_{columns}`), caching (con TTL) y particionado.
SHALL reusar `/explain-query` (creado en M-04) para confirmar N+1. SHALL generar handoff a `/db-migrate` de king-infra.

#### Scenario: Detecta FK sin índice y genera migration
- **Given** schema Postgres con `orders` referenciando `users(id)` sin índice en `orders.user_id`
- **When** el developer ejecuta `/db-optimize`
- **Then** detecta la FK sin índice
- **And** genera `CREATE INDEX idx_orders_user_id ON orders(user_id)`
- **And** genera el payload de handoff para `/db-migrate`

#### Scenario: Sugiere caching para query de dashboard
- **Given** una query agregada costosa sobre `orders` de los últimos 30 días
- **When** el developer ejecuta `/db-optimize`
- **Then** identifica la query como candidata a caching y sugiere Redis con TTL 5 min + código cache-aside

> Set Gherkin completo: M04 §7 (Feature: Database Excellence).
