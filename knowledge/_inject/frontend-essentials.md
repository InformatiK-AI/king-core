# UX/Accessibility Essentials (para inyección)

> **Nota**: Este archivo complementa `knowledge/universal/accessibility.md` con contenido específico para inyección en el agente @frontend. El knowledge universal cubre fundamentos; este archivo cubre checklists de acción.

> Versión compacta para inyección en agents. Referencia completa: `universal/accessibility.md`

## WCAG Quick Check

| Criterio | Nivel | Verificación |
|----------|-------|--------------|
| Alt text | A | Imágenes informativas tienen alt descriptivo |
| Contraste | AA | Texto 4.5:1, grande 3:1, UI 3:1 |
| Keyboard | A | Todo operable sin mouse |
| Focus visible | AA | Outline claro en :focus-visible |
| Labels | A | Todos los inputs tienen label |
| Headings | A | h1→h2→h3 en orden lógico |
| Errors | A | Identifican el campo con problema |
| Language | A | `<html lang="es">` definido |

## Patterns Obligatorios

```html
<!-- Botón con icono -->
<button aria-label="Cerrar">
  <svg aria-hidden="true">...</svg>
</button>

<!-- Input con error -->
<label for="email">Email</label>
<input id="email" aria-invalid="true" aria-describedby="err">
<span id="err" role="alert">Email inválido</span>

<!-- Modal -->
<div role="dialog" aria-modal="true" aria-labelledby="title">
  <h2 id="title">Título</h2>
</div>

<!-- Loading -->
<div role="status" aria-live="polite">Cargando...</div>

<!-- Skip link -->
<a href="#main" class="skip-link">Saltar al contenido</a>
```

## Señales de Alerta

- `<div onclick>` sin `role="button"` y `tabindex="0"`
- Input sin `<label>` o `aria-label`
- Imagen sin `alt` (o `alt=""` en imagen informativa)
- Contraste texto/fondo < 4.5:1
- `:focus { outline: none }` sin alternativa
- Modal sin focus trap
- Contenido solo por color (rojo=error)
- Autoplay en video/audio

## Checklist Pre-Commit UI

- [ ] Todos los inputs tienen label visible o aria-label
- [ ] Imágenes tienen alt apropiado
- [ ] Headings en orden jerárquico
- [ ] Tab navega en orden lógico
- [ ] Focus visible en todos los interactivos
- [ ] Contraste ≥ 4.5:1 (texto normal)
- [ ] Errores identifican el campo
- [ ] Modales atrapan focus y cierran con Escape
