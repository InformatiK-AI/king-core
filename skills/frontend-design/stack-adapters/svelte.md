---
stack: svelte
detect:
  - file: svelte.config.js
file_patterns:
  - pattern: src/app.css
    purpose: Global CSS entry point for token injection (SvelteKit convention)
  - pattern: src/app.html
    purpose: HTML shell — link font preconnect here
  - pattern: src/routes/+layout.svelte
    purpose: Root layout — imports app.css
token_consumption:
  method: "css-vars"
  snippet: |
    /* src/app.css */
    @import url('https://fonts.googleapis.com/css2?family={{HEADING_FONT}}:wght@400;600;700&family={{BODY_FONT}}:wght@400;500&display=swap');
    @import '../../.king/design/css-vars.css';

    *,
    *::before,
    *::after {
      box-sizing: border-box;
    }

    body {
      font-family: var(--font-body);
      background-color: var(--color-bg-default);
      color: var(--color-fg-default);
      margin: 0;
    }
tailwind_version: "detect"
tailwind_v3_config: "tailwind.config.cjs"
tailwind_v4_import: '@import "tailwindcss"'
animation_lib:
  name: svelte/transition
  install: "built-in — no install required"
  gpu_safe_patterns:
    - "`fade` and `fly` use `opacity` and `transform` — compositor-safe"
    - "Prefer `fly` with `y` parameter over `slide` which animates `height`"
    - "`crossfade` for shared-element transitions between routes"
    - "Use `tweened` or `spring` stores for physics-based value animations"
a11y_rules:
  - rule: "Svelte a11y compile-time warnings"
    check: "Zero a11y warnings in svelte-check output — treat as errors"
  - rule: "Respect prefers-reduced-motion"
    check: "Wrap transition directives with reduced motion check: `transition:fly|global={{ duration: prefersReduced ? 0 : 300 }}`"
  - rule: "Route announcements for SvelteKit"
    check: "SvelteKit announces route changes automatically — verify aria-live polite region is present in app.html"
---

## Integration Notes

SvelteKit uses `src/app.css` as the global stylesheet, imported in `src/routes/+layout.svelte`. Svelte's scoped styles do not bleed global — tokens MUST be imported at this root level.

**Tailwind detect rule**: Check `package.json` for `tailwindcss >= 4.0.0`. If v4: use `@import "tailwindcss"` in CSS, no `tailwind.config.cjs`.

**Root layout import** (`src/routes/+layout.svelte`):

```svelte
<script>
  import '../app.css';
</script>

<slot />
```

**Reduced motion store** (reusable across components):

```ts
// src/lib/motion.ts
import { readable } from 'svelte/store';

export const prefersReducedMotion = readable(false, (set) => {
  if (typeof window === 'undefined') return;
  const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
  set(mq.matches);
  const handler = (e: MediaQueryListEvent) => set(e.matches);
  mq.addEventListener('change', handler);
  return () => mq.removeEventListener('change', handler);
});
```

**Using the store in a component**:

```svelte
<script>
  import { fly } from 'svelte/transition';
  import { prefersReducedMotion } from '$lib/motion';
</script>

{#if visible}
  <div transition:fly={{ y: $prefersReducedMotion ? 0 : 20, duration: $prefersReducedMotion ? 0 : 300 }}>
    Content
  </div>
{/if}
```

**CSS vars in scoped `<style>`**: Svelte scoped styles can reference global CSS variables from `:root` — no special syntax needed.

**Vanilla Svelte (no Kit)**: Import `app.css` in the top-level `main.ts` instead. Structure is identical, just no `+layout.svelte`.
