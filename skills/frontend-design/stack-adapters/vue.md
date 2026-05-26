---
stack: vue
detect:
  - file: vite.config.ts
    content_match: "@vitejs/plugin-vue"
file_patterns:
  - pattern: src/main.ts
    purpose: App entry point — plugin registration
  - pattern: src/style.css
    purpose: Global CSS entry point for token injection
  - pattern: src/assets/main.css
    purpose: Alternative global CSS location (Vite scaffold default)
token_consumption:
  method: "css-vars"
  snippet: |
    /* src/style.css */
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
  name: "@vueuse/motion"
  install: "npm install @vueuse/motion"
  gpu_safe_patterns:
    - "Use `x`, `y`, `scale`, `rotate`, `opacity` — all compositor-safe"
    - "Avoid animating `width`, `height`, `padding` — they trigger layout"
    - "Use `v-motion` directive for declarative animations, avoid inline styles"
    - "`will-change: transform` on elements with enter/leave transitions"
a11y_rules:
  - rule: "Announce route changes to screen readers"
    check: "Use vue-router afterEach hook to update aria-live region"
  - rule: "Respect prefers-reduced-motion"
    check: "Check window.matchMedia('(prefers-reduced-motion: reduce)') before applying @vueuse/motion variants"
  - rule: "Form labels and ARIA attributes"
    check: "Every input has associated <label> or aria-label; error messages use aria-describedby"
---

## Integration Notes

Vue with Vite uses `src/style.css` (or `src/assets/main.css` depending on scaffold version) as the global CSS entry. Import tokens there — not in individual component `<style>` blocks, which scope styles to the component.

**Tailwind detect rule**: Check `package.json` for `tailwindcss >= 4.0.0`. If v4: use `@import "tailwindcss"` in CSS, no `tailwind.config.cjs`.

**@vueuse/motion plugin registration** (`src/main.ts`):

```ts
// src/main.ts
import { createApp } from 'vue';
import { MotionPlugin } from '@vueuse/motion';
import App from './App.vue';
import './style.css';

const app = createApp(App);
app.use(MotionPlugin);
app.mount('#app');
```

**Declarative animation with v-motion directive**:

```vue
<template>
  <div
    v-motion
    :initial="{ opacity: 0, y: 20 }"
    :enter="{ opacity: 1, y: 0, transition: { duration: 400 } }"
    :leave="{ opacity: 0, y: -20 }"
  >
    Content
  </div>
</template>
```

**Reduced motion guard**:

```ts
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const motionVariants = prefersReducedMotion
  ? { initial: {}, enter: {} }
  : { initial: { opacity: 0, y: 20 }, enter: { opacity: 1, y: 0 } };
```

**CSS vars in component `<style>`**: Variables defined in `:root` are accessible inside scoped Vue components without any extra configuration.
