#!/usr/bin/env bash
# contextual-observer — King Jarvis Mode (M-81)
# Hook PostToolUse Write|Edit (async: true): observa el archivo recién escrito,
# corre los 13 patrones de knowledge/universal/jarvis-patterns.md y appendea los
# findings a .king/jarvis/observations.jsonl (NDJSON, consumed:false).
#
# DEFERRED EMIT: NO emite nada al usuario. El hook UserPromptSubmit lee
# observations.jsonl y emite los findings al inicio del siguiente prompt.
#
# FAIL-SAFE: cualquier error interno se loguea como WARN en perf.log y el script
# termina con exit 0 — NUNCA interrumpe el pipeline de escritura del usuario.
# El `set -e` se desactiva dentro de la lógica de detección para garantizarlo.
set -euo pipefail

# --- Instrumentación de timing (T4) ---------------------------------------
START_MS=$(date +%s%3N 2>/dev/null || echo 0)

# --- 0. Helpers fail-safe --------------------------------------------------
# Trap global: ante cualquier fallo no capturado, log WARN y salir 0.
fail_safe() {
  local code=$?
  [ "$code" -ne 0 ] && _perf_log "WARN observer abortó (exit ${code}) file=${FILE:-?}"
  exit 0
}
trap fail_safe ERR

PERF_LOG=""
_perf_log() {
  # Best-effort: si no hay ruta de log, descartar en silencio.
  [ -n "$PERF_LOG" ] || return 0
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '?')" "$1" >> "$PERF_LOG" 2>/dev/null || true
}

# Motor de búsqueda: ripgrep si está, fallback a grep -E (dep. soft).
if command -v rg >/dev/null 2>&1; then
  RG_BIN="rg"
else
  RG_BIN=""
fi

# Busca un patrón con contexto (-A2 -B2 para layer S). Devuelve 0 si hay match.
# Aplica negative_lookahead sobre la ventana de contexto (anti-FP, R1).
# Args: <file> <pattern> <neg_lookahead> <ctx_lines>
_search() {
  local f="$1" pat="$2" neg="$3" ctx="${4:-0}" hits=""
  if [ -n "$RG_BIN" ]; then
    hits=$("$RG_BIN" --no-config -e "$pat" -A "$ctx" -B "$ctx" -- "$f" 2>/dev/null) || true
  else
    hits=$(grep -nE -A "$ctx" -B "$ctx" -e "$pat" -- "$f" 2>/dev/null) || true
  fi
  [ -n "$hits" ] || return 1
  # Si el negative_lookahead matchea en la ventana de contexto, descartar.
  if [ -n "$neg" ]; then
    if printf '%s' "$hits" | grep -qE -e "$neg" 2>/dev/null; then
      return 1
    fi
  fi
  return 0
}

# Appendea un finding como una línea NDJSON. Sanitiza comillas del path (R5).
# Args: <pattern_id> <severity> <suggestion-base> <skill>
_emit() {
  local pid="$1" sev="$2" sug_tpl="$3" skill="$4"
  local ts safe_file sug
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '1970-01-01T00:00:00Z')
  # Path relativo a la raíz del repo para legibilidad; sin contenido del archivo.
  safe_file="${REL_FILE//\"/\'}"
  sug="${sug_tpl//\{file\}/$safe_file}"
  sug="${sug//\"/\'}"
  printf '{"ts":"%s","pattern_id":"%s","file":"%s","severity":"%s","suggestion":"%s","skill":"%s","consumed":false}\n' \
    "$ts" "$pid" "$safe_file" "$sev" "$sug" "$skill" >> "$OBS_FILE" 2>/dev/null || \
    _perf_log "WARN no se pudo escribir finding ${pid} en observations.jsonl"
}

# --- 1. Leer file_path desde stdin (JSON del hook) -------------------------
INPUT=$(cat 2>/dev/null || true)
FILE=$(printf '%s' "$INPUT" | jq -r '.path // .file_path // .tool_input.file_path // empty' 2>/dev/null || true)
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

# --- 2. Resolver raíz del repo y rutas de salida ---------------------------
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$ROOT" ] || ROOT=$(pwd)
JARVIS_DIR="$ROOT/.king/jarvis"
OBS_FILE="$JARVIS_DIR/observations.jsonl"
PERF_LOG="$JARVIS_DIR/perf.log"
mkdir -p "$JARVIS_DIR" 2>/dev/null || exit 0

# Path relativo (para el finding) — fallback al absoluto si no se puede.
REL_FILE="${FILE#"$ROOT"/}"
[ -n "$REL_FILE" ] || REL_FILE="$FILE"

# --- 3. Early-exit (R2: latencia) ------------------------------------------
# 3a. Directorios ruidosos / artefactos que no son fuente.
case "$FILE" in
  */node_modules/*|*/dist/*|*/build/*|*/.next/*|*/out/*|*/.git/*|*/vendor/*|*/.venv/*|*/__pycache__/*)
    # dist/build/.next/out sí interesan SOLO para bundle-size-up (layer E).
    case "$FILE" in
      */node_modules/*|*/.git/*|*/vendor/*|*/.venv/*|*/__pycache__/*)
        _perf_log "skip dir-excluido ${REL_FILE}"; exit 0 ;;
    esac
    ;;
esac

# 3b. Tamaño > 5MB: skip (heurística regex no aporta y cuesta latencia).
SIZE=$(wc -c < "$FILE" 2>/dev/null || echo 0)
if [ "${SIZE:-0}" -gt 5242880 ]; then
  _perf_log "skip >5MB ${REL_FILE}"; exit 0
fi

# 3c. Tests / mocks / generados: no son objetivo de la mayoría de patrones.
IS_TEST=0
case "$FILE" in
  *.test.*|*.spec.*|*_test.*|*/test_*.py|*/__tests__/*|*/mocks/*|*/fixtures/*|*.stories.*|*.gen.*|*_pb.*)
    IS_TEST=1 ;;
esac

EXT="${FILE##*.}"
BASENAME="${FILE##*/}"

# A partir de aquí, los detectores son best-effort: relajamos -e para no abortar.
set +e

# --- 4. Detectores por patrón (filtrados por file_glob) --------------------

# ===== Layer S (Security) — contexto extendido -A2 -B2, negative lookahead ==
case "$EXT" in
  ts|js|go|py|java|rb|php|tsx|jsx)
    # 1. endpoint-sin-auth (ts|js|go|py)
    case "$EXT" in
      ts|js|go|py)
        if _search "$FILE" \
          '(app|router)\.(get|post|put|delete|patch)\s*\(\s*['"'"'"`/]' \
          'requireAuth|@UseGuards|authMiddleware|@Auth|isAuthenticated|passport\.|ensureAuth|middleware' 2; then
          _emit "endpoint-sin-auth" "warning" \
            "Veo que {file} tiene un endpoint sin middleware de auth evidente." \
            "/castle --layer S"
        fi ;;
    esac

    # 2. secret-en-codigo
    if [ "$IS_TEST" -eq 0 ]; then
      if _search "$FILE" \
        'sk-ant-api[0-9A-Za-z_-]{20,}|ghp_[0-9A-Za-z]{36}|ghs_[0-9A-Za-z]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9A-Za-z]{24}|xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[a-zA-Z0-9]{24,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' \
        'process\.env|os\.environ|System\.getenv|EXAMPLE|PLACEHOLDER|<your-|xxxx|REDACTED|\.example' 2; then
        _emit "secret-en-codigo" "error" \
          "Detecté lo que parece un secreto hardcodeado en {file}. Mové la credencial a una variable de entorno." \
          "/castle --layer S"
      fi
    fi

    # 3. password-plano
    if [ "$IS_TEST" -eq 0 ]; then
      if _search "$FILE" \
        '(password|passwd|pwd|secret|api[_-]?key)\s*[:=]\s*['"'"'"`][^'"'"'"`$\{][^'"'"'"`]{3,}['"'"'"`]' \
        'process\.env|os\.environ|getenv|config\.|\$\{|EXAMPLE|placeholder' 2; then
        _emit "password-plano" "error" \
          "Veo una posible contraseña/secreto en texto plano en {file}. Usá variables de entorno o un secret manager." \
          "/castle --layer S"
      fi
    fi
    ;;
esac

# ===== Layer A (Architecture) ==============================================
if [ "$IS_TEST" -eq 0 ]; then
  # 4. query-n-plus-1 (ts|js|go|py|java|rb)
  case "$EXT" in
    ts|js|go|py|java|rb)
      if _search "$FILE" \
        '\b(for|forEach|map|while)\b[^;{]*\{[^}]*\b(find|findOne|query|select|get|fetch|load|save|exec)\b\s*\(' \
        'include:|preload|join|\.in\(|where.*IN|batch|Promise\.all|eager' 0; then
        _emit "query-n-plus-1" "warning" \
          "Veo un posible patrón N+1 en {file}: una query dentro de un loop. Considerá eager-loading o batch." \
          "/optimize"
      fi ;;
  esac

  # 5. funcion-mayor-500-loc (size-count, bash wc)
  case "$EXT" in
    ts|js|go|py|java|rb|php)
      LOC=$(wc -l < "$FILE" 2>/dev/null || echo 0)
      if [ "${LOC:-0}" -gt 500 ]; then
        _emit "funcion-mayor-500-loc" "warning" \
          "El archivo {file} supera las 500 líneas. Considerá dividirlo en módulos más pequeños y cohesivos." \
          "/refactor"
      fi ;;
  esac

  # 6. dependency-no-pinneada (manifiestos)
  case "$BASENAME" in
    package.json|requirements.txt|go.mod|Gemfile|pyproject.toml)
      if _search "$FILE" \
        '['"'"'"][\^~>]|['"'"'"]\*['"'"'"]|>=|latest' \
        'engines|"node":|workspace:|file:|link:' 0; then
        _emit "dependency-no-pinneada" "warning" \
          "Detecté una dependencia sin versión fija (rango o latest) en {file}. Pinneá la versión para builds reproducibles." \
          "/castle --layer A"
      fi ;;
  esac

  # 7. hardcoded-url
  case "$EXT" in
    ts|js|go|py|java|rb|php)
      if _search "$FILE" \
        'https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|example\.|www\.w3\.org)' "" 0; then
        : # match en lista blanca de contexto, ignorar abajo
      fi
      if _search "$FILE" \
        'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' \
        '//|/\*|process\.env|os\.environ|getenv|config\.|baseUrl|@see|@link|localhost|127\.0\.0\.1|example\.|www\.w3\.org|schemas?\.' 0; then
        _emit "hardcoded-url" "info" \
          "Veo una URL hardcodeada en {file}. Considerá moverla a configuración o variables de entorno." \
          "/castle --layer E"
      fi ;;
  esac

  # 8. missing-error-boundary (tsx|jsx)
  case "$EXT" in
    tsx|jsx)
      if _search "$FILE" \
        'export\s+(default\s+)?(function|const)\s+[A-Z][A-Za-z0-9]*' \
        'ErrorBoundary|componentDidCatch|getDerivedStateFromError|react-error-boundary|withErrorBoundary|Suspense' 0; then
        _emit "missing-error-boundary" "info" \
          "El componente en {file} no parece estar protegido por un Error Boundary. Considerá envolverlo para fallos en runtime." \
          "/frontend-design"
      fi ;;
  esac
fi

# ===== Layer L (Logging) ===================================================
if [ "$IS_TEST" -eq 0 ]; then
  # 9. console-log-prod (ts|js|tsx|jsx)
  case "$EXT" in
    ts|js|tsx|jsx)
      if _search "$FILE" \
        'console\.(log|debug|info|warn|error)\s*\(' \
        '//|/\*|eslint-disable|logger\.' 0; then
        _emit "console-log-prod" "warning" \
          "Veo un console.* en {file}. En producción usá un logger estructurado en lugar de console." \
          "/castle --layer L"
      fi ;;
  esac

  # 10. try-catch-vacio (ts|js|go|py|java)
  case "$EXT" in
    ts|js|go|py|java)
      if _search "$FILE" \
        'catch\s*(\([^)]*\))?\s*\{\s*\}|except[^:]*:\s*pass' \
        '//\s*(ignor|expected|noop|intentional)|#\s*(ignor|expected|noop|intentional)' 1; then
        _emit "try-catch-vacio" "warning" \
          "Detecté un try/catch vacío en {file}: estás silenciando un error. Logueá o re-lanzá la excepción." \
          "/castle --layer L"
      fi ;;
  esac
fi

# ===== Layer T (Testing) ===================================================
# 11. pr-sin-tests (file-diff por glob): archivo de código sin contraparte test.
if [ "$IS_TEST" -eq 0 ]; then
  case "$EXT" in
    ts|js|go|py|java|rb)
      STEM="${BASENAME%.*}"
      DIR="${FILE%/*}"
      HAS_TEST=0
      # Heurística: buscar archivos de test cuyo nombre referencie el stem.
      if find "$ROOT" -type f \
        \( -name "${STEM}.test.*" -o -name "${STEM}.spec.*" -o -name "${STEM}_test.*" -o -name "test_${STEM}.py" \) \
        2>/dev/null | grep -q . ; then
        HAS_TEST=1
      fi
      # También aceptar un __tests__ hermano que mencione el stem.
      if [ "$HAS_TEST" -eq 0 ] && [ -d "$DIR/__tests__" ]; then
        if find "$DIR/__tests__" -type f -name "*${STEM}*" 2>/dev/null | grep -q .; then
          HAS_TEST=1
        fi
      fi
      if [ "$HAS_TEST" -eq 0 ]; then
        _emit "pr-sin-tests" "warning" \
          "Modificaste lógica en {file} pero no veo un test asociado. Considerá agregar o actualizar pruebas." \
          "/qa"
      fi ;;
  esac
fi

# ===== Layer E (Environment) ===============================================
# 12. bundle-size-up (size-delta, bash stat) — solo en artefactos de build.
case "$FILE" in
  */dist/*.js|*/dist/*.css|*/build/*.js|*/build/*.css|*/.next/*.js|*/.next/*.css|*/out/*.js|*/out/*.css)
    BASELINE="$JARVIS_DIR/bundle-baseline"
    CUR=$(wc -c < "$FILE" 2>/dev/null || echo 0)
    KEY=$(printf '%s' "$REL_FILE" | tr -c 'a-zA-Z0-9_.-' '_')
    PREV=""
    [ -f "$BASELINE" ] && PREV=$(grep -E "^${KEY} " "$BASELINE" 2>/dev/null | awk '{print $2}' | tail -1)
    if [ -n "$PREV" ] && [ "${PREV:-0}" -gt 0 ] 2>/dev/null; then
      # Crecimiento > 10%: CUR > PREV * 1.10  (aritmética entera: CUR*100 > PREV*110)
      if [ $(( CUR * 100 )) -gt $(( PREV * 110 )) ]; then
        _emit "bundle-size-up" "info" \
          "El bundle {file} creció respecto al baseline. Revisá si entró una dependencia pesada o código sin tree-shaking." \
          "/optimize"
      fi
    fi
    # Actualizar baseline (best-effort, append; el último gana en la lectura).
    printf '%s %s\n' "$KEY" "$CUR" >> "$BASELINE" 2>/dev/null || true
    ;;
esac

# 13. env-var-sin-default
if [ "$IS_TEST" -eq 0 ]; then
  case "$EXT" in
    ts|js|go|py|java|rb)
      if _search "$FILE" \
        'process\.env\.[A-Z_][A-Z0-9_]+|os\.environ\[['"'"'"][A-Z_][A-Z0-9_]+['"'"'"]\]|os\.getenv\(\s*['"'"'"][A-Z_][A-Z0-9_]+['"'"'"]\s*\)' \
        '\|\||\?\?|default|os\.environ\.get\([^)]+,|getenv\([^)]+,' 0; then
        _emit "env-var-sin-default" "info" \
          "La variable de entorno usada en {file} no tiene valor por defecto ni validación. Definí un fallback o validá su presencia al arrancar." \
          "/castle --layer E"
      fi ;;
  esac
fi

# --- 5. Cierre + timing ----------------------------------------------------
END_MS=$(date +%s%3N 2>/dev/null || echo "$START_MS")
_perf_log "perf contextual-observer: $(( END_MS - START_MS ))ms — ${REL_FILE}"
exit 0
