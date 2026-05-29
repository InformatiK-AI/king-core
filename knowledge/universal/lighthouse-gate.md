# Lighthouse Gate (M-50+M-51)

## What Lighthouse measures

Lighthouse audits four categories: **Performance**, **Accessibility**, **Best Practices**, and **SEO**. The M-50 gate enforces only **Performance** as the blocking metric because:

- Performance score is deterministic in CI (no HMR, no source maps, no hot-reload overlay)
- Accessibility is already gated in Phase 2b (`/a11y-audit` — WCAG 2.2 AA)
- Best Practices and SEO are tracked but do not block (set `enforcement: warn` in `.king/lighthouse.yaml`)

Default threshold: **95**. Configurable via `.king/lighthouse.yaml`.

## Why CI only

Local dev scores are informational only — NOT used for gating. Reason: dev environments run with HMR, source maps, and dev-mode bundles, which typically degrade the Lighthouse Performance score by **15–30 points** compared to a production build. Enforcing the gate in dev would generate false positives on every iteration.

Detection: Phase 2c activates when `CI=true` or `KING_LIGHTHOUSE=true` is set in the environment.

## Establishing the baseline on first deploy

The grace period prevents the first CI run from being blocked with no recourse:

1. Run `/promote` in CI without a `.king/lighthouse-baseline.json` present
2. Phase 2c detects the missing baseline → logs WARN, does not block
3. If the Lighthouse score meets the threshold (>= 95 by default), Phase 2c creates `.king/lighthouse-baseline.json` automatically
4. From that point on, any subsequent run with a score below the threshold will BLOCK

Commit `.king/lighthouse-baseline.json` to version control so the team shares the same baseline.

## `.king/lighthouse.yaml` schema

```yaml
threshold: 95                          # minimum Performance score (0–100)
categories:
  - performance                        # blocking gate
  enforcement: block                   # block | warn
url: https://{{PROD_URL}}             # URL to audit (override with LIGHTHOUSE_URL env var)
```

Optional keys:
- `categories[].accessibility: warn` — track but do not block
- `categories[].best-practices: warn`
- `categories[].seo: warn`

## Grace period

The grace period is the window between the first CI run and the first successful baseline creation. During this window:

- Phase 2c exits 0 (non-blocking)
- A WARN is logged: `[King/Lighthouse] WARN: No baseline found — establishing baseline on first successful run.`
- The grace period **expires automatically** after the first CI run where score >= threshold creates `.king/lighthouse-baseline.json`

There is no time limit — the grace period ends by action (creating the baseline), not by clock.

## Mobile-first prerequisite

Phase 2c runs a mobile-first check **before** the Lighthouse audit:

1. All HTML/template entry points must include `<meta name="viewport" content="width=device-width, initial-scale=1">`
2. CSS breakpoints must use `min-width` media queries (mobile-first pattern), not exclusively `max-width`

If this check fails, Phase 2c blocks immediately and the Lighthouse audit does not run. Fix the mobile-first issues first, then re-run `/promote`.
