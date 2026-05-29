# Hook: error-recovery (M-83)

**Conversational Error Recovery** — al terminar una sesión, detecta errores
bloqueantes y ofrece al usuario **3 opciones ejecutables** para recuperarse sin
perder contexto.

## Evento

- **Tipo**: `Stop`
- **`async: false`** — **deliberado**. El template de recuperación debe aparecer
  **antes** de que la sesión cierre; si fuera asíncrono, el usuario perdería la
  ventana para actuar sobre las opciones propuestas.

Registro en `hooks.json` (lo añade el orquestador, **no** este paquete):

```jsonc
"Stop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/error-recovery/error-recovery.sh",
        "async": false
      }
    ]
  }
]
```

## Flujo

1. Lee las **últimas ~50 líneas** del output de la sesión desde **stdin** del hook `Stop`.
2. Lee las **últimas 10 líneas** de `.king/registry.md` (vía `git rev-parse` para localizar la raíz).
3. Evalúa cada uno de los 5 patrones por **keyword match** (regex ERE, case-insensitive).
4. Si hay match: carga el template, **interpola las variables** (`{files}`, `{error_message}`, etc.) y lo emite por `echo`/`printf` al **stdout** del hook.
5. Si **ningún** patrón hace match: **no-op silencioso** — el `Stop` normal del usuario no se ve afectado.

Si una variable no puede resolverse desde el output, el placeholder se deja
sin interpolar (degradación elegante) en lugar de fallar.

## Los 5 patrones

Definidos en `knowledge/universal/error-recovery-patterns.md` (fuente única de verdad):

| Patrón                     | Source           | Dispara con (regex)                                            |
| -------------------------- | ---------------- | ------------------------------------------------------------- |
| `castle-breached-security` | `registry.md`    | `CASTLE BREACHED.*layer.*S`                                   |
| `build-fail`               | `session-output` | `build failed\|compilation error\|TS[0-9]+`                  |
| `test-fail`                | `session-output` | `[0-9]+ (test\|spec)s? (failed\|failing)\|FAIL `             |
| `lint-fail`                | `session-output` | `[0-9]+ (error\|warning)s?.*lint\|eslint\|golangci`         |
| `secret-detectado`         | `session-output` | `BLOCKED: Hardcoded secret\|secret detectado\|secret pattern` |

Cada template ofrece exactamente **3 opciones** (`[1]`, `[2]`, `[3]`), cada una
con un comando King (`/fix`, `/castle`, `/qa`, `/review`) o una acción git.

## Fail-safe

- `set -euo pipefail` + `trap ... ERR`: cualquier fallo interno se degrada a
  `[WARN]` en stderr y termina con **exit 0**. **Nunca** interrumpe el pipeline
  del `Stop`.
- Sin fuentes de entrada (stdin vacío y sin `.king/registry.md`) → no-op silencioso.
- Sin match → no-op silencioso.

## Prueba manual

```bash
# Debe emitir el template build-fail:
echo "src/app.ts: build failed TS2304: cannot find name" \
  | bash hooks/error-recovery/error-recovery.sh

# Debe ser no-op silencioso (sin salida):
echo "sesión normal, todo verde" \
  | bash hooks/error-recovery/error-recovery.sh
```
