---
name: changelog-generator
part-of: release
api_version: 1.0.0
---

# CHANGELOG Generator — Phase 5 Instructions

> Load this file at the start of Release Phase 5.
> Follow sections §1–§6 in order.

## §1 — Extract commits in range

```bash
git log --format="%H %s%n%b%n---END---" \
  $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD
```

Parse each commit: extract type, optional scope, description, and body (for BREAKING CHANGE footer).
Each output line has format: `{hash} {type}[({scope})][!]: {description}`

## §2 — Map commit types to Keep a Changelog categories

| Commit type | Category |
|-------------|----------|
| `feat` | Added |
| `fix` | Fixed |
| `security` | Security |
| `deprecate` | Deprecated |
| `remove` | Removed |
| `refactor`, `chore`, `perf`, `docs`, `test`, `build`, `ci`, `style` | Changed |
| Commit with `!` or `BREAKING CHANGE:` footer | prefix description with `⚠️ BREAKING:` |

> **Authoritative source**: `src/changelog_formatter.py::COMMIT_TYPE_MAP`

Any commit type not listed above maps to `Changed`.

## §3 — Enrich with GitHub issues and PRs (optional)

> **Skip this section if `gh` is not available or not authenticated** — complete the changelog with commits only and add a comment `<!-- gh CLI unavailable: issue/PR enrichment skipped -->`.

```bash
# Issues closed in milestone
gh issue list --state closed --milestone "vX.Y.Z" \
  --json number,title,labels --limit 100

# PRs merged since previous tag
gh pr list --state merged --base develop \
  --json number,title,labels --limit 100
```

Map issue labels: `bug` → Fixed, `enhancement` → Added, `security` → Security, `deprecated` → Deprecated.

Append issue/PR references as `(#N)` to matching description entries.

## §4 — Deduplicate

Remove duplicate entries within the same category:
- If a commit body contains `Closes #N` and an issue with number N was also fetched from gh, keep the issue entry (richer context) and discard the commit entry.
- Remove exact-string duplicates within each category list.

## §5 — Assemble Keep a Changelog section

Call `format_changelog_section(version, date, categories)` from `src/changelog_formatter.py`, or assemble manually following this template:

```markdown
## [X.Y.Z] — YYYY-MM-DD

### Added
- description of feat commits / enhancement issues

### Changed
### Deprecated
### Removed
### Fixed
### Security
```

Omit empty category headers (do not render `### Added` if no Added entries).
Canonical order: Added, Changed, Deprecated, Removed, Fixed, Security.

## §6 — Prepend to CHANGELOG.md

1. Read current `CHANGELOG.md` content.
2. Find the line `## [Unreleased]` — insert the new version section **after** `[Unreleased]` and its content, before the previous version entry.
   If `[Unreleased]` is absent, insert at the very top of the file.
3. Write back.
4. Stage and commit: `git add CHANGELOG.md && git commit -m "docs(changelog): update for vX.Y.Z"`

## See Also

- `knowledge/universal/deprecation-policy.md` — semantics for the Deprecated category
- `knowledge/universal/skill-versioning.md` — api_version bump rules for MAJOR entries
