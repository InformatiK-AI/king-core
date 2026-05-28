# Spec: audit-trends

**Capability**: audit-trends
**Status**: NEW
**RFC**: 2119 language applies throughout

---

## Summary

Every audit execution MUST append a structured entry to `.king/docs/audits/trends.json`. The `--compare-baseline {tag}` flag MUST produce a per-sub-dimension diff against a previously tagged entry. Entries accumulate; the file is never truncated.

---

## Requirements

### R1 — Append on every execution
Every audit execution MUST append one entry to `.king/docs/audits/trends.json`. If the file does not exist, the audit MUST create it with the first entry.

### R2 — Entry schema
Each entry MUST include:
- `timestamp`: ISO 8601 UTC string (e.g., `"2026-05-28T14:30:00Z"`)
- `health_score`: numeric value (0.00–100.00)
- `subdimensions`: object mapping each sub-dimension ID to its score (0.00–1.00); F-04 value is `null`
- `flags`: object with named fields (`scope`, `focus`, `ci_threshold`, `baseline_tag`, `auto_fix_applied`, `tag`) reflecting the flags used in this invocation
- `tag`: optional string, present only when `--tag {value}` was passed

### R3 — Baseline comparison
When `--compare-baseline {tag}` is passed, the audit MUST:
1. Locate the most recent entry in trends.json where `tag` equals the provided value
2. Compute a diff for each sub-dimension: `current_score - baseline_score`
3. Include in output: sub-dimension ID, current score, baseline score, delta (positive = improvement, negative = regression)

### R4 — Tag not found error
When `--compare-baseline {tag}` is passed and no entry with that tag exists in trends.json, the audit MUST exit with a non-zero status and MUST print a descriptive error message identifying the missing tag.

### R5 — Accumulative storage
The trends.json file MUST only be appended to. Existing entries MUST NOT be modified or deleted by any audit operation.

---

## Acceptance Scenarios

### Scenario 1 — Three executions produce three accumulated entries

**Given** a plugin with no existing trends.json
**When** audit is run three times in sequence (with any flags)
**Then** trends.json MUST contain exactly three entries
**And** each entry MUST include timestamp, health_score, subdimensions object with 25 keys, and flags object
**And** entries MUST appear in chronological order (ascending timestamp)

### Scenario 2 — Baseline diff shows improvements and regressions

**Given** trends.json contains an entry with `"tag": "v1.0"` and a lower health_score than the current state
**When** audit is run with `--compare-baseline v1.0`
**Then** the output MUST include a comparison table with one row per sub-dimension
**And** sub-dimensions that improved MUST show a positive delta
**And** sub-dimensions that regressed MUST show a negative delta
**And** unchanged sub-dimensions MUST show a delta of 0.00

### Scenario 3 — Missing tag produces descriptive error

**Given** trends.json exists but contains no entry with `"tag": "v2.0"`
**When** audit is run with `--compare-baseline v2.0`
**Then** the command MUST exit with a non-zero status code
**And** the error output MUST state that tag "v2.0" was not found in trends.json
