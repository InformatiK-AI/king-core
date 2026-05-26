# SDD Orchestrator Protocol

Structured Development Driver — protocolo para cambios complejos que requieren más de un ciclo de build.

> **Path resolution**: Paths `skills/`, `agents/`, `knowledge/` son relativas a KING_FRAMEWORK_PATH (anunciado al inicio de sesión). Prepend ese valor al usar Read.

## Activación

SDD se activa cuando RADAR/Decide determina que un cambio:
- Requiere múltiples agentes en paralelo
- Tiene alto riesgo de compactación de contexto
- Necesita trazabilidad explícita de decisiones
- Involucra 3+ archivos con dependencias complejas

## DAG (con paralelismo)

```
init ──► explore ──► proposal
                         │
                         ├──► specs ──────────┐
                         │                    ▼
                         └──► design ────► tasks ──► apply ──► verify ──► archive
```

`init` y `explore` son las fases 1-2 del pipeline completo (ejecutadas por `/sdd-new`).
`specs` y `design` corren en **PARALELO**. `tasks` depende de AMBOS.

El orquestador es **delegate-only**: coordina, no ejecuta código.

## Meta-commands

| Comando | Secuencia |
|---------|-----------|
| `/sdd-new <name>` | `sdd-init` → `sdd-explore` → `sdd-propose` |
| `/sdd-ff <name>` | `sdd-propose` → (`sdd-spec` ∥ `sdd-design`) → `sdd-tasks` |
| `/sdd-continue [name]` | Lee `state.yaml` → ejecuta próxima fase lista |

`/sdd-new`, `/sdd-ff`, y `/sdd-continue` son meta-commands manejados por el orquestador. NO invocarlos como skills.

## SDD Init Guard (MANDATORY)

Antes de ejecutar CUALQUIER comando SDD (`/sdd-new`, `/sdd-ff`, `/sdd-continue`, o cualquier fase individual), verificar si `sdd-init` ya corrió para este proyecto:

1. **Engram**: `mem_search(query: "sdd-init/{project}", project: "{project}")`
2. **Chronicle (fallback)**: verificar si `.king/sdd/config.yaml` existe
3. Si encontrado en cualquiera → init ya se realizó, proceder normalmente
4. Si NO encontrado → ejecutar `sdd-init` PRIMERO (delegar a sub-agente sdd-init), LUEGO proceder con el comando solicitado

Esto garantiza que:
- Las capacidades de testing están detectadas y cacheadas
- El modo TDD estricto se activa cuando el proyecto lo soporta
- El contexto del proyecto (stack, convenciones) está disponible para todas las fases

NO saltar este check. NO preguntar al usuario — ejecutar init silenciosamente si es necesario.

## Execution Mode

Al primer `/sdd-new`, `/sdd-ff` o `/sdd-continue` (o equivalente en lenguaje natural: "haceme un SDD para X") en la sesión, preguntar qué modo de ejecución prefiere:

- **Automatic** (`auto`): ejecutar todas las fases back-to-back sin pausar. Mostrar solo el resultado final. Usar cuando el usuario quiere velocidad y confía en el proceso.
- **Interactive** (`interactive`): después de cada fase, mostrar resumen y preguntar "¿Continuamos?" antes de la siguiente fase. Usar cuando el usuario quiere revisar y dirigir cada paso.

Default: **Interactive** (más seguro, da control al usuario).

Cachear la elección para la sesión — no volver a preguntar salvo que el usuario lo solicite explícitamente.

En modo **Interactive**, entre fases:
1. Mostrar resumen conciso de lo que produjo la fase
2. Listar qué hará la siguiente fase
3. Preguntar: "¿Continuamos?" — aceptar SÍ/continuar, NO/detener, o feedback específico para ajustar
4. Si hay feedback, incorporarlo antes de ejecutar la siguiente fase

## Delivery Strategy

Al primer `/sdd-new`, `/sdd-ff` o `/sdd-continue` en la sesión, también preguntar y cachear la estrategia de entrega:

- **`ask-on-risk`** (default): detener y preguntar si el forecast de tasks supera el budget de 400 líneas
- **`auto-chain`**: splitear automáticamente en PRs encadenados si el scope lo requiere
- **`single-pr`**: entregar todo en un solo PR; requerir `size:exception` si el scope es grande
- **`exception-ok`**: continuar sin preguntar, siempre usar `size:exception` para PRs grandes

Pasar `delivery_strategy` como parámetro a `sdd-tasks` y `sdd-apply`.

### Chain Strategy

Cuando `delivery_strategy` resulta en PRs encadenados (por elección del usuario via `ask-on-risk` o automáticamente via `auto-chain`), preguntar cuál estrategia de cadena usar:

- **`stacked-to-main`**: cada PR mergea directamente a main en orden. Iteración rápida, corrección al vuelo. Mejor para equipos que priorizan velocidad y slices independientes.
- **`feature-branch-chain`**: el branch feature/tracker acumula la integración final. PR #1 apunta al tracker branch; PRs posteriores apuntan al PR inmediatamente anterior. Solo el tracker mergea a main. Mejor para control de rollback y releases coordinados.

Cachear `chain_strategy` para la sesión. Pasar junto con `delivery_strategy` a `sdd-tasks` y `sdd-apply`. No volver a preguntar salvo cambio explícito de scope.

## Review Workload Guard (MANDATORY)

Después de que `sdd-tasks` completa y ANTES de lanzar `sdd-apply`, inspeccionar el `Review Workload Forecast` del output de sdd-tasks.

Si dice `Chained PRs recommended: Yes`, `400-line budget risk: High`, líneas estimadas > 400, o `Decision needed before apply: Yes`, aplicar la `delivery_strategy` cacheada:

- **`ask-on-risk`**: DETENER y preguntar si splitear en PRs encadenados/stacked o proceder con `size:exception`. Si el usuario elige PRs encadenados y `chain_strategy` no está cacheada, preguntar también cuál chain strategy usar.
- **`auto-chain`**: NO preguntar sobre el split. Si `chain_strategy` no está cacheada, preguntar cuál usar. Pasar a `sdd-apply`: implementar solo el próximo slice autónomo con commits de work-unit, con boundaries claros de inicio, fin, verificación y rollback.
- **`single-pr`**: DETENER y requerir/registrar `size:exception` antes del apply.
- **`exception-ok`**: continuar, pero indicar a `sdd-apply` que este run usa `size:exception`.

El modo Automatic NO anula este guard. Siempre pasar la `delivery_strategy` resuelta a `sdd-apply`.

Al lanzar `sdd-apply`, incluir siempre: `delivery_strategy` resuelta, `chain_strategy`, y el boundary de PR elegido o la excepción aceptada.

## Model Assignments

Leer esta tabla al inicio de sesión (o antes de la primera delegación), cachearla y pasar el alias en cada llamada a Agent tool via el parámetro `model`. Si una fase no está en la tabla, usar la fila `default`. Si no tenés acceso al modelo asignado, substituir `sonnet` y continuar.

**Mandatory model gate**: CADA llamada a Agent DEBE incluir `model`. Llamar a Agent sin `model` es inválido. Antes de cada Agent call, resolver la fase al alias de esta tabla; para delegación general/no-SDD usar `default`.

| Fase | Modelo | Razón |
|------|--------|-------|
| `sdd-explore` | sonnet | Lectura de código, estructural — no arquitectónico |
| `sdd-propose` | opus | Decisiones arquitectónicas |
| `sdd-spec` | sonnet | Escritura estructurada |
| `sdd-design` | opus | Decisiones de arquitectura |
| `sdd-tasks` | sonnet | Descomposición mecánica |
| `sdd-apply` | sonnet | Implementación |
| `sdd-verify` | sonnet | Validación contra spec |
| `sdd-archive` | haiku | Copiar y cerrar |
| `default` | sonnet | Delegación general no-SDD |

## Persistencia de Estado

Estado del DAG en `.king/sdd/<change-name>/state.yaml`:

```yaml
change: "<name>"
started: "<ISO>"
phases:
  proposal: completed
  specs: completed
  design: completed
  tasks: in_progress
  apply: pending
  verify: pending
  archive: pending
last_updated: "<ISO>"
```

## OpenSpec Structure

```
.king/sdd/<change-name>/
├── config.yaml          # Rules, TDD settings, persistence mode
├── state.yaml           # DAG state para recovery
├── proposal.md          # Fase: proposal
├── specs/               # Fase: specs (delta specs)
│   └── spec.md
├── design/              # Fase: design
│   └── design.md
├── tasks/               # Fase: tasks
│   └── checklist.md
└── archive/             # Fase: archive (audit trail)
    └── summary.md
```

## Sub-agent Return Envelope

Cada sub-agente retorna:

```yaml
status: "SUCCESS|PARTIAL|BLOCKED"
executive_summary: "{1-2 oraciones}"
artifacts:
  - path: "{archivo creado/modificado}"
    description: "{qué contiene}"
next_recommended: "{siguiente fase}"
risks: []
```

## Sub-Agent Context Protocol

Los sub-agentes tienen un contexto fresco sin memoria. El orquestador controla el acceso al contexto.

### SDD Phases — Tabla de Lectura/Escritura

Para fases con dependencias requeridas, el sub-agente lee directamente del backend — el orquestador pasa referencias de artefactos (topic keys de Engram o paths de Chronicle), NO el contenido en sí.

| Fase | Lee | Escribe |
|------|-----|---------|
| `sdd-explore` | nada | `explore` |
| `sdd-propose` | exploration (opcional) | `proposal` |
| `sdd-spec` | proposal (requerido) | `spec` |
| `sdd-design` | proposal (requerido) | `design` |
| `sdd-tasks` | spec + design (requeridos) | `tasks` |
| `sdd-apply` | tasks + spec + design + **apply-progress (si existe)** | `apply-progress` |
| `sdd-verify` | spec + tasks + **apply-progress** | `verify-report` |
| `sdd-archive` | todos los artefactos | `archive-report` |

### Strict TDD Forwarding (MANDATORY)

Al lanzar sub-agentes de `sdd-apply` o `sdd-verify`, el orquestador DEBE:

1. Buscar capacidades de testing: `mem_search(query: "sdd-init/{project}", project: "{project}")`
2. Si el resultado contiene `strict_tdd: true`:
   - Agregar al prompt del sub-agente: `"STRICT TDD MODE IS ACTIVE. Test runner: {test_command}. Debés seguir strict-tdd.md. NO caer en Standard Mode."`
   - Esto es NO-NEGOCIABLE. No confiar en que el sub-agente lo descubra independientemente.
3. Si la búsqueda falla o `strict_tdd` no está presente, NO agregar la instrucción TDD (el sub-agente usa Standard Mode).

Resolver el estado TDD UNA VEZ por sesión (al primer lanzamiento de apply/verify) y cachearlo.

### Apply-Progress Continuity (MANDATORY)

Al lanzar `sdd-apply` para un batch de continuación (no el primer batch):

1. Buscar apply-progress existente: `mem_search(query: "sdd/{change-name}/apply-progress", project: "{project}")`
2. Si encontrado, agregar al prompt del sub-agente: `"APPLY-PROGRESS PREVIO EXISTE en topic_key 'sdd/{change-name}/apply-progress'. DEBÉS leerlo primero via mem_search + mem_get_observation, mergear tu nuevo progreso con el existente, y guardar el resultado combinado. NO sobreescribir — MERGEAR."`
3. Si no encontrado (primer batch), no se necesita instrucción especial.

Esto previene pérdida de progreso entre batches. El sub-agente es responsable de read-merge-write, pero el orquestador DEBE avisarle que existe progreso previo.

### Engram Topic Key Format

| Artefacto | Topic Key |
|-----------|-----------|
| Contexto del proyecto | `sdd-init/{project}` |
| Exploración | `sdd/{change-name}/explore` |
| Propuesta | `sdd/{change-name}/proposal` |
| Spec | `sdd/{change-name}/spec` |
| Design | `sdd/{change-name}/design` |
| Tasks | `sdd/{change-name}/tasks` |
| Apply progress | `sdd/{change-name}/apply-progress` |
| Verify report | `sdd/{change-name}/verify-report` |
| Archive report | `sdd/{change-name}/archive-report` |
| DAG state | `sdd/{change-name}/state` |

Los sub-agentes recuperan contenido completo en dos pasos:
1. `mem_search(query: "{topic_key}", project: "{project}")` → obtener observation ID
2. `mem_get_observation(id: {id})` → contenido completo (REQUERIDO — los resultados de search están truncados)

## Behavior Injection

Each SDD phase is launched with its SKILL.md as the instruction set. CASTLE gates and knowledge context are declared inside each skill — the orchestrator documents the authoritative mapping here for cross-phase visibility.

### Phase → Gates → Knowledge mapping

| Phase | CASTLE Gates | Knowledge Files (if exist) |
|-------|-------------|---------------------------|
| `sdd-explore` | A | `.king/knowledge/architecture.md` |
| `sdd-design` | A + S | `.king/knowledge/architecture.md`, `.king/knowledge/conventions.md` |
| `sdd-apply` | C + A + T | `.king/knowledge/conventions.md`, `.king/knowledge/stack.md` |
| `sdd-verify` | C + A + S + T + L | `.king/knowledge/architecture.md`, `.king/knowledge/conventions.md` |

**Graceful degradation rule**: If `.king/knowledge/` does not exist or a specific file is absent, the sub-agent logs a warning and continues. SDD is portable to projects without King Framework initialized.

### CASTLE Verdict Propagation

Sub-agents return `castle_verdict` in their envelope. The orchestrator:
- `FORTIFIED` or `CONDITIONAL` → proceed to next phase
- `BREACHED` → pause and surface to user before proceeding to next phase
- `sdd-verify` returning `BREACHED` → block `sdd-archive`; require apply fix cycle

**Best-effort note**: `castle_verdict` is a trust-on-first-use signal — sub-agents self-assess based on local context and may lack full cross-phase visibility. When `BREACHED`, surface the **full CASTLE Assessment table** from the envelope to the user, not just the verdict string, so they can evaluate the finding directly.

### Intentional Omission from castle/SKILL.md

The SDD sub-agents (`sdd-explore`, `sdd-design`, `sdd-apply`, `sdd-verify`) are internal pipeline agents and are **intentionally excluded** from the public configuration table in `castle/SKILL.md`. This exclusion is deliberate — do not add SDD sub-agents to `castle/SKILL.md`.

## Engram Runtime Fallback

Cuando `artifact_store.mode` es `engram` o `hybrid` y una operación Engram falla en runtime:

1. **Detectar**: cualquier error/timeout de `mem_save`, `mem_search`, o `mem_get_observation`.
2. **Degradar**: set flag de sesión — todas las operaciones Engram posteriores se omiten.
   La operación fallida se reintenta contra Chronicle (sin pérdida de artefacto).
3. **Notificar**: emitir exactamente una vez:
   `WARN: Engram unreachable — using Chronicle fallback for this session`
4. **Registrar**: actualizar `state.yaml` añadiendo bajo `artifact_store`:
   `fallback_activated_at: {phase-id}` — NO sobreescribir si ya existe.
5. **Continuar**: usar Chronicle para todas las fases restantes del cambio.

**Recovery en sesión siguiente**: leer `fallback_activated_at` en `state.yaml` →
preferir Chronicle para fases en o después de ese punto. Ver `persistence-contract.md`
sección "Runtime Fallback" para el protocolo completo.

## Recovery Post-Compactación

1. Leer `.king/sdd/<change-name>/state.yaml` → restaurar fase actual del DAG
2. Leer `.king/registry.md` → identificar workflows activos
3. Leer último session document en `.king/sessions/` → recuperar contexto reciente
4. Continuar con `/sdd-continue`

## Referencias por Fase

| Fase | Skill |
|------|-------|
| Init | `skills/sdd-init/SKILL.md` |
| Explore | `skills/sdd-explore/SKILL.md` |
| Propose | `skills/sdd-propose/SKILL.md` |
| Spec | `skills/sdd-spec/SKILL.md` |
| Design | `skills/sdd-design/SKILL.md` |
| Tasks | `skills/sdd-tasks/SKILL.md` |
| Apply | `skills/sdd-apply/SKILL.md` |
| Verify | `skills/sdd-verify/SKILL.md` |
| Archive | `skills/sdd-archive/SKILL.md` |

## Quality Skills Chain (opcional)

SDD puede invocar skills de lifecycle (`/refactor`, `/optimize`, `/review`) durante la fase `verify` como quality gates adicionales, antes del Spec Compliance Matrix.

Controlado por `rules.verify.quality_skills` en `.king/sdd/config.yaml`:
- `enabled: false` (default) — no se invoca ningún skill adicional
- `enabled: true` + `chain: ["/refactor", "/optimize", "/review"]` — se ejecutan en secuencia, limitados a los archivos del cambio

Los findings se agregan como sección `Quality Skills Findings` en el verify-report. CRITICAL findings se elevan como WARNING en el reporte de verificación (no auto-BREACH).

Ver `skills/sdd-verify/SKILL.md` → Step 4e para la implementación detallada.
