#!/usr/bin/env bash
# logging-emit-check — King M06 (M-08)
# PostToolUse Write|Edit: verifica que handlers HTTP / consumers / funciones publicas
# exportadas incluyan al menos un log estructurado con correlationId/trace_id.
# Sentinel: SOLO actua si existe .king/observability.yaml (proyecto con /observe).
# Severidad: .king/observability.yaml -> logging.enforcement (warn|block). Default warn.
# Heuristica de superficie (no AST): alcance a nivel de archivo restringido a lo publico.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r ".path // .file_path // empty" 2>/dev/null)
CONTENT=$(echo "$INPUT" | jq -r ".content // .new_string // empty" 2>/dev/null)
[ -z "$FILE" ] && exit 0
[ -z "$CONTENT" ] && exit 0

# Solo archivos de codigo soportados
case "$FILE" in
  *.ts|*.js|*.py|*.go|*.java) ;;
  *) exit 0 ;;
esac

# Exclusiones por defecto (tests, specs, mocks)
case "$FILE" in
  *.test.*|*.spec.*|*/mocks/*|*/__tests__/*) exit 0 ;;
esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
CFG="$ROOT/.king/observability.yaml"
# Sentinel: sin config el hook esta inactivo (no molesta a proyectos sin observabilidad)
[ -f "$CFG" ] || exit 0

# Leer enforcement / require_correlation_id de la seccion logging:
ENFORCE=$(awk '/^logging:/{f=1;next} /^[a-zA-Z]/{f=0} f && /enforcement:/{print $2; exit}' "$CFG" 2>/dev/null)
[ -z "$ENFORCE" ] && ENFORCE=warn
REQ_CID=$(awk '/^logging:/{f=1;next} /^[a-zA-Z]/{f=0} f && /require_correlation_id:/{print $2; exit}' "$CFG" 2>/dev/null)
[ -z "$REQ_CID" ] && REQ_CID=true

# Patrones por stack: handler/export que dispara la evaluacion, logger presente, campo de correlacion, snippet
HANDLER_RE=""; LOGGER_RE=""; CID_RE=""; SNIPPET=""
case "$FILE" in
  *.ts|*.js)
    HANDLER_RE='(app|router)\.(get|post|put|patch|delete)[[:space:]]*\(|export[[:space:]]+(async[[:space:]]+)?function[[:space:]]+[A-Za-z_]'
    LOGGER_RE='(logger|log)\.(info|warn|error|debug)[[:space:]]*\('
    CID_RE='correlationId|trace_id'
    SNIPPET='const log = logger.child({ correlationId: req.headers["x-correlation-id"] }); log.info({}, "evento");' ;;
  *.py)
    HANDLER_RE='@(app|router)\.(get|post|put|patch|delete)[[:space:]]*\(|@[A-Za-z_]+\.route[[:space:]]*\(|^def[[:space:]]+[A-Za-z]|^async[[:space:]]+def[[:space:]]+[A-Za-z]'
    LOGGER_RE='(log|logger)\.(info|warning|error|debug)[[:space:]]*\('
    CID_RE='correlation_id|bind_contextvars|trace_id'
    SNIPPET='log = logger.bind(correlation_id=cid); log.info("evento")' ;;
  *.go)
    HANDLER_RE='http\.HandleFunc[[:space:]]*\(|func[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*\([[:space:]]*w[[:space:]]+http\.ResponseWriter'
    LOGGER_RE='\.(Info|Warn|Error|Debug)[[:space:]]*\('
    CID_RE='correlationId|zap\.String'
    SNIPPET='logger.Info("evento", zap.String("correlationId", cid))' ;;
  *.java)
    HANDLER_RE='@(Get|Post|Put|Patch|Delete|Request)Mapping'
    LOGGER_RE='log\.(info|warn|error|debug)[[:space:]]*\('
    CID_RE='MDC\.put\("correlationId"|correlationId'
    SNIPPET='MDC.put("correlationId", cid); log.info("evento");' ;;
esac

# Linea del primer handler/export publico detectado
HLINE=$(echo "$CONTENT" | grep -nE "$HANDLER_RE" | head -1 | cut -d: -f1)
[ -z "$HLINE" ] && exit 0   # sin handler/export publico: nada que verificar

# Hay logger? (+ correlacion si se exige)
if echo "$CONTENT" | grep -qE "$LOGGER_RE"; then
  if [ "$REQ_CID" = "true" ]; then
    echo "$CONTENT" | grep -qE "$CID_RE" && exit 0
  else
    exit 0
  fi
fi

# Falta log estructurado (o falta el campo de correlacion)
if [ "$ENFORCE" = "block" ]; then
  echo "[logging-emit-check] VETO — Handler/export publico en ${FILE}:${HLINE} no incluye log estructurado con correlationId."
  echo "  Correccion: ${SNIPPET}"
  exit 2
fi
echo "[logging-emit-check] WARNING — Handler/export publico en ${FILE}:${HLINE} no incluye log estructurado con correlationId."
echo "  Correccion: ${SNIPPET}"
exit 0
