# Mobile Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `knowledge/universal/accessibility.md`

## Constraints Críticos

| Constraint | Valor mínimo | Consecuencia si se viola |
|-----------|-------------|--------------------------|
| Touch target | 44×44 px | Toques fallidos, UX degradada |
| Viewport mínimo | 320 px ancho | Layout roto en iPhones SE |
| FPS animaciones | 60 fps | Sensación de lag |
| Bundle inicial | < 200 KB | Tiempo de carga inaceptable en 3G |
| Tiempo de carga 3G | < 5s | Abandono del usuario |

## Offline & Conectividad

```javascript
// Detectar estado de red
navigator.onLine // básico
window.addEventListener('offline', showOfflineBanner);

// Service Worker — cachear assets críticos
self.addEventListener('install', e => e.waitUntil(
  caches.open('v1').then(cache => cache.addAll(CRITICAL_ASSETS))
));
```

## Compatibilidad de Plataforma

| API Web | iOS Safari | Chrome Android | Alternativa |
|---------|-----------|----------------|-------------|
| `position: sticky` | ✅ | ✅ | — |
| Web Notifications | ❌ PWA | ✅ | FCM / APNs nativo |
| Vibration API | ❌ | ✅ | Omitir gracefully |
| Input `type=date` | UI nativa | UI nativa | Verificar UX en ambos |

## Señales de Alerta

- Touch targets < 44px (especialmente en navegación)
- `overflow: hidden` en body → scroll roto en iOS
- `position: fixed` + `transform` → bug de stacking en Safari
- `vh` unidades sin fallback → barra de navegación oculta contenido
- Sin feedback visual en tap (300ms delay sin `touch-action: manipulation`)
- Imágenes sin `loading="lazy"` ni dimensiones declaradas

## Checklist Mobile

- [ ] Viewport meta tag: `<meta name="viewport" content="width=device-width, initial-scale=1">`
- [ ] Touch targets ≥ 44×44 px verificados
- [ ] Layout probado en 320px y 768px de ancho
- [ ] Comportamiento offline definido (banner + cache)
- [ ] Animaciones con `will-change` o `transform` (GPU-accelerated)
- [ ] Teclado virtual no oculta inputs en iOS
