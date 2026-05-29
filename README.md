# King Framework Core (king-core)

King Framework plugin providing 51 skills for the complete SDLC pipeline.

## Local Quality Gates

```bash
# Run full test suite
python -m pytest tests/ --cov=src --cov-fail-under=80 -v

# Run self-audit (health score)
python scripts/audit_self.py --ci-threshold 80

# Run benchmarks
python tests/benchmarks/bench_score_calc.py

# Lint Python sources
pip install ruff && ruff check src/ scripts/ tests/

# Install pre-commit hooks
pip install pre-commit && pre-commit install
pre-commit run --all-files
```

## Architecture

- `skills/` — 51 King skills (SKILL.md + sub-files)
- `src/` — Python modules: score_calc, semver, changelog_formatter
- `tests/` — pytest suite: unit, integration, snapshots, benchmarks
- `scripts/` — automation tools: audit_self.py, add_api_version.py
- `knowledge/` — framework knowledge docs
- `.github/workflows/` — CI/CD pipeline

## CI Pipeline

| Job | What it checks |
|-----|----------------|
| `test-suite` | pytest + coverage >= 80% |
| `lint-format` | ruff + markdownlint |
| `security-scan` | semgrep |
| `license-check` | pip-audit |
| `performance-benchmark` | timing regression vs baseline |
| `audit-self` | health score >= 80% |
