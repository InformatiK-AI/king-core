# Capa S — Security Checks

## S1: Secrets Scan
**Severidad**: BLOQUEANTE
**Descripción**: No debe haber secrets hardcodeados en el código.

### Checks:
- No hay patrones `sk-ant-*` en código fuente
- No hay `API_KEY=valor` hardcodeado
- No hay passwords, tokens, o credenciales en código
- `.env` no está trackeado en git
- `.env.example` no contiene valores reales

### Cómo verificar:
```bash
grep -rn "sk-ant-" --include="*.js" --include="*.jsx" .
grep -rn "API_KEY\s*=" --include="*.js" --include="*.jsx" . | grep -v "process.env"
grep -rn "password\s*=" --include="*.js" --include="*.jsx" . | grep -v "example"
```

---

## S2: Dependency Audit
**Severidad**: WARNING (BLOQUEANTE si hay CRITICAL)
**Descripción**: Las dependencias no deben tener vulnerabilidades conocidas.

### Checks:
- `npm audit` no reporta vulnerabilidades CRITICAL
- `npm audit` no reporta vulnerabilidades HIGH
- Dependencias con última publicación >12 meses marcadas como WARNING
- package-lock.json presente y comitteado

### Cómo verificar:
```bash
cd [project-root] && npm audit --json 2>/dev/null
```

---

## S3: OWASP Patterns
**Severidad**: BLOQUEANTE
**Descripción**: El código no debe contener patrones vulnerables del OWASP Top 10.

### Checks:
- **Injection**: No hay concatenación directa de input de usuario en queries/comandos
- **XSS**: Inputs del usuario se sanitizan antes de render (React lo hace por defecto con JSX)
- **SSRF**: Las URLs para llamadas externas no vienen directamente del usuario
- **Broken Auth**: La API key del servidor no se expone al frontend
- **Security Misconfiguration**: CORS configurado con whitelist, no wildcard

### Cómo verificar:
1. Buscar uso de innerHTML sin sanitización — cada uso debe justificarse
2. Verificar que CORS_ORIGIN no es `*`
3. Verificar que la API key no se incluye en respuestas al frontend
4. Buscar usos de evaluación dinámica de código (constructores de Function, etc.)

---

## S4: Attack Surface
**Severidad**: WARNING
**Descripción**: Evaluar la superficie de ataque de cambios nuevos.

### Checks:
- ¿Se agrega un nuevo endpoint? → Necesita rate limiting y validación
- ¿Se agrega input de usuario? → Necesita sanitización
- ¿Se agrega una nueva dependencia? → Evaluar su security posture
- ¿Se modifica el manejo de la API key? → Revisión extra

### Cómo verificar:
1. Revisar diff para nuevos endpoints/inputs/dependencias
2. Para cada nuevo vector, verificar que tiene protección adecuada

---

## S5: Data Protection
**Severidad**: BLOQUEANTE
**Descripción**: Datos sensibles deben manejarse correctamente.

### Checks:
- El código fuente del usuario no se loggea completo en servidor
- Los reportes PDF/export no incluyen API keys
- Stats en memoria no contienen PII
- Error messages no exponen stack traces al cliente

### Cómo verificar:
1. Buscar `console.log` en server/index.js que pueda incluir request body completo
2. Verificar que error handlers no envían stack traces
3. Verificar que exports/PDFs no incluyen metadata sensible
