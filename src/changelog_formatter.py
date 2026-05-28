"""Keep a Changelog formatter for King Framework /release.

Maps conventional commit types to Keep a Changelog categories.
Pure functions — zero I/O, zero subprocess. Follows score_calc.py conventions.
"""
from __future__ import annotations
import re
from datetime import date

# Authoritative commit-type → Keep a Changelog category mapping (spec R1)
COMMIT_TYPE_MAP: dict[str, str] = {
    "feat":       "Added",
    "fix":        "Fixed",
    "security":   "Security",
    "deprecate":  "Deprecated",
    "remove":     "Removed",
    # All others (refactor, chore, perf, docs, test, build, ci, style) → Changed
}

# Keep a Changelog canonical category order
CATEGORY_ORDER = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"]

_COMMIT_RE = re.compile(
    r"^(?P<hash>[0-9a-f]+)\s+"
    r"(?P<type>[a-z]+)"
    r"(?:\([^)]+\))?"          # optional scope
    r"(?P<breaking>!)?"        # optional ! for breaking
    r":\s*"
    r"(?P<desc>.+)$"
)

_BREAKING_FOOTER_RE = re.compile(r"BREAKING[ -]CHANGE:\s*(.+)", re.IGNORECASE)


def parse_commits(log_lines: list[str]) -> dict[str, list[str]]:
    """Parse git log lines into Keep a Changelog categories.

    Input format per line: "{hash} {type}[({scope})][!]: {description}"
    Lines that do not match the commit pattern are treated as body text for
    the preceding commit (e.g. BREAKING CHANGE footer lines).
    BREAKING CHANGE in body/footer → prefixes description with "⚠️ BREAKING: ".
    Returns only non-empty categories (spec R2 SHOULD omit empty).
    """
    categories: dict[str, list[str]] = {c: [] for c in CATEGORY_ORDER}

    # Build commit blocks: each new subject line that matches _COMMIT_RE starts
    # a new block; non-matching lines (including blank lines) accumulate as body.
    blocks: list[tuple[str, str]] = []  # (subject, body)
    current_subject: str | None = None
    current_body_lines: list[str] = []

    for line in log_lines:
        stripped = line.strip()
        if _COMMIT_RE.match(stripped):
            # Flush previous commit if any
            if current_subject is not None:
                blocks.append((current_subject, "\n".join(current_body_lines)))
            current_subject = stripped
            current_body_lines = []
        else:
            # Body line (including blank lines)
            if current_subject is not None:
                current_body_lines.append(stripped)

    # Flush last commit
    if current_subject is not None:
        blocks.append((current_subject, "\n".join(current_body_lines)))

    for subject, body in blocks:
        m = _COMMIT_RE.match(subject)
        if not m:
            continue

        commit_type = m.group("type")
        is_breaking = bool(m.group("breaking"))
        description = m.group("desc")

        # Check body for BREAKING CHANGE footer
        breaking_match = _BREAKING_FOOTER_RE.search(body)
        if breaking_match or is_breaking:
            description = f"⚠️ BREAKING: {description}"

        category = COMMIT_TYPE_MAP.get(commit_type, "Changed")
        categories[category].append(description)

    # Return only non-empty categories, preserving canonical order
    return {c: items for c in CATEGORY_ORDER if (items := categories[c])}


def format_changelog_section(
    version: str,
    release_date: str | None = None,
    categories: dict[str, list[str]] | None = None,
) -> str:
    """Render a Keep a Changelog section string.

    Args:
        version: e.g. "2.0.0"
        release_date: ISO date string e.g. "2026-05-28". Defaults to today.
        categories: output of parse_commits(). If None or empty, renders placeholder.

    Returns:
        Markdown string starting with "## [X.Y.Z] — YYYY-MM-DD".
    """
    if release_date is None:
        release_date = date.today().isoformat()

    header = f"## [{version}] — {release_date}"

    if not categories:
        return f"{header}\n\n_(no changes logged)_\n"

    parts = [header]
    for category in CATEGORY_ORDER:
        items = categories.get(category, [])
        if not items:
            continue
        parts.append(f"\n### {category}")
        for item in items:
            parts.append(f"- {item}")

    return "\n".join(parts) + "\n"
