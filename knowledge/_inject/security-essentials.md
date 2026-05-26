# Security Essentials (para inyección)

> Versión compacta optimizada para inyección en agents. Contenido completo incluido aquí.

## Prevención Mandatoria

| Riesgo | NUNCA | SIEMPRE |
|--------|-------|---------|
| SQL Injection | `+ userId` en query | Prepared statements |
| XSS | innerHTML con user input | textContent / escape |
| Secrets | Hardcoded en código | process.env / env vars |
| Passwords | MD5, SHA1, SHA256 solo | bcrypt(12+), argon2 |
| Auth | Token sin expiración | 15min-1h, refresh token |

## Patterns Rápidos

```typescript
// SQL - SIEMPRE prepared
db.query('SELECT * FROM users WHERE id = $1', [userId]);

// Passwords - SIEMPRE bcrypt
const hash = await bcrypt.hash(password, 12);

// Secrets - SIEMPRE env vars
const apiKey = process.env.API_KEY;

// Input - SIEMPRE validar servidor
const { email } = schema.parse(req.body);
```

## Señales de Alerta

- `eval()`, `exec()` con input usuario
- Query string concatenada (`+ variable`)
- `dangerouslySetInnerHTML` sin sanitizar
- Archivos `.env`, `.pem`, `.key` en git
- `password = "..."` hardcoded

## Checklist Pre-Commit

- [ ] `npm audit` / `pip-audit` sin HIGH
- [ ] Sin secrets en código
- [ ] Input validado servidor-side
- [ ] Prepared statements para SQL
- [ ] Headers de seguridad configurados
