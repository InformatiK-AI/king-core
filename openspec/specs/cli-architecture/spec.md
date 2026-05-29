# Delta Spec — cli-architecture (M-63)

## ADDED Requirements

### Requirement: Knowledge `cli-architecture.md`
El framework SHALL proveer `knowledge/universal/cli-architecture.md` con la spec del binario `king-framework`:
estructura de packages Go, los comandos (`install`, `status`, `doctor`, `update`, `backup`, `restore`,
`skill *`, `agent *`), sus flags, exit codes y política de output. MUST referenciar `multi-platform-adapters.md`
(el binario usa la interface `AgentAdapter`).

### Requirement: Comando `install`
SHALL detectar el agente (`--agent auto|cursor|gemini|…`), instalar el plugin, configurar hooks y verificar.
MUST soportar `--dry-run`, `--force`, `--config <path>`.

#### Scenario: install detecta agente automáticamente
- **Given** Claude Code instalado y el proyecto sin `.king/`
- **When** `king-framework install`
- **Then** output "Agente detectado: claude-code", crea `.king/`, `hooks.json` con matchers críticos, exit code 0

### Requirement: Comando `doctor` con `--fix`
SHALL verificar plugin, hooks, MCP, `.king/` válido, versión y dependencias, reportando `[OK]/[WARN]/[ERROR]`.
Con `--fix` MUST aplicar correcciones automáticas. Exit code 2 ante validation error.

#### Scenario: doctor detecta y --fix corrige
- **Given** `.king/` sin `coverage.yaml`
- **When** `king-framework doctor` → exit 2 con `[WARN] .king/coverage.yaml ausente`; luego `doctor --fix`
- **Then** crea `coverage.yaml` con defaults de M01 y el `doctor` siguiente reporta `[OK]`

### Requirement: Comando `status` (human + JSON)
SHALL mostrar agente activo, fase SDD, skills, gates, última sesión y estado Engram/Chronicle. Con `--json`
MUST emitir JSON válido con `sdd_phase` y `gates_status`. Exit code 0.

#### Scenario: status --json es parseable
- **Given** proyecto con fase `sdd-build`
- **When** `king-framework status --json`
- **Then** JSON válido con `"sdd_phase": "sdd-build"` y `gates_status` por gate, exit 0

### Requirement: Comando `update` con verificación de firma
SHALL self-actualizar por canal (`stable|beta|canary`) y MUST verificar la firma GPG ANTES de reemplazar el
binario; si la verificación falla, el binario actual MUST NO modificarse.

#### Scenario: update no aplica si la firma falla
- **When** `king-framework update` y la firma GPG no valida
- **Then** el binario actual no es reemplazado

### Requirement: Exit codes, output y cross-platform
SHALL definir exit codes estándar (0 success, 1 general, 2 validation, 3 network, 4 permission, 5 version
conflict), output human con ANSI desactivable (`--no-color`/`NO_COLOR=1`), `--json`, `--quiet`, y shell
completions (bash/zsh/fish/PowerShell). El comportamiento MUST ser idéntico cross-OS salvo separadores de path.

#### Scenario: CLI cross-platform consistente
- **Given** binario `windows/amd64`
- **When** `king-framework.exe status` en PowerShell
- **Then** output idéntico a linux/amd64 salvo separadores de path; mismo exit code

> Set Gherkin completo: M12 §7 (Feature: CLI Cross-Platform king-framework — 6 escenarios).
> Consistencia: los comandos `doctor`/`status` MUST cubrir lo que el skill `onboard` (M-11) invoca como `doctor`/`status`/`hint`.
