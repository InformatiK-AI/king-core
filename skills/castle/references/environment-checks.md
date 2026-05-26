# Capa E — Environment Checks

## E1: Smoke Tests
**Severidad**: BLOQUEANTE
**Descripción**: Tests básicos de funcionamiento en el ambiente desplegado.

### Checks:
- La aplicación inicia sin errores (`npm run dev` o `npm start`)
- El health endpoint responde (`GET /api/health`)
- El frontend carga correctamente (Vite dev server o build estático)
- La comunicación frontend → backend funciona (proxy /api)

### Cómo verificar:
```bash
cd [project-root]
# Backend
curl -s http://localhost:3001/api/health | grep -q '"status"'
# Frontend (dev)
curl -s http://localhost:5173 | grep -q '<div id="root">'
```

---

## E2: Environment Parity
**Severidad**: WARNING
**Descripción**: Los ambientes deben tener configuración consistente.

### Checks:
- `.env.example` documenta todas las variables necesarias
- Variables de entorno tienen defaults razonables (PORT=3001, CORS_ORIGIN=localhost:5173)
- No hay configuración hardcodeada que varíe entre ambientes
- El build de producción funciona igual que el dev (misma API, mismos endpoints)

### Ambientes King:
| Ambiente | Branch | Port | DB | CORS |
|----------|--------|------|----|------|
| dev | develop | 3001 | king-dev | localhost:5173 |
| qa | develop (promoted) | 3002 | king-qa | localhost:5174 |
| prod | main | 3003 | king-prod | dominio producción |

### Cómo verificar:
1. Comparar .env entre ambientes (si worktrees están configurados)
2. Verificar que cada ambiente tiene sus variables correctas
3. Verificar que los ports no colisionan

---

## E3: Rollback Readiness
**Severidad**: WARNING
**Descripción**: Debe ser posible hacer rollback rápidamente.

### Checks:
- ¿Se puede volver al commit anterior con git?
- ¿Hay cambios de schema de datos que impiden rollback?
- ¿Los worktrees permiten switch rápido entre versiones?
- ¿El deploy es reproducible (npm install + npm run build)?

### Cómo verificar:
1. Verificar que no hay migraciones irreversibles
2. Verificar que el proceso de deploy es determinístico
3. Verificar que el worktree de producción puede apuntar a un tag anterior

---

## E4: Post-Deploy Health
**Severidad**: BLOQUEANTE
**Descripción**: Después de deploy, verificar que el sistema funciona.

### Checks:
- Health endpoint responde con status OK
- API key está configurada (apiKeyConfigured: true)
- El frontend puede comunicarse con el backend
- Rate limiting funciona
- Stats endpoint responde

### Cómo verificar:
1. Ejecutar smoke tests (E1) contra el ambiente desplegado
2. Verificar que todas las respuestas son correctas
3. Hacer una request de prueba a /api/claude (con input mínimo)
