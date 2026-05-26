---
stack: nextjs
detect:
  - file: next.config.js
  - file: next.config.mjs
file_patterns:
  - pattern: app/globals.css
    purpose: App Router global styles — primary token injection point
  - pattern: pages/_app.tsx
    purpose: Pages Router global styles entry
  - pattern: app/layout.tsx
    purpose: Root layout — font loading via next/font
token_consumption:
  method: "css-vars"
  snippet: |
    /* app/globals.css */
    @import url('https://fonts.googleapis.com/css2?family={{HEADING_FONT}}:wght@400;600;700&family={{BODY_FONT}}:wght@400;500&display=swap');
    @import '../../.king/design/css-vars.css';

    html {
      font-family: var(--font-body);
    }

    body {
      background-color: var(--color-bg-default);
      color: var(--color-fg-default);
      -webkit-font-smoothing: antialiased;
    }
tailwind_version: "detect"
tailwind_v3_config: "tailwind.config.cjs"
tailwind_v4_import: '@import "tailwindcss"'
animation_lib:
  name: framer-motion
  install: "npm install framer-motion"
  gpu_safe_patterns:
    - "Use `transform` and `opacity` only — compositor-safe properties"
    - "Add `'use client'` directive to any component using framer-motion hooks"
    - "Wrap page transitions in `<AnimatePresence mode='wait'>` in root layout"
    - "Avoid layout animations on SSR'd content — they cause hydration mismatches"
a11y_rules:
  - rule: "Semantic HTML with Next.js Image alt text"
    check: "Every <Image> has descriptive alt; decorative images use alt=''"
  - rule: "Respect prefers-reduced-motion"
    check: "useReducedMotion() hook from framer-motion in animated components"
  - rule: "Skip navigation link for keyboard users"
    check: "Add <a href='#main-content'> as first child of <body>"
---

## Integration Notes

Next.js supports both App Router (`app/globals.css`) and Pages Router (`pages/_app.tsx`). Token import path is relative to the CSS file location — adjust `../../.king/design/css-vars.css` based on project depth.

**Tailwind detect rule**: Check `package.json` for `tailwindcss >= 4.0.0`. If v4: use `@import "tailwindcss"` in CSS, no `tailwind.config.cjs`.

**next/font preferred over Google Fonts** (avoids external network request):

```tsx
// app/layout.tsx
import { Inter, Playfair_Display } from 'next/font/google';

const bodyFont = Inter({ subsets: ['latin'], variable: '--font-body' });
const headingFont = Playfair_Display({ subsets: ['latin'], variable: '--font-heading' });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${bodyFont.variable} ${headingFont.variable}`}>
      <body>{children}</body>
    </html>
  );
}
```

**App Router AnimatePresence** for page transitions:

```tsx
// app/template.tsx (not layout.tsx — template re-mounts on navigation)
'use client';
import { motion } from 'framer-motion';

export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -8 }}
      transition={{ duration: 0.2 }}
    >
      {children}
    </motion.div>
  );
}
```

**Server Components caveat**: framer-motion components must be `'use client'`. Extract animated wrappers into separate client components and keep data-fetching in Server Components.
