"""Snapshot test: score_calc output is stable across code changes.

Golden values are pre-calculated from the formula and embedded as constants.
Run `pytest --snapshot-update` (if a snapshot library is added) to regenerate.
Currently uses hardcoded golden values for zero-dependency stability.
"""
import json
from pathlib import Path
from src.score_calc import compute_subdim_scores, compute_health_score

SNAPSHOT_FILE = Path(__file__).parent / "audit_report_snapshot.json"

_KNOWN_INPUT = {
    "inventory":     {"I01": 0.9, "I02": 0.8, "I03": 0.0, "I04": 0.0},
    "format":        {"F01": 1.0, "F02": 1.0, "F03": 1.0, "F04": 1.0, "F05": 1.0},
    "cross_refs":    {"X01": 0.7, "X02": 0.6, "X03": 0.5, "X04": 0.0},
    "instructions":  {"Q01": 0.5, "Q02": 0.0, "Q03": 1.0, "Q04": 1.0},
    "communication": {"C01": 1.0, "C02": 0.8, "C03": 0.0, "C04": 0.5},
    "efficiency":    {"E01": 0.0, "E02": 0.0, "E03": 0.5, "E04": 0.5},
}

# Pre-calculated golden values (formula: SUBDIMENSIONS.md §7.1b)
# inventory:  (0.9*8 + 0.8*4 + 0*4 + 0*4) / 20 * 100 = 52.0
# format:     all 1.0 -> 100.0
# cross_refs: (0.7*7 + 0.6*5 + 0.5*4 + 0*4) / 20 * 100 = 49.5
# instructions: (0.5*5 + 0*4 + 1*3 + 1*3) / 15 * 100 = 56.6667
# communication: (1*5 + 0.8*4 + 0*3 + 0.5*3) / 15 * 100 = 64.6667
# efficiency: (0*3 + 0*3 + 0.5*2 + 0.5*2) / 10 * 100 = 20.0
# health = 52.0*0.20 + 100.0*0.20 + 49.5*0.20 + 56.6667*0.15 + 64.6667*0.15 + 20.0*0.10
#        = 10.4 + 20.0 + 9.9 + 8.5 + 9.7 + 2.0 = 60.5
_GOLDEN_SUBDIM = {
    "inventory": 52.0,
    "format": 100.0,
    "cross_refs": 49.5,
    "instructions": 56.66666666666667,
    "communication": 64.66666666666667,
    "efficiency": 20.0,
}
_GOLDEN_HEALTH = 60.5


def _compute():
    subdim = compute_subdim_scores(_KNOWN_INPUT)
    health = compute_health_score(subdim)
    return {"subdim_scores": subdim, "health_score": round(health, 4)}


def test_snapshot_matches():
    """Fail if formula output changes relative to stored snapshot."""
    current = _compute()
    if not SNAPSHOT_FILE.exists():
        SNAPSHOT_FILE.write_text(json.dumps(current, indent=2))
        return  # First run: write snapshot, pass

    stored = json.loads(SNAPSHOT_FILE.read_text())
    assert current["health_score"] == stored["health_score"], (
        f"health_score changed: stored={stored['health_score']}, "
        f"current={current['health_score']}"
    )
    for group in current["subdim_scores"]:
        assert abs(current["subdim_scores"][group] - stored["subdim_scores"][group]) < 0.001, \
            f"{group} score changed"


def test_golden_subdim_scores():
    """Assert each group score matches pre-calculated golden value."""
    subdim = compute_subdim_scores(_KNOWN_INPUT)
    for group, expected in _GOLDEN_SUBDIM.items():
        assert abs(subdim[group] - expected) < 0.001, (
            f"{group}: expected {expected:.4f}, got {subdim[group]:.4f}"
        )


def test_golden_health_score():
    """Assert health score matches pre-calculated golden value."""
    subdim = compute_subdim_scores(_KNOWN_INPUT)
    health = compute_health_score(subdim)
    assert abs(health - _GOLDEN_HEALTH) < 0.01, (
        f"health_score: expected {_GOLDEN_HEALTH}, got {health:.4f}"
    )
