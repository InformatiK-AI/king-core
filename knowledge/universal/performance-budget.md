# Performance Budget Gate

## Core Web Vitals

Google defines three field metrics that directly measure user experience:

| Metric | Good | Needs Improvement | Poor |
|--------|------|--------------------|------|
| **LCP** (Largest Contentful Paint) | < 2500ms | 2500–4000ms | > 4000ms |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1–0.25 | > 0.25 |
| **INP** (Interaction to Next Paint) | < 200ms | 200–500ms | > 500ms |

These thresholds are set at the 75th percentile of real user data. INP replaced FID as a Core Web Vital in March 2024.

## Calibrating the Budget for Your Project

Measure under realistic conditions:

- **Mobile first**: test on a mid-range Android device (Moto G Power class)
- **Network**: simulate 4G (40 Mbps down, 20ms RTT) using Chrome DevTools throttling
- **Baseline**: run 5 Lighthouse audits and take the median — single runs have high variance

Calibration steps:

1. Run `/perf-audit` (or `npx lhci autorun`) on your current build
2. Record median LCP, CLS, INP from real-user data (CrUX dashboard or PageSpeed Insights)
3. Set budgets in `.king/performance.yaml` 10–15% tighter than your current median to create regression headroom
4. Re-audit after each major frontend change

## Tooling

- **Lighthouse CLI**: `npx lighthouse https://your-site.com --output json --output-path report.json`
- **LHCI (CI integration)**: `npx lhci autorun` — reads `.lhcirc.json` for multi-URL configs
- **WebPageTest**: film strip + waterfall for root-cause analysis of LCP candidates
- **Chrome DevTools Performance panel**: frame-by-frame INP and layout shift attribution

## Config File Naming — Legacy Migration

The canonical config file is `.king/performance.yaml` (ADR #7). The older
`.king/performance-budget.yaml` name is deprecated. The `perf-check.sh` hook
reads `.king/performance.yaml` exclusively. If only the legacy file exists the
hook emits a warning and exits 0 without blocking.

To migrate:
```bash
mv .king/performance-budget.yaml .king/performance.yaml
```

The `legacy_alias` field in `.king/performance.yaml` documents this migration
path but does not affect hook behavior.

## When to Adjust the Budget

A performance budget is a contract, not a moving target.

**DO tighten the budget** after a successful optimization sprint — lock in the
gains so regressions are caught immediately.

**DO NOT raise the budget** because a feature made metrics worse. Raising
thresholds to silence the gate hides real regressions from future reviewers.

If a legitimate architectural constraint prevents meeting the budget
(e.g., a required third-party script adds 80 KB), document the exception in
`.king/audit/performance-bypass.log` with a justification and set
`enforcement: warn` temporarily. Schedule a follow-up issue to resolve the
root cause.

Anti-pattern: `lcp_ms: 5000` because "our users have fast connections." Budget
based on worst-case realistic conditions, not best-case observations.
