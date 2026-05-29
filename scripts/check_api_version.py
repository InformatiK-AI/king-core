"""Pre-commit hook: verify api_version field in modified SKILL.md files."""
from __future__ import annotations
import re
import sys
from pathlib import Path


def check_file(path: str) -> bool:
    """Return True if file has valid api_version in frontmatter."""
    text = Path(path).read_text(encoding="utf-8-sig")
    m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.DOTALL)
    if not m:
        print(f"WARN: {path} has no frontmatter")
        return True  # non-blocking for files without frontmatter
    fm = m.group(1)
    if "api_version:" not in fm:
        print(f"FAIL: {path} missing api_version in frontmatter")
        return False
    return True


def main() -> None:
    files = sys.argv[1:]
    failed = [f for f in files if not check_file(f)]
    if failed:
        print(f"\n{len(failed)} SKILL.md file(s) missing api_version.")
        sys.exit(1)


if __name__ == "__main__":
    main()
