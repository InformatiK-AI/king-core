"""Unit tests for src/score_calc.py."""
import pytest
from src.score_calc import (
    compute_subdim_scores,
    compute_health_score,
    GROUP_WEIGHTS,
    DIMENSION_WEIGHTS,
)


def _all_ones() -> dict:
    return {g: {sid: 1.0 for sid in w} for g, w in GROUP_WEIGHTS.items()}


def _all_zeros() -> dict:
    return {g: {sid: 0.0 for sid in w} for g, w in GROUP_WEIGHTS.items()}


class TestComputeSubdimScores:
    def test_all_ones_gives_100_per_group(self):
        scores = compute_subdim_scores(_all_ones())
        for group in GROUP_WEIGHTS:
            assert scores[group] == pytest.approx(100.0)

    def test_all_zeros_gives_0_per_group(self):
        scores = compute_subdim_scores(_all_zeros())
        for group in GROUP_WEIGHTS:
            assert scores[group] == pytest.approx(0.0)

    def test_f04_none_uses_denominator_17(self):
        """F04=None -> format_score = (rest of format scores * weights) / 17 * 100."""
        scores = _all_ones()
        scores["format"]["F04"] = None
        result = compute_subdim_scores(scores)
        # F01*5 + F02*5 + F03*4 + F05*3 = 5+5+4+3 = 17; /17 * 100 = 100
        assert result["format"] == pytest.approx(100.0)

    def test_f04_none_partial_format(self):
        """F04=None + F01=0.5 -> (0.5*5 + 1*5 + 1*4 + 1*3) / 17 * 100."""
        scores = {g: {sid: 1.0 for sid in w} for g, w in GROUP_WEIGHTS.items()}
        scores["format"]["F04"] = None
        scores["format"]["F01"] = 0.5
        result = compute_subdim_scores(scores)
        expected = (0.5 * 5 + 1 * 5 + 1 * 4 + 1 * 3) / 17 * 100
        assert result["format"] == pytest.approx(expected)

    def test_non_format_none_treated_as_zero(self):
        """None in non-format group contributes 0 (weight stays in denom)."""
        scores = _all_ones()
        scores["inventory"]["I01"] = None
        result = compute_subdim_scores(scores)
        # I01=0, rest=1: (0*8 + 1*4 + 1*4 + 1*4) / 20 * 100 = 12/20*100 = 60
        assert result["inventory"] == pytest.approx(60.0)


class TestComputeHealthScore:
    def test_all_100_gives_100(self):
        scores = {g: 100.0 for g in DIMENSION_WEIGHTS}
        assert compute_health_score(scores) == pytest.approx(100.0)

    def test_all_0_gives_0(self):
        scores = {g: 0.0 for g in DIMENSION_WEIGHTS}
        assert compute_health_score(scores) == pytest.approx(0.0)

    def test_critical_penalty_applies(self):
        scores = {g: 100.0 for g in DIMENSION_WEIGHTS}
        result = compute_health_score(scores, penalties={"critical": 1})
        assert result == pytest.approx(90.0)

    def test_clamps_to_zero_on_excessive_penalty(self):
        scores = {g: 10.0 for g in DIMENSION_WEIGHTS}
        result = compute_health_score(scores, penalties={"critical": 10})
        assert result == pytest.approx(0.0)

    def test_clamps_to_100_on_overflow(self):
        scores = {g: 110.0 for g in DIMENSION_WEIGHTS}  # impossible but defensive
        result = compute_health_score(scores)
        assert result == pytest.approx(100.0)

    def test_penalties_default_to_zero(self):
        """No penalties passed -> no deduction."""
        scores = {g: 50.0 for g in DIMENSION_WEIGHTS}
        result_no_penalties = compute_health_score(scores)
        result_explicit_zero = compute_health_score(scores, penalties={})
        assert result_no_penalties == pytest.approx(result_explicit_zero)

    def test_high_and_medium_penalties(self):
        """high*3 + medium*1 applied correctly."""
        scores = {g: 100.0 for g in DIMENSION_WEIGHTS}
        result = compute_health_score(scores, penalties={"high": 2, "medium": 3})
        # penalty = 2*3 + 3*1 = 9
        assert result == pytest.approx(91.0)

    def test_dimension_weights_sum_to_1(self):
        assert sum(DIMENSION_WEIGHTS.values()) == pytest.approx(1.0)
