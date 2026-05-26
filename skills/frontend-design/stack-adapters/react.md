---
stack: react
detect:
  - file: package.json
    content_match: '"react":'
file_patterns:
  - pattern: src/index.css
    purpose: Global CSS entry point for token injection
  - pattern: src/main.tsx
    purpose: App entry point
  - pattern: src/App.tsx
    purpose: Root component
token_consumption:
  method: "css-vars"
  snippet: |
    /* src/index.css */
    @import url('https://fonts.googleapis.com/css2?family={{HEADING_FONT}}:wght@400;600;700&family={{BODY_FONT}}:wght@400;500&display=swap');
    @import '../.king/design/css-vars.css';

    body {
      font-family: var(--font-body);
      background-color: var(--color-bg-default);
      color: var(--color-fg-default);
    }
tailwind_version: "detect"
tailwind_v3_config: "tailwind.config.cjs"
tailwind_v4_import: '@import "tailwindcss"'
animation_lib:
  name: framer-motion
  install: "npm install framer-motion"
  gpu_safe_patterns:
    - "Use `transform` and `opacity` only — they trigger compositor, not layout"
    - "Prefer `layoutId` over animating `width`/`height` directly"
    - "`will-change: transform` on elements with complex animations"
    - "Avoid animating `top`, `left`, `margin` — use `x`, `y` translate instead"
a11y_rules:
  - rule: "Respect prefers-reduced-motion"
    check: "Wrap framer-motion variants with useReducedMotion() hook"
  - rule: "Focus management on modal/drawer open"
    check: "Use autoFocus or FocusTrap when overlay components mount"
  - rule: "Color contrast minimum 4.5:1 for body text"
    check: "Verify --color-fg-default vs --color-bg-default in DevTools"
---

## Integration Notes

React consumes design tokens via CSS custom properties imported in `src/index.css`. This approach keeps tokens decoupled from component logic — components reference variables, not hardcoded values.

**Tailwind detect rule**: Check `package.json` for `tailwindcss >= 4.0.0`. If v4: use `@import "tailwindcss"` in CSS, no `tailwind.config.cjs`.

**Framer Motion setup**: Wrap the app root with `LazyMotion` for bundle optimization:

```tsx
// src/main.tsx
import { LazyMotion, domAnimation } from 'framer-motion';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <LazyMotion features={domAnimation}>
    <App />
  </LazyMotion>
);
```

**Token reload in dev**: Vite HMR picks up CSS changes automatically. No restart needed after regenerating `.king/design/css-vars.css`.

**Reduced motion hook** (add to shared utils):

```tsx
import { useReducedMotion } from 'framer-motion';

export function useMotionVariants(full: Variants, reduced: Variants) {
  const shouldReduce = useReducedMotion();
  return shouldReduce ? reduced : full;
}
```
