# Node.js Patterns Knowledge Base

## Propósito
Conocimiento experto de Node.js que se inyecta en agents durante /genesis.
Se usa cuando el proyecto incluye Node.js/Express en su stack.

---

## Async/Await Patterns

### Siempre manejar errores
```typescript
// MAL: Promise sin catch
async function getData() {
  const data = await fetch('/api');  // Si falla, unhandled rejection
  return data;
}

// BIEN: Try/catch
async function getData() {
  try {
    const data = await fetch('/api');
    return data;
  } catch (error) {
    logger.error('Failed to fetch data', { error });
    throw new AppError('DATA_FETCH_FAILED', error);
  }
}
```

### Parallel vs Sequential
```typescript
// Sequential (lento): cada uno espera al anterior
const user = await getUser(id);
const orders = await getOrders(id);
const reviews = await getReviews(id);
// Tiempo: t1 + t2 + t3

// Parallel (rápido): todos al mismo tiempo
const [user, orders, reviews] = await Promise.all([
  getUser(id),
  getOrders(id),
  getReviews(id)
]);
// Tiempo: max(t1, t2, t3)

// Promise.allSettled cuando algunos pueden fallar
const results = await Promise.allSettled([
  fetchOptionalData1(),
  fetchOptionalData2()
]);
```

### Rate limiting concurrent requests
```typescript
import pLimit from 'p-limit';

// Máximo 5 requests concurrentes
const limit = pLimit(5);

const results = await Promise.all(
  urls.map(url => limit(() => fetch(url)))
);
```

### Async iteration
```typescript
// Procesar stream async
for await (const chunk of readableStream) {
  await processChunk(chunk);
}

// Procesar array con límite de concurrencia
import { asyncPool } from 'modern-async';

for await (const result of asyncPool(items, async (item) => {
  return processItem(item);
}, 5)) {
  // Max 5 concurrent
}
```

---

## Error Handling

### Custom Error classes
```typescript
class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string) {
    super('NOT_FOUND', `${resource} not found`, 404);
  }
}

class ValidationError extends AppError {
  constructor(message: string, public details: any[]) {
    super('VALIDATION_ERROR', message, 400);
  }
}
```

### Express error middleware
```typescript
// Error handler (siempre 4 argumentos)
function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // Log error
  logger.error('Request failed', {
    error: err.message,
    stack: err.stack,
    requestId: req.id,
    path: req.path
  });

  // Determinar response
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        ...(err instanceof ValidationError && { details: err.details })
      }
    });
  }

  // Error no esperado - no exponer detalles
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      requestId: req.id
    }
  });
}

app.use(errorHandler);
```

### Async route wrapper
```typescript
// Wrapper para capturar errores async automáticamente
function asyncHandler(fn: RequestHandler): RequestHandler {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// Uso
app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id);
  if (!user) throw new NotFoundError('User');
  res.json({ data: user });
}));
```

---

## Middleware Patterns

### Orden de middleware
```typescript
// 1. Request ID (primero para tracing)
app.use(requestId());

// 2. Logging
app.use(requestLogger());

// 3. Security headers
app.use(helmet());

// 4. CORS
app.use(cors(corsOptions));

// 5. Body parsing
app.use(express.json({ limit: '10kb' }));

// 6. Rate limiting
app.use(rateLimiter);

// 7. Authentication
app.use(authenticate);

// 8. Routes
app.use('/api', routes);

// 9. 404 handler
app.use(notFoundHandler);

// 10. Error handler (siempre último)
app.use(errorHandler);
```

### Request ID middleware
```typescript
import { v4 as uuid } from 'uuid';

function requestId(): RequestHandler {
  return (req, res, next) => {
    req.id = req.headers['x-request-id'] as string || uuid();
    res.setHeader('x-request-id', req.id);
    next();
  };
}
```

### Authentication middleware
```typescript
async function authenticate(req: Request, res: Response, next: NextFunction) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      throw new AppError('UNAUTHORIZED', 'No token provided', 401);
    }

    const payload = await verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    next(new AppError('UNAUTHORIZED', 'Invalid token', 401));
  }
}

// Autorización por rol
function authorize(...roles: string[]): RequestHandler {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new AppError('FORBIDDEN', 'Insufficient permissions', 403));
    }
    next();
  };
}

// Uso
app.delete('/users/:id', authenticate, authorize('admin'), deleteUser);
```

### Validation middleware
```typescript
import { z } from 'zod';

function validate(schema: z.Schema): RequestHandler {
  return (req, res, next) => {
    try {
      req.validated = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params
      });
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        next(new ValidationError('Invalid request', error.errors));
      } else {
        next(error);
      }
    }
  };
}

// Schema
const createUserSchema = z.object({
  body: z.object({
    email: z.string().email(),
    name: z.string().min(1).max(100),
    password: z.string().min(8)
  })
});

// Uso
app.post('/users', validate(createUserSchema), createUser);
```

---

## Streams

### Cuándo usar streams
```typescript
// ✓ Usar streams para:
// - Archivos grandes
// - Respuestas HTTP grandes
// - Procesamiento en tiempo real
// - Pipelines de transformación

// ✗ No streams para:
// - Datos pequeños (<1MB)
// - Cuando necesitas el objeto completo
```

### Pipe pattern
```typescript
import { pipeline } from 'stream/promises';
import fs from 'fs';
import zlib from 'zlib';

// Pipeline seguro con manejo de errores
async function compressFile(input: string, output: string) {
  await pipeline(
    fs.createReadStream(input),
    zlib.createGzip(),
    fs.createWriteStream(output)
  );
}
```

### Transform stream
```typescript
import { Transform } from 'stream';

const upperCaseTransform = new Transform({
  transform(chunk, encoding, callback) {
    this.push(chunk.toString().toUpperCase());
    callback();
  }
});

// Con pipeline
await pipeline(
  fs.createReadStream('input.txt'),
  upperCaseTransform,
  fs.createWriteStream('output.txt')
);
```

### JSON streaming
```typescript
import { parser } from 'stream-json';
import { streamArray } from 'stream-json/streamers/StreamArray';

// Procesar JSON grande sin cargar todo en memoria
const jsonStream = fs.createReadStream('huge.json')
  .pipe(parser())
  .pipe(streamArray());

for await (const { value } of jsonStream) {
  await processItem(value);
}
```

---

## Database Patterns

### Connection pooling
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,                    // Max connections
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 2000
});

// Usar pool, no conexiones individuales
async function query(text: string, params?: any[]) {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;

  logger.debug('Query executed', { text, duration, rows: result.rowCount });

  return result;
}
```

### Transaction pattern
```typescript
async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Uso
const order = await withTransaction(async (client) => {
  const order = await createOrder(client, orderData);
  await updateInventory(client, order.items);
  await chargePayment(client, order.total);
  return order;
});
```

### Repository pattern
```typescript
interface UserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  create(data: CreateUserDTO): Promise<User>;
  update(id: string, data: UpdateUserDTO): Promise<User>;
  delete(id: string): Promise<void>;
}

class PostgresUserRepository implements UserRepository {
  constructor(private pool: Pool) {}

  async findById(id: string): Promise<User | null> {
    const { rows } = await this.pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return rows[0] || null;
  }

  async create(data: CreateUserDTO): Promise<User> {
    const { rows } = await this.pool.query(
      `INSERT INTO users (email, name, password_hash)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [data.email, data.name, await hashPassword(data.password)]
    );
    return rows[0];
  }
}
```

---

## Configuration

### Environment-based config
```typescript
// config.ts
const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000'),

  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    name: process.env.DB_NAME || 'myapp',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || ''
  },

  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '15m'
  },

  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379'
  }
} as const;

// Validar config requerida al iniciar
function validateConfig() {
  const required = ['JWT_SECRET', 'DB_PASSWORD'];
  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
}

validateConfig();
export default config;
```

### Feature flags
```typescript
const features = {
  newCheckout: process.env.FEATURE_NEW_CHECKOUT === 'true',
  betaApi: process.env.FEATURE_BETA_API === 'true'
};

// Uso
if (features.newCheckout) {
  app.use('/checkout', newCheckoutRouter);
} else {
  app.use('/checkout', legacyCheckoutRouter);
}
```

---

## Graceful Shutdown

```typescript
const server = app.listen(config.port);

async function shutdown(signal: string) {
  logger.info(`${signal} received, shutting down gracefully`);

  // Stop accepting new connections
  server.close(() => {
    logger.info('HTTP server closed');
  });

  // Close database connections
  await pool.end();
  logger.info('Database pool closed');

  // Close other connections (Redis, etc)
  await redis.quit();
  logger.info('Redis connection closed');

  process.exit(0);
}

// Timeout for graceful shutdown
const SHUTDOWN_TIMEOUT = 30000;

process.on('SIGTERM', () => {
  const timeout = setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, SHUTDOWN_TIMEOUT);

  shutdown('SIGTERM').finally(() => clearTimeout(timeout));
});

process.on('SIGINT', () => shutdown('SIGINT'));
```

---

## Logging

### Structured logging
```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label })
  },
  redact: ['password', 'token', 'authorization']
});

// Child logger con contexto
const requestLogger = logger.child({ requestId: req.id });

requestLogger.info({ userId: user.id }, 'User logged in');
```

### Request logging middleware
```typescript
function requestLogger(): RequestHandler {
  return (req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
      const duration = Date.now() - start;

      logger.info({
        requestId: req.id,
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        duration,
        userAgent: req.headers['user-agent']
      }, 'Request completed');
    });

    next();
  };
}
```

---

## Caching

### Redis patterns
```typescript
import Redis from 'ioredis';

const redis = new Redis(config.redis.url);

// Cache-aside pattern
async function getCachedUser(id: string): Promise<User> {
  const cacheKey = `user:${id}`;

  // Check cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }

  // Fetch from DB
  const user = await userRepository.findById(id);
  if (!user) throw new NotFoundError('User');

  // Store in cache
  await redis.setex(cacheKey, 3600, JSON.stringify(user));

  return user;
}

// Invalidate on update
async function updateUser(id: string, data: UpdateUserDTO): Promise<User> {
  const user = await userRepository.update(id, data);
  await redis.del(`user:${id}`);
  return user;
}
```

### In-memory cache para datos pequeños
```typescript
import NodeCache from 'node-cache';

const cache = new NodeCache({
  stdTTL: 600,      // 10 minutes default
  checkperiod: 120  // Check for expired every 2 min
});

function memoize<T>(
  fn: (...args: any[]) => Promise<T>,
  keyFn: (...args: any[]) => string,
  ttl: number = 600
) {
  return async (...args: any[]): Promise<T> => {
    const key = keyFn(...args);
    const cached = cache.get<T>(key);

    if (cached !== undefined) {
      return cached;
    }

    const result = await fn(...args);
    cache.set(key, result, ttl);
    return result;
  };
}
```

---

## Testing

### Unit test structure
```typescript
describe('UserService', () => {
  let userService: UserService;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    userRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    };

    userService = new UserService(userRepository);
  });

  describe('create', () => {
    it('should create user with hashed password', async () => {
      const input = { email: 'test@test.com', password: 'password123' };

      userRepository.create.mockResolvedValue({
        id: '1',
        email: input.email,
        passwordHash: 'hashed'
      });

      const user = await userService.create(input);

      expect(userRepository.create).toHaveBeenCalledWith({
        email: input.email,
        passwordHash: expect.any(String)
      });
      expect(user.email).toBe(input.email);
    });
  });
});
```

### Integration test con supertest
```typescript
import request from 'supertest';
import app from '../app';

describe('POST /api/users', () => {
  it('should create a new user', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({
        email: 'new@test.com',
        name: 'Test User',
        password: 'password123'
      })
      .expect(201);

    expect(response.body.data).toMatchObject({
      email: 'new@test.com',
      name: 'Test User'
    });
    expect(response.body.data.password).toBeUndefined();
  });

  it('should return 400 for invalid email', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'not-an-email', password: 'password123' })
      .expect(400);

    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });
});
```

---

## Checklist Node.js

### Por endpoint
- [ ] Input validado con schema
- [ ] Errores manejados y tipados
- [ ] Respuestas consistentes
- [ ] Logging de request/response

### Por servicio
- [ ] Errores async capturados
- [ ] Timeout en operaciones externas
- [ ] Retry para operaciones transitorias
- [ ] Circuit breaker para dependencias

### Operacional
- [ ] Graceful shutdown implementado
- [ ] Health check endpoint
- [ ] Logs estructurados
- [ ] Métricas expuestas
- [ ] Config validada al iniciar
