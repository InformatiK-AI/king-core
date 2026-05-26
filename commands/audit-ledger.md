---
name: audit-ledger
description: "Consultar y exportar el audit trail inmutable de operaciones de agentes King. Filtra por rango de fechas, agente y skill. Exporta a JSON o CSV."
argument-hint: "[--from YYYY-MM-DD] [--to YYYY-MM-DD] [--agent @nombre] [--skill nombre] [--format table|json|csv]"
allowed-tools: [Read, Grep, Glob, Bash]
---
# /audit-ledger

Consulta el audit trail inmutable de King Framework almacenado en `.king/audit/`.

> **Nota**: Este command lee el ledger de audit de operaciones de agentes.
> Para auditar la salud del framework (agentes, skills, hooks), usar `/audit`.
> Contrato completo del ledger: `hooks/audit-hook.md`

## Uso

```
/audit-ledger [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--agent @nombre] [--skill nombre] [--format table|json|csv]
```

## Opciones

| Opción | Descripción | Default |
|--------|-------------|---------|
| `--from YYYY-MM-DD` | Fecha de inicio del rango (inclusive) | Hoy |
| `--to YYYY-MM-DD` | Fecha de fin del rango (inclusive) | Hoy |
| `--agent @nombre` | Filtrar por agente específico (ej: `@developer`) | Todos |
| `--skill nombre` | Filtrar por skill específico (ej: `build`, `review`) | Todos |
| `--format table\|json\|csv` | Formato de output | `table` |

## Proceso de Ejecución

### 1. Validar parámetros

```bash
# Validar formato de fechas (ISO-8601 YYYY-MM-DD)
if [[ -n "$FROM" ]] && ! [[ "$FROM" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "ERROR: --from '$FROM' no es una fecha válida (formato esperado: YYYY-MM-DD)" >&2
  exit 1
fi
if [[ -n "$TO" ]] && ! [[ "$TO" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "ERROR: --to '$TO' no es una fecha válida (formato esperado: YYYY-MM-DD)" >&2
  exit 1
fi
```

### 2. Leer archivos del rango

```bash
AUDIT_DIR=".king/audit"
RESULTS=()

# Iterar sobre archivos JSONL en el directorio
for f in "$AUDIT_DIR"/*.jsonl; do
  [[ -f "$f" ]] || continue
  DATE=$(basename "$f" .jsonl)

  # Verificar que la fecha cae dentro del rango
  [[ -n "$FROM" && "$DATE" < "$FROM" ]] && continue
  [[ -n "$TO"   && "$DATE" > "$TO"   ]] && continue

  RESULTS+=("$f")
done

if [[ ${#RESULTS[@]} -eq 0 ]]; then
  echo "No hay entradas de audit en el rango especificado."
  exit 0
fi
```

### 3. Filtrar y exportar

```bash
# Concatenar y filtrar con jq
jq -c \
  --arg agent "${AGENT:-}" \
  --arg skill "${SKILL:-}" \
  'select(
    ($agent == "" or .agent == $agent) and
    ($skill == "" or .skill == $skill)
  )' "${RESULTS[@]}" | {
    case "$FORMAT" in
      json)
        jq -s '.'
        ;;
      csv)
        echo "schema_version,timestamp,session_id,workflow_id,skill,agent,action,input_sha256,output_sha256"
        jq -r '[.schema_version,.timestamp,.session_id,.workflow_id,.skill,.agent,.action,.input_sha256,.output_sha256] | @csv'
        ;;
      table|*)
        jq -r '"\(.timestamp | .[0:19])  \(.session_id | .[0:12])  \(.skill | .[0:10])  \(.agent | .[0:12])  \(.action | .[0:10])"'
        ;;
    esac
  }
```

## Manejo de Edge Cases

| Caso | Comportamiento |
|------|---------------|
| Rango sin resultados | Mensaje informativo, exit 0 |
| `--agent` no encontrado en el rango | 0 resultados, mensaje informativo, exit 0 |
| Fecha inválida en `--from`/`--to` | Error descriptivo, exit 1 |
| Línea JSONL corrupta | Skipear línea + WARN en output, continuar |
| `.king/audit/` no existe | Mensaje: "No hay entradas de audit. Ejecutar al menos un skill primero." |
| Archivo JSONL vacío | Ignorar silenciosamente |

## Ejemplos

```bash
# Ver entradas de hoy
/audit-ledger

# Ver últimos 7 días
/audit-ledger --from 2026-05-01 --to 2026-05-08

# Ver solo operaciones de @developer
/audit-ledger --from 2026-05-01 --agent @developer

# Exportar en JSON para análisis externo
/audit-ledger --from 2026-05-01 --to 2026-05-08 --format json

# Exportar en CSV
/audit-ledger --from 2026-05-01 --to 2026-05-08 --format csv

# Filtrar por skill específico
/audit-ledger --skill build --from 2026-05-01
```

## Output de Ejemplo (format: table)

```
TIMESTAMP            SESSION       SKILL       AGENT         ACTION
2026-05-08T15:30:00  WF-011-S001   build       @developer    Edit
2026-05-08T16:00:00  WF-011-S002   review      @qa           Read
2026-05-08T16:30:00  WF-011-S003   qa          @qa           Bash
```

## Relacionado

- `hooks/audit-hook.md` — Contrato y schema completo del audit ledger
- `knowledge/_inject/audit-ledger-essentials.md` — One-liners jq para consultas directas
- `/audit` — Auditoria de salud del King Framework (distinto de este command)
