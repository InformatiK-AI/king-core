#!/usr/bin/env bash
# emit-observations.sh — Deferred emit del Contextual Observer (M-81).
# Hook UserPromptSubmit: lee findings consumed:false de .king/jarvis/observations.jsonl,
# emite hasta 3 al contexto del prompt actual y los marca consumed:true.
#
# Por qué deferred: el observer (PostToolUse) NO interrumpe al escribir; sus hallazgos
# se difieren a este punto para que el usuario los vea sin perder contexto (mitiga R1 FP).
#
# Fail-safe: set -euo pipefail + trap ERR → exit 0. Nunca interrumpe el prompt.
set -euo pipefail
trap 'exit 0' ERR

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
OBS="$ROOT/.king/jarvis/observations.jsonl"
[ -f "$OBS" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Hallazgos pendientes (consumed:false), máximo 3 (oldest-first)
PENDING=$(jq -c 'select(.consumed == false)' "$OBS" 2>/dev/null | head -3)
[ -z "$PENDING" ] && exit 0

echo "[King Jarvis] Observaciones del contexto reciente (Contextual Observer):"
echo "$PENDING" | jq -r '"  • [\(.severity)] \(.suggestion)  →  \(.skill)"' 2>/dev/null || exit 0

# Marcar los primeros 3 consumed:false como consumed:true (preserva el resto).
TMP="$OBS.tmp"
N=0
: > "$TMP"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  c=$(printf '%s' "$line" | jq -r '.consumed' 2>/dev/null || echo "true")
  if [ "$c" = "false" ] && [ "$N" -lt 3 ]; then
    printf '%s\n' "$line" | jq -c '.consumed = true' >> "$TMP" 2>/dev/null || printf '%s\n' "$line" >> "$TMP"
    N=$((N + 1))
  else
    printf '%s\n' "$line" >> "$TMP"
  fi
done < "$OBS"
mv "$TMP" "$OBS" 2>/dev/null || rm -f "$TMP"
exit 0
