# Performance Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `universal/performance.md`

## Métricas Clave

| Métrica | Target | Crítico |
|---------|--------|---------|
| Time to First Byte (TTFB) | < 200ms | > 600ms |
| First Contentful Paint (FCP) | < 1.8s | > 3s |
| Largest Contentful Paint (LCP) | < 2.5s | > 4s |
| Time to Interactive (TTI) | < 3.8s | > 7.3s |
| API Response | < 100ms | > 500ms |

## Patterns Rápidos

```typescript
// Lazy loading - SIEMPRE para rutas
const Dashboard = lazy(() => import('./Dashboard'));

// Memoization - Solo cuando necesario
const expensive = useMemo(() => compute(data), [data]);

// Debounce - Para input de usuario
const debouncedSearch = useMemo(
  () => debounce(search, 300),
  []
);

// Pagination - NUNCA cargar todo
const { data } = useQuery(['items', page],
  () => fetchItems({ page, limit: 20 })
);
```

## Señales de Alerta

- `useEffect` sin dependencias que hace fetch
- `.map().filter().reduce()` encadenados en renders
- Imágenes sin `loading="lazy"` ni dimensiones
- Bundle > 250KB sin code splitting
- N+1 queries en backend

## Checklist Pre-Deploy

- [ ] Bundle analizado (webpack-bundle-analyzer)
- [ ] Imágenes optimizadas (WebP, tamaños correctos)
- [ ] Lazy loading en rutas
- [ ] Cache headers configurados
- [ ] Queries con índices (EXPLAIN)
