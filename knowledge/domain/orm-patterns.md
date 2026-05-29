# ORM Patterns y Anti-Patterns — Guía de Persistencia

> Versión completa. Para inyección en agents usar `knowledge/_inject/orm-patterns.md`.
> Skill asociado: `/explain-query`. Agente: `@performance` (sección "ORM Checks").

---

## Mapa Mental

| Capa | Responsabilidad | Patrón aplicable |
|------|-----------------|------------------|
| Dominio | Reglas de negocio puras | Specification |
| Aplicación | Orquestación, transacciones | Unit of Work |
| Persistencia | Acceso a datos, sin tipos ORM filtrados | Repository |
| Lectura | Vistas optimizadas, proyecciones | Read/Write Split |

**Regla de oro**: el dominio NUNCA importa tipos del ORM. Si `import { Prisma }` aparece en `domain/`, hay una abstracción filtrada (leaked abstraction).

---

## PATRONES

## 1. Repository Pattern

### Problema que resuelve
El código de negocio termina acoplado al ORM concreto. Cambiar de Prisma a Drizzle, o testear sin DB real, se vuelve imposible porque las llamadas `prisma.user.findMany(...)` están esparcidas por servicios, controllers y casos de uso. El tipo `Prisma.UserGetPayload<...>` se filtra hasta el dominio.

El Repository define un **contrato de persistencia en términos del dominio** (entidades, no filas) y oculta el ORM detrás de una interfaz.

### Antes (acoplado al ORM)

```typescript
// application/create-order.ts — el caso de uso conoce Prisma
import { PrismaClient, Prisma } from '@prisma/client';

export class CreateOrderUseCase {
  constructor(private prisma: PrismaClient) {}

  async execute(input: CreateOrderInput) {
    // Tipo del ORM filtrado al dominio
    const user: Prisma.UserGetPayload<{ include: { wallet: true } }> | null =
      await this.prisma.user.findUnique({
        where: { id: input.userId },
        include: { wallet: true },
      });
    if (!user) throw new Error('user not found');
    if (user.wallet.balance < input.total) throw new Error('insufficient funds');

    return this.prisma.order.create({ data: { userId: user.id, total: input.total } });
  }
}
```

### Después (Repository con contrato de dominio)

```typescript
// domain/repositories/user-repository.ts — interfaz, cero ORM
export interface UserRepository {
  findById(id: UserId): Promise<User | null>; // User es entidad de dominio
}

// infrastructure/prisma-user-repository.ts — el ORM vive SOLO aquí
export class PrismaUserRepository implements UserRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: UserId): Promise<User | null> {
    const row = await this.prisma.user.findUnique({
      where: { id: id.value },
      include: { wallet: true },
    });
    return row ? UserMapper.toDomain(row) : null; // mapper traduce fila → entidad
  }
}

// application/create-order.ts — depende de la interfaz, testeable con mock
export class CreateOrderUseCase {
  constructor(
    private users: UserRepository,
    private orders: OrderRepository,
  ) {}

  async execute(input: CreateOrderInput): Promise<Order> {
    const user = await this.users.findById(new UserId(input.userId));
    if (!user) throw new UserNotFoundError(input.userId);
    user.assertCanAfford(input.total); // regla EN la entidad, no en la query
    return this.orders.save(Order.create(user.id, input.total));
  }
}
```

### Señales de alarma
- `import` del ORM (`@prisma/client`, `typeorm`, `sqlalchemy`) en `domain/` o `application/`.
- Tipos generados por el ORM (`Prisma.XGetPayload`, `Entity` de TypeORM) usados como tipos de retorno fuera de `infrastructure/`.
- Tests que necesitan una base de datos real para probar una regla de negocio.
- Métodos del repository que devuelven `any` o el row crudo en vez de una entidad.

---

## 2. Unit of Work

### Problema que resuelve
Una operación de negocio toca varias tablas (crear orden + descontar saldo + escribir log). Si cada repository commitea por su cuenta, un fallo a mitad de camino deja **escrituras parciales** (partial writes): la orden existe pero el saldo no se descontó. El Unit of Work agrupa todas las escrituras en una sola transacción con commit/rollback coordinado.

### Antes (escrituras parciales)

```typescript
async function checkout(input: CheckoutInput) {
  await orderRepo.save(order);        // commit 1 — OK
  await walletRepo.debit(userId, total); // commit 2 — si esto falla...
  await auditRepo.log(event);         // ...la orden YA quedó persistida. Inconsistente.
}
```

### Después (Unit of Work)

```typescript
// infrastructure/prisma-unit-of-work.ts
export class PrismaUnitOfWork implements UnitOfWork {
  constructor(private prisma: PrismaClient) {}

  async run<T>(work: (ctx: RepoContext) => Promise<T>): Promise<T> {
    return this.prisma.$transaction(async (tx) => {
      const ctx: RepoContext = {
        orders: new PrismaOrderRepository(tx),  // los repos usan la MISMA tx
        wallets: new PrismaWalletRepository(tx),
        audit: new PrismaAuditRepository(tx),
      };
      return work(ctx); // si lanza → Prisma hace rollback de TODO
    });
  }
}

// application/checkout.ts
async function checkout(input: CheckoutInput, uow: UnitOfWork) {
  return uow.run(async ({ orders, wallets, audit }) => {
    const order = Order.create(input.userId, input.total);
    await orders.save(order);
    await wallets.debit(input.userId, input.total); // si falla, la orden NO se persiste
    await audit.log(OrderCreated.from(order));
    return order; // commit atómico al salir sin error
  });
}
```

```python
# SQLAlchemy — el Session ES el Unit of Work nativo
async def checkout(input: CheckoutInput, session: AsyncSession) -> Order:
    async with session.begin():            # abre transacción; commit/rollback automático
        order = Order.create(input.user_id, input.total)
        session.add(order)
        await debit_wallet(session, input.user_id, input.total)
        session.add(AuditLog.order_created(order))
        # al salir del bloque sin excepción → commit; con excepción → rollback
    return order
```

### Señales de alarma
- Varios `await repo.save(...)` consecutivos sin transacción que los envuelva.
- Estados intermedios visibles tras un fallo (una entidad creada y otra no).
- Repos que reciben su propia conexión/cliente en vez de un contexto transaccional compartido.
- Lógica de compensación manual ("si falla el segundo paso, borro el primero") — eso es un rollback hecho a mano y frágil.

---

## 3. Specification Pattern

### Problema que resuelve
El repository se llena de métodos: `findActiveUsers`, `findActiveUsersByCountry`, `findActivePremiumUsersByCountry`... La combinatoria explota. El Specification encapsula cada criterio como un objeto componible (`AND`, `OR`, `NOT`) y el repository expone UN método `findMany(spec)`.

### Antes (proliferación de métodos)

```typescript
interface UserRepository {
  findActive(): Promise<User[]>;
  findActiveByCountry(country: string): Promise<User[]>;
  findActivePremiumByCountry(country: string): Promise<User[]>;
  findInactiveOlderThan(days: number): Promise<User[]>;
  // ...y seguirá creciendo con cada nueva combinación
}
```

### Después (specifications componibles)

```typescript
// domain/specifications/specification.ts
export interface Specification<T> {
  isSatisfiedBy(candidate: T): boolean;          // para validación en memoria
  toQuery(): Prisma.UserWhereInput;              // traducción a filtro ORM
}

export class ActiveUser implements Specification<User> {
  isSatisfiedBy(u: User) { return u.status === 'active'; }
  toQuery() { return { status: 'active' }; }
}

export class FromCountry implements Specification<User> {
  constructor(private code: string) {}
  isSatisfiedBy(u: User) { return u.country === this.code; }
  toQuery() { return { country: this.code }; }
}

// Combinador AND genérico
export class And<T> implements Specification<T> {
  constructor(private specs: Specification<T>[]) {}
  isSatisfiedBy(c: T) { return this.specs.every(s => s.isSatisfiedBy(c)); }
  toQuery() { return { AND: this.specs.map(s => s.toQuery()) }; }
}

// El repository expone UN solo método
interface UserRepository {
  findMany(spec: Specification<User>): Promise<User[]>;
}

// Uso — se componen criterios en el caso de uso, no en el repo
const spec = new And([new ActiveUser(), new FromCountry('CL'), new Premium()]);
const users = await repo.findMany(spec);
```

### Señales de alarma
- Más de 8-10 métodos `findX` en un repository, muchos con nombres casi idénticos.
- Métodos con explosión de parámetros opcionales (`find(active?, country?, premium?, ...)`).
- Criterios de negocio (qué es "usuario activo") duplicados en queries y en validaciones de servicio.
- Copy-paste de cláusulas `WHERE` entre métodos.

---

## 4. Read/Write Split (CQRS-lite)

### Problema que resuelve
Cargar un agregado completo (con todas sus relaciones e invariantes) solo para mostrar una tabla en pantalla es caro y mezcla responsabilidades. La escritura necesita el agregado consistente; la lectura solo necesita una **proyección plana**. Separar read models de write models permite además rutear lecturas a réplicas y escrituras al primario.

### Antes (un solo modelo para todo)

```typescript
// Carga el agregado entero (12 relaciones) solo para una lista de 3 columnas
const orders = await orderRepo.findAll(); // hidrata Order + items + payments + shipping...
return orders.map(o => ({ id: o.id, total: o.total, status: o.status }));
```

### Después (read model dedicado + routing de réplica)

```typescript
// WRITE side — agregado consistente, va al primario
export class OrderRepository {
  constructor(private primary: PrismaClient) {}
  async save(order: Order) { /* agregado completo con invariantes */ }
}

// READ side — proyección plana, va a la réplica
export class OrderReadModel {
  constructor(private replica: PrismaClient) {} // conexión a read-replica

  async listForDashboard(tenantId: string): Promise<OrderRow[]> {
    // SELECT directo de las columnas necesarias — sin hidratar el agregado
    return this.replica.$queryRaw<OrderRow[]>`
      SELECT id, total, status, created_at
      FROM orders
      WHERE tenant_id = ${tenantId}
      ORDER BY created_at DESC
      LIMIT 50`;
  }
}
```

```python
# Routing por motor: dos engines, uno al primario y otro a la réplica
write_engine = create_async_engine(PRIMARY_URL, pool_size=10)
read_engine  = create_async_engine(REPLICA_URL, pool_size=20)  # más lecturas

# La escritura usa el write session; la lectura el read session (réplica)
async def dashboard(tenant_id: str) -> list[OrderRow]:
    async with read_session() as s:
        rows = await s.execute(
            text("SELECT id, total, status FROM orders WHERE tenant_id = :t LIMIT 50"),
            {"t": tenant_id},
        )
        return [OrderRow(*r) for r in rows]  # proyección, no entidades
```

### Señales de alarma
- Listados de UI que hidratan agregados completos con todas sus relaciones.
- Mismo modelo usado para validar invariantes Y para serializar a JSON de respuesta.
- Todas las lecturas pegándole al primario aunque la app sea read-heavy.
- DTOs de respuesta construidos a partir de entidades de dominio con `include` masivos "por las dudas".

> **Cuándo NO aplicarlo**: si la app es pequeña o write-heavy con baja lectura, el split agrega complejidad sin beneficio. Es una optimización, no un default.

---

## ANTI-PATRONES

## 1. N+1 Query

### Cómo detectarlo
1 query para traer N entidades + N queries adicionales para traer una relación de cada una. Patrón visible: un `map`/`forEach`/`for` que itera resultados y dentro accede a una relación lazy o ejecuta otra query.

```typescript
// 1 query: trae N posts
const posts = await postRepo.findAll();

// N queries: una por cada post para traer su autor
for (const post of posts) {
  post.author = await userRepo.findById(post.authorId); // ← N+1
}
```

**Detección en logs**: ráfaga de `SELECT ... WHERE id = ?` idénticas variando solo el parámetro. En desarrollo, activar logging de SQL del ORM revela la ráfaga inmediatamente.

### Por qué duele
100 posts = 101 queries. Cada query tiene round-trip de red + parsing + planning. Latencia que debería ser ~5ms se vuelve ~500ms y escala linealmente con los datos. Es la causa #1 de endpoints lentos en producción.

### Cómo corregirlo

```typescript
// Opción A: eager load en UNA query (JOIN o batch del ORM)
const posts = await postRepo.findAll({ include: { author: true } }); // Prisma

// Opción B: si los IDs ya están, batch con WHERE IN (2 queries totales)
const posts = await postRepo.findAll();
const authorIds = [...new Set(posts.map(p => p.authorId))];
const authors = await userRepo.findMany({ where: { id: { in: authorIds } } });
const byId = new Map(authors.map(a => [a.id, a]));
posts.forEach(p => { p.author = byId.get(p.authorId)!; });
// De N+1 a exactamente 2 queries
```

---

## 2. God Repository

### Cómo detectarlo
Un repository con más de 10 métodos, que mezcla CRUD con lógica de negocio en las queries, conoce más de una entidad raíz, y es imposible de mockear sin reimplementar media DB.

```typescript
// God Repository — hace de todo
class UserRepository {
  findById() {}
  findByEmail() {}
  findActive() {}
  calculateLifetimeValue() {}     // ← lógica de negocio en el repo
  sendWelcomeEmail() {}           // ← efecto secundario, no persistencia
  generateMonthlyReport() {}      // ← reporting + agregaciones de otras tablas
  syncWithCrm() {}                // ← integración externa
  // ...22 métodos más
}
```

### Por qué duele
Viola Single Responsibility. Cambiar el cálculo de LTV obliga a tocar el repository de persistencia. No se puede testear la regla de negocio sin la DB. Cualquier cambio tiene radio de impacto enorme. El repository deja de ser una abstracción de datos y se vuelve un cajón de sastre.

### Cómo corregirlo
- Mover lógica de negocio a la **entidad** o a un **domain service** (`LtvCalculator`).
- Mover efectos secundarios (emails, CRM) a sus propios servicios/adapters.
- Reporting/agregaciones → un **read model** dedicado, no el repository de escritura.
- Si quedan muchos criterios de búsqueda → **Specification Pattern**.
- El repository final solo persiste y recupera UNA entidad raíz: `findById`, `findMany(spec)`, `save`, `delete`.

---

## 3. Query in Loop

### Cómo detectarlo
Cualquier llamada ORM dentro de `for`, `while`, `forEach`, `map`, comprehensions o recursión. Es la forma generalizada del N+1 — incluye también escrituras en loop.

```typescript
// Lectura en loop (N+1)
for (const id of ids) { results.push(await repo.findById(id)); }

// Escritura en loop — N round-trips de INSERT
for (const item of items) { await repo.create(item); }
```

### Por qué duele
Cada iteración paga el costo completo de un round-trip a la DB. 1000 items = 1000 viajes secuenciales. Una operación batch que tomaría ~20ms toma varios segundos. Además satura el connection pool.

### Cómo corregirlo

```typescript
// Lectura: WHERE IN (1 query)
const results = await repo.findMany({ where: { id: { in: ids } } });

// Escritura: bulk insert (1 query)
await repo.createMany({ data: items }); // Prisma createMany / Drizzle insert.values([...])
```

> **CASTLE T check** (`@performance`): "no queries in loops". Toda llamada ORM dentro de un loop es una violación; la corrección sugerida es `findMany` + `WHERE IN` para lecturas, o bulk insert/update para escrituras.

---

## 4. Anemic Repository (Leaked Abstraction)

### Cómo detectarlo
El repository devuelve un `IQueryable`, `QuerySession`, `QueryBuilder` o el cliente ORM en crudo, dejando que el dominio construya queries. La abstracción "se filtra": el dominio sigue acoplado al ORM, ahora de forma indirecta.

```typescript
// Anemic — el repo expone la mecánica del ORM al dominio
interface UserRepository {
  query(): Prisma.UserDelegate;   // ← devuelve el delegate de Prisma
  queryBuilder(): SelectQueryBuilder<User>; // ← TypeORM QueryBuilder filtrado
}

// El dominio termina escribiendo queries del ORM
const users = await repo.query().findMany({ where: { status: 'active' } });
```

### Por qué duele
Es el Repository Pattern aparente sin el beneficio real. El dominio sigue conociendo la sintaxis del ORM, los tests siguen necesitando la DB, y cambiar de ORM rompe el dominio. Peor que no tener repository, porque da falsa sensación de desacoplamiento.

### Cómo corregirlo
- El repository expone **métodos con semántica de dominio** que devuelven entidades, nunca query builders.
- Para criterios dinámicos, usar **Specification** (el spec se traduce a query DENTRO de infrastructure).
- Si necesitás flexibilidad de lectura compleja → **read model** con queries dedicadas, no un builder expuesto.

```typescript
// Correcto — semántica de dominio, entidades de retorno
interface UserRepository {
  findMany(spec: Specification<User>): Promise<User[]>;
  findById(id: UserId): Promise<User | null>;
  save(user: User): Promise<void>;
}
```

---

## GUÍA POR ORM

## Prisma (TypeScript)

### `include` vs `select`
- `include`: trae TODOS los campos de la relación además de los del modelo base. Cómodo pero sobre-fetcha.
- `select`: trae SOLO los campos enumerados. Reduce payload y memoria. Preferir `select` para read models y endpoints de alto tráfico.

```typescript
// include — trae User completo + todos los campos del post
await prisma.user.findUnique({ where: { id }, include: { posts: true } });

// select — trae solo lo necesario (menos datos sobre el cable)
await prisma.user.findUnique({
  where: { id },
  select: { id: true, name: true, posts: { select: { id: true, title: true } } },
});
```

### `findMany` optimization
Prisma resuelve relaciones anidadas con queries separadas + batching interno (no JOIN). Usar `where: { id: { in: [...] } }` para evitar N+1. Paginar con `take`/`skip` o, mejor, **cursor-based** (`cursor` + `take`) para datasets grandes.

### Transaction API
- `$transaction([...])` (array): batch de operaciones independientes, atómicas.
- `$transaction(async (tx) => {...})` (interactiva): lógica condicional dentro de la transacción — usar para Unit of Work. Pasar `tx` a los repositories.

---

## Drizzle (TypeScript)

### Joins vs Relations API
- **Relations query API** (`db.query.users.findMany({ with: { posts: true } })`): ergonómico, devuelve estructura anidada, hace queries separadas optimizadas.
- **SQL-like joins** (`db.select().from(users).leftJoin(posts, ...)`): control total, una sola query con JOIN, devuelve filas planas que debés mapear. Preferir joins explícitos cuando importa el plan exacto o necesitás agregaciones.

```typescript
// Relations API — anidado, cómodo
const result = await db.query.users.findMany({ with: { posts: true } });

// Join explícito — una query, control del plan
const rows = await db.select({ user: users, post: posts })
  .from(users).leftJoin(posts, eq(posts.userId, users.id));
```

### Batch API
`db.batch([...])` envía múltiples statements en un solo round-trip (driver-dependiente, ideal en libSQL/Turso). Para inserts masivos usar `insert(table).values([...])` con array — un solo INSERT multi-row, no loop.

---

## SQLAlchemy (Python)

### `selectinload` vs `joinedload`
- `joinedload`: una sola query con JOIN. Eficiente para relaciones **to-one** (many-to-one, one-to-one). En to-many duplica filas del lado padre.
- `selectinload`: query separada con `WHERE IN` para la colección. Preferir para relaciones **to-many** (one-to-many): evita la explosión cartesiana del JOIN.

```python
# to-one → joinedload (1 query, sin duplicación)
stmt = select(Order).options(joinedload(Order.customer))

# to-many → selectinload (2 queries, sin filas duplicadas)
stmt = select(User).options(selectinload(User.posts))
```

Sin ninguna de las dos + acceso a la relación en un loop = N+1 por lazy loading.

### Session scoping
El `Session` es el Unit of Work. NO compartir una sesión entre requests/threads. En async usar `async_sessionmaker` + `async with session.begin()` por request. Evitar el patrón global `scoped_session` en web async — un session por unidad de trabajo.

---

## TypeORM (TypeScript)

### QueryBuilder vs Repository
- `Repository`/`EntityManager`: API declarativa (`find`, `findOne`, `save`). Cómoda para CRUD; las `relations` se resuelven con queries o JOINs según config.
- `QueryBuilder`: SQL programático para queries complejas, agregaciones y control del plan. Usarlo cuando `find` no alcanza, pero NUNCA exponerlo fuera de infrastructure (sería Anemic Repository).

```typescript
// Repository — CRUD declarativo
await repo.find({ where: { active: true }, relations: { posts: true } });

// QueryBuilder — control fino, encapsulado en el repo
await repo.createQueryBuilder('u')
  .leftJoinAndSelect('u.posts', 'p')
  .where('u.active = :active', { active: true })
  .getMany();
```

### Eager vs Lazy loading
- `eager: true` en la relación: se carga SIEMPRE, en todas las queries de esa entidad → sobre-fetch garantizado. Evitar como default.
- Lazy (`Promise<...>` en la propiedad): se carga al acceder → N+1 si se accede en loop.
- **Recomendado**: relaciones no-eager + cargar explícitamente con `relations`/`leftJoinAndSelect` cuando se necesite. Carga explícita > carga implícita.

---

## Hibernate (Java)

### Fetch strategies
- `FetchType.LAZY` (default en colecciones): carga al acceder → riesgo de `LazyInitializationException` fuera de sesión y de N+1.
- `FetchType.EAGER`: carga siempre → sobre-fetch.
- **Recomendado**: todo LAZY + resolver con `JOIN FETCH` en la query JPQL donde se necesite, o `@EntityGraph` para definir el grafo de carga por caso de uso.

```java
// JOIN FETCH — resuelve la relación en una query, evita N+1
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.status = :status")
List<Order> findWithItems(@Param("status") String status);

// EntityGraph — grafo de carga declarativo por método
@EntityGraph(attributePaths = {"items", "customer"})
List<Order> findByStatus(String status);
```

### Second-level cache
La 1st-level cache es por-sesión (automática). La **2nd-level cache** (Ehcache, Infinispan) es compartida entre sesiones — cachea entidades read-mostly por su ID. Activar solo en entidades de baja escritura/alta lectura (catálogos, config). Combinar con **query cache** para resultados de queries repetidas. Cachear entidades volátiles invita a stale reads.

### Criteria API
API tipada para queries dinámicas en tiempo de ejecución (filtros opcionales según input). Es el equivalente Java del Specification: componer `Predicate`s. Preferir sobre concatenar JPQL como string (que invita a inyección y errores).

---

## GORM (Go)

### `Preload`
Carga relaciones con queries separadas + `WHERE IN` (evita N+1). Sin `Preload`, acceder a una relación en un loop dispara N queries.

```go
// Preload — 2 queries (orders + items con WHERE IN), no N+1
db.Preload("Items").Where("status = ?", "paid").Find(&orders)

// Preload anidado
db.Preload("Items.Product").Find(&orders)
```

Para JOIN real en una sola query (relaciones to-one) usar `Joins("Customer")`.

### `Session`
`db.Session(&gorm.Session{...})` crea una configuración aislada (logger, contexto, dry-run, `PrepareStmt`) sin mutar la instancia base `*gorm.DB`. Útil para scoping por request y para activar prepared statements en hot paths. NO reutilizar un `*gorm.DB` con condiciones ya encadenadas (riesgo de query pollution entre llamadas).

### `Scopes`
Funciones reutilizables que encapsulan fragmentos de query componibles — el Specification Pattern idiomático de GORM. Evitan la proliferación de métodos repository.

```go
func Active(db *gorm.DB) *gorm.DB        { return db.Where("status = ?", "active") }
func FromCountry(c string) func(*gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB { return db.Where("country = ?", c) }
}

// Composición
db.Scopes(Active, FromCountry("CL")).Find(&users)
```

---

## Tabla de Decisión Rápida

| Síntoma | Anti-pattern probable | Fix |
|---------|----------------------|-----|
| Ráfaga de `SELECT ... WHERE id = ?` | N+1 Query | eager load / `WHERE IN` |
| ORM call dentro de `for`/`map` | Query in Loop | batch / bulk insert |
| Repository con 20+ métodos | God Repository | mover lógica a dominio + Specification |
| `import` ORM en `domain/` | Anemic / leaked abstraction | Repository con entidades de retorno |
| `findX` que crecen sin parar | (falta) Specification | criterios componibles |
| Escrituras parciales tras fallo | (falta) Unit of Work | transacción que envuelve los saves |
| Listado UI hidrata agregado completo | (falta) Read/Write Split | read model con proyección |

---

## Checklist de Revisión ORM

### Arquitectura
- [ ] El dominio no importa tipos del ORM (sin leaked abstractions)
- [ ] Repositories devuelven entidades, no query builders ni rows crudos
- [ ] Criterios de búsqueda dinámicos vía Specification, no método-por-combinación
- [ ] Lógica de negocio en entidades/domain services, no en queries del repo

### Transacciones
- [ ] Operaciones multi-tabla envueltas en Unit of Work / transacción
- [ ] Repos comparten el contexto transaccional (no abren conexión propia)
- [ ] Sin lógica de compensación manual reemplazando un rollback

### Performance
- [ ] Cero llamadas ORM dentro de loops (lecturas → `WHERE IN`, escrituras → bulk)
- [ ] Relaciones cargadas explícitamente (no eager por default, no lazy en loop)
- [ ] Estrategia de fetch correcta por cardinalidad (to-one JOIN, to-many `selectinload`/`Preload`)
- [ ] `select` específico en read models de alto tráfico (no `include`/`SELECT *`)
- [ ] Lecturas read-heavy ruteadas a réplica cuando aplica (Read/Write Split)
