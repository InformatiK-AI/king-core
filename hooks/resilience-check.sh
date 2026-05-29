#!/usr/bin/env bash
# hooks/resilience-check.sh — King Framework M-10 Resilience Check
#
# PostToolUse hook (Write|Edit): detecta llamadas a servicios externos
# (HTTP / fetch / axios / gRPC / SDK) sin wrapper de retry/timeout/circuit-breaker
# y emite WARNING sugiriendo /resilience-weave.
#
# enforcement: warn (default) | block — configurable en .king/resilience.yaml.
# Degradación graciosa: exit 0 si no aplica (no rompe ningún flujo).

set -uo pipefail

RAW_INPUT=$(cat)

# Extraer path y contenido (Write usa .path/.content; Edit usa .new_string).
FILE=$(echo "$RAW_INPUT" | jq -r '.path // .file_path // empty' 2>/dev/null || true)
CONTENT=$(echo "$RAW_INPUT" | jq -r '.content // .new_string // empty' 2>/dev/null || true)
[ -z "$CONTENT" ] && exit 0

# Solo código de aplicación — ignorar markdown/config/tests.
case "$FILE" in
  *.test.*|*_test.*|*.spec.*) exit 0 ;;
  *.ts|*.tsx|*.js|*.jsx|*.go|*.py|*.java|*.kt|*.rs|*.cs) ;;
  *) exit 0 ;;
esac

# ¿Hay una llamada a servicio externo?
HTTP_RE='fetch\(|axios\.|axios\(|http\.(get|post|put|delete|request)|requests\.(get|post|put|delete)|urllib|http\.Client|grpc\.|HttpClient|WebClient|RestTemplate'
echo "$CONTENT" | grep -qiE "$HTTP_RE" || exit 0

# ¿Ya hay señal de resiliencia presente? Si la hay, no advertir.
RESIL_RE='retry|timeout|circuit|CircuitBreaker|withRetry|backoff|AbortController|WithTimeout|signal:|deadline|bulkhead|fallback|cockatiel|opossum|p-retry|gobreaker|tenacity|pybreaker|resilience4j|polly|failsafe'
if echo "$CONTENT" | grep -qiE "$RESIL_RE"; then
  exit 0
fi

# Determinar enforcement desde .king/resilience.yaml (default: warn).
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
ENFORCEMENT="warn"
if [ -f "$ROOT/.king/resilience.yaml" ]; then
  if grep -qiE '^[[:space:]]*enforcement:[[:space:]]*block' "$ROOT/.king/resilience.yaml"; then
    ENFORCEMENT="block"
  fi
fi

MSG="Llamada a servicio externo sin retry/timeout/circuit-breaker en ${FILE:-archivo}. Ejecutá /resilience-weave (king-arch, si está instalado) para tejer resiliencia (retry + CB + timeout + fallback). Ref: knowledge/domain/resilience-patterns.md"

if [ "$ENFORCEMENT" = "block" ]; then
  echo "[King Resilience] BLOCKED: $MSG"
  exit 2
fi

echo "[King Resilience] WARNING: $MSG"
exit 0
