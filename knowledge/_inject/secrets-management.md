# Secrets Management — Knowledge Inject

> **Ámbito**: Gestión operacional de secretos — cuándo y cómo manejar env vars, vault, KMS y rotation.
> Para prevención en código (no hardcodear, patrones de detección), ver `security-essentials.md`.

---

## 12-Factor App — Variables de Entorno

El [Factor III](https://12factor.net/config) establece la separación estricta entre config y código.

### Regla fundamental

```
Código → repositorio público (sin secretos)
Config → variables de entorno (nunca commiteadas)
```

### Estructura recomendada

| Archivo | Propósito | ¿Commitear? |
|---------|-----------|-------------|
| `.env.example` | Plantilla con placeholders documentados | ✅ Sí |
| `.env` | Valores reales del entorno local | ❌ No (en .gitignore) |
| `.env.production` | Valores de producción | ❌ No (en .gitignore) |

> En CI/CD: nunca definir secretos en archivos de workflow — usar el secrets manager del proveedor (GitHub Actions `secrets.NOMBRE`, Vercel / Railway / Render Environment Variables, AWS Parameter Store).

---

## Vault y Secrets Managers

Cuándo escalar desde env vars simples a un gestor dedicado:

| Señal | Recomendación |
|-------|--------------|
| Equipo > 5 personas | Considerar vault centralizado |
| Secrets con rotación automática requerida | AWS Secrets Manager / HashiCorp Vault |
| Auditoría de acceso requerida (compliance) | Vault con audit log |
| Multi-region / multi-cloud | AWS KMS o Azure Key Vault |
| Un solo desarrollador, proyecto pequeño | `.env` + .gitignore es suficiente |

> Regla de integración: leer secrets en **startup**, cachear en memoria, nunca re-leer por request. HashiCorp Vault y AWS Secrets Manager siguen este patrón.
> AWS KMS es para **cifrado de datos en reposo** (columnas sensibles en DB), no solo para almacenar credenciales.

---

## Trade-offs: Env Vars vs Vault

| Dimensión | Env Vars | Vault / Secrets Manager |
|-----------|----------|------------------------|
| Simplicidad | ✅ Mínima configuración | ⚠️ Requiere infraestructura adicional |
| Seguridad en reposo | ⚠️ Texto plano en el proceso | ✅ Cifrado, audit log |
| Rotación | ❌ Manual + redeploy | ✅ Automática |
| Riesgo de exposición en logs | **ALTO** — `console.log(process.env)` expone todo (OWASP A09) | MEDIO — solo si se loguea el valor |
| Riesgo SSRF | N/A | **MEDIO** — si la URL del vault acepta input externo (OWASP A10) |
| Costo operacional | Bajo | Medio-alto |
| Recomendado para | Proyectos pequeños, dev/staging | Producción con compliance |

> ⚠️ **Advertencia crítica (OWASP A09)**: Las variables de entorno son texto plano en la memoria del proceso.
> Cualquier `console.log(process.env)`, `print(os.environ)` o stack trace no sanitizado puede
> exponerlas en logs de producción o en herramientas de observabilidad (Datadog, Sentry, etc.).
> Siempre configurar filtros de datos sensibles en el APM/logger.

---

## Rotation Strategies

### Cuándo rotar

| Evento | Acción inmediata |
|--------|-----------------|
| Secret comprometido (leak en código, logs) | Revocar AHORA, luego rotar |
| Empleado con acceso deja la empresa | Rotar en las 24h siguientes |
| Rotación periódica (compliance) | Según política: 90/180 días |
| Brecha de seguridad en el proveedor | Revocar y rotar todos los secretos del proveedor |

### Proceso de rotación sin downtime

```
1. Crear nuevo secret en el proveedor (el viejo sigue activo)
2. Actualizar la aplicación para usar el nuevo secret
3. Deployar la aplicación
4. Verificar que la aplicación funciona con el nuevo secret
5. Revocar el secret anterior
```

> Nunca revocar el secret antiguo antes de verificar que el nuevo funciona.
> El downtime ocurre cuando se revoca antes de confirmar.

### Señales de compromiso

- Secret aparece en un commit de git (incluso si se eliminó después — **ya está en el historial**)
- Secret aparece en logs de CI/CD o en salida de herramientas
- Alertas de uso inusual del proveedor (llamadas desde IPs no esperadas)
- Notificación de GitGuardian, GitHub Secret Scanning, o similar

**Respuesta a compromiso**:
1. **Revocar inmediatamente** en el proveedor (no esperar)
2. Limpiar el historial de git: `git filter-repo` o BFG Repo Cleaner
3. Generar nuevo secret
4. Auditar logs del proveedor para detectar uso malicioso
5. Documentar el incidente

> Para detectar secretos hardcodeados en código, ver `security/SECURITY-GATE.md` → Layer 1 y Layer 2.
