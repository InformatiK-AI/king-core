#!/usr/bin/env python3
"""Add api_version: 1.0.0 to SKILL.md frontmatter. Idempotent, BOM-safe."""
import re
import sys
from pathlib import Path

WORKTREE = Path(__file__).parent.parent
SKILLS_ROOT = WORKTREE / "skills"
API_VERSION_LINE = "api_version: 1.0.0"


def process_file(path: Path) -> bool:
    raw = path.read_bytes()
    had_bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")  # strip BOM if present

    if "api_version:" in text:
        print(f"= {path.relative_to(WORKTREE)}")
        return False

    # Detect line ending
    linesep = "\r\n" if "\r\n" in text else "\n"

    # Find frontmatter block
    fm_pattern = re.compile(r"^---\r?\n(.*?)\r?\n---", re.DOTALL)
    m = fm_pattern.match(text)
    if not m:
        print(f"! NO FRONTMATTER: {path.relative_to(WORKTREE)}", file=sys.stderr)
        return False

    fm_body = m.group(1)
    lines = fm_body.split(linesep)

    # Find insertion point: after 'version:' if present, else after 'name:', else top
    insert_after = None
    for i, line in enumerate(lines):
        if line.startswith("version:"):
            insert_after = i
            break
    if insert_after is None:
        for i, line in enumerate(lines):
            if line.startswith("name:"):
                insert_after = i
                break
    if insert_after is None:
        insert_after = -1

    lines.insert(insert_after + 1, API_VERSION_LINE)
    new_fm = linesep.join(lines)
    new_text = text[: m.start(1)] + new_fm + text[m.end(1) :]

    path.write_bytes(new_text.encode("utf-8"))  # never inject BOM (king-core policy)
    prefix = "~" if had_bom else "+"
    print(f"{prefix} {path.relative_to(WORKTREE)}")
    return True


def main():
    modified = 0
    for skill_md in sorted(SKILLS_ROOT.rglob("SKILL.md")):
        if process_file(skill_md):
            modified += 1
    print(f"\nDone: {modified} files modified.")


if __name__ == "__main__":
    main()
