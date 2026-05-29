#!/usr/bin/env bash
# hooks/api-change-check.sh — King Framework M-30 API Contract Change Check
#
# PostToolUse hook (Write|Edit): si se modifica un handler/controller y el proyecto
# tiene una spec OpenAPI, emite WARNING para validar el contrato con /api-contract-first.
#
# enforcement: warn (no bloquea). Degradación graciosa: exit 0 si no aplica.

set -uo pipefail

RAW_INPUT=$(cat)
FILE=$(echo "$RAW_INPUT" | jq -r '.path // .file_path // empty' 2>/dev/null || true)
CONTENT=$(echo "$RAW_INPUT" | jq -r '.content // .new_string // empty' 2>/dev/null || true)
[ -z "$FILE" ] && exit 0

# Solo código de aplicación.
case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.go|*.py|*.java|*.kt|*.rs|*.cs) ;;
  *) exit 0 ;;
esac

# ¿Es un handler/controller? Por path o por definición de rutas HTTP en el contenido.
IS_HANDLER=0
case "$FILE" in
  *handler*|*Handler*|*controller*|*Controller*|*routes*|*router*|*/api/*|*endpoint*) IS_HANDLER=1 ;;
esac
ROUTE_RE='app\.(get|post|put|delete|patch)\(|router\.(get|post|put|delete|patch)\(|@app\.route|@router\.(get|post|put|delete|patch)|@(Get|Post|Put|Delete|Patch)Mapping|@RestController|http\.HandleFunc|gin\.|fastify\.'
if [ "$IS_HANDLER" -eq 0 ] && [ -n "$CONTENT" ]; then
  echo "$CONTENT" | grep -qiE "$ROUTE_RE" && IS_HANDLER=1
fi
[ "$IS_HANDLER" -eq 0 ] && exit 0

# ¿Existe una spec OpenAPI en el proyecto?
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
SPEC=""
for cand in openapi.yaml openapi.yml openapi.json api/openapi.yaml api/openapi.yml api/openapi.json docs/openapi.yaml spec/openapi.yaml swagger.yaml swagger.json; do
  if [ -f "$ROOT/$cand" ]; then SPEC="$cand"; break; fi
done
[ -z "$SPEC" ] && exit 0

echo "[King API] WARNING: handler/controller modificado (${FILE}) con spec OpenAPI presente (${SPEC}). Validá el contrato con /api-contract-first ${SPEC} --compare-to <spec-anterior> para detectar breaking changes."
exit 0
