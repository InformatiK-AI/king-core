# Delta Spec — multi-platform-adapters (M-17)

## ADDED Requirements

### Requirement: Knowledge `multi-platform-adapters.md`
El framework SHALL proveer `knowledge/universal/multi-platform-adapters.md` que especifique el translator layer
Apex Core. MUST documentar la interface `AgentAdapter` (Detect/Install/ConfigureSkills/ConfigureHooks/
ConfigureMCP/Verify), los structs `KingConfig` y `VerifyReport`, y la tabla de 11 plataformas con su nivel de
soporte (Skills/Hooks/MCP) y tier.

### Requirement: Principio source-of-truth
El doc SHALL establecer que el source of truth es siempre King (Claude Code) y que los adapters son proyecciones
de salida: si un adapter rompe, el skill nativo MUST seguir funcionando intacto. NO es una reescritura en Go.

#### Scenario: Adapter Cursor no sobreescribe reglas del usuario
- **Given** `.cursor/rules/my-custom-rule.mdc` existe y king-core tiene 5 skills
- **When** `king-framework install --agent cursor`
- **Then** se crean los 5 `.mdc` de King, `my-custom-rule.mdc` queda intacto, y existe `.king/backups/pre-install/`

### Requirement: Merge strategy no-destructiva
Todo adapter SHALL hacer merge, nunca overwrite. Para formatos append (Gemini `GEMINI.md`, Zed `settings.json`)
MUST ser idempotente (re-instalar no duplica la sección). MUST crear backup en `.king/backups/pre-install/`.

#### Scenario: Gemini genera GEMINI.md válido sin truncar
- **Given** un proyecto con el skill `/build`
- **When** `king-framework install --agent gemini`
- **Then** `GEMINI.md` contiene la sección "# King Framework Skills" con `/build`, y el contenido previo no se trunca

### Requirement: Tiers de compatibilidad
El doc MUST clasificar las plataformas en Tier 1 (Claude Code, Cursor, Gemini, OpenCode — soporte completo o
casi), Tier 2 (Continue, Cody, Windsurf, Codex — solo skills) y Tier 3 (Aider, Zed, Helix/Neovim — best-effort
MCP). Tier 2/3 MUST NO bloquear release. Hooks no traducibles MUST emitir WARN en `Verify()`.

#### Scenario: Verify reporta capacidades por plataforma
- **When** `king-framework install --agent cursor --verify`
- **Then** output muestra `[OK] Skills: 5/5`, `[WARN] Hooks: no soportados en Cursor`, `[OK] MCP: configurado`

### Requirement: dry-run y fixtures golden
El doc SHALL especificar `--dry-run` (lista cambios sin tocar el filesystem) y la estrategia de fixtures golden
para testing de adapters (input King → output esperado por plataforma) y el adapter-versioning (referencia a
`skill-versioning.md`; cómo detectar y versionar cuando una plataforma cambia su formato).

#### Scenario: dry-run no muta el filesystem
- **Given** `.cursor/rules/` no existe
- **When** `king-framework install --agent cursor --dry-run`
- **Then** el output lista los archivos que se crearían y ningún archivo es creado/modificado

> Set Gherkin completo: M12 §7 (Feature: Apex Core Multi-platform Adapters — 5 escenarios).
