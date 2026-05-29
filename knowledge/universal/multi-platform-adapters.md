# Multi-Platform Adapters — Apex Core (M-17)

> **Qué es esto**: la SPEC del *translator layer* de King Framework. Define el contrato de los adapters que
> proyectan los skills King a 11 plataformas de coding-agent. El binario que implementa esta spec (`apex-core`,
> en Go) vive en el repo externo `king-framework/apex-core`. Este documento es el CONTRATO, no la implementación.
>
> Relacionado: [`cli-architecture.md`](./cli-architecture.md) (comandos del binario), [`skill-versioning.md`](./skill-versioning.md) (versionado).

## Principio fundamental: source-of-truth único

El source of truth es **siempre King (Claude Code)**: `SKILL.md` + `hooks.json` + `agents/` + `knowledge/`.
Apex Core **lee** ese formato nativo y lo **proyecta** al formato que cada plataforma espera. Los adapters son
proyecciones de salida:

- Apex Core **NO** es una reescritura de King en Go.
- Si un adapter se rompe o una plataforma cambia su formato, el skill en Claude Code **sigue funcionando intacto**.
- La traducción es **unidireccional** (King → plataforma). No hay sync inverso.

## Interface `AgentAdapter`

Cada plataforma implementa esta interface. Contrato (Go):

```go
type AgentAdapter interface {
    // Detecta si la plataforma está instalada en el sistema.
    Detect() (bool, error)

    // Instala el plugin/extension en la plataforma.
    Install(config KingConfig) error

    // Convierte skills King al formato de la plataforma (merge no-destructivo).
    ConfigureSkills(skills []Skill, targetDir string) error

    // Convierte hooks King al formato de la plataforma (si soportado; si no, WARN).
    ConfigureHooks(hooks HooksJSON, targetDir string) error

    // Configura MCP server si la plataforma lo soporta.
    ConfigureMCP(mcpConfig MCPConfig, targetDir string) error

    // Verifica que la instalación es correcta y reporta capacidades.
    Verify() (VerifyReport, error)
}
```

### Struct `VerifyReport` (T23)

Output estructurado de `Verify()`. Cada check tiene status y mensaje legible:

```go
type CheckStatus string // "OK" | "WARN" | "ERROR"

type Check struct {
    Name    string      // p.ej. "Skills", "Hooks", "MCP"
    Status  CheckStatus
    Message string      // "5/5 instalados", "no soportados en Cursor — 3 hooks no traducidos"
}

type VerifyReport struct {
    Platform string
    Checks   []Check
    OK       bool // false si algún Check es ERROR (WARN no invalida)
}
```

Render esperado:

```
[OK]   Skills: 5/5 instalados
[WARN] Hooks: no soportados en Cursor — 3 hooks no traducidos
[OK]   MCP: configurado
```

> `KingConfig` (paths, agent, version) se define en [`cli-architecture.md`](./cli-architecture.md) (T22),
> porque es compartida con todos los comandos del CLI.

## Las 11 plataformas (tiers y capacidades)

> La tabla está ordenada **por tier** (no por prioridad histórica): primero las Tier 1, luego Tier 2, luego Tier 3.

| Plataforma | Tier | Skills | Hooks | MCP | Destino del skill |
|-----------|:----:|--------|-------|-----|-------------------|
| Claude Code | 1 | nativo | nativo | nativo | (identity — sin traducción) |
| Cursor | 1 | sí | via MCP | sí | `.cursor/rules/{skill}.mdc` |
| Gemini CLI | 1 | sí | no | sí | `GEMINI.md` (append) |
| OpenCode | 1 | sí | parcial | sí | `.opencode/instructions/{skill}.md` |
| Continue | 2 | sí | no | sí | `.continue/config.json` (context provider) |
| Cody | 2 | sí | no | sí | `cody.json` (custom command) |
| Windsurf | 2 | sí | no | sí | `.windsurf/rules/{skill}.md` |
| Codex | 2 | sí | no | no | `.codex/instructions.md` (merged) |
| Aider | 3 | sí | no | no | `.aider.conf.yml` (`read: [...]`) |
| Zed | 3 | sí | no | sí | `.zed/settings.json` (system_prompt append) |
| Helix / Neovim | 3 | via LSP/MCP | no | sí | `.mcp/config.json` (MCP server ref) |

**Reglas de tier**:
- **Tier 1** — soporte completo o casi. Bloquea release si falla.
- **Tier 2** — solo skills (sin hooks). No bloquea release.
- **Tier 3** — best-effort, típicamente solo MCP. No bloquea release; la comunidad contribuye mejoras.

## Árbol de traducción

```
King SKILL.md
├── Cursor     → .cursor/rules/{skill-name}.mdc
├── Gemini     → GEMINI.md (sección appended)
├── OpenCode   → .opencode/instructions/{skill-name}.md
├── Codex      → .codex/instructions.md (merged)
├── Continue   → .continue/config.json (context provider entry)
├── Cody       → cody.json (custom command)
├── Windsurf   → .windsurf/rules/{skill-name}.md
├── Aider      → .aider.conf.yml (read: [...])
├── Zed        → .zed/settings.json (system_prompt appended)
└── Helix/Nvim → .mcp/config.json (MCP server ref)

King hooks.json
├── Claude Code → completo (nativo)
├── OpenCode    → parcial (subset soportado)
└── resto       → no traducible → WARN en Verify()
```

## Merge strategy: NUNCA overwrite

Requisito transversal de **todo** adapter (riesgo R02). Reglas:

1. **Merge, no overwrite.** El adapter integra el contenido King junto al existente del usuario.
2. **Backup obligatorio.** Antes de escribir, snapshot en `.king/backups/pre-install/{timestamp}/`.
3. **Idempotencia** para formatos append (Gemini `GEMINI.md`, Zed `settings.json`, Codex `instructions.md`):
   re-instalar **no duplica** la sección — se delimita con marcadores `<!-- KING:BEGIN -->` … `<!-- KING:END -->`
   y se reemplaza el bloque entre marcadores.
4. **`--force`** sólo sobrescribe dentro del bloque King; jamás toca contenido fuera de los marcadores.

### Adapter Cursor (T17)
`SKILL.md` → un `.cursor/rules/{skill-name}.mdc` por skill. El `.mdc` lleva frontmatter Cursor
(`description`, `globs`, `alwaysApply`) + el cuerpo del skill simplificado. Reglas del usuario en `.cursor/rules/`
quedan intactas. Backup previo en `.king/backups/pre-install/`.

### Adapter Gemini CLI (T18)
`SKILL.md` → sección en `GEMINI.md` (root) bajo `# King Framework Skills`, delimitada por marcadores. Idempotente.
El `GEMINI.md` previo del usuario no se trunca: se preserva todo lo que esté fuera del bloque King.

### Adapter OpenCode (T19)
`SKILL.md` → `.opencode/instructions/{skill-name}.md`. Formato muy similar a Claude Code; diferencias mapeadas:
OpenCode soporta un subset de hooks (parcial) — los hooks soportados se traducen, el resto → WARN.

### Adapters Tier 2 (T20) — Continue, Cody, Windsurf, Codex
Mapeo mínimo **solo skills**. Sin hooks. Cada uno según su destino (tabla). Codex además sin MCP: skills van como
system prompt merged en `.codex/instructions.md`.

### Adapters Tier 3 (T21) — Aider, Zed, Helix, Neovim
Best-effort. Aider: skills como `read:` files en `.aider.conf.yml`. Zed: append a `system_prompt` en
`.zed/settings.json`. Helix/Neovim: sólo setups MCP-capable → referencia al MCP server en `.mcp/config.json`.

## `--dry-run`

Todo `install` MUST soportar `--dry-run`: lista exactamente los archivos que se crearían/modificarían (con diff
resumido) y **no toca el filesystem**. Es el modo de verificación previo recomendado.

## Fixtures golden para testing de adapters (T27)

Estrategia de testing (la implementan los tests del repo externo, aquí se define el contrato):

- **Input**: un set fijo de archivos King de referencia (`testdata/king-input/`): N `SKILL.md`, un `hooks.json`,
  un `agents/`, un `knowledge/`.
- **Output golden**: por plataforma, el árbol esperado (`testdata/golden/{platform}/`).
- **Aserción**: `ConfigureSkills`/`ConfigureHooks`/`ConfigureMCP` sobre el input deben producir exactamente el
  golden (byte-a-byte salvo timestamps). Cambios de formato de una plataforma se detectan como diff golden.

## Adapter versioning (T28)

Cada adapter declara la versión del formato de su plataforma que soporta (`platformFormatVersion`). Si una
plataforma cambia su formato (p.ej. Cursor migra `.mdc`), se versiona el adapter siguiendo la política de
[`skill-versioning.md`](./skill-versioning.md) (semver + deprecation window). `Verify()` MUST emitir WARN si
detecta una versión de formato no soportada.

## Checklist de revisión final (T29)

- [x] 11 adapters especificados (Cursor, Gemini, OpenCode, Continue, Cody, Windsurf, Codex, Aider, Zed, Helix, Neovim)
- [x] Tabla de compatibilidad con 11 filas, tier y capacidades (Skills/Hooks/MCP)
- [x] Merge strategy no-destructiva + backup + idempotencia documentadas
- [x] Structs `AgentAdapter` y `VerifyReport` definidos; `KingConfig` referenciado a `cli-architecture.md`
- [x] Fixtures golden (T27) y adapter-versioning (T28) documentados
- [x] Hooks no traducibles → WARN en `Verify()`

## Trazabilidad Gherkin (M12 §7 — Feature: Apex Core Multi-platform Adapters)

| Escenario | Cubierto por |
|-----------|--------------|
| Cursor no sobreescribe reglas existentes | Merge strategy + backup + Adapter Cursor |
| Gemini genera GEMINI.md válido sin truncar | Idempotencia + Adapter Gemini |
| Verify reporta capacidades por plataforma | `VerifyReport` + tiers |
| dry-run muestra cambios sin aplicar | sección `--dry-run` |
| Distribución verificable (firma GPG) | ver [`cli-architecture.md`](./cli-architecture.md) §firma |
