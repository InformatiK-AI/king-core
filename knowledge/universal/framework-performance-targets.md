# Framework Performance Targets

Performance targets for King Framework core operations.
`HARD` targets block releases if exceeded. `SOFT` targets generate warnings only.

## Targets (v2.x)

| Metric | Target | Level | Measurement |
|--------|--------|-------|-------------|
| Hook execution p95 | < 50ms | HARD | OTel trace or `time` wrapper |
| Skill SKILL.md parse | < 200ms | SOFT | `time python -c "import yaml; yaml.safe_load(open(...))"` |
| `/genesis` end-to-end | < 60s | HARD | E2E test timer |
| Plugin install | < 30s | SOFT | Install script timer |
| Plugin size compressed | < 10MB | HARD | `zip -r /tmp/king.zip . && du -sh /tmp/king.zip` |

## OTel Self-Instrumentation (opt-in)

```bash
export KING_OTEL_ENABLED=1
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

When enabled, king-core emits spans for:
- `hook_execution` — each hook invocation
- `skill_load` — SKILL.md parse time
- `audit_phase_{N}` — each audit phase duration

Disable by unsetting `KING_OTEL_ENABLED` or setting it to `0`.

## Performance Regression Detection

Baseline metrics are stored in `.github/perf-baseline.json`.
The CI job `performance-benchmark` compares each run against the baseline.
A regression of +20% or more on any HARD target **blocks the PR**.

## Measuring Locally

```bash
# Run the benchmark suite
python tests/benchmarks/bench_score_calc.py

# Check plugin size
zip -r /tmp/king-core.zip skills/ src/ knowledge/ --exclude "**/__pycache__/*"
du -sh /tmp/king-core.zip

# Time a single audit-self run
time python scripts/audit_self.py --ci-threshold 80
```

## See Also

- `knowledge/universal/deprecation-policy.md` — deprecation timelines
- `.github/perf-baseline.json` — current baseline values
- `.github/workflows/framework-quality.yml` — CI benchmark job
