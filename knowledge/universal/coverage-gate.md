# Coverage Gate (M-12)

## What It Is

The Coverage Gate is the **T (Testing)** pillar of the CASTLE quality framework.
It enforces numeric test coverage thresholds automatically via a `PostToolUse` hook
(`hooks/coverage-emit.sh`) that fires whenever Claude Code runs a Bash tool. If the
output contains coverage metrics, the hook compares the result against the project's
`.king/coverage.yaml` configuration and writes `.king/castle/coverage-report.json`.

The `/castle-report` command (M-34) reads that JSON to compute the CASTLE aggregate score.

## `.king/coverage.yaml` Schema

| Field | Type | Default | Description |
|---|---|---|---|
| `thresholds.global` | integer | `80` | Minimum % coverage for the whole project. |
| `thresholds.per_package` | map | `{}` | Per-directory overrides (e.g. `src/core: 95`). |
| `thresholds.per_branch_type` | map | see template | Different thresholds by git branch prefix. |
| `thresholds.enforcement` | `block\|warn` | `block` | `block` exits 2 and stops the operation; `warn` logs and exits 0. |
| `thresholds.exclude` | list | see template | Glob patterns excluded from the coverage count. |
| `audit.log` | path | `.king/audit/coverage-bypass.log` | File where audited bypasses are recorded. |
| `audit.require_justification` | bool | `true` | Whether the bypass log must include a reason. |

## Defaults and When to Change Them

- **`global: 80`** is a safe default for most projects. Raise to 90+ for financial or security-critical modules.
- **`per_package`** should override `global` for isolated critical paths (e.g., `src/payments: 95`) rather than raising the global threshold, which can penalize low-value glue code.
- **`per_branch_type.hotfix: 70`** relaxes the gate on emergency fixes to avoid slowing down incident response.
- **`per_branch_type.release: 90`** tightens the gate before promotion to production.

## Audited Bypass

When `enforcement: warn`, the gate does NOT block — it logs the event:

```
[2025-05-28T14:00:00Z] BYPASS coverage=72.3% threshold=80% delta=-7.7% enforcement=warn
```

The log lives at `.king/audit/coverage-bypass.log`. A bypass is not an error;
it is a deliberate, traceable decision. Audits enable retrospectives: if the same
file bypasses every sprint, that is a technical debt signal, not a policy gap.

## Anti-Patterns

- **Excluding too much**: every exclusion hides real risk. Keep `exclude` to generated code, mocks, and test fixtures only.
- **Threshold too low**: a `global: 40` threshold provides false confidence. Start at 80; lower only for legacy codebases with a documented migration plan.
- **`enforcement: warn` permanently**: warn mode is for onboarding, not steady state. Flip to `block` once the baseline is established.
- **No audit log review**: bypasses without periodic review become invisible debt. Include bypass log analysis in sprint retrospectives.
- **Raising threshold without baseline**: jumping from 60% to 95% in one PR breaks CI for the whole team. Raise incrementally (5% per sprint).
