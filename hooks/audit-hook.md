# Audit Hook — AI Audit Ledger

> Mecanismo de trazabilidad inmutable de King Framework para registrar todas las operaciones de agentes.
> Implementado como Paso N+1.6 en `session-management/SKILL.md`, ejecutado después del commit de tracking (N+1.4).
> **Nota**: No es un hook nativo de Claude Code. Es una convención del dominio King, escrita por `session-management` al cierre de cada sesión.

Ver también: **ADR-007** en `docs/adr/ADR-007-audit-ledger-n16-convention.md`.

---

## Mecanismo

El Audit Ledger se escribe en **Phase N+1, Paso N+1.6** de `session-management`, después del commit de tracking (N+1.4). En ese punto el pipeline tiene acceso completo a:

- El skill recién completado y el agente que actuó
- El workflow y session IDs activos
- Los hashes SHA-256 del input y output de la sesión
- El resultado CASTLE

El paso es **fail-safe**: si cualquier parte falla, se agrega un `WARN` al session document y la ejecución continúa sin bloquear el skill.

---

## Schema del Audit Entry

Cada entrada es una línea JSON válida (`application/x-ndjson`). Los 9 campos son obligatorios:

```json
{
  "schema_version": "1.0",
  "timestamp": "2026-05-08T15:30:00Z",
  "session_id": "WF-011-S001",
  "workflow_id": "WF-011",
  "skill": "build",
  "agent": "@developer",
  "action": "Edit",
  "input_sha256": "a3f1c2d4e5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2",
  "output_sha256": "b7e2f3a4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2"
}
```

### Definición de campos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `schema_version` | string | Versión del schema — siempre `"1.0"` |
| `timestamp` | string | ISO 8601 UTC al momento de la escritura |
| `session_id` | string | ID de sesión del workflow activo (`WF-NNN-SNNN`) |
| `workflow_id` | string | ID del workflow activo (`WF-NNN`); `"standalone"` si no hay workflow |
| `skill` | string | Nombre del skill que completó la sesión (ej: `build`, `review`) |
| `agent` | string | Agente principal de la sesión (ej: `@developer`); `"none"` si no aplica |
| `action` | string | Acción principal realizada (ej: `Edit`, `Write`, `Bash`, `plan`, `review`) |
| `input_sha256` | string | SHA-256 hex de los primeros 4KB del prompt de entrada; `"none"` si no disponible |
| `output_sha256` | string | SHA-256 hex de los primeros 4KB del output de la sesión; `"none"` si no disponible |

### Campo `redacted` (opcional)

Si se aplica redacción de secrets, la entrada incluye el campo adicional:

```json
{
  "schema_version": "1.0",
  "timestamp": "2026-05-08T15:30:00Z",
  "session_id": "WF-011-S001",
  "workflow_id": "WF-011",
  "skill": "build",
  "agent": "@developer",
  "action": "Edit",
  "input_sha256": "none",
  "output_sha256": "none",
  "redacted": true
}
```

---

## Redacción de Secrets (Two-Layer)

Antes de calcular los hashes o incluir cualquier dato textual en la entrada de audit, aplicar las dos capas de redacción en orden:

### Layer 1 — Nombre de campo sensible

Si el nombre de un campo del payload contiene cualquiera de estos términos (case-insensitive):

```
password | token | key | secret | apikey | api_key | credential | auth | bearer
```

→ **Omitir el campo completamente** del payload antes de serializar. Agregar `"redacted": true` a la entrada.

### Layer 2 — Valor con patrón de secret conocido

Si el valor textual del input o output (primeros 4KB) contiene cualquiera de estos patrones:

```regex
sk-ant-api[0-9A-Za-z_-]{10,}
ghp_[0-9A-Za-z]{20,}
AKIA[0-9A-Z]{16}
BEGIN\s+(RSA |EC |OPENSSH )?PRIVATE KEY
sk_live_[A-Za-z0-9]{20,}
sk_test_[A-Za-z0-9]{20,}
Bearer\s+[A-Za-z0-9\-._~+/]+=*
```

→ **No calcular hash del texto**. Usar `"none"` para `input_sha256` y/o `output_sha256`. Agregar `"redacted": true` a la entrada.

### Regla de oro

**NUNCA** almacenar valores crudos de secrets, tokens, passwords ni claves en el archivo JSONL — ni truncados ni parcialmente. Solo hashes o `"none"`.

---

## Path Canónico

```
.king/audit/YYYY-MM-DD.jsonl
```

- Un archivo por día calendario (UTC)
- Append-only: siempre usar `>>` (nunca `>` ni operaciones de reescritura)
- Si el directorio `.king/audit/` no existe: crearlo con `mkdir -p` antes de escribir
- Formato del nombre: `YYYY-MM-DD.jsonl` donde la fecha es UTC del momento de escritura

---

## Algoritmo de Escritura (Paso N+1.6)

```
1. mkdir -p .king/audit/
2. DATE ← date -u +"%Y-%m-%d"
3. TIMESTAMP ← date -u +"%Y-%m-%dT%H:%M:%SZ"
4. FILE ← .king/audit/${DATE}.jsonl

5. Aplicar redacción two-layer al input y output de la sesión
6. Si hay secrets detectados → set INPUT_HASH="none", OUTPUT_HASH="none", REDACTED=true
7. Si NO hay secrets:
   INPUT_HASH=$(printf '%s' "${INPUT:0:4096}"  | sha256sum); INPUT_HASH="${INPUT_HASH%% *}"
   OUTPUT_HASH=$(printf '%s' "${OUTPUT:0:4096}" | sha256sum); OUTPUT_HASH="${OUTPUT_HASH%% *}"
   (fallback con openssl: INPUT_HASH=$(printf '%s' "${INPUT:0:4096}" | openssl dgst -sha256); INPUT_HASH="${INPUT_HASH##* }")

8. ENTRY ← jq -cn \
     --arg sv  "1.0" \
     --arg ts  "$TIMESTAMP" \
     --arg sid "$SESSION_ID" \
     --arg wid "$WORKFLOW_ID" \
     --arg sk  "$SKILL" \
     --arg ag  "$AGENT" \
     --arg ac  "$ACTION" \
     --arg ih  "$INPUT_HASH" \
     --arg oh  "$OUTPUT_HASH" \
     '{schema_version:$sv,timestamp:$ts,session_id:$sid,workflow_id:$wid,
       skill:$sk,agent:$ag,action:$ac,input_sha256:$ih,output_sha256:$oh}'

9. Si REDACTED=true → ENTRY ← ENTRY | . + {redacted: true}

10. printf '%s\n' "$ENTRY" >> "$FILE"   ← append atómico

11. Si cualquier paso falla → loguear WARN en session document, continuar (exit 0)
```

> **Nota Windows (Git Bash)**: `sha256sum` está disponible en Git Bash via GNU coreutils. En PowerShell puro, usar `Get-FileHash` o `openssl`. El framework asume Git Bash como shell de ejecución de hooks.

---

## Política de Rotación y Retención

| Parámetro | Valor default |
|-----------|---------------|
| Rotación | Diaria (un archivo por día UTC) |
| Retención | 30 días |
| Limpieza | Automática en `hooks/session-start` al inicio de cada sesión |
| Ubicación archivos viejos | Eliminados (no archivados) |

### Limpieza automática (session-start)

Al inicio de cada sesión, el hook de session-start verifica y elimina archivos de audit con más de 30 días:

```bash
find .king/audit/ -name "*.jsonl" -mtime +30 -delete 2>/dev/null || true
```

---

## Ejemplo de Entrada Válida

```jsonl
{"schema_version":"1.0","timestamp":"2026-05-08T15:30:00Z","session_id":"WF-011-S002","workflow_id":"WF-011","skill":"build","agent":"@developer","action":"Edit","input_sha256":"a3f1c2d4e5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2","output_sha256":"b7e2f3a4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2"}
```

## Ejemplo de Entrada con Redacción

```jsonl
{"schema_version":"1.0","timestamp":"2026-05-08T16:00:00Z","session_id":"WF-011-S003","workflow_id":"WF-011","skill":"build","agent":"@developer","action":"Write","input_sha256":"none","output_sha256":"none","redacted":true}
```

---

## Comportamiento Fail-Safe

El Paso N+1.6 NUNCA bloquea el pipeline. Ante cualquier error:

1. Loguear en el session document bajo `### Audit Ledger`:
   ```
   | Paso N+1.6 | WARN: [motivo del fallo] |
   ```
2. Continuar con la ejecución normal
3. El skill completado se considera exitoso aunque el audit falle

Errores típicos y su manejo:

| Error | Handling |
|-------|----------|
| `jq` no disponible | WARN en session doc, no escribir entrada |
| `sha256sum` no disponible | Usar `"none"` para ambos hashes, escribir entrada igualmente |
| `.king/audit/` no se puede crear | WARN en session doc, no escribir entrada |
| JSONL corrupto en el archivo | No afecta: se hace append, no lectura |
| Timeout de escritura | WARN en session doc, continuar |
