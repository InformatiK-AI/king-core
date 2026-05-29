"""Self-audit script for king-core CI.

Scans skills/ for SKILL.md files and computes a health score
using src/score_calc.py sub-dimension weights.

Usage:
  python scripts/audit_self.py [--ci-threshold N]
  Exit code 0 if score >= threshold, 1 otherwise.
"""
from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.score_calc import compute_subdim_scores, compute_health_score, GROUP_WEIGHTS
from src.semver import is_valid_semver

SKILLS_ROOT = Path(__file__).parent.parent / "skills"
_SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def _parse_frontmatter(text: str) -> dict[str, str]:
    """Extract key: value pairs from YAML frontmatter block."""
    match = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.DOTALL)
    if not match:
        return {}
    fields: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            fields[key.strip()] = val.strip()
    return fields


def _score_skill(skill_path: Path) -> dict[str, dict[str, float | None]]:
    """Score a single SKILL.md against the 25 sub-dimensions."""
    try:
        text = skill_path.read_text(encoding="utf-8-sig")
    except Exception:
        return {g: {sid: 0.0 for sid in w} for g, w in GROUP_WEIGHTS.items()}

    fm = _parse_frontmatter(text)
    has_name = bool(fm.get("name"))
    has_version = bool(fm.get("version"))
    has_api_version = bool(fm.get("api_version"))
    has_description = bool(fm.get("description") or fm.get("descripcion"))
    api_version_valid = is_valid_semver(fm.get("api_version", "")) if has_api_version else False
    has_phases_section = "## Fase" in text or "## Phase" in text or "## PHASES" in text
    has_checkpoint = "CHECKPOINT" in text
    has_required_outputs = "REQUIRED OUTPUTS" in text or "OUTPUT" in text.upper()
    file_exists = skill_path.exists()
    parent_has_skill = (skill_path.parent / "SKILL.md").exists()
    has_phases_md = (skill_path.parent / "PHASES.md").exists()
    has_reference_md = (skill_path.parent / "REFERENCE.md").exists()
    has_blocking = "BLOCKING" in text
    has_castle = "CASTLE" in text
    line_count = len(text.splitlines())
    has_examples = "```" in text
    has_see_also = "See Also" in text or "Ver también" in text or "## Ver " in text

    # Repo-level facts (same for all skills in the same repo)
    repo_root = skill_path.parent
    while repo_root.parent != repo_root and not (repo_root / ".git").exists():
        repo_root = repo_root.parent
    repo_has_pyproject = (repo_root / "pyproject.toml").exists()
    repo_has_requirements_test = (repo_root / "requirements-test.txt").exists()
    repo_has_changelog = (repo_root / "CHANGELOG.md").exists()
    repo_has_license = any(
        (repo_root / n).exists() for n in ("LICENSE", "LICENSE.md", "LICENSE.txt")
    )

    scores: dict[str, dict[str, float | None]] = {
        "inventory": {
            "I01": 1.0 if has_name else 0.0,
            "I02": 1.0 if has_description else 0.0,
            "I03": 0.5,  # author field not required per-skill
            "I04": 1.0 if repo_has_license else 0.0,
        },
        "format": {
            "F01": 1.0 if file_exists else 0.0,
            "F02": 1.0 if file_exists else 0.0,
            "F03": 1.0 if parent_has_skill else 0.0,
            "F04": (1.0 if api_version_valid else 0.5) if has_api_version else None,
            "F05": 1.0 if (has_name and has_version) else 0.5,
        },
        "cross_refs": {
            "X01": 1.0 if has_phases_section else 0.5,
            "X02": 1.0 if has_checkpoint else 0.5,
            "X03": 1.0 if has_examples else 0.0,
            "X04": 1.0 if has_required_outputs else 0.5,
        },
        "instructions": {
            "Q01": 1.0 if repo_has_pyproject else 0.0,
            "Q02": 1.0 if repo_has_requirements_test else 0.0,
            "Q03": 1.0 if repo_has_changelog else 0.0,
            "Q04": 1.0 if has_version else 0.0,
        },
        "communication": {
            "C01": 1.0 if has_castle else 0.5,
            "C02": 1.0 if has_examples else 0.0,
            "C03": 1.0 if has_reference_md else 0.5,
            "C04": 1.0 if has_see_also else 0.5,
        },
        "efficiency": {
            "E01": 0.5,  # install script at repo level
            "E02": 0.5,  # uninstall at repo level
            "E03": 1.0 if has_phases_md else 0.5,
            "E04": 0.5,  # upgrade notes at repo level
        },
    }
    return scores


def audit_skills(root: Path) -> tuple[float, int]:
    """Audit all SKILL.md under root. Returns (avg_health_score, skill_count)."""
    skill_files = sorted(root.rglob("SKILL.md"))
    if not skill_files:
        return 0.0, 0

    scores_list = []
    for skill_path in skill_files:
        group_scores = _score_skill(skill_path)
        subdim = compute_subdim_scores(group_scores)
        health = compute_health_score(subdim)
        scores_list.append(health)

    avg = sum(scores_list) / len(scores_list)
    return round(avg, 2), len(scores_list)


def main() -> None:
    parser = argparse.ArgumentParser(description="King Framework self-audit.")
    parser.add_argument(
        "--ci-threshold", type=float, default=80.0,
        help="Minimum health score (0-100). Exit 1 if below. Default: 80."
    )
    parser.add_argument(
        "--scope", default=str(SKILLS_ROOT),
        help="Path to scan for SKILL.md files."
    )
    args = parser.parse_args()

    scope = Path(args.scope)
    avg_score, count = audit_skills(scope)

    print(f"King Framework Self-Audit")
    print(f"  Skills scanned: {count}")
    print(f"  Average health score: {avg_score:.2f}")
    print(f"  CI threshold: {args.ci_threshold}")

    if avg_score >= args.ci_threshold:
        print(f"\nCI_RESULT: PASS | EXIT_CODE: 0")
        sys.exit(0)
    else:
        print(f"\nCI_RESULT: FAIL | EXIT_CODE: 1")
        print(f"  Score {avg_score:.2f} < threshold {args.ci_threshold}")
        sys.exit(1)


if __name__ == "__main__":
    main()
