# Performance Knowledge Base

## Propósito
Conocimiento experto de performance que se inyecta en agents durante /genesis.
Este conocimiento aplica a TODOS los proyectos, independiente del stack.

---

## Principios Fundamentales

### 1. Medir antes de optimizar
```
"Premature optimization is the root of all evil" - Donald Knuth

Flujo correcto:
1. Identificar problema real (no supuesto)
2. Medir con herramientas
3. Optimizar el cuello de botella
4. Medir de nuevo
5. Repetir
```

### 2. La regla del 80/20
- 80% del tiempo se gasta en 20% del código
- Optimizar ese 20% tiene impacto real
- El resto es micro-optimización sin impacto

### 3. Optimizar para el caso común
- No optimizar edge cases raros
- Priorizar el happy path

---

## Big O Notation

### Complejidades comunes
```
O(1)        Constante       Hash lookup, array access
O(log n)    Logarítmica     Binary search
O(n)        Lineal          Loop simple
O(n log n)  Linearítmica    Merge sort, quick sort
O(n²)       Cuadrática      Nested loops
O(2^n)      Exponencial     Subsets, backtracking
O(n!)       Factorial       Permutaciones
```

### Visualización de impacto
```
n = 1000 elementos

O(1)        →  1 operación
O(log n)    →  10 operaciones
O(n)        →  1,000 operaciones
O(n log n)  →  10,000 operaciones
O(n²)       →  1,000,000 operaciones
O(2^n)      →  impracticable
```

### Análisis práctico
```typescript
// O(1) - Constante
const first = array[0];
const value = hashMap.get(key);

// O(n) - Lineal
const found = array.find(x => x.id === id);
const total = array.reduce((sum, x) => sum + x, 0);

// O(n²) - Cuadrática - EVITAR con n grande
for (let i = 0; i < n; i++) {
  for (let j = 0; j < n; j++) {
    // ...
  }
}

// O(n) optimización de O(n²)
const set = new Set(array1.map(x => x.id));
const intersection = array2.filter(x => set.has(x.id));
```

---

## Profiling

### Qué buscar
```
1. Hot paths     → Código que se ejecuta muchísimo
2. Slow paths    → Código que tarda mucho
3. Memory leaks  → Memoria que no se libera
4. Blocking ops  → I/O síncrono que bloquea
```

### Herramientas por plataforma
```
JavaScript/Node:
- Chrome DevTools Performance
- Node --prof / --inspect
- clinic.js

Python:
- cProfile
- py-spy
- memory_profiler

Go:
- pprof
- trace

Rust:
- perf
- flamegraph
```

### Flame Graphs
```
Lectura de flame graphs:
- Ancho = tiempo en esa función
- Altura = profundidad de call stack
- Buscar funciones anchas (hot spots)
- Buscar torres altas (deep recursion)

   ┌─────────────────────────────────┐
   │        processRequest          │
   ├──────────────┬──────────────────┤
   │  validateInput │    saveToDb     │  ← saveToDb es ancho = lento
   ├──────────────┤                  │
   │   parseJSON   │                  │
   └──────────────┴──────────────────┘
```

---

## Caching

### Cuándo cachear
```
✓ Datos que se leen mucho y cambian poco
✓ Cálculos costosos con inputs repetidos
✓ Respuestas de APIs externas (con TTL)

✗ Datos que cambian constantemente
✗ Datos únicos por usuario/request
✗ Datos pequeños que son rápidos de obtener
```

### Estrategias
```
Cache-Aside (Lazy Loading):
1. Buscar en cache
2. Si no existe, buscar en DB
3. Guardar en cache
4. Retornar

Write-Through:
1. Escribir en cache Y DB simultáneamente
2. Siempre consistente, más lento

Write-Behind:
1. Escribir en cache
2. Async escribir en DB
3. Más rápido, riesgo de pérdida
```

### Implementación
```typescript
// Cache-Aside pattern
async function getUser(id: string): Promise<User> {
  // 1. Check cache
  const cached = await cache.get(`user:${id}`);
  if (cached) return JSON.parse(cached);

  // 2. Fetch from DB
  const user = await db.users.findById(id);
  if (!user) throw new NotFoundError();

  // 3. Store in cache
  await cache.set(`user:${id}`, JSON.stringify(user), 'EX', 3600);

  return user;
}

// Invalidar cache al actualizar
async function updateUser(id: string, data: Partial<User>) {
  await db.users.update(id, data);
  await cache.del(`user:${id}`);  // Invalidar
}
```

### Cache Invalidation
```
"There are only two hard things in CS:
cache invalidation and naming things"

Estrategias:
1. TTL (Time To Live)    → Expira automáticamente
2. Event-based           → Invalidar en update
3. Version-based         → key:v2 reemplaza key:v1
```

---

## Database Performance

### Índices
```sql
-- Crear índice en columnas usadas en WHERE, JOIN, ORDER BY
CREATE INDEX idx_users_email ON users(email);

-- Índice compuesto para queries combinadas
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- EXPLAIN para verificar uso de índice
EXPLAIN SELECT * FROM users WHERE email = 'test@test.com';
```

### Query optimization
```sql
-- MAL: SELECT * trae todo
SELECT * FROM orders WHERE user_id = 123;

-- BIEN: Solo columnas necesarias
SELECT id, total, status FROM orders WHERE user_id = 123;

-- MAL: N+1 queries
for user in users:
    orders = db.query("SELECT * FROM orders WHERE user_id = ?", user.id)

-- BIEN: JOIN o batch
SELECT u.*, o.* FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.id IN (1, 2, 3);
```

### N+1 Problem
```typescript
// MAL: N+1 queries (1 + N)
const users = await User.findAll();
for (const user of users) {
  user.orders = await Order.findAll({ where: { userId: user.id }});
}

// BIEN: Eager loading (1 + 1)
const users = await User.findAll({
  include: [{ model: Order }]
});

// O batch loading
const users = await User.findAll();
const userIds = users.map(u => u.id);
const orders = await Order.findAll({ where: { userId: userIds }});
```

### Connection Pooling
```typescript
// Pool de conexiones (no crear conexión por request)
const pool = createPool({
  host: 'localhost',
  user: 'root',
  database: 'mydb',
  connectionLimit: 10,      // Max conexiones
  queueLimit: 0,            // Max en espera
  waitForConnections: true  // Esperar si pool lleno
});

// Uso
const connection = await pool.getConnection();
try {
  await connection.query('SELECT ...');
} finally {
  connection.release();  // SIEMPRE liberar
}
```

---

## Network Performance

### Reducir requests
```typescript
// MAL: Múltiples requests pequeños
const user = await fetch('/api/user/1');
const orders = await fetch('/api/user/1/orders');
const reviews = await fetch('/api/user/1/reviews');

// BIEN: Un request agregado
const userData = await fetch('/api/user/1?include=orders,reviews');

// O GraphQL
const { user, orders, reviews } = await graphql(`
  query {
    user(id: 1) {
      name
      orders { id, total }
      reviews { id, rating }
    }
  }
`);
```

### Compression
```typescript
// Habilitar gzip/brotli
app.use(compression({
  level: 6,  // Balance velocidad/ratio
  threshold: 1024  // Solo >1KB
}));
```

### Pagination
```typescript
// SIEMPRE paginar listas
app.get('/users', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);
  const offset = (page - 1) * limit;

  const [users, total] = await Promise.all([
    db.users.findMany({ skip: offset, take: limit }),
    db.users.count()
  ]);

  res.json({
    data: users,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  });
});
```

---

## Memory Management

### Memory Leaks comunes
```typescript
// 1. Event listeners no removidos
class Component {
  mount() {
    window.addEventListener('resize', this.onResize);
  }
  unmount() {
    window.removeEventListener('resize', this.onResize); // IMPORTANTE
  }
}

// 2. Closures que retienen referencias
function createHandler() {
  const hugeData = loadHugeData();  // Retenido por closure
  return () => {
    console.log(hugeData.length);   // hugeData nunca se libera
  };
}

// 3. Cache sin límite
const cache = {};  // Crece infinitamente
function memoize(fn) {
  return (key) => {
    if (!cache[key]) cache[key] = fn(key);
    return cache[key];
  };
}

// SOLUCIÓN: LRU Cache con límite
const LRU = require('lru-cache');
const cache = new LRU({ max: 500 });
```

### Streaming vs Loading
```typescript
// MAL: Cargar todo en memoria
const data = fs.readFileSync('huge-file.csv');
const rows = parseCSV(data);

// BIEN: Stream
const stream = fs.createReadStream('huge-file.csv');
const parser = stream.pipe(csvParser());

parser.on('data', (row) => {
  processRow(row);  // Procesa uno a la vez
});
```

---

## Async Performance

### Paralelismo
```typescript
// MAL: Secuencial
const user = await getUser(id);
const orders = await getOrders(id);
const reviews = await getReviews(id);
// Total: t1 + t2 + t3

// BIEN: Paralelo
const [user, orders, reviews] = await Promise.all([
  getUser(id),
  getOrders(id),
  getReviews(id)
]);
// Total: max(t1, t2, t3)
```

### Promise.all vs Promise.allSettled
```typescript
// Promise.all: Falla si cualquiera falla
const results = await Promise.all(promises);

// Promise.allSettled: Continúa aunque alguno falle
const results = await Promise.allSettled(promises);
results.forEach(r => {
  if (r.status === 'fulfilled') {
    console.log(r.value);
  } else {
    console.error(r.reason);
  }
});
```

### Rate Limiting requests
```typescript
// Limitar requests concurrentes
import pLimit from 'p-limit';

const limit = pLimit(5);  // Max 5 concurrent

const results = await Promise.all(
  urls.map(url => limit(() => fetch(url)))
);
```

---

## Lazy Loading

### Módulos
```typescript
// MAL: Import estático de todo
import { HeavyChart } from './heavy-chart';

// BIEN: Dynamic import cuando se necesita
const HeavyChart = await import('./heavy-chart');
```

### Componentes (React)
```typescript
// Lazy loading de componentes
const HeavyComponent = React.lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyComponent />
    </Suspense>
  );
}
```

### Imágenes
```html
<!-- Native lazy loading -->
<img src="image.jpg" loading="lazy" />

<!-- Con Intersection Observer para más control -->
```

---

## Performance Budgets

### Métricas clave (Web)
```
LCP (Largest Contentful Paint)  < 2.5s
FID (First Input Delay)         < 100ms
CLS (Cumulative Layout Shift)   < 0.1
TTI (Time to Interactive)       < 5s
Bundle size (JS)                < 200KB gzipped
```

### Métricas clave (API)
```
P50 latency    < 100ms
P95 latency    < 500ms
P99 latency    < 1s
Error rate     < 0.1%
```

### Enforcement
```json
// package.json
{
  "bundlesize": [
    {
      "path": "./dist/main.js",
      "maxSize": "100 kB"
    }
  ]
}
```

---

## Checklist de Performance

### Antes de lanzar
- [ ] Profiling ejecutado, hot spots identificados
- [ ] Queries tienen índices apropiados
- [ ] N+1 queries eliminados
- [ ] Assets comprimidos y minificados
- [ ] Lazy loading implementado
- [ ] Caching estratégico configurado

### Monitoreo continuo
- [ ] Métricas de latencia capturadas
- [ ] Alertas en degradación
- [ ] Performance budgets en CI
- [ ] Dashboards de performance

### Red flags
- [ ] Loops O(n²) con n grande
- [ ] SELECT * en tablas grandes
- [ ] Sin paginación en listas
- [ ] Cache sin límite/TTL
- [ ] Sync I/O en hot paths
