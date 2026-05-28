# Skill Versioning Convention

## §1 — Frontmatter Contract

Every `SKILL.md` MUST include `api_version: MAJOR.MINOR.PATCH` in its YAML frontmatter block. This field signals the interface contract version of the skill — not the content revision.

Placement order within frontmatter: `name` → `version` → `api_version` → `description`.

```yaml
---
name: my-skill
version: 1.0.0
api_version: 1.0.0
description: >
  What this skill does.
---
```

The `api_version` field is evaluated by the audit skill as sub-dimension F-04 (`api-version-present`) at 3% weight in the FORMAT group.

## §2 — Bump Rules

| Bump | When to use |
|------|-------------|
| PATCH | Typo fixes, wording, example updates — no behavior change |
| MINOR | New phases, new optional params — backward-compatible additions |
| MAJOR | Removed phases, changed output contracts, renamed required params |

A "behavior change" means any modification that alters what a caller (agent or human) MUST do or MUST expect when invoking the skill.

## §3 — Breaking Change Definition

A MAJOR bump is any change that breaks existing callers without migration. Specifically:

- Removing a phase that callers depend on
- Renaming a required input parameter
- Changing the output contract (fields removed, types changed, structure reorganized)
- Removing a command or slash-command exposed by the skill

A MAJOR bump REQUIRES a CHANGELOG section (format defined in M-72) with:
1. **What broke** — the specific interface element that changed
2. **Why it changed** — the design or product reason
3. **How callers migrate** — the exact action callers must take

MINOR and PATCH bumps do NOT require a CHANGELOG entry (recommended but not enforced until M-72).

## §4 — Baseline Note

All `SKILL.md` files in king-core were backfilled to `api_version: 1.0.0` as part of M-71 (2026-05-28).

`1.0.0` means "first formally versioned release." This does NOT imply prior formal versions exist — skills were in production before versioning was introduced. The baseline value was chosen over `0.1.0` (which would falsely signal instability) and over omission (which would leave F-04 unscored).

## §5 — CHANGELOG Format (M-72 forward)

The CHANGELOG format for skill `api_version` bumps is reserved for M-72. When M-72 is implemented, MAJOR bumps will require a `## CHANGELOG` section in the relevant `SKILL.md` following the structure in §3.

Until M-72 ships, authors are encouraged (not required) to document MAJOR changes inline.

MAJOR bumps that deprecate a feature MUST also follow the deprecation process defined in
`knowledge/universal/deprecation-policy.md` — specifically: MINOR bump first (announcement),
6-month warning period, then MAJOR bump for removal.

## §6 — Audit Scoring

F-04 (`api-version-present`) evaluates the `api_version` field at **3%** weight in the FORMAT group.

Scoring criteria:
- `1.0` — `api_version` is present and is a valid semver string (`MAJOR.MINOR.PATCH`)
- `0.5` — `api_version` is present but does not match semver format
- `null` — `api_version` is absent (field missing entirely)

When F-04 is `null`, it is excluded from the format_score denominator:
- Full scoring: `format_score = (F-01*5 + F-02*5 + F-03*4 + F-04*3 + F-05*3) / 20 * 100`
- Null F-04: `format_score = (F-01*5 + F-02*5 + F-03*4 + F-05*3) / 17 * 100`
