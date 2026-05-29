# Tasks — M-17 Apex Core + M-63 CLI (spec)

> Detalle largo (criterios, paths) en `mejora/planes-detallados/M12-developer-experience-tooling.md §6 (T16-T40)`.
> Aquí: tareas de 1 línea. Marcar `[x]` al completar (sdd-apply). T49-T50 NO aplican a este cambio.

## Apply — multi-platform-adapters.md (M-17)
- [x] T16 Crear `knowledge/universal/multi-platform-adapters.md`: interface `AgentAdapter`, tabla plataformas, mapeo formatos
- [x] T17 Spec adapter Cursor (`.cursor/rules/*.mdc`): conversión, merge strategy, backup
- [x] T18 Spec adapter Gemini (`GEMINI.md` append): formato de sección, idempotencia
- [x] T19 Spec adapter OpenCode (`.opencode/instructions/`): diff vs Claude Code
- [x] T20 Spec adapters Tier 2 (Continue, Cody, Windsurf, Codex): mapeo mínimo solo-skills
- [x] T21 Spec adapters Tier 3 (Aider, Zed, Helix, Neovim): best-effort MCP
- [x] T23 Definir struct `VerifyReport` (checks con status y mensaje)
- [x] T27 Spec fixtures golden de adapters (input King → output esperado)
- [x] T28 Definir adapter-versioning (referencia a skill-versioning.md)
- [x] T29 Revisión final: 11 adapters con spec completa + tabla de compatibilidad correcta

## Apply — cli-architecture.md (M-63 + structs M-17)
- [x] T22 Definir struct `KingConfig` (paths, agent, version)
- [x] T24 Crear `knowledge/universal/cli-architecture.md`: packages Go, comandos, integración adapters
- [x] T25 Estrategia de distribución (Homebrew, Scoop, go install, Docker, GitHub Releases)
- [x] T26 Estrategia de firma (GPG, checksum, verificación en update)
- [x] T30 Documentar `install` (detección agente, pasos, errores, flags)
- [x] T31 Documentar `status` (datos de `.king/`, output human/JSON, flags)
- [x] T32 Documentar `doctor` (checks exhaustivos, `--fix`)
- [x] T33 Documentar `update` (firma, canales, rollback)
- [x] T34 Documentar `backup`/`restore` (snapshot, dedup, integridad)
- [x] T35 Documentar `skill *` (sub-comandos, interface Apex Hub sin implementarlo)
- [x] T36 Documentar `agent *` (enable/disable, efecto en hooks.json)
- [x] T37 Tabla exit codes + política de output (`--no-color`/`--quiet`/`--json`)
- [x] T38 Shell completions (bash/zsh/fish/PowerShell)
- [x] T39 Spec de testing del CLI (subprocess tests, CI matrix OS, fixtures `.king/`)
- [x] T40 Revisar consistencia con comandos doctor/status/hint de M-11

## Verify
- [x] Cobertura Gherkin §7: M-17 (5 escenarios) + M-63 (6 escenarios) reflejados en los docs
- [ ] Coherencia cruzada cli-architecture ↔ multi-platform-adapters ↔ skill-versioning
- [ ] CASTLE ≥ 85 sobre los documentos
