# Template: Browser Extension

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Spec oficial del template **Browser Extension** (community-templates 09). Describe el stack exacto, los skills King pre-configurados, la estructura que `/genesis` produce y la configuración de calidad. No es código: es la especificación que `/genesis` consume para generar una extensión de navegador cross-browser.

El eje de esta template no es un servidor ni una app: es el **modelo de ejecución sandboxeado de Manifest V3**, donde el código vive fragmentado en contextos aislados (service worker, content scripts, popup) que se comunican por mensajes, opera bajo permisos que el usuario debe aprobar explícitamente, y se distribuye mediante un proceso de revisión de tienda que castiga cualquier permiso de más. Cuatro ejes la distinguen: **arquitectura de mensajería entre contextos aislados**, **principio de mínimo privilegio en permisos**, **portabilidad Chrome/Firefox/Edge** y **el review de tienda como gate de release no negociable**.

---

## Stack

| Capa | Tecnología | Versión | Rol |
|---|---|---|---|
| Plataforma | Manifest V3 (WebExtensions API) | MV3 | Modelo de ejecución estándar Chrome/Edge/Firefox |
| Lenguaje | TypeScript (strict) | 5.x | Tipado de la WebExtensions API vía `@types/chrome` / `webextension-polyfill` |
| Bundler | Vite + `@crxjs/vite-plugin` | 6.x / última | HMR real sobre service worker y content scripts; genera el `manifest.json` desde config tipada |
| Cross-browser | `webextension-polyfill` (Mozilla) | última | API `browser.*` con Promesas, unifica Chrome (callbacks) y Firefox |
| UI (popup/options) | React + Tailwind CSS + shadcn/ui | 19 / 4.x / última | Superficie visual de popup, options page y side panel |
| Estado persistente | `chrome.storage` (local/sync) tipado | API MV3 | Config y estado entre contextos; sin acceso a `localStorage` desde el worker |
| Validación de mensajes | Zod | última | Schema de cada mensaje cruzado entre contextos (runtime + tipos) |
| Empaquetado/publish | `web-ext` (Mozilla) + `chrome-webstore-upload-cli` | última | Lint de tienda, build firmable y subida automatizada a las stores |
| Tests | Vitest + `@webext-core/fake-browser` + Playwright | última | Unit con browser API mockeada + E2E cargando la extensión real |

Navegadores objetivo por defecto: **Chrome / Edge** (Chromium, mismo paquete) y **Firefox** (build separado por diferencias de MV3). El polyfill permite una sola base de código con dos artefactos de salida.

---

## Skills King pre-configurados

Activos por defecto en `.king/config`:

| Skill | Rol en este template |
|---|---|
| `/genesis` | Bootstrap del scaffold con esta template |
| `/build` | Workflow de feature (mensaje → handler → tests → PR) |
| `/frontend-design` | UI de popup, options page y side panel de alto impacto |
| **king-design / `/design` (M9)** | Catálogos de paletas, font-pairings y estilos para que popup y options tengan identidad visual coherente en el poco espacio disponible. **Referencia central de UI de esta template.** |
| `publish-package` | Build firmable + lint `web-ext` + subida a Chrome Web Store y AMO |
| `/release` | Release GitFlow: certificación CASTLE, bump de `version` del manifest, tag semver |
| `/promote` | Promoción develop → qa → prod del canal de tienda (unlisted/beta → public) |
| `/audit` | Health Score del framework instalado |
| CASTLE | Foco en **C · A · S · T · E**, con **S (Security)** reforzado por el modelo de permisos (ver sección CASTLE) |

Las skills de **king-design (M9)** se pre-cargan porque el popup y la options page son UI real con una restricción brutal: pocos cientos de píxeles y cero margen para inconsistencia visual. Reutilizar los catálogos de paletas y font-pairings de M9 evita reinventar el sistema de diseño en un espacio donde cada decisión visual pesa.

---

## Estructura de proyecto generada

```
mi-extension/
├── src/
│   ├── manifest.config.ts      # manifest MV3 tipado (lo genera @crxjs en build)
│   ├── background/
│   │   └── service-worker.ts   # event-driven: NO estado en memoria, usa chrome.storage
│   ├── content/
│   │   └── content-script.ts   # inyectado en la página; mundo aislado por defecto
│   ├── popup/                  # acción del toolbar (React)
│   │   ├── index.html
│   │   └── App.tsx
│   ├── options/                # página de configuración (React)
│   │   ├── index.html
│   │   └── App.tsx
│   ├── messaging/
│   │   ├── schema.ts           # Zod: contrato tipado de cada mensaje entre contextos
│   │   └── bus.ts              # wrapper de browser.runtime con validación
│   ├── storage/
│   │   └── store.ts            # acceso tipado a chrome.storage (local/sync)
│   └── ui/                     # componentes shadcn/ui + tema king-design (M9)
├── public/
│   └── icons/                  # 16/32/48/128 px (requeridos por las stores)
├── tests/
│   ├── unit/                   # fake-browser
│   └── e2e/                    # Playwright cargando la extensión
├── .king/
│   ├── config                  # skills activos
│   ├── coverage.yaml           # thresholds CASTLE-T
│   └── castle/                 # reportes
├── .github/workflows/
│   ├── ci.yml                  # test + lint web-ext + castle por PR
│   └── publish.yml             # build + upload a stores en tag v*
├── vite.config.ts              # @crxjs/vite-plugin
└── web-ext-config.mjs          # config de lint y run de Mozilla web-ext
```

Separación clave: los tres contextos (`background/`, `content/`, `popup`+`options`) **nunca comparten memoria** — solo se comunican vía `messaging/`. El módulo `messaging/schema.ts` es el único punto donde se define qué mensajes existen, forzando que todo cruce de frontera pase por validación Zod. El service worker MV3 **no mantiene estado en variables**: cualquier dato persistente vive en `storage/`, porque el navegador lo termina cuando está ocioso.

---

## CASTLE configuration

| Layer | Estado | Gate específico de esta template |
|---|---|---|
| **C** Contracts | Activo | Cada mensaje entre contextos tiene schema Zod (`messaging/schema.ts`). El `manifest.json` generado es un contrato versionado; el set de `permissions` se documenta con su justificación. |
| **A** Architecture | Activo | Aislamiento estricto de contextos: `content/` y `background/` no se importan entre sí, solo intercambian mensajes. El service worker no puede asumir estado en memoria entre invocaciones (enforcer). |
| **S** Security | **Activo (reforzado)** | **Permisos mínimos**: gate que falla si el manifest declara un permiso no usado en código. `host_permissions` específicos (no `<all_urls>` sin justificación). CSP MV3 estricta: prohibido `eval`/código remoto. Validación de todo mensaje entrante (un content script corre en una página hostil). |
| **T** Testing | Activo | Coverage global 80%; `messaging/` y `storage/` a 90% (la frontera entre contextos es donde se rompen las extensiones). E2E carga la extensión real en un navegador headless. |
| **L** Logging | Atenuado (`warn`) | No hay backend: el "log" es la consola de cada contexto. Gate verifica que no queden `console.log` en build de producción y que los errores del worker se reporten, no logging estructurado persistente. |
| **E** Environment | Activo | Paridad de comportamiento Chrome/Edge vs Firefox: el build debe producir y lintear ambos artefactos. Verificación de que el polyfill cubre las APIs usadas en los dos motores. |

`.king/coverage.yaml`: `thresholds.global: 80`, `per_package: { src/messaging: 90, src/storage: 90 }`, `enforcement: block`. El refuerzo de **S** es la diferencia estructural de esta template: una extensión corre con los permisos del usuario sobre **todas las páginas que visita**, y la tienda rechaza permisos injustificados. El gate de "permisos mínimos" no es opcional — es el mismo criterio que aplica el revisor de Chrome Web Store, traído al CI para fallar antes y no en el review.

---

## CI/CD incluido

Plataforma de distribución target: **Chrome Web Store** + **Firefox Add-ons (AMO)** (no un servidor de deploy; el "deploy" de una extensión es el publish a las tiendas). Dos workflows de GitHub Actions:

**`ci.yml`** (por PR): `pnpm install` → `pnpm typecheck` → `pnpm lint` → `web-ext lint` (validador oficial de Mozilla, anticipa rechazos de tienda) → `pnpm test --coverage` (gate 80%) → `pnpm test:e2e` (Playwright carga la extensión) → CASTLE check (incluye el gate de permisos mínimos). Bloquea merge si falla cualquier paso o el gate CASTLE-S.

**`publish.yml`** (en push de tag `v*`):

1. Build de los dos artefactos: Chromium (Chrome/Edge) y Firefox.
2. `web-ext lint` final como puerta previa a la subida.
3. Sube el artefacto Chromium a **Chrome Web Store** vía `chrome-webstore-upload-cli` (credenciales OAuth solo por secrets de CI).
4. Sube y firma el artefacto Firefox en **AMO** vía `web-ext sign`.
5. Adjunta ambos `.zip`/`.xpi` al **GitHub Release** y genera changelog desde conventional commits.

El submission queda en estado **pendiente de review** en ambas tiendas — el pipeline automatiza la subida, pero el gate humano del revisor es deliberadamente no automatizable. Por eso `web-ext lint` corre tanto en PR como antes de publicar: detectar un permiso injustificado o una CSP inválida en CI cuesta minutos; descubrirlo en un rechazo de tienda cuesta días de ciclo de release.

---

## Cómo usar

```
king-framework genesis --template browser-extension-starter
```

## Decisiones de diseño

Cada elección responde a una restricción estructural de Manifest V3 y del modelo de distribución por tienda, no a preferencia genérica:

- **Manifest V3 sobre V2 — no es elección, es el único camino** — Chrome dejó de aceptar extensiones MV2 en la store y MV2 está en fin de vida en todos los navegadores Chromium. La template nace en MV3 porque cualquier extensión nueva que apunte a V2 sería rechazada hoy. La consecuencia de diseño cae sobre el background: el **service worker efímero** reemplaza la background page persistente, y por eso la template prohíbe estado en memoria y obliga a `chrome.storage` desde el inicio.

- **`webextension-polyfill` + un solo codebase sobre dos proyectos separados** — Chrome usa callbacks y Firefox usa Promesas en la WebExtensions API; las diferencias de MV3 entre ambos son reales pero acotadas. El polyfill de Mozilla normaliza la API a `browser.*` con Promesas, permitiendo **una base de código y dos artefactos de build** en vez de mantener dos proyectos. Mantener forks paralelos por navegador es donde mueren las extensiones cross-browser: cada feature se implementa dos veces y divergen.

- **Vite + `@crxjs/vite-plugin` sobre webpack o build manual del manifest** — el ciclo de desarrollo de extensiones es notoriamente lento: editar, recompilar, recargar la extensión, reabrir el popup. `@crxjs` aporta **HMR real sobre service worker y content scripts** (no recarga completa) y, críticamente, **genera el `manifest.json` desde config TypeScript tipada**, eliminando la clase entera de bugs de un manifest escrito a mano (permiso mal escrito, ruta de script inexistente). El manifest deja de ser un JSON frágil y pasa a ser código verificado por el compilador.

- **Zod en la frontera de mensajes, no opcional** — un content script corre **dentro de una página web que puede ser hostil**, y cualquier mensaje que llega al service worker cruza una frontera de confianza. Validar cada mensaje con Zod (runtime + tipos) en `messaging/schema.ts` convierte la mensajería entre contextos —el punto más frágil y más atacable de una extensión— en un contrato explícito y verificado. Confiar en el `payload` de un mensaje sin validar es el equivalente a confiar en input de red sin sanitizar.

- **Principio de mínimo privilegio elevado a gate de CASTLE-S** — el revisor de tienda rechaza extensiones que piden permisos que no usan, y cada permiso de más reduce la tasa de instalación (el usuario ve el prompt y desconfía). La template hace que CI **falle si el manifest declara un permiso no referenciado en código** y prohíbe `<all_urls>` sin justificación documentada. Es traer el criterio del revisor al pipeline: fallar en minutos en CI en vez de en días en un rechazo de store.

- **king-design (M9) para popup y options en vez de CSS ad-hoc** — un popup tiene unos cientos de píxeles y cero tolerancia a inconsistencia visual; un sistema de diseño improvisado se nota de inmediato en ese espacio. Reutilizar los catálogos de paletas, font-pairings y estilos de M9 da identidad visual coherente entre popup, options y side panel sin reinventar el sistema, y conecta esta template con el resto del ecosistema King de diseño en lugar de tratarla como una isla.
