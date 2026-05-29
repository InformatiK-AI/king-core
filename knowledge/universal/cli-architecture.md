# CLI Architecture — `king-framework` (M-63)

> **Qué es esto**: la SPEC del binario CLI `king-framework` (Apex Core). Define comandos, flags, exit codes,
> output y distribución. El binario en Go vive en el repo externo `king-framework/apex-core`; este documento es
> el CONTRATO. M-17 es el motor (interface `AgentAdapter`), M-63 es el volante (estos comandos) — mismo binario.
>
> Relacionado: [`multi-platform-adapters.md`](./multi-platform-adapters.md), [`skill-versioning.md`](./skill-versioning.md).

## Estructura de packages (Go)

```
apex-core/
├── cmd/king-framework/main.go      // entrypoint, dispatch de comandos
├── internal/cli/                   // parsing de comandos/flags, output (cobra-style)
├── internal/adapters/              // implementaciones de AgentAdapter (1 por plataforma)
├── internal/config/                // KingConfig, lectura de .king/
├── internal/doctor/                // checks de doctor
├── internal/dist/                  // update, firma GPG, canales
└── internal/backup/                // snapshot/restore con dedup
```

## Struct `KingConfig` (T22)

Configuración mínima que el binario necesita para operar. Compartida por todos los comandos:

```go
type KingConfig struct {
    KingDir   string // ruta a .king/ (default: ./.king)
    Agent     string // "claude-code" | "cursor" | "gemini" | ... | "auto"
    Version   string // versión del framework instalada (semver)
    ProjectDir string // root del proyecto
    NoColor   bool   // desactiva ANSI (también vía NO_COLOR=1)
}
```

## Comandos

### `install [--agent auto|cursor|gemini|opencode|...]`
Detecta el agente instalado, instala el plugin, configura hooks y verifica.
- Flags: `--dry-run` (lista cambios sin aplicar), `--force`, `--config <path>`.
- Flujo: detectar agente → backup `.king/backups/pre-install/` → `ConfigureSkills`/`ConfigureHooks`/`ConfigureMCP`
  del adapter → `Verify()`.
- Errores: agente no detectado → exit 2; sin permisos de escritura → exit 4.

```
$ king-framework install
Agente detectado: claude-code
✓ .king/ creado con configuración base
✓ hooks.json con matchers críticos configurados
✓ Verify: Skills 12/12, Hooks 4/4, MCP configurado
exit 0
```

### `status [--json] [--project <path>]`
Muestra agente activo, fase SDD, skills cargados, gates configurados, última sesión y estado Engram/Chronicle.
- `--json` → JSON parseable (campos `agent`, `sdd_phase`, `gates_status`, `last_session`, `memory_backend`).
- Default human-readable con ANSI.

```json
{
  "agent": "claude-code",
  "sdd_phase": "sdd-build",
  "gates_status": { "coverage": "ok", "castle": "ok", "performance": "warn" },
  "last_session": "2026-05-28T21:00:00Z",
  "memory_backend": "engram"
}
```

### `doctor [--fix] [--verbose]`
Verifica plugin instalado, hooks activos, MCP configurado, `.king/` válido, versión y dependencias. Reporta
`[OK]/[WARN]/[ERROR]`. Con `--fix` aplica correcciones automáticas.
- Exit 0 si todo OK; exit 2 si hay validation error (WARN/ERROR).

```
$ king-framework doctor
[OK]   plugin king-core instalado (v1.9.x)
[WARN] .king/coverage.yaml ausente — coverage gate inactivo
[OK]   hooks.json parseable, 4 matchers
exit 2

$ king-framework doctor --fix
[FIX]  .king/coverage.yaml creado con defaults de M01
[OK]   .king/coverage.yaml presente
exit 0
```

Lista de checks (exhaustiva): plugin presente y versión; `hooks.json` parseable y matchers críticos; MCP server
alcanzable; `.king/` con `knowledge/`, `sessions/`, `coverage.yaml`, `castle.yaml`/`performance.yaml`; versión del
framework vs última disponible; dependencias del stack detectadas.

> **Consistencia con M-11 (onboard):** los datos de `doctor` y `status` aquí son la fuente que el skill `onboard`
> (C2) consume como `/onboard doctor` y `/onboard status`. El `hint` de onboard deriva el "próximo paso" de
> `status.sdd_phase` + `onboard-progress.yaml`. (T40)

### `update [--channel stable|beta|canary]`
Self-update del binario. **Verifica la firma GPG ANTES de reemplazar**; si la verificación falla, el binario
actual NO se modifica. Soporta rollback al binario previo si el nuevo falla un smoke check.

### `backup [--output <path>] [--include knowledge|sessions|all]` / `restore <snapshot> [--dry-run]`
`backup`: snapshot de `.king/` en `.tar.gz` **firmado**, con dedup de contenido. `restore`: muestra diff antes de
aplicar; `--dry-run` solo muestra el diff. Verificación de integridad (checksum) antes de restaurar.

### `skill list|install|update|remove|info`
Gestión de skills. `list [--installed] [--available] [--query <term>]`, `install <name>[@version]`,
`update [<name>|--all]`, `remove <name>`, `info <name>`. Define la **interface** hacia Apex Hub (marketplace),
sin implementar el Hub (eso es M-Apex-Hub, posterior).

### `agent list|enable|disable`
`list` muestra agentes disponibles; `enable <name>`/`disable <name>` activa/desactiva un agente y refleja el
cambio en `hooks.json` (aditivo, sin romper matchers existentes).

## Exit codes estándar (T37)

```
0 — success
1 — general error
2 — validation error (setup incorrecto)
3 — network error
4 — permission error
5 — version conflict
```

## Output (T37)

- **Default**: human-readable con colores ANSI. Desactivables con `--no-color` o `NO_COLOR=1`.
- `--json`: JSON parseable para scripting (todos los comandos de lectura).
- `--quiet`: solo exit code, sin stdout.
- Cross-platform: output idéntico en linux/darwin/windows salvo separadores de path.

## Shell completions (T38)

`king-framework completion {bash|zsh|fish|powershell}` emite el script de completado para el shell indicado.

## Distribución (T25)

- Homebrew tap: `brew install king-framework/tap/king`
- Scoop bucket: `scoop install king-framework/king`
- `go install github.com/king-framework/apex-core@latest`
- GitHub Releases: binarios `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`, `windows/amd64`
- Docker: `ghcr.io/king-framework/apex-core:latest`

## Firma y verificación (T26 · riesgo R01)

- Releases firmados con **GPG**; checksums SHA-256 publicados junto a cada binario.
- `king-framework --verify-signature` valida firma GPG + checksum del binario actual.
- `update` verifica firma **antes** de reemplazar. SBOM publicado por release.

```
$ king-framework --verify-signature
Firma GPG: válida
Checksum SHA-256: coincide
exit 0
```

## Testing strategy (T39)

Contrato de testing (lo ejecutan los tests del repo externo):
- **Subprocess tests**: invocar el binario compilado y aseverar stdout/exit code.
- **CI matrix OS**: linux/macos/windows × arquitecturas soportadas.
- **Fixtures `.king/`**: un set de directorios `.king/` por estado (sin coverage.yaml, con veto, fase sdd-build…)
  para ejercitar `doctor`/`status`.

> Ver también las fixtures golden de adapters en [`multi-platform-adapters.md`](./multi-platform-adapters.md) §fixtures.

## Trazabilidad Gherkin (M12 §7 — Feature: CLI Cross-Platform king-framework)

| Escenario | Cubierto por |
|-----------|--------------|
| install detecta agente automáticamente | comando `install` |
| doctor detecta y reporta problemas | comando `doctor` (exit 2) |
| doctor --fix corrige problemas | comando `doctor --fix` |
| status output JSON | comando `status --json` |
| CLI es cross-platform | sección Output (cross-platform) |
| update verifica firma antes de aplicar | comando `update` + §Firma |
