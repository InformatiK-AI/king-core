"""Unit tests for src/semver.py."""
import pytest
from src.semver import is_valid_semver, parse_semver


@pytest.mark.parametrize("s", ["1.0.0", "2.3.1", "0.0.1", "10.20.30", "0.0.0"])
def test_valid_semver(s):
    assert is_valid_semver(s) is True


@pytest.mark.parametrize("s", ["1.0", "1.0.0.0", "abc", "", "1.0.a", "01.0.0"])
def test_invalid_semver(s):
    assert is_valid_semver(s) is False


def test_parse_semver_returns_tuple():
    assert parse_semver("1.2.3") == (1, 2, 3)


def test_parse_semver_zero_version():
    assert parse_semver("0.0.0") == (0, 0, 0)


def test_parse_semver_large_numbers():
    assert parse_semver("10.20.30") == (10, 20, 30)


def test_parse_semver_raises_on_invalid():
    with pytest.raises(ValueError):
        parse_semver("not-semver")


def test_parse_semver_raises_on_leading_zero():
    with pytest.raises(ValueError):
        parse_semver("01.0.0")
