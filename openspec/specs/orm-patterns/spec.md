# Delta Spec — orm-patterns (M-04)

## ADDED Requirements

### Requirement: Knowledge `orm-patterns.md`
El framework SHALL proveer `knowledge/domain/orm-patterns.md` documentando 4 patrones
(Repository, Unit of Work, Specification, Read/Write Split), 4 anti-patrones
(N+1 Query, God Repository, Query in Loop, Anemic Repository) y guías por ORM
(Prisma, Drizzle, SQLAlchemy, TypeORM, Hibernate, GORM). Cada patrón MUST incluir
problema que resuelve, ejemplo antes/después y señales de alarma.

### Requirement: Skill `/explain-query`
El skill `/explain-query` SHALL analizar una query SQL o llamada ORM y detectar full table scans,
índices faltantes y N+1. SHALL degradar graciosamente sin conexión DB (análisis estático LLM).

#### Scenario: Detecta N+1 en loop ORM
- **Given** un archivo con un `forEach` que ejecuta `findById` dentro del loop
- **When** el developer ejecuta `/explain-query` sobre el archivo
- **Then** identifica el patrón N+1 con las líneas exactas
- **And** sugiere refactor con `findMany` + `WHERE IN` mostrando código antes/después

#### Scenario: Genera CREATE INDEX desde query sin índice
- **Given** una query `SELECT * FROM orders WHERE user_id = $1 AND status = $2` sin índice compuesto
- **When** el developer ejecuta `/explain-query` con la query
- **Then** genera `CREATE INDEX idx_orders_user_id_status ON orders(user_id, status)`
- **And** explica el impacto estimado en latencia

### Requirement: Extensión @performance (ADITIVA)
`agents/performance.md` SHALL incorporar (sin remover contenido) una sección "ORM Checks":
ORM calls en loops → invocar `/explain-query`; check CASTLE T "no queries in loops".

#### Scenario: @performance detecta ORM call en loop durante /review
- **Given** código con `Array.forEach` con llamada ORM en el cuerpo
- **When** `@performance` revisa el código
- **Then** detecta la violación "no queries in loops" y recomienda `/explain-query`

> Set Gherkin completo: M04 §7 (Feature: ORM Patterns y Anti-Patterns).
