# Contextual Observer — Jarvis Mode (M-81)

Hook `PostToolUse Write|Edit` que observa cada archivo recién escrito, corre los
**13 patrones** de detección contextual y deja sus hallazgos en una cola para que
King te los comente —diferidos— en tu siguiente prompt.

> No es un linter ni un gate. **No bloquea ni te interrumpe.** Es la
> "inteligencia ambiental" de Jarvis: nota cosas mientras trabajás y te las
> menciona cuando hagas una pausa, no en medio del flujo.

---

## Componentes

| Archivo | Rol |
|---------|-----|
| `contextual-observer.sh` | Script del hook (este directorio) |
| `../../knowledge/universal/jarvis-patterns.md` | Catálogo de los 13 patrones (fuente de verdad del diseño) |
| `.king/jarvis/observations.jsonl` | Cola NDJSON de findings (`consumed:false`) — generada en runtime |
| `.king/jarvis/perf.log` | Log de timing y WARNs fail-safe — generado en runtime |
| `.king/jarvis/bundle-baseline` | Baseline de tamaño de bundles para `bundle-size-up` — generado en runtime |

---

## Flujo

```
                 Write|Edit del usuario
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │ PostToolUse (async: true, no bloquea)│
        │        contextual-observer.sh        │
        └─────────────────────────────────────┘
                          │
       1. Lee file_path desde stdin (JSON del hook)
       2. Early-exit (node_modules/.git/vendor, >5MB)
       3. Filtra patrones por extensión (file_glob)
       4. Ejecuta detectores (ripgrep / wc / find / stat)
       5. Append de findings → .king/jarvis/observations.jsonl
                          │
                          ▼
          (NO emite nada al usuario — deferred)
                          │
              … el usuario sigue trabajando …
                          │
                  Siguiente prompt
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │ UserPromptSubmit                     │
        │ lee observations.jsonl (consumed:    │
        │ false), emite ≤3 findings al inicio  │
        │ del contexto y marca consumed:true   │
        └─────────────────────────────────────┘
```

### 1. Entrada (stdin)

El hook recibe el JSON de `PostToolUse`. El script extrae el path probando, en
orden: `.path`, `.file_path`, `.tool_input.file_path` (cubre tanto `Write` como
`Edit`). Si no hay path o el archivo no existe → `exit 0`.

### 2. Early-exit (mitigación R2 — latencia)

Salta de inmediato (sin tocar disco) si el archivo está en `node_modules/`,
`.git/`, `vendor/`, `.venv/`, `__pycache__/`, o pesa más de 5 MB. Los directorios
de build (`dist/`, `build/`, `.next/`, `out/`) **no** se excluyen del todo: son
la entrada del patrón `bundle-size-up` (layer E).

### 3. Filtrado por `file_glob`

Cada patrón declara su `file_glob`. El script filtra por extensión (`case` sobre
`$EXT`) y por nombre de archivo para manifiestos (`package.json`, `go.mod`, etc.).
Los archivos de test/mock/fixture/generados (`IS_TEST=1`) se excluyen de todos los
patrones salvo los de seguridad cuando corresponde.

### 4. Detectores

| Tipo | Motor | Cómo |
|------|-------|------|
| `regex` (layer S) | ripgrep `-A2 -B2` | match + `negative_lookahead` sobre la ventana de contexto |
| `regex` (otras layers) | ripgrep | match + `negative_lookahead` |
| `size-count` | `wc -l` | `funcion-mayor-500-loc`: archivo > 500 líneas |
| `file-diff` | `find` glob | `pr-sin-tests`: busca contraparte `*.test.* / *.spec.* / *_test.* / test_*.py` |
| `size-delta` | `wc -c` + baseline | `bundle-size-up`: crecimiento > 10% vs `bundle-baseline` |

**Fallback de motor**: si `ripgrep` (`rg`) no está en el PATH, el script cae a
`grep -E` automáticamente (dependencia *soft*). El comportamiento es equivalente;
ripgrep solo aporta velocidad en archivos grandes.

### 5. Salida — `observations.jsonl` (NDJSON, append-only)

Una línea JSON por finding:

```json
{"ts":"2026-05-28T10:15:00Z","pattern_id":"endpoint-sin-auth","file":"src/api/users.ts","severity":"warning","suggestion":"Veo que src/api/users.ts tiene un endpoint sin middleware de auth evidente.","skill":"/castle --layer S","consumed":false}
```

Append-only NDJSON → seguro para escrituras concurrentes (mitigación R3: el
observer **nunca** toca `project-state.json`, solo este archivo).

---

## Deferred emit (vía `UserPromptSubmit`)

El observer **no le habla al usuario**. Escribe los findings con `consumed:false`
y termina. El hook `UserPromptSubmit` (ya presente en `hooks.json`) es quien:

1. Lee `observations.jsonl`.
2. Filtra los `consumed:false`.
3. Prepende **como máximo 3** findings al inicio del contexto del siguiente prompt.
4. Marca esos findings como `consumed:true`.

Por qué diferido y no inmediato:

- **No interrumpe** el flujo de escritura (`async:true` + cola).
- **Reduce el costo de un falso positivo** (R1): si el aviso no aplica, lo ignorás
  sin perder el contexto de lo que estabas haciendo.
- **Agrupa** hallazgos de varias escrituras en un solo aviso ordenado.

> El marcado `consumed:true` y la emisión los implementa el hook
> `UserPromptSubmit`. Este observer solo produce la cola.

---

## Falsos positivos (R1 — FPR < 15%)

Los 13 patrones son heurísticas de texto, no análisis AST. Para mantener la señal
alta sin ruido:

- Cada patrón documenta un `false_positive_hint` en `jarvis-patterns.md`.
- Los patrones de **layer S** usan `negative_lookahead` y contexto `-A2 -B2`.
- Tests/mocks/fixtures/generados quedan fuera del alcance.
- **Criterio de aceptación** (suite §4 del plan): 25 *true positives* + 25 *false
  positives* por patrón. Si el FPR supera el 15 % (más de 3 FP sobre 25), el
  patrón **no se mergea** hasta afinar su regex/lookahead.

La emisión diferida es la última red de seguridad: un FP que llegue al prompt no
bloquea nada y se descarta con un vistazo.

---

## Fail-safe y robustez

El script corre con `set -euo pipefail` y un `trap … ERR` que garantiza:

- **Nunca interrumpe el pipeline**: cualquier error interno se loguea como `WARN`
  en `perf.log` y el script termina con `exit 0`. Un fallo del observer no rompe
  tu `Write`/`Edit`.
- **Anti prompt-injection (R5)**: la `suggestion` la genera el script a partir de
  plantillas fijas; **nunca** se interpola contenido del archivo analizado. Las
  comillas del path se sanitizan antes de escribir el NDJSON.
- **Atomicidad (R3)**: solo appendea a `observations.jsonl` (append-only). No toca
  `project-state.json`.

---

## Performance (R2 / T4)

Cada ejecución registra su duración en `perf.log`:

```
[2026-05-28T10:15:00Z] perf contextual-observer: 42ms — src/api/users.ts
```

- Hook `async:true` → no bloquea la escritura.
- Early-exit en < 10 ms cuando no hay match o el archivo está excluido.
- Objetivo: **p95 < 200 ms** en archivos de hasta 1000 líneas.

---

## Registro en `hooks.json`

El observer se registra como `PostToolUse` con matcher `Write|Edit` y `async:true`.
**Este archivo no edita `hooks.json`** — lo hace el orquestador. Fragmento esperado:

```jsonc
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/contextual-observer/contextual-observer.sh",
        "async": true
      }
    ]
  }
]
```

Coexiste sin conflicto con el `PreToolUse Write|Edit` (security gate): el gate
corre **antes** (Pre) y el observer **después** (Post) de cada escritura.

---

## `.gitignore`

Los artefactos de runtime no se versionan:

```
.king/jarvis/observations.jsonl
.king/jarvis/perf.log
.king/jarvis/bundle-baseline
```
