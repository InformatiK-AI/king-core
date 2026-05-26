# Accessibility Knowledge Base

## Propósito
Conocimiento experto de accesibilidad web que se inyecta en agents durante /genesis.
Este conocimiento aplica a TODOS los proyectos con interfaz de usuario.

---

## WCAG 2.1/2.2 Fundamentos

### Los 4 Principios (POUR)

| Principio | Significado | Pregunta Clave |
|-----------|-------------|----------------|
| **Perceivable** | Usuarios pueden percibir el contenido | ¿Puede verse/oírse/sentirse? |
| **Operable** | UI y navegación son operables | ¿Puede usarse con cualquier input? |
| **Understandable** | Contenido y UI son comprensibles | ¿Es claro y predecible? |
| **Robust** | Compatible con tecnologías asistivas | ¿Funciona con screen readers? |

### Niveles de Conformidad

| Nivel | Descripción | Requisito Típico |
|-------|-------------|------------------|
| **A** | Mínimo accesible | Obligatorio para todos |
| **AA** | Accesibilidad estándar | Requisito legal común |
| **AAA** | Accesibilidad óptima | Aspiracional, no siempre alcanzable |

---

## Criterios WCAG Esenciales

### 1. Perceivable

#### 1.1 Alternativas de Texto (A)
```html
<!-- Imagen informativa -->
<img src="chart.png" alt="Ventas Q4: 45% crecimiento vs Q3">

<!-- Imagen decorativa -->
<img src="divider.png" alt="" role="presentation">

<!-- Imagen compleja -->
<figure>
  <img src="infographic.png" alt="Resumen del proceso de compra">
  <figcaption>
    Descripción detallada del proceso...
  </figcaption>
</figure>

<!-- Icono con significado -->
<button>
  <svg aria-hidden="true">...</svg>
  <span class="sr-only">Cerrar</span>
</button>
```

#### 1.3 Adaptable (A)
```html
<!-- Estructura semántica -->
<header>
  <nav aria-label="Principal">...</nav>
</header>
<main>
  <h1>Título Principal</h1>
  <section aria-labelledby="section-title">
    <h2 id="section-title">Sección</h2>
  </section>
</main>
<footer>...</footer>

<!-- Orden de lectura lógico -->
<!-- El orden del DOM debe coincidir con el orden visual -->
```

#### 1.4 Distinguible (AA)
```css
/* Contraste mínimo */
/* Texto normal: 4.5:1 */
/* Texto grande (18px+ bold, 24px+ normal): 3:1 */

/* BIEN */
.text { color: #333; background: #fff; } /* 12.6:1 */

/* MAL */
.text { color: #767676; background: #fff; } /* 4.48:1 - falla por poco */

/* Texto sobre imagen */
.overlay {
  background: rgba(0, 0, 0, 0.7);
  color: white;
}
```

### 2. Operable

#### 2.1 Accesible por Teclado (A)
```html
<!-- Elementos nativos son accesibles -->
<button>Click me</button>
<a href="/page">Link</a>
<input type="text">

<!-- Si usas div, necesitas ARIA + keyboard -->
<div
  role="button"
  tabindex="0"
  onclick="handleClick()"
  onkeydown="if(e.key==='Enter'||e.key===' ')handleClick()"
>
  Custom Button
</div>
```

#### 2.4 Navegable (A/AA)
```html
<!-- Skip link -->
<a href="#main-content" class="skip-link">
  Saltar al contenido principal
</a>

<!-- Títulos descriptivos -->
<title>Carrito de Compras - MiTienda</title>

<!-- Focus visible -->
<style>
:focus-visible {
  outline: 3px solid #005fcc;
  outline-offset: 2px;
}
</style>

<!-- Breadcrumbs -->
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Inicio</a></li>
    <li><a href="/productos">Productos</a></li>
    <li aria-current="page">Detalle</li>
  </ol>
</nav>
```

### 3. Understandable

#### 3.1 Legible (A)
```html
<!-- Idioma de la página -->
<html lang="es">

<!-- Cambio de idioma en texto -->
<p>El término <span lang="en">responsive design</span> significa...</p>
```

#### 3.2 Predecible (A)
```html
<!-- No cambiar contexto en focus -->
<!-- MAL -->
<select onchange="window.location = this.value">

<!-- BIEN -->
<select id="country">
<button onclick="navigate(document.getElementById('country').value)">
  Ir
</button>

<!-- Navegación consistente -->
<!-- Mismo orden de menú en todas las páginas -->
```

#### 3.3 Ayuda en la Entrada (A/AA)
```html
<!-- Identificar errores -->
<label for="email">Email</label>
<input
  id="email"
  type="email"
  aria-invalid="true"
  aria-describedby="email-error"
>
<span id="email-error" role="alert">
  Por favor ingresa un email válido
</span>

<!-- Prevención de errores (para acciones importantes) -->
<dialog>
  <p>¿Confirmas la eliminación de tu cuenta?</p>
  <button>Cancelar</button>
  <button>Confirmar eliminación</button>
</dialog>
```

### 4. Robust

#### 4.1 Compatible (A)
```html
<!-- HTML válido -->
<!-- IDs únicos, tags cerrados, atributos quoted -->

<!-- ARIA correcto -->
<!-- Roles válidos, states booleanos, properties con valores válidos -->
<button aria-expanded="false" aria-controls="menu">
  Menú
</button>
<ul id="menu" hidden>...</ul>
```

---

## ARIA Patterns

### Roles Comunes

| Rol | Uso | Ejemplo |
|-----|-----|---------|
| `button` | Elemento clickeable | `<div role="button">` |
| `dialog` | Modal/popup | `<div role="dialog">` |
| `alert` | Mensaje importante | `<div role="alert">` |
| `tablist/tab/tabpanel` | Pestañas | Ver ejemplo abajo |
| `menu/menuitem` | Menú de acciones | Dropdown menu |
| `navigation` | Área de navegación | `<nav>` equivalente |
| `search` | Área de búsqueda | Form de búsqueda |

### Estados y Propiedades

```html
<!-- Estados (cambian con interacción) -->
aria-expanded="true|false"
aria-selected="true|false"
aria-checked="true|false|mixed"
aria-pressed="true|false"
aria-hidden="true|false"
aria-disabled="true"
aria-invalid="true"

<!-- Propiedades (generalmente estáticas) -->
aria-label="Descripción"
aria-labelledby="id-del-label"
aria-describedby="id-descripcion"
aria-controls="id-controlado"
aria-owns="id-owned"
aria-live="polite|assertive|off"
aria-atomic="true|false"
```

### Patrones de Componentes

#### Tabs
```html
<div role="tablist" aria-label="Secciones">
  <button
    role="tab"
    aria-selected="true"
    aria-controls="panel-1"
    id="tab-1"
  >
    Tab 1
  </button>
  <button
    role="tab"
    aria-selected="false"
    aria-controls="panel-2"
    id="tab-2"
    tabindex="-1"
  >
    Tab 2
  </button>
</div>

<div
  role="tabpanel"
  id="panel-1"
  aria-labelledby="tab-1"
>
  Contenido 1
</div>
<div
  role="tabpanel"
  id="panel-2"
  aria-labelledby="tab-2"
  hidden
>
  Contenido 2
</div>
```

#### Modal
```html
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title"
  aria-describedby="dialog-desc"
>
  <h2 id="dialog-title">Título del Modal</h2>
  <p id="dialog-desc">Descripción del propósito</p>

  <!-- Contenido -->

  <button>Cancelar</button>
  <button>Confirmar</button>
</div>

<!-- Focus management requerido:
1. Focus al abrir va al primer elemento focuseable o al dialog
2. Focus queda atrapado dentro del modal
3. Escape cierra el modal
4. Focus vuelve al elemento que abrió el modal
-->
```

#### Accordion
```html
<div class="accordion">
  <h3>
    <button
      aria-expanded="false"
      aria-controls="section1"
    >
      Sección 1
    </button>
  </h3>
  <div id="section1" hidden>
    Contenido colapsado
  </div>
</div>
```

#### Live Regions
```html
<!-- Para mensajes de feedback -->
<div aria-live="polite" aria-atomic="true" class="sr-only">
  <!-- Contenido dinámico anunciado por SR -->
</div>

<!-- Para alertas urgentes -->
<div role="alert">
  Error: No se pudo guardar
</div>

<!-- Para actualizaciones de progreso -->
<div
  role="progressbar"
  aria-valuenow="25"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-label="Cargando"
>
  25%
</div>
```

---

## Formularios Accesibles

### Labels
```html
<!-- Explícito (preferido) -->
<label for="name">Nombre</label>
<input id="name" type="text">

<!-- Implícito -->
<label>
  Nombre
  <input type="text">
</label>

<!-- Con aria-label (solo si no hay label visible) -->
<input type="search" aria-label="Buscar productos">

<!-- Con aria-labelledby (múltiples fuentes) -->
<span id="billing">Facturación</span>
<span id="name">Nombre</span>
<input aria-labelledby="billing name">
```

### Instrucciones y Errores
```html
<label for="password">Contraseña</label>
<input
  id="password"
  type="password"
  aria-describedby="password-hint password-error"
  aria-invalid="true"
  aria-required="true"
>
<span id="password-hint">Mínimo 8 caracteres</span>
<span id="password-error" role="alert">
  La contraseña es muy corta
</span>
```

### Grupos de Campos
```html
<fieldset>
  <legend>Método de envío</legend>
  <label>
    <input type="radio" name="shipping" value="standard">
    Estándar (3-5 días)
  </label>
  <label>
    <input type="radio" name="shipping" value="express">
    Express (1-2 días)
  </label>
</fieldset>
```

---

## Patrones de UX

### Estados de Carga
```html
<!-- Loading spinner -->
<div role="status" aria-live="polite">
  <span class="spinner" aria-hidden="true"></span>
  <span class="sr-only">Cargando...</span>
</div>

<!-- Skeleton screens -->
<div aria-busy="true" aria-label="Cargando contenido">
  <div class="skeleton-line"></div>
  <div class="skeleton-line"></div>
</div>
```

### Estados Vacíos
```html
<div role="status">
  <p>No hay resultados para "xyz"</p>
  <p>Intenta con otros términos de búsqueda</p>
</div>
```

### Feedback de Acciones
```html
<!-- Toast/Notification -->
<div
  role="status"
  aria-live="polite"
  class="toast"
>
  Cambios guardados correctamente
</div>

<!-- Error crítico -->
<div role="alert">
  Error al procesar el pago. Por favor intenta de nuevo.
</div>
```

### Navegación Móvil
```html
<button
  aria-expanded="false"
  aria-controls="mobile-menu"
  aria-label="Abrir menú de navegación"
>
  <span class="hamburger" aria-hidden="true"></span>
</button>
<nav id="mobile-menu" hidden>
  <!-- Links -->
</nav>
```

---

## Testing de Accesibilidad

### Herramientas Automatizadas

```typescript
// Jest + Testing Library
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

it('should have no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

```bash
# Lighthouse CLI
npx lighthouse http://localhost:3000 --only-categories=accessibility

# axe CLI
npx @axe-core/cli http://localhost:3000

# Pa11y
npx pa11y http://localhost:3000
```

### Testing Manual

#### Checklist de Teclado
1. Tab navega en orden lógico
2. Shift+Tab navega hacia atrás
3. Enter/Space activan botones y links
4. Escape cierra modales y popups
5. Arrow keys navegan en tabs, menús, sliders
6. Focus siempre visible

#### Checklist de Screen Reader
1. Todo contenido tiene texto alternativo
2. Headings describen secciones
3. Links tienen texto descriptivo
4. Formularios anuncian labels y errores
5. Cambios dinámicos se anuncian
6. Tablas tienen headers

#### Zoom Testing
1. Funciona al 200% sin scroll horizontal
2. Texto es legible
3. Layout no se rompe
4. Touch targets siguen accesibles

---

## HTML Semántico

### Elementos Correctos

| En vez de | Usar |
|-----------|------|
| `<div onclick>` | `<button>` |
| `<span>` para título | `<h1>-<h6>` |
| `<div>` para lista | `<ul>`, `<ol>`, `<dl>` |
| `<div>` para nav | `<nav>` |
| `<div>` para artículo | `<article>` |
| `<div>` para aside | `<aside>` |
| `<div>` para pie | `<footer>` |
| `<b>` para énfasis | `<strong>` |
| `<i>` para énfasis | `<em>` |

### Landmarks

```html
<body>
  <header>
    <nav aria-label="Principal">...</nav>
  </header>

  <nav aria-label="Breadcrumb">...</nav>

  <main>
    <article>
      <header>...</header>
      <section>...</section>
      <footer>...</footer>
    </article>
    <aside>...</aside>
  </main>

  <footer>...</footer>
</body>
```

---

## Checklist Rápido

### Pre-commit UI
- [ ] Labels en todos los inputs
- [ ] Alt en todas las imágenes
- [ ] Heading hierarchy lógica
- [ ] Focus visible en interactivos
- [ ] Contraste verificado
- [ ] Navegación por teclado funciona
- [ ] ARIA solo donde es necesario
- [ ] No hay trampas de focus

### Por Componente
- [ ] Semántica HTML correcta
- [ ] Estados comunicados (aria-expanded, etc.)
- [ ] Errores identificados claramente
- [ ] Loading states anunciados
- [ ] Color no es único indicador

---

## WCAG 2.2 — Criterios Nuevos

> Criterios añadidos en WCAG 2.2 (octubre 2023) que NO estaban en WCAG 2.1.
> El gate `rules/accessibility-gate.md` aplica nivel AA de WCAG 2.2 — estos criterios son bloqueantes.

| ID | Nombre | Nivel | Descripción | Ejemplo de violación |
|----|--------|-------|-------------|----------------------|
| **2.4.11** | Focus Not Obscured | AA | El componente con foco por teclado no debe estar completamente oculto por contenido sticky (headers, footers, banners). | Un sticky header cubre completamente el input que recibe foco al hacer Tab. |
| **2.4.12** | Focus Not Obscured (Enhanced) | AAA | El componente con foco no debe estar parcialmente oculto por contenido sticky. | La mitad del botón enfocado queda detrás de un cookie banner. |
| **2.4.13** | Focus Appearance | AAA | El indicador de foco debe tener al menos 2px de grosor y suficiente contraste (3:1 mínimo). | Un outline de 1px con color gris claro sobre fondo blanco. |
| **2.5.7** | Dragging Movements | AA | Toda funcionalidad de arrastre debe tener una alternativa de un solo puntero (clic/tap). | Un slider que solo puede manipularse arrastrando, sin botones +/- alternativos. |
| **2.5.8** | Target Size (Minimum) | AA | Los targets interactivos deben tener al menos 24×24 CSS pixels (o espacio equivalente alrededor). | Un ícono de cierre de 16×16px sin padding adicional. |
| **3.2.6** | Consistent Help | A | Si existe un mecanismo de ayuda (chat, FAQ, teléfono), debe aparecer en la misma posición relativa en todas las páginas. | El botón de chat flotante aparece en esquina inferior derecha en home pero en superior izquierda en checkout. |
| **3.3.7** | Redundant Entry | A | No se debe pedir al usuario información que ya proporcionó en el mismo proceso. | Pedir nuevamente el email en el paso de confirmación cuando ya fue ingresado en el registro. |
| **3.3.8** | Accessible Authentication (Minimum) | AA | Los procesos de autenticación no deben requerir test cognitivo (transcribir texto distorsionado) sin alternativa. | CAPTCHA de texto sin opción de audio ni alternativa basada en objetos. |
| **3.3.9** | Accessible Authentication (Enhanced) | AAA | Los procesos de autenticación no deben requerir ningún test cognitivo, incluyendo reconocimiento de objetos. | CAPTCHA de imágenes sin alternativa de ningún tipo. |

> **Nota**: WCAG 2.2 eliminó el criterio 4.1.1 (Parsing) que existía en WCAG 2.1 por ser redundante con la madurez actual de los parsers de HTML.

---

## Recursos

- WCAG 2.1: https://www.w3.org/TR/WCAG21/
- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- ARIA Practices: https://www.w3.org/WAI/ARIA/apg/
- WebAIM: https://webaim.org/
- Deque University: https://dequeuniversity.com/
- a11y Project: https://www.a11yproject.com/
