"""Health-score formula for King Framework audit.

Weights per skills/audit/SUBDIMENSIONS.md (M-69/M-71).
F04 null-exclusion: denominator drops to 17 when api_version absent.

Sub-dim ID mapping: bare IDs (I01, F04) == hyphenated IDs (I-01, F-04).
"""
from __future__ import annotations

# Sub-dim ID -> weight (bare IDs match SUBDIMENSIONS.md notation without hyphens)
GROUP_WEIGHTS: dict[str, dict[str, int]] = {
    "inventory":      {"I01": 8, "I02": 4, "I03": 4, "I04": 4},
    "format":         {"F01": 5, "F02": 5, "F03": 4, "F04": 3, "F05": 3},
    "cross_refs":     {"X01": 7, "X02": 5, "X03": 4, "X04": 4},
    "instructions":   {"Q01": 5, "Q02": 4, "Q03": 3, "Q04": 3},
    "communication":  {"C01": 5, "C02": 4, "C03": 3, "C04": 3},
    "efficiency":     {"E01": 3, "E02": 3, "E03": 2, "E04": 2},
}

# Each group's contribution to the final blended score
DIMENSION_WEIGHTS: dict[str, float] = {
    "inventory": 0.20,
    "format": 0.20,
    "cross_refs": 0.20,
    "instructions": 0.15,
    "communication": 0.15,
    "efficiency": 0.10,
}

# F04 null-exclusion: when F04 is None, use this denominator
_FORMAT_FULL_DENOM = 20
_FORMAT_NULL_F04_DENOM = 17  # F04 weight (3) dropped from denominator


def compute_subdim_scores(
    scores_by_group: dict[str, dict[str, float | None]],
) -> dict[str, float]:
    """Weighted-sum each group to a 0-100 score.

    None scores drop their weight from the denominator.
    F04=None -> format denominator becomes 17.
    Other None sub-dims -> contribute 0 (their weight remains in denominator).
    """
    result: dict[str, float] = {}
    for group, weights in GROUP_WEIGHTS.items():
        group_scores = scores_by_group.get(group, {})

        if group == "format":
            f04_score = group_scores.get("F04")
            denom = _FORMAT_NULL_F04_DENOM if f04_score is None else _FORMAT_FULL_DENOM
            total = 0.0
            for sid, w in weights.items():
                if sid == "F04" and f04_score is None:
                    continue  # excluded from numerator when None
                score = group_scores.get(sid, 0.0)
                total += (score or 0.0) * w
            result[group] = (total / denom) * 100
        else:
            denom = sum(weights.values())
            total = sum(
                (group_scores.get(sid, 0.0) or 0.0) * w
                for sid, w in weights.items()
            )
            result[group] = (total / denom) * 100

    return result


def compute_health_score(
    subdim_scores: dict[str, float],
    penalties: dict[str, int] | None = None,
) -> float:
    """Blend group scores and subtract penalties.

    Formula: base = sum(subdim_scores[g] * DIMENSION_WEIGHTS[g])
    Penalties: critical*10 + high*3 + medium*1
    Returns: max(0.0, min(100.0, base - penalty))
    """
    if penalties is None:
        penalties = {}

    base = sum(
        subdim_scores.get(group, 0.0) * w
        for group, w in DIMENSION_WEIGHTS.items()
    )
    penalty = (
        penalties.get("critical", 0) * 10
        + penalties.get("high", 0) * 3
        + penalties.get("medium", 0) * 1
    )
    return max(0.0, min(100.0, base - penalty))
