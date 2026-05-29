---
name: autofix
part-of: audit
---

# Audit Auto-Fix Catalog

> Archivo parte de: `skills/audit/SKILL.md`
> Activo solo cuando se pasa `--auto-fix`. Sin ese flag, el audit solo reporta — no modifica archivos.

---

## Classification

| Class | Execution | Condition |
|-------|-----------|-----------|
| `auto` | Execute silently when `--auto-fix` is passed. Strictly additive. | Idempotent, safe, no judgment required |
| `guided` | Show step-by-step instructions. User executes manually. | Requires context or judgment |
| `manual` | Report issue only. No fix action taken. | Complex; risk of unintended side effects |

---

## Safety Contract

> 🚫 These operations are NEVER performed by any fix class

- NEVER delete any file or directory
- NEVER overwrite existing non-empty field values
- NEVER move or rename files or directories
- NEVER truncate file contents
- Only CREATE new files or APPEND/ADD to existing ones

**Idempotence guarantee**: Running `--auto-fix` a second time on the same plugin MUST produce zero new fix actions. Every `auto` fix checks existence before acting.

---

## Fix Catalog

| ID | Issue | Fix Operation | Class | Idempotent | Linked Sub-dim |
|----|-------|---------------|-------|------------|----------------|
| AF-01 | Missing `api_version` in frontmatter | Add `api_version: 1.0.0` after last existing frontmatter field (only if field absent) | auto | Yes | F-04 |
| AF-02 | Missing `description` in frontmatter | Add `description: "TODO: add description"` placeholder (only if field absent or empty) | guided | Yes | I-02 |
| AF-03 | Missing `author` field in frontmatter | Add `author: ""` placeholder (only if field absent) | auto | Yes | I-03 |
| AF-04 | Missing `license` field in frontmatter | Add `license: ""` placeholder (only if field absent) | auto | Yes | I-04 |
| AF-05 | Missing `CHANGELOG.md` or `HISTORY.md` | Create `CHANGELOG.md` with skeleton: `# Changelog\n\n## Unreleased\n` (only if neither file exists) | guided | Yes | Q-03 |
| AF-06 | Missing `README.md` | Create `README.md` with skeleton: `# {plugin-name}\n\n## Overview\n\nTODO\n\n## Usage\n\nTODO\n` (only if absent) | guided | Yes | C-01 |
| AF-07 | Missing install script | Create `install.sh` with skeleton shebang and `# TODO: add install steps` comment (only if absent) | auto | Yes | E-01 |
| AF-08 | Missing `dependency-manifest` | Create `requirements.txt` (or `package.json` stub) with header comment only (only if no manifest detected) | guided | Yes | E-03 |
| AF-09 | Missing required directory in plugin structure | Run `mkdir -p {expected_dir}` for each declared directory that does not exist | auto | Yes | F-01 |
| AF-10 | Missing `SKILL.md` entrypoint in skill root | Create `SKILL.md` with v2.0 skeleton template (frontmatter + required sections) only if absent | guided | Yes | F-03 |
| AF-11 | Missing `upgrade-notes` section in CHANGELOG | Append `## Upgrade Notes\n\n- No breaking changes.\n` to existing CHANGELOG.md (only if section absent) | guided | Yes | E-04 |
| AF-12 | Missing usage example in README | Append `\n## Usage Example\n\n\`\`\`bash\n# TODO: add example\n\`\`\`\n` to README.md (only if no code fence present) | guided | Yes | C-02 |

---

## Execution Protocol

When `--auto-fix` is passed:

1. Run audit phases 1–6 normally, collecting all issues.
2. For each issue linked to an `auto` class fix in this catalog:
   a. Check precondition (file/field absent).
   b. If precondition met: apply the additive operation.
   c. Record fix in "Auto-Fix Applied" section of report.
   d. Re-score the affected sub-dimension.
3. For each issue linked to a `guided` class fix: include in report under "Guided Fix Suggestions."
4. For each issue linked to a `manual` class fix: include in report under "Manual Fix Required."

### --dry-run + --auto-fix behavior

When both `--dry-run` and `--auto-fix` are passed simultaneously:
- Simulate which fixes WOULD be applied.
- List them under "Would auto-fix:" block in report.
- Do NOT modify any files.

---

## Report Sections Produced

```markdown
## Auto-Fix Applied
| AF-ID | Sub-dim | Fix Applied | File Modified |
|-------|---------|-------------|---------------|
| AF-01 | F-04    | Added api_version: 1.0.0 | plugins/my-plugin/SKILL.md |

## Guided Fix Suggestions
| AF-ID | Sub-dim | Suggested Action |
|-------|---------|-----------------|
| AF-02 | I-02    | Add meaningful description to frontmatter |

## Manual Fix Required
| AF-ID | Sub-dim | Issue Description |
|-------|---------|------------------|
| ...   | ...     | ...              |
```
