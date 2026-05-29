#!/usr/bin/env bash
# instrument-emit-check — King M06 (M-09)
# PostToolUse Write|Edit: verifica instrumentacion OTel (span/metricas) en handlers HTTP
# y funciones publicas exportadas, y advierte de labels de alta cardinalidad.
# Sentinel: SOLO actua si existe .king/observability.yaml.
# Severidad: .king/observability.yaml -> instrumentation.enforcement (warn|block). Default warn.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r ".path // .file_path // empty" 2>/dev/null)
CONTENT=$(echo "$INPUT" | jq -r ".content // .new_string // empty" 2>/dev/null)
[ -z "$FILE" ] && exit 0
[ -z "$CONTENT" ] && exit 0

case "$FILE" in
  *.ts|*.js|*.py|*.go) ;;
  *) exit 0 ;;
esac

# Exclusiones (heredan de logging + propias: generados, migraciones, build)
case "$FILE" in
  *.test.*|*.spec.*|*/mocks/*|*/__tests__/*|*/migrations/*|*.gen.go|*_pb.go|*/dist/*|*/build/*) exit 0 ;;
esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
CFG="$ROOT/.king/observability.yaml"
[ -f "$CFG" ] || exit 0

ENFORCE=$(awk '/^instrumentation:/{f=1;next} /^[a-zA-Z]/{f=0} f && /enforcement:/{print $2; exit}' "$CFG" 2>/dev/null)
[ -z "$ENFORCE" ] && ENFORCE=warn

HANDLER_RE=""; INSTR_RE=""; SNIPPET=""
case "$FILE" in
  *.ts|*.js)
    HANDLER_RE='(app|router)\.(get|post|put|patch|delete)[[:space:]]*\(|export[[:space:]]+(async[[:space:]]+)?function[[:space:]]+[A-Za-z_]'
    INSTR_RE='startActiveSpan|otelhttp|metrics\.(counter|histogram)|recordMetric|meter\.'
    SNIPPET='await tracer.startActiveSpan("op", async (span) => { /* ... */ span.end(); });' ;;
  *.py)
    HANDLER_RE='@(app|router)\.(get|post|put|patch|delete)[[:space:]]*\(|^async[[:space:]]+def[[:space:]]+[A-Za-z]|^def[[:space:]]+[A-Za-z]'
    INSTR_RE='start_as_current_span|FastAPIInstrumentor|meter\.create_'
    SNIPPET='with tracer.start_as_current_span("op"): ...' ;;
  *.go)
    HANDLER_RE='http\.HandleFunc[[:space:]]*\(|func[[:space:]]+[A-Za-z0-9_]*Handler[[:space:]]*\(|func[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*\('
    INSTR_RE='otelhttp\.NewHandler|tracer\.Start|meter\.(Int64Counter|Float64Histogram)'
    SNIPPET='ctx, span := tracer.Start(ctx, "op"); defer span.End()' ;;
esac

HLINE=$(echo "$CONTENT" | grep -nE "$HANDLER_RE" | head -1 | cut -d: -f1)
[ -z "$HLINE" ] && exit 0
echo "$CONTENT" | grep -qE "$INSTR_RE" && exit 0   # ya instrumentado

# Label de alta cardinalidad (siempre se advierte, no bloquea por si solo)
CARD=""
echo "$CONTENT" | grep -qE 'user_id|request_id|email' && CARD="  Nota: posible label de alta cardinalidad (user_id/request_id/email) — usar atributo de span, no label de metrica."

if [ "$ENFORCE" = "block" ]; then
  echo "[instrument-emit-check] VETO — Handler/funcion publica en ${FILE}:${HLINE} sin instrumentacion OTel (span/metricas)."
  echo "  Correccion: ${SNIPPET}"
  [ -n "$CARD" ] && echo "$CARD"
  exit 2
fi
echo "[instrument-emit-check] WARNING — Handler/funcion publica en ${FILE}:${HLINE} sin instrumentacion OTel (span/metricas)."
echo "  Correccion: ${SNIPPET}"
[ -n "$CARD" ] && echo "$CARD"
exit 0
