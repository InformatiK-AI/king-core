# Proposal — M-64 VS Code Extension (spec)

> Fase: sdd-propose · Change: m64-vscode-extension-spec · Backend: openspec

## Why

King solo tiene superficie de terminal. Muchos developers viven en VS Code y no obtienen feedback visual de
fase SDD, gates, coverage ni a11y sin salir al terminal. M-64 define la SPEC de una extensión VS Code (cliente
delgado que observa `.king/` y delega a `apex-core`). El código TS vive en repo externo; aquí se define el contrato.

## What Changes

Se agrega a `king-core`: `knowledge/universal/vscode-extension-spec.md` — spec de Status Bar, Command Palette,
Diff Viewer, Coverage Gutters, A11y Warnings, settings y testing.

Fuente de verdad: `mejora/planes-detallados/M12-developer-experience-tooling.md` (§2 M-64, §6 T41-T48, §7 Gherkin).

## Capabilities (contrato para sdd-spec)

| # | Capability | Item | Artefacto |
|---|------------|------|-----------|
| 1 | `vscode-extension` | M-64 | `knowledge/universal/vscode-extension-spec.md` |

## Scope

- **In scope**: la spec markdown de features (T41-T48).
- **Excluido (repo externo `king-framework/vscode-extension`)**: T49 (`package.json`/`extension.ts`) y T50
  (implementación TS del Status Bar). Código TS NO va en un plugin markdown.

## Verification

`sdd-verify` valida cobertura del Gherkin §7 (5 escenarios) en el documento + cross-refs a `cli-architecture.md`.
Gate CASTLE ≥ 85, pytest estructural verde.
