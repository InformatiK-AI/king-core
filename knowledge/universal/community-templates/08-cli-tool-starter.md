# Template: CLI Tool

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial para construir herramientas de línea de comandos distribuibles. El eje de esta template no es el negocio ni la UI web, sino el **ciclo de vida de un binario que vive en la terminal del usuario**: empaquetado, distribución por múltiples package managers, experiencia de terminal pulida, configuración persistente y autoactualización segura.

## Stack

| Capa | Tecnología | Versión | Rol |
|---|---|---|---|
| Lenguaje | Go | 1.23 | Compilación a binario estático single-file, cross-compilation nativa |
| Framework CLI | Cobra | 1.8 | Comandos, subcomandos, flags, generación de docs y completions |
| Config | Viper | 1.19 | Precedencia flags > env > archivo > defaults; formatos YAML/TOML/JSON |
| UX terminal | Lip Gloss + Bubble Tea | 0.13 / 1.x | Estilos, spinners, prompts interactivos, TUI opcional |
| Autoupdate | go-update + selfupdate | latest | Reemplazo del binario in-place con verificación de checksum |
| Empaquetado | GoReleaser | 2.x | Build multiplataforma, firma, changelog y publish a N package managers |
| Tests | testing (stdlib) + testscript | go1.23 | Tabla de casos + golden files para salida de terminal |

Plataformas objetivo de compilación por defecto: `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`, `windows/amd64`.

## Skills King pre-configurados

Activos por defecto en `.king/config`:

- `/genesis` — bootstrap del proyecto con esta template.
- `/build` — workflow de feature (comando → flags → tests → PR).
- `publish-package` — publicación coordinada a Homebrew, Scoop, APT/DEB, AUR y `go install` vía GoReleaser. **Skill central de esta template.**
- `/release` — release GitFlow: certificación CASTLE, tag semver, GitHub release con artefactos firmados.
- `/promote` — promoción develop → qa → prod del canal de distribución.
- `/audit` — health score del framework instalado.
- CASTLE con foco en **C · A · S · T · E** (Logging atenuado por la naturaleza efímera del proceso; ver sección CASTLE).

## Estructura de proyecto generada

```
mi-cli/
├── cmd/
│   ├── root.go            # comando raíz: persistent flags, init de Viper, --version
│   ├── version.go         # subcomando version (build info inyectada por ldflags)
│   ├── update.go          # subcomando autoupdate (selfupdate + verificación checksum)
│   └── config.go          # subcomando config get/set/path
├── internal/
│   ├── ui/                # estilos Lip Gloss, spinners, renderizado de salida
│   │   ├── styles.go
│   │   └── output.go      # respeta NO_COLOR, --json, isatty
│   ├── config/            # carga, precedencia y validación (Viper)
│   │   └── config.go
│   └── core/              # lógica de dominio, agnóstica de la CLI
├── main.go                # entrypoint: solo llama a cmd.Execute()
├── completions/           # bash, zsh, fish, powershell (generadas por Cobra)
├── .goreleaser.yaml       # build matrix, firma, brews, scoops, nfpms, aur
├── .king/
│   ├── config             # skills activos
│   ├── coverage.yaml      # thresholds CASTLE-T
│   └── castle/            # reportes
├── .github/workflows/
│   ├── ci.yml             # test + lint + castle por PR
│   └── release.yml        # GoReleaser en tag v*
└── README.md
```

Separación clave: `cmd/` solo orquesta (parseo de flags, wiring); `internal/core/` contiene la lógica testeable sin tocar la terminal. Esto permite testear el dominio sin simular stdin/stdout.

## CASTLE configuration

| Layer | Estado | Gate específico de esta template |
|---|---|---|
| **C** Contracts | Activo | Cada subcomando documenta sus flags, exit codes y formato de salida (`--json`). Exit codes estables forman parte del contrato público. |
| **A** Architecture | Activo | `cmd/` no puede importar lógica de negocio inline; debe delegar a `internal/core/`. Enforcer de dependencia unidireccional. |
| **S** Security | Activo | Autoupdate exige verificación de checksum SHA-256 y firma cosign del release. Sin descarga de binarios sin verificar. Config nunca persiste secretos en texto plano. |
| **T** Testing | Activo | Coverage global 75% en `internal/core/`; golden files obligatorios para salida de comandos (`testscript`). |
| **L** Logging | Atenuado (`warn`) | Un CLI es un proceso efímero: el "log" es la salida a stderr. Gate verifica separación stdout (datos) / stderr (diagnóstico) y soporte de `-v/--verbose`, no logging estructurado persistente. |
| **E** Environment | Activo | Matriz de compilación cruzada debe pasar en los 5 targets. Verificación de paridad de comportamiento entre OS (paths, line endings, color). |

`.king/coverage.yaml`: `thresholds.global: 75`, `per_package: { internal/core: 85 }`, `enforcement: block`. El umbral global se mantiene en 75 (no 80) porque `cmd/` es glue de wiring de bajo valor de test; el valor real se concentra en `internal/core` a 85%.

## CI/CD incluido

Dos workflows de GitHub Actions:

**`ci.yml`** (por PR): matriz `ubuntu-latest`, `macos-latest`, `windows-latest`. Pasos: `go test ./...` con coverage → `golangci-lint` → CASTLE check (emit-check hook). Bloquea merge si falla cualquier OS o el gate CASTLE-T.

**`release.yml`** (en push de tag `v*`): ejecuta `goreleaser release --clean`. GoReleaser:

1. Compila la matriz de 5 targets.
2. Genera checksums SHA-256 y los firma con cosign.
3. Publica artefactos en el **GitHub Release**.
4. Hace `publish-package` a los canales: **Homebrew tap**, **Scoop bucket**, paquetes **DEB** (nfpms), **AUR** y disponibilidad vía **`go install`**.
5. Genera changelog desde conventional commits.

Plataforma de distribución target: **package managers nativos del OS** (no un servidor de deploy). El "deploy" de un CLI es el publish a los registries donde el usuario hace `brew install` / `scoop install` / `apt install`. La autoactualización (`mi-cli update`) consume el mismo GitHub Release que produce este pipeline, cerrando el loop sin infraestructura adicional.

## Cómo usar

```
king-framework genesis --template cli-tool-starter
```

## Decisiones de diseño

- **Go sobre Node/Python para el binario** — un CLU se distribuye como **un único ejecutable estático sin runtime**. Go compila a un binario que el usuario corre sin instalar intérpretes ni gestionar `node_modules`/`venv`. Node y Python obligan a empaquetar el runtime (pkg, PyInstaller) inflando el artefacto y rompiendo en entornos con versiones distintas. Para una herramienta de terminal, el arranque en milisegundos y el zero-dependency install son el diferenciador de UX.

- **GoReleaser sobre scripts de build a mano** — la distribución multi-package-manager es el problema MÁS caro de un CLI, no la lógica. GoReleaser resuelve build-matrix + firma + checksums + publish a Homebrew/Scoop/AUR/DEB en una sola declaración. Escribir y mantener esos pipelines a mano es donde mueren los proyectos CLI: el `.goreleaser.yaml` es el activo central de la template, no un detalle.

- **Cobra + Viper sobre flag stdlib** — la precedencia de configuración (flag → env → archivo → default) es un requisito casi universal en CLIs serios, y Viper la implementa correctamente sin reinventarla. Cobra aporta gratis las **shell completions** y la generación de docs, que son UX de terminal esperada por usuarios avanzados. El `flag` de stdlib obliga a construir todo eso a mano.

- **Lip Gloss con degradación a texto plano** — la UX de terminal debe ser bonita en un TTY interactivo y **parseable en un pipe**. El renderizado respeta `NO_COLOR`, detecta `isatty` y ofrece `--json` para integración con scripts. Color forzado sobre stdout no-TTY rompe a quien hace `mi-cli | grep`; esto es una decisión de respeto al ecosistema Unix, no estética.

- **Autoupdate con verificación de firma, no opcional** — `mi-cli update` reemplaza un binario que el usuario ejecuta con sus permisos. Descargar y sobrescribir sin verificar checksum + firma cosign es un vector de supply-chain directo. La template hace la verificación obligatoria (gate CASTLE-S) en lugar de dejarla como mejora futura, porque el costo de retrofittear seguridad en un canal de distribución ya adoptado es prohibitivo.

- **stdout para datos, stderr para diagnóstico** — separar los streams es lo que hace componible a un CLI. Los mensajes de progreso, spinners y errores van a stderr; solo el resultado consumible va a stdout. Es la razón por la que CASTLE-L se atenúa a `warn`: el contrato de logging de un CLI no es JSON estructurado persistente, es la disciplina de streams.
