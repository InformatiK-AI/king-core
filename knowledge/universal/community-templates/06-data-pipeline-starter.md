# Template: Data Pipeline

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial para construir pipelines de datos batch/incremental con foco en
**ingest → transform → load**, orquestación declarativa, idempotencia garantizada,
calidad de datos verificable y observability de extremo a extremo. Pensado para
equipos que mueven datos entre fuentes operacionales y un almacén analítico sin
heredar la deuda de un pipeline artesanal.

## Stack

| Capa | Tecnología | Versión | Rol |
|------|-----------|---------|-----|
| Lenguaje | Python | 3.12 | Runtime de toda la lógica de datos |
| Transformación | dbt-core | 1.8 | Modelado SQL versionado, tests de datos, lineage |
| Orquestación | Dagster | 1.7 | Assets declarativos, scheduling, backfills, reintentos |
| Ingesta | dlt (data load tool) | 0.5 | Extracción incremental tipada con state management |
| Almacén analítico | DuckDB (local/dev) / BigQuery (prod) | DuckDB 1.0 / BQ Standard | Compute + storage del warehouse |
| Validación de datos | Pandera + dbt tests | Pandera 0.20 | Contratos de schema en bordes + assertions SQL |
| Empaquetado | uv | 0.4 | Gestión de dependencias y entornos reproducibles |
| Observability | OpenTelemetry + Dagster sensors | OTel 1.27 | Traces, métricas de freshness y logs estructurados |
| Deploy target | Dagster Cloud (Serverless) / GitHub Actions | — | Ejecución programada y CI |

## Skills King pre-configurados

Activos por defecto en `.king/config.yaml`:

- `/genesis` — bootstrap del proyecto a partir de esta spec.
- `/build` — desarrollo guiado de assets y modelos.
- `/observe` (M06) — instrumentación OTel y SLOs de freshness/volumen.
- `/slo-define` (M06) — define objetivos de frescura y latencia del pipeline.
- `/contract-test` (M05) — verifica contratos de schema en los bordes de ingest/load.
- `/property-test` (M05) — propiedades de idempotencia y rangos sobre transformaciones.
- `/promote` — promoción develop → qa → prod con verificación de ambiente.
- `/cicd-generate` (M06) — genera el workflow de orquestación + tests.
- `/audit` — Health Score del framework instalado.
- CASTLE completo con énfasis en **T (Testing)**, **L (Logging)** y **E (Environment)**.

## Estructura de proyecto generada

```
data-pipeline/
├── .king/
│   ├── config.yaml
│   ├── coverage.yaml          # global 80, data_quality gate
│   └── castle/
├── ingestion/                 # INGEST — fuentes vía dlt
│   ├── sources/
│   │   ├── postgres_source.py
│   │   └── api_source.py
│   └── schemas/               # contratos Pandera de entrada
├── transformations/           # TRANSFORM — dbt project
│   ├── models/
│   │   ├── staging/           # 1:1 con fuentes, sin lógica de negocio
│   │   ├── intermediate/      # joins y normalización
│   │   └── marts/             # tablas finales de consumo
│   ├── tests/                 # dbt data tests (unique, not_null, accepted_values)
│   ├── dbt_project.yml
│   └── profiles.yml
├── orchestration/             # Dagster — assets + jobs + schedules
│   ├── assets.py              # ingest/transform/load como assets
│   ├── jobs.py
│   ├── schedules.py
│   ├── sensors.py             # freshness + failure alerting
│   └── resources.py           # conexiones parametrizadas por ambiente
├── loading/                   # LOAD — materialización al warehouse
│   └── targets.py
├── quality/                   # checks transversales de calidad de datos
│   └── expectations.py
├── tests/
│   ├── unit/                  # transformaciones puras
│   ├── contract/              # schema en bordes
│   └── property/              # idempotencia, monotonicidad
├── .github/workflows/
│   └── pipeline.yml
├── pyproject.toml
└── README.md
```

## CASTLE configuration

| Layer | Estado | Gates específicos del pipeline |
|-------|--------|-------------------------------|
| **C — Contracts** | Activo | Pandera valida schema en ingest y load; ruptura de contrato = falla bloqueante. |
| **A — Architecture** | Activo | Separación estricta staging → intermediate → marts; sin lógica de negocio en staging. |
| **S — Security** | Activo | Credenciales solo vía variables de ambiente / secrets; PII marcada y enmascarada en logs. |
| **T — Testing** | Activo (énfasis) | dbt tests (unique/not_null) + property tests de idempotencia; coverage mínimo 80%. |
| **L — Logging** | Activo (énfasis) | Logs estructurados JSON por asset; trace_id propagado ingest→load vía OTel. |
| **E — Environment** | Activo (énfasis) | Paridad dev (DuckDB) ↔ prod (BigQuery) mediante el mismo SQL dbt y resources parametrizados. |

Gate adicional propio del template: **data-quality gate** — el pipeline NO promueve a
prod si algún dbt test crítico falla o si la freshness supera el SLO definido.

## CI/CD incluido

Plataforma de ejecución: **Dagster Cloud Serverless** (prod) con **GitHub Actions** como
gate de integración. Workflow `pipeline.yml` generado por defecto:

```yaml
name: data-pipeline
on:
  pull_request:
  push:
    branches: [main, develop]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - run: uv sync --frozen
      - name: Lint + unit tests
        run: uv run pytest tests/unit tests/property -q
      - name: Contract tests (schema en bordes)
        run: uv run pytest tests/contract -q
      - name: dbt build sobre DuckDB efimero
        run: uv run dbt build --target ci   # corre modelos + data tests
      - name: CASTLE check
        run: uv run king-castle --layers T,L,E --fail-under 80
  deploy:
    needs: validate
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: dagster-io/dagster-cloud-action@v0.1
```

- En cada PR: el pipeline completo corre contra un DuckDB efímero (cero costo, cero infra),
  ejecutando modelos y data tests reales sobre datos de fixtures.
- En merge a `main`: despliegue del code location a Dagster Cloud; los schedules toman
  efecto y la materialización corre contra BigQuery.

## Cómo usar

```
king-framework genesis --template data-pipeline-starter
```

## Decisiones de diseño

- **Dagster sobre Airflow** — Airflow modela *tareas*; Dagster modela *assets de datos*.
  Para un pipeline cuyo producto ES el dato, los assets dan lineage, freshness checks y
  backfills selectivos de forma nativa, sin DAGs imperativos frágiles. Además, los
  recursos parametrizados por ambiente eliminan el clásico "funciona en dev, falla en prod".

- **dbt para transform, no Python crudo** — el SQL versionado de dbt convierte la
  transformación en código revisable con tests de datos de primera clase (`unique`,
  `not_null`, `relationships`). El lineage automático y la documentación generada son
  gratis; reescribir eso en pandas sería reinventar la rueda con peor observabilidad.

- **dlt para ingest** — resuelve el problema más subestimado del ingest: el **state
  management incremental**. dlt persiste el cursor de última extracción y normaliza
  schemas evolutivos automáticamente, garantizando ingestas idempotentes sin lógica
  manual de "qué ya cargué". Escribir esto a mano es la fuente #1 de duplicados.

- **DuckDB en dev/CI, BigQuery en prod** — el mismo SQL de dbt corre en ambos motores,
  dando paridad real (CASTLE E). DuckDB en CI permite ejecutar el pipeline COMPLETO con
  datos reales de fixtures en segundos y a costo cero, en vez de mockear el warehouse o
  pagar slots de BigQuery por cada PR.

- **Idempotencia como invariante, no como deseo** — toda materialización usa estrategia
  `merge`/upsert con clave de negocio, nunca `append` ciego. Esto se verifica con
  property tests (`/property-test`): re-ejecutar un asset N veces produce el mismo estado.
  Es lo que permite reintentos y backfills seguros sin corromper datos.

- **Pandera en los bordes, dbt tests en el centro** — la validación se ubica donde el dato
  cruza un límite de confianza: Pandera tipa lo que entra (ingest) y lo que sale (load),
  mientras los dbt tests cubren las invariantes internas del modelo. Validar dos veces el
  mismo punto es desperdicio; validar el borde equivocado es dejar pasar basura.
