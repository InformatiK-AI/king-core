# Delta Spec — vscode-extension (M-64)

## ADDED Requirements

### Requirement: Knowledge `vscode-extension-spec.md`
`king-core` SHALL proveer `knowledge/universal/vscode-extension-spec.md` que especifique las features de la
extensión VS Code: Status Bar, Command Palette, Diff Viewer, Coverage Gutters, A11y Warnings, settings y testing.
MUST establecer que la extensión es un cliente delgado (observa `.king/`, delega a `apex-core`) y que el código TS
vive en el repo externo `king-framework/vscode-extension`.

### Requirement: Status Bar
SHALL especificar un status bar siempre visible con fase SDD, gates y coverage, leídos de `.king/sessions/` y
`.king/coverage-report.json`, con colores verde/amarillo/rojo (rojo = veto activo).

#### Scenario: status bar muestra fase SDD activa
- **Given** `.king/sessions/` con fase `sdd-build`
- **Then** el status bar muestra `⚔ King | sdd-build` en verde

#### Scenario: status bar rojo con veto
- **Given** un veto CASTLE activo en `.king/sessions/`
- **Then** el status bar muestra el estado en rojo

### Requirement: Command Palette
SHALL especificar los comandos `King: Run /genesis|/build|/qa|/promote`, `Show CASTLE Report`, `Open Session Log`,
`Doctor`, `Open Skill Reference`, invocados por shell exec al terminal integrado.

#### Scenario: command palette ejecuta skill
- **Given** el developer selecciona `King: Run /qa`
- **Then** el terminal integrado ejecuta `/qa` y el panel King muestra el progreso

### Requirement: Coverage Gutters y A11y Warnings
Coverage Gutters SHALL leer `.king/coverage-report.json` (M01) y pintar gutter verde/rojo con hover de tests.
A11y Warnings SHALL integrar axe-core mostrando el código WCAG inline con link a la regla.

#### Scenario: coverage gutters muestran cobertura
- **Given** `.king/coverage-report.json` con líneas cubiertas/no cubiertas
- **Then** el gutter pinta verde las cubiertas y rojo las no cubiertas

#### Scenario: a11y warnings en JSX
- **Given** axe-core detecta `img` sin `alt` en `Button.tsx:42`
- **Then** la línea muestra `WCAG 1.1.1` inline con link a la doc

> Set Gherkin completo: M12 §7 (Feature: VS Code Extension — 5 escenarios).
> Excluido: T49-T50 (código TS) → repo externo `king-framework/vscode-extension`.
