#!/usr/bin/env bash
# hooks/coverage-emit.sh — King Framework M-12 Coverage Gate
#
# PostToolUse hook: evaluates test coverage after each Bash tool execution.
# Writes .king/castle/coverage-report.json and exits 0 (pass/warn) or 2 (block).
#
# STDIN FORMAT (PostToolUse):
#   Claude Code sends a JSON object to stdin when a tool completes.
#   The exact schema is empirically prototyped here — docs are incomplete.
#   We try multiple known field paths before falling back to raw stdin.
#   If none contain coverage data, we exit 0 silently (graceful degradation).
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

# ── 2. Detect coverage data ─────────────────────────────────────────────────

# Exit silently if the output has no coverage signals.
# Most Bash calls (git, file writes, etc.) produce no coverage data.
has_coverage_signal() {
  echo "$TOOL_OUTPUT" | grep -qiE 'coverage|PASS|FAIL|[0-9]+\.[0-9]+%' 2>/dev/null
}

if ! has_coverage_signal; then
  exit 0
fi

# ── 3. Extract coverage percentage ──────────────────────────────────────────

# Capture the last percentage-like number in the output.
# Using tail -1 because runners typically emit a summary line at the end
# (e.g., "All files | 85.23 | ...").
COVERAGE_PCT=$(
  echo "$TOOL_OUTPUT" \
    | grep -oP '[0-9]+\.?[0-9]*(?=%)' 2>/dev/null \
    | tail -1 \
    || true
)

if [ -z "$COVERAGE_PCT" ]; then
  # Output had coverage keywords but no parseable percentage — skip silently.
  exit 0
fi

# ── 4. Read threshold config ─────────────────────────────────────────────────

# Resolve project root (where .king/ lives) relative to cwd.
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

COVERAGE_YAML="$PROJECT_ROOT/.king/coverage.yaml"

THRESHOLD=80
ENFORCEMENT="block"

if [ -f "$COVERAGE_YAML" ]; then
  # Parse with yq if available; fall back to simple grep for bare scalar values.
  if command -v yq &>/dev/null; then
    THRESHOLD=$(yq e '.thresholds.global // 80' "$COVERAGE_YAML" 2>/dev/null || echo "80")
    ENFORCEMENT=$(yq e '.thresholds.enforcement // "block"' "$COVERAGE_YAML" 2>/dev/null || echo "block")
  else
    # Minimal grep fallback — handles "global: 80" style lines only.
    GLOBAL_LINE=$(grep -E '^\s*global\s*:' "$COVERAGE_YAML" 2>/dev/null | tail -1 || true)
    if [ -n "$GLOBAL_LINE" ]; then
      THRESHOLD=$(echo "$GLOBAL_LINE" | grep -oP '[0-9]+' | head -1 || echo "80")
    fi
    ENF_LINE=$(grep -E '^\s*enforcement\s*:' "$COVERAGE_YAML" 2>/dev/null | tail -1 || true)
    if [ -n "$ENF_LINE" ]; then
      ENFORCEMENT=$(echo "$ENF_LINE" | grep -oP '(block|warn)' | head -1 || echo "block")
    fi
  fi
fi

# ── 5. Compute delta and status ──────────────────────────────────────────────

# Guard against injection: validate both values are pure floats before awk arithmetic.
[[ "$COVERAGE_PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "[King/Coverage] WARN: unparseable coverage value — skipping gate"; exit 0; }
[[ "$THRESHOLD"    =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "[King/Coverage] WARN: invalid threshold in config — skipping gate"; exit 0; }

# Arithmetic in bash requires integer ops; use awk for floats.
DELTA=$(awk "BEGIN { printf \"%.1f\", $COVERAGE_PCT - $THRESHOLD }")
STATUS="pass"
if awk "BEGIN { exit ($COVERAGE_PCT < $THRESHOLD) ? 0 : 1 }"; then
  STATUS="fail"
fi

# ── 6. Write coverage-report.json ───────────────────────────────────────────

CASTLE_DIR="$PROJECT_ROOT/.king/castle"
mkdir -p "$CASTLE_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$CASTLE_DIR/coverage-report.json" <<EOF
{
  "coverage": $COVERAGE_PCT,
  "threshold": $THRESHOLD,
  "status": "$STATUS",
  "delta": $DELTA,
  "timestamp": "$TIMESTAMP"
}
EOF

# ── 7. Enforce or warn ───────────────────────────────────────────────────────

if [ "$STATUS" = "pass" ]; then
  exit 0
fi

# Coverage is below threshold.

if [ "$ENFORCEMENT" = "warn" ]; then
  # Audited bypass: log the event and exit 0 (non-blocking).
  AUDIT_DIR="$PROJECT_ROOT/.king/audit"
  mkdir -p "$AUDIT_DIR"
  AUDIT_LOG="$AUDIT_DIR/coverage-bypass.log"
  echo "[$TIMESTAMP] BYPASS coverage=${COVERAGE_PCT}% threshold=${THRESHOLD}% delta=${DELTA}% enforcement=warn" >> "$AUDIT_LOG"
  echo "[King/Coverage] WARN: Coverage ${COVERAGE_PCT}% < required ${THRESHOLD}% (delta: ${DELTA}%) — logged to $AUDIT_LOG"
  exit 0
fi

# enforcement=block: emit structured error with top-10 uncovered lines and exit 2.
echo "[King/Coverage] BLOCKED: Coverage ${COVERAGE_PCT}% < required ${THRESHOLD}% (delta: ${DELTA}%)"

# Extract up to 10 uncovered file:line pairs from test output.
# Covers common formats: Go (file.go:45), Istanbul (|  45 |), pytest-cov (file.py  45-82)
UNCOVERED=$(
  echo "$TOOL_OUTPUT" | grep -oP '[\w./\-]+\.(go|ts|tsx|js|jsx|py|rb|java|kt)\s*:\s*[0-9]+' 2>/dev/null \
  | head -10 \
  | sed 's/[[:space:]]//g' \
  || true
)

if [ -n "$UNCOVERED" ]; then
  echo "[King/Coverage] Uncovered lines (top 10):"
  echo "$UNCOVERED" | while IFS= read -r line; do
    echo "  • $line"
  done
fi

exit 2
