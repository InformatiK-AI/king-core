"""Semantic versioning utilities for King Framework skill api_version field."""
from __future__ import annotations
import re

_SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def is_valid_semver(s: str) -> bool:
    """Return True iff *s* is a valid MAJOR.MINOR.PATCH semver string."""
    return bool(_SEMVER_RE.match(s))


def parse_semver(s: str) -> tuple[int, int, int]:
    """Parse *s* into (major, minor, patch).

    Raises ValueError if *s* is not valid semver.
    """
    m = _SEMVER_RE.match(s)
    if not m:
        raise ValueError(f"Not a valid semver string: {s!r}")
    return int(m.group(1)), int(m.group(2)), int(m.group(3))
