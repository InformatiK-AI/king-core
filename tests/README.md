# Tests — King Framework Test Suite

## Running Tests

```bash
# Full test suite with coverage
python -m pytest tests/ --cov=src --cov-fail-under=80 -v

# Specific layer
python -m pytest tests/unit/ -v
python -m pytest tests/integration/ -v
python -m pytest tests/snapshots/ -v
```

## Performance Benchmarks

```bash
# Run benchmarks directly
python tests/benchmarks/bench_score_calc.py

# Run audit self-check
python scripts/audit_self.py --ci-threshold 80
```

Benchmarks compare against `.github/perf-baseline.json`.
A regression > 20% on any HARD metric exits with code 1.

## Test Layers

| Layer | Path | Purpose |
|-------|------|---------|
| Unit | `tests/unit/` | Pure function tests |
| Integration | `tests/integration/` | End-to-end logic |
| Snapshots | `tests/snapshots/` | Golden value regression |
| Benchmarks | `tests/benchmarks/` | Performance timing |

## Fixtures

`tests/fixtures/` contains:
- `minimal-king-project/` — passing, health >= 60
- `full-king-project/` — high quality, health >= 80
- `broken-king-project/` — intentionally broken, health < 60
