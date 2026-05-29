# Design — M-64 VS Code Extension (spec)

> Fase: sdd-design · Fuente de verdad: `mejora/planes-detallados/M12-developer-experience-tooling.md` §2 M-64, §6 T41-T48, §7.

## Decisión arquitectónica

La spec describe una extensión que es **cliente delgado**: observa `.king/` (file watcher) y delega ejecución a
`apex-core` / Claude Code. No reimplementa lógica King. El código TS vive en el repo externo
`king-framework/vscode-extension`; in-repo se entrega SOLO la spec markdown.

## Exclusión explícita T49-T50

T49 (`package.json`/`extension.ts`) y T50 (Status Bar TS) son **código TypeScript** — no van en un plugin markdown.
Se excluyen de este cambio y se documentan como artefactos del repo externo. (Decisión confirmada en el plan.)

## Anatomía del knowledge doc
Encabezado con propósito + nota "spec de features, código en repo externo" → secciones por feature (Status Bar,
Command Palette, Diff Viewer, Coverage Gutters, A11y, Settings, Testing) → cada feature con su escenario Gherkin →
tabla de trazabilidad. Cross-ref a `cli-architecture.md` (backend `apex-core`).

## Mapeo tareas → sección
T41 propósito/arquitectura; T42 Status Bar; T43 Command Palette; T44 Diff Viewer; T45 Coverage Gutters;
T46 A11y; T47 Settings; T48 Testing. T49-T50 excluidas (repo externo).

## Decisiones específicas
1. **Degradación si falta `apex-core`**: la extensión cae a solo-lectura (observa `.king/`, no ejecuta).
2. **Coverage Gutters consume el formato de M01** (`.king/coverage-report.json`) — dependencia de datos, no de código.
3. **Settings namespace `king.*`** con defaults seguros (todo activable/desactivable).
