# Template: AI Agent

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial para construir agentes de IA production-grade: aplicaciones que integran uno o más LLMs con orquestación, RAG, herramientas (tools/function-calling) y guardrails de seguridad. El énfasis NO es un chatbot de demo, sino un agente con observabilidad de tokens, control de coste y evaluación de prompts versionada desde el día uno.

## Stack

| Capa | Tecnología | Versión | Por qué |
|---|---|---|---|
| Runtime | Python | 3.12 | Ecosistema LLM canónico (SDKs first-class de Anthropic/OpenAI, tooling de eval maduro). |
| Orquestación de agente | LangGraph | 0.2.x | Grafo de estado explícito sobre la cadena lineal de LangChain; permite ciclos, checkpoints y human-in-the-loop sin reinventar el control de flujo. |
| Cliente LLM primario | `anthropic` SDK | 0.40.x | Proveedor por defecto (Claude). Tool-use tipado y prompt caching nativo. |
| Cliente LLM secundario | `openai` SDK | 1.x | Fallback/routing multi-proveedor; embeddings y modelos de evaluación. |
| Vector store | Qdrant | 1.12.x | Self-hostable y con cloud gratuito; filtros por payload nativos para RAG con metadatos. |
| Embeddings | `fastembed` (BGE-small) | 0.4.x | Embeddings locales por defecto: cero coste por query y sin fuga de datos al proveedor en indexación. |
| API HTTP | FastAPI | 0.115.x | Async-first (streaming SSE de tokens), validación con Pydantic, OpenAPI gratis. |
| Validación/contratos | Pydantic | 2.x | Esquemas de I/O del agente y de las tool-calls como contratos verificables. |
| Observabilidad LLM | OpenTelemetry + Langfuse | OTel 1.27 / Langfuse 2.x | Trazas de spans LLM (latencia, tokens, coste) con backend self-host; alimenta el hook `emit-span` de king-ai. |
| Gestión de prompts | Ficheros versionados en `prompts/` (Jinja2) | — | Prompts como artefactos de código revisables en PR, no strings embebidos. |
| Tests | pytest + pytest-asyncio + `deepeval` | pytest 8.x | Unit/integration + evals semánticas de prompts (no solo assert exacto). |
| Empaquetado | uv | 0.5.x | Resolución e instalación deterministas; `uv.lock` reproducible. |
| Deploy target | Docker → Fly.io / Railway | — | Imagen única con el agente + worker; long-running async sin cold-start agresivo de serverless puro. |

> Las claves de proveedores LLM y de Langfuse son secrets de entorno (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `QDRANT_URL`, `LANGFUSE_*`). NUNCA se generan en el repo ni se piden en el chat.

## Skills King pre-configurados

Activos por defecto en `.king/config` al generar con este template:

| Skill | Origen | Rol en el template |
|---|---|---|
| `/genesis` | king-core | Bootstrap del proyecto y del `.king/`. |
| `/build` | king-core | Workflow de feature (architecture → impl → QA → PR). |
| `rag-setup` | king-ai | Configura el pipeline de ingesta, chunking, embeddings y el vector store Qdrant. |
| `ai-safety` | king-ai | Guardrails de entrada/salida: prompt-injection, PII, jailbreak y políticas de contenido. |
| `prompt-eval` | king-ai | Suite de evaluación de prompts versionada; gate de regresión semántica antes de merge. |
| `ai-cost-gate` | king-ai | Presupuesto de tokens/coste por operación; bloquea si una llamada excede el budget. |
| `ai-observability` | king-ai | Instrumentación OTel de spans LLM y dashboards de tokens/latencia/coste. |
| `llm-integration` | king-ai | Capa de abstracción multi-proveedor (routing, retries, fallback Claude↔GPT). |
| `/deploy` · `/promote` | king-entrepreneur / king-core | Deploy a Fly.io/Railway y promoción develop→qa→prod. |
| `/castle` | king-core | Certificación CASTLE completa (ver sección dedicada). |

Skills king-ai opcionales (no activos por defecto, habilitables con `/genesis --with`): `ai-audit-ledger` (trail inmutable de llamadas LLM) y `cost-report` (reporte agregado de gasto).

## Estructura de proyecto generada

```
ai-agent-starter/
├── .king/
│   ├── config.yaml              # skills activos + perfil "ai-agent"
│   ├── coverage.yaml            # umbrales de cobertura + token budget
│   └── castle/                  # reportes CASTLE
├── src/
│   ├── agent/
│   │   ├── graph.py             # grafo LangGraph (nodos, edges, checkpoints)
│   │   ├── state.py             # estado del agente (Pydantic)
│   │   └── tools/               # tool-calls registradas (function-calling)
│   ├── llm/
│   │   ├── client.py            # abstracción multi-proveedor (llm-integration)
│   │   ├── router.py            # routing/fallback Claude↔GPT
│   │   └── guardrails.py        # hooks ai-safety in/out
│   ├── rag/
│   │   ├── ingest.py            # pipeline de ingesta + chunking
│   │   ├── store.py             # cliente Qdrant
│   │   └── retriever.py         # recuperación con filtros de metadatos
│   ├── observability/
│   │   └── tracing.py           # spans OTel + export a Langfuse
│   └── api/
│       ├── main.py              # FastAPI app (streaming SSE)
│       └── routes.py            # endpoints del agente
├── prompts/
│   ├── system.jinja2            # prompt de sistema versionado
│   └── tasks/                   # prompts por tarea (revisables en PR)
├── evals/
│   ├── datasets/                # casos dorados (golden set)
│   └── test_prompts.py          # evals deepeval (prompt-eval)
├── tests/
│   ├── unit/
│   └── integration/
├── .github/workflows/ci.yml
├── Dockerfile
├── pyproject.toml
├── uv.lock
└── .env.example
```

## CASTLE configuration

Layers activos y gates específicos de un agente de IA:

| Layer | Estado | Gate específico del template |
|---|---|---|
| **C — Contracts** | Activo | Esquemas Pydantic obligatorios para el estado del agente, la I/O de la API y CADA tool-call. El contrato de la tool ES la fuente de verdad del function-calling. |
| **A — Architecture** | Activo | Frontera dura: la lógica de orquestación (`agent/`) no importa SDKs de proveedor directamente; pasa por `llm/client.py`. Verificable en review. |
| **S — Security** | Activo + reforzado | `ai-safety` obligatorio: validación de prompt-injection y PII redaction en entrada/salida. Secrets solo por entorno. Bloquea merge si un prompt de sistema queda sin guardrail. |
| **T — Testing** | Activo | Doble gate: cobertura de código ≥ 80% **y** suite `prompt-eval` sin regresión semántica contra el golden set (`evals/datasets/`). |
| **L — Logging** | Activo + reforzado | `ai-observability`: cada llamada LLM emite un span OTel con tokens in/out, latencia y coste. Sin span = no PASS. |
| **E — Environment** | Activo | `.env.example` completo; el `ai-cost-gate` lee el token budget de `.king/coverage.yaml` y veta operaciones que lo excedan. |

Reforzados respecto al baseline CASTLE: **S** y **L**, porque en un agente de IA el riesgo dominante no es el bug funcional clásico sino la fuga de datos (injection/PII) y la ceguera de coste/comportamiento (sin trazas no hay forma de explicar ni acotar el gasto de un LLM no determinista).

## CI/CD incluido

Plataforma de deploy target: **Fly.io** (default) o **Railway** (auto-detectado por `/deploy`).

`.github/workflows/ci.yml` generado:

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --frozen
      - name: Lint & types
        run: uv run ruff check . && uv run mypy src
      - name: Unit & integration tests
        run: uv run pytest --cov=src --cov-fail-under=80
      - name: Prompt evals (golden set)
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: uv run pytest evals/ -m eval
      - name: CASTLE check
        run: uv run king castle --gate

  deploy-preview:
    needs: quality
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --app ${{ vars.FLY_APP }}-pr-${{ github.event.number }} --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

  deploy-prod:
    needs: quality
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

Las evals de prompt en CI usan un subconjunto del golden set (smoke) para acotar coste; la suite completa corre en el gate de `/promote` a qa.

## Tests incluidos

- **Framework**: `pytest` + `pytest-asyncio` (código async de FastAPI/LangGraph) y `deepeval` (evals semánticas de prompts).
- **Configuración inicial**: `tests/unit/` y `tests/integration/` con fixtures de LLM mockeado (las pruebas unitarias NUNCA llaman a un proveedor real); `evals/` con golden set versionado y marcador `-m eval` para aislar las pruebas que sí consumen tokens.
- **Cobertura mínima**: **80%** de código (`--cov-fail-under=80`) configurado en `.king/coverage.yaml`, MÁS un gate de regresión de `prompt-eval` (la calidad semántica no puede caer bajo el umbral del golden set). La cobertura de líneas sola es insuficiente para un sistema no determinista: por eso el doble gate.

## Cómo usar

```
king-framework genesis --template ai-agent-starter
```

## Decisiones de diseño

- **LangGraph sobre LangChain (chains) o framework propio**: un agente real necesita ciclos (reflexión, reintento de tool-call), checkpoints y puntos de human-in-the-loop. LangGraph modela eso como un grafo de estado explícito y auditable; las chains lineales obligan a hackear el control de flujo, y un orquestador propio es reinventar la rueda sin la comunidad detrás.
- **Multi-proveedor con Claude como primario, vía `llm/client.py`**: acoplar el agente al SDK de un solo proveedor es deuda técnica garantizada (cambios de precio, deprecación de modelos, rate limits). La capa de abstracción (`llm-integration`) permite routing y fallback Claude↔GPT sin tocar la lógica de orquestación, y respeta la frontera CASTLE-A.
- **Embeddings locales (fastembed/BGE) por defecto en RAG**: la indexación masiva con embeddings de API tiene coste lineal con el corpus y envía cada documento al proveedor. Embeddings locales eliminan ese coste y esa fuga en el caso común; se puede subir a embeddings de API solo si la calidad de recuperación lo exige, como decisión consciente.
- **Qdrant sobre pgvector o un índice in-memory**: Qdrant es self-hostable, tiene cloud gratuito para arrancar, y soporta filtros por payload nativos —imprescindibles para RAG con metadatos (tenant, fecha, fuente). pgvector acopla el vector store al Postgres transaccional y escala peor en búsqueda ANN; un índice in-memory no sobrevive a un reinicio.
- **Prompts como artefactos versionados + `prompt-eval` como gate**: un prompt embebido en un string es invisible al review y su degradación pasa desapercibida. Tratar los prompts como código (`prompts/`, revisables en PR) y exigir que NO haya regresión semántica contra un golden set convierte la calidad del LLM en algo verificable, no en una impresión subjetiva.
- **CASTLE refuerza S y L, no T-funcional**: en software determinista el bug funcional es el riesgo rey; en un agente de IA el riesgo rey es la fuga de datos (injection/PII) y la ceguera de coste/comportamiento. Por eso `ai-safety` (S) y `ai-observability` (L) son obligatorios y bloqueantes: sin guardrails ni spans de tokens, el agente es una caja negra cara e insegura.
