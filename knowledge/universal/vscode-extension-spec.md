# VS Code Extension — Spec de Features (M-64)

> **Qué es esto**: la SPEC de features de la extensión VS Code de King Framework. El CÓDIGO de la extensión
> (TypeScript) vive en el repo externo `king-framework/vscode-extension`. Este documento define QUÉ debe hacer y
> CÓMO se comunica con el backend, para guiar ese desarrollo. NO incluye código TS (T49-T50 son del repo externo).
>
> Relacionado: [`cli-architecture.md`](./cli-architecture.md) (backend `apex-core`), [`multi-platform-adapters.md`](./multi-platform-adapters.md).

## Propósito y arquitectura (T41)

Superficie visual de King para developers que no viven en la terminal. La extensión es un **cliente delgado**:
no reimplementa lógica King, sino que observa `.king/` y delega la ejecución a `apex-core` / Claude Code.

```
VS Code Extension (TS, repo externo king-framework/vscode-extension)
   ├── file watcher sobre .king/sessions/ y .king/*.json
   ├── shell exec → `king-framework <cmd>` (apex-core) o Claude Code
   └── render: status bar, command palette, diff viewer, gutters, a11y
```

Fuente de verdad de los datos: `.king/` (sessions, coverage-report.json, castle report). Backend de ejecución:
`apex-core` (ver `cli-architecture.md`). Si `apex-core` no está instalado → la extensión degrada a solo-lectura.

## Status Bar (T42)

Siempre visible, esquina inferior izquierda:

```
⚔ King | fase: sdd-build | gates: ✓ | coverage: 87%
```

- **Datos**: fase SDD y gates desde `.king/sessions/`; coverage desde `.king/coverage-report.json`.
- **Obtención**: file watcher sobre `.king/sessions/`; refresca al guardar archivo o al detectar cambio.
- **Colores**: verde (gates OK), amarillo (warnings), **rojo (veto activo)**.
- **Click**: abre el panel King.

#### Scenario: status bar muestra fase SDD activa
- **Given** `.king/sessions/` con fase `sdd-build`
- **Then** status bar muestra `⚔ King | sdd-build` en verde

#### Scenario: status bar rojo con veto
- **Given** `.king/sessions/` con un veto CASTLE activo
- **Then** status bar muestra `⚔ King | VETO activo` en rojo

## Command Palette (T43)

`Cmd/Ctrl+Shift+P → "King:"` expone:

```
King: Run /genesis
King: Run /build
King: Run /qa
King: Run /promote
King: Show CASTLE Report
King: Open Session Log
King: Doctor
King: Open Skill Reference
```

- **Invocación**: shell exec al terminal integrado (`king-framework <cmd>` o el skill en Claude Code).
- Al ejecutar, abre el panel King mostrando el progreso.

#### Scenario: command palette ejecuta skill
- **Given** el developer abre la Command Palette y selecciona `King: Run /qa`
- **Then** el terminal integrado ejecuta `/qa` y el panel King muestra el progreso

## Diff Viewer (T44)

Panel lateral:
- Muestra el diff del último `/build` con anotaciones de agente.
- Marca en rojo las líneas con veto activo.
- Botón **"Apply Fix"** para aceptar una sugerencia de CASTLE (aplica el cambio vía git).

## Coverage Gutters (T45)

- **Input**: `.king/coverage-report.json` (formato generado por el coverage gate de M01).
- Líneas cubiertas → barra verde en el gutter; no cubiertas → barra roja.
- Hover sobre la línea → muestra qué tests la cubren.

#### Scenario: coverage gutters muestran cobertura
- **Given** `.king/coverage-report.json` con datos y `src/auth/handler.go` con líneas cubiertas y no cubiertas
- **When** el developer abre el archivo
- **Then** las cubiertas muestran barra verde y las no cubiertas barra roja en el gutter

## A11y Warnings (T46)

- Integra con **axe-core** (si el proyecto tiene frontend).
- Warnings inline en JSX/HTML con el código de violación WCAG.
- Link directo a la documentación de la regla.

#### Scenario: a11y warnings en JSX
- **Given** axe-core detecta `img` sin `alt` en `Button.tsx` línea 42
- **When** el developer abre `Button.tsx`
- **Then** la línea 42 muestra el warning inline `WCAG 1.1.1: img element missing alt attribute` y el hover linkea la doc de la regla

## Configuración de la extensión (T47)

`settings.json` de VS Code, namespace `king.*`:

| Setting | Default | Propósito |
|---------|---------|-----------|
| `king.apexCorePath` | `king-framework` (PATH) | Ruta al binario `apex-core` |
| `king.statusBar.enabled` | `true` | Mostrar/ocultar el status bar |
| `king.coverageGutters.enabled` | `true` | Activar coverage gutters |
| `king.a11y.enabled` | `true` | Activar a11y warnings (axe-core) |
| `king.refreshOnSave` | `true` | Refrescar status al guardar |

## Testing (T48)

Contrato de testing (lo ejecutan los tests del repo externo):
- **VS Code Extension Testing API** (`@vscode/test-electron`).
- **Fixtures de repos**: un set de proyectos `.king/` por estado (sin sesión, con veto, con coverage-report) para
  cada feature.
- **Casos por feature**: status bar (3 estados de color), command palette (exec del skill), coverage gutters
  (mapeo de líneas), a11y (warning inline).

## Fuera de alcance in-repo (T49-T50 — repo externo)

`package.json` de la extensión, `extension.ts` (activación + registro de comandos), implementación TS del file
watcher y del render del Status Bar. Viven en `king-framework/vscode-extension`. Aquí se ESPECIFICA su contrato.

## Trazabilidad Gherkin (M12 §7 — Feature: VS Code Extension)

| Escenario | Sección |
|-----------|---------|
| Status bar muestra fase SDD activa | Status Bar |
| Status bar cambia a rojo con veto | Status Bar |
| Command palette ejecuta skill | Command Palette |
| Coverage gutters muestran cobertura | Coverage Gutters |
| A11y warnings en JSX | A11y Warnings |
