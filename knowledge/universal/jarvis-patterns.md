# Jarvis Patterns — Contextual Intelligence (M-81)

Catálogo de los **13 patrones** que el hook `contextual-observer.sh`
(PostToolUse `Write|Edit`) evalúa sobre cada archivo modificado.

El observer **NO emite al usuario inmediatamente**: appendea cada finding a
`.king/jarvis/observations.jsonl` (NDJSON, `consumed: false`) y el hook
`UserPromptSubmit` los emite —diferidos— al inicio del siguiente prompt.

## Schema de cada patrón

```yaml
- id: <slug-kebab-case>            # identificador único del patrón
  layer: <C|A|S|T|L|E>            # capa CASTLE a la que pertenece
  detector:
    type: regex                    # regex | size-count | file-diff | size-delta
    engine: ripgrep                # ripgrep | bash wc | bash glob | bash stat
    file_glob: "**/*.{ts,js}"     # extensiones donde aplica el patrón
    pattern: '<regex>'             # patrón positivo (lo que dispara)
    negative_lookahead: '<regex>'  # si matchea en el contexto, NO dispara (anti-FP)
  severity: <info|warning|error>   # gravedad del finding
  suggestion: "texto con {file}"   # mensaje generado por el script (NUNCA del archivo)
  skill_to_invoke: "/comando"      # skill King sugerido para remediar
  auto_fix: <true|false>           # si el patrón admite corrección automática
  false_positive_hint: "..."       # cuándo ignorar (documentación anti-FP)
```

## Reglas anti falsos positivos (R1, FPR < 15%)

- Cada patrón documenta `false_positive_hint`.
- Los patrones de **layer S (Security)** usan `negative_lookahead` y se ejecutan
  con contexto extendido (`rg -A 2 -B 2`) antes de emitir.
- Los detectores excluyen tests, mocks, fixtures, build y `node_modules`
  (filtrado en el script, no en el regex).
- El campo `{file}` se sustituye por el path; **el contenido del archivo nunca
  se interpola** en la `suggestion` (R5 — anti prompt-injection).
- Criterio de aceptación por patrón: máximo 3 falsos positivos sobre 25 casos
  sintéticos (FPR < 15%), o el patrón bloquea su merge.

---

## Patrones — Layer S (Security)

```yaml
- id: endpoint-sin-auth
  layer: S
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py}"
    pattern: '(app|router)\.(get|post|put|delete|patch)\s*\(\s*[''"`/]'
    negative_lookahead: 'requireAuth|@UseGuards|authMiddleware|@Auth|isAuthenticated|passport\.|ensureAuth|middleware'
  severity: warning
  suggestion: "Veo que {file} tiene un endpoint sin middleware de auth evidente."
  skill_to_invoke: "/castle --layer S"
  auto_fix: false
  false_positive_hint: "Ignorar si el archivo es de rutas públicas documentadas (health, /login, /webhooks firmados) o si el auth se aplica globalmente en un router padre."
```

```yaml
- id: secret-en-codigo
  layer: S
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py,java,rb,php,yaml,yml,json,env,sh}"
    pattern: 'sk-ant-api[0-9A-Za-z_-]{20,}|ghp_[0-9A-Za-z]{36}|ghs_[0-9A-Za-z]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9A-Za-z]{24}|xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[a-zA-Z0-9]{24,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
    negative_lookahead: 'process\.env|os\.environ|System\.getenv|EXAMPLE|PLACEHOLDER|<your-|xxxx|REDACTED|\.example'
  severity: error
  suggestion: "Detecté lo que parece un secreto hardcodeado en {file}. Mové la credencial a una variable de entorno."
  skill_to_invoke: "/castle --layer S"
  auto_fix: false
  false_positive_hint: "Ignorar en archivos *.example / fixtures de test que usan tokens falsos, o si el valor es un placeholder documentado (EXAMPLE, <your-token>)."
```

```yaml
- id: password-plano
  layer: S
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py,java,rb,php}"
    pattern: '(password|passwd|pwd|secret|api[_-]?key)\s*[:=]\s*[''"`][^''"`$\{][^''"`]{3,}[''"`]'
    negative_lookahead: 'process\.env|os\.environ|getenv|config\.|\$\{|EXAMPLE|placeholder|\*{3,}|password\s*[:=]\s*[''"`][''"`]'
  severity: error
  suggestion: "Veo una posible contraseña/secreto en texto plano en {file}. Usá variables de entorno o un secret manager."
  skill_to_invoke: "/castle --layer S"
  auto_fix: false
  false_positive_hint: "Ignorar si el valor proviene de env/config, si es string vacío, o si es un nombre de campo/columna (no un valor literal)."
```

---

## Patrones — Layer A (Architecture)

```yaml
- id: query-n-plus-1
  layer: A
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py,java,rb}"
    pattern: '\b(for|forEach|map|while)\b[^;{]*\{[^}]*\b(find|findOne|query|select|get|fetch|load|save|exec)\b\s*\('
    negative_lookahead: 'include:|preload|join|\.in\(|where.*IN|batch|Promise\.all|eager'
  severity: warning
  suggestion: "Veo un posible patrón N+1 en {file}: una query dentro de un loop. Considerá eager-loading o batch."
  skill_to_invoke: "/optimize"
  auto_fix: false
  false_positive_hint: "Ignorar si la query usa include/join/batch, si itera sobre un set acotado en memoria, o si está dentro de Promise.all."
```

```yaml
- id: funcion-mayor-500-loc
  layer: A
  detector:
    type: size-count
    engine: bash wc
    file_glob: "**/*.{ts,js,go,py,java,rb,php}"
    pattern: 'wc -l del archivo > 500'
    negative_lookahead: ''
  severity: warning
  suggestion: "El archivo {file} supera las 500 líneas. Considerá dividirlo en módulos más pequeños y cohesivos."
  skill_to_invoke: "/refactor"
  auto_fix: false
  false_positive_hint: "Ignorar en archivos generados (*.gen.*, *_pb.*), bundles, lockfiles, o data/fixtures grandes que no son lógica."
```

```yaml
- id: dependency-no-pinneada
  layer: A
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/{package.json,requirements.txt,go.mod,Gemfile,pyproject.toml}"
    pattern: '[''"][\^~>]|[''"]\*[''"]|>=|latest'
    negative_lookahead: 'engines|"node":|workspace:|file:|link:'
  severity: warning
  suggestion: "Detecté una dependencia sin versión fija (rango o latest) en {file}. Pinneá la versión para builds reproducibles."
  skill_to_invoke: "/castle --layer A"
  auto_fix: false
  false_positive_hint: "Ignorar en el campo engines, en dependencias workspace/file/link, o si el proyecto usa un lockfile que ya fija versiones transitivas."
```

```yaml
- id: hardcoded-url
  layer: A
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py,java,rb,php}"
    pattern: 'https?://(?!localhost|127\.0\.0\.1|0\.0\.0\.0|example\.|schemas?\.|www\.w3\.org)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    negative_lookahead: '//|/\*|\*|process\.env|os\.environ|getenv|config\.|baseUrl|@see|@link|test|spec|mock'
  severity: info
  suggestion: "Veo una URL hardcodeada en {file}. Considerá moverla a configuración o variables de entorno."
  skill_to_invoke: "/castle --layer E"
  auto_fix: false
  false_positive_hint: "Ignorar URLs en comentarios/docstrings, namespaces XML/JSON-schema, localhost, dominios example.* o referencias @see/@link."
```

```yaml
- id: missing-error-boundary
  layer: A
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{tsx,jsx}"
    pattern: 'export\s+(default\s+)?(function|const)\s+[A-Z][A-Za-z0-9]*'
    negative_lookahead: 'ErrorBoundary|componentDidCatch|getDerivedStateFromError|react-error-boundary|withErrorBoundary|Suspense'
  severity: info
  suggestion: "El componente en {file} no parece estar protegido por un Error Boundary. Considerá envolverlo para fallos en runtime."
  skill_to_invoke: "/frontend-design"
  auto_fix: false
  false_positive_hint: "Ignorar componentes presentacionales puros, hooks, o si el árbol ya está envuelto por un ErrorBoundary en un layout superior."
```

---

## Patrones — Layer L (Logging)

```yaml
- id: console-log-prod
  layer: L
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,tsx,jsx}"
    pattern: 'console\.(log|debug|info|warn|error)\s*\('
    negative_lookahead: '//|/\*|\*|eslint-disable|logger\.|test|spec|\.stories\.'
  severity: warning
  suggestion: "Veo un console.* en {file}. En producción usá un logger estructurado en lugar de console."
  skill_to_invoke: "/castle --layer L"
  auto_fix: true
  false_positive_hint: "Ignorar en archivos de test/stories, scripts de CLI/dev-tooling, o si la línea tiene un eslint-disable explícito."
```

```yaml
- id: try-catch-vacio
  layer: L
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py,java}"
    pattern: 'catch\s*(\([^)]*\))?\s*\{\s*\}|except[^:]*:\s*pass'
    negative_lookahead: '//\s*(ignor|expected|noop|intentional)|#\s*(ignor|expected|noop|intentional)'
  severity: warning
  suggestion: "Detecté un try/catch vacío en {file}: estás silenciando un error. Logueá o re-lanzá la excepción."
  skill_to_invoke: "/castle --layer L"
  auto_fix: false
  false_positive_hint: "Ignorar si hay un comentario que documenta la omisión intencional (// expected / # noop) o si es un cleanup best-effort."
```

---

## Patrones — Layer T (Testing)

```yaml
- id: pr-sin-tests
  layer: T
  detector:
    type: file-diff
    engine: bash glob
    file_glob: "**/*.{ts,js,go,py,java,rb}"
    pattern: 'archivo de código modificado sin contraparte *.test.* / *.spec.* / *_test.* / test_*.py'
    negative_lookahead: ''
  severity: warning
  suggestion: "Modificaste lógica en {file} pero no veo un test asociado. Considerá agregar o actualizar pruebas."
  skill_to_invoke: "/qa"
  auto_fix: false
  false_positive_hint: "Ignorar en cambios de config, docs, tipos puros, archivos generados, o si el test vive en una ubicación no convencional ya cubierta."
```

---

## Patrones — Layer E (Environment)

```yaml
- id: bundle-size-up
  layer: E
  detector:
    type: size-delta
    engine: bash stat
    file_glob: "**/{dist,build,.next,out}/**/*.{js,css}"
    pattern: 'tamaño del bundle crece > 10% respecto al baseline en .king/jarvis/bundle-baseline'
    negative_lookahead: ''
  severity: info
  suggestion: "El bundle {file} creció respecto al baseline. Revisá si entró una dependencia pesada o código sin tree-shaking."
  skill_to_invoke: "/optimize"
  auto_fix: false
  false_positive_hint: "Ignorar si no existe baseline previo (primer build), si el crecimiento es esperado por una feature nueva, o en builds de desarrollo sin minificar."
```

```yaml
- id: env-var-sin-default
  layer: E
  detector:
    type: regex
    engine: ripgrep
    file_glob: "**/*.{ts,js,go,py,java,rb}"
    pattern: 'process\.env\.[A-Z_][A-Z0-9_]+|os\.environ\[[''"][A-Z_][A-Z0-9_]+[''"]\]|os\.getenv\(\s*[''"][A-Z_][A-Z0-9_]+[''"]\s*\)'
    negative_lookahead: '\|\||\?\?|,\s*[''"]|default|getenv\([^)]+,|os\.environ\.get\([^)]+,|process\.env\.[A-Z_]+\s*\|\|'
  severity: info
  suggestion: "La variable de entorno usada en {file} no tiene valor por defecto ni validación. Definí un fallback o validá su presencia al arrancar."
  skill_to_invoke: "/castle --layer E"
  auto_fix: false
  false_positive_hint: "Ignorar si la variable se valida/normaliza en un módulo central de config, o si su ausencia debe fallar el arranque de forma intencional."
```

---

## Resumen — Tabla de los 13 patrones

| # | ID | Layer | Tipo detector | Engine | Severity | auto_fix |
|---|----|-------|---------------|--------|----------|----------|
| 1 | `endpoint-sin-auth` | S | regex | ripgrep | warning | no |
| 2 | `secret-en-codigo` | S | regex | ripgrep | error | no |
| 3 | `password-plano` | S | regex | ripgrep | error | no |
| 4 | `query-n-plus-1` | A | regex | ripgrep | warning | no |
| 5 | `funcion-mayor-500-loc` | A | size-count | bash wc | warning | no |
| 6 | `dependency-no-pinneada` | A | regex | ripgrep | warning | no |
| 7 | `hardcoded-url` | A | regex | ripgrep | info | no |
| 8 | `missing-error-boundary` | A | regex | ripgrep | info | no |
| 9 | `console-log-prod` | L | regex | ripgrep | warning | sí |
| 10 | `try-catch-vacio` | L | regex | ripgrep | warning | no |
| 11 | `pr-sin-tests` | T | file-diff | bash glob | warning | no |
| 12 | `bundle-size-up` | E | size-delta | bash stat | info | no |
| 13 | `env-var-sin-default` | E | regex | ripgrep | info | no |

Total: **13 patrones** — S:3, A:5, L:2, T:1, E:2.
