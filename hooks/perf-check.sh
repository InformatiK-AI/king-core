#!/usr/bin/env bash
# hooks/perf-check.sh — King Framework M-27 Performance Budget Gate
#
# PostToolUse hook: evaluates performance metrics after each Bash tool execution.
# Writes .king/castle/perf-report.json and exits 0 (pass/warn) or 2 (block).
#
# STDIN FORMAT (PostToolUse):
#   Claude Code sends a JSON object to stdin when a tool completes.
#   The exact schema is empirically prototyped here — docs are incomplete.
#   We try multiple known field paths before falling back to raw stdin.
#   If none contain performance data, we exit 0 silently (graceful degradation).
#   Tracked open question: design.md#open-questions PostToolUse stdin format.

set -euo pipefail

# ── 1. Parse stdin ──────────────────────────────────────────────────────────

RAW_INPUT=$(cat)

# Try known PostToolUse JSON field paths in priority order.
# '.tool_response' is the most likely field name based on PreToolUse patterns;
# '.output' and '.stdout' are fallbacks for variant schemas.
TOOL_OUTPUT=$(
  echo "$RAW_INPUT" \
    | jq -r '.tool_response // .output // .stdout // empty' 2>/dev/null \
    || true
)

# If jq extraction yielded nothing, treat the raw input itself as plain text.
if [ -z "$TOOL_OUTPUT" ]; then
  TOOL_OUTPUT="$RAW_INPUT"
fi

# ── 2. Detect performance signals ───────────────────────────────────────────

# Exit silently if the output has no performance signals.
# Most Bash calls (git, file writes, etc.) produce no performance data.
has_perf_signal() {
  echo "$TOOL_OUTPUT" | grep -qiE 'LCP|CLS|INP|bundle|lighthouse|[0-9]+\s*ms|[0-9]+\s*[kK][bB]|benchmark|perf' 2>/dev/null
}

if ! has_perf_signal; then
  exit 0
fi

# ── 3. Resolve project root and config ──────────────────────────────────────

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

PERF_YAML="$PROJECT_ROOT/.king/performance.yaml"
LEGACY_YAML="$PROJECT_ROOT/.king/performance-budget.yaml"

# ADR #7: canonical config is .king/performance.yaml.
# If canonical does not exist but legacy does → WARN + exit 0.
# If neither exists → WARN (no config) + exit 0.
if [ ! -f "$PERF_YAML" ]; then
  if [ -f "$LEGACY_YAML" ]; then
    echo "[King/Perf] WARN: Legacy config detected at .king/performance-budget.yaml — rename to .king/performance.yaml (ADR #7)"
    exit 0
  fi
  echo "[King/Perf] WARN: No performance config found — run /genesis to configure (.king/performance.yaml)"
  exit 0
fi

# ── 4. Read thresholds from .king/performance.yaml ──────────────────────────

# Parse with yq if available; fall back to simple grep for bare scalar values.
LCP_BUDGET=2500
CLS_BUDGET="0.1"
INP_BUDGET=200
JS_BUDGET=200
CSS_BUDGET=50
ENFORCEMENT="block"

if command -v yq &>/dev/null; then
  LCP_BUDGET=$(yq e '.budgets.web_vitals.lcp_ms // 2500' "$PERF_YAML" 2>/dev/null || echo "2500")
  CLS_BUDGET=$(yq e '.budgets.web_vitals.cls // 0.1' "$PERF_YAML" 2>/dev/null || echo "0.1")
  INP_BUDGET=$(yq e '.budgets.web_vitals.inp_ms // 200' "$PERF_YAML" 2>/dev/null || echo "200")
  JS_BUDGET=$(yq e '.budgets.bundle_size.js_kb // 200' "$PERF_YAML" 2>/dev/null || echo "200")
  CSS_BUDGET=$(yq e '.budgets.bundle_size.css_kb // 50' "$PERF_YAML" 2>/dev/null || echo "50")
  ENFORCEMENT=$(yq e '.enforcement // "block"' "$PERF_YAML" 2>/dev/null || echo "block")
else
  # Minimal grep fallback — handles "lcp_ms: 2500" style lines only.
  _lcp=$(grep -E '^\s*lcp_ms\s*:' "$PERF_YAML" 2>/dev/null | grep -oP '[0-9]+' | head -1 || true)
  [ -n "$_lcp" ] && LCP_BUDGET="$_lcp"
  _cls=$(grep -E '^\s*cls\s*:' "$PERF_YAML" 2>/dev/null | grep -oP '[0-9]+\.?[0-9]*' | head -1 || true)
  [ -n "$_cls" ] && CLS_BUDGET="$_cls"
  _inp=$(grep -E '^\s*inp_ms\s*:' "$PERF_YAML" 2>/dev/null | grep -oP '[0-9]+' | head -1 || true)
  [ -n "$_inp" ] && INP_BUDGET="$_inp"
  _js=$(grep -E '^\s*js_kb\s*:' "$PERF_YAML" 2>/dev/null | grep -oP '[0-9]+' | head -1 || true)
  [ -n "$_js" ] && JS_BUDGET="$_js"
  _css=$(grep -E '^\s*css_kb\s*:' "$PERF_YAML" 2>/dev/null | grep -oP '[0-9]+' | head -1 || true)
  [ -n "$_css" ] && CSS_BUDGET="$_css"
  _enf=$(grep -E '^\s*enforcement\s*:' "$PERF_YAML" 2>/dev/null | grep -oP '(block|warn)' | head -1 || true)
  [ -n "$_enf" ] && ENFORCEMENT="$_enf"
fi

# ── 5. Parse metrics from tool output ───────────────────────────────────────

# LCP: match patterns like "LCP: 3100ms", "LCP 3100 ms", "LCP=3100"
LCP_ACTUAL=$(
  echo "$TOOL_OUTPUT" \
    | grep -oP 'LCP[:\s=]+\K[0-9]+\.?[0-9]*(?=\s*ms)?' 2>/dev/null \
    | tail -1 \
    || true
)

# CLS: match patterns like "CLS: 0.12", "CLS=0.12"
CLS_ACTUAL=$(
  echo "$TOOL_OUTPUT" \
    | grep -oP 'CLS[:\s=]+\K[0-9]+\.?[0-9]*' 2>/dev/null \
    | grep -vE '^[0-9]{4,}' \
    | tail -1 \
    || true
)

# INP: match patterns like "INP: 180ms", "INP=180"
INP_ACTUAL=$(
  echo "$TOOL_OUTPUT" \
    | grep -oP 'INP[:\s=]+\K[0-9]+\.?[0-9]*(?=\s*ms)?' 2>/dev/null \
    | tail -1 \
    || true
)

# JS bundle: match patterns like "200kb", "200 KB", "200kB" (excludes CSS/image lines)
JS_ACTUAL=$(
  echo "$TOOL_OUTPUT" \
    | grep -iv 'css\|image\|img\|font' \
    | grep -oP '[0-9]+\.?[0-9]*(?=\s*[kK][bB])' 2>/dev/null \
    | tail -1 \
    || true
)

# ── 6. Determine if we have any parseable metrics ───────────────────────────

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
CASTLE_DIR="$PROJECT_ROOT/.king/castle"
mkdir -p "$CASTLE_DIR"

# null-safe: use "null" literal for JSON when metric absent
_json_val() { [ -n "$1" ] && echo "$1" || echo "null"; }

LCP_JSON=$(_json_val "$LCP_ACTUAL")
CLS_JSON=$(_json_val "$CLS_ACTUAL")
INP_JSON=$(_json_val "$INP_ACTUAL")
JS_JSON=$(_json_val "$JS_ACTUAL")

# No parseable metrics — write missing status and exit 0 (first run / no baseline).
if [ "$LCP_JSON" = "null" ] && [ "$CLS_JSON" = "null" ] && [ "$INP_JSON" = "null" ] && [ "$JS_JSON" = "null" ]; then
  cat > "$CASTLE_DIR/perf-report.json" <<EOF
{
  "metrics": {
    "lcp_ms": null,
    "cls": null,
    "inp_ms": null,
    "js_kb": null
  },
  "budget_exceeded": false,
  "violations": [],
  "enforcement": "$ENFORCEMENT",
  "status": "missing",
  "checked_at": "$TIMESTAMP"
}
EOF
  exit 0
fi

# ── 7. Baseline handling ─────────────────────────────────────────────────────

BASELINE_FILE="$PROJECT_ROOT/.king/castle/perf-baseline.json"

if [ ! -f "$BASELINE_FILE" ]; then
  # First execution: write baseline and exit 0.
  cat > "$BASELINE_FILE" <<EOF
{
  "lcp_ms": $LCP_JSON,
  "cls": $CLS_JSON,
  "inp_ms": $INP_JSON,
  "js_kb": $JS_JSON,
  "created_at": "$TIMESTAMP"
}
EOF
  cat > "$CASTLE_DIR/perf-report.json" <<EOF
{
  "metrics": {
    "lcp_ms": $LCP_JSON,
    "cls": $CLS_JSON,
    "inp_ms": $INP_JSON,
    "js_kb": $JS_JSON
  },
  "budget_exceeded": false,
  "violations": [],
  "enforcement": "$ENFORCEMENT",
  "status": "pass",
  "checked_at": "$TIMESTAMP"
}
EOF
  echo "[King/Perf] Baseline created — future runs will compare against this baseline"
  exit 0
fi

# ── 8. Compare metrics vs budgets ───────────────────────────────────────────

VIOLATIONS_JSON=""
BUDGET_EXCEEDED=false

# Helper: compare integer metric vs budget
_check_int() {
  local metric_name="$1"
  local actual="$2"
  local budget="$3"
  if [ "$actual" != "null" ] && [ -n "$actual" ]; then
    # Validate numeric before awk to prevent injection.
    [[ "$actual" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 0
    [[ "$budget" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 0
    if awk "BEGIN { exit ($actual > $budget) ? 0 : 1 }"; then
      local delta
      delta=$(awk "BEGIN { printf \"%d\", $actual - $budget }")
      if [ -n "$VIOLATIONS_JSON" ]; then
        VIOLATIONS_JSON="$VIOLATIONS_JSON,"
      fi
      VIOLATIONS_JSON="${VIOLATIONS_JSON}
    { \"metric\": \"${metric_name}\", \"actual\": ${actual}, \"budget\": ${budget}, \"delta\": ${delta} }"
      BUDGET_EXCEEDED=true
    fi
  fi
}

# Helper: compare float metric vs budget (CLS)
_check_float() {
  local metric_name="$1"
  local actual="$2"
  local budget="$3"
  if [ "$actual" != "null" ] && [ -n "$actual" ]; then
    # Validate numeric before awk to prevent injection.
    [[ "$actual" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 0
    [[ "$budget" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 0
    if awk "BEGIN { exit ($actual > $budget) ? 0 : 1 }"; then
      local delta
      delta=$(awk "BEGIN { printf \"%.3f\", $actual - $budget }")
      if [ -n "$VIOLATIONS_JSON" ]; then
        VIOLATIONS_JSON="$VIOLATIONS_JSON,"
      fi
      VIOLATIONS_JSON="${VIOLATIONS_JSON}
    { \"metric\": \"${metric_name}\", \"actual\": ${actual}, \"budget\": ${budget}, \"delta\": ${delta} }"
      BUDGET_EXCEEDED=true
    fi
  fi
}

_check_int "lcp_ms"  "$LCP_ACTUAL"  "$LCP_BUDGET"
_check_float "cls"   "$CLS_ACTUAL"  "$CLS_BUDGET"
_check_int "inp_ms"  "$INP_ACTUAL"  "$INP_BUDGET"
_check_int "js_kb"   "$JS_ACTUAL"   "$JS_BUDGET"

STATUS="pass"
if [ "$BUDGET_EXCEEDED" = "true" ]; then
  STATUS="fail"
fi

# ── 9. Write perf-report.json ────────────────────────────────────────────────

cat > "$CASTLE_DIR/perf-report.json" <<EOF
{
  "metrics": {
    "lcp_ms": $LCP_JSON,
    "cls": $CLS_JSON,
    "inp_ms": $INP_JSON,
    "js_kb": $JS_JSON
  },
  "budget_exceeded": $BUDGET_EXCEEDED,
  "violations": [$VIOLATIONS_JSON
  ],
  "enforcement": "$ENFORCEMENT",
  "status": "$STATUS",
  "checked_at": "$TIMESTAMP"
}
EOF

# ── 10. Enforce or warn ──────────────────────────────────────────────────────

if [ "$STATUS" = "pass" ]; then
  exit 0
fi

# Budget exceeded — build violation message from first violation found.
FIRST_METRIC=$(echo "$VIOLATIONS_JSON" | grep -oP '"metric":\s*"\K[^"]+' | head -1 || true)
FIRST_ACTUAL=$(echo "$VIOLATIONS_JSON" | grep -oP '"actual":\s*\K[0-9.]+' | head -1 || true)
FIRST_BUDGET=$(echo "$VIOLATIONS_JSON" | grep -oP '"budget":\s*\K[0-9.]+' | head -1 || true)
FIRST_DELTA=$(echo "$VIOLATIONS_JSON" | grep -oP '"delta":\s*\K[0-9.]+' | head -1 || true)

if [ "$ENFORCEMENT" = "warn" ]; then
  # Audited bypass: log the event and exit 0 (non-blocking).
  AUDIT_DIR="$PROJECT_ROOT/.king/audit"
  mkdir -p "$AUDIT_DIR"
  AUDIT_LOG="$AUDIT_DIR/performance-bypass.log"
  echo "[$TIMESTAMP] BYPASS ${FIRST_METRIC}=${FIRST_ACTUAL} budget=${FIRST_BUDGET} delta=+${FIRST_DELTA} enforcement=warn" >> "$AUDIT_LOG"
  echo "[King/Perf] WARN: ${FIRST_METRIC}: ${FIRST_ACTUAL} > budget ${FIRST_BUDGET} (delta: +${FIRST_DELTA}) — logged to $AUDIT_LOG"
  exit 0
fi

# enforcement=block: emit structured error and exit 2.
echo "[King/Perf] BLOCKED: ${FIRST_METRIC}: ${FIRST_ACTUAL} > budget ${FIRST_BUDGET} (delta: +${FIRST_DELTA})"
exit 2
