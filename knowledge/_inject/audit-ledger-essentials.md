# Audit Ledger Essentials (para inyección)

> Versión compacta para inyección en agents. Contrato completo: `hooks/audit-hook.md`
> Referencia arquitectónica: `docs/adr/ADR-007-audit-ledger-n16-convention.md`

## Qué es el Audit Ledger

Registro inmutable de todas las operaciones de agentes King Framework. Escrito automáticamente en **Phase N+1.6** de `session-management` al cierre de cada sesión. No requiere acción explícita de los agentes.

## Schema (9 campos obligatorios)

| Campo | Tipo | Ejemplo |
|-------|------|---------|
| `schema_version` | string | `"1.0"` |
| `timestamp` | string ISO 8601 UTC | `"2026-05-08T15:30:00Z"` |
| `session_id` | string | `"WF-011-S001"` |
| `workflow_id` | string | `"WF-011"` o `"standalone"` |
| `skill` | string | `"build"` |
| `agent` | string | `"@developer"` o `"none"` |
| `action` | string | `"Edit"`, `"Write"`, `"plan"` |
| `input_sha256` | string hex-64 | `"a3f1c2d4..."` o `"none"` |
| `output_sha256` | string hex-64 | `"b7e2f3a4..."` o `"none"` |

Campo adicional `"redacted": true` si se aplicó redacción de secrets.

## Path Canónico

```
.king/audit/YYYY-MM-DD.jsonl
```

Un archivo por día UTC. Append-only. Retención: 30 días.

## Qué NO aparece en el Ledger

- Valores crudos de secrets, tokens, passwords, API keys — nunca
- Contenido completo del prompt o response (solo hashes de los primeros 4KB)
- Rutas fuera de `.king/` ni datos de usuarios externos al proyecto

## Consulta con jq (one-liners)

```bash
# Todas las entradas de hoy
cat .king/audit/$(date -u +%Y-%m-%d).jsonl | jq .

# Filtrar por agente
cat .king/audit/*.jsonl | jq 'select(.agent == "@developer")'

# Filtrar por skill
cat .king/audit/*.jsonl | jq 'select(.skill == "build")'

# Filtrar por rango de fechas (shell)
for f in .king/audit/2026-05-{01..08}.jsonl; do
  [[ -f "$f" ]] && cat "$f"
done | jq .

# Contar entradas por skill
cat .king/audit/*.jsonl | jq -s 'group_by(.skill) | map({skill: .[0].skill, count: length})'

# Ver entradas con redacción aplicada
cat .king/audit/*.jsonl | jq 'select(.redacted == true)'
```

## Verificación de Integridad

```bash
# Verificar que cada línea es JSON válido
while IFS= read -r line; do
  printf '%s' "$line" | jq empty || echo "WARN: línea inválida"
done < .king/audit/$(date -u +%Y-%m-%d).jsonl

# Verificar formato de hashes (64 chars hex)
cat .king/audit/*.jsonl | jq -r '.input_sha256,.output_sha256' | \
  grep -vE '^[a-f0-9]{64}$|^none$' && echo "WARN: hash inválido"
```

## Señales de Alerta

- `redacted: true` en muchas entradas → revisar si el agente expone secrets en sus outputs
- Hashes `"none"` repetidos → `sha256sum` o `jq` no disponibles en el entorno
- Gaps de fechas en `.king/audit/` → sesiones sin Phase N+1.6 ejecutado

## Reglas para Agentes

- **NO** escribir manualmente en `.king/audit/` — el ledger lo gestiona session-management
- **NO** eliminar ni truncar archivos JSONL — son append-only por diseño
- **SÍ** usar `/audit-ledger` para consultar entradas
- **SÍ** reportar gaps o entradas corruptas al usuario via WARN en el session document
