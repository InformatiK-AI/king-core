# Platform Adapters Roadmap — Más allá de las 11 Plataformas Actuales

Este documento es la referencia viva del roadmap de expansión de plataformas de King. Define
qué plataformas soporta King hoy via Apex Core, los criterios objetivos para priorizar nuevas
plataformas, el contrato público `AgentAdapter` que todo adapter debe implementar, la matriz de
paridad de features por plataforma, y el proceso por el cual la comunidad contribuye adapters.

Es un documento **actualizable por contributors**: cuando una plataforma nueva entra como
candidato o un adapter alcanza un nivel de paridad distinto, se actualiza la tabla
correspondiente en un PR contra `develop`.

---

## Plataformas actuales (King v2.x)

King soporta **11 plataformas** a través de Apex Core: Claude Code como runtime nativo más 10
adapters que traducen los artefactos del framework (skills, hooks, knowledge, MCP, agentes) al
formato nativo de cada plataforma.

| # | Plataforma | Tipo de integración |
|---|-----------|---------------------|
| 1 | Claude Code | Nativo (referencia) |
| 2 | OpenCode | Adapter |
| 3 | Cursor | Adapter |
| 4 | Gemini CLI | Adapter |
| 5 | VS Code Copilot | Adapter |
| 6 | Codex | Adapter |
| 7 | Windsurf | Adapter |
| 8 | Antigravity | Adapter |
| 9 | Kimi | Adapter |
| 10 | Kiro IDE | Adapter |
| 11 | Qwen Code | Adapter |

Claude Code es la **implementación de referencia**: define el comportamiento canónico de cada
feature. Un adapter se mide por cuánto se aproxima a esa referencia (ver Feature Parity Matrix).

---

## Criterios de priorización para nuevas plataformas

Una plataforma candidata es **prioritaria** si cumple **≥ 3 de los 6 criterios** siguientes. Los
criterios son objetivos y verificables — no dependen de opinión:

| ID | Criterio | Cómo se verifica |
|----|----------|------------------|
| C1 | La plataforma tiene ≥ 10k usuarios activos mensuales | Métrica pública del vendor, store, o estimación documentada con fuente |
| C2 | Soporta custom instructions / system prompts configurables | Existe un mecanismo documentado para inyectar instrucciones persistentes |
| C3 | Soporta file context (leer archivos del proyecto) | El agente puede acceder a archivos del workspace |
| C4 | Soporta comandos slash o equivalente | Existe un mecanismo de invocación tipo comando |
| C5 | Hay demanda verificable de la comunidad (≥ 10 issues/requests en king-hub) | Conteo de issues/requests etiquetados `platform-request` |
| C6 | Un contributor externo ya empezó el adapter (Tier 2 o 3 del Trust Model) | Existe un PR o fork público con avance real |

**Regla de priorización**: `criterios_cumplidos >= 3` ⇒ candidato **prioritario**.
Un candidato con < 3 criterios queda registrado pero **no prioritario** hasta que sume otro
criterio (típicamente C5 o C6, que crecen con el tiempo).

La **complejidad de implementación** (Baja / Media / Alta / Muy Alta) es ortogonal a la prioridad:
indica el esfuerzo estimado, no si vale la pena. Un candidato prioritario con complejidad Muy Alta
puede esperar a que un contributor con conocimiento de la plataforma lo tome.

---

## Candidatos identificados (próximas plataformas)

Cada fila cuenta explícitamente los criterios cumplidos. La columna **Prioritario** se deriva de la
regla `≥ 3 criterios`.

| Plataforma | Criterios cumplidos | # | Prioritario | Complejidad | Estado |
|-----------|---------------------|---|-------------|-------------|--------|
| Continue.dev | C1, C2, C3, C4 | 4 | Sí | Media | Candidato A1 |
| Cline (VS Code) | C1, C2, C3, C4 | 4 | Sí | Baja | Candidato A2 |
| Aider | C1, C2, C3 | 3 | Sí | Media | Candidato B1 |
| Amazon Q Developer | C1, C2, C3 | 3 | Sí | Alta | Candidato B2 |
| JetBrains AI | C1, C2, C3, C4 | 4 | Sí | Alta | Candidato B3 |
| GitHub Copilot Chat | C1, C2, C3, C4, C5 | 5 | Sí | Muy Alta | Candidato C1 |
| Tabnine | C1, C2 | 2 | No | Alta | Registrado (no prioritario) |

Notas de lectura:
- **A1/A2** son el siguiente lote por complejidad baja/media y alta prioridad.
- **B1–B3** son prioritarios pero con complejidad mayor; ideales para contributors con experiencia
  en esas plataformas.
- **C1** tiene la mayor demanda (5 criterios, incluyendo C5) pero complejidad Muy Alta.
- **Tabnine** queda registrado: solo cumple 2 criterios. Subirá a prioritario si gana C5 (demanda)
  o C6 (un contributor empieza el adapter).

---

## Interface `AgentAdapter` (contrato público para contributors)

`AgentAdapter` es la interface que **todo adapter debe implementar** para ser un adapter King
válido. Está definida en Apex Core (Go) y M-97 la documenta como **contrato público** para
contributors. La firma indica tipos de entrada y salida; el contrato de comportamiento describe qué
hace cada método y **bajo qué condición retorna error**.

Invariante de seguridad transversal: **los adapters solo escriben configuración** (archivos de
instrucciones, hooks declarativos, manifiestos MCP) en el formato nativo de la plataforma. **Ningún
adapter ejecuta código arbitrario** ni descarga ni corre binarios de terceros. Toda escritura es
sobre rutas de configuración conocidas y declarativas.

### Métodos

El adapter expone **7 métodos**:

```go
type AgentAdapter interface {
    Detect() bool
    Capabilities() AgentCapabilities
    Install(config AgentConfig) error
    ConfigureSkills(skills []Skill) error
    ConfigureHooks(hooks []Hook) error
    ConfigureMCP(mcpServers []MCPServer) error
    Verify() (bool, []string)
}
```

#### 1. `Detect() bool`
- **Firma**: sin parámetros → `bool`.
- **Contrato**: detecta si la plataforma está instalada y activa en el entorno actual (presencia
  de su binario, su directorio de configuración o su variable de entorno característica).
- **Retorno**: `true` si la plataforma está presente y operable; `false` en caso contrario.
- **Condición de error**: este método **no retorna error**. La ausencia de la plataforma es un
  resultado válido (`false`), no un fallo. Cualquier excepción de I/O al inspeccionar el entorno se
  trata internamente como "no detectado".

#### 2. `Capabilities() AgentCapabilities`
- **Firma**: sin parámetros → `AgentCapabilities`.
- **Contrato**: reporta qué features de King soporta la plataforma y a qué nivel (`full`,
  `partial`, `none`), incluyendo si soporta `KING_LANG` (selección de idioma de las instrucciones).
  Es la fuente de verdad que alimenta la Feature Parity Matrix y los warnings de `Install`.
- **Retorno**: estructura `AgentCapabilities` con un nivel por feature (Skills, Hooks, MCP, Agents,
  CASTLE, KING_LANG, ...).
- **Condición de error**: este método **no retorna error**. Es una declaración estática del adapter;
  siempre devuelve una estructura válida. Si una feature no aplica, se reporta como `none`.

#### 3. `Install(config AgentConfig) error`
- **Firma**: `config AgentConfig` → `error`.
- **Contrato**: orquesta la instalación completa escribiendo la configuración nativa de la
  plataforma (instrucciones, hooks, knowledge, MCP) a partir de `config`. Internamente invoca
  `ConfigureSkills`, `ConfigureHooks` y `ConfigureMCP` según las capabilities. Cuando la plataforma
  no soporta una feature, **emite un warning claro** indicando qué quedó fuera y cómo mitigarlo, y
  **continúa** con las features soportadas (degradación elegante, no fallo total). Respeta
  `KING_LANG` si `Capabilities` lo declara soportado.
- **Retorno**: `nil` si la instalación de las features soportadas se completó.
- **Condición de error**: retorna `error` si **no puede escribir** la configuración nativa (permisos,
  ruta inexistente, disco lleno) o si `config` es inválido (campos requeridos faltantes). Una feature
  no soportada **no es error** — es un warning. La operación es idempotente: reinstalar no duplica
  ni corrompe configuración previa.

#### 4. `ConfigureSkills(skills []Skill) error`
- **Firma**: `skills []Skill` → `error`.
- **Contrato**: traduce cada `SKILL.md` (canónico en español) al formato de instrucciones nativo de
  la plataforma (p. ej. reglas de Cursor, custom instructions de Copilot, prompt de sistema). Si la
  plataforma soporta `KING_LANG`, escribe la variante de idioma correspondiente.
- **Retorno**: `nil` si todos los skills soportados se tradujeron y escribieron.
- **Condición de error**: retorna `error` si falla la escritura del archivo de instrucciones nativo o
  si un `Skill` no puede mapearse a ningún mecanismo de la plataforma (cuando Skills es `none`, este
  método **no se invoca**; el warning lo emite `Install`).

#### 5. `ConfigureHooks(hooks []Hook) error`
- **Firma**: `hooks []Hook` → `error`.
- **Contrato**: configura los hooks en el mecanismo nativo de la plataforma (eventos pre/post,
  triggers declarativos). Solo declara configuración; **no instala ni ejecuta** los scripts.
- **Retorno**: `nil` si los hooks soportados quedaron configurados.
- **Condición de error**: retorna `error` si la escritura de la configuración de hooks falla. Si la
  plataforma no soporta hooks (`none`), este método **no se invoca** y `Install` emite el warning
  correspondiente.

#### 6. `ConfigureMCP(mcpServers []MCPServer) error`
- **Firma**: `mcpServers []MCPServer` → `error`.
- **Contrato**: configura los servidores MCP en el formato nativo (p. ej. `.mcp.json` o equivalente)
  **si la plataforma soporta MCP**. Solo escribe el manifiesto de conexión; no levanta servidores.
- **Retorno**: `nil` si los servidores MCP soportados quedaron declarados.
- **Condición de error**: retorna `error` si la escritura del manifiesto MCP falla. Si la plataforma
  no soporta MCP (`none`), este método **no se invoca** y `Install` emite el warning.

#### 7. `Verify() (bool, []string)`
- **Firma**: sin parámetros → `(bool, []string)`.
- **Contrato**: verifica que la instalación quedó correcta (archivos presentes, formato válido,
  rutas esperadas). Retorna el resultado y la lista de issues detectados.
- **Retorno**: `(true, [])` si todo está correcto; `(false, [issues...])` si hay problemas, donde
  cada string describe un issue concreto y accionable.
- **Condición de error**: este método **no retorna `error`**; los problemas se reportan como
  `(false, issues)`. La lista vacía con `true` es el único estado "todo OK". Si no puede inspeccionar
  el entorno, retorna `(false, ["no se pudo verificar: <motivo>"])`.

### Resumen de contrato de error

| Método | Retorno | Retorna error |
|--------|---------|---------------|
| `Detect` | `bool` | No (ausencia = `false`) |
| `Capabilities` | `AgentCapabilities` | No (declaración estática) |
| `Install` | `error` | Sí — si no puede escribir config o `config` inválido |
| `ConfigureSkills` | `error` | Sí — si falla escritura de instrucciones |
| `ConfigureHooks` | `error` | Sí — si falla escritura de hooks |
| `ConfigureMCP` | `error` | Sí — si falla escritura de manifiesto MCP |
| `Verify` | `(bool, []string)` | No (issues vía slice) |

---

## Soporte de `KING_LANG`

`KING_LANG` selecciona el idioma de las instrucciones que el adapter escribe (canónico español;
variantes `en`, `pt`, `fr` cuando existen — ver `i18n-framework.md`). El soporte depende de la
plataforma:

- **Donde la plataforma lo permita** (custom instructions configurables por idioma o múltiples
  archivos de instrucciones), el adapter **MUST** respetar `KING_LANG` y escribir la variante
  correspondiente. `Capabilities()` reporta `KING_LANG: full`.
- **Donde la plataforma solo admita un set de instrucciones**, el adapter escribe el canónico español
  e ignora `KING_LANG`, reportando `KING_LANG: none` y emitiendo un warning en `Install` indicando
  que la plataforma no soporta selección de idioma.

`KING_LANG` **nunca** cambia el comportamiento de un skill ni de un gate CASTLE — solo el idioma del
texto de las instrucciones.

---

## Feature Parity Matrix

Cada adapter documenta qué features de King soporta y a qué nivel. Niveles: **✓ full** (paridad con
Claude Code), **✓ partial** (soportado con limitaciones documentadas), **✗** (no soportado). Cuando
un adapter reporta `✗` o `partial` en una feature, `AgentAdapter.Install()` emite un warning claro
explicando qué quedó fuera y cómo el usuario puede mitigarlo.

Claude Code es la referencia y aparece como **✓ full** en todas las features.

| Feature | Claude Code | OpenCode | Cursor | Gemini CLI | VS Code Copilot | Codex | Windsurf | Antigravity | Kimi | Kiro IDE | Qwen Code |
|---------|-------------|----------|--------|------------|-----------------|-------|----------|-------------|------|----------|-----------|
| Skills | ✓ full | ✓ full | ✓ partial | ✓ full | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ full | ✓ partial |
| Hooks | ✓ full | ✓ full | ✗ | ✓ partial | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ partial | ✗ |
| MCP | ✓ full | ✓ full | ✓ partial | ✓ full | ✓ partial | ✗ | ✓ partial | ✓ partial | ✗ | ✓ partial | ✓ partial |
| Agents | ✓ full | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| CASTLE | ✓ full | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial | ✓ partial |
| KING_LANG | ✓ full | ✓ full | ✓ partial | ✓ full | ✓ partial | ✗ | ✓ partial | ✓ partial | ✗ | ✓ partial | ✗ |

La matriz cubre las **11 plataformas actuales** (11 columnas) y **6 features** evaluadas (Skills,
Hooks, MCP, Agents, CASTLE, KING_LANG). Se actualiza cuando un adapter cambia su nivel de paridad.

### Comportamiento ante una feature no soportada

1. `Capabilities()` declara el nivel (`partial`/`none`).
2. `Install()` detecta el nivel y, para `partial`/`none`, **emite un warning** del tipo:
   `"[adapter X] Hooks no soportado: los gates pre/post no se ejecutarán automáticamente.
   Mitigación: ejecuta 'king-core:castle' manualmente antes de cada merge."`
3. `Install()` **continúa** con las features soportadas — nunca aborta por una feature faltante.
4. El usuario obtiene una instalación funcional con expectativas claras de qué quedó fuera.

---

## Proceso de contribución de un adapter

1. **Abrir Issue** en king-core con el template **"New Platform Adapter"** — describir la plataforma
   y enumerar los criterios cumplidos (C1–C6) con su evidencia.
2. **Decisión del core team**: aprueba o rechaza según los criterios de priorización (`≥ 3`).
3. Si **aprobado**: fork + implementar la interface `AgentAdapter` (los 7 métodos) + tests de
   verificación.
4. **PR contra `develop`** que incluya: implementación del adapter + test de detección (`Detect`) +
   test de instalación (`Install`) + test de verificación (`Verify`).
5. **Code review** por el equipo core (al menos 1 maintainer con conocimiento de la plataforma).
6. **Merge a `develop`** → incluido en el próximo release de Apex Core, y la plataforma se mueve de la
   tabla de candidatos a la lista de plataformas actuales + una columna nueva en la Feature Parity
   Matrix.

---

## Dependencias y alcance

- **M-97 es documental**: define el contrato y el roadmap. La **implementación** de adapters nuevos
  es trabajo de Apex Core (Go), fuera del scope de M13.
- La interface `AgentAdapter` ya está definida en Apex Core (M12); M-97 la publica como contrato para
  contributors.
- El soporte runtime de `KING_LANG` requiere que Apex Core lo provea (trabajo de M12 o posterior); la
  policy de idiomas vive en `i18n-framework.md`.

## See Also

- `knowledge/universal/i18n-framework.md` — policy de i18n y selección de idioma (`KING_LANG`).
- `knowledge/universal/skill-versioning.md` — versionado de skills que los adapters traducen.
- M12 — Apex Core: definición original de la interface `AgentAdapter` y los 10 adapters base.
