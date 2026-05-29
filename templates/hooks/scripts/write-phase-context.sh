#!/usr/bin/env bash
# write-phase-context.sh
# Escribe el contexto de la transición de fase en disco para que @conductor lo consuma.
# Es el handler por defecto que /genesis instala para activar Jarvis (modo proactivo).
#
# Recibe 6 ENV VARS del dispatcher PhaseTransition (session-management Paso N+1.5):
#   KING_FROM_PHASE, KING_TO_PHASE, KING_PROJECT_NAME, KING_BRANCH,
#   KING_TIMESTAMP, KING_STATUS
# El workflow_id se obtiene del registry activo para prevenir race conditions entre worktrees.
#
# Seguridad:
#   - Usa jq --arg para serializar JSON (nunca string concat — previene injection)
#   - El signal file es consumido y eliminado por Paso N+1.5b de session-management
#
# Fail-safe: set -euo pipefail + cualquier error termina el script con exit ≠ 0,
# que el dispatcher captura como WARN y continúa. El pipeline principal NO se interrumpe.

set -euo pipefail

OUTPUT_FILE=".king/hooks/.conductor-context.json"

# Crear directorio si no existe (idempotente)
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Extraer workflow_id del registry (WF-NNN en la tabla de Workflows Activos)
WORKFLOW_ID=$(grep -m1 "^| WF-" ".king/registry.md" 2>/dev/null | awk -F'|' '{print $2}' | tr -d ' ' || echo "unknown")

# Serializar payload como JSON estructurado.
# --arg escapa caracteres especiales — nunca interpolación directa de $VAR en JSON.
jq -n \
  --arg from_phase    "${KING_FROM_PHASE:-unknown}" \
  --arg to_phase      "${KING_TO_PHASE:-unknown}" \
  --arg project_name  "${KING_PROJECT_NAME:-unknown}" \
  --arg branch        "${KING_BRANCH:-unknown}" \
  --arg status        "${KING_STATUS:-unknown}" \
  --arg timestamp     "${KING_TIMESTAMP:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}" \
  --arg workflow_id   "${WORKFLOW_ID}" \
  '{
    schema_version: "1.0",
    workflow_id:  $workflow_id,
    from_phase:   $from_phase,
    to_phase:     $to_phase,
    project_name: $project_name,
    branch:       $branch,
    status:       $status,
    timestamp:    $timestamp
  }' > "$OUTPUT_FILE"

exit 0
