# Template: Desktop App

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial para construir una aplicación de escritorio multiplataforma (Windows + macOS + Linux) distribuible. El eje de esta template no es la web ni el móvil, sino el **ciclo de vida de un binario instalable que corre con los permisos del usuario en su máquina**: empaquetado por OS, firma de código y notarización, autoactualización segura y reutilización de la capa de diseño King para una UI nativa-en-sensación. `/genesis` consume esta spec para saber qué generar al elegir `--template desktop-app`.

## Stack

| Capa | Tecnología | Versión baseline | Rol |
|------|-----------|------------------|-----|
| Shell de escritorio | Tauri | 2.x | Webview nativo del SO + backend Rust; binario pequeño, superficie de ataque reducida |
| Runtime backend | Rust | 1.83 (edition 2021) | Comandos nativos, FS, IPC tipado con el frontend vía `#[tauri::command]` |
| UI (renderer) | React + Vite + TypeScript | React 18.3 / Vite 6 / TS 5.6 | Capa de presentación servida al webview; reusa skills de diseño King |
| Estilos / design system | Tailwind + componentes King | Tailwind 3.4 | Sistema de diseño consistente (ver `/frontend-design` y `ui-ux-pro-max`) |
| Estado / IPC | Zustand + Tauri IPC | latest | Estado en el renderer; mutaciones nativas vía invoke tipado |
| Autoupdate | Tauri Updater plugin | `@tauri-apps/plugin-updater` 2.x | Reemplazo de versión con verificación de firma obligatoria |
| Empaquetado | Tauri Bundler | incluido en Tauri 2 | `.msi`/`.exe` (NSIS), `.dmg`/`.app`, `.deb`/`.AppImage`/`.rpm` |
| Firma + notarización | signtool (Win) · `codesign`+`notarytool` (macOS) | nativo del SO | Confianza del SO, sin SmartScreen/Gatekeeper bloqueando el instalador |
| Tests | Vitest + WebDriver (tauri-driver) | Vitest 2.x | Unit del renderer + E2E sobre la app empaquetada |

> **Variante Electron**: `/genesis` puede generar la misma topología sobre Electron 33 + `electron-builder` 25 + `electron-updater`, con el mismo frontend React/Vite. El default es **Tauri** por la razón documentada en Decisiones de diseño; Electron queda como variante de primera clase para equipos con dependencia dura de APIs de Node en el proceso main o de un ecosistema de paquetes nativos npm ya adoptado.

## Skills King pre-configurados

Activos por defecto en `.king/config` al generar con este template:

| Skill | Plugin | Función en el template |
|-------|--------|------------------------|
| `/genesis` | king-core | Inicializa el proyecto y este template |
| `/build` | king-core | Ciclo de feature (comando nativo + UI + tests + PR) |
| `/frontend-design` | king-core | Diseño e implementación de la UI del renderer con alto impacto visual |
| `ui-ux-pro-max` | (skill) | Estilos, paletas, tipografía y componentes para la capa de presentación |
| `/release` | king-core | Release GitFlow: certificación CASTLE, tag semver, GitHub Release con artefactos firmados |
| `/promote` | king-core | Promoción develop → qa → prod del canal de distribución (stable/beta) |
| `/qa` | king-core | QA de la feature antes de empaquetar |
| `/audit` | king-core | Health score del framework instalado |
| `/castle` | king-core | Evaluación CASTLE completa, con foco en **S** (firma) y **E** (paridad de OS) |

La UI de un app de escritorio es una superficie de presentación de primera clase: por eso `/frontend-design` y `ui-ux-pro-max` se activan por defecto, a diferencia de la template CLI. La diferencia con una web es que aquí la UI vive dentro de un webview empaquetado, no servido por un servidor.

## Estructura de proyecto generada

```
mi-app-desktop/
├── src/                            # renderer (React + Vite + TS)
│   ├── features/                   # screaming architecture por feature
│   ├── core/
│   │   └── ipc/                    # wrappers tipados sobre invoke() — único punto de IPC
│   ├── ui/                         # componentes (design system King)
│   └── main.tsx
├── src-tauri/                      # backend nativo (Rust)
│   ├── src/
│   │   ├── lib.rs                  # registro de comandos + plugins (updater)
│   │   ├── commands/               # #[tauri::command] — superficie nativa expuesta
│   │   └── main.rs                 # entrypoint
│   ├── capabilities/               # permisos granulares por ventana (Tauri 2 ACL)
│   ├── icons/                      # iconos multiplataforma (.ico, .icns, png)
│   ├── tauri.conf.json             # bundle targets, updater endpoints, allowlist
│   └── Cargo.toml
├── .king/
│   ├── config                      # skills activos del template
│   ├── knowledge/stack.md          # stack resuelto (Tauri o Electron)
│   ├── coverage.yaml               # umbrales CASTLE-T
│   └── castle/                     # reportes de gates
├── e2e/                            # tests E2E sobre la app empaquetada (tauri-driver)
├── vite.config.ts
└── .github/workflows/
    ├── ci.yml                      # test + lint + CASTLE + build de prueba por PR
    └── release.yml                 # build matriz + firma + notarización + GitHub Release en tag v*
```

Separación clave: `src/core/ipc/` es el **único** puente entre el renderer y el backend Rust; ningún componente de UI llama a `invoke()` directamente. Esto mantiene la superficie nativa auditada en un solo lugar (gate CASTLE-A) y permite testear la UI mockeando el contrato IPC sin levantar el backend.

## CASTLE configuration

Layers activos por defecto, con énfasis en los gates específicos de una app de escritorio distribuida:

| Layer | Estado | Gate específico de esta template |
|---|---|---|
| **C** Contracts | Activo | Cada `#[tauri::command]` documenta sus parámetros, tipos de retorno y errores. El contrato IPC entre Rust y el renderer es tipado y versionado. |
| **A** Architecture | Activo | El renderer accede al backend SOLO vía `src/core/ipc/`; ningún componente invoca `invoke()` inline. Enforcer de puente IPC único. |
| **S** Security | Activo (reforzado) | Allowlist/capabilities mínimas por ventana (no `all: true`); CSP estricta en el webview; autoupdate exige firma verificada; **release sin firmar BLOQUEA** el publish. |
| **T** Testing | Activo | Coverage global 75%; comandos Rust con `cargo test`; E2E del flujo de arranque + una acción nativa sobre el bundle real. |
| **L** Logging | Atenuado (`warn`) | App local sin servidor central: el gate verifica logging local rotado a archivo del usuario (`app_log_dir`) y captura de panics de Rust, no logging estructurado remoto. |
| **E** Environment | Activo | La matriz de empaquetado debe producir artefacto válido en los 3 OS; verificación de paridad de comportamiento (paths, separadores, permisos de instalación). |

`.king/coverage.yaml`: `thresholds.global: 75`, `per_package: { src/core: 85 }`, `enforcement: block`. El umbral global se mantiene en 75 (no 80) porque buena parte del renderer es UI difícil de cubrir con valor real; el núcleo del contrato IPC (`src/core/ipc`) se exige a 85%.

Gate destacado: **S** bloquea cualquier release que no esté firmado y —en macOS— notarizado. Distribuir un binario sin firmar condena al usuario a las pantallas de SmartScreen (Windows) y Gatekeeper (macOS), que es donde mueren las instalaciones de apps independientes.

## CI/CD incluido

Plataforma de distribución target: **GitHub Releases** como canal de descarga directa y backend del autoupdater. No hay servidor de deploy: el "deploy" de un app de escritorio es publicar instaladores firmados que el usuario descarga, y servir el manifiesto del updater desde ese mismo Release.

**`.github/workflows/ci.yml`** (por PR): matriz `windows-latest`, `macos-latest`, `ubuntu-latest`. Pasos: typecheck + lint del renderer → `vitest run` con coverage → `cargo test` en `src-tauri` → CASTLE check (emit-check hook) → build de prueba del bundle (sin firmar) para verificar que el empaquetado no se rompió. Bloquea merge si falla cualquier OS o el gate CASTLE.

**`.github/workflows/release.yml`** (en push de tag `v*`): build de la matriz multiplataforma con `tauri build`, luego por OS:

1. **Windows** — bundle NSIS/MSI, firma con `signtool` usando el certificado de la organización (secreto de CI), timestamp del firmado.
2. **macOS** — bundle `.dmg`/`.app`, `codesign` con Developer ID + **notarización** vía `notarytool` + stapling del ticket.
3. **Linux** — bundle `.AppImage`/`.deb`/`.rpm` (firma GPG opcional del repo).
4. Genera el manifiesto del **updater** firmado con la clave privada de Tauri (clave pública embebida en `tauri.conf.json`) y lo publica junto a los artefactos.
5. Sube todos los instaladores al **GitHub Release** y genera changelog desde conventional commits.

Canales de actualización: `stable` (release) y `beta` (pre-release), mapeados a tags. La app consulta el endpoint del updater del canal configurado; `/promote` mueve una versión de `beta` a `stable`. Todas las claves de firma y notarización viven en secrets de CI, nunca en el repositorio (CASTLE-E).

## Cómo usar

```
king-framework genesis --template desktop-app-starter
```

## Decisiones de diseño

- **Tauri sobre Electron como default** — Tauri usa el **webview nativo del SO** (WebView2 en Windows, WebKit en macOS/Linux) en vez de empaquetar Chromium completo. Resultado: instaladores de pocos MB en lugar de 100+ MB, menor consumo de RAM y una superficie de ataque drásticamente menor (no se transporta un navegador entero con cada release). El backend en Rust impone un modelo de permisos explícito (capabilities por ventana) que en Electron es opt-in y suele quedar en `nodeIntegration: true`. Electron sigue siendo variante de primera clase para equipos atados a APIs de Node en el proceso main o a módulos nativos npm; no es un camino degradado.

- **Firma de código y notarización NO son opcionales** — un instalador sin firmar dispara SmartScreen en Windows y es directamente rechazado por Gatekeeper en macOS moderno. Para una app que el usuario instala con sus privilegios, la firma es el contrato de confianza con el SO, no una mejora futura. Por eso es un gate CASTLE-S que **bloquea** el release: retrofittear firma sobre un canal de distribución ya adoptado obliga a re-publicar y re-educar a los usuarios, un costo prohibitivo.

- **Autoupdate con verificación de firma obligatoria** — el updater reemplaza un binario que corre con los permisos del usuario; descargar y sobrescribir sin verificar es un vector de supply-chain directo. Tauri Updater firma el manifiesto con una clave privada y verifica con la pública embebida en el binario, de modo que ni siquiera un Release comprometido puede empujar una actualización maliciosa sin la clave. La verificación es obligatoria por diseño, alineada con el mismo principio que la template CLI.

- **React + Vite en el renderer para reusar la capa de diseño King** — el frontend del app es una superficie de presentación de primera clase, no un detalle. Elegir React + Vite + Tailwind permite que `/frontend-design` y `ui-ux-pro-max` generen y revisen la UI con los mismos patrones que un proyecto web King, maximizando el reuso de skills. La diferencia es de empaquetado (webview embebido vs. servidor), no de stack de UI: esto evita un ecosistema de diseño paralelo solo para escritorio.

- **Puente IPC único en `src/core/ipc/`** — el punto donde el renderer cruza al backend nativo es la frontera de seguridad y de tipos del app. Centralizar todo `invoke()` en una capa tipada (en vez de dispersarlo en componentes) deja la superficie nativa auditable en un solo archivo (gate CASTLE-A) y permite testear la UI mockeando ese contrato sin levantar Rust. Dispersar IPC por la UI es la causa típica de allowlists infladas y de comandos nativos olvidados sin protección.

- **GitHub Releases como canal y backend del updater** — un app de escritorio independiente no necesita infraestructura de deploy: el instalador se descarga y el updater consume el mismo manifiesto publicado en el Release. Reusar GitHub Releases cierra el loop build → firma → publish → autoupdate sin servidores adicionales, igual que el patrón validado en la template CLI, y mantiene el costo operativo de un proyecto independiente en cero.
