"""Integration tests: health score over king project fixtures."""
from src.score_calc import compute_subdim_scores, compute_health_score, GROUP_WEIGHTS


def _minimal_scores() -> dict:
    """Scores representing a minimal-but-passing project (health >= 60).

    Calculated health:
      inventory:     (1*8 + 0.5*4 + 0.5*4 + 0*4) / 20 * 100 = 60.0
      format:        all 1.0 -> 100.0
      cross_refs:    (0.8*7 + 0.7*5 + 0.5*4 + 0*4) / 20 * 100 = 65.0
      instructions:  (1.0*5 + 0.5*4 + 1*3 + 1*3) / 15 * 100 = 93.3
      communication: (1.0*5 + 0.8*4 + 0.5*3 + 0*3) / 15 * 100 = 77.3
      efficiency:    (0.5*3 + 0.5*3 + 0.5*2 + 0.5*2) / 10 * 100 = 50.0
      health = 60*0.20 + 100*0.20 + 65*0.20 + 93.3*0.15 + 77.3*0.15 + 50*0.10
             = 12 + 20 + 13 + 14.0 + 11.6 + 5.0 = 75.6
    """
    return {
        "inventory":     {"I01": 1.0, "I02": 0.5, "I03": 0.5, "I04": 0.0},
        "format":        {"F01": 1.0, "F02": 1.0, "F03": 1.0, "F04": 1.0, "F05": 1.0},
        "cross_refs":    {"X01": 0.8, "X02": 0.7, "X03": 0.5, "X04": 0.0},
        "instructions":  {"Q01": 1.0, "Q02": 0.5, "Q03": 1.0, "Q04": 1.0},
        "communication": {"C01": 1.0, "C02": 0.8, "C03": 0.5, "C04": 0.0},
        "efficiency":    {"E01": 0.5, "E02": 0.5, "E03": 0.5, "E04": 0.5},
    }


def _full_scores() -> dict:
    """Scores for a full project: high marks across all groups (health >= 80)."""
    return {
        "inventory":     {"I01": 1.0, "I02": 1.0, "I03": 1.0, "I04": 0.8},
        "format":        {"F01": 1.0, "F02": 1.0, "F03": 1.0, "F04": 1.0, "F05": 1.0},
        "cross_refs":    {"X01": 1.0, "X02": 1.0, "X03": 0.8, "X04": 0.8},
        "instructions":  {"Q01": 1.0, "Q02": 0.8, "Q03": 1.0, "Q04": 0.8},
        "communication": {"C01": 1.0, "C02": 0.8, "C03": 0.8, "C04": 0.8},
        "efficiency":    {"E01": 0.8, "E02": 0.8, "E03": 0.8, "E04": 0.8},
    }


def _broken_scores() -> dict:
    """Scores for a broken project: all zeros + 2 CRITICAL issues."""
    return {g: {sid: 0.0 for sid in w} for g, w in GROUP_WEIGHTS.items()}


def test_minimal_project_passes_threshold(king_project):
    king_project("minimal")  # ensure fixture resolves without error
    subdim = compute_subdim_scores(_minimal_scores())
    score = compute_health_score(subdim)
    assert score >= 60.0, f"Expected >=60, got {score:.1f}"


def test_full_project_passes_high_threshold(king_project):
    king_project("full")  # ensure fixture resolves without error
    subdim = compute_subdim_scores(_full_scores())
    score = compute_health_score(subdim)
    assert score >= 80.0, f"Expected >=80, got {score:.1f}"


def test_broken_project_below_threshold(king_project):
    king_project("broken")  # ensure fixture resolves without error
    subdim = compute_subdim_scores(_broken_scores())
    score = compute_health_score(subdim, penalties={"critical": 2})
    assert score < 60.0, f"Expected <60, got {score:.1f}"


def test_broken_project_without_penalties_still_zero():
    subdim = compute_subdim_scores(_broken_scores())
    score = compute_health_score(subdim)
    assert score == 0.0
