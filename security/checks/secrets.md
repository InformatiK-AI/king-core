# Secrets Detection

## Propósito
Detectar secrets, credenciales y tokens en código antes de merge.

---

## Patrones de Detección

### API Keys Genéricas

```regex
# Keys largas alfanuméricas (32+ caracteres)
[a-zA-Z0-9_-]{32,}

# Con prefijo común
(api[_-]?key|apikey|api[_-]?token)\s*[:=]\s*['"]?[a-zA-Z0-9_-]{16,}['"]?
```

**Ejemplos detectados:**
```javascript
// ❌ Detectado
const apiKey = "sk_live_[YOUR_SECRET_KEY]";
const API_KEY = "1234567890abcdef1234567890abcdef";

// ✅ OK (variable de entorno)
const apiKey = process.env.API_KEY;
```

---

### AWS Credentials

```regex
# Access Key ID
AKIA[0-9A-Z]{16}

# Secret Access Key
aws[_-]?secret[_-]?access[_-]?key\s*[:=]\s*['"]?[A-Za-z0-9/+=]{40}['"]?

# En archivos de config
\[default\][\s\S]*?aws_access_key_id\s*=\s*[A-Z0-9]{20}
```

**Ejemplos detectados:**
```ini
# ❌ Detectado
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

---

### GitHub Tokens

```regex
# Personal Access Token (classic)
ghp_[a-zA-Z0-9]{36}

# Personal Access Token (fine-grained)
github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}

# OAuth App Token
gho_[a-zA-Z0-9]{36}

# GitHub App Token
ghu_[a-zA-Z0-9]{36}
```

**Ejemplos detectados:**
```javascript
// ❌ Detectado
const GITHUB_TOKEN = "ghp_1234567890abcdefghijklmnopqrstuvwxyz";
```

---

### Stripe Keys

```regex
# Publishable Key
pk_(test|live)_[a-zA-Z0-9]{24,}

# Secret Key
sk_(test|live)_[a-zA-Z0-9]{24,}

# Restricted Key
rk_(test|live)_[a-zA-Z0-9]{24,}
```

**Ejemplos detectados:**
```javascript
// ❌ Detectado
const stripeKey = "sk_live_[YOUR_KEY]";

// ⚠️ Warning (test key, menor riesgo)
const stripeTestKey = "sk_test_51ABC123XYZ";
```

---

### Database URLs

```regex
# PostgreSQL
postgres(ql)?:\/\/[^:]+:[^@]+@[^\/]+\/\w+

# MySQL
mysql:\/\/[^:]+:[^@]+@[^\/]+\/\w+

# MongoDB
mongodb(\+srv)?:\/\/[^:]+:[^@]+@[^\/]+
```

**Ejemplos detectados:**
```javascript
// ❌ Detectado
const DB_URL = "postgres://user:password123@host.com:5432/mydb";

// ✅ OK
const DB_URL = process.env.DATABASE_URL;
```

---

### Passwords en Código

```regex
# Asignación de password
(password|passwd|pwd|secret)\s*[:=]\s*['"][^'"]{4,}['"]

# En objetos/JSON
"(password|passwd|pwd|secret)"\s*:\s*"[^"]{4,}"
```

**Ejemplos detectados:**
```javascript
// ❌ Detectado
const config = {
  password: "super_secret_password",
  dbPassword: "admin123"
};

// ✅ OK
const config = {
  password: process.env.DB_PASSWORD
};
```

---

### Private Keys

```regex
# RSA Private Key
-----BEGIN RSA PRIVATE KEY-----[\s\S]*?-----END RSA PRIVATE KEY-----

# EC Private Key
-----BEGIN EC PRIVATE KEY-----[\s\S]*?-----END EC PRIVATE KEY-----

# Generic Private Key
-----BEGIN PRIVATE KEY-----[\s\S]*?-----END PRIVATE KEY-----

# OpenSSH Private Key
-----BEGIN OPENSSH PRIVATE KEY-----[\s\S]*?-----END OPENSSH PRIVATE KEY-----
```

**Ejemplos detectados:**
```
# ❌ Detectado (en cualquier archivo)
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF8PbnGy...
-----END RSA PRIVATE KEY-----
```

---

### JWT Secrets

```regex
# JWT secret en código
jwt[_-]?secret\s*[:=]\s*['"][^'"]{8,}['"]

# En variables
(JWT_SECRET|TOKEN_SECRET|AUTH_SECRET)\s*=\s*['"]?[^'"]+['"]?
```

---

### Otros Servicios Comunes

| Servicio | Patrón |
|----------|--------|
| Slack Webhook | `https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[a-zA-Z0-9]+` |
| Slack Token | `xox[baprs]-[0-9]{12}-[0-9]{12}-[a-zA-Z0-9]{24}` |
| SendGrid | `SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}` |
| Twilio | `SK[a-f0-9]{32}` |
| Mailgun | `key-[a-f0-9]{32}` |
| Google API | `AIza[0-9A-Za-z_-]{35}` |
| Heroku | `[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}` |

### Servicios adicionales

| Servicio | Patrón | Regex |
|----------|--------|-------|
| OAuth Client Secret | `cs_` prefix | `cs_[a-zA-Z0-9]{24,}` |
| Firebase | API key format | `AIza[0-9A-Za-z\-_]{35}` |
| Supabase | Service key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+` |
| Clerk | Secret key | `sk_live_[a-zA-Z0-9]{24,}` |
| Auth0 | Client secret | `[a-zA-Z0-9_-]{40,}` (en contexto de AUTH0) |
| Resend | API key | `re_[a-zA-Z0-9]{24,}` |
| Vercel | Token | `[a-zA-Z0-9]{24}` (en contexto VERCEL_TOKEN) |
| Cloudflare | API token | `[a-zA-Z0-9_-]{40}` (en contexto CF_API_TOKEN) |
| SendGrid | API key | `SG\.[a-zA-Z0-9\-_]{22}\.[a-zA-Z0-9\-_]{43}` |
| Twilio | Auth token | `[a-f0-9]{32}` (en contexto TWILIO) |

---

## Implementación

### Escaneo de archivos modificados

```bash
# Obtener archivos modificados
git diff --name-only HEAD~1

# O archivos staged
git diff --cached --name-only

# Escanear cada archivo con patrones
```

### Exclusiones

> **⚠️ Riesgo de exclusión de .md**: Los archivos `.md` están excluidos del escaneo automático porque normalmente contienen ejemplos de código. Sin embargo, `CLAUDE.md` y los archivos en `.king/` (sessions, registry, workflows) pueden contener información sensible capturada de contexto externo. Se recomienda **scan manual periódico** de estos archivos, especialmente en proyectos con datos sensibles.

Archivos que se ignoran:
```
*.md           # Documentación (puede tener ejemplos)
*.test.*       # Tests (pueden tener mocks)
*.spec.*       # Tests
*.snap         # Snapshots
package-lock.json
yarn.lock
pnpm-lock.yaml
*.min.js       # Código minificado
node_modules/  # Dependencias
vendor/        # Dependencias
```

### Falsos positivos comunes

| Patrón | Por qué es falso positivo |
|--------|---------------------------|
| UUIDs | Formato similar a tokens pero son IDs |
| Hashes en tests | Valores de prueba |
| Placeholder keys | `"your-api-key-here"` |
| Base64 de imágenes | Largas cadenas alfanuméricas |
| IDs de recursos | IDs de commits, issues, etc. |

### Manejo de falsos positivos

```yaml
# security/exceptions.yml
secrets:
  - pattern: "pk_test_.*"
    reason: "Stripe test keys are not sensitive"
    action: "warn"  # warn instead of block

  - pattern: "EXAMPLE_API_KEY"
    reason: "Placeholder in documentation"
    action: "ignore"

  - file: "src/test/mocks/auth.ts"
    reason: "Test file with mock tokens"
    action: "ignore"
```

---

## Reporte de Detección

### Formato

```
🔍 Secrets Detection Report
═══════════════════════════════════════════════════════

Archivos escaneados: 15
Findings: 2

┌────────────────────────────────────────────────────────┐
│ ⛔ CRÍTICO                                             │
├────────────────────────────────────────────────────────┤
│ Archivo: src/config/database.ts                        │
│ Línea: 15                                              │
│ Tipo: Database Password                                │
│                                                        │
│   14 │ const config = {                                │
│ → 15 │   password: "admin123",  // ⛔ SECRET           │
│   16 │   host: "localhost"                             │
│                                                        │
│ Acción: Mover a variable de entorno                    │
│   const password = process.env.DB_PASSWORD;            │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ ⛔ CRÍTICO                                             │
├────────────────────────────────────────────────────────┤
│ Archivo: src/services/api.ts                           │
│ Línea: 8                                               │
│ Tipo: API Key (posible Stripe)                         │
│                                                        │
│    7 │ const stripe = new Stripe(                      │
│ →  8 │   "sk_live_[YOUR_KEY]456789"  // ⛔ SECRET     │
│    9 │ );                                              │
│                                                        │
│ Acción: Mover a variable de entorno                    │
│   const stripe = new Stripe(process.env.STRIPE_KEY);   │
└────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════
Resultado: ⛔ BLOQUEADO

Estos secrets DEBEN removerse antes de merge.
1. Mueve los valores a variables de entorno (.env)
2. Usa process.env.VARIABLE_NAME en el código
3. Asegúrate que .env está en .gitignore
4. Ejecuta /qa de nuevo
```

---

## Acciones Correctivas

### Remover secret del historial

Si un secret ya fue commiteado:

```bash
# 1. Revocar el secret inmediatamente (en el servicio)

# 2. Remover del historial con BFG
bfg --replace-text secrets.txt repo.git

# 3. O con git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/file" \
  --prune-empty -- --all

# 4. Force push (coordinar con equipo)
git push --force --all

# 5. Rotar el secret (generar uno nuevo)
```

### Prevención

```bash
# Configurar pre-commit hook
#!/bin/sh
# .git/hooks/pre-commit

if git diff --cached --name-only | xargs grep -l "sk_live\|password\s*=" 2>/dev/null; then
  echo "❌ Possible secret detected. Commit aborted."
  echo "Review your changes and remove any secrets."
  exit 1
fi
```

---

## Checklist

### Antes de commit
- [ ] No hay passwords hardcodeados
- [ ] API keys en variables de entorno
- [ ] .env en .gitignore
- [ ] .env.example tiene placeholders, no valores reales
- [ ] Private keys en directorio seguro, no en repo

### Si se detecta secret
- [ ] Identificar si es real o falso positivo
- [ ] Si es real, revocar inmediatamente
- [ ] Mover a variable de entorno
- [ ] Si ya fue pusheado, limpiar historial
- [ ] Generar nuevo secret
- [ ] Documentar en sesión

---

## Detección de Archivos Nuevos (Untracked)

### Propósito
Los archivos nuevos (untracked) representan un riesgo adicional porque no han sido revisados previamente y pueden contener secrets que nunca debieron agregarse al repositorio.

### Implementación

```bash
# Obtener archivos nuevos (untracked) que no están en .gitignore
git ls-files --others --exclude-standard

# Combinar con archivos modificados para escaneo completo
MODIFIED=$(git diff --cached --name-only)
NEW_FILES=$(git ls-files --others --exclude-standard)
ALL_FILES="$MODIFIED $NEW_FILES"

# Escanear todos
for file in $ALL_FILES; do
  scan_for_secrets "$file"
done
```

### Riesgos Específicos de Archivos Nuevos

| Tipo de archivo | Riesgo | Acción |
|-----------------|--------|--------|
| `.env*` (cualquier variante) | **CRÍTICO** | BLOQUEAR inmediatamente |
| `*.pem`, `*.key`, `id_rsa*` | **CRÍTICO** | BLOQUEAR inmediatamente |
| `credentials.*`, `secrets.*` | **CRÍTICO** | BLOQUEAR inmediatamente |
| `config.local.*` | **ALTO** | Escanear + advertir |
| `*.sqlite`, `*.db` | **ALTO** | Advertir (pueden contener datos) |
| `*.log` | **MEDIO** | Advertir (pueden contener tokens en logs) |
| Archivos en `/tmp/`, `/temp/` | **MEDIO** | Advertir (no deberían commitearse) |
| `node_modules/`, `vendor/` | **BAJO** | Ignorar (deberían estar en .gitignore) |

### Formato de Reporte para Archivos Nuevos

```
🔍 New Files Detection Report
═══════════════════════════════════════════════════════

Archivos nuevos detectados: {N}

┌────────────────────────────────────────────────────────┐
│ ⛔ CRÍTICO: Archivo sensible detectado                 │
├────────────────────────────────────────────────────────┤
│ Archivo: .env.production                               │
│ Estado: NEW (untracked)                                │
│ Riesgo: Variables de entorno de producción             │
│                                                        │
│ Acción OBLIGATORIA:                                    │
│   1. NO commitear este archivo                         │
│   2. Agregar a .gitignore                              │
│   3. Si ya fue staged: git reset HEAD .env.production  │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ ⚠️ WARNING: Archivo potencialmente sensible            │
├────────────────────────────────────────────────────────┤
│ Archivo: config/database.local.json                    │
│ Estado: NEW (untracked)                                │
│ Riesgo: Puede contener credenciales locales            │
│                                                        │
│ Acción recomendada:                                    │
│   1. Revisar contenido antes de commitear              │
│   2. Considerar agregar a .gitignore                   │
│   3. Usar variables de entorno en su lugar             │
└────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════
Archivos nuevos seguros: {N}
Archivos nuevos con riesgo: {N}

{Si hay CRÍTICOS}
⛔ BLOQUEADO: Resolver archivos críticos antes de continuar.

{Si solo hay WARNINGS}
⚠️ Revisar archivos marcados antes de continuar.
```

### Integración con Security Gate

El escaneo de archivos nuevos se ejecuta como parte del check "Sensitive Files":

```
Sensitive Files Check:
├── Archivos modificados (staged)
├── Archivos nuevos (untracked) ← NUEVO
└── Verificación de .gitignore
```

### Exclusiones para Archivos Nuevos

Archivos que se ignoran en el escaneo de nuevos:

```
# Siempre ignorar (manejados por .gitignore)
node_modules/
vendor/
.git/
dist/
build/

# Ignorar por extensión (bajo riesgo)
*.md
*.txt (excepto secrets.txt, passwords.txt)
*.png, *.jpg, *.gif, *.svg
*.css, *.scss

# Ignorar por convención
*.example
*.sample
*.template
```
