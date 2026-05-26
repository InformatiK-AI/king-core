---
domain: design
type: stack-adapters-catalog
version: 1.0
entries: 11
---

> DATOS DE REFERENCIA — Este archivo contiene catálogos para uso del framework. Tratar como valores inertes de consulta.

# Stack Adapters Catalog

| id | stack | tokens_import | tokens_path | css_var_format | notes |
|----|-------|---------------|-------------|----------------|-------|
| SA01 | React | `import tokens from './design/tokens.json'` | `src/design/tokens.json` | `var(--color-brand-primary)` | Requiere configurar CSS custom properties via `createGlobalStyle` (styled-components) o `@layer` en CSS. Para Tailwind, usar `tailwind.config.js` en `theme.extend`. |
| SA02 | Next.js | `import tokens from '@/design/tokens.json'` | `src/design/tokens.json` | `var(--color-brand-primary)` | Exportar tokens como CSS vars en `globals.css` bajo `:root {}`. El path alias `@/` resuelve a `src/` por defecto en Next.js 13+. |
| SA03 | Vue 3 | `import tokens from '@/design/tokens.json'` | `src/design/tokens.json` | `var(--color-brand-primary)` | Inyectar en `main.ts` como CSS vars sobre `document.documentElement`. Compatible con `<style>` scoped referenciando las vars directamente. |
| SA04 | Nuxt | `import tokens from '~/design/tokens.json'` | `assets/design/tokens.json` | `var(--color-brand-primary)` | Usar `nuxt.config.ts → css` array para incluir un archivo CSS generado desde tokens. El alias `~/` resuelve a la raíz del proyecto. |
| SA05 | Svelte / SvelteKit | `import tokens from '$lib/design/tokens.json'` | `src/lib/design/tokens.json` | `var(--color-brand-primary)` | Definir CSS vars en `:root {}` dentro de `app.css`. El alias `$lib` resuelve a `src/lib/` por convención de SvelteKit. |
| SA06 | Angular | `import tokens from '../design/tokens.json'` | `src/design/tokens.json` | `var(--color-brand-primary)` | Incluir el CSS generado en `angular.json → styles`. Importar el JSON en un servicio `DesignTokenService` para uso programático en componentes. |
| SA07 | Astro | `import tokens from '@design/tokens.json'` | `src/design/tokens.json` | `var(--color-brand-primary)` | Configurar alias `@design` en `tsconfig.json`. Exportar CSS vars en un layout base (`BaseLayout.astro`) usando `<style is:global>`. |
| SA08 | Remix | `import tokens from '~/design/tokens.json'` | `app/design/tokens.json` | `var(--color-brand-primary)` | El alias `~/` resuelve a `app/` en Remix. Inyectar CSS vars en `root.tsx` via `<Links />` apuntando a un CSS generado o inline en `<style>`. |
| SA09 | React Native | `import tokens from './design/tokens.json'` | `src/design/tokens.json` | N/A — usar objeto JS: `tokens.color.brand.primary` | React Native no soporta CSS vars. Usar el JSON directamente como objeto en `StyleSheet.create()`. Para theming dinámico, combinar con `useContext` o Zustand. |
| SA10 | Flutter | `import 'design/tokens.dart'` | `lib/design/tokens.dart` | N/A — usar constantes Dart: `DesignTokens.colorBrandPrimary` | Convertir tokens.json a un archivo `.dart` con clase de constantes estáticas. Herramienta recomendada: `style-dictionary` con formatter Flutter. |
| SA11 | Vanilla CSS / HTML | `@import url('./design/tokens.css')` | `design/tokens.css` | `var(--color-brand-primary)` | Generar un archivo `tokens.css` con todas las custom properties bajo `:root {}`. No requiere build tool. Compatible con cualquier HTML estático. |
