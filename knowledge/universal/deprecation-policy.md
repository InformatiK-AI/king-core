# Deprecation Policy

King Framework guarantees users a minimum runway before any breaking change takes effect.
This document is the authoritative reference for skill maintainers and consumers.

---

## Timelines

| Event | Minimum timeline |
|-------|-----------------|
| Deprecation announcement → removal | **6 months** |
| LTS release cadence | Every **18 months** |
| LTS active support window | **24 months** from GA |
| MAJOR version: backward compatibility | Guaranteed via compatibility-mode for all v1.x skills |

---

## Deprecation Process

A skill feature is deprecated in three stages:

1. **Announce** (MINOR bump)
   - Bump `api_version` MINOR in the skill's frontmatter
   - Add a `DEPRECATED` note in the skill's Knowledge Injection section
   - Open a GitHub Issue with label `deprecation` and a milestone set to the removal release

2. **Warning period** (active for ≥ 6 months)
   - The skill emits a visible warning when the deprecated feature is used
   - The CHANGELOG gains a `Deprecated` entry (see M-72 for format)
   - The REFERENCE.md of the affected skill documents the shim behavior

3. **Remove** (MAJOR bump only)
   - Removal is only allowed in the next MAJOR version
   - Minimum 6 months must have elapsed since the announcement
   - A migration guide must exist before the PR merges
   - Regression tests verifying the prior behavior must pass before removal

---

## Compatibility-Mode

Skills on older `api_version` that consume a deprecated API receive a **shim** automatically
until end of support:

- The shim accepts the old input and translates it to the new API silently
- The shim behavior is documented in the `REFERENCE.md` of the modified skill
- The test matrix for each King release covers all currently-supported skill versions

Compatibility-mode is **not** guaranteed for features removed without following this policy.

---

## LTS Schedule

| Version | LTS since | Active support until |
|---------|-----------|---------------------|
| v1.x    | retroactive (M-73) | TBD — per roadmap |
| v2.x    | next major release | +24 months from GA |

---

## Communicating Deprecations

Every deprecation MUST be communicated through all three channels:

1. **CHANGELOG** — entry under `Deprecated` category (format defined in M-72)
2. **GitHub Issue** — label `deprecation`, milestone set to the removal release
3. **Runtime warning** — the skill emits a human-readable warning at invocation time

---

## Maintainer Responsibilities

Before removing any skill feature, a maintainer MUST verify:

- [ ] Migration guide exists and is linked from the deprecation Issue
- [ ] Regression tests verifying the **prior behavior** are passing
- [ ] The minimum 6-month timeline has elapsed since the announcement
- [ ] compatibility-mode shim is documented in REFERENCE.md (if applicable)
- [ ] CHANGELOG `Deprecated` entry was added at announcement time

---

## See Also

- `knowledge/universal/skill-versioning.md` — api_version bump rules and breaking-change definition
- `skills/audit/SUBDIMENSIONS.md` — F-04 (api-version-present) scoring
- M-72 — CHANGELOG auto-generation (defines the `Deprecated` category format)
