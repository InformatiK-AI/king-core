# Node.js Security - Implementación

> Conceptos base: ver `../../_inject/security-essentials.md`

Este documento contiene solo implementaciones Node.js/Express específicas.

---

## Injection Prevention

### SQL (con pg/mysql2)
```typescript
// Prepared statement
const { rows } = await pool.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

### NoSQL (MongoDB)
```typescript
// Validar tipo antes de query
const email = String(req.body.email);
const user = await User.findOne({ email });
```

### Command
```typescript
// Usar execFile, no exec
import { execFile } from 'child_process';
execFile('convert', [filename, 'output.png']);
```

### Path Traversal
```typescript
const uploadsDir = path.resolve('./uploads');
const requestedPath = path.resolve(uploadsDir, req.params.filename);
if (!requestedPath.startsWith(uploadsDir)) {
  throw new ForbiddenError('Invalid path');
}
```

---

## XSS Prevention

### Content Security Policy
```typescript
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  }
}));
```

### Cookie Security
```typescript
app.use(session({
  secret: process.env.SESSION_SECRET,
  cookie: {
    secure: true,
    httpOnly: true,
    sameSite: 'strict',
    maxAge: 3600000
  }
}));
```

---

## CSRF Protection

### Forms tradicionales
```typescript
import csrf from 'csurf';
const csrfProtection = csrf({ cookie: true });
app.get('/form', csrfProtection, (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() });
});
```

### SPAs
```typescript
// Custom header (no puede enviarse cross-origin sin CORS)
if (req.headers['x-requested-with'] !== 'XMLHttpRequest') {
  return res.status(403).json({ error: 'CSRF' });
}
```

---

## Authentication

### Password hashing (bcrypt)
```typescript
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
const valid = await bcrypt.compare(input, hash);
```

### JWT
```typescript
import jwt from 'jsonwebtoken';

// Sign
jwt.sign(payload, secret, {
  algorithm: 'HS256',
  expiresIn: '15m',
  issuer: 'my-app'
});

// Verify
jwt.verify(token, secret, {
  algorithms: ['HS256'],
  issuer: 'my-app'
});
```

### Rate limiting
```typescript
import rateLimit from 'express-rate-limit';
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts'
});
app.post('/login', loginLimiter, handler);
```

---

## Request Validation (Zod)

```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email().max(255).toLowerCase().trim(),
  password: z.string().min(8).max(128)
    .regex(/[A-Z]/, 'Uppercase required')
    .regex(/[0-9]/, 'Number required')
});

// Middleware
const result = schema.safeParse(req.body);
if (!result.success) {
  return res.status(400).json({ error: result.error.issues });
}
```

---

## Payload Limits

```typescript
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// Files (multer)
const upload = multer({
  limits: { fileSize: 5 * 1024 * 1024, files: 5 },
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      cb(new Error('Only images'));
    }
    cb(null, true);
  }
});
```

---

## Logging (sin secrets)

```typescript
import pino from 'pino';
const logger = pino({
  redact: {
    paths: ['password', 'token', 'authorization', '*.password'],
    censor: '[REDACTED]'
  }
});
```

---

## Error Handling

```typescript
function errorHandler(err, req, res, next) {
  logger.error({ error: err.message, stack: err.stack });

  // No exponer internals
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', requestId: req.id }
  });
}
```

---

## Dependency Audit

```bash
npm audit --audit-level=high
npm ci  # En CI, no npm install
```

---

## Checklist Node.js

- [ ] `npm audit` sin HIGH/CRITICAL
- [ ] Helmet configurado
- [ ] CORS restrictivo
- [ ] Rate limiting activo
- [ ] Input validado con Zod
- [ ] Prepared statements
- [ ] Logs redactados
- [ ] Errors no exponen internals
