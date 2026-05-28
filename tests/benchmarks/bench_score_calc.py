"""Performance benchmarks for src/ modules.

Run directly: python tests/benchmarks/bench_score_calc.py
Or as pytest: pytest tests/benchmarks/ -v (no coverage required)
"""
from __future__ import annotations
import json
import sys
import time
from pathlib import Path

# Ensure project root is on path when run directly
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.score_calc import compute_subdim_scores, compute_health_score, GROUP_WEIGHTS
from src.semver import parse_semver

BASELINE_FILE = Path(__file__).parent.parent.parent / ".github" / "perf-baseline.json"
REGRESSION_THRESHOLD_PCT = 20


def _all_ones() -> dict:
    return {g: {sid: 1.0 for sid in w} for g, w in GROUP_WEIGHTS.items()}


def bench_score_calc_1000() -> float:
    """Time 1000 full health-score computations. Returns ms."""
    scores = _all_ones()
    start = time.perf_counter()
    for _ in range(1000):
        subdim = compute_subdim_scores(scores)
        compute_health_score(subdim)
    elapsed_ms = (time.perf_counter() - start) * 1000
    return elapsed_ms


def bench_semver_10000() -> float:
    """Time 10000 semver parse operations. Returns ms."""
    versions = ["1.0.0", "2.3.1", "0.0.1", "10.20.30", "1.2.3"]
    start = time.perf_counter()
    for i in range(10000):
        parse_semver(versions[i % len(versions)])
    elapsed_ms = (time.perf_counter() - start) * 1000
    return elapsed_ms


def run_benchmarks() -> dict[str, float]:
    results = {
        "score_calc_1000_iterations_ms": round(bench_score_calc_1000(), 2),
        "semver_parse_10000_iterations_ms": round(bench_semver_10000(), 2),
    }
    return results


def check_regressions(results: dict[str, float]) -> list[str]:
    regressions = []
    if not BASELINE_FILE.exists():
        return regressions
    baseline = json.loads(BASELINE_FILE.read_text())
    metrics = baseline.get("metrics", {})
    threshold = baseline.get("_threshold_regression_pct", REGRESSION_THRESHOLD_PCT)
    for key, current in results.items():
        if key in metrics:
            baseline_val = metrics[key]
            if baseline_val > 0:
                pct_change = ((current - baseline_val) / baseline_val) * 100
                if pct_change > threshold:
                    regressions.append(
                        f"{key}: {baseline_val}ms -> {current}ms "
                        f"(+{pct_change:.1f}% > {threshold}% threshold)"
                    )
    return regressions


if __name__ == "__main__":
    print("Running benchmarks...")
    results = run_benchmarks()
    for key, val in results.items():
        print(f"  {key}: {val}ms")

    regressions = check_regressions(results)
    if regressions:
        print("\nWARN: REGRESSIONS DETECTED:")
        for r in regressions:
            print(f"  {r}")
        raise SystemExit(1)
    else:
        print("\nNo regressions detected.")
