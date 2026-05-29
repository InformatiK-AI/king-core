---
name: trends
part-of: audit
---

# Audit Trends Engine

> Archivo parte de: `skills/audit/SKILL.md`
> Activo en Phase 7 en todas las ejecuciones (excepto `--dry-run`). Para baseline diff, solo si `--compare-baseline {tag}` presente.

---

## trends.json Schema

**Path**: `.king/docs/audits/trends.json`

```json
{
  "entries": [
    {
      "timestamp": "2026-05-28T14:30:00Z",
      "health_score": 87.5,
      "tag": "v1.9.3",
      "subdimensions": {
        "I-01": 1.0,
        "I-02": 0.8,
        "I-03": 1.0,
        "I-04": 1.0,
        "F-01": 0.9,
        "F-02": 1.0,
        "F-03": 1.0,
        "F-04": null,
        "F-05": 0.9,
        "X-01": 0.85,
        "X-02": 1.0,
        "X-03": 0.75,
        "X-04": 1.0,
        "Q-01": 1.0,
        "Q-02": 0.9,
        "Q-03": 0.8,
        "Q-04": 1.0,
        "C-01": 1.0,
        "C-02": 0.8,
        "C-03": 0.9,
        "C-04": 0.7,
        "E-01": 1.0,
        "E-02": 0.5,
        "E-03": 1.0,
        "E-04": 0.5
      },
      "flags": {
        "scope": "full",
        "focus": "all",
        "ci_threshold": null,
        "baseline_tag": null,
        "auto_fix_applied": []
      }
    }
  ]
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | string (ISO 8601 UTC) | Yes | Exact time audit completed, e.g. `"2026-05-28T14:30:00Z"` |
| `health_score` | number (0.00–100.00) | Yes | Final health score after penalties |
| `tag` | string | No | Optional label set by `--tag {value}` or `--compare-baseline` reference |
| `subdimensions` | object | Yes | Map of 25 sub-dim IDs to scores (0.00–1.00). F-04 value is `null` (WARNING-only) |
| `flags.scope` | string | Yes | Value of `--scope` used (`full` or `quick`) |
| `flags.focus` | string | Yes | Value of `--focus` used |
| `flags.ci_threshold` | number or null | Yes | Value of `--ci-threshold {N}`, or `null` if flag not passed |
| `flags.baseline_tag` | string or null | Yes | Value of `--compare-baseline {tag}`, or `null` if not passed |
| `flags.auto_fix_applied` | array of sub-dim IDs | Yes | Sub-dims re-scored after `--auto-fix`; `[]` if flag not passed |

---

## Write Algorithm (prepend)

> Executed in Phase 7.1c on every audit run (unless `--dry-run` is active)

```
1. Resolve path: .king/docs/audits/trends.json

2. If file does not exist:
   a. Create directory .king/docs/audits/ if absent (mkdir -p)
   b. Initialize file: { "entries": [] }

3. Read file content → parse as JSON → get entries array

4. Build new entry object:
   {
     "timestamp": <current UTC ISO 8601>,
     "health_score": <computed health_score>,
     "tag": <value of --tag flag, or omit field if not passed>,
     "subdimensions": {
       "I-01": <score>, ..., "F-04": null, ..., "E-04": <score>
     },
     "flags": {
       "scope": <--scope value>,
       "focus": <--focus value>,
       "ci_threshold": <N or null>,
       "baseline_tag": <tag or null>,
       "auto_fix_applied": [<sub-dim IDs> or []]
     }
   }

5. Prepend: entries.unshift(newEntry)
   Result: new entry is at entries[0]; all previous entries shift right

6. Write back: JSON.stringify({ "entries": entries }, null, 2) → trends.json

7. Do NOT truncate. Do NOT cap entries. Accumulate indefinitely.
```

---

## Baseline Diff Algorithm

> Executed in Phase 7.1d when `--compare-baseline {tag}` is passed

```
1. Parse argument: extract {tag} from --compare-baseline

2. Read .king/docs/audits/trends.json
   - If file absent or empty: ERROR "trends.json not found — no baseline available"

3. Search entries[] for the most recent entry where entry.tag === {tag}
   - "Most recent" = lowest index in entries[] (prepend storage = entries[0] is newest)

4. If no matching entry found:
   ERROR: "Baseline tag '{tag}' not found in trends.json"
   - Exit with status code 1 (non-zero)
   - Error is non-blocking: audit report is still written, error appended to report

5. Compute delta per sub-dimension:
   delta_i = current_score_i - baseline_score_i
   - If baseline_score_i is null (F-04): delta = "N/A"
   - If current_score_i is null (F-04): delta = "N/A"

6. Compute overall delta:
   health_score_delta = current_health_score - baseline_health_score

7. Classify trend per sub-dim:
   delta > 0  → ↑ (improvement)
   delta < 0  → ↓ (regression)
   delta == 0 → → (unchanged)

8. Output diff table (appended to audit report):
```

### Baseline Diff Output Format

```markdown
## Baseline Diff — vs. {tag}

**Baseline timestamp**: {baseline entry timestamp}
**Baseline health_score**: {baseline_health_score}%
**Current health_score**: {current_health_score}%
**Delta**: {health_score_delta:+.2f}%

| ID | Name | Baseline | Current | Delta | Trend |
|----|------|----------|---------|-------|-------|
| I-01 | metadata-completeness | 0.80 | 0.90 | +0.10 | ↑ |
| I-02 | description-quality | 0.50 | 0.50 | 0.00 | → |
| I-03 | author-present | 1.00 | 1.00 | 0.00 | → |
| I-04 | license-declared | 0.00 | 1.00 | +1.00 | ↑ |
| F-01 | directory-structure | 1.00 | 0.80 | -0.20 | ↓ |
| F-04 | api-version-present | N/A | N/A | N/A | — |
| ... | ... | ... | ... | ... | ... |
```

---

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `trends.json` does not exist on first run | Create with `{ "entries": [] }`, then write first entry |
| `trends.json` is malformed JSON | Log error, do NOT overwrite; skip trends write for this run |
| `--compare-baseline {tag}` and tag not found | Emit error message, exit non-zero, append error to report, continue |
| `--dry-run` active | Skip all writes. Log "Would write to trends.json" with entry preview |

---

## Storage Notes

- **No cap**: entries accumulate indefinitely. Historical memory is the goal.
- **Git-versioned**: `trends.json` is committed with the repo (recommended). Provides PR-level visibility into health trend.
- **Reading latest entry**: always `entries[0]` (prepend order).
- **Reading by tag**: iterate from `entries[0]` forward; first match wins.
