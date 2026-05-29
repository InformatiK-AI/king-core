#!/usr/bin/env bash
# error-recovery — King M02 (M-83) — Conversational Error Recovery
# Evento: Stop (async:false). Al terminar la sesión, detecta errores bloqueantes
# en el output (stdin) y en .king/registry.md, y ofrece 3 opciones de recuperación.
#
# Patrones (ver knowledge/universal/error-recovery-patterns.md):
#   castle-breached-security · build-fail · test-fail · lint-fail · secret-detectado
#
# Fail-safe: cualquier error interno se degrada a [WARN] y exit 0.
#            NUNCA interrumpe el pipeline del Stop. No-op silencioso sin match.

set -euo pipefail

# --- Fail-safe: cualquier fallo interno -> WARN, sin bloquear el Stop ---------
trap 'echo "[error-recovery] WARN: fallo interno (linea ${LINENO}); no-op." >&2; exit 0' ERR

# --- Entradas ----------------------------------------------------------------
# Output de la sesión: últimas ~50 líneas del stdin del hook Stop.
SESSION_OUTPUT=""
if [ ! -t 0 ]; then
  SESSION_OUTPUT=$(tail -n 50 2>/dev/null || true)
fi

# .king/registry.md: últimas 10 líneas de la sesión activa.
REGISTRY_TAIL=""
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$ROOT" ] && [ -f "$ROOT/.king/registry.md" ]; then
  REGISTRY_TAIL=$(tail -n 10 "$ROOT/.king/registry.md" 2>/dev/null || true)
fi

# Sin ninguna fuente -> no-op silencioso.
if [ -z "$SESSION_OUTPUT" ] && [ -z "$REGISTRY_TAIL" ]; then
  exit 0
fi

# --- Helpers -----------------------------------------------------------------
# match SOURCE_TEXT PATTERN -> 0 si el patrón ERE hace match (case-insensitive).
match() {
  printf '%s' "$1" | grep -Eiq "$2"
}

# emit TEMPLATE: imprime el template ya interpolado al stdout del hook.
emit() {
  printf '%s\n' "$1"
}

MATCHED=0

# --- Patrón 1: castle-breached-security (source: registry.md) -----------------
if match "$REGISTRY_TAIL" 'CASTLE BREACHED.*layer.*S'; then
  FILES=$(printf '%s' "$REGISTRY_TAIL" \
    | grep -Eio '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+' | sort -u | tr '\n' '|' | sed 's/|$//; s/|/, /g' || true)
  [ -z "$FILES" ] && FILES="{files}"
  emit "► CASTLE BREACHED — Layer S
El skill /castle detectó vulnerabilidades críticas en: ${FILES}
Tenés 3 opciones:
  [1] /fix --target security — King genera los fixes y los propone para review
  [2] /castle --layer S --detail — auditoría detallada con guía de remediación
  [3] Escalar a @security — revisión manual de los findings"
  MATCHED=1
fi

# --- Patrón 2: build-fail (source: session-output) ---------------------------
if match "$SESSION_OUTPUT" 'build failed|compilation error|TS[0-9]+'; then
  ERROR_MESSAGE=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Ei 'build failed|compilation error|TS[0-9]+' | head -n 1 || true)
  [ -z "$ERROR_MESSAGE" ] && ERROR_MESSAGE="{error_message}"
  ERROR_SUMMARY=$(printf '%s' "$ERROR_MESSAGE" | cut -c1-120)
  [ -z "$ERROR_SUMMARY" ] && ERROR_SUMMARY="{error_summary}"
  emit "► Build fallido
Error: ${ERROR_SUMMARY}
Tenés 3 opciones:
  [1] /fix --error \"${ERROR_MESSAGE}\" — fix directo
  [2] Mostrar el contexto completo del error para analizarlo juntos
  [3] Revertir al último commit estable (git stash)"
  MATCHED=1
fi

# --- Patrón 3: test-fail (source: session-output) ----------------------------
if match "$SESSION_OUTPUT" '[0-9]+ (test|spec)s? (failed|failing)|FAIL '; then
  FAIL_COUNT=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Eio '[0-9]+ (test|spec)s? (failed|failing)' | grep -Eo '^[0-9]+' | head -n 1 || true)
  [ -z "$FAIL_COUNT" ] && FAIL_COUNT="{fail_count}"
  TOTAL_COUNT=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Eio '[0-9]+ (tests?|specs?)( total| passed| ran)' | grep -Eo '^[0-9]+' | head -n 1 || true)
  [ -z "$TOTAL_COUNT" ] && TOTAL_COUNT="{total_count}"
  TEST_FILE=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Eio '[A-Za-z0-9_./-]+\.(test|spec)\.[A-Za-z0-9]+|[A-Za-z0-9_./-]+_test\.[A-Za-z0-9]+' | head -n 1 || true)
  [ -z "$TEST_FILE" ] && TEST_FILE="{test_file}"
  MODULE=$(basename "$TEST_FILE" 2>/dev/null | sed -E 's/\.(test|spec)\..*$//; s/_test\..*$//' || true)
  [ -z "$MODULE" ] && MODULE="{module}"
  emit "► Tests fallando — ${FAIL_COUNT} de ${TOTAL_COUNT} tests
Módulo afectado: ${TEST_FILE}
Tenés 3 opciones:
  [1] /fix --test \"${TEST_FILE}\" — King analiza el failure y propone fix
  [2] /qa --focus ${MODULE} — QA completo sobre el módulo
  [3] Ver el diff desde el último test verde"
  MATCHED=1
fi

# --- Patrón 4: lint-fail (source: session-output) ----------------------------
if match "$SESSION_OUTPUT" '[0-9]+ (error|warning)s?.*lint|eslint|golangci'; then
  WARNINGS=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Eio '[0-9]+ warnings?' | grep -Eo '^[0-9]+' | head -n 1 || true)
  [ -z "$WARNINGS" ] && WARNINGS="{warnings}"
  ERRORS=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Eio '[0-9]+ errors?' | grep -Eo '^[0-9]+' | head -n 1 || true)
  [ -z "$ERRORS" ] && ERRORS="{errors}"
  FILES=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Eio '[A-Za-z0-9_./-]+\.(ts|tsx|js|jsx|go|py|rs|java)' | sort -u | tr '\n' '|' | sed 's/|$//; s/|/, /g' || true)
  [ -z "$FILES" ] && FILES="{files}"
  emit "► Lint fallando — ${WARNINGS} warnings, ${ERRORS} errors
Archivos afectados: ${FILES}
Tenés 3 opciones:
  [1] Auto-fix lint errors — ejecuta linter con --fix
  [2] /review --focus lint — revisión con contexto de arquitectura
  [3] Mostrar los ${ERRORS} errores bloqueantes para resolverlos manualmente"
  MATCHED=1
fi

# --- Patrón 5: secret-detectado (source: session-output) ---------------------
if match "$SESSION_OUTPUT" 'BLOCKED: Hardcoded secret|secret detectado|secret pattern'; then
  HIT=$(printf '%s' "$SESSION_OUTPUT" \
    | grep -Ei 'BLOCKED: Hardcoded secret|secret detectado|secret pattern' | head -n 1 || true)
  FILE=$(printf '%s' "$HIT" \
    | grep -Eo '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+' | head -n 1 || true)
  [ -z "$FILE" ] && FILE="{file}"
  LINE=$(printf '%s' "$HIT" \
    | grep -Eio '(line|línea)[: ]*[0-9]+' | grep -Eo '[0-9]+' | head -n 1 || true)
  [ -z "$LINE" ] && LINE="{line}"
  emit "► ALERTA CRÍTICA — Secret detectado en código
Archivo: ${FILE}, línea ${LINE}
Tenés 3 opciones:
  [1] Eliminar ahora + rotar el secret — King guía el proceso completo
  [2] Mover a variable de entorno — King genera el refactor seguro
  [3] Marcar como false positive — si es un valor de ejemplo sin valor real"
  MATCHED=1
fi

# --- Sin match: no-op silencioso ---------------------------------------------
[ "$MATCHED" -eq 0 ] && exit 0

exit 0
