---
name: db-migrations-essentials
scope: injection
version: 1.0
---

# DB Migrations Essentials

> Slim knowledge inject para el skill `/db-migrate` y agentes que operan sobre sistemas de migraciones de BD.

---

## Detección de Sistema de Migraciones (cascade)

Evaluar en este orden. Usar el **primer match** encontrado.

| # | Sistema | Archivos indicadores | Tabla de control | Notas críticas |
|---|---------|---------------------|-----------------|----------------|
| 1 | **Flyway** | `flyway.conf`, `flyway.toml`, `*/db/migration/V[0-9]*.sql` | `flyway_schema_history` | ⚠️ `flyway undo` solo Teams/Enterprise — ver abajo |
| 2 | **Alembic** | `alembic.ini`, `alembic/env.py`, `alembic/versions/*.py` | `alembic_version` | — |
| 3 | **golang-migrate** | `migrations/*.up.sql` + `*.down.sql` (par) | `schema_migrations` | — |
| 4 | **Rails** | `db/migrate/[0-9]{14}_*.rb`, `db/schema.rb` | `schema_migrations` | — |
| 5 | **Laravel** | `database/migrations/[0-9]{4}_[0-9]{2}_[0-9]{2}_*.php` | `migrations` | — |
| 6 | **Django** | `*/migrations/[0-9]{4}_*.py`, `manage.py` | `django_migrations` | — |
| 7 | **TypeORM** | `src/migrations/*-*.ts` con clase + `up()`/`down()` | `migrations` (configurable en ormconfig) | — |
| 8 | **Sequelize** | `.sequelizerc`, `migrations/[0-9]{14}-*.js` | `SequelizeMeta` | — |
| 9 | **SQL puro (King)** | `migrations/[0-9]{3}_*.sql` sin ninguno de los anteriores | `_king_migrations` (crear si no existe) | Ver schema canónico § abajo |
| 10 | **Desconocido** | ningún indicador encontrado | — | Preguntar al usuario |

> **⚠️ Flyway rollback**: `flyway undo` requiere licencia Teams/Enterprise. En Community, usar script SQL manual o nueva migración correctiva. Detectar con `flyway version` antes de ofrecer rollback.

---

## Schema Canónico — Tabla de Control (SQL puro King)

Para proyectos sin ORM, crear esta tabla en la BD objetivo:

```sql
CREATE TABLE IF NOT EXISTS _king_migrations (
    version      VARCHAR(50)   NOT NULL,
    script_name  VARCHAR(255)  NOT NULL,
    checksum_sha256 CHAR(64)   NOT NULL,
    applied_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    applied_by   VARCHAR(100)  NOT NULL,
    execution_ms INTEGER,
    status       VARCHAR(20)   NOT NULL DEFAULT 'APPLIED',
    PRIMARY KEY (version)
);
```

**Valores de `status`**: `APPLIED` | `REVERTED` | `FAILED` | `CHECKSUM_MISMATCH`

---

## Convención de Nombres — SQL puro King

```
migrations/
├── 001_create_users.sql
├── 002_add_email_index.sql
├── 003_create_orders.sql
└── 003_create_orders.down.sql   ← rollback del script 003
```

- Prefijo: 3 dígitos con zero-padding (`001`, `002`, `999`)
- Separador: `_` (guión bajo)
- Nombre: `[a-zA-Z0-9_-]+` (sin espacios, sin caracteres especiales)
- Regex de nombre válido: `^[0-9]{3,}_[a-zA-Z0-9_-]+\.sql$`
- Rollback inline: sección `-- down:` en el mismo archivo (alternativa al archivo `.down.sql`)

**Ejemplo de script con rollback inline:**
```sql
-- up:
ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- down:
ALTER TABLE users DROP COLUMN email;
```

---

## Cálculo de Delta Pendiente

Para determinar qué migraciones no se han aplicado en un ambiente:

1. **Listar archivos en disco**: `fd -e sql . migrations/` o `Get-ChildItem migrations/*.sql` → filtrar solo archivos `up` (excluir `.down.sql`)
2. **Leer tabla de control**: `SELECT version FROM _king_migrations WHERE status = 'APPLIED'`
3. **Calcular diferencia**: archivos en disco cuyo número de versión NO está en la tabla de control
4. **Ordenar**: por número de versión ascendente (numérico, no lexicográfico)

> **Gap detection**: si la tabla de control tiene versiones 001 y 003 pero no 002, y el archivo 002 existe en disco, reportar como GAP — puede indicar una migración aplicada fuera del sistema.

---

## Checksum SHA-256

Algoritmo obligatorio para verificación de integridad:

```bash
# Unix / macOS
shasum -a 256 migrations/001_create_users.sql | awk '{print $1}'

# Windows (PowerShell)
(Get-FileHash migrations/001_create_users.sql -Algorithm SHA256).Hash.ToLower()

# Python (cross-platform)
import hashlib
hashlib.sha256(open('migrations/001_create_users.sql','rb').read()).hexdigest()
```

**Invariante de checksum**: si el checksum del archivo actual difiere del hash almacenado en la tabla de control → `CHECKSUM_MISMATCH` → la migración fue modificada post-aplicación → BLOQUEAR ejecución de nuevas migraciones + alertar al usuario.

**NUNCA usar MD5 ni SHA-1** — tienen colisiones conocidas explotables.

---

## Invariantes de Seguridad — Análisis Estático Pre-Ejecución

Antes de ejecutar cualquier script de migración, analizar su contenido con estas reglas:

| Patrón detectado | Acción |
|-----------------|--------|
| `DROP DATABASE` | BLOQUEAR — requiere veto @security + aprobación explícita del usuario |
| `DROP SCHEMA` | BLOQUEAR — requiere veto @security + aprobación explícita del usuario |
| `DROP TABLE {nombre}` | WARN + confirmación — mostrar tabla afectada |
| `TRUNCATE TABLE` | WARN + confirmación — mostrar tabla afectada |
| `DELETE FROM {tabla}` sin cláusula WHERE | WARN + confirmación — operación destructiva masiva |
| `ALTER TABLE {t} DROP COLUMN {c}` | WARN + confirmación — pérdida de datos |
| `GRANT` / `REVOKE` / `CREATE USER` / `ALTER ROLE` | WARN + confirmación — operación de privilegios |
| Credenciales hardcodeadas (`password =`, `API_KEY =`) | BLOQUEAR — secret expuesto en migración |

El análisis usa regex case-insensitive sobre el contenido completo del archivo (no solo la primera línea).

---

## Estrategias de Rollback por Tipo

| Tipo de migración | Reversibilidad | Estrategia |
|------------------|----------------|-----------|
| `ADD COLUMN` | ✓ Reversible | DOWN: `DROP COLUMN` |
| `CREATE TABLE` | ✓ Reversible | DOWN: `DROP TABLE` |
| `CREATE INDEX` | ✓ Reversible | DOWN: `DROP INDEX` |
| `ADD CONSTRAINT` | ✓ Reversible | DOWN: `DROP CONSTRAINT` |
| `DROP COLUMN` | ✗ Irreversible | Requiere backup previo + confirmación |
| `DROP TABLE` | ✗ Irreversible | Requiere backup previo + confirmación |
| `RENAME TABLE` | ~ Semi-reversible | DOWN: `RENAME TABLE` inverso |
| `CHANGE COLUMN TYPE` | ✗ Potencialmente destructivo | Evaluar pérdida de datos por casting |

> **Rollback irreversible**: si la migración a revertir es de tipo irreversible, el skill debe:
> 1. Detectarlo con análisis del DOWN script
> 2. WARN explícito: "Esta operación puede causar pérdida de datos permanente"
> 3. Requerir confirmación escribiendo el nombre completo de la migración
> 4. Recomendar backup antes de ejecutar

---

## Ambientes y Configuración

El skill detecta el ambiente destino desde:
1. Flag `--env dev|qa|prod` en el comando
2. Variable de entorno `KING_ENV`
3. Default: `dev`

La connection string para el ambiente se lee de:
- `.env` del proyecto (variable `DATABASE_URL`)
- `.king/knowledge/environments.md` (tabla de ambientes)

> **NUNCA** pasar credenciales como argumento CLI. Siempre usar env vars o archivos de credenciales (`.pgpass`, `.my.cnf`).

---

## Transaccionalidad por Motor de BD

| Motor | DDL transaccional | Implicación para dry-run y rollback |
|-------|------------------|-------------------------------------|
| PostgreSQL | ✓ Sí | Dry-run con BEGIN + ROLLBACK garantizado |
| SQLite | ✓ Sí | Dry-run con copia temporal del archivo |
| MySQL / MariaDB | ✗ No (DDL auto-commit) | WARN antes de apply; dry-run limitado a DML |
| SQL Server | ✓ Sí | Dry-run con BEGIN TRANSACTION + ROLLBACK |
| Oracle | ~ Parcial | DDL hace COMMIT implícito; WARN al usuario |

> Para MySQL: el skill DEBE mostrar un warning explícito antes de ejecutar cualquier DDL, ya que el rollback automático no es posible en caso de error a mitad del script.
